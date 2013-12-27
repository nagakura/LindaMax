WebSocket       = require("ws")
EventEmitter    = require("events").EventEmitter
moment          = require("moment")
RocketIO        = require "rocketio-client"

class Linda extends EventEmitter
  session: ""

  constructor: (url, name)->
    @io = new RocketIO url
    @io.connect()

  push: (type, data)->
    @io.push type, data

class TupleSpace

  constructor: (@name, @linda)->
    @time = moment().format()

  write: (tuple, opts)->
    throw new Error("TupleSpace.write's Arguments[0] should be object") if typeof tuple isnt 'object'
    opts = opts || {}
    @linda.push "__linda_write", [@name, tuple, opts]

  read: (tuple, callback)->
    throw new Error("TupleSpace.read's Arguments[0] should be object") if typeof tuple isnt 'object'
    throw new Error("TupleSpace.read's Arguments[1] should be callback function") if typeof callback isnt 'function'
    cid = @callbackId()
    @linda.io.once "__linda_read_callback_#{cid}", (data)=>
      callback data.tuple, data.info
    @linda.push "__linda_read", [@name, tuple, cid]

  watch: (tuple, callback)->
    throw new Error("TupleSpace.watch's Arguments[0] should be object") if typeof tuple isnt 'object'
    throw new Error("TupleSpace.watch's Arguments[1] should be callback function") if typeof callback isnt 'function'
    cid = @callbackId()
    @linda.io.once "__linda_watch_callback_#{cid}", (data)->
      callback data.tuple, data.info
    @linda.push "__linda_watch", [@name, tuple, cid]

  take: (tuple, callback)->
    throw new Error("TupleSpace.take's Arguments[0] should be object") if typeof tuple isnt 'object'
    throw new Error("TupleSpace.take's Arguments[1] should be callback function") if typeof callback isnt 'function'
    cid = @callbackId()
    @linda.io.once "__linda_take_callback_#{cid}", (data)->
      callback data.tuple, data.info
    @linda.push "__linda_take", [@name, tuple, cid]
 
  callbackId: ()->
    "#{moment().diff(@time)}#{moment().unix()}_#{Math.random(1000000)}"

module.exports =
  Linda: Linda
  TupleSpace: TupleSpace