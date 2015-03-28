'use strict'

require '../helpers'
_ = require 'underscore'


# 当前位置定义的类
class LanePosition
#  当前位置的类
  constructor: (@car, lane, @position) ->
#    随机生成一个id 格式是 laneposition+id
    @id = _.uniqueId 'laneposition'
#    是否是空闲的 默认为true
    @free = true
#    车道
    @lane = lane

#    定义属性 lane
  @property 'lane',
    get: -> @_lane
    set: (lane) ->
      @release()
      @_lane = lane
      # @acquire()

#  定义属性 当前 相对位置 用当前位置除以车道的长度
  @property 'relativePosition',
    get: -> @position / @lane.length

  acquire: ->
    if @lane?.addCarPosition?
      @free = false
      @lane.addCarPosition this

  release: ->
    if not @free and @lane?.removeCar
      @free = true
      @lane.removeCar this

  getNext: ->
    return @lane.getNext this if @lane and not @free

  @property 'nextCarDistance',
    get: ->
      next = @getNext()
      if next
        rearPosition = next.position - next.car.length / 2
        frontPosition = @position + @car.length / 2
        return result =
          car: next.car
          distance: rearPosition - frontPosition
      return result =
        car: null
        distance: Infinity

module.exports = LanePosition
