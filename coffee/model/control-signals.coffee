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
#    周期长度
    @cycleTime=120
#    黄灯时间
    @yellowTime=3
#    信号周期设置
    @timeSettings = [
      {"start":0, "end":36},
      {"start":38, "end":48},
      {"start":60, "end":100},
      {"start":102, "end":120}
    ]

  states: [
    ['R', 'FR', 'R', 'FR'],
    ['R', 'LR', 'R', 'LR'],
    ['FR', 'R', 'FR', 'R'],
    ['LR', 'R', 'LR', 'R']
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
    if @timeSettings.length is 0
      @time += delta
      if @time > @flipInterval
        @flip()
        @time -= @flipInterval
    else
      @time += delta
      tempTime =  @time % @cycleTime

      statusIndex = @stateNum % @states.length

      if statusIndex is 3
        if tempTime > 0 and tempTime < @timeSettings[0].end
          @flip()
      else
        if tempTime > @timeSettings[statusIndex].end + @yellowTime
          @flip()

  @copy: (controlSignals, intersection) ->
    if !controlSignals?
      return new ControlSignals intersection
    result = Object.create ControlSignals::
    result.cycleTime = controlSignals.cycleTime
    result.yellowTime = controlSignals.yellowTime
    result.timeSettings = controlSignals.timeSettings
    result.stateNum = 0
    result.time = 0
    result.cycleNumber=0
    result.intersection = intersection
    result

  toJSON: ->
    obj =
      cycleTime: @cycleTime
      yellowTime: @yellowTime
      timeSettings: @timeSettings



module.exports = ControlSignals
