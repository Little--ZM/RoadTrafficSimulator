'use strict'

{sqrt, atan2} = Math
require '../helpers'

class Point

  constructor: (@x = 0, @y = 0) ->

#    长度是 用勾股定理求出来的
  @property 'length',
    get: ->
      sqrt @x * @x + @y * @y

#    求出方向 使用tan
  @property 'direction',
    get: ->
      atan2 @y, @x

#     标准化
  @property 'normalized',
    get: ->
      new Point @x / @length, @y / @length

#    加一个点
  add: (o) ->
    new Point @x + o.x, @y + o.y

#    建一个点
  subtract: (o) ->
    new Point @x - o.x, @y - o.y
#   乘。。。 不大清楚
  mult: (k) ->
    new Point @x * k, @y * k

# 不大清楚是什么意思
  divide: (k) ->
    new Point @x / k, @y / k

module.exports = Point
