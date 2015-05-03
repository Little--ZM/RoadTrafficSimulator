'use strict'

{PI} = Math
require '../helpers'
$ = require 'jquery'
_ = require 'underscore'
chroma = require 'chroma-js'
Point = require '../geom/point'
Rect = require '../geom/rect'
Graphics = require './graphics'
ToolMover = require './mover'
ToolIntersectionMover = require './intersection-mover'
ToolIntersectionBuilder = require './intersection-builder'
ToolRoadBuilder = require './road-builder'
ToolHighlighter = require './highlighter'
Zoomer = require './zoomer'
settings = require '../settings'

class Visualizer
  constructor: (@world, @$canvas) ->
    @canvas = @$canvas[0]
    @ctx = @canvas.getContext('2d')

    @carImage = new Image()
    @carImage.src = 'images/car.png'

    @updateCanvasSize()
    @zoomer = new Zoomer 4, this, true
    @graphics = new Graphics @ctx
    @toolRoadbuilder = new ToolRoadBuilder this, true
    @toolIntersectionBuilder = new ToolIntersectionBuilder this, true
    @toolHighlighter = new ToolHighlighter this, true
    @toolIntersectionMover = new ToolIntersectionMover this, true
    @toolMover = new ToolMover this, true
    @_running = false
    @previousTime = 0
    @timeFactor = settings.defaultTimeFactor
    @debug = false

  drawIntersection: (intersection, alpha) ->
    color = intersection.color or settings.colors.intersection
    @graphics.drawRect intersection.rect
    @ctx.lineWidth = 0.4
    @graphics.stroke color
    @graphics.fillRect intersection.rect, color, alpha
    for road in intersection.inRoads
      leftLine = road.leftmostLane.leftBorder
      rightLine = road.rightmostLane.rightBorder
      percent = settings.stopLineGap / leftLine.length
      @graphics.drawLine leftLine.getPoint(1 - percent), rightLine.getPoint(1 - percent)
      @graphics.stroke settings.colors.roadMarking
#    vertices = intersection.rect.getVertices()
#    for j, i in [1, 2, 3, 0]
#      @graphics.drawLine vertices[i], vertices[i].add (vertices[j].subtract vertices[i]).mult 0.5
#      @ctx.closePath()
#      @graphics.stroke settings.colors.roadMarking

  drawIntersectionWithCurve: (intersection, alpha) ->
    color = intersection.color or settings.colors.road
    @ctx.lineWidth = 0.4
    vertices = intersection.rect.getVertices()
    #@graphics.drawIntersectionCurve vertices[0].x,vertices[0].y,vertices[1].x-vertices[0].x,color,alpha
    length = settings.stopLineGap
    roadsBySector = []
    for road in intersection.roads
      do (road) ->
        sector = road.source.rect.getSectorId road.target.rect.center()
        roadsBySector[sector] = road
    if roadsBySector[0] and roadsBySector[1]
      @graphics.drawSingleIntersectionCurve vertices[1], roadsBySector[0].target.rect.getVertices()[2], roadsBySector[1].target.rect.getVertices()[0], length, color, alpha
    if roadsBySector[1] and roadsBySector[2]
      @graphics.drawSingleIntersectionCurve vertices[2], roadsBySector[1].target.rect.getVertices()[3], roadsBySector[2].target.rect.getVertices()[1], length, color, alpha
    if roadsBySector[2] and roadsBySector[3]
      @graphics.drawSingleIntersectionCurve vertices[3], roadsBySector[2].target.rect.getVertices()[0], roadsBySector[3].target.rect.getVertices()[2], length, color, alpha
    if roadsBySector[3] and roadsBySector[0]
      @graphics.drawSingleIntersectionCurve vertices[0], roadsBySector[3].target.rect.getVertices()[1], roadsBySector[0].target.rect.getVertices()[3], length, color, alpha

  drawSignals: (road) ->
    lightsColors = [settings.colors.redLight, settings.colors.greenLight]
    intersection = road.target
    if intersection.roads.length > 2
      segment = road.targetSide
      sideId = road.targetSideId
      lights = intersection.controlSignals.state[sideId]

      @ctx.save()
      @ctx.translate segment.center.x, segment.center.y
      @ctx.rotate (sideId + 1) * PI / 2
      @ctx.scale 1 * segment.length, 1 * segment.length
      # map lane ending to [(0, -0.5), (0, 0.5)]
      if lights[0]
        @graphics.drawTriangle(
          new Point(0.1, -0.2),
          new Point(0.2, -0.4),
          new Point(0.3, -0.2)
        )
        @graphics.fill settings.colors.greenLight
      if lights[1]
        @graphics.drawTriangle(
          new Point(0.3, -0.1),
          new Point(0.5, 0),
          new Point(0.3, 0.1)
        )
        @graphics.fill settings.colors.greenLight
      if lights[2]
        @graphics.drawTriangle(
          new Point(0.1, 0.2),
          new Point(0.2, 0.4),
          new Point(0.3, 0.2)
        )
        @graphics.fill settings.colors.greenLight
      @ctx.restore()

  drawRoad: (road, alpha) ->
    throw Error 'invalid road' if not road.source? or not road.target?
    sourceSide = road.sourceSide
    targetSide = road.targetSide

    @ctx.save()
    @ctx.lineWidth = 0.4
    leftLine = road.leftmostLane.leftBorder
    percent = settings.stopLineGap / leftLine.length
    @graphics.drawSegment leftLine.subsegment percent, 1 - percent
    @graphics.stroke settings.colors.roadMarking

    rightLine = road.rightmostLane.rightBorder
    percent = settings.stopLineGap / rightLine.length
    @graphics.drawSegment rightLine.subsegment percent, 1 - percent
    @graphics.stroke settings.colors.roadMarking
    @ctx.restore()

    @graphics.polyline sourceSide.source, sourceSide.target,
    targetSide.source, targetSide.target
    @graphics.fill settings.colors.road, alpha

    @ctx.save()
    for lane in road.lanes[1..]
      line = lane.rightBorder
      percent = settings.stopLineGap / line.length
      dashSize = 1
      @graphics.drawSegment line.subsegment percent, 1 - percent
      @ctx.lineWidth = 0.2
      @ctx.lineDashOffset = 1.5 * dashSize
      @ctx.setLineDash [dashSize]
      @graphics.stroke settings.colors.roadMarking
    @ctx.restore()

  drawCar: (car) ->
    angle = car.direction
    center = car.coords
    rect = new Rect 0, 0, 1.1 * car.length, 1.7 * car.width
    rect.center new Point 0, 0
