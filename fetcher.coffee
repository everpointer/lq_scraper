fs = require("fs")
jsdom = require("jsdom")
request = require "request"

# read api configuration
configs_buf = fs.readFileSync __dirname + "/config/api.json"
configs = JSON.parse configs_buf

# async grap taobao reviews
fetch_taobao_comments = (operator_id, product_id, page = 1, callback) ->
    # 请求获得点评页面评论
    tb_confs = configs.comment.taobao
    review_result = 
        info:
            "current_page":page
            "page_size":tb_confs.page_size
        ,scoreInfo:{}
        ,rateListInfo:{}
        ,data:[]
    request 
        url: tb_confs.fetch_url + "&userNumId=" + operator_id + "&auctionNumId=" + product_id + "&currentPage=" + page
        headers: 
            "User-Agent" : "Mozilla/5.0 (X11; U; Linux i686; zh-CN; rv:1.9.1.2) Gecko/20090803 Fedora/3.5.2-2.fc11 Firefox/3.5.2"
        ,
        encoding: "gbk"
        (error, response, body) ->
            if !error && response.statusCode is 200
                index = body.indexOf "{"
                reviews = JSON.parse(body.substr(index))
                if reviews && typeof reviews isnt undefined
                    review_result.scoreInfo = reviews.scoreInfo
                    review_result.paginator = reviews.rateListInfo.paginator
                    for item in reviews.rateListInfo.rateList
                        item = filter_taobao_item item
                        review_result.data.push item
                filePath = "websites/taobao_reviews_" + product_id + ".json"
                fs.writeFile filePath, JSON.stringify review_result
                callback null,review_result
            else
                callback error

# rateListInfo structure
# "paginator": {
#             "beginIndex": 1,
#             "endIndex": 20,
#             "firstPage": 1,
#             "items": 117,
#             "itemsPerPage": 20,
#             "lastPage": 6,
#             "length": 20,
#             "offset": 0,
#             "page": 1,
#             "pages": 6
#         },

# filter taobao item result to a specific structure
filter_taobao_item = (item) ->
    new_item = {
        rateId : item.id
        nick : item.displayUserNick
        userId : item.displayUserNumId
        content : item.rateContent
        date : item.rateDate
        userVipLevel : item.userVipLevel
        userLink : item.displayUserLink
        userCreditImg : "http://pics.taobaocdn.com/newrank/"+item.displayRatePic
    }
    return new_item

# async grap dianping reviews
fetch_dp_comments = (shop_id, page = 1, callback) ->
    # 请求获得点评页面评论
    # dp_confs = configs.comment.dianping
    reviews =
        info:
            "current_page":page
            "page_size":configs.comment.dianping.page_size
        ,data:[]

    request 
        url: configs.comment.dianping.fetch_url + shop_id + "/review_all?pageno=" + page
        headers: 
            "User-Agent" : "Mozilla/5.0 (X11; U; Linux i686; zh-CN; rv:1.9.1.2) Gecko/20090803 Fedora/3.5.2-2.fc11 Firefox/3.5.2"
        ,
        (error, response, body) ->
            if !error && response.statusCode is 200
                document = jsdom.jsdom(body)
                xPathResult = document.evaluate('//*[@id="top"]/div[4]/div[1]/div/div/ul[2]/ul', document,null, 4,null)
                reviews_ul = xPathResult.iterateNext()
                for review_li in reviews_ul.children
                    review = parse_dp_review_li review_li
                    reviews.data.push review
                filepath = "websites/dianping_reviews_" + shop_id + ".json"
                fs.writeFile filepath, JSON.stringify reviews
                callback null,reviews
            else
                callback error

# parse dianping review structure into a object
parse_dp_review_li = (review_li) ->
    $ = require 'jQuery'
    review_result = {}

    review_jq = $(review_li)

    review_result.review_id = parseInt(review_jq.attr("id").substring(4))
    # user info
    user_info = $(review_li).find ".user-info"
    review_result.user_name = $(user_info).children("a").html()
    review_result.user_id  = $(user_info).children("a").attr "user-id"

    # comment rate
    comment_rst = $(review_li).find ".comment-rst"
    # 不是所有人都会打星星的评分，可能不存在，相反还是抓‘口味，环境，服务’等评论数据,一直有
    review_result.avatar = $(review_li).find("a.avatar img").attr("src")
    comment_star_span = $(comment_rst).children("span")
    if typeof comment_star_span is 'undefined' or comment_star_span.length < 1
        review_result.comment_star = "none"
    else
        comment_star_class = $(comment_star_span).attr("class")
        star_prefix = "irr-star"
        review_result.comment_star = parseInt(comment_star_class.substring(comment_star_class.indexOf(star_prefix) + star_prefix.length))/10
    # flavour, environment, service
    # 不知道为什么child 偶数才能匹配到
    comment_other = comment_rst.children("dl")
    review_result.flavour = comment_other.children("dd:nth-child(2)").text()
    review_result.environment = comment_other.children("dd:nth-child(4)").text()
    review_result.service = comment_other.children("dd:nth-child(6)").text()
    if comment_other.children("dd:nth-child(4)") && typeof comment_other.children("dd:nth-child(8)") isnt undefined
        review_result.average = comment_other.children("dd:nth-child(8)").text()

    # comment content
    comment_entry = $(review_li).find ".comment-entry"
    if  $(comment_entry).children("div.comment-type").length > 0
        review_result.comment_type = $(comment_entry).children("div.comment-type").children("span").text()
    review_result.comment_content = $(comment_entry).children("div[id$='summary']").html()

    # misc info
    comment_misc = $(review_li).find ".misc"
    review_result.comment_time = $(comment_misc).children("span.time").html()

    return review_result

exports.fetch_comments = (operator_id, fetch_id, platform, page = 1, callback) ->
    console.log fetch_id + platform
    switch platform
        when "taobao" then fetch_taobao_comments operator_id, fetch_id, page, callback
        when "dianping" then fetch_dp_comments fetch_id, page, callback
        else console.log("unknown platform:" + platform)