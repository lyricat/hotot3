defaultColumns = [
    {
        slot_name: ''
        serv: 'twitter'
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
        serv: 'twitter'
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
    },
    {
        slot_name: ''
        serv: 'twitter'
        name: 'search'
        type: 'search'
        display_name: 'Search'
        title: 'Search'
        icon_name: 'mono-icon-search'
        singleton: false
        update_interval: 120
        auto_refresh: true
        notification: true
        with_sound: false
        params: []
        mute: []
    },
    {
        slot_name: ''
        serv: 'twitter'
        name: 'people'
        type: 'people'
        display_name: 'People'
        title: 'People'
        icon_name: 'mono-icon-user'
        singleton: false
        update_interval: 120
        auto_refresh: true
        notification: true
        with_sound: false
        params: []
        mute: []
    },
    {
        slot_name: ''
        serv: 'twitter'
        name: 'list'
        type: 'list'
        display_name: 'List'
        title: 'List'
        icon_name: 'mono-icon-tag'
        singleton: false
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
    search: defaultColumns[2]
    people: defaultColumns[3]
    list: defaultColumns[4]
}

dynamicTypeNames = ['search', 'people', 'list']

objChecker = (obj) ->
    return obj.constructor == Object or obj.constructor == Array

root = exports ? this

root.app.factory('ProtoTwitter', ['$http', 'Proto', 'OAuth1', 'HototCache', 'Logger', ($http, Proto, OAuth1, HototCache, Logger) ->
    buildFn = () ->
        buildFn.messageUpdateInterval = 300
        buildFn.supportMessage = true

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
                when 'incoming_message' then return 'id'
                when 'sent_message' then return 'id'
                when 'search' then return 'external_id'
            return 'id'

        ProtoTwitter = {}
        ProtoTwitter.state = 0
        ProtoTwitter.screen_name = ''
        ProtoTwitter.name = 'twitter'
        ProtoTwitter.displayName = 'Twitter'
        ProtoTwitter.authType = "oauth"
        ProtoTwitter.httpBase = 'https://twitter.com/'
        ProtoTwitter.apiBase = 'https://api.twitter.com/1.1/'
        ProtoTwitter.signApiBase = 'https://api.twitter.com/1.1/'
        ProtoTwitter.searchApiBase = 'https://twitter.com/phoenix_search.phoenix'
        ProtoTwitter.uploadApiBase = 'https://upload.twitter.com/1.1/'
        ProtoTwitter.key = "nYvvlKCjRBdm71An5JoFTg"
        ProtoTwitter.secret = "vt8Dw8a4cnrubcm9E0Zny72YMoFwISbovDKdI77fvJ8"
        ProtoTwitter.oauth = new OAuth1()
        ProtoTwitter.oauth.key = ProtoTwitter.key
        ProtoTwitter.oauth.secret = ProtoTwitter.secret
        ProtoTwitter.accessToken = null
        ProtoTwitter.supportStream = true
        ProtoTwitter.supportSubStream =
            home: true
            mention: true
            message: true

        # public
        ProtoTwitter.config = (slot) ->
            ProtoTwitter.screen_name = slot.name
            ProtoTwitter.accessToken = slot.access_token
            ProtoTwitter.key = slot.key
            ProtoTwitter.secret = slot.secret
            ProtoTwitter.oauth.key = slot.key
            ProtoTwitter.oauth.secret = slot.secret

        ProtoTwitter.auth = (username, password) ->
            ProtoTwitter.state = 0
            Logger.info("Auth: try to get auth_url")
            ProtoTwitter.oauth.get_request_token(
                (result) ->
                    if result == ''
                        ProtoTwitter.err = 'Network problem, maybe'
                    else
                        Logger.info("Auth: get auth_url #{ProtoTwitter.oauth.get_auth_url()}")
                        ProtoTwitter.fakeLogin(
                            username
                            password
                            (pin) ->
                                Logger.info("Auth: pass user authorization")
                                ProtoTwitter.oauth.get_access_token(pin,
                                    (result) ->
                                        # console.log "ok"
                                        Logger.info("Auth: get access token")
                                        ProtoTwitter.accessToken = ProtoTwitter.oauth.access_token
                                        ProtoTwitter.state = 1
                                    ,
                                    (xhr, textStatus, errorThrown) ->
                                        Logger.info("Auth: failed to get access token")
                                        ProtoTwitter.err = "Failed to get access token"
                                        ProtoTwitter.state = -1
                                )
                            ,
                            () ->
                                Logger.info("Auth: failed to pass user authorization")
                                ProtoTwitter.state = -1
                        )
                (result) ->
                    Logger.info("Auth: failed to get request token")
                    ProtoTwitter.err = 'Failed to get request token'
                    ProtoTwitter.state = -1
            )
            return

        ProtoTwitter.verify = (ok, err) ->
            ProtoTwitter.verify_credentials(ok, err)

        ProtoTwitter.handleComposerResult = (result, ok, err) ->
            replyToId = null
            if result.context and result.context.type
                if result.context.type == 'reply'
                    replyToId = result.context.id

            if not result.has_attachment
                ProtoTwitter.updateStatus(result.text, replyToId, ok, err)
            else
                ProtoTwitter.updateStatusWithPictures(result.text, replyToId, result.attachment, ok, err)
            return

        ProtoTwitter.handleMessagerResult = (result, ok, err) ->
            if result.text and result.recipient
                ProtoTwitter.postMessage(result.text, {screen_name: result.recipient.name}, ok, err)
            return

        ProtoTwitter.handleUpdateProfile = (profile, ok, err) ->
            ProtoTwitter.updateProfile(profile, ok, err)
            return

        ProtoTwitter.handleUpdateAvatar = (avatar, ok, err) ->
            ProtoTwitter.updateAvatar(avatar, ok, err)
            return

        ProtoTwitter.handleRepost = (id, ok, err) ->
            ProtoTwitter.retweet(id, ok, err)
            return

        ProtoTwitter.handleUndoRepost = (id, ok, err) ->
            ProtoTwitter.destroyRetweet(id, ok, err)
            return

        ProtoTwitter.handleUndoFav = (id, ok, err) ->
            ProtoTwitter.destroyFavorite(id, ok, err)
            return

        ProtoTwitter.handleFav = (id, ok, err) ->
            ProtoTwitter.createFavorite(id, ok, err)
            return

        ProtoTwitter.handleDelete = (id, ok, err) ->
            ProtoTwitter.destroyStatus(id, ok, err)
            return

        ProtoTwitter.handleFollow = (screen_name, ok, err) ->
            ProtoTwitter.follow(screen_name, ok, err)
            return

        ProtoTwitter.handleUnfollow = (screen_name, ok, err) ->
            ProtoTwitter.unfollow(screen_name, ok, err)
            return

        ProtoTwitter.handleBlock = (screen_name, ok, err) ->
            ProtoTwitter.block(screen_name, ok, err)
            return

        ProtoTwitter.handleUnblock = (screen_name, ok, err) ->
            ProtoTwitter.unblock(screen_name, ok, err)
            return

        ProtoTwitter.handleMarkSpam = (screen_name, ok, err) ->
            ProtoTwitter.markSpam(screen_name, ok, err)
            return

        ProtoTwitter.handleColumnLoad = (opts, success, error) ->
            switch opts.type
                when 'home'
                    opts.count = 20
                    ProtoTwitter.loadHome(opts, success, error)
                when 'mention'
                    opts.count = 20
                    ProtoTwitter.loadMention(opts, success, error)
                when 'incoming_message'
                    opts.count = 100
                    ProtoTwitter.loadIncomingMessage(opts, success, error)
                when 'sent_message'
                    opts.count = 100
                    ProtoTwitter.loadSentMessage(opts, success, error)
                when 'people'
                    opts.count = 20
                    ProtoTwitter.loadUserTimeline(opts, success, error)
                when 'list'
                    opts.count = 20
                    ProtoTwitter.loadListStatus(opts, success, error)
                when 'search'
                    opts.count = 20
                    ProtoTwitter.loadSearchResult(opts, success, error)
                when 'favorite'
                    opts.count = 20
                    ProtoTwitter.loadFavorite(opts, success, error)
                when 'following'
                    ProtoTwitter.loadFollowing(opts, success, error)
                when 'follower'
                    ProtoTwitter.loadFollower(opts, success, error)
            return

        ProtoTwitter.handleColumnLoadMore = (opts, success, error) ->
            switch opts.type
                when 'home'
                    opts.count = 20
                    ProtoTwitter.loadHome(opts, success, error)
                when 'mention'
                    opts.count = 20
                    ProtoTwitter.loadMention(opts, success, error)
                when 'people'
                    opts.count = 20
                    ProtoTwitter.loadUserTimeline(opts, success, error)
                when 'list'
                    opts.count = 20
                    ProtoTwitter.loadListStatus(opts, success, error)
                when 'search'
                    opts.count = 20
                    ProtoTwitter.loadSearchResult(opts, success, error)
                when 'favorite'
                    opts.count = 20
                    ProtoTwitter.loadFavorite(opts, success, error)
            return            

        ProtoTwitter.getComments = (item, success, error) ->
            comments = []
            keys = ["#{ProtoTwitter.name}/#{ProtoTwitter.screen_name}/home", "#{ProtoTwitter.name}/#{ProtoTwitter.screen_name}/mention"]
            getComment = (key, id, callback) ->
                ret = HototCache.findById(keys, id)
                comment = ret[0]
                if comment
                    callback(comment)
                else
                    ProtoTwitter.showTweet(id, (comment) -> 
                            callback(comment)
                        , () ->
                            callback(null)
                    )
                return
            appendComment = (comment) ->
                if comment
                    comments.push(comment)
                    if comment.has_comments
                        getComment(keys, comment.previous_item_id, appendComment)
                    else
                        success(comments)
                else
                    error(comments)
                return
            getComment(keys, item.previous_item_id, appendComment)

        ProtoTwitter.getUser = (screen_name, success, error) ->
            ProtoTwitter.showUser(screen_name, success, error)

        ProtoTwitter.getRelationship = (screen_name1, screen_name2, success, error) ->
            ProtoTwitter.showRelationship(screen_name1, screen_name2, success, error)

        ProtoTwitter.getFollowings = (screen_name, success, error) ->
            ProtoTwitter.getFollowingIds(screen_name, success, error)

        # privated
        ProtoTwitter.fakeLogout = (html, success, error) ->
            rAuthToken = new RegExp('name="authenticity_token".*?value="(.*)?"', "g")
            rReferer = new RegExp('name="referer".*?value="(.*)?"', 'g')
            mAuthToken = rAuthToken.exec(html)
            mReferer = rReferer.exec(html)
            params = {'authenticity_token': mAuthToken[1], 'referer': mReferer[1], '_method': 'delete'}
            # console.log mAct, mAuthToken, mOAuthToken
            # sign out
            $http({method: 'POST', url: 'https://twitter.com/intent/session', data: params})
                .success((data, status, headers, config) ->
                    success(data)
                ).error(() ->
                    ProtoTwitter.err = 'Failed to sign out'
                    error()
                )

        ProtoTwitter.fakeLogin = (username, password, success, error) ->
            rAuthToken = new RegExp('name="authenticity_token".*?value="(.*)?"', "g")
            rOAuthToken = new RegExp('name="oauth_token".*?value="(.*)?"', "g")
            rReferer = new RegExp('name="referer".*?value="(.*)?"', 'g')
            rCheckSignForm = new RegExp('fieldset class="sign-in"', "g")
            doLogin = (username, password, params) ->
                rPin = new RegExp('<code>(\\d+)<\/code>', 'g')
                params["session[username_or_email]"] = username
                params["session[password]"] = password
                params["remember_me"] = '0'
                Logger.info("Auth: try to pass user authorization")
                $http({method: 'POST', url: 'https://api.twitter.com/oauth/authorize', data: params})
                    .success((data, status, headers, config) ->
                        mPin = rPin.exec(data)
                        if mPin == null
                            ProtoTwitter.err = 'Failed to get PIN code, may be caused by invalid user name or password'
                            error()
                        else
                            pin = mPin[1]
                            # console.log(pin)
                            success(pin)
                    ).error(() ->
                        ProtoTwitter.err = 'Failed to get PIN code'
                        error()
                    )
            $http({method: 'GET', url: ProtoTwitter.oauth.get_auth_url()})
                .success((data, status, headers, config) ->
                    mAuthToken = rAuthToken.exec(data)
                    mOAuthToken = rOAuthToken.exec(data)
                    mCheckSignForm = rCheckSignForm.exec(data)
                    if mAuthToken == null or mOAuthToken == null
                        ProtoTwitter.err = "Failed to parse page, please try to sign in your account manually."
                        error()
                        return
                    params = {'authenticity_token': mAuthToken[1], 'oauth_token': mOAuthToken[1]}
                    # authorization is required
                    if mCheckSignForm != null
                        doLogin(username, password, params)
                    else
                        ProtoTwitter.fakeLogout(data, 
                            (data)-> 
                                Logger.info("Auth: fake logou")
                                doLogin(username, password, params)
                            ,
                            () ->
                                ProtoTwitter.err = 'Failed to sign out'
                                error()
                        )
                    return                    
                ).error(() ->
                    ProtoTwitter.err = 'Failed to login your account'
                    error()
                )
            return

        ProtoTwitter.get = (url, params, onSuccess, onError) ->
            ProtoTwitter.ajax('GET', url, params, {'X-PHX': 'true'}, onSuccess, onError)

        ProtoTwitter.post = (url, params, onSuccess, onError) ->
            ProtoTwitter.ajax('POST', url, params, {}, onSuccess, onError)
            
        ProtoTwitter.ajax = (method, url, params, headers, onSuccess, onError) ->
            params['source'] = 'Hotot';
            signUrl = if ProtoTwitter.useSameSignApiBase then url else url.replace(ProtoTwitter.apiBase, ProtoTwitter.signApiBase)

            if ProtoTwitter.authType == 'oauth'
                signedParams = ProtoTwitter.oauth.form_signed_params(signUrl, ProtoTwitter.accessToken, method, params, method == 'POST')
                if method == 'GET'
                    url = url + '?' + signedParams
                    params = {}
                else
                    params = signedParams
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

        ProtoTwitter.verify_credentials = (success, error) ->
            url = ProtoTwitter.apiBase + 'account/verify_credentials.json'
            params =
                'include_entities': '1'
            ok = (me) -> success(ProtoTwitter.convertUser(me))
            ProtoTwitter.get(url, params, ok, error)

        ProtoTwitter.loadHome = (opts, success, error) ->
            url = ProtoTwitter.apiBase + 'statuses/home_timeline.json'
            params =
                'include_entities': '1'
            params.count = if opts.count then opts.count else 20
            if opts.position_arg1 then params.since_id = opts.position_arg1
            if opts.position_arg2 then params.max_id = opts.position_arg2
            ok = (items) -> success(ProtoTwitter.convertTweets(items))            
            ProtoTwitter.get(url, params, ok, error)

        ProtoTwitter.loadMention = (opts, success, error) ->
            url = ProtoTwitter.apiBase + 'statuses/mentions_timeline.json'
            params =
                'include_entities': '1'
            params.count = if opts.count then opts.count else 20
            if opts.position_arg1 then params.since_id = opts.position_arg1
            if opts.position_arg2 then params.max_id = opts.position_arg2
            ok = (items) -> success(ProtoTwitter.convertTweets(items))            
            ProtoTwitter.get(url, params, ok, error)

        ProtoTwitter.loadSentMessage = (opts, success, error) ->
            url = ProtoTwitter.apiBase + 'direct_messages/sent.json'
            params =
                'include_entities': '1'
            params.count = if opts.count then opts.count else 20
            ok = (items) -> if objChecker(items) then success(ProtoTwitter.convertMessages(items))
            ProtoTwitter.get(url, params, ok, error)

        ProtoTwitter.loadIncomingMessage = (opts, success, error) ->
            url = ProtoTwitter.apiBase + 'direct_messages.json'
            params =
                'include_entities': '1'
            params.count = if opts.count then opts.count else 20
            ok = (items) -> if objChecker(items) then success(ProtoTwitter.convertMessages(items))
            ProtoTwitter.get(url, params, ok, error)

        ProtoTwitter.loadUserTimeline = (opts, success, error) ->
            url = ProtoTwitter.apiBase + 'statuses/user_timeline.json'
            params =
                'screen_name': opts.params[0]
                'include_entities': '1'
                'include_rts': true
            params.count = if opts.count then opts.count else 20
            if opts.position_arg1 then params.since_id = opts.position_arg1
            if opts.position_arg2 then params.max_id = opts.position_arg2
            ok = (items) -> success(ProtoTwitter.convertTweets(items))            
            ProtoTwitter.get(url, params, ok, error)

        ProtoTwitter.loadListStatus = (opts, success, error) ->
            url = ProtoTwitter.apiBase + 'lists/statuses.json'
            params =
                'owner_screen_name': opts.params[0]
                'slug': opts.params[1]
                'include_entities': true
                'include_rts': true
            params.count = if opts.count then opts.count else 20
            if opts.position_arg1 then params.since_id = opts.position_arg1
            if opts.position_arg2 then params.max_id = opts.position_arg2
            ok = (items) -> success(ProtoTwitter.convertTweets(items))            
            ProtoTwitter.get(url, params, ok, error)

        ProtoTwitter.loadSearchResult = (opts, success, error) ->
            url = ProtoTwitter.apiBase + 'search/tweets.json'
            params =
                'q': opts.params[0]
                'include_entities': '1'
                'include_rts': true
            params.count = if opts.count then opts.count else 20
            if opts.position_arg1 then params.since_id = opts.position_arg1
            if opts.position_arg2 then params.max_id = opts.position_arg2
            ok = (results) -> success(ProtoTwitter.convertSearchResult(results))            
            ProtoTwitter.get(url, params, ok, error)

        ProtoTwitter.loadFavorite = (opts, success, error) ->
            url = ProtoTwitter.apiBase + 'favorites/list.json'
            params =
                'include_entities': '1'
            params.count = if opts.count then opts.count else 20
            if opts.position_arg1 then params.since_id = opts.position_arg1
            if opts.position_arg2 then params.max_id = opts.position_arg2
            params.screen_name = opts.params[0]
            ok = (results) -> success(ProtoTwitter.convertTweets(results))            
            ProtoTwitter.get(url, params, ok, error)

        ProtoTwitter.loadFollowing = (opts, success, error) ->
            url = ProtoTwitter.apiBase + 'friends/list.json'
            params =
                'include_entities': '1'
            if opts.position_arg1 
                params.cursor = opts.position_arg1
            else
                params.cursor = opts.position_arg2
            params.screen_name = opts.params[0]
            ok = (results) -> success(ProtoTwitter.convertUserList(results))            
            ProtoTwitter.get(url, params, ok, error)

        ProtoTwitter.loadFollower = (opts, success, error) ->
            url = ProtoTwitter.apiBase + 'followers/list.json'
            params =
                'include_entities': '1'
            if opts.position_arg1 
                params.cursor = opts.position_arg1
            else
                params.cursor = opts.position_arg2
            params.screen_name = opts.params[0]
            ok = (results) -> success(ProtoTwitter.convertUserList(results))            
            ProtoTwitter.get(url, params, ok, error)

        ProtoTwitter.updateProfile = (profile, success, error) ->
            url = ProtoTwitter.apiBase + 'account/update_profile.json'
            params =
                'name': profile.display_name
                'url': profile.raw_url
                'location': profile.location
                'description': profile.description
                'include_entities': '1'
            ok = (me) -> success(ProtoTwitter.convertUser(me))            
            ProtoTwitter.post(url, params, ok, error)

        ProtoTwitter.signAuthStr = (url) ->
            signedParams = ProtoTwitter.oauth.form_signed_params(url, ProtoTwitter.accessToken, 'POST', {}, true)
            authStr = 'OAuth oauth_consumer_key="' + signedParams.oauth_consumer_key + '"' + 
                ', oauth_signature_method="' + signedParams.oauth_signature_method + '"' + 
                ', oauth_token="' + signedParams.oauth_token + '"' + 
                ', oauth_timestamp="' + signedParams.oauth_timestamp + '"' + 
                ', oauth_nonce="' + signedParams.oauth_nonce + '"' + 
                ', oauth_version="' + signedParams.oauth_version + '"' + 
                ', oauth_signature="' + encodeURIComponent(signedParams.oauth_signature) + '"'
            return authStr

        ProtoTwitter.updateAvatar = (avatar, success, error) ->
            url = ProtoTwitter.apiBase + 'account/update_profile_image.json'
            params =
                'include_entities': '1'
            #     'image': avatar.base64_data
            # ok = (me) -> success(ProtoTwitter.convertUser(me))            
            # ProtoTwitter.post(url, params, ok, error)
            headers =
                'Authorization': ProtoTwitter.signAuthStr(url)
            avatar.name = 'image'
            ret = Hotot.encodeMultipartFormdataBlob(params, avatar)
            angular.extend(headers, ret[0])
            formData = ret[1]
            ok = (me) -> success(ProtoTwitter.convertUser(me))            
            $http({method: "POST", headers: headers, url: url, data: formData})
                .success((data, status, headers, config) ->
                    ok(data, status, headers, config)
                ).error((data, status, headers, config) ->
                    error(data, status, headers, config)
                )

        ProtoTwitter.postMessage = (text, opts, success, error) ->
            url = ProtoTwitter.apiBase + 'direct_messages/new.json'
            params =
                'text': text
            if opts.user_id
                params.user_id = opts.user_id
            else if opts.screen_name
                params.screen_name = opts.screen_name
            else
                error() 
                return
            ok = (item) -> success(ProtoTwitter.convertMessage(item))            
            ProtoTwitter.post(url, params, ok, error)
            return

        ProtoTwitter.updateStatus = (text, replyToId, success, error) ->
            url = ProtoTwitter.apiBase + 'statuses/update.json'
            params =
                'status': text
                'include_entities': '1'
            if replyToId
                params['in_reply_to_status_id'] = replyToId
            ok = (item) -> success(ProtoTwitter.convertTweet(item))            
            ProtoTwitter.post(url, params, ok, error)

        ProtoTwitter.updateStatusWithPictures = (text, replyToId, media, success, error) ->
            url = ProtoTwitter.apiBase + 'statuses/update_with_media.json'
            params =
                'status': text
                'include_entities': '1'
            if replyToId
                params['in_reply_to_status_id'] = replyToId
            # angular.extend(params, signedParams)

            headers =
                'Authorization': ProtoTwitter.signAuthStr(url)

            media.name = 'media[]'
            ret = Hotot.encodeMultipartFormdataBlob(params, media)
            angular.extend(headers, ret[0])
            formData = ret[1]

            ok = (item) -> success(ProtoTwitter.convertTweet(item)) 
            # Notice
            # 1. dont append signed params to url, use authorization header.
            # 2. twitter current only accept blob octet-stream, base64 based picture is not acceptable. 
            $http({method: "POST", headers: headers, url: url, data: formData})
                .success((data, status, headers, config) ->
                    ok(data, status, headers, config)
                ).error((data, status, headers, config) ->
                    error(data, status, headers, config)
                )

        ProtoTwitter.destroyStatus = (id, success, error) ->
            url = ProtoTwitter.apiBase + "statuses/destroy/#{id}.json"
            ok = (item) -> success(ProtoTwitter.convertTweet(item))
            ProtoTwitter.post(url, {}, ok, error)

        ProtoTwitter.retweet = (id, onSuccess, onError) ->
            url = ProtoTwitter.apiBase + "statuses/retweet/#{id}.json"
            params = {}
            ok = (item) -> 
                onSuccess(ProtoTwitter.convertEvent(ProtoTwitter.tweet2Event('retweet', item)))            
            ProtoTwitter.post(url, params, ok, onError)
        
        ProtoTwitter.destroyRetweet = (id, success, error) ->
            url = ProtoTwitter.apiBase + "statuses/destroy/#{id}.json"
            ok = (item) -> success(ProtoTwitter.convertEvent(ProtoTwitter.tweet2Event('retweet', item)))
            ProtoTwitter.post(url, {}, ok, error)

        ProtoTwitter.createFavorite = (id, onSuccess, onError) ->
            url = ProtoTwitter.apiBase + "favorites/create.json"
            params = {id: id}
            ok = (item) -> onSuccess(ProtoTwitter.convertTweet(item))            
            ProtoTwitter.post(url, params, ok, onError)

        ProtoTwitter.destroyFavorite = (id, onSuccess, onError) ->
            url = ProtoTwitter.apiBase + "favorites/destroy.json"
            params = {id: id}
            ok = (item) -> onSuccess(ProtoTwitter.convertTweet(item))            
            ProtoTwitter.post(url, params, ok, onError)

        ProtoTwitter.follow = (screen_name, success, error) ->
            url = ProtoTwitter.apiBase + "friendships/create.json"
            params = {}
            params.screen_name = screen_name
            ok = (item) -> success(ProtoTwitter.convertUser(item))            
            ProtoTwitter.post(url, params, ok, error)

        ProtoTwitter.unfollow = (screen_name, success, error) ->
            url = ProtoTwitter.apiBase + "friendships/destroy.json"
            params = {}
            params.screen_name = screen_name
            ok = (item) -> success(ProtoTwitter.convertUser(item))            
            ProtoTwitter.post(url, params, ok, error)

        ProtoTwitter.block = (screen_name, success, error) ->
            url = ProtoTwitter.apiBase + "blocks/create.json"
            params = {}
            params.screen_name = screen_name
            ok = (item) -> success(ProtoTwitter.convertUser(item))            
            ProtoTwitter.post(url, params, ok, error)

        ProtoTwitter.unblock = (screen_name, success, error) ->
            url = ProtoTwitter.apiBase + "blocks/destroy.json"
            params = {}
            params.screen_name = screen_name
            ok = (item) -> success(ProtoTwitter.convertUser(item))            
            ProtoTwitter.post(url, params, ok, error)

        ProtoTwitter.markSpam = (screen_name, success, error) ->
            url = ProtoTwitter.apiBase + "users/report_spam.json"
            params = {}
            params.screen_name = screen_name
            ok = (item) -> success(ProtoTwitter.convertUser(item))            
            ProtoTwitter.post(url, params, ok, error)

        ProtoTwitter.showTweet = (id, onSuccess, onError) ->
            url = ProtoTwitter.apiBase + "statuses/show/#{id}.json"
            params = 
                'include_entities': '1'
            ok = (item) -> onSuccess(ProtoTwitter.convertTweet(item))            
            ProtoTwitter.get(url, params, ok, onError)

        ProtoTwitter.showUser = (screen_name, onSuccess, onError) ->
            url = ProtoTwitter.apiBase + "users/show.json"
            params = 
                'include_entities': '1'
            params.screen_name = screen_name
            ok = (item) -> onSuccess(ProtoTwitter.convertUser(item))          
            ProtoTwitter.get(url, params, ok, onError)

        ProtoTwitter.showRelationship = (screen_name1, screen_name2, success, error) ->
            url = ProtoTwitter.apiBase + "friendships/show.json"
            params = 
                'include_entities': '1'
            params.source_screen_name = screen_name1
            params.target_screen_name = screen_name2
            ok = (rel) -> 
                rel = rel.relationship
                relation = Hotot.RELATIONSHIP.STRANGER
                if rel.source.following and rel.source.followed_by
                    relation = Hotot.RELATIONSHIP.FRIENDS
                else if rel.source.following and not rel.source.followed_by
                    relation = Hotot.RELATIONSHIP.FOLLOWING
                else if not rel.source.following and rel.source.followed_by
                    relation = Hotot.RELATIONSHIP.FOLLOWED
                else if rel.source.blocking
                    relation = Hotot.RELATIONSHIP.BLOCKED
                else if rel.source.marked_spam
                    relation = Hotot.RELATIONSHIP.MARKED_SPAM
                else
                    relation = Hotot.RELATIONSHIP.STRANGER
                success(relation)            
                return
            ProtoTwitter.get(url, params, ok, error)

        ProtoTwitter.getFollowingIds = (screen_name, success, error) ->
            url = ProtoTwitter.apiBase + "friends/ids.json"
            params = 
                'include_entities': '1'
                'stringify_ids': 'true'
                'count': 2000
            params.screen_name = screen_name
            ok = (ret) -> success(ret.ids)
            ProtoTwitter.get(url, params, ok, error)

        ProtoTwitter.convertUser = (_user) ->
            user = Hotot.emptyUser()
            user.id = _user.id_str
            user.name = _user.screen_name
            user.display_name = _user.name
            user.direct_url = "https://twitter.com/#{_user.screen_name}"
            if _user.entities and _user.entities.url
                user.url = ProtoTwitter.formEntities(_user.entities.url, _user.url)[0]
            else 
                if _user.url != null
                    user.url = "<a class=\"link\" target=\"_blank\" href=\"#{_user.url}\" title=\"#{_user.url}\">#{_user.url}</a>"
                else
                    user.url = null
            if user.url != null
                m = user.url.match(/<.*>(.*)<\/.*>/)
                if m.length > 1
                    user.raw_url = m[1]
            if _user.entities and _user.entities.description
                user.description = ProtoTwitter.formEntities(_user.entities.description, _user.description)[0]
            else
                user.description = _user.description
            user.location = _user.location
            user.avatar_url = _user.profile_image_url
            user.background_url = _user.profile_background_image_url
            user.protected = _user.protected
            user.following = _user.following
            user.statuses_count = _user.statuses_count
            user.friends_count = _user.friends_count
            user.followers_count = _user.followers_count
            user.favorites_count = _user.favourites_count
            return user

        ProtoTwitter.formMedia = (tweet, text) ->
            out = []
            # for twitter's pic service
            if tweet.entities
                if tweet.entities.hasOwnProperty('media')
                    for ent in tweet.entities.media
                        out.push({
                            type: "photo",
                            url: ent.media_url,
                            thumb_url: ent.media_url + ":thumb"
                        })
            out = out.concat(Hotot.extractMedia(text))
            return out

        ProtoTwitter.formEntities = (_entities, _text) ->
            if _text == null or _text == undefined
                _text = ''
            formEntityHTML = (k, entity) ->
                switch k
                    when 'media'
                        ret = "<a class=\"media_link\" target=\"_blank\" href=\"#{entity.expanded_url}\">#{entity.display_url}</a>"
                    when 'hashtags'
                        ret = "<a class=\"hash_link\" target=\"_blank\" href=\"#{ProtoTwitter.httpBase}/search?q=%23#{entity.text}\" title=\"##{entity.text}\">##{entity.text}</a>"
                    when 'urls'
                        if entity.display_url
                            ret = "<a class=\"link\" target=\"_blank\" href=\"#{entity.expanded_url}\" title=\"#{entity.expanded_url}\">#{entity.display_url}</a>"
                        else
                            ret = "<a class=\"link\" target=\"_blank\" href=\"#{entity.url}\" title=\"#{entity.url}\">#{entity.url}</a>"
                    when 'user_mentions'
                        ret = "<a class=\"user_link\" href=\"hotot://people/#{entity.screen_name}\" title=\"#{entity.name}\">@#{entity.screen_name}</a>"
                return ret

            formEntityPlain = (k, entity) ->
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
            text = ''
            convertText = ''
            entities = []
            for k, v of _entities
                if v.length != 0
                    for elem in v
                        if elem.indices
                            entities.push([k, elem])
            if entities.length == 0
                text = ProtoTwitter.transferChars(_text)
                convertText = _text
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
                    textArray.push(ProtoTwitter.transferChars(_text.slice(lastPos, elem.indices[0])))
                    textArray.push(formEntityHTML(k, elem, _text.slice(elem.indices[0], elem.indices[1])))
                    cTextArray.push(_text.slice(lastPos, elem.indices[0]))
                    cTextArray.push(formEntityPlain(k, elem, _text.slice(elem.indices[0], elem.indices[1])))
                    lastPos = elem.indices[1]
                textArray.push(ProtoTwitter.transferChars(_text.slice(lastPos, _text.length)))
                cTextArray.push(_text.slice(lastPos, _text.length))
                text = textArray.join('')
                convertText = cTextArray.join('')
            return [text, convertText]

        ProtoTwitter.transferChars = (text) ->
            ret = text.replace(/</g, "&lt;")
            ret = ret.replace(/>/g, "&gt;")
            ret = ret.replace(/[\r\n]\s+[\r\n]/g, '\n\n')
            ret = ret.replace(/\n/g, '<br/>')
            return ret

        ProtoTwitter.formatText = (tweet) ->
            if tweet.entities
                ret = ProtoTwitter.formEntities(tweet.entities, tweet.text)
                text = ret[0]
                convertText = ret[1] 
            else
                text = ProtoTwitter.transferChars(tweet.text)
                convertText = tweet.text
            return [text, convertText]

        ProtoTwitter.convertTweet = (tweet) ->
            ret = ProtoTwitter.formatText(tweet)
            date = new Date(tweet.created_at)
            item = Hotot.emptyItem()
            # principal
            item.serv = 'twitter'
            item.id = tweet.id_str
            # core
            item.title = tweet.user.name
            item.URL = "https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id_str}"
            item.text = ret[0]
            item.raw_text = tweet.text
            item.converted_text = ret[1]
            item.time = date.toLocaleTimeString()
            item.timestamp = date.getTime()
            # extend
            item.previous_item_id = tweet.in_reply_to_status_id_str
            item.next_item_id = ''
            item.recipient_id = tweet.in_reply_to_user_id_str
            item.recipient_name = tweet.in_reply_to_screen_name
            item.feature_pic_url = tweet.user.profile_image_url
            item.source = tweet.source
            item.entities = tweet.entities
            item.repostable = (not tweet.user.protected and tweet.user.screen_name != ProtoTwitter.screen_name)
            item.favorited = tweet.favorited
            item.reposted = tweet.retweeted
            item.deletable = tweet.user.screen_name == ProtoTwitter.screen_name
            item.has_comments = (tweet.in_reply_to_status_id_str != null)
            # author
            item.author = ProtoTwitter.convertUser(tweet.user)
            # some more modifications
            if tweet.entities and tweet.entities.user_mentions
                # @TODO mentions should be user list
                item.mentions = tweet.entities.user_mentions
            mlist = ProtoTwitter.formMedia(tweet, item.converted_text)
            if mlist.length != 0
                item.media = mlist
                item.has_media = true
                item.media_thumb_url = mlist[0].thumb_url
            return item

        ProtoTwitter.convertTweets = (tweets) ->
            out = []
            for tw in tweets
                if tw.retweeted_status and tw.retweeted_status != undefined
                    out.push(ProtoTwitter.convertEvent(ProtoTwitter.tweet2Event('retweet', tw)))
                else
                    out.push(ProtoTwitter.convertTweet(tw))
            return out

        ProtoTwitter.convertUserList = (ret) ->
            out = []
            for usr in ret.users
                out.push(ProtoTwitter.convertUser(usr))
            out.next_cursor = ret.next_cursor_str
            out.previous_cursor = ret.previous_cursor_str
            return out

        ProtoTwitter.convertSearchResult = (result) ->
            tweets = result.statuses
            out = []
            for tw in tweets
                if tw.retweeted_status and tw.retweeted_status != undefined
                    out.push(ProtoTwitter.convertEvent(ProtoTwitter.tweet2Event('retweet', tw)))
                else
                    out.push(ProtoTwitter.convertTweet(tw))
            out.max_id = result.search_metadata.max_id_str
            out.since_id = result.search_metadata.since_id_str
            return out

        ProtoTwitter.tweet2Event = (type, tweet) ->
            evt = 
                event: type
                source: tweet.user
                target: tweet.retweeted_status.user
                target_object: tweet.retweeted_status
                created_at: tweet.created_at
                original_id: tweet.id_str
            return evt

        ProtoTwitter.convertMessage = (message) ->
            ret = ProtoTwitter.formatText(message)
            date = new Date(message.created_at)
            item = 
                # principal
                action: 0 # 0 for insert, 1 for merge
                serv: 'twitter'
                id: message.id_str
                # core
                URL: "https://twitter.com/"
                text: ret[0]
                raw_text: message.text
                converted_text: ret[1]
                time: date.toLocaleTimeString()
                timestamp: date.getTime()
                recipient: ProtoTwitter.convertUser(message.recipient)
                sender: ProtoTwitter.convertUser(message.sender)
                # extend
                entities: message.entities
                deletable: false
                has_media: false
                media: []
                media_thumb_url: ''
                mentions: []
                has_attachments: false
                attachments: []
            if message.entities and message.entities.user_mentions
                item.mentions = message.entities.user_mentions
            mlist = ProtoTwitter.formMedia(message, item.converted_text)
            if mlist.length != 0
                item.media = mlist
                item.has_media = true
                item.media_thumb_url = mlist[0].thumb_url
            return item

        ProtoTwitter.convertMessages = (msgs) ->
            out = []
            for msg in msgs
                if msg and msg != undefined
                    out.push(ProtoTwitter.convertMessage(msg))
            return out

        ProtoTwitter.convertEvent = (evt) ->
            source = evt.source 
            target = evt.target
            object = evt.target_object
            date = new Date(evt.created_at)
            item = ProtoTwitter.convertTweet(object)
            # some modifications
            if evt.event == 'retweet'
                item.rt_id = evt.original_id
            item.time = date.toLocaleTimeString()
            item.timestamp = date.getTime()
            item.is_event = true
            item.event.source_name = "@#{source.screen_name}"
            item.event.target_name = if target.screen_name == ProtoTwitter.screen_name then 'Your' else "@#{target.screen_name}'s"
            item.event.target_object_name = 'Tweet'
            # build attachments
            item.has_attachments = true
            if evt.event == 'favorite'
                item.event.action = 'likes'
                item.attachments_label = 'They like this tweet'
            else if evt.event == 'retweet'
                item.event.action = 'retweets'
                item.attachments_label = 'They retweet this tweet'
            else
                item.event.action = evt.event
                item.attachments_label = "They #{evt.event} this tweet"
            att = Hotot.emptyAttachment()
            att.title = "@#{source.screen_name}, #{source.name}"
            att.url = "https://twitter.com/#{source.screen_name}"
            att.thumb_url = source.profile_image_url
            item.attachments.push(att)
            return item

        ProtoTwitter.buildWatcher = () ->
            watcher = {}
            watcher.emptyTester = new RegExp('^[\n\r\t ]*$', 'g')
            watcher.createAt = 0
            watcher.listeners =
                'home': []
                'mention': []
                'message': []

            watcher.notify = (streamName, result) ->
                # convert tweet to a regular item
                convert = if streamName == 'message' then ProtoTwitter.convertMessage else ProtoTwitter.convertTweet
                for key, lis of watcher.listeners[streamName]
                    lis([convert(result)])

            watcher.notifyEvent = (streamName, result) ->
                item = null
                # convert event to a regular item
                switch result.event
                    when 'favorite'
                        Logger.info("@#{result.source.screen_name} fav @#{result.target.screen_name}'s tweet")
                        item = ProtoTwitter.convertEvent(result)
                        item.action = 1 # merge
                    when 'unfavorite'
                        Logger.info("@#{result.source.screen_name} un-fav @#{result.target.screen_name}'s tweet")
                    when 'retweet'
                        Logger.info("@#{result.source.screen_name} retweet @#{result.target.screen_name}'s tweet")
                        item = ProtoTwitter.convertEvent(result)
                        item.action = 1 # merge
                    when 'unretweet'
                        Logger.info("@#{result.source.screen_name} un-fav @#{result.target.screen_name}'s tweet")
                    when 'follow'
                        Logger.info("@#{result.source.screen_name} fo @#{result.target.screen_name}'s tweet")
                    when 'unfollow'
                        Logger.info("@#{result.source.screen_name} un-fo @#{result.target.screen_name}'s tweet")
                if item != null
                    for key, lis of watcher.listeners[streamName]
                        lis([item])

            watcher.bind = (streamName, key, callback) ->
                Logger.info("column #{key} binds to stream #{streamName}")
                watcher.listeners[streamName][key] = callback

            watcher.unbind = (streamName, key) ->
                Logger.info("column #{key} unbinds from stream #{streamName}")
                if watcher.listeners[streamName].hasOwnProperty(key)
                    delete watcher.listeners[streamName][key]

            watcher.updateBinding = (bindings) ->
                for bd in bindings
                    # streamName, callback = bd
                    if not watcher.listeners[streamName].hasOwnProperty(bd[0])
                        watcher.bind(bd[0], bd[1])

            watcher.cleanup = (trick) ->
                # @TODO
                # if trick % 600 == 0
                    # reset stream per 10 mins
                if not watcher.running
                    watcher.start()
                return

            watcher.start = () ->
                watcher.times = 0
                watcher.lastTextLength = 0
                watcher.createStream()
                watcher.running = true

            watcher.onStateChanged = (xhr) ->
                if xhr.status == 401 or xhr.status == 407
                    Logger.error("Streams XHR OAuth error")
                if xhr.status == 420
                    Logger.warn("Streams XHR 420 error")
                watcher.running = false
                now = new Date().toLocaleString()                
                Logger.info("Streams Exit #{xhr.createAt} -> #{now}")

            watcher.handleStream = (xhr) ->
                # first part is always be friends list: 
                # {"friends":[25959744, 25959744]}
                # then events and tweets follow
                # so, handle the structure at first
                newText = xhr.responseText.substr(watcher.lastTextLength)
                Logger.info("Streams XHR readyState: #{xhr.readyState}, status: #{xhr.status}, length: #{xhr.responseText.length}, create: #{watcher.createAt.toLocaleTimeString()}")
                oldPosition = watcher.lastTextLength
                watcher.lastTextLength = xhr.responseText.length
                # limit xhr.responseText length & abort 
                if xhr.responseText.length > 500000
                    Logger.info("Streams Receives #{xhr.responseText.length} bytes")
                    setTimeout(() ->
                            xhr.abort()
                        ,
                        100
                    )
                # empty reply, twitter use newline to keep stream alive
                if watcher.emptyTester.test(newText)
                    Logger.info("Streams XHR Receives nothing")
                    return
                # @TODO the procedure to process tweets/events can be more simple.
                # because all json objects are complete.
                try
                    item = JSON.parse(newText)
                catch e
                    Logger.warn("Streams JSON parse error #{e.message} \n #{newText}")
                    return
                # then crack them
                watcher.crackStream(item)
                return

            watcher.crackStream = (item) ->
                if not item
                    return
                # handle messages, tweets
                # console.log item
                if item.direct_message
                    # notify registers with item.direct_message
                    watcher.notify('message', item.direct_message)
                    return
                # if item.delete and item.delete.status
                #     # notify registers with item.delete.status
                #     return
                if item.text and item.user
                    if item.retweeted_status
                        # notify registers with item as retweeted
                        # custom event for retweet
                        evt = ProtoTwitter.tweet2Event('retweet', item)
                        watcher.crackEvent(evt)
                        return
                    # ignore tweets from blocking users
                    # if globals.blocking_ids.indexOf(item.user.id_str) !== -1
                    #    return
                    # notify registers with [item]
                    watcher.notify('home', item)
                    # mentions
                    if item.entities
                        for mention in item.entities.user_mentions
                            if mention.screen_name == ProtoTwitter.screen_name
                                # notify registers with [item]
                                watcher.notify('mention', item)
                                break

                watcher.crackEvent(item)
                return 

            watcher.crackEvent = (item) ->
                # handle events
                if item.event
                    target = item.target
                    source = item.source
                    # someone did about me
                    if target.screen_name == ProtoTwitter.screen_name
                        watcher.notifyEvent('mention', item)
                    else
                        # not did by me
                        if source.screen_name != ProtoTwitter.screen_name
                            watcher.notifyEvent('home', item)
                return

            watcher.createStream = () ->
                url = 'https://userstream.twitter.com/1.1/user.json'
                signUrl = url
                #  events about the user, and the events about their followings
                params = 
                    'with': 'followings'
                # console.log ProtoTwitter.accessToken
                signed_params = ProtoTwitter.oauth.form_signed_params(signUrl, ProtoTwitter.accessToken, 'GET', params, false)
                url = url + '?' + signed_params
                Logger.info("Streams Open [User Stream]")
                xhr = new XMLHttpRequest()
                xhr.open('GET', url, true)
                xhr.setRequestHeader('X-User-Agent', 'Hotot')
                watcher.createAt = new Date()
                xhr.onabort = xhr.onerror = xhr.onload = () ->
                    watcher.onStateChanged(xhr)
                xhr.onreadystatechange = () ->
                    watcher.handleStream(xhr)
                xhr.send(null)

            return watcher
        return ProtoTwitter
    return buildFn
])
