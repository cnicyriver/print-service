# a middleware for paging


module.exports = 
	supportPagination:(req,res,next)->
		req.limit = if ( req.query !=null && req.query.limit != null && !isNaN(req.query.limit) ) then Number(req.query.limit) else 20
		req.skip = if ( req.query !=null && req.query.skip !=null && !isNaN(req.query.skip)) then Number(req.query.skip) else 0
		next()