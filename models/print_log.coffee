Pos = require '../lib/pos'
nconf = require '../lib/nconf'
orm = require 'orm'
moment = require 'moment'
cluster = require 'cluster'
async = require 'async'

CONST = 
	waiting:0 # 0：等待打印
	success:1 # 1：打印成功
	fail:2 # 2：打印失败
	error:3 # 3：打印机故障（打印机故障排除后会自动补打）
	printing:4 # 4：正在打印（print_time字段标识了正在打印的时间，如果超时，该记录会重置为0）
	other:5 # 5：其他错误。例如打印机IP为空、要打印的内容为空等

module.exports = (db)->
	print_log = db.define 'print_log',
		print_log_id : type : 'serial'
		addtime: type : 'integer',size:11
		printIP: type : 'text'
		print_message: type : 'object'
		is_ok : type: 'integer'
		success_no : type : 'text'
		print_type : type : 'text'
		print_time : type : 'integer',size:11
		trans_id: type : 'text'
		print_nums: type : 'integer',size:11
		print_sort: type : 'integer'
	,
		id: 'print_log_id'
		methods:
			# 打印
			# 回调参数：err,this
			print:(callback=->)->
				@is_ok = if @printIP then CONST.printing else CONST.other
				@print_time = new Date().getTime() / 1000
				@trans_id = null
				@save (err)=>
					return callback(@) if err or not @printIP
					result = Pos.print @printIP,@print_message
					# result = Pos.print '192.168.1.222',@print_message
					beforeStauts = @is_ok
					@is_ok = if result is 0 then CONST.success else CONST.fail
					# 返回OpenError标识为打印机故障，其他则为打印失败。打印失败的不会自动补打。
					@is_ok = CONST.error if result is 'OpenError'
					@print_nums++
					console.log moment(new Date()).format('HH:mm:ss SSS'),'进程,日志,当前,之前,结果,打印次数',cluster.worker.id,@print_log_id,@is_ok,beforeStauts,result,@print_nums
					@save (err)=>
						callback @
	# 查找一条处于某个状态的打印日志
	print_log.getOneByStatus = (status,callback=->)->
		@one is_ok:status,callback
	# 查找一条属于某个打印机的日志
	print_log.getOneByPrintManage = (print_manage_id,callback=->)->
		@one print_id:print_manage_id,callback

	# 根据打印机ID循环检测并打印标识为打印机故障的记录
	print_log.loopFill = (print_manage_id,callback=->)->
		@find {
			print_id:print_manage_id
			is_ok:CONST.error
		}
		.each (print_log)->
			print_log.is_ok = CONST.waiting
		.save (err)=>
			@loopPrint null,callback

	# 处理所有等待打印的日志
	print_log.loopPrint = (callback=->)->
		@find 
			is_ok:CONST.waiting
		.limit 1
		.order 'print_sort'
		.run (err,list)->
			return callback() if err or not list or list.length is 0
			list[0].print callback

	# 清除超过日期的打印日志
	print_log.clearOld = (callback=->)->

		clearTimes = nconf.get 'print:clearOldTimes'
		return callback() if clearTimes is 0
		lastTime = (new Date().getTime() - clearTimes)/1000
		@find addtime:orm.lt lastTime
		.remove callback

	# 检测打印超时的日志，设置为打印机故障
	print_log.checkTimeoutLogs = (callback=->)->
		timeOut = nconf.get 'print:printTimeout'
		return callback() if timeOut is 0
		lastTime = (new Date().getTime() - timeOut)/1000
		@find
			print_time: orm.lt lastTime
			is_ok : CONST.printing
		.each (log)->
			log.is_ok = CONST.waiting
		.save callback






