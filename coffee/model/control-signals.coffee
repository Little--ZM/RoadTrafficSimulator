'use strict'

{random} = Math
require '../helpers'
settings = require '../settings'

class ControlSignals
  constructor: (@intersection) ->
    @time = 0
    @flipMultiplier = 1 + (random() * 0.4 - 0.2) # 0.8 - 1.2
    @stateNum = 0
#    添加周期时间
    @cycleNumber=0

  states: [
    ['LR', 'R', 'LR', 'R'],
    ['FR', 'R', 'FR', 'R'],
    ['R', 'LR', 'R', 'LR'],
    ['R', 'FR', 'R', 'FR']
  ]

#  红灯为0 绿灯为1
  @STATE = [RED: 0, GREEN: 1]

#  信号灯的间隔
  @property 'flipInterval',
    get: -> @flipMultiplier * settings.lightsFlipInterval

  _decode: (str) ->
    state = [0, 0, 0]
    state[0] = 1 if 'L' in str
    state[1] = 1 if 'F' in str
    state[2] = 1 if 'R' in str
    state

  @property 'state',
    get: ->
      stringState = @states[@stateNum % @states.length]
      (@_decode x for x in stringState)

#    随着时间的到达，信号灯的状态随之改变 需要记录状态和时间
  flip: ->
    @stateNum += 1
    if not @intersection.generateCar
      stateIndex =  @stateNum % @states.length
#      判断不是第一个循环
      if @stateNum isnt 0 and stateIndex is 0
        @cycleNumber += 1
#      判断不同的车道方向的车道开始有绿灯，则开始计算最大排队长度
      if stateIndex % 2 is 0
        @intersection.caculatorCarInLane @cycleNumber

#    时间推进函数
  onTick: (delta) =>
    @time += delta
    if @time > @flipInterval
      @flip()
      @time -= @flipInterval

module.exports = ControlSignals
