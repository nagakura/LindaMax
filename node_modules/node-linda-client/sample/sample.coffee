LindaClient = require("../lib/client")
Linda = LindaClient.Linda
TupleSpace = LindaClient.TupleSpace

linda = new Linda "http://linda.masuilab.org"
linda.ts = new TupleSpace "baba", linda

linda.io.on "connect", ->
  linda.ts.watch [0, 1], (tuple, info)->
    console.log "watch!"
    console.log tuple, info
  linda.ts.write [0, 1, 2]
  linda.ts.read [0, 1, 2], (tuple, info)->
    console.log "read!"
    console.log tuple, info
  linda.ts.write [0, 1, 2, 3]
  linda.ts.take [0, 1, 2], (tuple, info)->
    console.log "take!"
    console.log tuple, info
