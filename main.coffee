cluster = require 'cluster'
orm = require 'orm'
moment = require 'moment'
nconf = require './lib/nconf'
restify = require 'restify'
curlify = require 'request-as-curl'
async = require 'async'
paging = require './lib/paging'


if cluster.isMaster
	require('./lib/printTask')()
	cluster.on 'exit',(worker)->
		cluster.fork()
	# 根据cpu数量开启多个子进程
	cluster.fork() for i in [1..require('os').cpus().length]
	return

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


	require('./lib/printTask') db

	require('./models/print_log') db
	require('./models/print_manage') db
	require('./routes/service.print') server



	
