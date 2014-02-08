
root = exports ? this
root.app.controller('ColumnCtrl', ['$scope', 'AppService', 'SliderService', 'HototCache', 'RelationService', 'ColumnsState', 'ConnManager', 'DialogService', 'HototColumn', 'HototSlot', 'HototDaemon', 'SettingsService', 'NotifyService', 'Logger',
($scope, AppService, SliderService, HototCache, RelationService, ColumnsState, ConnManager, DialogService, HototColumn, HototSlot, HototDaemon, SettingsService, NotifyService, Logger) ->
    $scope.props = {}
    $scope.items = null
    settings = null
    state = null
    ownerSlot = null
    myColumn = null
    client = null
    key = ''
    scroll = null
    scrollBottom = 0
    isNotify = false
    now = null
    id = ''
    buffer = null
    isScrolling = false
    lock = false
    globalMute = {}
    muteEngine = null
    _timer = null
    firstTime = true
    delegatedListeners = {}
    $scope.placeholder = 
        text: 'no more content'
        details: ':)'

    $scope.loadmore = 
        show: false
        text: 'load more'

    $scope.$on('SliderChangeSlot', () ->
        if SliderService.currentSlot.serv == myColumn.serv and SliderService.currentSlot.name == myColumn.slot_name
            setTimeout(refreshScroller, 100)
    )

    $scope.$on('SliderToTop', () ->
        if SliderService.currentCol.serv == myColumn.serv and SliderService.currentCol.slot_name == myColumn.slot_name
            scrollScroller(0, 0, 100)
            SliderService.selectItem(myColumn.serv, myColumn.slot_name, myColumn.name, "TOP")
    )

    $scope.$on('SliderDeleteColumn', () ->
        if SliderService.deleteParams.serv == myColumn.serv and SliderService.deleteParams.slot_name == myColumn.slot_name
            if SliderService.deleteParams.name == "*" or SliderService.deleteParams.name == myColumn.name
                deleteMyself()
    )

    $scope.$on('SliderUpdateColumnMute', () ->
        if SliderService.updateColumnMuteParams.serv == myColumn.serv and SliderService.updateColumnMuteParams.slot_name == myColumn.slot_name
            if SliderService.updateColumnMuteParams.name == myColumn.name
                myColumn.mute = SliderService.updateColumnMuteParams.mute
                applyMute()
    )

    $scope.$on('SettingsUpdateMute', () ->
        globalMute = SettingsService.updateMuteParams.mute
        applyMute()
    )

    $scope.$on('SliderScrollColumn', () ->
        if SliderService.currentCol.serv == myColumn.serv and SliderService.currentCol.slot_name == myColumn.slot_name
            if SliderService.currentCol.name == "*" or SliderService.currentCol.name == myColumn.name
                item = document.getElementById("#{id}").querySelector("[data-id='#{SliderService.itemId}']")
                if item and getScroller()
                    if Hotot.detectOS() == 'osx'
                        pos = 0 - item.offsetTop + 120
                        if pos > 0
                            pos = 0
                        else if pos < getScrollerMaxScrollY()
                            pos = getScrollerMaxScrollY()
                    else 
                        pos = item.offsetTop - 120
                        if pos < 0
                            pos = 0
                        else if pos > getScrollerMaxScrollY()
                            pos = getScrollerMaxScrollY()
                    scrollScroller(0, pos, 200)
                item = null
    )

    mergeMutes = (mute1, mute2) ->
        mute = []
        for m1 in mute1
            m1 = m1.toLowerCase()
            mute.push(m1)
        for m2 in mute2
            m2 = m2.toLowerCase()
            if mute.indexOf(m2) == -1
                mute.push(m2)
        return mute

    applyMute = () ->
        mute = mergeMutes(myColumn.mute, globalMute)
        muteEngine.compile(mute)
        $scope.items = muteEngine.filter($scope.items)
        return

    createMuteEngine = ->
        engine = 
            keywords: []
            names: {}
            hashtags: []
        engine.compile = (mute) ->
            for m in mute
                m = m.toLowerCase()
                _m = m.substring(1)
                switch m[0]
                    when '#'
                        if this.hashtags.indexOf(_m) == -1
                            this.hashtags.push(_m)
                    when '@'
                        this.names[_m] = true
                    else
                        if this.keywords.indexOf(_m) == -1
                            this.keywords.push(_m)
            return
        engine.check = (item) ->
            text = item.converted_text.toLowerCase()
            name = item.author.name
            displayName = item.author.display_name
            for kw in this.keywords
                if text.indexOf(kw) != -1 then return true
            if this.names.hasOwnProperty(name) or this.names.hasOwnProperty(displayName) then return true
            return false
        engine.filter = (items) ->
            return items.filter((x) -> not engine.check(x))
        return engine

    refresh = (items, isUpdateState, reversion) ->
        _refresh = ()->
            now = new Date()
            insertMany(items, reversion)
            # only modify state after pulling
            if isUpdateState and $scope.items.length != 0
                switch state.position_mode
                    when 'id'
                        state.max_id = $scope.items[$scope.items.length - 1].id
                        state.since_id = $scope.items[0].id
                    when 'external_id'
                        state.max_id = $scope.items.max_id
                        state.since_id = $scope.items.since_id
        _checkScrolling = ->
            if isScrolling == true or lock == true
                _scrollingTimer = setTimeout(_checkScrolling, 500)
            else
                lock = true
                _refresh()
                lock = false
        # _checkScrolling()
        _refresh()
        return

    liveTimeFetch = ()->
        if client == null then return
        posArg1 = ''
        posArg2 = ''
        switch state.position_mode
            when 'id' or 'external_id'
                # posArg1 = state.since_id
                # posArg2 = state.max_id
                # @BUG of twitter? 403 forbidden if use specified since_id or max_id in search
                posArg1 = state.since_id
                posArg2 = ''
            when 'cursor'
                posArg1 = state.previous_cursor 
                posArg2 = '' # state.next_cursor
            when 'page'
                posArg1 = state.page
        $scope.placeholder.text = 'loading'
        $scope.placeholder.details = 'please wait a moment...'
        client.handleColumnLoad(
                type: if myColumn.type then myColumn.type else myColumn.name
                params: myColumn.params
                position_arg1: posArg1
                position_arg2: posArg2
            , (items) -> 
                refresh(items, true, true)
                if $scope.items.length == 0
                    $scope.placeholder.text = 'no more content'
                    $scope.placeholder.details = ':)'
                else
                    $scope.loadmore.show = true
            , (data) ->
                $scope.placeholder.text = 'failed to load content'
                $scope.placeholder.details = if data.constructor == String then data else JSON.stringify(data)
        )
        return

    $scope.loadMore = ()->
        if client == null then return
        posArg1 = ''
        posArg2 = ''
        switch state.position_mode
            when 'id' or 'external_id'
                # posArg1 = state.since_id
                # posArg2 = state.max_id
                # @BUG of twitter? 403 forbidden if use specified since_id or max_id in search
                posArg1 = ""
                posArg2 = state.max_id
            when 'cursor'
                posArg1 = state.next_cursor # state.previous_cursor 
                posArg2 = ''
            when 'page'
                posArg1 = state.page
        $scope.loadmore.text = 'loading ...'
        client.handleColumnLoadMore(
                type: if myColumn.type then myColumn.type else myColumn.name
                params: myColumn.params
                position_arg1: posArg1
                position_arg2: posArg2
            , (item) -> 
                refresh(item, true, false)
                if $scope.items.length == 0
                    $scope.loadmore.text = 'no more content. :)'
                else
                    $scope.loadmore.text = 'load more'
            , (data) ->
                $scope.loadmore.text = 'failed to load content. :('
                setTimeout(()->
                        $scope.loadmore.text = 'load more'
                    , 
                        5000
                )
                return
        )
        return

    insertMany = (items, reversion) ->
        opts = {}
        if reversion and reversion != undefined
            opts.reversion = reversion
        if getScroller()
            if Hotot.detectOS() == 'osx'
                scrollBottom = getScrollerH() + getScrollerY()
            else
                scrollBottom = getScrollerH() - getScrollerY()
            # console.log 'scroll.y='+scroll.y, 'scrollerH='+scroll.scrollerH, 'scrollbottom='+scrollBottom
        tot = 0
        ret = 0
        insertedItems = []
        # insert isolated items
        preview_media = SettingsService.settings.preview_media.value
        for it in items
            if muteEngine.check(it)
                continue
            if it.has_media and not preview_media
                it.has_media = false
                it.media = []
                it.media_thumb_url = ''
            if it.action == 1 # handle merge action
                pos = -1
                mit = null
                for eit, i in $scope.items
                    # if there are two item with same id and same event
                    if eit.id == it.id and (eit.event.action == 0 or eit.event.action == it.event.action)
                        mit = ColumnUtils.mergeAttachments(it, eit)
                        pos = i
                        break
                if pos != -1
                    $scope.items.splice(pos, 1)
                    ret = ColumnUtils.insert($scope.items, mit, opts)
                    if ret != 0
                        tot += ret
                        insertedItems.push(mit)
                else
                    ret = ColumnUtils.insert($scope.items, it, opts)
                    if ret != 0
                        tot += ret
                        insertedItems.push(it)
            else
                ret = ColumnUtils.insert($scope.items, it, opts)
                if ret != 0
                    tot += ret
                    insertedItems.push(it)
        if getScroller() and getScrollerY() == 0
            HototCache.trim(key)
        setTimeout(() ->
                refreshScroller()
                if reversion != false # don't relocate if loading more.
                    relocateScroller()
            ,
            0
        )
        Logger.info("Insert #{tot} items into Column #{key}")
        if myColumn.notification and not firstTime
            if insertedItems.length == 0
                return
            else if 2 < insertedItems.length
                NotifyService.notify("New Items", "Insert #{tot} items into Column #{key}")
            else
                for it in insertedItems
                    if it.is_event
                        NotifyService.notify("New Event", "#{it.event.source_name} #{it.event.action} #{it.event.target_name} #{it.event.target_object_name}")
                    else
                        NotifyService.notify("#{it.title} - @#{it.author.name}:", "#{it.converted_text}")
            SliderService.setColumnNotifyStatus(myColumn.serv, myColumn.slot_name, myColumn.name)
        if firstTime
            firstTime = false
        users = []
        for item in insertedItems
            users.push(item.author) 
        RelationService.add(myColumn.serv, myColumn.slot_name, users)
        return

    $scope.initColumn = (col) ->
        settings = SettingsService.settings
        myColumn = col
        # mute engine
        globalMute = SettingsService.getMute()
        muteEngine = createMuteEngine()
        mute = mergeMutes(myColumn.mute, globalMute)
        muteEngine.compile(mute)
        # client
        client = ConnManager.getConn(myColumn.serv, myColumn.slot_name)
        proto = ConnManager.getProto(myColumn.serv)
        key = "#{myColumn.serv}/#{myColumn.slot_name}/#{myColumn.name}"
        # bind to column state
        state = ColumnsState.bind(key, proto.getColumnPositionMode(myColumn.name))
        # bind to cache
        $scope.items = HototCache.bind(key)
        # bind to daemon
        HototDaemon.bind(key, myColumn.update_interval, () ->
            liveTimeFetch()
        )
        # bind to stream 
        if client.supportStream and client.supportSubStream[myColumn.name]
            HototDaemon.bindStream(myColumn.serv, myColumn.slot_name, myColumn.name, myColumn.name, (items) ->
                $scope.$apply(() ->
                    refresh(items, false, true)
                )
            )
        # get owner
        HototSlot.get(myColumn.serv, myColumn.slot_name, (slot) ->
            ownerSlot = slot
        )
        initScroller()
        delegatedClick('user_link', onUserlinkClick)

    initScroller = () ->
        id = "#{myColumn.serv}_#{myColumn.slot_name}_#{myColumn.name}"
        if Hotot.detectOS() == 'osx'
            setTimeout(() ->
                    scroll = new iScroll(id,
                        { 
                            bounce: true,
                            momentum: false,
                            useTransition: true,
                            onScrollEnd: whenScrollStop,
                            onScrollStart: whenScrollStart,
                            onScrollMove: whenScrollMove,
                            scrollbarClass:'scrollbar',
                        },
                    )
                , 300
                )
        else
            setTimeout(() ->
                    scroll = document.getElementById(id)
                    scrollBottom = scroll.scrollHeight - scroll.scrollTop
                , 300
            )

    destroyScroller = ->
        if scroll == null then return
        if Hotot.detectOS() == 'osx'
            scroll.destroy()
            scroll = null

    scrollScroller = (posX, posY, time) ->
        if scroll == null then return
        if Hotot.detectOS() == 'osx'
            scroll.scrollTo(posX, posY, time)
        else
            scroll.scrollTop = posY

    refreshScroller = () ->
        if scroll == null then return
        if Hotot.detectOS() == 'osx'
            scroll.refresh()
        return

    relocateScroller = (ret) ->
        if scroll == null then return
        if Hotot.detectOS() == 'osx'
            if scroll.y == 0
                return
            else
                scroll.scrollTo(0, 0 - (scroll.scrollerH - scrollBottom))
            # console.log 'relocate', 'scroll.y='+scroll.y, 'scrollerH='+scroll.scrollerH, 'scrollbottom='+scrollBottom
        else
            if scroll.scrollTop == 0
                return
            else
                scroll.scrollTop = scroll.scrollHeight - scrollBottom

    getScrollerY = ->
        if scroll == null then return 0
        if Hotot.detectOS() == 'osx'
            return scroll.y
        else
            return scroll.scrollTop

    getScrollerMaxScrollY = ->
        if scroll == null then return 0
        if Hotot.detectOS() == 'osx'
            return scroll.maxScrollY
        else
            return scroll.scrollHeight + scroll.scrollTop

    getScrollerH = ->
        if scroll == null then return 0
        if Hotot.detectOS() == 'osx'
            return scroll.scrollerH
        else
            return scroll.scrollHeight

    getScroller = ->
        return scroll

    whenScrollStop = (evt) ->
        # isScrolling = true
        # if _timer != null
        #     clearTimeout(_timer)
        # _timer = setTimeout(() ->
        #     isScrolling = false
        # , 1000
        # )
        return

    whenScrollStart = (evt) ->
        return

    whenScrollMove = (evt) ->
        return

    deleteMyself = ->
        ColumnsState.unbind(key)
        HototCache.unbind(key)
        client = ConnManager.getConn(myColumn.serv, myColumn.slot_name)
        if client.supportStream and client.supportSubStream[name]
            HototDaemon.unbindStream(myColumn.serv, myColumn.slot_name, myColumn.name, myColumn.name)
        HototDaemon.unbind(key)
        destroyScroller()
        Logger.info("Destroy Column #{key}")

    $scope.loadComments = (item) ->
        ret = HototCache.getComments(key, item.id)
        commentState = ret[0]
        comments = ret[1]
        if commentState == 0 # then open them
            HototCache.setCommentsState(key, item.id, 2)
            if comments.length == 0 # then load them
                client.getComments(item, (comments) -> 
                        HototCache.setComments(key, item.id, 1, comments)
                    , (comments) ->
                        HototCache.setComments(key, item.id, 1, comments)
                )
            else
                HototCache.setComments(key, item.id, 1, comments)
        else if commentState == 1 # then fold them
            HototCache.setComments(key, item.id, 0, comments)
        else # commentState == 2, just wait
            return
        return

    $scope.getCommentsState = (item) ->
        commentState = HototCache.getCommentsState(key, item.id)
        m = {0: 'ctrl-icon-comment folded', 1: 'ctrl-icon-comment open', 2: 'icon-spinner'}
        return m[commentState]

    $scope.getComments = (item) ->
        comments = []
        if not item.has_comments
            return []
        ret = HototCache.getComments(key, item.id)
        if ret[0] == 0 # fold
            return []
        return ret[1]

    # overlayed
    delegatedClick = (cls, callback) ->
        if delegatedListeners.hasOwnProperty(cls)
            delegatedListeners[cls] = null
        delegatedListeners[cls] = callback
        return 

    onUserlinkClick = (evt) ->
        username = Hotot.getNameFromURL(evt.target.href)
        hotot.bus.sendMessage({
            role: 'column', cmd: "do_view_people", content: {serv: myColumn.serv, slot_name: myColumn.slot_name, user_name: username}
        })
        evt.preventDefault()

    $scope.openMediaPreview = (item) ->
        opts = {}
        DialogService.openPreviewDialog(opts, item.media)

    $scope.doItemReply = (item) ->
        hotot.bus.sendMessage({
            role: 'column', cmd: "do_reply_item", content: {serv: myColumn.serv, slot_name: myColumn.slot_name, item: item}
        })

    $scope.doItemFav = (item) ->
        ok1 = () ->
            item.favorited = true
        ok2 = () ->
            item.favorited = false
        err = () ->
            return
        client = ConnManager.getConn(myColumn.serv, myColumn.slot_name)
        if item.favorited
            client.handleUndoFav(item.id, ok2, err)
        else
            client.handleFav(item.id, ok1, err)

    $scope.doItemRepost = (item) ->
        ok1 = (ret) ->
            item.reposted = true
            item.rt_id = ret.rt_id
        ok2 = (ret) ->
            item.reposted = false
            item.rt_id = ''
        err = () ->
            return
        client = ConnManager.getConn(myColumn.serv, myColumn.slot_name)
        if item.reposted
            client.handleUndoRepost(item.rt_id, ok2, err)
        else
            client.handleRepost(item.id, ok1, err)

    $scope.doItemQuote = (item) ->
        DialogService.openComposeDialog(SliderService.currentSlot, 
            {   
                type: "quote",
                text: item.converted_text,
                id: item.id,
                author_name: item.author.name,
                author_id: item.author.id,
                mentions: []
            }
        )

    $scope.doItemDelete = (item) ->
        ok = (item) ->
            pos = -1
            # @TODO use bsearch
            for it, i in $scope.items
                if it.id == item.id
                    pos = i
                    break
            if pos != -1
                $scope.items.splice(pos, 1)
        err = () ->
            return
        client = ConnManager.getConn(myColumn.serv, myColumn.slot_name)
        client.handleDelete(item.id, ok, err)
        return

    # common methods for column
    $scope.onDelegatedClick = (evt) ->
        for cls in evt.target.classList
            if delegatedListeners.hasOwnProperty(cls)
                delegatedListeners[cls](evt)
                return false
        return true

    $scope.isEmpty = ->
        return $scope.items.length == 0

    $scope.loadFeaturePic = (item) ->
        Hotot.fetchImage(item.feature_pic_url, (data) ->
            $scope.$apply(() ->
                item.feature_pic_data = window.webkitURL.createObjectURL(data)
            )
        )
        return

    $scope.loadMediaThumb = (item) ->
        if item.has_media
            Hotot.fetchImage(item.media_thumb_url, (data) ->
                $scope.$apply(() ->
                    item.media_thumb_data = window.webkitURL.createObjectURL(data)
                )
            )
        return

    $scope.loadAttachmentThumb = (att) ->
        if att
            Hotot.fetchImage(att.thumb_url, (data) ->
                $scope.$apply(() ->
                    att.thumb_data = window.webkitURL.createObjectURL(data)
                )
            )
        return

    $scope.getItemFavState = (item) ->
        return if item.favorited then 'faved' else ''

    $scope.getItemRepostState = (item) ->
        return if item.reposted then 'reposted' else ''

    $scope.getItemCornerMarkCls = (item) ->
        if item.favorited and item.reposted
            return 'green'
        if item.favorited
            return 'orange'
        if item.reposted
            return 'blue'

    $scope.getItemTextStyles = ->
        return {'line-height': settings.line_height.value, 'font-size': settings.font_size.value + 'pt'}    

    $scope.getPlaceholderText = ->
        return $scope.placeholder.text

    $scope.getPlaceholderDetails = ->
        return $scope.placeholder.details

    $scope.getFormatTime = (item) ->
        ts = new Date(item.timestamp)
        diff = now - ts
        if diff != item.diff
            m = Math.floor(Math.abs(diff/1000/60))
            item.time = Hotot.formatTime(m, ts, 'en')
            item.diff = diff
        return item.time

    $scope.selectItem = (item) ->
        SliderService.selectItem(myColumn.serv, myColumn.slot_name, myColumn.name, item)

    $scope.getItemStyles = (item) ->
        return if item.selected then 'selected' else ''

    return
])
