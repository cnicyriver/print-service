
# 注册一个唯一的任务，分配给子进程来执行。子进程执行结束后通知主进程

cluster = require 'cluster'
moment = require 'moment'

taskList = {}

# 返回一个随机的工作进程
getOneRandomWorker = ->
	list = (worker for id,worker of cluster.workers)
	(list.sort -> Math.random() < 0.5)[0]

# 消息格式：
# msg:json对象属性：
# taskName:任务名称
# result:子进程处理的结果作为该参数传递给主进程
# type : 'run'/'complete'/'exec'
# 	run: 主-》子
# 	complete：子-》主
# 	exec：子-》主
# 


# 挂上消息钩子
if cluster.isMaster
	cluster.on 'listening',(worker,address)->
		worker.on 'message',(msg)->
			# console.log '主进程接收到消息'
			if typeof msg is 'object' and OnlyOneTask[msg.taskName]
				if msg.type is 'exec'
					OnlyOneTask[msg.taskName].exec()
				else if msg.type is 'complete'
					OnlyOneTask[msg.taskName].status = false
					OnlyOneTask[msg.taskName].callback(msg.result)
else
	process.on 'message',(msg)->
		# console.log moment(new Date()).format('YYYYMMDDHHmmssSSS'),'子进程',cluster.worker.id,'接收到消息',msg.taskName
		if typeof msg is 'object' and OnlyOneTask[msg.taskName] and msg.type is 'run'
			OnlyOneTask[msg.taskName].run()


Task = (@name)->
Task.prototype = 
	# 任务名称，both master and worker
	name : ''
	# 要执行的任务，for worker
	task: ->
		process.send @name
	# 子进程成功后的回调，for master
	callback: ->
	# 最后一次执行时间，for master
	lastExecTime: new Date()
	# 任务状态，for master
	status : false
	# 任务中断检测间隔，默认10秒，for master
	crashTime : 10000
	# for master
	exec : ->
		# console.log @name,@status,@crashTime,@lastExecTime
		return if @status and (new Date() - @lastExecTime < @crashTime)
		@status = true
		@lastExecTime = new Date()
		getOneRandomWorker().send 
			taskName:@name
			type: 'run'
	# for worker
	run : ->
		@task (result)=>
			process.send 
				taskName:@name
				type: 'complete'
				result: result
	# 设置任务，for worker
	setTask:(task)->
		@task = task if task
	# 设置子进程完成后的回调，for master
	setComplete : (task)->
		@callback = task if task

OnlyOneTask = 
	# both worker and master
	define: (name,task)->
		if cluster.isMaster
			@[name] = new Task(name)
			@[name].setComplete task
		else
			@[name] = new Task(name)
			@[name].setTask task
		@[name]

module.exports = OnlyOneTask
