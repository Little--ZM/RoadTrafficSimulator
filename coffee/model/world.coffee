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

#   瞬时平均速度
  @property 'instantSpeed',
    get: ->
      speeds = _.map @cars.all(), (car) -> car.speed
      return 0 if speeds.length is 0
      return (_.reduce speeds, (a, b) -> a + b) / speeds.length

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
    @carsNumber = 0
#    车辆生成交叉口
    @carProducerIntersection = new Pool Intersection, obj.intersections

    @realIntersection = new Pool Intersection, obj.intersections

    @timeFactor = 1

  save: ->
#    将this中的对象全部都放入 {} 中
    data = _.extend {}, this
#    删除data中的 cars
    delete data.cars
#    将当前数据用json格式存储起来
    localStorage.world = JSON.stringify data

#    加载仿真场景
  load: ->
    data = localStorage.world
    data = data and JSON.parse data

#    知道data为空，则返回
    return unless data?
    @clear()
    @carsNumber = data.carsNumber or 0

#    添加交叉口
    for id, intersection of data.intersections
      @addIntersection Intersection.copy intersection

#      添加到道路
#    TODO  这里的逻辑需要修改 不能随机的选择 交叉口作为起始点和终止点
    for id, road of data.roads
      road = Road.copy road
      road.source = @getIntersection road.source
      road.target = @getIntersection road.target
      @addRoad road

#      产生地图
  generateMap: (minX = -2, maxX = 2, minY = -2, maxY = 2) ->
    @clear()
    intersectionsNumber = (0.8 * (maxX - minX + 1) * (maxY - minY + 1)) | 0
    map = {}
    gridSize = settings.gridSize
    step = 5 * gridSize
    @carsNumber = 100

#   创建 intersectionsNumber 个交叉口
    while intersectionsNumber > 0
      x = _.random minX, maxX
      y = _.random minY, maxY

#      unless 直到 的意思
#      map中的 坐标xy为的内容为空 则可以继续进行
      unless map[[x, y]]?

        rect = new Rect step * x, step * y, gridSize, gridSize
        intersection = new Intersection rect
        @addIntersection map[[x, y]] = intersection
        intersectionsNumber -= 1

    for x in [minX..maxX]
      previous = null
      is_road = 0
      for y in [minY..maxY]
        intersection = map[[x, y]]
        if intersection?
          if abs(is_road - x - y) < 2
#            如果previous 存在 就添加道路
            @addRoad new Road intersection, previous if previous?
            @addRoad new Road previous, intersection if previous?
          previous = intersection
          is_road = x + y


    for y in [minY..maxY]
      previous = null
      is_road = 0
      for x in [minX..maxX]
        intersection = map[[x, y]]
        if intersection?
          if abs(is_road - x - y) < 2
            @addRoad new Road intersection, previous if previous?
            @addRoad new Road previous, intersection if previous?
          previous = intersection
          is_road = x + y
    null

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


    for id, intersection of @intersections.all()
      if intersection.roads.length >= 2
        @realIntersection.put intersection
      else
        @carProducerIntersection.put intersection



#  创建单个交叉口的地图模型
  generateSingleCrossRoadMap: ->
    @clear()
    map = {}
    gridSize = settings.gridSize
    stepX = 8 * gridSize
    stepY = 4 * gridSize
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

    for id, intersection of @intersections.all()
#      console.log intersection.roads.length
      if intersection.roads.length >= 2
        @realIntersection.put intersection
      else
        @carProducerIntersection.put intersection



  clear: ->
    @set {}

  onTick: (delta) =>
    throw Error 'delta > 1' if delta > 1
    @refreshCars()
    for id, intersection of @intersections.all()
      intersection.controlSignals.onTick delta
    for id, car of @cars.all()
      car.move delta
      @removeCar car unless car.alive

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
      @addCar car
      road.lanes[laneNumber].carsInLane[car.id] = car



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
