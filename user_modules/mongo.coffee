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
  data:     {}
  created:  type:Date, default: new Date()

ClientSchema = new Schema
  path:     type:String, unique: true
  url:      type:String, unique:true
  blocks:   []
  connections: []

#modelを登録
Mono   = db.model "monos", MonoSchema
Sensor = db.model "sensors", SensorSchema
Client = db.model "clients", ClientSchema
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
createSensor = (name, data)->
  if name is ""
    console.log "sensor not exist"
    return
  Sensor.findOne name: name, (err, sensor)->
    if !err
      buf = new Sensor
        name: name
        data: data
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

#クライアント情報を保存
saveClient = (path, blocks)->
  Client.findOne path: path, (err, client)->
    if !err and !client?
      buf = new Client
        path: path
        blocks: blocks
      buf.save()
      console.log "client saved"
    if !err and client?
      client.path = path
      client.blocks = blocks
      client.save()
      console.log "client renewal"

#コネクションを保存
saveConnections = (path, connections)->
  Client.findOne path: path, (err, client)->
    if !err and !client?
      console.log "client not found"
    if !err and client?
      client.connections = connections
      client.save()
      console.log "connections renewal"

#urlを保存
saveOutput = (path, url)->
  Client.findOne path: path, (err, client)->
    if !err and !client?
      console.log "client not found"
    if !err and client?
      client.url = url
      client.save()
      console.log "output data renewal"

#センサー情報取得
#getSensor = (name)->
###
Mono.findOne (name: "aaa")
.populate("sensors")
.exec((err, mono)->
  if !mono?
    console.log "object not exist"
    return
  if !err and mono?
    #console.log "get sensor:", mono.sensors
    console.log mono
    mono
)
###


#module exports
module.exports =
  createMono: createMono
  createSensor: createSensor
  addSensor: addSensor
  saveClient: saveClient
  saveConnections: saveConnections
  saveOutput: saveOutput
  monoModel: Mono
  sensorModel: Sensor
  clientModel: Client
  #getSensor: getSensor
  
