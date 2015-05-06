'use strict'

{random,abs} = Math
require '../helpers'
_ = require 'underscore'
Car = require './car'
Intersection = require './intersection'
Road = require './road'
Pool = require './pool'
Rect = require '../geom/rect'
settings = require '../settings'

# 整个仿真的环境
class World
  constructor: ->
    @set {}

#  瞬时平均速度
  @property 'instantSpeed',
    get: ->
      return 0 if @totalCarsNum is 0
      avgspeed = (@totalAverageSpeed / @totalCarsNum  * 3.6)
      return avgspeed

#  平均延误
  @property 'instantDelay',
    get: ->
      return 0 if @totalCarsNum is 0
      return @totalDelay/@totalCarsNum

#  平均停车次数
  @property 'instantStopTimes',
    get: ->
      return 0 if @totalStopCarsNum is 0
      return @totalStopTimes/@totalCarsNum

#  平均停车延误
  @property 'instantStopDelay',
    get: ->
      return 0 if @totalStopCarsNum is 0
      return @totalStopDelay/@totalStopCarsNum

#  实时停车比例
  @property "instantStopRate",
    get: ->
      return 0 if @totalStopCarsNum is 0
      return @totalStopCarsNum/@totalCarsNum


  #    环境设定
  set: (obj) ->
#    定义一个map
    obj ?= {}
#    定义交叉口node 存放在一个pool中
    @intersections = new Pool Intersection, obj.intersections
#    定义一一个道路的pool
    @roads = new Pool Road, obj.roads
#    定义一个车辆的pool
    @cars = new Pool Car, obj.cars
#    将车辆的数量设为0
    @carsNumber = 10
#    车辆生成交叉口
    @carProducerIntersection = new Pool Intersection, obj.intersections

    @realIntersection = new Pool Intersection, obj.intersections

    @timeFactor = 1

#    一下几个统计项目，只统计消失的车辆
#    所有完成车路程的车辆的平均速度和
    @totalAverageSpeed = 0
#    总延误
    @totalDelay = 0
#    总共停车次数
    @totalStopTimes = 0.0
#    总共停车的延误
    @totalStopDelay = 0
#    所有有过停车的行为的车辆
    @totalStopCarsNum = 0
#   所有已经完成路程的车辆的数目
    @totalCarsNum = 0
#   仿真的时间
    @sim_time = 0

  save: ->
    @generateRealIntersecionAndCarProducer()
#    将this中的对象全部都放入 {} 中
    data = _.extend {}, this
#    删除data中的 cars
    delete data.cars
#    将当前数据用json格式存储起来
    localStorage.world = JSON.stringify data

  load: (data) ->
    data = data or localStorage.world
    data = data and JSON.parse data
    return unless data?
    @clear()
    @carsNumber = data.carsNumber or 0
    for id, intersection of data.intersections
      @addIntersection Intersection.copy intersection
    for id, road of data.roads
      road = Road.copy road
      road.source = @getIntersection road.source
      road.target = @getIntersection road.target
      @addRoad road
    @generateRealIntersecionAndCarProducer()
#    区分真实交叉口以及 车辆产生rect

  generateRealIntersecionAndCarProducer: ->
    @realIntersection.clear()
    @carProducerIntersection.clear()
    for id, intersection of @intersections.all()
      if intersection.roads.length >= 2
        @realIntersection.put intersection
      else
        intersection.generateCar = true
        @carProducerIntersection.put intersection


#  按照一定逻辑 入口产生车辆
  generateCars:->
    null

# 创建四个交叉口的车辆模型地图
  generateCrossRoadMap: ->
    @clear()
    intersectionNumber = 12
    map = {}
    gridSize = settings.gridSize
    step = 5 * gridSize
    @carsNumber = 50

    @addIntersection map[[0,-1]] = new Intersection new Rect step * 0, step * -1, gridSize, gridSize
    @addIntersection map[[1,-1]] = new Intersection new Rect step * 1, step * -1, gridSize, gridSize
    @addIntersection map[[-1,0]] = new Intersection new Rect step * -1, step * 0, gridSize, gridSize
    @addIntersection map[[0,0]] = new Intersection new Rect step * 0, step * 0, gridSize, gridSize
    @addIntersection map[[1,0]] = new Intersection new Rect step * 1, step * 0, gridSize, gridSize
    @addIntersection map[[2,0]] = new Intersection new Rect step * 2, step * 0, gridSize, gridSize
    @addIntersection map[[-1,1]] = new Intersection new Rect step * -1, step * 1, gridSize, gridSize
    @addIntersection map[[0,1]] = new Intersection new Rect step * 0, step * 1, gridSize, gridSize
    @addIntersection map[[1,1]] = new Intersection new Rect step * 1, step * 1, gridSize, gridSize
    @addIntersection map[[2,1]] = new Intersection new Rect step * 2, step * 1, gridSize, gridSize
    @addIntersection map[[0,2]] = new Intersection new Rect step * 0, step * 2, gridSize, gridSize
    @addIntersection map[[1,2]] = new Intersection new Rect step * 1, step * 2, gridSize, gridSize


    @addRoad new Road map[[0,-1]], map[[0,0]]
    @addRoad new Road map[[0,0]], map[[0,-1]]

    @addRoad new Road map[[1,-1]], map[[1,0]]
    @addRoad new Road map[[1,0]], map[[1,-1]]

    @addRoad new Road map[[-1,0]], map[[0,0]]
    @addRoad new Road map[[0,0]], map[[-1,0]]

    @addRoad new Road map[[0,0]], map[[1,0]]
    @addRoad new Road map[[1,0]], map[[0,0]]

    @addRoad new Road map[[1,0]], map[[2,0]]
    @addRoad new Road map[[2,0]], map[[1,0]]

    @addRoad new Road map[[0,0]], map[[0,1]]
    @addRoad new Road map[[0,1]], map[[0,0]]

    @addRoad new Road map[[1,0]], map[[1,1]]
    @addRoad new Road map[[1,1]], map[[1,0]]

    @addRoad new Road map[[-1,1]], map[[0,1]]
    @addRoad new Road map[[0,1]], map[[-1,1]]

    @addRoad new Road map[[0,1]], map[[1,1]]
    @addRoad new Road map[[1,1]], map[[0,1]]

    @addRoad new Road map[[1,1]], map[[2,1]]
    @addRoad new Road map[[2,1]], map[[1,1]]

    @addRoad new Road map[[0,1]], map[[0,2]]
    @addRoad new Road map[[0,2]], map[[0,1]]

    @addRoad new Road map[[1,1]], map[[1,2]]
    @addRoad new Road map[[1,2]], map[[1,1]]

    @generateRealIntersecionAndCarProducer()

