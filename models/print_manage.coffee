
Pos = require '../lib/pos'
nconf = require '../lib/nconf'
orm = require 'orm'

module.exports = (db)->
	print_manage = db.define 'print_manage',
		print_manage_id : type : 'serial'
		last_checked_date: type : 'integer'
		printIP: type : 'text'
		print_status:type: 'integer'
	,
		id: 'print_manage_id'
		methods:
			# 检测打印机状态。
			# 回调参数：
			# err,print_manage
			# 错误、打印机对象
			queryStatus:(callback)->
				self = @
				@last_checked_date = new Date().getTime()/1000
				# ip为空
				@print_status =0 if not @printIP
				@save (err)=>
					return callback(err,@) if err or not @printIP
					arrStatus = Pos.query @printIP
					@print_status = if not arrStatus or arrStatus.length> 0 then 0 else 1
					@save (err)=>
						callback err,@
	# 获取一个最早检测过状态的打印机
	# 回调的参数：err,print
	print_manage.getOneEarlyChecked = (callback)->
		lastTime = parseInt (new Date().getTime() - nconf.get('print:checkTimes'))/1000 
		@find
			'or':[
				{last_checked_date:null}
				{last_checked_date:orm.lt lastTime}
				{last_checked_date:''}
			]
		.limit 1
		.order 'last_checked_date'
		.run (err,list)->
			return callback(err,null) if not list or list.length is 0
			callback err,list[0]




