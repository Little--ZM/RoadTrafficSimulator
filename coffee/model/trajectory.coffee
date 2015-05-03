'use strict'

{min, max, abs} = Math
require '../helpers'
LanePosition = require './lane-position'
Curve = require '../geom/curve'
_ = require 'underscore'

# 车辆的轨迹轨迹类 用于判断车辆的各种判断
# 传入的参数 车辆 车道 车辆所在位置
class Trajectory
# 构造函数
  constructor: (@car, lane, position) ->
#    position如果不存在就定义为0
    position ?= 0
#    定义当前的 车道位置类 ： 传入参数有 车辆，车道，位置
    @current = new LanePosition @car, lane, position
    @current.acquire()
    @next = new LanePosition @car
    @temp = new LanePosition @car
    @isChangingLanes = false
    @turnNumber = null

  @property 'lane',
    get: -> @temp.lane or @current.lane

  @property 'absolutePosition',
    get: -> if @temp.lane? then @temp.position else @current.position

  @property 'relativePosition',
    get: -> @absolutePosition / @lane.length

  @property 'direction',
    get: -> @lane.getDirection @relativePosition

  @property 'coords',
    get: -> @lane.getPoint @relativePosition

  @property 'nextCarDistance',
    get: ->
      a = @current.nextCarDistance
      b = @next.nextCarDistance
      if a.distance < b.distance then a else b

  @property 'distanceToStopLine',
    get: ->
      return @getDistanceToIntersection() if not @canEnterIntersection()
      return Infinity

  @property 'nextIntersection',
    get: -> @current.lane.road.target

  @property 'previousIntersection',
    get: -> @current.lane.road.source

  getNextCarDistanceinNextLane: (nextLane) ->
    @current.getNextCarDistanceinNextLane nextLane

  isValidTurn: ->
    #TODO right turn is only allowed from the right lane
    nextLane = @car.nextLane
    sourceLane = @current.lane
    throw Error 'no road to enter' unless nextLane
#    @turnNumber = sourceLane.getTurnDirection nextLane
    throw Error 'no U-turns are allowed' if @turnNumber is 3
    if @turnNumber is 0 and not sourceLane.canTurnLeft
      throw Error 'no left turns from this lane'
    if @turnNumber is 2 and not sourceLane.canTurnRight
      throw Error 'no right turns from this lane'
#    if turnNumber is 1
#      直行道路在交叉口中央的时候不许换道
#     TODO 当两个路段的道路不一样的时候，可以选择切换车道
#      return false
    return true

  canEnterIntersection: ->
    nextLane = @car.nextLane
    sourceLane = @current.lane
    return true unless nextLane
    intersection = @nextIntersection
#    turnNumber = sourceLane.getTurnDirection nextLane
    sideId = sourceLane.road.targetSideId
    intersection.controlSignals.state[sideId][@turnNumber]

  getDistanceToIntersection: ->
    distance = @current.lane.length - @car.length / 2 - @current.position
    if not @isChangingLanes then max distance, 0 else Infinity

  timeToMakeTurn: (plannedStep = 0) ->
    @getDistanceToIntersection() <= plannedStep

  moveForward: (distance) ->
    distance = max distance, 0
    @current.position += distance
    @next.position += distance
    @temp.position += distance
    if @timeToMakeTurn() and @canEnterIntersection() and @isValidTurn()
      @current.lane.road.target.CPAThroughIntersectionMapByCycle[@current.lane.road.target.CycleNum] +=1
      nextLane = @car.popNextLane()
#      @_startChangingLanes nextLane, 0
      if @turnNumber isnt 1
        @_startChangingLanes nextLane, 0
      else
        @_startChangingLanes nextLane.road.lanes[@current.lane.laneIndex], 0
    tempRelativePosition = @temp.position / @temp.lane?.length
    gap = 1.5 * @car.length
    if @isChangingLanes and @temp.position > gap and not @current.free
      @current.release()
    if @isChangingLanes and @next.free and
    @temp.position + gap > @temp.lane?.length
      @next.acquire()
    if @isChangingLanes and tempRelativePosition >= 1
      @_finishChangingLanes()
    if @current.lane and not @isChangingLanes and not @car.nextLane
      @car.pickNextLane()

#  checkRearviewMirror: (nextLane) ->
#    for id, o of nextLane.carsPositions
#      if @current.position - o.position  < @car.length
#        console.log o.car.ChangeLanePosition
#        console.log @car.ChangeLanePosition
#        changeLanePositionDistance = o.car.ChangeLanePosition - @car.ChangeLanePosition
#
#        if abs changeLanePositionDistance < @car.length/2
#          return false
#    return true

  checkRearviewMirror: (nextLane) ->
    for id, o of nextLane.carsPositions
      if 0 < @current.position - o.position  < @car.length
        return false
      if 0 < o.position - @current.position < @car.length
        return false
    return true

  canInitiativeChangeLane: (nextLane) ->
    nextLaneCarDistance = @current.getNextCarDistanceinNextLane nextLane
    nextCarDistance = @nextCarDistance
    return nextLaneCarDistance.distance > nextCarDistance.distance



  checkRearviewMirrorAndStraight: (nextLane) ->
    for id, o of nextLane.carsPositions
      if @current.position > o.position
        if @current.position - o.position  < @car.length
          return false
    return true

  changeLane: (nextLane) ->
    throw Error 'already changing lane' if @isChangingLanes
    throw Error 'no next lane' unless nextLane?
    throw Error 'next lane == current lane' if nextLane is @lane
#    如果当前的道路与下一条lane的road不是同一条，抛出错误
    throw Error 'not neighbouring lanes' unless @lane.road is nextLane.road
    nextPosition = @current.position + 2 * @car.length


    throw Error 'too late to change lane'+ @car.id unless nextPosition < @lane.length
    @_startChangingLanes nextLane, nextPosition

  _getIntersectionLaneChangeCurve: ->

  _getAdjacentLaneChangeCurve: ->
    p1 = @current.lane.getPoint @current.relativePosition
    p2 = @next.lane.getPoint @next.relativePosition
    distance = p2.subtract(p1).length
    direction1 = @current.lane.middleLine.vector.normalized.mult distance * 0.3
    control1 = p1.add direction1
    direction2 = @next.lane.middleLine.vector.normalized.mult distance * 0.3
    control2 = p2.subtract direction2
    curve = new Curve p1, p2, control1, control2

  _getCurve: ->
    # FIXME: race condition due to using relativePosition on intersections
    @_getAdjacentLaneChangeCurve()

  _startChangingLanes: (nextLane, nextPosition) ->
    throw Error 'already changing lane' if @isChangingLanes
    throw Error 'no next lane ' + nextLane.toJSON() unless nextLane?
    @isChangingLanes = true
    @next.lane = nextLane
    @next.position = nextPosition

    curve = @_getCurve()

    @temp.lane = curve
    @temp.position = 0 # @current.lane.length - @current.position
    @next.position -= @temp.lane.length

  _finishChangingLanes: ->
    throw Error 'no lane changing is going on' unless @isChangingLanes
    @isChangingLanes = false

#     將車从旧的lane中移除，放入新的lane中
    delete @current.lane.carsInLane[@car.id]
    @next.lane.carsInLane[@car.id] = @car

    # TODO swap current and next
    @current.lane = @next.lane
    @current.position = @next.position or 0
    @current.acquire()
    @next.lane = null
    @next.position = NaN
    @temp.lane = null
    @temp.position = NaN
    @current.lane

  release: ->
    @current?.release()
    @next?.release()
    @temp?.release()

module.exports = Trajectory