#    boundRect = new Rect 0, 0, car.length, car.width
#    boundRect.center new Point 0, 0

    @graphics.save()
    @ctx.translate center.x, center.y
    @ctx.rotate angle
    l = 0.90 - 0.30 * car.speed / car.maxSpeed
    style = chroma(car.color, 0.8, l, 'hsl').hex()
    @graphics.drawImage @carImage, rect
#    @graphics.fillRect boundRect, style
    @graphics.restore()
    if @debug
      @ctx.save()
      @ctx.fillStyle = "black"
      @ctx.font = "1px Arial"
      @ctx.fillText car.id, center.x, center.y

      if (curve = car.trajectory.temp?.lane)?
        @graphics.drawCurve curve, 0.1, 'red'
      @ctx.restore()

  drawGrid: ->
    gridSize = settings.gridSize
    box = @zoomer.getBoundingBox()
    return if box.area() >= 2000 * gridSize * gridSize
    sz = 0.4

    for i in [box.left()..box.right()] by gridSize
      for j in [box.top()..box.bottom()] by gridSize
        rect = new Rect i - sz / 2, j - sz / 2, sz, sz
        @graphics.fillRect rect, settings.colors.gridPoint

  updateCanvasSize: ->
    if @$canvas.attr('width') isnt $(window).width or
    @$canvas.attr('height') isnt $(window).height
      @$canvas.attr
        width: $(window).width()
        height: $(window).height()

  draw: (time) =>
    delta = (time - @previousTime) || 0
    if delta > 30
      delta = 100 if delta > 100
      @previousTime = time
      @world.onTick @timeFactor * delta / 1000, @timeFactor
      @updateCanvasSize()
      @graphics.clear settings.colors.background
      @graphics.save()
      @zoomer.transform()
      @drawGrid()
      @drawRoad road, 1 for id, road of @world.roads.all()
      for id, intersection of @world.intersections.all()
        @drawIntersection intersection, 1
      for id, intersection of @world.realIntersection.all()
        @drawIntersectionWithCurve intersection, 1


      @drawSignals road for id, road of @world.roads.all()
      @drawCar car for id, car of @world.cars.all()
      @toolIntersectionBuilder.draw() # TODO: all tools
      @toolRoadbuilder.draw()
      @toolHighlighter.draw()
      @graphics.restore()
    window.requestAnimationFrame @draw if @running

  @property 'running',
    get: -> @_running
    set: (running) ->
      if running then @start() else @stop()

  start: ->
#    if !@_running
    unless @_running
      @_running = true
      @draw()

  stop: ->
    @_running = false

module.exports = Visualizer
