cluster = require 'cluster'
orm = require 'orm'
moment = require 'moment'
nconf = require './lib/nconf'
restify = require 'restify'
curlify = require 'request-as-curl'
async = require 'async'
paging = require './lib/paging'



# 是否正在检测打印机列表状态
checkingPrintList = false
# 最后一次检测打印机列表的时间。
lastCheckingTime = null
# 是否正在处理打印日志
checkingPrintLogList = false

if cluster.isMaster
	# 注册消息处理
	regMessage = (worker)->
		worker.on 'message',(msg)->
			# 接收到子进程消息后，再回传给子进程，交给子进程处理
			# console.log worker.id,'recv msg from worker:',msg
			# 子进程检测打印机列表完毕
			return checkingPrintList = false  if msg is 'checkingPrintListComplete'
				# console.log '接收到子进程的消息'
			return checkingPrintLogList = false if msg is 'checkingPrintLogListComplete'
			getRanWorker().send msg
		worker.on 'listening',(msg)->
			checkingPrintList = false
	# 随机获取一个子进程，简单的实现负载均衡
	getRanWorker = ->
		i = j = 0
		i++ for id of cluster.workers
		j = Math.floor(Math.random() * i)
		i = 0
		for id,worker of cluster.workers
			return worker if i is j
			i++
	if nconf.get 'print:autoCheckPrint'
		# 防止子进程崩溃后检测流程中断。checkingPrintList一直处于true状态，通过验证最后一次检测时间，重新启动检测
		setInterval ->
			checkingPrintList = false if new Date() - lastCheckingTime > nconf.get 'print:checkCrashTime'
			# 只有收到子进程检测完毕消息后才会继续检测
			return if checkingPrintList
			checkingPrintList = true
			lastCheckingTime = new Date()
			# 定时检测打印机状态
			getRanWorker().send 'checkPrintStatus'
		,2000
	# 根据cpu数量开启多个子进程
	regMessage cluster.fork() for i in [1..require('os').cpus().length]
	cluster.on 'exit',(worker)->
		# 子进程挂掉之后，重开一个子进程并注册消息
		regMessage cluster.fork()
	return;

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

	# return;
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

	

