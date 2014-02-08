class Hotot
    @CURRENT_VERSION = '3.0.18.6'
    @CURRENT_CODENAME = 'Cindy'
    @rtlang =
        'en':
            'just now': 'just now'
            'minute': 'm'
            'hour': 'h'
            'day': ''
            'month': ' '
            'year': ', '
            'ago': ''
            'month_name': ['Jan', 'Feb', 'Mar', 'April', 'May', 'Jun', 'July', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        'zh_CN':
            'just now': '刚才'
            'minute': '分钟' # postfix
            'hour': '小时'
            'day': '日' 
            'month': '月'
            'year': '年'
            'ago': '前'
            'month_name': ['1', '2', '3', '4', '5', '6', '7', '8', '9',  '10',  '11', '12']

    @mediaReg = 
        'instagr.am':
            reg: new RegExp('http:\\/\\/instagr.am\\/p\\/([a-zA-Z0-9_\\-]+)\\/?','g')
            base: 'http://instagr.am/'
        'instagram.com':
            reg: new RegExp('http:\\/\\/instagram.com\\/p\\/([a-zA-Z0-9_\\-]+)\\/?','g')
            base: 'http://instagr.am/'
        'img.ly': 
            reg: new RegExp('http:\\/\\/img.ly\\/([a-zA-Z0-9_\\-]+)','g')
            base: 'http://img.ly/'

    @extractMedia: (text) ->
        out = []
        i = 0
        for pvdName, data of @mediaReg
            match = data.reg.exec(text)
            i = 0
            while match != null and i < 5
                switch pvdName
                    when 'img.ly'
                        out.push({
                            type: 'photo'
                            url: "#{data.base}/show/full/#{match[1]}"
                            thumb_url: "#{data.base}/show/thumb/#{match[1]}"
                        })
                    when 'instagr.am'
                        out.push({
                            type: 'photo'
                            url: "#{data.base}/p/#{match[1]}/media/?size=l"
                            thumb_url: "#{data.base}/p/#{match[1]}/media/?size=t"
                        })
                    when 'instagram.com'
                        out.push({
                            type: 'photo'
                            url: "#{data.base}/p/#{match[1]}/media/?size=l"
                            thumb_url: "#{data.base}/p/#{match[1]}/media/?size=t"
                        })
                match = data.reg.exec(text)
                i += 1
        return out

    @formatTime = (m, oldTime, local)->
        text = ''
        if not @rtlang.hasOwnProperty(local)
            local = 'en'
        map = @rtlang[local]
        if m <= 1
            text = map['just now']
        else if m > 1 and m <= 60
            text = m + map['minute'] + map['ago']
        else if m > 60 and m <= 1440
            text = Math.round(m/60) + map['hour'] + map['ago']
        else if m > 1440 and m <= 1051200
            text = map['month_name'][oldTime.getMonth()] + map['month'] + oldTime.getDate() + map['day'] 
        else
            text = oldTime.getFullYear() + map['year'] + map['month_name'][oldTime.getMonth()] + map['month'] + oldTime.getDate() + map['day'] 
        return text

    @fetchImage: (url, success, fail) ->
        xhr = new XMLHttpRequest()
        xhr.open('GET', url, true)
        xhr.responseType = 'blob'
        xhr.onload = (e) ->
            success(this.response)
        xhr.send()

    @checkUpdate: (callback) ->
        compareVersion = (v1, v2) ->
            # in this form: major.minor.increasable
            a1 = v1.split('.')
            a2 = v2.split('.')
            if a1.length == 0 or a2.length == 0 then return 0
            a1 = a1.map((e) -> parseInt(e))
            a2 = a2.map((e) -> parseInt(e))
            max = if a1.length < a2.length then a1.length else a2.length
            for i in [0 ... max]
                if a1[i] < a2[i]
                    return -1
                else if a1[i] > a2[i]
                    return 1
            return 0

        crackManifest = (mf) ->
            if mf.manifest_version == '1'
                ver = mf.version
                url = mf.url
                return {version: ver, url: url}
            return {}
        xhr = new XMLHttpRequest()
        xhr.open('GET', "http://dl.hotot.org/update_manifest.json", true)
        xhr.responseType = 'application/json'
        xhr.onload = (e) =>
            mf = JSON.parse(xhr.response)
            ret = crackManifest(mf)
            switch compareVersion(@CURRENT_VERSION, ret.version)
                when -1
                    console.log "new version"
                    callback(true, ret.version, ret.url)
                when 0
                    console.log "up to date"
                    callback(false)
                when 1
                    console.log "are you guy the developer?" 
                    callback(false)
        xhr.send()

    @detectOS = ->
        if navigator.platform.toUpperCase().indexOf('MAC') != -1 
            return 'osx'
        if navigator.platform.toUpperCase().indexOf('WIN') != -1 
            return 'windows'
        if navigator.platform.toUpperCase().indexOf('LINUX') != -1 
            return 'linux'
        return 'unknow'

    @generateUUID: () ->
        S4 = () ->
            return (((1+Math.random())*0x10000)|0).toString(16).substring(1);
        return (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4())

    @normalizeResult: (result) ->
        if result.constructor == String
            try
                return JSON.parse(result)
            catch e
                return result
        return result

    @dataURL2Uint8Array: (dataURL) ->
        BASE64_MARKER = ';base64,'
        parts = dataURL.split(BASE64_MARKER)
        contentType = parts[0].split(':')[1]
        raw = window.atob(parts[1]) # raw is not ArrayBuffer
        rawLength = raw.length
        uInt8Array = new Uint8Array(rawLength)
        for i in [0 ... rawLength]
            uInt8Array[i] = raw.charCodeAt(i)
        return uInt8Array

    @imageTest: (filename) ->
        return /.*(jpg|jpeg|png|gif)$/i.test(filename)

    @quote: (text) ->
        text = encodeURIComponent(text)
        text = text.replace(/\!/g, "%21")
        text = text.replace(/\*/g, "%2A")
        text = text.replace(/\'/g, "%27")
        text = text.replace(/\(/g, "%28")
        text = text.replace(/\)/g, "%29")
        return text


    @unserializeDict = (str) ->
        dict = {} # return {} if dict is invalid.
        pairs = str.split('&')
        if 1 < pairs.length
            for pair in pairs
                tuple = pair.split('=')
                dict[decodeURIComponent(tuple[0])] = decodeURIComponent(tuple[1])
        return dict

    @normalizeParams = (params) ->
        sortable = []
        # params_list = [ [key, value] ... ]
        params_list = []
        for k, v of params
            params_list.push([k, params[k]])
        # do sort
        params_list.sort((a, b) ->
            if a[0] < b[0] then return -1
            if a[0] > b[0] then return 1
            return 0
        )
        # encode each key-value pair
        for pair in params_list
            sortable.push(@quote(pair[0]) + '=' + @quote(pair[1]))
        return sortable.join('&')

    @encodeMultipartFormdataBlob: (fields, media) ->
        # media.data should be available Uint8Array
        BOUNDARY = 'HototFormBoundary31415926535897932384626'
        CRLF = '\r\n'
        L = []
        bytes = []
        for key, value of fields
            L.push('--' + BOUNDARY)
            L.push('Content-Disposition: form-data; name="'+key+'"')
            L.push('')
            L.push(value) # don't need encodeURI
        L.push('--' + BOUNDARY)
        L.push('Content-Disposition: form-data; name="'+media.name+'"; filename="'+media.filename+'"')
        L.push('Content-Type: application/octet-stream')
        if media.encoding
            L.push('Content-Transfer-Encoding:' + media.encoding)
        L.push('')

        blobArray = []
        blobArray.push(L.join(CRLF) + CRLF)
        # console.log media.data
        # bufview = new Uint8Array(media.data)
        # console.log bufview
        blobArray.push(media.data)
        blobArray.push(CRLF)
        LL = []
        LL.push('--' + BOUNDARY + '--')
        LL.push('')
        blobArray.push(LL.join(CRLF))
        # console.log blobArray
        body = new Blob(blobArray)

        headers = {'Content-Type':'multipart/form-data; boundary=' + BOUNDARY}
        return [headers, body]

    @encodeMultipartFormdataBase64: (fields, media) ->
        # media.data should be dataURI
        # base64 based formdata doesn't work at twitter. it returns 403 error creating status
        BOUNDARY = 'HototFormBoundary31415926535897932384626'
        CRLF = '\r\n'
        L = []
        bytes = []
        for key, value of fields
            L.push('--' + BOUNDARY)
            L.push('Content-Disposition: form-data; name="'+key+'"')
            L.push('')
            L.push(value) # don't need encodeURI
        L.push('--' + BOUNDARY)
        L.push('Content-Disposition: form-data; name="'+media.name+'"; filename="'+media.filename+'"')
        if not media.type
            media.type = 'application/octet-stream'
        L.push('Content-Type: ' + media.type)
        L.push('Content-Transfer-Encoding: base64')
        L.push('')

        L.push(media.data)
        L.push('--' + BOUNDARY + '--')
        L.push('')
        body = L.join(CRLF)
        headers = {'Content-Type':'multipart/form-data; boundary=' + BOUNDARY}
        return [headers, body]

    @saveBounds: () ->
        win = hotot.window.current()
        bounds = win.getBounds()
        pair = {'WINDOW_BOUNDS': bounds}
        hotot.storage.local.set(pair)

    @emptyItem: ->
        # build empty item, defaults attributes are false/null/''/[]
        item = 
            # principal
            action: 0
            serv: ''
            id: ''
            # core
            title: ''
            URL: ''
            text: ''
            raw_text: ''
            converted_text: ''
            time: ''
            timestamp: ''
            event: ''
            # extend
            previous_item_id: ''
            next_item_id: ''
            recipient_id: ''
            recipient_name: ''
            feature_pic_url: ''
            source: ''
            entities: null
            deletable: false
            repostable: false
            favorited: false
            reposted: false
            original_id: ''
            rt_id: ''
            reposter_id: ''
            reposter_name: ''
            has_comments: false
            has_quote: false
            quote_text: ''
            has_media: false
            media: []
            media_thumb_url: ''
            mentions: []
            has_attachments: false
            attachments_label: ''
            attachments: []
            is_event: false
            author: {}
            event: {
                action: ''
                target_name: ''
                source_name: ''
                target_object_name: ''
            }
        return item

    @emptyAttachment : ->
        att = 
            title: ''
            thumb_url: ''
            url: ''

    @RELATIONSHIP: {
        SELF: -2
        UNKNOWN: -1
        FOLLOWING: 0
        FOLLOWED: 1
        FRIENDS: 2
        STRANGER: 3
        BLOCKED: 4
        SELF_STR: 'It\'s YOU!'
        UNKNOWN_STR: '...'
        FOLLOWING_STR: 'Following them'
        FOLLOWED_STR: 'Followed by them'
        FRIENDS_STR: 'You\'re friends'
        STRANGER_STR: 'Not following'
        BLOCKED_STR: 'Blocked'
    }

    @emptyUser : ->
        user = 
            id: ''
            name: ''
            display_name: ''
            url: ""
            raw_url: ""
            direct_url: ""
            description: ''
            location: ''
            avatar_url: ''
            background_url: ''
            protected: false
            relationship: @RELATIONSHIP.UNKNOWN
            statuses_count: 0
            friends_count: 0
            followers_count: 0
            favourites_count: 0
            following: false

    @sameName: (name1, name2) ->
        return name1.toLowerCase() == name2.toLowerCase()

    @getNameFromURL: (url) ->
        return url.substring(url.lastIndexOf('/')+1) #hotot://people/NAME

root = exports ? this
root.Hotot = Hotot
