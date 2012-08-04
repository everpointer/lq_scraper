var poolModule = require('generic-pool');
exports.pool = poolModule.Pool({
  name: 'mysql',
  create: function(callback) {
    var c, mysql;
    mysql = require('mysql');
    c = mysql.createClient({
      host: 'localhost',
      port: 3306,
      user: 'root',
      password: 'ghz86377328',
      database: 'lq_verify'
    });
    return callback(c);
  },
  destroy: function(client) {
    return client.end();
  },
  max: 10,
  idleTimeoutMillis: 30000,
  log: false
});