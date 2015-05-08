'use strict'

require '../helpers'
_ = require 'underscore'
Segment = require '../geom/segment'

# 车道的类 一个车道可能会有2-n 条车道
class Lane

#  构造函数 起始节点 目标节点 所在的道路
  constructor: (@laneId, @sourceSegment, @targetSegment, @road, @laneIndex, @canTurnLeft, @canTurnRight, @canGoStraight=true) ->

    @leftAdjacent = null
    #    右边临近车道
    @rightAdjacent = null
    #    是否是最左边的车道
    @leftmostAdjacent = null
    #    是否是最右边的车道
    @rightmostAdjacent = null
    #    车辆的位置的集合
    @carsPositions = {}
    #    车辆集合
    @carsInLane = {}
    #    车道上的车辆数
    @carsNumber = 0
    #   更新函数
    @update()

  toJSON: ->
    obj = _.extend {}, this
    delete obj.carsPositions
    obj

#    属性起始道路的节点的id
  @property 'sourceSideId',
    get: -> @road.sourceSideId

#    目标道路的节点
  @property 'targetSideId',
    get: -> @road.targetSideId

#      是否是最右边的车道
  @property 'isRightmost',
    get: -> this is @.rightmostAdjacent

#      是否是最左边的车道
  @property 'isLeftmost',
    get: -> this is @.leftmostAdjacent

  @property 'leftBorder',
    get: ->
      new Segment @sourceSegment.source, @targetSegment.target

  @property 'rightBorder',
    get: ->
      new Segment @sourceSegment.target, @targetSegment.source

  update: ->
    @middleLine = new Segment @sourceSegment.center, @targetSegment.center
    @length = @middleLine.length
    @direction = @middleLine.direction

  getTurnDirection: (other) ->
    return @road.getTurnDirection other.road

  getDirection: ->
    @direction

  getPoint: (a) ->
    @middleLine.getPoint a

  addCarPosition: (carPosition) ->
    throw Error 'car is already here' if carPosition.id of @carsPositions
    @carsPositions[carPosition.id] = carPosition

  removeCar: (carPosition) ->
    throw Error 'removing unknown car' unless carPosition.id of @carsPositions
    delete @carsPositions[carPosition.id]

  getNext: (carPosition) ->
    throw Error 'car is on other lane' if carPosition.lane isnt this
    next = null
    bestDistance = Infinity
    for id, o of @carsPositions
      distance = o.position - carPosition.position
      if not o.free and 0 < distance < bestDistance
        bestDistance = distance
        next = o
    next

  getNextLanesNextCar: (currentPosition, nextLane) ->
    bestDistance = Infinity
    leastDistance = Infinity
    next = null
    for id, o of nextLane.carsPositions
      distance = o.position - currentPosition
      if not o.free and 0 < distance < bestDistance
        bestDistance = distance
        next = o
      distance = currentPosition - o.position
      if 0 < distance < leastDistance
        leastDistance = distance

    if bestDistance > 12 and leastDistance > 20
      return next
    return null


module.exports = Lane
