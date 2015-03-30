'use strict'

{max, min, random, sqrt} = Math
require '../helpers'
_ = require 'underscore'
Trajectory = require './trajectory'

class Car
  constructor: (lane, position,speed,length) ->
    @id = _.uniqueId 'car'
    @color = (300 + 240 * random() | 0) % 360
    @_speed = speed
    @width = 1.7
    @length = length
    @maxSpeed = _.random(30,50)
    @s0 = 2
    @timeHeadway = 1.5
    @maxAcceleration = 1
    @maxDeceleration = 3
    @trajectory = new Trajectory this, lane, position
    @alive = true
    @preferedLane = null
    @ChangeLanePosition = null

#    行车起始时间
    @beginTime = 0
#    行车结束时间
    @stopTime = null
#    车辆的行程
    @distance = 0.0

#    坐标
  @property 'coords',
    get: -> @trajectory.coords

#     速度
  @property 'speed',
    get: -> @_speed
    set: (speed) ->
      speed = 0 if speed < 0
      speed = @maxSpeed if speed > @maxSpeed
      @_speed = speed

#     方向
  @property 'direction',
    get: -> @trajectory.direction
#
#  @property 'ChangeLanePosition',
#    get: ->

#  @canChangeLanePosition: ->
#    lowLaneLength =
#    highLaneLength =
#
#    changeLanePosition = _.random(@trajectory.current.lane.length * 0.1, @trajectory.current.lane.length  - 4 * @length)
#    if @trajectory.absolutePosition > changeLanePosition and @trajectory.absolutePosition < highLaneLength
#      return true
#    return false

#  获取时间延误
  getTimeDelay: ->
    if not @alive
      minTime = @distance/@maxSpeed
      realTime = @stopTime - @beginTime
      return realTime -minTime
    else
      console.log "not stop yet"


  release: ->
    @trajectory.release()

#    获得加速度
  getAcceleration: ->
    nextCarDistance = null
#    if @trajectory.isChangingLanes and @nextLane
#      Distance = @trajectory.getNextCarDistanceinNextLane @nextLane
#      if Distance.car
#        nextCarDistance = Distance
#      else nextCarDistance = @trajectory.nextCarDistance
#    else
    nextCarDistance = @trajectory.nextCarDistance
    distanceToNextCar = max nextCarDistance.distance, 0
    a = @maxAcceleration
    b = @maxDeceleration
    deltaSpeed = (@speed - nextCarDistance.car?.speed) || 0
    freeRoadCoeff = (@speed / @maxSpeed) ** 4
    distanceGap = @s0
    timeGap = @speed * @timeHeadway
    breakGap = @speed * deltaSpeed / (2 * sqrt a * b)
    safeDistance = distanceGap + timeGap + breakGap
    busyRoadCoeff = (safeDistance / distanceToNextCar) ** 2
    safeIntersectionDistance = 1 + timeGap + @speed ** 2 / (2 * b)
    intersectionCoeff =
    (safeIntersectionDistance / @trajectory.distanceToStopLine) ** 2
    coeff = 1 - freeRoadCoeff - busyRoadCoeff - intersectionCoeff
    return @maxAcceleration * coeff

#    移动
  move: (delta) ->
    acceleration = @getAcceleration()
#    速度加上 加速度*倍速
    @speed += acceleration * delta

    if not @trajectory.isChangingLanes and @nextLane
      currentLane = @trajectory.current.lane
#      turnNumber = currentLane.getTurnDirection @nextLane
#      根据转向来将选择的道路来进行
      preferedLane = switch @trajectory.turnNumber
        when 0 then @pickLeftLane currentLane
        when 2 then @pickRightLane currentLane
        else @pickStraightLane currentLane
      if @ChangeLanePosition is null
#        @ChangeLanePosition = @trajectory.current.lane.length * 0.1
        @ChangeLanePosition = _.random(@trajectory.current.lane.length * 0.1, currentLane.length - 5 * @length)
      if preferedLane isnt currentLane and @trajectory.absolutePosition > this.ChangeLanePosition
        if @trajectory.checkRearviewMirror preferedLane
          @trajectory.changeLane preferedLane
        else if @trajectory.absolutePosition > currentLane.length - 3.5 * @length
          @trajectory.changeLane preferedLane

    step = @speed * delta + 0.5 * acceleration * delta ** 2

##     如果发现下一辆车的距离与小于将要前进的步伐
#    if @trajectory.nextCarDistance.distance < step
#      console.log 'bad IDM'
#      acceleration = @getAcceleration()
#      step = @speed * delta + 0.5 * acceleration * delta ** 2

#     如果没有下一条路了，则选择没有
    if @trajectory.timeToMakeTurn(step)
      return @alive = false if not @nextLane?

    @distance += step
    @trajectory.moveForward step

  pickLeftLane: (currentLane) ->
    if not currentLane.isLeftmost
      return currentLane.leftAdjacent
    else
      return currentLane

  pickRightLane: (currentLane) ->
    if not currentLane.canTurnRight
      return currentLane.rightAdjacent
    else
      return currentLane

  pickStraightLane: (currentLane) ->
    nextLane = null
    if currentLane.isLeftmost
      nextLane=currentLane.rightAdjacent
    if currentLane.isRightmost
      nextLane=currentLane.leftAdjacent

    if nextLane and @trajectory.canInitiativeChangeLane nextLane
      return nextLane
    else
      return currentLane



#    选择吓一跳道路
  pickNextRoad: ->
    intersection = @trajectory.nextIntersection
    @nextRoad = null
    currentLane = @trajectory.current.lane
#    选取可能去的下一个交叉口，这个交叉口是当前交叉口连接的交叉口中挑选。当然，去除了当前的交叉口
    possibleRoads = intersection.roads.filter (x) ->
      x.target isnt currentLane.road.source
    return null if possibleRoads.length is 0
    @nextRoad = _.sample possibleRoads

#  这里的下一条车道指的是 下一条道路中的想要选择的车道
  pickNextLane: ->
    throw Error 'next lane is already chosen' if @nextLane
    @nextLane = null
    @nextRoad = @pickNextRoad()
    return null if not @nextRoad
    # throw Error 'can not pick next road' if not nextRoad
    @trajectory.turnNumber = @trajectory.current.lane.road.getTurnDirection @nextRoad
    # 0 - left, 1 - forward, 2 - right
    laneNo = switch @trajectory.turnNumber
      when 0 then @nextRoad.lanesNumber - 1
      when 1 then @trajectory.current.lane.laneIndex
      when 2 then 0
    @nextLane = @nextRoad.lanes[laneNo]
    throw Error 'can not pick next lane' if not @nextLane
    return @nextLane

#  getLaneNumber: (nextRoad) ->
#    if @lanesNumber < nextRoad.lanesNumber
#       return @lanesNumber
#    else
#      return _.random 0, nextRoad.lanesNumber - 1


  popNextLane: ->
    nextLane = @nextLane
    @nextLane = null
    @preferedLane = null
    return nextLane

module.exports = Car
