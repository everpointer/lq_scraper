
/*
 * GET home page.
 */

exports.index = function(req, res){
  res.render('index', { title: 'Express' });
};

/*
 * GET comments
 * url: http://localhost:3000/comments?operator_id=867510228fetch_id=18319176950&platform=taobao&page=1
 */
exports.comments = function(req, res){
    var fetcher = require("../fetcher.js");
    var url = require("url");
    var querystring = require('querystring');
    var callback, fetch_id, page, platform, queryObj, queryStr;
    queryStr = url.parse(req.url).query;
    queryObj = querystring.parse(queryStr);
    operator_id = queryObj['operator_id'] || "";
    fetch_id = queryObj['fetch_id'];
    platform = queryObj['platform'];
    page = parseInt(queryObj['page'], 10);
    callback = queryObj['callback'];
    if (fetch_id && typeof fetch_id !== void 0 && platform && typeof platform !== void 0) {
      return fetcher.fetch_comments(operator_id, fetch_id, platform, page, function(error, result) {
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
};

/**
 * GET all products
 */
exports.products = function(req, res) {
    var url = require("url");
    var querystring = require('querystring');
    var callback, fetch_id, page, platform, queryObj, queryStr, title;
    queryStr = url.parse(req.url).query;
    queryObj = querystring.parse(queryStr);
    platform = queryObj['platform'];
    title = queryObj['title'];
    callback = queryObj['callback'];

    if (platform && typeof platform !== void 0)
    {
      if (platform === "taobao")
      {
        var products_db = require("../modules/products.js");
        var params = {"platform":platform, "title":title};
        products = products_db.get_products(params, function (result) {
            res.writeHead(200, {
                'Content-Type': 'application/json;charset=UTF-8'
            });
            res.end( callback + "(" + JSON.stringify(result) + ");");
        });
      } else if (platform === "dianping")
      {
        var fetch_dp_shops = require("../fetch_dp_nb_shops");
        shops = fetch_dp_shops.fetch_shops(title, function (error, result) {
            if (error !== null)
            {
              console.log(error);
              res.writeHead(500);
              return res.end("Internal Server Error!");
            } else {
              res.writeHead(200, {
                  'Content-Type': 'application/json;charset=UTF-8'
              });
              if (!result || result.length === 0)
              {
                res.end (callback + '( [{title:"没有找到匹配的商户:'+title+'!!!"}] )');
              } else {
                res.end( callback + "(" + JSON.stringify(result) + ");");
              }
            }
        });
      }
    } else {
      res.writeHead(400, {
        'Content-Type': 'text/plain'
      });
      return res.end("Bad Request!");
    }
};
