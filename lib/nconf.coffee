path = require 'path'
nconf = module.exports = require 'nconf'

nconf.file 'file':path.join __dirname,'../config.json'
nconf.defaults
	'mysql':
		'host':'localhost'
		'user':'root'
		'password':'sa'
		'db':'daofulin_sell'
		'charset':'utf8'
	'server':
		'port':8080
		'hostName':'api.a.com'
	'print':
		'autoCheckPrint':true # 是否开启自动检测打印机状态
		'checkTimes':1000 * 60 # 检测打印机状态间隔。单位ms
		'checkCrashTime' : 1000 * 60 * 2 #检测子进程崩溃的时间间隔。单位ms。默认2分钟检测一次。
		'autoPrintErrorLogs' : true #是否自动补打失败记录，只有开启自动检测打印机状态才有效。
		'clearOldTimes': 1000 * 3600 * 24 * 2 # 默认超过2天的打印日志会自动清除。设置为0则永不清除。单位ms。
		'printTimeout': 1000 * 10 # 打印时间超过10秒的日志自动设置为打印机故障。单位ms，设置为0则不检测。