#  创建单个交叉口的地图模型
  generateSingleCrossRoadMap: ->
    @clear()
    map = {}
    gridSize = settings.gridSize
    stepX = 8 * gridSize
    stepY = 8 * gridSize
    @carsNumber = 10

    @addIntersection map[[-1,0]] = new Intersection new Rect stepX * -1, 0, gridSize, gridSize
    @addIntersection map[[0,-1]] = new Intersection new Rect 0, stepY * -1, gridSize, gridSize
    @addIntersection map[[0,0]] = new Intersection new Rect  0,  0, gridSize, gridSize
    @addIntersection map[[1,0]] = new Intersection new Rect stepX * 1, 0, gridSize, gridSize
    @addIntersection map[[0,1]] = new Intersection new Rect 0, stepY * 1, gridSize, gridSize

#    下
    @addRoad new Road map[[0,-1]], map[[0,0]]
    @addRoad new Road map[[0,0]], map[[0,-1]]

#    左
    @addRoad new Road map[[-1,0]], map[[0,0]]
    @addRoad new Road map[[0,0]], map[[-1,0]]

#    右
    @addRoad new Road map[[0,0]], map[[1,0]]
    @addRoad new Road map[[1,0]], map[[0,0]]

#    上
    @addRoad new Road map[[0,0]], map[[0,1]]
    @addRoad new Road map[[0,1]], map[[0,0]]

    @generateRealIntersecionAndCarProducer()

  clear: ->
    @set {}

  onTick: (delta, timeFactor) =>
    throw Error 'delta > 1' if delta > 1
    @sim_time += delta
    @refreshCars()
    for id, intersection of @intersections.all()
      intersection.controlSignals.onTick delta
    for id, car of @cars.all()
      car.move delta
      if !car.alive
#        添加延误时间。
        if car.distance > 0
          @totalDelay += car.timeSpend - car.distance / car.maxSpeed
  #        添加停车相关。
          if car.hasBeenStoped
            @totalStopTimes += car.stop_times
            @totalStopDelay += car.stop_delay
            @totalStopCarsNum += 1
          @totalAverageSpeed += car.distance / car.timeSpend
          @totalCarsNum += 1
        @removeCar car

  refreshCars: ->
    @addRandomCar1() if @cars.length < @carsNumber
#    @removeRandomCar() if @cars.length > @carsNumber

  addRoad: (road) ->
    @roads.put road
    road.source.roads.push road
    road.target.inRoads.push road
    road.update()

  getRoad: (id) ->
    @roads.get id

  addCar: (car) ->
    @cars.put car


  getCar: (id) ->
    @cars.get(id)

  removeCar: (car) ->
    @cars.pop car

  addIntersection: (intersection) ->
    @intersections.put intersection

  getIntersection: (id) ->
    @intersections.get id

  addRandomCar: ->
    road = _.sample @roads.all()
    if road?
      lane = _.sample road.lanes
      @addCar new Car lane if lane?

#      TODO 这里车辆的产生算法需要改进
  addRandomCar1: ->
    for id, intersection of @carProducerIntersection.all()
      road = _.sample intersection.roads
      laneNumber = _.random 0, road.lanesNumber - 1
      speed = _.random(5,10)
      catLength = 3 + 2 * random()
      car = new Car road.lanes[laneNumber] ,catLength/2 ,speed,catLength
      if car.trajectory.nextCarDistance.distance > catLength
        @addCar car
        road.lanes[laneNumber].carsInLane[car.id] = car
      else
        car.release()




#    intersection = _.sample @carProducerIntersection.all()
#    if intersection?
#      road = _.sample intersection.roads
#      if road?
#        for lane in road.lanes
#          @addCar new Car lane if lane?

  removeRandomCar: ->
    car = _.sample @cars.all()
    if car?
      @removeCar car

module.exports = World
