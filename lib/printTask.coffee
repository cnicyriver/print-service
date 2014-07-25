OnlyOneTask = require './OnlyOneTask'
cluster = require 'cluster'
moment = require 'moment'
nconf = require './nconf'


module.exports = (db)->
	if cluster.isMaster
		if nconf.get 'print:autoCheckPrint'
			# 注册一个唯一任务
			checkPrintTask = OnlyOneTask.define 'checkPrintTask',(print)->
				console.log '检测打印机完成', not print
				if print 
					checkPrintTask.exec() 
					# console.log moment(new Date()).format('YYYYMMDDHHmmssSSS'),print.print_manage_id
			# 任务中断检测间隔
			checkPrintTask.crashTime = nconf.get('print:checkCrashTime') or 10000
			clearOldTask = OnlyOneTask.define 'clearOldTask'
			checkTimeoutLogsTask = OnlyOneTask.define 'checkTimeoutLogs'
			loopPrintTask = OnlyOneTask.define 'loopPrintTask',(print)->
				if print
					# console.log moment(new Date()).format('YYYY-MM-DD HH:mm:ss SSS'),'打印日志：',print.print_log_id,print.is_ok
					loopPrintTask.exec()
				else
					# console.log moment(new Date()).format('YYYY-MM-DD HH:mm:ss SSS'),'全部打印完毕'
			loopPrintTask.crashTime = 5000
			setInterval ->
				checkPrintTask.exec()
				clearOldTask.exec()
				checkTimeoutLogsTask.exec()
				loopPrintTask.exec()
			,5000
	else
		# 检测打印机任务
		OnlyOneTask.define 'checkPrintTask',(callback)->
			db.models.print_manage.getOneEarlyChecked (err,print)->
				return callback() if not print
				console.log '检测打印机',cluster.worker.id,print.printIP,print.print_manage_id
				print.queryStatus (err,print)->
					return callback(print) if print.print_status is 0
					db.models.print_log.loopFill print.print_manage_id,->
						callback(print)
		# 清除过时的日志
		OnlyOneTask.define 'clearOldTask',(callback)->
			db.models.print_log.clearOld callback
		# 检测超时的记录
		OnlyOneTask.define 'checkTimeoutLogsTask',(callback)->
			db.models.print_log.checkTimeoutLogs callback
		# 检测打印日志
		OnlyOneTask.define 'loopPrintTask',(callback)->
			db.models.print_log.loopPrint callback