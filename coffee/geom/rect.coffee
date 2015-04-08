'use strict'

{abs} = Math
require '../helpers'
_ = require 'underscore'
Point = require './point'
Segment = require './segment'

# 交叉口的图形 即一个矩形的类
class Rect
  constructor: (@x, @y, @_width = 0, @_height = 0) ->

  @copy: (rect) ->
    new Rect rect.x, rect.y, rect._width, rect._height

  toJSON: ->
    _.extend {}, this

  area: ->
    @width() * @height()

  left: (left) ->
    @x = left if left?
    @x

  right: (right) ->
    @x = right - @width() if right?
    @x + @width()

  width: (width) ->
    @_width = width if width?
    @_width

  top: (top) ->
    @y = top if top?
    @y

  bottom: (bottom) ->
    @y = bottom - @height() if bottom?
    @y + @height()

  height: (height) ->
    @_height = height if height?
    @_height

  center: (center) ->
    if center?
      @x = center.x - @width() / 2
      @y = center.y - @height() / 2
    new Point @x + @width() / 2, @y + @height() / 2

#    检测是否包含这个点,检测是否在这个点内
  containsPoint: (point) ->
    @left() <= point.x <= @right() and @top() <= point.y <= @bottom()

#    是否包含模块
  containsRect: (rect) ->
    @left() <= rect.left() and rect.right() <= @right() and
    @top() <= rect.top() and rect.bottom() <= @bottom()

#    用于获取rect的四角
  getVertices: ->
    [
      new Point(@left(), @top()),
      new Point(@right(), @top()),
      new Point(@right(), @bottom()),
      new Point(@left(), @bottom()),
    ]

  getSide: (i) ->
    vertices = @getVertices()
    new Segment vertices[i], vertices[(i + 1) % 4]


#
#    0---1
#    |   |
#    |   |
#    2---3
#   找出 source 和 target 的 SectorID 就可以确定车的走向
  getSectorId: (point) ->
    offset = point.subtract @center()
    return 0 if offset.y <= 0 and abs(offset.x) <= abs(offset.y)
    return 1 if offset.x >= 0 and abs(offset.x) >= abs(offset.y)
    return 2 if offset.y >= 0 and abs(offset.x) <= abs(offset.y)
    return 3 if offset.x <= 0 and abs(offset.x) >= abs(offset.y)
    throw Error 'algorithm error'

  getSector: (point) ->
    @getSide @getSectorId point

module.exports = Rect
