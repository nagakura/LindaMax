UserMongo = require "./user_modules/mongo.js"
UserLinda = require "./user_modules/linda.js"

express = require('express')
routes =  require('./routes')
user = require('./routes/user')
http = require('http')
path = require('path')
url = require "url"
app = express()
cookie = require "cookie"


app.set('port',process.env.PORT || 3000)
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


#app.get('/', routes.detail)

app.get("/", (req,res)->
  res.render("index", {title: "linda"})
)

app.get("/:obj", (req, res)->
  #res.render("detail", {contents: UserMongo.getSensor(req.params.obj)})
  Mono = UserMongo.monoModel
  Mono.findOne(name: req.params.obj).populate("sensors").exec (err, mono)->
    if mono?
      ###
      console.log mono.sensors
      res.send(mono.sensors)
      ###
      res.render("detail")
    else
      res.render("err")
)

io = require('socket.io').listen(server)
io.sockets.on("connection", (socket)->
  socket.on "path", (path)->
    UserMongo.clientModel.findOne path:path, (err, client)->
      if !err and client?
        socket.emit "blocks", client.blocks

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
    linda.io.on "connect", ->
      #linda.ts.read contents, (tuple, info)->
      linda.ts.watch contents, (tuple, info)->
        console.log tuple, info
        console.log tuple[tuple.length-1]
        linda.io.emit "disconnect"
        socket.emit "lindaData", [data, tuple[tuple.length-1]]


  socket.on "saveClient", (data)->
    path = data[0]
    #blocks = data[1].replace(/<\/div>/g, "</div>区切り").split("区切り")
    #blocks.pop()
    if data[1]?
      blocks = data[1]
    else
      blocks = []
    console.log blocks
    UserMongo.saveClient path, blocks

  socket.on("disconnect", ()->
    console.log "control disconnect"
  )
)

