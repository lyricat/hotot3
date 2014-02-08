root = exports ? this

root.app.controller('HototApp', ['$scope', 'HototSlot', 'HototColumn', 'AppService', 'SliderService', 'DialogService', 'ConnManager', 'HototDaemon', 'RelationService', 'MessageService', 'Logger',
($scope, HototSlot, HototColumn, AppService, SliderService, DialogService, ConnManager, HototDaemon, RelationService, MessageService, Logger) ->  
    resizeTimer = null
    $scope.props = {composeBtnExpendClass: ""}
    $scope.splash = 
        show: true
        fade_out: false
        text: 'loading...'
    $scope.guide = 
        show: false
        fade_out: false
        add_slot:
            show: false
            text: 'Add an account here'
    $scope.masks = 
        show: true
    $scope.notify_bar = 
        show: false
        text: 'No thing new here'
        link: '#'
        link_icon: ''

    $scope.search_entry = 
        text: ''
        expand: ''
    $scope.search_layer = 
        cls: ''
        show: ''

    $scope.slots = [{}, {}, {}]
    $scope.currentSlot = SliderService.currentSlot

    $scope.$on('SliderUpdate', () ->
        refreshSlotList()
    )

    $scope.$on('AppTriggerResize', () ->
        resize()
    )

    $scope.$on('SliderChangeSlot', () ->
        resize()
    )

    $scope.$on('SliderNoMoreSlot', () ->
        hideMe()
        checkSlot()
    )

    $scope.$on('SliderDeleteSlot', () ->
        whenSlotDeleted(SliderService.deletedSlotParams.serv, SliderService.deletedSlotParams.name)
    )

    hideMe = ->
        win = hotot.window.current()
        win.hide()

    showMe = ->
        win = hotot.window.current()
        win.show()
        win.focus()
        win.drawAttention()
        Logger.info("Init layout")
        setTimeout(triggerResize, 1000)
        setTimeout(() ->
                $scope.splash.fade_out = true
            , 1000
        )
        setTimeout(() ->
                checkUpdate()
            , 5000
        )

    checkSlot = (callback)->
        _checkSlot = ->
            HototSlot.all((_slots) ->
                if _slots.length == 0
                    # waiting
                    setTimeout(_checkSlot, 2000)
                else
                    showMe()
                    callback()
            )
        HototSlot.all((_slots) ->
            if _slots.length == 0
                DialogService.openNewSlotDialog()
            _checkSlot()
        )

    setUpContextMenu = () ->
        chrome.contextMenus.removeAll(() ->
            chrome.contextMenus.create({
                title: 'Reply',
                id: 'context_menu_reply',
                targetUrlPatterns: ['chrome-extension://*/more'],
                contexts: ['link'],
            })
            chrome.contextMenus.create({
                title: 'Quote',
                id: 'context_menu_quote',
                targetUrlPatterns: ['chrome-extension://*/item'],
                contexts: ['link'],
            })
            chrome.contextMenus.create({
                title: 'All',
                id: 'context_menu_all',
                targetUrlPatterns: ['chrome-extension://*/*'],
                contexts: ['link'],
            })
        )

    whenSlotDeleted = (serv, name)->
        HototDaemon.unbindVerifier(serv, name)
        RelationService.unbind(serv, name)
        return

    verifySlot = (slot) ->
        client = ConnManager.getConn(slot.serv, slot.name)
        client.verify(
            (profile) -> 
                verifyOK(slot, profile)
            , () ->
                verifyError(slot)
        )
        client.getFollowings(slot.name
            , (ids) -> 
                RelationService.updateFollowingIds(slot.serv, slot.name, ids)
            , () ->
                Logger.info("Failed to get followings of #{slot.serv}/#{slot.key}")
        )
        return
    
    verifyOK = (slot, profile) ->
        SliderService.updateSlotAvatar(slot.serv, slot.name, profile.avatar_url)
        SliderService.updateSlotProfile(slot.serv, slot.name, profile)
        return

    verifyError = (slot) ->
        Logger.info("Failed to verify this slot #{slot.serv}/#{slot.key}")
        return

    refreshSlotList = () ->
        $scope.slots.length = 0
        for obj, i in SliderService.slotList
            $scope.slots.push(SliderService.slotList[i].slot)
        $scope.currentSlot = SliderService.currentSlot
        return

    $scope.hasNewMessage = () ->
        if SliderService.currentSlot
            count = MessageService.getNewMessageCount(SliderService.currentSlot.serv, SliderService.currentSlot.name)
            if count != 0
                return true
        return false

    $scope.toggleSearchMode = () ->
        if $scope.search_entry.expand
            $scope.leaveSearchMode()
        else
            $scope.enterSearchMode()

    $scope.enterSearchMode = () ->
        $scope.search_entry.expand = true
        $scope.search_layer.show = true
        $scope.search_layer.cls = 'slide'
        setTimeout(() ->
                document.querySelector('.search_entry').focus()
            , 500
        )
        return

    $scope.leaveSearchMode = () ->
        $scope.search_entry.expand = false
        $scope.search_layer.show = false
        $scope.search_layer.cls = ''

    $scope.searchLayerCls = () ->
        return $scope.search_layer.cls

    $scope.getSearchEntryStyles = () ->
        if $scope.search_entry.expand
            return { 'width': '180px'}
        return {'width': '0'}

    $scope.handleSearchEntryKeyup = (evt) ->
        if evt.keyCode == 27 #esc
            $scope.leaveSearchMode()
        else if evt.keyCode == 13
            keywords = $scope.search_entry.text.trim()
            search(keywords)

    search = (keywords) ->
        AppService.broadcast('search', {keywords: keywords})
        return

    $scope.selectSlot = (slot, index) ->
        SliderService.currentSlot = SliderService.slotList[index].slot
        SliderService.broadcast('change_slot')

    $scope.openColumnsDialog = () ->
        if SliderService.currentSlot
            DialogService.openColumnsDialog(SliderService.currentSlot)
        return

    $scope.openMessageDialog = () ->
        if SliderService.currentSlot
            MessageService.clearNewMessageCount(SliderService.currentSlot.serv, SliderService.currentSlot.name)
            DialogService.openMessageDialog(SliderService.currentSlot)
        return

    $scope.openProfileDialog = () ->
        if SliderService.currentSlot
            DialogService.openProfileDialog(SliderService.currentSlot)
        return

    # layour
    $scope.initApp = () ->
        # setUpContextMenu()
        HotkeyUtils.register([HotkeyUtils.CMD, 'N'], openComposeDialog)
        HotkeyUtils.register([HotkeyUtils.CMD, '1'], (evt) -> SliderService.triggerSlideTo(1))
        HotkeyUtils.register([HotkeyUtils.CMD, '2'], (evt) -> SliderService.triggerSlideTo(2))
        HotkeyUtils.register([HotkeyUtils.CMD, '3'], (evt) -> SliderService.triggerSlideTo(3))
        HotkeyUtils.register([HotkeyUtils.CMD, '4'], (evt) -> SliderService.triggerSlideTo(4))
        HotkeyUtils.register([HotkeyUtils.CMD, '5'], (evt) -> SliderService.triggerSlideTo(5))
        HotkeyUtils.register([HotkeyUtils.CMD, '6'], (evt) -> SliderService.triggerSlideTo(6))
        HotkeyUtils.register(['J'], (evt) -> SliderService.selectNextItem())
        HotkeyUtils.register(['K'], (evt) -> SliderService.selectPrevItem())
        HotkeyUtils.register(['H'], (evt) -> SliderService.triggerSlidePrev())
        HotkeyUtils.register(['L'], (evt) -> SliderService.triggerSlideNext())
        HotkeyUtils.register([HotkeyUtils.CMD, 'J'], (evt) -> SliderService.selectLastItem())
        HotkeyUtils.register([HotkeyUtils.CMD, 'K'], (evt) -> SliderService.selectFirstItem())
        HotkeyUtils.register([HotkeyUtils.CMD, 'R'], (evt) -> 
            replySelected()
        )
        HotkeyUtils.register([HotkeyUtils.CMD, 'T'], (evt) -> 
            repostSelected()
        )
        HotkeyUtils.register([HotkeyUtils.CMD, HotkeyUtils.SHIFT, 'T'], (evt) -> 
            quoteSelected()
        )
        HotkeyUtils.register([HotkeyUtils.CMD, HotkeyUtils.SHIFT, 'R'], (evt) -> 
            hotot.runtime.reload()
        )
        HotkeyUtils.register([HotkeyUtils.CMD, 'Q'], (evt) -> 
            window.close()
        )
        HotkeyUtils.register([HotkeyUtils.CMD, 'W'], (evt) -> 
            window.close()
        )
        HotkeyUtils.register([HotkeyUtils.CMD, 'I'], (evt) -> 
            DialogService.openPeopleDialog()
        ) 
        checkSlot(() ->
            HototSlot.all((slots) ->
                for slot in slots
                    HototDaemon.bindVerifier(slot.serv, slot.name, () ->
                        verifySlot(slot)
                    )
                    RelationService.bind(slot.serv, slot.name)
            )
            $scope.$apply(() ->
                refreshSlotList()
            )
        )

    $scope.guideHideCls = ->
        return if $scope.guide.fade_out then 'fade_out' else ''

    $scope.splashHideCls = ->
        return if $scope.splash.fade_out then 'fade_out' else ''

    $scope.guideAniEnd = ->
        $scope.guide.show = false
        if $scope.guide.show == false and $scope.splash.show == false
            $scope.masks.show = false

    $scope.splashAniEnd = ->
        $scope.splash.show = false
        if $scope.guide.show == false and $scope.splash.show == false
            $scope.masks.show = false

    $scope.hideGuide = ->
        $scope.guide.fade_out = true

    $scope.getNotifyBarLinkIcon = ->
        return $scope.notify_bar.link_icon        

    $scope.openComposeDialog = (evt)->
        openComposeDialog(evt)

    openComposeDialog = (evt)->
        DialogService.openComposeDialog(SliderService.currentSlot)
        return false

    $scope.currentSlotAvailable = ->
        return if SliderService.currentSlot then true else false

    $scope.openSettingsDialog = (evt) ->
        if evt.altKey
            DialogService.openLogDialog()
        else
            DialogService.openSettingsDialog()

    $scope.openNewSlotDialog = () ->
        DialogService.openNewSlotDialog()

    angular.element(window).bind('resize', () ->
        if resizeTimer
            clearTimeout(@resizeTimer)
        resizeTimer = setTimeout(triggerResize, 200)
    )

    # $scope.getCurrentAvatar = ->
    #     if SliderService.currentSlot
    #         return SliderService.currentSlot.avatar
    #     return ''

    $scope.handleKeydown = (evt) ->
        HotkeyUtils.crack(evt)
        return

    checkUpdate = ->
        Hotot.checkUpdate((result, ver, url) ->
            if result
                $scope.notify_bar.text = "A new version of Hotot is available!"
                $scope.notify_bar.link = url
                $scope.notify_bar.link_icon = "icon-download-alt"
                $scope.notify_bar.show = true
        )

    getSlotColumnNum = ->
        if SliderService.currentSlot
            return SliderService.currentSlot.columns.length
        return 0

    resize = () ->
        body = angular.element(document.querySelector('body'))[0]
        winWidth = body.clientWidth
        winHeight = body.clientHeight
        mainWidth = body.clientWidth #- 42 # 42px is the width of side
        mainHeight = body.clientHeight - 68 # 68px is the height of nav
        maxColNum = parseInt(mainWidth / 300) ? 1
        slotColNum = getSlotColumnNum()
        if slotColNum < maxColNum
            maxColNum = slotColNum
        if maxColNum > 0
            if maxColNum < 2
                $scope.props.composeBtnExpendClass = ""
            else
                $scope.props.composeBtnExpendClass = "expend"
        sizeInfo = 
            winWidth: winWidth
            winHeight: winHeight
            mainWidth: mainWidth
            mainHeight: mainHeight
            maxColNum: maxColNum
        setTimeout(() ->
                AppService.broadcast('resize', sizeInfo)
                Hotot.saveBounds()
            , 100
        )

    triggerResize = () ->
        resize()

    replySelected = () ->
        item = SliderService.getSelectedItem()
        if item
            DialogService.openComposeDialog(SliderService.currentSlot, 
                {   
                    type: "reply",
                    text: item.raw_text,
                    id: item.id,
                    author_name: item.author.name,
                    author_id: item.author.id,
                    author_avatar_data: item.author.avatar_url,
                    mentions: item.mentions
                }
            )

    replySelected = () ->
        item = SliderService.getSelectedItem()
        if item
            DialogService.openComposeDialog(SliderService.currentSlot, 
                {   
                    type: "reply",
                    text: item.raw_text,
                    id: item.id,
                    author_name: item.author.name,
                    author_id: item.author.id,
                    author_avatar_data: item.feature_pic_data,
                    mentions: item.mentions
                }
            )

    repostSelected = () ->
        item = SliderService.getSelectedItem()
        ok1 = (ret) ->
            item.reposted = true
            item.rt_id = ret.rt_id
        ok2 = (ret) ->
            item.reposted = false
            item.rt_id = ''
        err = () ->
            return
        client = ConnManager.getConn(SliderService.currentSlot.serv, SliderService.currentSlot.name)
        if item.reposted
            client.handleUndoRepost(item.rt_id, ok2, err)
        else
            client.handleRepost(item.id, ok1, err)
        return

    quoteSelected = () ->
        item = SliderService.getSelectedItem()
        if item
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

    return
])
