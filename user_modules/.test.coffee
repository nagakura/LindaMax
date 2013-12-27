mongoose = require "mongoose"
db = mongoose.connect("mongodb://localhost/mono")
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

#スキーマ登録
MonoSchema = new Schema
  name:     type:String, unique: true
  content:  type:String, default: "this is test"
  sensors:  [type:ObjectId, ref: "sensors"]
  created:  type: Date, default: new Date()

SensorSchema = new Schema
  name:     type:String, unique: true
  created:  type:Date, default: new Date()

#modelを登録
Mono = db.model "monos", MonoSchema
Sensor = db.model "sensors", SensorSchema

#オブジェクトを作成
createMono = (name, content)->
  if name is ""
    console.log "object not exist"
    return
  Mono.findOne name: name, (err, mono)->
    if !err
      buf = new Mono
        name: name
        content: content if content
      buf.save()
      console.log "create mono"

#sensor作成
createSensor = (name)->
  if name is ""
    console.log "sensor not exist"
    return
  Sensor.findOne name: name, (err, sensor)->
    if !err
      buf = new Sensor
        name: name
      buf.save()
      console.log "create sensor"

#sensor追加
addSensor = (monoN, sensorN)->
  Mono.findOne name: monoN, (err, mono)->
    if !mono?
      console.log "object not exist"
      return
    if !err and mono?
      isid = true
      Sensor.findOne name:sensorN, (err, sensor)->
        if !sensor?
          console.log "sensor not exist"
          return
        if !err and sensor?
          for i in mono.sensors
            isid = false if ("" + i) is ("" + sensor._id)
          if isid
            mono.sensors.push sensor
            mono.save()
            console.log "add sensor"
          else
            console.log "this name exist"

#センサー情報取得
getSensor = (name)->
  Mono.findOne(name:name)
  ###
  Mono.findOne({name:"aaa"}).populate("sensors").exec((err, mono)->
    if !mono?
      console.log "object not exist"
      return
    if !err and mono?
      #console.log "get sensor:", mono.sensors
      console.log mono
      #mono
  )
  ###

console.log getSensor("aaa").sensors

#module exports
module.exports =
  createMono: createMono
  createSensor: createSensor
  addSensor: addSensor
  #getSensor: getSensor
  
