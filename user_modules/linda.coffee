LindaClient = require("node-linda-client")
Linda = LindaClient.Linda
TupleSpace = LindaClient.TupleSpace


linda = (ts)->
  linda = new Linda "http://linda.masuilab.org"
  linda.ts = new TupleSpace ts, linda
  linda
  ###
  linda.io.on "connect", ->
    console.log "connect"
    linda.ts.watch [name], (tuple, info)->
      #console.log tuple, info
  ###

module.exports =
  linda: linda
