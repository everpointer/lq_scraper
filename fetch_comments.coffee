http = require('http')
url = require('url')
fs = require('fs')
querystring = require('querystring')
fetcher = require "./fetcher.js"

# fetch_id = '18319176950'  # taobao: product_id, dianping:shop_id
# platform = 'taobao'
# page = 1
# fetch_id = '2131474'  # taobao: product_id, dianping:shop_id
# platform = 'dianping'
# page = 1
# fetcher.fetch_comments fetch_id, platform, page

http.createServer (req, res) ->
    queryStr = url.parse(req.url).query
    queryObj = querystring.parse(queryStr)
    fetch_id = queryObj['fetch_id']
    platform = queryObj['platform']
    page = parseInt(queryObj['page'])
    callback = queryObj['callback'] # callback用于jsonp
    # 获取评论
    if fetch_id && typeof fetch_id != undefined && platform && typeof platform != undefined
        fetcher.fetch_comments fetch_id, platform, page, (error, result) ->
            if !error
                res.writeHead 200, {'Content-Type':'application/json;charset=UTF-8'}
                res.end callback + "(" + (JSON.stringify result) + ");"
            else
                res.writeHead 500
                res.end "Internal Server Error!"
    else
        res.writeHead 400, {'Content-Type':'text/plain'}
        res.end "Bad Request!"
.listen(1337, '127.0.0.1')

console.log('Server running at http://127.0.0.1:1337/');