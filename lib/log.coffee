moment = require 'moment'
fs = require 'fs'
# 日志路径
logFolder = '../logs/'
# 日志文件名格式。会自动加上日期前缀
logFileName = '_error.txt'


# 写入日志
module.exports = (msg,callback=->)->
	path  = logFolder + moment(new Date()).format('YYYY-MM-DD') + logFileName
	console.log path,123123123123123
	fs.appendFile path,moment(new Date()).format('YYYYMMDDHHmmssZ') + ' ' + msg + '\r\n',callback