restify = require 'restify'
async = require 'async'
log = require '../lib/log'
Pos = require '../lib/pos'
nconf = require '../lib/nconf'

orm = require 'orm'




PrintTask = 
	# 开始检测等待打印的任务
	checkPrintTask:(@models)->
		@loopPrint CONST_STATUS.waiting


	# 从检测队列中取一个打印机检测状态
	checkOnePrint:(models,callback=->)->
		self = @
		lastTime = parseInt (new Date().getTime() - nconf.get('print:checkTimes'))/1000
		# check_date字段顺序排列，优先检测check_date数字最小的打印机，就不会漏掉某些打印机一直没有检测了。
		models.print_manage.find 'or':[
			{check_date:null},
			{check_date:orm.lt lastTime}
			{check_date:''}
		]
		.limit 1
		.order 'check_date'
		.run (err,prints)->
			return callback() if not prints or prints.length is 0
			self.checkPrint models,prints[0].print_manage_id,(print)->
				if print.print_status is 1 and nconf.get('print:autoPrintErrorLogs') is true
					# 打印机恢复正常工作，自动打印标识为打印机故障的记录
				else
					callback()
	# 检测单个打印机状态。传入打印机id、检测成功后回调。callback会传入最终的print对象
	checkPrint:(models,print_manage_id,callback=->)->
		models.print_manage.get print_manage_id,(err,print)->
			return callback(print) if err or not print
			print.check_date = new Date().getTime()/1000
			print.save (err)->
				if not print.printIP
					arrStatus = Pos.quert print.printIP
					print.print_status = if arrStatus.length > 0 or not arrStatus then 0 else 1
				else
					print.print_status = 0
				print.save (err)->
					callback print
	# 打印某条记录
	print:(models,print_log_id,callback=->)->
		models.print_log.get print_log_id,(err,print)->
			return callback() if not print or err
			print.is_ok = if print.printIP then CONST_STATUS.printing else CONST_STATUS.other
			print.save (err)->
				return callback() if err or not print.printIP
				result = Pos.print(print.printIP,print.print_message)
				print.is_ok = if result is 0 then CONST_STATUS.success else CONST_STATUS.fail
				#标识为打印机故障，其他则为打印失败。打印失败的不会自动补打。
				print.is_ok = CONST_STATUS.error if result is 'OpenError' 
				print.save (err)->
					return callback() if err
					callback print

	loopPrint:(status,ip,callback=->)->
		self = @
		query = is_ok:status
		query.printIP = ip if ip
		@models.print_log.one query,(err,print)->
			return callback() if not print
			if not print.printIP
				print.is_ok = CONST_STATUS.other
				return print.save (err)->
					self.loopPrint status,ip,callback
			print.is_ok = CONST_STATUS.printing
			print.save (err)->
				# 打印
				result = Pos.print(print.printIP,print.print_message)
				print.is_ok = if result is 0 then CONST_STATUS.success else CONST_STATUS.fail
				#标识为打印机故障，其他则为打印失败。打印失败的不会自动补打。
				print.is_ok = CONST_STATUS.error if result is 'OpenError' 
				# console.log 'print_log_id:',print.print_log_id,'status:',print.is_ok,'result:',result
				print.save (err)->
					self.loopPrint status,ip,callback
	

module.exports = PrintTask