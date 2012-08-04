var pool = require('./mysql').pool;

exports.get_products = function(params, result_cb) {
   // acquire connection - callback function is called
    // once a resource becomes available
    var platform = params.platform;
    pool.acquire(function(err, client) {
        if (err) {
            // handle error - this is generally the err from your
            // factory.create function
            console.log(err);
        }
        else {
            var sql = "";
            if (platform === "taobao")
            {
                sql = "SELECT * FROM products_ju_nb ";
                if (typeof(params.title) !== void 0 && params.title !== "" )
                    sql += "WHERE title like '%"+params.title+"%'";
            }
            client.query(sql, [], function(err, rows, fields) {
                // return object back to pool
                if (err) {
                    console.log(err);
                } else {
                   result_cb(filter_rows(platform, rows));
                }
                pool.returnToPool(client);
            });
        }
    });
};

function filter_rows(platform, rows)
{
    var i, len;
    var result = [];
    if (platform === "taobao")
    {
        for ( i =0, len = rows.length; i < len; i++)
        {
            result.push({
                'title':rows[i]['operator']+"--"+rows[i]['title'],
                'fetch_id':rows[i]['product_id'],
                'operator_id':rows[i]['operator_id'],
                'href':rows[i]['href'],
                'price':rows[i]['price'],
                'sales_amount':rows[i]['sales_amount'],
                'rate':rows[i]['rate']
            });
        }
    } else if (platform === "dianping") {
        return null;
    } else {
        return null;
    }
    return result;
}

