assert = require "assert"


LindaClient = require("../client").LindaClient
TupleSpace  = require("../client").TupleSpace

linda = new LindaClient("localhost:10010")
ts    = new TupleSpace("takumibaba", linda)


before (done)->
	linda.io.on "connect", ->
		done()
	linda.connect()

describe "tuplespace", ->
	it "write and read request", (done)->
		t = [0, 1, 2]
		ts.read t, (tuple, info)->
			assert.deepEqual tuple, t
			done()
		ts.write t

	it "write and watch request", (done)->
		t = [3, 4, 5]
		ts.watch t, (tuple, info)->
			assert.deepEqual tuple, t
			done()
		ts.write t
		
	it "write and take", (done)->
		ts.write ["take", 1, 2, 3]
		ts.write ["take", 4, 5, 6]
		ts.write ["take", 7, 8, 9]
		ts.take ["take"], (tuple, info)=>
			assert.deepEqual tuple, ["take", 7, 8, 9]
			ts.take ["take"], (tuple, info)=>
				assert.deepEqual tuple, ["take", 4, 5, 6]
				ts.take ["take"], (tuple, info)=>
					assert.deepEqual tuple, ["take", 1, 2, 3]
					done()

