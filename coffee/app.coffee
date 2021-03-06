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
#  canvas.attr
#    width: $(window).width()
#    height: $(window).height()
  $('#simulation-canvas').append(canvas)

  builderCanvas = $('<canvas />', {id: 'builder-canvas'})
#  builderCanvas.attr
#    width: $(window).width()
#    height: $(window).height()
  $('#map-builder-canvas').append(builderCanvas)
#
#  signalHelpCanvas = $('<canvas />', {id: 'signalHelpCanvas'})
#  $('#signal-help-canvas').append(builderCanvas)
##  $('#signal-help').hide()

  window.world = new World()
  window.visualizer = new Visualizer world, canvas
#  window.builderVisualizer.start(false)

  window.builderWorld = new World()
  window.builderVisualizer = new Visualizer builderWorld, builderCanvas
  window.builderVisualizer.start(true)

#  window.signalHelpWorld = new World()
#  window.signalHelpVisualizer = new Visualizer signalHelpWorld, signalHelpCanvas
#  window.signalHelpVisualizer.start(true)


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
