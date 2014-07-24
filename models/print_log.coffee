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
					return callback(err,@) if err or not @printIP
					result = Pos.print @printIP,@print_message
					# result = Pos.print '192.168.1.222',@print_message
					beforeStauts = @is_ok
					@is_ok = if result is 0 then CONST.success else CONST.fail
					# 返回OpenError标识为打印机故障，其他则为打印失败。打印失败的不会自动补打。
					@is_ok = CONST.error if result is 'OpenError'
					@print_nums++
					console.log moment(new Date()).format('YYYYMMDDHHmmssSSS'),'进程id',cluster.worker.id,'日志id',@print_log_id,@is_ok,beforeStauts,@print_nums,result
					@save (err)=>
						callback err,@
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
	
	print_log.loopPrint = (trans_id,callback=->)->
		if not trans_id
			trans_id = Math.random()
			# moment(new Date()).format('YYYYMMDDHHmmssSSS')
			db.models.print_log.find({is_ok:0,trans_id:null})
			.each (print_log)->
				print_log.trans_id = trans_id
			.save (err)=>
				@loopPrint trans_id,callback
			return;
		@one {
			is_ok:CONST.waiting
			trans_id:trans_id
		},(err,log)=>
			# console.log '查找打印日志',err,log
			return callback() if err or not log
			log.print =>
				@loopPrint(trans_id,callback)

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
		self = @
		async.parallel
			# 正在打印但是超时的记录
			find:(cb)->
				self.find
					print_time: orm.lt lastTime
					is_ok : CONST.printing
				.each (log)->
					log.is_ok = CONST.error
				.save cb
			# 等待打印，但是已经有事务ID的记录
			find1:(cb)->
				self.find
					addtime: orm.lt lastTime
					is_ok: CONST.waiting
				.each (log)->
					log.is_ok = CONST.waiting
					log.trans_id = null
				.save cb
		,(err,result)->
			callback()






