var pool = require('./mysql').pool;

exports.insert_products = function(products, result_cb) {
   // acquire connection - callback function is called
    // once a resource becomes available
    pool.acquire(function(err, client) {
        if (err) {
            // handle error - this is generally the err from your
            // factory.create function
            console.log(err);
            pool.returnToPool(client);
            result_cb(err);
            return;
        }
        else {
            var product;
            var insertSql;
            for(var i = 0, len = products.length; i < len; i++)
            {
                product = products[i];
                insertSql = "INSERT INTO products_ju_nb(operator,href,product_id,title,price,sales_amount,rate,operator_id) ";
                insertSql += "VALUES('"+product.operator+"','"+addslashes(product.href)+"','"+product.product_id+"'";
                insertSql += ",'"+addslashes(product.title)+"',"+product.price+","+product.sales_amount+","+product.rate+",'"+product.operator_id+"')";
                query = client.query(insertSql, function(err, result) {
                    // return object back to pool
                    // if (err) {
                    //     result_cb(err);
                    //     pool.returnToPool(client);
                    //     return;
                    // }
                });
            }
            pool.returnToPool(client);
            result_cb(true);
        }
    });
};

exports.empty_table = function(callback) {
    pool.acquire(function(err, client) {
        if (err) {
            // handle error - this is generally the err from your
            // factory.create function
            console.log(err);
            pool.returnToPool(client);
            callback(err);
            return;
        } else {
            var empty_sql = 'TRUNCATE TABLE `products_ju_nb`';
            query = client.query(empty_sql, function(err, result) {
                // return object back to pool
                // if (err) {
                //     result_cb(err);
                //     pool.returnToPool(client);
                //     return;
                // }
            });
            pool.returnToPool(client);
            callback(true);
        }
    });
};

function addslashes(str) {
    str=str.replace(/\\/g,'\\\\');
    str=str.replace(/\'/g,'\\\'');
    str=str.replace(/\"/g,'\\"');
    str=str.replace(/\0/g,'\\0');
    return str;
}