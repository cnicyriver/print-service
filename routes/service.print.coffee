Pos = require '../lib/pos'


moment = require 'moment'

module.exports = (server)->
	server.get '/service/print/till/:ip',(req,res,next)->
		res.send status:if Pos.kickOutDrawer(req.params.ip) is true then 1 else -1
		next()

	server.get '/service/print/notice',(req,res,next)->
		process.send 'checkPrintTask'
		res.send 
			status:1
			# count:count
		# req.models.print_log.find({is_ok:0}).count (err,count)->
		# 	console.log 'recv count:',count
		# 	res.send 
		# 		status:1
		# 		count:count
		next()
	server.get '/service/print/query/:ip',(req,res,next)->
		res.send status:Pos.query(req.params.ip)
		next()

	server.get '/service/print/notice1',(req,res,next)->
		a = 1
		console.log a.test.op