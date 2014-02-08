root = exports ? this

root.app.controller('SearchCtrl', ['$scope', 'AppService', 'SliderService', 'HototCache', 'RelationService', 'ColumnsState', 'ConnManager', 'DialogService', 'HototColumn', 'HototSlot', 'HototDaemon', 'SettingsService', 'NotifyService', 'Logger',
($scope, AppService, SliderService, HototCache, RelationService, ColumnsState, ConnManager, DialogService, HototColumn, HototSlot, HototDaemon, SettingsService, NotifyService, Logger) ->  

    $scope.items = []

    $scope.placeholder = 
        text: 'no more content'
        details: ':)'

    $scope.loadmore = 
        show: false
        text: 'load more'

    delegatedListeners = {}

    slot = null
    proto = null
    client = null
    key = ''
    state = {}
    settings = null
    now = null
    keywords = ''

    $scope.$on('AppSearch', () ->
        resetSearch()
        keywords = AppService.keywords
        search(keywords)
    )

    refresh = (items, isUpdateState, reversion) ->
        now = new Date()
        # insertMany(items, reversion)
        $scope.items = items
        # only modify state after pulling
        if isUpdateState and $scope.items.length != 0
            switch state.position_mode
                when 'id'
                    state.max_id = $scope.items[$scope.items.length - 1].id
                    state.since_id = $scope.items[0].id
                when 'external_id'
                    state.max_id = $scope.items.max_id
                    state.since_id = $scope.items.since_id
        return

    resetSearch = () ->
        # client
        slot = SliderService.currentSlot
        client = ConnManager.getConn(slot.serv, slot.name)
        proto = ConnManager.getProto(slot.serv)
        key = "#{slot.serv}/#{slot.name}/#search"
        # bind to column state
        state = ColumnsState.bind(key, proto.getColumnPositionMode('search'))
        # bind to cache
        $scope.items = HototCache.bind(key)
        return

    search = (keywords) ->
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
                type: 'search'
                params: [keywords]
                position_arg1: posArg1
                position_arg2: posArg2
            , (items) -> 
                # refresh(items, true, true)
                $scope.items = items
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

    $scope.init = () ->
        settings = SettingsService.settings
        # get owner
        delegatedClick('user_link', onUserlinkClick)

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

    $scope.getKeywords = () ->
        return keywords

    $scope.showMeta = () ->
        if keywords.length == 0
            return false
        return true

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


])