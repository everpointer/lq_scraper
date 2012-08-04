jsdom = require "jsdom"
$ = require "jQuery"
request = require "request"

# 抓取点评宁波站搜索结果url前缀，加上query参数即可
# 只返回第1页的数据，每页最多显示15条数据
nb_search_url = "http://www.dianping.com/search/keyword/11/0_"
page_size = 15

exports.fetch_shops = (title, callback) ->
    if title is ""
        callback "lack of arg: 'title'!"
        return
    shops = []
    request
        url: nb_search_url + encodeURIComponent(title.trim())
        headers:             
            "User-Agent" : "Mozilla/5.0 (X11; U; Linux i686; zh-CN; rv:1.9.1.2) Gecko/20090803 Fedora/3.5.2-2.fc11 Firefox/3.5.2"
        (error, response, body) ->
            if !error && response.statusCode is 200
                # document = jsdom.jsdom body
                # xpathresult = document.evaluate('//*[@id="searchlist"]/dl', document,null, 4,null)
                # searchList = xpathresult.iterateNext()
                console.log "search title:"+title
                jq_doc = $(body)
                searchList = $(jq_doc.find("#searchList dl")[0]).children("dd")

                if (!searchList || searchList.length is 0)
                    callback "page scraping error: no shop list elements!"
                    return
                for shop in searchList
                    shop = parse_db_search_result shop
                    shops.push shop
                callback null, shops
            else
                callback error

parse_db_search_result = (shop) ->
    result = {}
    jq_shop = $(shop)
    # 解析shop fetch的结果
    # parse shop rate
    rate_span = $(jq_shop.find(".remark")[0]).children("li").children("span")
    rate_class = rate_span.attr('class')
    # 店铺评分
    result.rate = parseFloat(rate_class.substr rate_class.indexOf('irr-star')+8)/10
    # 人均价格
    result.average =  parseInt($(jq_shop.find(".average")[0]).text().substr(1))
    # 店铺地址
    address_row = $(jq_shop.find(".address")[0]).text().substr(3).split("  ")
    result.address = address_row[0]
    result.phone = address_row[1]
    result.shop_name = jq_shop.find(".shopname a").attr("title")
    result.title = jq_shop.find(".shopname a").text()
    shopid_text = jq_shop.find(".shopname a").attr("href")
    result.fetch_id = shopid_text.substr shopid_text.indexOf("shop/")+5

    return result


