'use strict'

require '../helpers'
_ = require 'underscore'
ControlSignals = require './control-signals'
Rect = require '../geom/rect'

class Intersection
  constructor: (@rect) ->
    @id = _.uniqueId 'intersection'
    @roads = []
    @inRoads = []
    @controlSignals = new ControlSignals this
#    根据交叉口的信号灯周期，计算排队排毒周期
    @carStayInLaneMapByCycle = {}
#    指的是通过交叉口的车辆的数目 最后根据仿真跑的时间，可以统计出交叉口的流量
    @carThroughIntersectionMapByCycle = {}
#    指的是最大通行能力，指的在一定时间段内通过的最大车流量
#    这个map 记录这每一个周期内的车流量
    @CPAThroughIntersectionMapByCycle = {}
    @maxCPA = 0
    @CycleNum = 0
    @avragelineCars = 0
    @generateCar = false
    @CPAThroughIntersectionMapByCycle[0] = 0

#  用于计算当前当前周期交叉口排队长度 最大排队长度是每条车道上的车辆数
  caculatorCarInLane: (CycleNum) ->
    if @CycleNum+1 is CycleNum
      @carStayInLaneMapByCycle[@CycleNum] = @avragelineCars / (@roads[0].lanesNumber * 4)
      @avragelineCars = 0
      @CPAThroughIntersectionMapByCycle[CycleNum] = 0
      @CycleNum = CycleNum
    for road in @inRoads
      if @controlSignals.state[road.targetSideId][0] is 1
        for lane in road.lanes
          @avragelineCars += lane.carsPositions.size


#   平均排队车辆数是指一个信号周期内各车道最大排队车辆数的平均值
  @copy: (intersection) ->
    intersection.rect = Rect.copy intersection.rect
    result = Object.create Intersection::
    _.extend result, intersection
    result.roads = []
    result.inRoads = []
    result.controlSignals = new ControlSignals result
    result

  toJSON: ->
    obj =
      id: @id
      rect: @rect

  update: ->
    road.update() for road in @roads
    road.update() for road in @inRoads

module.exports = Intersection
