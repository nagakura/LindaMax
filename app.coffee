UserMongo = require "./user_modules/mongo.js"
UserLinda = require "./user_modules/linda.js"
Puid = require "puid"

express = require('express')
routes =  require('./routes')
user = require('./routes/user')
http = require('http')
path = require('path')
request = require "request"
url = require "url"
app = express()
cookie = require "cookie"

app.set('port',process.env.PORT || 4555)
app.set('views', __dirname + '/views')
app.set('view engine','jade')
app.use(express.favicon())
app.use(express.logger('dev'))
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(express.cookieParser())
app.use(express.session({secret:"hogehuga", cookie:{httpOnly: false}}))
app.use(app.router)
app.use(express.static(path.join(__dirname, 'public')))

if('development' == app.get('env'))
  app.use(express.errorHandler())


server = http.createServer(app).listen(app.get('port'), ()->
  console.log('Express server listening on port ' + app.get('port'))
)

app.get("/control", (req,res)->
  res.render("index", {title: "LindaMax"})
)

app.get("/", (req,res)->
  res.render("explain", {title: "LindaMax"})
)

app.post("/", (req,res)->
  data = {}
  data.name = req.body.name
  res.set('Content-Type', 'application/json')
  res.json(data)
)

app.get("/:obj", (req, res)->
  #res.render("detail", {contents: UserMongo.getSensor(req.params.obj)})
  Mono = UserMongo.monoModel
  Mono.findOne(name: req.params.obj).populate("sensors").exec (err, mono)->
    if mono?
      res.render("detail")
    else
      res.render("err")
)

app.get("/:obj/output", (req, res)->
  console.log req.params.obj
  UserMongo.clientModel.findOne path:req.params.obj, (err, client)->
    if !err and client? and client.url?
      res.render "output", {url: client.url, form:client.form}
    else
      res.render "output"
)

io = require('socket.io').listen(server)
io.sockets.on("connection", (socket)->
  socket.on "path", (path)->
    UserMongo.clientModel.findOne path:path, (err, client)->
      if !err and client?
        socket.emit "blocks", client.blocks
        if client.connections?
          socket.emit "restoreConnections", client.connections

  UserMongo.sensorModel.find({}, (err, sensor)->
    socket.emit "sensors", sensor
  )
  #mongo
  socket.on "CreateMono", (data)->
    UserMongo.createMono data

  socket.on "CreateSensor", (data)->
    linda = UserLinda.linda "delta"
    linda.io.on "connect", ->
      linda.ts.read ["sensor", "light"], (tuple, info)->
        console.log tuple, info
        console.log tuple[tuple.length-1]
        linda.io.emit "disconnect"
        UserMongo.createSensor data, tuple[2]

  socket.on "AddSensor", (data)->
    UserMongo.addSensor data[0], data[1]

  socket.on "sensorRequest", (data)->
    contents = data.split("/")
    linda = UserLinda.linda contents[0]
    contents.shift()
    #test
    ###
    setInterval ->
      socket.emit "lindaData", [data, 7+Math.random()*2]
    , 2000
    ###
    linda.io.on "connect", ->
      #linda.ts.read contents, (tuple, info)->
      linda.ts.watch contents, (tuple, info)->
        console.log tuple, info
        console.log tuple[tuple.length-1]
        linda.io.emit "disconnect"
        socket.emit "lindaData", [data, tuple[tuple.length-1]]

  socket.on "saveConnections", (data)->
    path = data[0]
    if data[1]?
      connections = data[1]
    else
      connections = []
    UserMongo.saveConnections path, connections

  socket.on "saveOutput", (data)->
    path = data[0]
    url = data[1][0]
    form = data[1][1]
    UserMongo.saveOutput path, url, form

  socket.on "urlRequest", (path)->
    url = null
    UserMongo.clientModel.findOne path:path, (err, client)->
      if !err and client?
        options =
          uri: client.url
          #form: {text: "hogehoge"}
          form: JSON.parse(client.form)
          json: true
        console.log "uri", client.url
        console.log "form", JSON.parse(client.form)
        request.get(options, (error, response, body)->
          if !error and response.statusCode is 200
            console.log body
          else
            console.log "error:", response.statusCode
        )


  socket.on "saveClient", (data)->
    path = data[0]
    if data[1]?
      blocks = data[1]
    else
      blocks = []
    console.log "path", path
    console.log "blocks", blocks
    UserMongo.saveClient path, blocks

  uid = null
  socket.on "uidRequest", ()->
    puid = new Puid()
    uid = puid.generate()
    socket.emit "uidResponse", uid

  socket.on("disconnect", ()->
    console.log "control disconnect"
  )
)

