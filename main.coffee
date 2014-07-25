cluster = require 'cluster'
orm = require 'orm'
moment = require 'moment'
nconf = require './lib/nconf'
restify = require 'restify'
curlify = require 'request-as-curl'
async = require 'async'
paging = require './lib/paging'
OnlyOneTask = require './lib/OnlyOneTask'



if cluster.isMaster
	if nconf.get 'print:autoCheckPrint'
		# 注册一个唯一任务
		printTask = OnlyOneTask.define 'printTask',(print)->
			if print 
				printTask.exec() 
				console.log print.print_manage_id
		# 任务中断检测间隔
		printTask.crashTime = nconf.get('print:checkCrashTime') or 10000
		setInterval ->
			printTask.exec()
		,2000
	# 根据cpu数量开启多个子进程
	cluster.fork() for i in [1..require('os').cpus().length]
	cluster.on 'exit',(worker)->
		cluster.fork()
	return

user = nconf.get 'mysql:user'
password = nconf.get 'mysql:password'
host = nconf.get 'mysql:host'
db = nconf.get 'mysql:db'
orm.connect "mysql://#{user}:#{password}@#{host}/#{db}",(err,db)->
	if err 
		console.log 'Cannot connect to Mysql.'
		throw err
	db.settings.set 'connection.debug',true
	

	serverParams = {}
	server = restify.createServer serverParams
	server.use restify.gzipResponse()
	server.use restify.authorizationParser()
	server.use restify.bodyParser mapParams:false
	server.use restify.queryParser()
	server.use (req,res,next)->
		req.db = db
		req.models = db.models
		# console.log moment(new Date()).format('YYYYMMDDHHmmssZ') + ' ' + req.method + ' ' + req.url
		# console.log curlify req
		next()
	server.use restify.CORS()
	server.use restify.fullResponse()
	server.use paging.supportPagination
	server.on 'uncaughtException',(req,res,route,error)->
		console.log 'Uncaught exception in ' + route.method + ' ' + route.path + ':'
		console.log error
		res.send 'server error.'

	server.listen nconf.get('server:port'),->
		console.log "#{server.name} listening at #{server.url}"


	require('./models/print_log') db
	require('./models/print_manage') db
	require('./routes/service.print') server



	OnlyOneTask.define 'printTask',(callback)->
		db.models.print_log.clearOld() #清除过时的日志
		db.models.print_log.checkTimeoutLogs() #检测超时的记录
		db.models.print_log.loopPrint() #同时检测打印队列
		db.models.print_manage.getOneEarlyChecked (err,print)->
			return callback() if not print
			print.queryStatus (err,print)->
				return callback(print) if print.print_staus is 0
				db.models.print_log.loopFill print.print_manage_id,->
					callback(print)


	return;
	process.on 'message',(msg)->
		# console.log cluster.worker.id,'recv msg from master:',msg
		switch msg
			when 'checkPrintTask'
				# console.log '检测打印任务'
				# 
				# 
				# console.log 'start task',moment(new Date()).format('YYYYMMDDHHmmss SSS')
				# a = 1
				# for i in [1..10000000]
				# 	a = a * i
				# console.log 'task complete',moment(new Date()).format('YYYYMMDDHHmmss SSS')
				# process.send 'checkingPrintLogListComplete'
				# return;
				db.models.print_log.loopPrint null,->
					process.send 'checkingPrintLogListComplete'
			when 'checkPrintStatus'
				# console.log '检测打印机状态'
				db.models.print_log.clearOld() #清除过时的日志
				db.models.print_log.checkTimeoutLogs() #检测超时的记录
				db.models.print_log.loopPrint() #同时检测打印队列
				# return;
				# 检测打印机状态
				db.models.print_manage.getOneEarlyChecked (err,print)->
					return process.send 'checkingPrintListComplete' if not print
					# 检测打印机状态
					print.queryStatus (err,print)->
						# console.log '进程ID',cluster.worker.id,'检测状态结束',print.print_manage_id,print.printIP
						if print.print_status is 0
							# 打印机故障
							process.send 'checkingPrintListComplete' 
						else
							# 检测是否有可以补打的单子
							db.models.print_log.loopFill print.print_manage_id,->
								process.send 'checkingPrintListComplete' 

	

