jsdom = require "jsdom"
request = require "request"
# 抓取淘宝宁波各大运营商所有商品的基本信息

# 宁波所有运营商
operators = [
    {"title":"来趣", "user_num_id":"867510228", "shop_url":"http://lqwlshfw.tmall.com"}
    {"title":"瑞淘", "user_num_id":"732279177", "shop_url":"http://rtdzshfw.tmall.com"}
    {"title":"心怡", "user_num_id":"717301792", "shop_url":"http://xyshfw.tmall.com"}
    {"title":"完美", "user_num_id":"792448220", "shop_url":"http://wmzxshfw.tmall.com"}
    {"title":"应邀", "user_num_id":"698513518", "shop_url":"http://yyshfw.tmall.com"}]
# 店铺查询商品连接结构
# http://xxx.tmall.com/search.htm?search=y&viewType=grid&orderType=_newOn&pageNum=2

# 通过 计时器 setInterval()加上状态变量来判断评论抓取是否完毕
grap_done = false
previousGrap = true
pageno = 1
page_size = 20
products = []
index = 0

# obj operator 
fetch_products = (operators, callback) ->
    return if previousGrap is false
    previousGrap = false
    # request operator's products page
    fetch_url = operators[index].shop_url + "/search.htm?search=y&viewType=grid&orderType=_newOn&pageNum="+pageno
    request
        url: fetch_url
        headers:             
            "User-Agent" : "Mozilla/5.0 (X11; U; Linux i686; zh-CN; rv:1.9.1.2) Gecko/20090803 Fedora/3.5.2-2.fc11 Firefox/3.5.2"
        encoding: "gbk"
        (error, response, body) ->
            if !error && response.statusCode is 200
                document = jsdom.jsdom(body)
                xPathResult = document.evaluate('//*[@id="J_ShopSearchResult"]/div/div[2]/ul', document,null, 4,null)
                products_ul = xPathResult.iterateNext()
                if (products_ul is null && index is operators.length-1)
                    clearInterval intervalId
                    callback null,products
                    console.log "done fetching"
                    return
                else if products_ul is null
                    console.log "done fetch "+operators[index]['title']+"'s products!"
                    pageno=1
                    index++
                    previousGrap = true
                    console.log "begin fetch "+operators[index]['title']+"'s products!"
                    return
                for product_li in products_ul.children
                    product = parse_product_li product_li
                    product.operator = operators[index]['title']
                    product.operator_id = operators[index]['user_num_id']
                    products.push product
                # console.log products
                pageno++
                if (products.length < page_size && index is operators.length-1)
                    clearInterval intervalId
                    callback null,products
                    console.log "done fetching"
                else if products.length < page_size
                    console.log "done fetch "+operators[index]['title']+"'s products!"
                    pageno=1
                    index++
                    console.log "begin fetch "+operators[index]['title']+"'s products!"
            else
                clearInterval intervalId
                callback error
            previousGrap = true

# 解析taobao 产品返回结果
parse_product_li = (product_li) ->
    $ = require 'jQuery'
    url = require "url"
    product_jq = $(product_li)
    product = {}
    # 解析出产品的各项数据
    href = product_jq.find(".item .pic a").attr("href")
    # taobao 产品长度为11位
    product_id = href.substr(href.indexOf("id=") + 3, 11)
    desc = product_jq.find(".desc a").text()

    price_text = product_jq.find(".price strong").text()
    price = parseInt(price_text.substring(0, price_text.indexOf("元") - 1), 10)

    sales_amount = parseInt(product_jq.find(".sales-amount em").text(), 10)

    rate_text = product_jq.find(".rating span:nth-child(1)").attr("title")
    rate = rate_text.substring(0, rate_text.indexOf("分"))

    product.href = href
    product.product_id = product_id
    product.title = desc.trim()
    product.price = price
    product.sales_amount = sales_amount
    product.rate = rate
    return product

# execute fetching
console.log "begin fetch "+operators[0]['title']+"'s products!"
intervalId = setInterval fetch_products, 1000, operators, (error,products)->
        if (error)
            console.log error
        else
            # 将产品记录数据库
            products_ju_nb = require('./modules/products_ju_nb')
            # 指定时间同步1次，获得数据之后，不做增量比对，直接删除所有数据，重新插入
            products_ju_nb.empty_table (result)->
                if result is true
                    console.log "done empty table products_ju_nb"
                else
                    console.log "fail to empty table:"+result
                    return
            products_ju_nb.insert_products products, (result) ->
                if result is true
                    console.log "Insert products done!"
                else
                    console.log "Insert products error:" + result
# fetch_products operators[0], (products) ->
