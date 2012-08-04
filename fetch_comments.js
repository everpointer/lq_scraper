// Generated by CoffeeScript 1.3.3
(function() {
  var fetcher, fs, http, querystring, url;

  http = require('http');

  url = require('url');

  fs = require('fs');

  querystring = require('querystring');

  fetcher = require("./fetcher.js");

  http.createServer(function(req, res) {
    var callback, fetch_id, page, platform, queryObj, queryStr;
    queryStr = url.parse(req.url).query;
    queryObj = querystring.parse(queryStr);
    fetch_id = queryObj['fetch_id'];
    platform = queryObj['platform'];
    page = parseInt(queryObj['page']);
    callback = queryObj['callback'];
    if (fetch_id && typeof fetch_id !== void 0 && platform && typeof platform !== void 0) {
      return fetcher.fetch_comments(fetch_id, platform, page, function(error, result) {
        if (!error) {
          res.writeHead(200, {
            'Content-Type': 'application/json;charset=UTF-8'
          });
          return res.end(callback + "(" + (JSON.stringify(result)) + ");");
        } else {
          res.writeHead(500);
          return res.end("Internal Server Error!");
        }
      });
    } else {
      res.writeHead(400, {
        'Content-Type': 'text/plain'
      });
      return res.end("Bad Request!");
    }
  }).listen(1337, '127.0.0.1');

  console.log('Server running at http://127.0.0.1:1337/');

}).call(this);