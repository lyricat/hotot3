defaultColumns = [
    {
        slot_name: ''
        serv: 'weibo'
        name: 'home'
        type: 'home'
        display_name: 'Home'
        title: 'Home'
        icon_name: 'mono-icon-home'
        singleton: true
        update_interval: 120
        auto_refresh: true
        notification: false
        with_sound: false
        params: []
        mute: []
    },
    {
        slot_name: ''
        serv: 'weibo'
        name: 'mention'
        type: 'mention'
        display_name: 'Mention'
        title: 'Mention'
        icon_name: 'mono-icon-at'
        singleton: true
        update_interval: 120
        auto_refresh: true
        notification: true
        with_sound: false
        params: []
        mute: []
    }
]
defaultColumnBook = {
    home: defaultColumns[0]
    mention: defaultColumns[1]
}

dynamicTypeNames = []

objChecker = (obj) ->
    return obj.constructor == Object or obj.constructor == Array

root = exports ? this

root.app.factory('ProtoWeibo', ['$http', 'Proto', 'OAuth2', 'HototCache', 'Logger', 
($http, Proto, OAuth2, HototCache, Logger) ->
    buildFn = () ->
        buildFn.messageUpdateInterval = 300

        buildFn.getDefaultColumnTypes = ->
            return [
                    {type: 'home', singleton: true, params: []}
                    {type: 'mention', singleton: true, params: []}
                ]

        buildFn.getColumnTypes = ->
            return [
                    {type: 'home', singleton: true, params: []}
                    {type: 'mention', singleton: true, params: []}
                    {type: 'search', singleton: false, params:[{name: 'Key words', placeholder_text: 'e.g. words or #hashtag', value:""}]}, 
                    {type: 'people', singleton: false, params:[{name: 'Screen name', placeholder_text: 'e.g. @HototApp', value:""}]}, 
                    {type: 'list', singleton: false, params:[{name: 'Screen name', placeholder_text: 'e.g. @HototApp', value:""}, {name: 'List name', placeholder_text: 'e.g. Listname', value:""}]},
                ]

        buildFn.buildColumn = (type, slot_name, params)->
            if defaultColumnBook.hasOwnProperty(type)
                cc = {}
                angular.extend(cc, defaultColumnBook[type])
                cc.slot_name = slot_name
                if params
                    cc.params = params
                if dynamicTypeNames.indexOf(type) != -1 
                    cc.name = "#{type}:#{Hotot.generateUUID()}"
                    cc.title = "#{cc.title}:#{params.join('/')}"
                else  # singleton
                    cc.name = type
                cc.name = cc.name.toLowerCase()
                return cc
            return null

        buildFn.formalizeColumn = (col) ->
            if defaultColumnBook.hasOwnProperty(col.type)
                colTmp = defaultColumnBook[col.type]
                col.display_name = colTmp.display_name
                col.title = colTmp.title
                col.icon_name = colTmp.icon_name
                if typeof col.mute == "undefined" then col.mute = []
            return col

        buildFn.getSettings = ()->
            return {}

        buildFn.getColumnPositionMode = (name)->
            switch name
                when 'home' then return 'id'
                when 'mention' then return 'id'
            return 'id'

        ProtoWeibo = {}
        ProtoWeibo.state = 0
        ProtoWeibo.screen_name = ''
        ProtoWeibo.username = ''
        ProtoWeibo.name = 'weibo'
        ProtoWeibo.displayName = 'Weibo'
        ProtoWeibo.authType = "oauth"
        ProtoWeibo.httpBase = 'https://weibo.com/'
        ProtoWeibo.apiBase = 'https://api.weibo.com/2/'
        ProtoWeibo.key = "3444469326"
        ProtoWeibo.secret = "525ce3250407aa3c54af70e6b4e1d262"
        ProtoWeibo.username = ''
        ProtoWeibo.password = ''
        ProtoWeibo.oauth = new OAuth2()
        ProtoWeibo.oauth.key = ProtoWeibo.key
        ProtoWeibo.oauth.secret = ProtoWeibo.secret
        ProtoWeibo.accessToken = null
        ProtoWeibo.supportStream = false
        ProtoWeibo.supportSubStream = null

        # public
        ProtoWeibo.config = (slot) ->
            ProtoWeibo.screen_name = slot.name
            ProtoWeibo.accessToken = slot.access_token
            ProtoWeibo.username = slot.username
            ProtoWeibo.password = slot.password
            ProtoWeibo.key = slot.key
            ProtoWeibo.secret = slot.secret
            ProtoWeibo.oauth.key = slot.key
            ProtoWeibo.oauth.secret = slot.secret

        ProtoWeibo.authPIN = (pin) ->
            ProtoWeibo.state = 0
            Logger.info("Auth: try to get access token")
            ProtoWeibo.oauth.get_access_token(pin,
                (result) ->
                    # console.log "ok"
                    Logger.info("Auth: get access token")
                    ProtoWeibo.accessToken = ProtoWeibo.oauth.access_token.access_token
                    ProtoWeibo.expires = ProtoWeibo.oauth.access_token.expires_in
                    ProtoWeibo.state = 1
                ,
                (xhr, textStatus, errorThrown) ->
                    Logger.info("Auth: failed to get access token")
                    ProtoWeibo.err = "Failed to get access token"
                    ProtoWeibo.state = -1
            )
            return

        ProtoWeibo.getAuthorizeURL = () ->
            return ProtoWeibo.oauth.get_auth_url()

        ProtoWeibo.verify = (ok, err) ->
            ProtoWeibo.getAccountUID((uid) ->
                ProtoWeibo.showUser(uid, ok, err)
            , err)
            return

        ProtoWeibo.handleComposerResult = (result, ok, err) ->
            if result.context and result.context.type
                if result.context.type == 'reply'
                    ProtoWeibo.createComment(result.text, result.context.id, ok, err)
            else
                if not result.has_attachment
                    ProtoWeibo.updateStatus(result.text, ok, err)
                else
                    ProtoWeibo.updateStatusWithPictures(result.text, result.attachment, ok, err)
                return

        ProtoWeibo.handleMessagerResult = (result, ok, err) ->
            return

        ProtoWeibo.handleRepost = (id, ok, err) ->
            return

        ProtoWeibo.handleUndoRepost = (id, ok, err) ->
            return

        ProtoWeibo.handleUndoFav = (id, ok, err) ->
            return

        ProtoWeibo.handleFav = (id, ok, err) ->
            return

        ProtoWeibo.handleDelete = (id, ok, err) ->
            return

        ProtoWeibo.handleColumnLoad = (opts, success, error) ->
            switch opts.type
                when 'home'
                    opts.count = 20
                    ProtoWeibo.loadHome(opts, success, error)
                when 'mention'
                    opts.count = 20
                    ProtoWeibo.loadMention(opts, success, error)
            return

        ProtoWeibo.handleColumnLoadMore = (opts, success, error) ->
            return

        ProtoWeibo.getComments = (item, success, error) ->
            return

        ProtoWeibo.getUser = (id, success, error) ->
            return

        ProtoWeibo.getRelationship = (id1, id2, success, error) ->
            return
            
        ProtoWeibo.getFollowings = (id, success, error) ->
            return

        # private
        ProtoWeibo.fakeLogin = (username, password, success, error) ->
            doLogin = (username, password, params) ->
                params['display'] = 'wap2.0'
                params['action'] = 'submit'
                params['response_type'] = 'code'
                params['redirect_uri'] = 'https://api.weibo.com/oauth2/default.html'
                params['regCallback'] = 'https%3A%2F%2Fapi.weibo.com%2F2%2Foauth2%2Fauthorize%3Fclient_id%3D3444469326%26response_type%3Dcode%26display%3Dwap2.0%26redirect_uri%3Dhttps%3A%2F%2Fapi.weibo.com%2Foauth2%2Fdefault.html%26from%3D%26with_cookie%3D'
                params['client_id'] = ProtoWeibo.oauth.key
                params["userId"] = username
                params["passwd"] = password
                params["state"] = ''
                params["from"] = ''
                params['with_cookie'] = ''
                params['x'] = -590
                params['y'] = -222
                headers = {'Referer': 'https://api.weibo.com/oauth2/authorize?client_id=3444469326&redirect_uri=https://api.weibo.com/oauth2/default.html&display=wap&forcelogin=true'}
                Logger.info("Auth: try to pass user authorization")
                $http({method: 'POST', headers: headers, url: 'https://api.weibo.com/oauth2/authorize', data: params})
                    .success((data, status, headers, config) ->
                        console.log data
                        success(pin)
                    ).error(() ->
                        error()
                    )
                return
            $http({method: 'GET', url: ProtoWeibo.oauth.get_auth_url()})
                .success((data, status, headers, config) ->
                    params = {}
                    # authorization is required
                    Logger.info("Auth: fake logou")
                    doLogin(username, password, params)
                    return                    
                ).error(() ->
                    ProtoWeibo.err = 'Failed to login your account'
                    error()
                )
            return

        ProtoWeibo.get = (url, params, onSuccess, onError) ->
            ProtoWeibo.ajax('GET', url, params, {}, onSuccess, onError)

        ProtoWeibo.post = (url, params, onSuccess, onError) ->
            ProtoWeibo.ajax('POST', url, params, {}, onSuccess, onError)
            
        ProtoWeibo.ajax = (method, url, params, headers, onSuccess, onError) ->
            params['source'] = 'Hotot'
            params['access_token'] = ProtoWeibo.accessToken
            if method == 'GET'
                url = url + '?' + Hotot.normalizeParams(params)
                params = {}
            $http({method: method, url: url, data: params})
                .success((data, status, headers, config) ->
                    Proto.successHandler(data, status, headers, config)
                    onSuccess(data, status, headers, config)
                ).error((data, status, headers, config) ->
                    if onError
                        onError(data, status, headers, config)
                    else
                        Proto.defaultErrorHandler(data, status, headers, config)
                )
            return 

        ProtoWeibo.updateStatus = (text, success, error) ->
            url = ProtoWeibo.apiBase + 'statuses/update.json'
            params =
                'status': text
            ok = (item) -> success(ProtoWeibo.convertTweet(item))            
            ProtoWeibo.post(url, params, ok, error)

        ProtoWeibo.getAccountUID = (success, error) ->
            url = ProtoWeibo.apiBase + 'account/get_uid.json'
            ok = (obj) -> success(obj.uid)
            ProtoWeibo.get(url, {}, ok, error)

        ProtoWeibo.showUser = (param, success, error) ->
            url = ProtoWeibo.apiBase + 'users/show.json'
            params = {}
            if typeof param == 'string'
                params.screen_name = param
            else if typeof param == 'number'
                params.uid = param
            ProtoWeibo.get(url, params, success, error)

        ProtoWeibo.loadHome = (opts, success, error) ->
            url = ProtoWeibo.apiBase + 'statuses/home_timeline.json'
            params = {}
            params.count = if opts.count then opts.count else 20
            if opts.position_arg1 then params.since_id = opts.position_arg1
            if opts.position_arg2 then params.max_id = opts.position_arg2
            ok = (items) -> success(ProtoWeibo.convertTweets(items))            
            ProtoWeibo.get(url, params, ok, error)

        ProtoWeibo.loadMention = (opts, success, error) ->
            url = ProtoWeibo.apiBase + 'statuses/mentions.json'
            params = {}
            params.count = if opts.count then opts.count else 20
            if opts.position_arg1 then params.since_id = opts.position_arg1
            if opts.position_arg2 then params.max_id = opts.position_arg2
            ok = (items) -> success(ProtoWeibo.convertTweets(items))            
            ProtoWeibo.get(url, params, ok, error)

        ProtoWeibo.formMedia = (tweet, text) ->
            out = []
            # for weibo's pic service
            if tweet.thumbnail_pic
                out.push({
                    type: "photo", url: tweet.original_pic, thumb_url: tweet.thumbnail_pic
                })
            else
                if tweet.retweeted_status and tweet.retweeted_status.thumbnail_pic
                    out.push({
                        type: "photo", url: tweet.retweeted_status.original_pic, thumb_url: tweet.retweeted_status.thumbnail_pic
                    })
            out = out.concat(Hotot.extractMedia(text))
            return out

        ProtoWeibo.formatText = (tweet) ->
            transferChars = (text) ->
                text = text.replace(/</g, "&lt;")
                text = text.replace(/>/g, "&gt;")
                text = text.replace(/[\r\n]\s+[\r\n]/g, '\n\n')
                text = text.replace(/\n/g, '<br/>')
                return text
            formEntityHTML = (k, entity, text) ->
                switch k
                    when 'media'
                        ret = "<a class=\"media_link\" target=\"_blank\" href=\"#{entity.expanded_url}\">#{entity.display_url}</a>"
                    when 'hashtags'
                        ret = "<a class=\"hash_link\" target=\"_blank\" href=\"#{ProtoWeibo.httpBase}/search?q=%23#{entity.text}\" title=\"##{entity.text}\">##{entity.text}</a>"
                    when 'urls'
                        ret = "<a class=\"link\" target=\"_blank\" href=\"#{entity.expanded_url}\" title=\"#{entity.expanded_url}\">#{entity.display_url}</a>"
                    when 'user_mentions'
                        ret = "<a class=\"user_link\" target=\"_blank\" href=\"#{ProtoWeibo.httpBase}/#{entity.screen_name}\" title=\"#{entity.display_name}\">@#{entity.screen_name}</a>"
                return ret

            formEntityPlain = (k, entity, text) ->
                switch k
                    when 'media'
                        ret = "#{entity.expanded_url}"
                    when 'hashtags'
                        ret = "##{entity.text}"
                    when 'urls'
                        ret = "#{entity.expanded_url}"
                    when 'user_mentions'
                        ret = "@#{entity.screen_name}"
                return ret
            entities = []
            text = ''
            convertText = ''
            if tweet.entities
                for k, v of tweet.entities
                    if v.length != 0
                        for elem in v
                            if elem.indices
                                entities.push([k, elem])
                if entities.length == 0
                    text = transferChars(tweet.text)
                    convertText = tweet.text
                else
                    textArray = []
                    cTextArray = []
                    entities.sort((a, b) ->
                        return if a[1].indices[0] < b[1].indices[0] then -1 else 1
                    )
                    lastPos = 0
                    for ent in entities
                        k = ent[0]
                        elem = ent[1]
                        textArray.push(transferChars(tweet.text.slice(lastPos, elem.indices[0])))
                        textArray.push(formEntityHTML(k, elem, tweet.text.slice(elem.indices[0], elem.indices[1])))
                        cTextArray.push(tweet.text.slice(lastPos, elem.indices[0]))
                        cTextArray.push(formEntityPlain(k, elem, tweet.text.slice(elem.indices[0], elem.indices[1])))
                        lastPos = elem.indices[1]
                    textArray.push(transferChars(tweet.text.slice(lastPos, tweet.text.length)))
                    cTextArray.push(tweet.text.slice(lastPos, tweet.text.length))
                    text = textArray.join('')
                    convertText = cTextArray.join('')
            else
                text = transferChars(tweet.text)
                convertText = tweet.text
            return [text, convertText]

        ProtoWeibo.convertTweet = (tweet) ->
            ret = ProtoWeibo.formatText(tweet)
            date = new Date(tweet.created_at)
            item = Hotot.emptyItem()
            # principal
            item.serv = 'weibo'
            item.id = tweet.idstr
            # core
            item.title = tweet.user.name
            item.URL = "http://weibo.com/#{tweet.user.screen_name}"
            item.text = ret[0]
            item.raw_text = tweet.text
            item.converted_text = ret[1]
            item.time = date.toLocaleTimeString()
            item.timestamp = date.getTime()
            # extend
            item.previous_item_id = tweet.in_reply_to_status_id
            item.next_item_id = ''
            item.recipient_id = tweet.in_reply_to_user_id
            item.recipient_name = tweet.in_reply_to_screen_name
            item.feature_pic_url = tweet.user.profile_image_url
            item.source = tweet.source
            item.entities = null
            item.repostable = true
            item.favorited = tweet.favorited
            item.reposted = tweet.retweeted
            item.deletable = tweet.user.screen_name == ProtoWeibo.screen_name
            item.has_comments = (tweet.comments_count != 0)
            item.has_quote = if tweet.retweeted_status then true else false
            if item.has_quote
                if tweet.retweeted_status.deleted
                    item.quote_text = tweet.retweeted_status.text
                else
                    item.quote_text = "@"+ tweet.retweeted_status.user.screen_name + ":" + tweet.retweeted_status.text
            # author
            item.author = 
                id: tweet.user.id.toString()
                name: tweet.user.screen_name
                display_name: tweet.user.name
                url: "http://weibo.com/#{tweet.user.screen_name}"
                avatar_url: tweet.user.profile_image_url
            # some more modifications
            if tweet.entities and tweet.entities.user_mentions
                item.mentions = tweet.entities.user_mentions
            mlist = ProtoWeibo.formMedia(tweet, item.converted_text)
            if mlist.length != 0
                item.media = mlist
                item.has_media = true
                item.media_thumb_url = mlist[0].thumb_url
            return item

        ProtoWeibo.convertTweets = (result) ->
            tweets = result.statuses
            out = []
            for tw in tweets
                out.push(ProtoWeibo.convertTweet(tw))
            return out

        return ProtoWeibo

    return buildFn
])