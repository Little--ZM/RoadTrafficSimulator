'use strict'

require '../helpers'

# 对象池 概念
class Pool
#  构造函数 需要工厂类 对象池
  constructor: (@factory, pool) ->
    @objects = {}
    if pool? and pool.objects?
      for k, v of pool.objects
#        根据给定的对象的属性来新建的一个对象
        @objects[k] = @factory.copy(v)

  toJSON: ->
    @objects

#    通过id 取得相应的对象
  get: (id) ->
    @objects[id]

#    将对象存入相应的对象的列表中
  put: (obj) ->
    @objects[obj.id] = obj

#    将对象弹出 即删除
  pop: (obj) ->
    id = obj.id ? obj
    result = @objects[id]
    result.release?()
    delete @objects[id]
    result

#    取得所有的对象
  all: ->
    @objects

#    将所有的对象清空
  clear: ->
    @objects = {}

#    取得兑现的个数
  @property 'length',
    get: -> Object.keys(@objects).length

module.exports = Pool
