moment = require 'moment'
fs = require 'fs'
path = require 'path'
# 日志路径
logFolder = '../logs/'
# 日志文件名格式。会自动加上日期前缀
logFileName = '_error.txt'


# 写入日志
module.exports = (msg,callback=->)->
	logPath  = path.join __dirname , logFolder + moment(new Date()).format('YYYY-MM-DD') + logFileName
	fs.appendFile path,moment(new Date()).format('YYYY-MM-DD HH:mm:ss SSS') + ' ' + msg + '\r\n',callback