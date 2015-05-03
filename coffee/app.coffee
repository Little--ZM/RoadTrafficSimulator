'use strict'

require './helpers'
$ = require 'jquery'
_ = require 'underscore'
Visualizer = require './visualizer/visualizer'
DAT = require 'dat-gui'
World = require './model/world'
settings = require './settings'

$ ->
  canvas = $('<canvas />', {id: 'canvas'})
  $('#simulation-canvas').append(canvas)
  builderCanvas = $('<canvas />', {id: 'builder-canvas'})
  $('#map-builder-canvas').append(builderCanvas)

  window.world = new World()
#  world.generateMap()
#  if world.intersections.length is 0
#    world.generateMap()
#    world.carsNumber = 0
  window.visualizer = new Visualizer world, canvas

  window.builderWorld = new World()
  window.builderVisualizer = new Visualizer builderWorld, builderCanvas
  window.builderVisualizer.start()

  window.settings = settings
#   gui = new DAT.GUI()
#   guiWorld = gui.addFolder 'world'
#   guiWorld.open()
#   guiWorld.add world, 'save'
#   guiWorld.add world, 'load'
#   guiWorld.add world, 'clear'
#   guiWorld.add world, 'generateMap'
#   guiWorld.add world, 'generateCrossRoadMap'
#   guiWorld.add world, 'generateSingleCrossRoadMap'
#   guiVisualizer = gui.addFolder 'visualizer'
#   guiVisualizer.open()
#   guiVisualizer.add(visualizer, 'running').listen()
#   guiVisualizer.add(visualizer, 'debug').listen()
#   guiVisualizer.add(visualizer.zoomer, 'scale', 0.1, 2).listen()
#   guiVisualizer.add(visualizer, 'timeFactor', 0.1, 10).listen()
#   guiWorld.add(world, 'carsNumber').min(0).max(200).step(1).listen()
# #  guiWorld.add(world, 'timeFactor').min(1).max(5).step(0.1).listen()
#   guiWorld.add(world, 'instantSpeed').step(0.00001).listen()
#   gui.add(settings, 'lightsFlipInterval', 0, 50, 0.01).listen()
