app = angular.module('HototPeopleDialog', [])

app.factory('Cache', ['$rootScope', ($rootScope) ->
    Cache = {}
    Cache.cache = {
        'timeline': []
        'follower': []
        'following': []
        'favorite': []
    }
    return Cache
])
app.controller('PeopleCtrl', ['$scope', 'Cache', ($scope, Cache) ->
    $scope.loading_mask =
        show: true
    $scope.user = Hotot.emptyUser()
    notSetUser = true
    notSetRel = true
    notSetBg = true
    majorAccount = null
    timers = {
        'timeline': 0,
        'follower': 0,
        'following': 0, 
        'favorite': 0
    }
    $scope.followButton = 
        disabled: true
        oldLabel: '...'
        label: '...'
        cls: 'disabled'
    $scope.columns = [
        {
            name: 'timeline'
            type: 'people'
            label: 'Timeline'
            default_placeholder_text: 'loading'
            items: []
            show: true
        },
        {
            name: 'follower'
            label: 'Follower'
            default_placeholder_text: 'loading'
            items: []
            show: false
        },
        {
            name: 'following'
            label: 'Following'
            default_placeholder_text: 'loading'
            items: []
            show: false
        },
        {
            name: 'favorite'
            label: 'Favorites'
            default_placeholder_text: 'loading'
            items: []
            show: false
        }
    ]
    currentColumn = $scope.columns[0]


    win = hotot.window.current()

    hotot.bus.onMessage.addListener((request, sender, senderResponse) ->
        if request.recipient != win.id
            return
        if request.cmd == 'set_people_account'
            majorAccount = request.content.major_account
        if request.cmd == 'set_people_user' and notSetUser 
            $scope.$apply(() ->
                setUser(request.content.user)
            )
        if request.cmd == 'set_people_relationship' and notSetRel
            $scope.$apply(() ->
                $scope.user.relationship = request.content.rel
                notSetRel = false
            )
    )

    $scope.$watch('user.relationship', () ->
        unlockFollowButton()
    )

    lockFollowButton = ->
        $scope.followButton.disabled = true
        $scope.followButton.oldLabel = '...'
        $scope.followButton.label = '...'
        $scope.followButton.cls = 'disabled'

    unlockFollowButton = ->
        $scope.followButton.disabled = false
        switch $scope.user.relationship
            when Hotot.RELATIONSHIP.FOLLOWING
                $scope.followButton.label = Hotot.RELATIONSHIP.FOLLOWING_STR
                $scope.followButton.cls = 'following'
            when Hotot.RELATIONSHIP.FRIENDS
                $scope.followButton.label = Hotot.RELATIONSHIP.FRIENDS_STR
                $scope.followButton.cls = 'following'
            when Hotot.RELATIONSHIP.SELF
                $scope.followButton.label = Hotot.RELATIONSHIP.SELF_STR
                $scope.followButton.cls = 'edit'
            when Hotot.RELATIONSHIP.FOLLOWED
                $scope.followButton.label = Hotot.RELATIONSHIP.FOLLOWED_STR
                $scope.followButton.cls = 'non_following'
            when Hotot.RELATIONSHIP.STRANGER
                $scope.followButton.label = Hotot.RELATIONSHIP.STRANGER_STR
                $scope.followButton.cls = 'non_following'
            when Hotot.RELATIONSHIP.BLOCKED
                $scope.followButton.label = Hotot.RELATIONSHIP.BLOCKED_STR
                $scope.followButton.cls = 'blocked'
            when Hotot.RELATIONSHIP.UNKNOWN
                if $scope.user.following
                    $scope.followButton.label = 'Following'
                    $scope.followButton.cls = 'following'
                else
                    $scope.followButton.label = 'Follow'
                    $scope.followButton.cls = 'non_following'

    setUser = (user) ->
        $scope.user = user
        $scope.user.id = user.id
        $scope.user.name = user.name
        $scope.user.display_name = user.display_name
        $scope.user.url = user.url
        $scope.user.description = user.description
        $scope.user.avatar_url = user.avatar_url
        $scope.user.background_url = user.background_url
        $scope.user.protected = user.protected
        $scope.user.statuses_count = user.statuses_count
        $scope.user.favorites_count = user.favorites_count
        $scope.user.friends_count = user.friends_count
        $scope.user.followers_count = user.followers_count
        $scope.user.following = user.following
        $scope.user.relationship = user.relationship
        unlockFollowButton()
        loadAvatar()
        loadBackground()
        $scope.loading_mask = true
        notSetUser = false

    loadAvatar = ->
        Hotot.fetchImage($scope.user.avatar_url, (data) ->
            $scope.$apply(() ->
                $scope.user.avatar = window.webkitURL.createObjectURL(data)
            )
        )

    loadBackground = ->
        Hotot.fetchImage($scope.user.background_url, (data) ->
            notSetBg = false
            $scope.$apply(() ->
                $scope.user.background = window.webkitURL.createObjectURL(data)
            )
        )

    editMode = ->
        return

    follow = ->
        handleResponse = (resp) ->
            if resp.result == 'ok'
                $scope.$apply(() ->
                    if $scope.user.relationship == Hotot.RELATIONSHIP.FOLLOWED
                        $scope.user.relationship = Hotot.RELATIONSHIP.FRIENDS
                    if $scope.user.relationship == Hotot.RELATIONSHIP.STRANGER
                        $scope.user.relationship = Hotot.RELATIONSHIP.FOLLOWING
                )
            else
                unlockFollowButton()
        lockFollowButton()
        hotot.bus.sendMessage(
            {
                role: 'column', cmd: "follow_people", content: {serv: majorAccount.serv, slot_name: majorAccount.name, user_name: $scope.user.name}
            }, (resp) ->
                handleResponse(resp)
        )
        return

    unfollow = ->
        handleResponse = (resp) ->
            if resp.result == 'ok'
                $scope.$apply(() ->
                    if $scope.user.relationship == Hotot.RELATIONSHIP.FRIENDS
                        $scope.user.relationship = Hotot.RELATIONSHIP.FOLLOWED
                    if $scope.user.relationship == Hotot.RELATIONSHIP.FOLLOWING
                        $scope.user.relationship = Hotot.RELATIONSHIP.STRANGER
                )
            else
                unlockFollowButton()
        lockFollowButton()
        hotot.bus.sendMessage(
            {
                role: 'column', cmd: "unfollow_people", content: {serv: majorAccount.serv, slot_name: majorAccount.name, user_name: $scope.user.name}
            }, (resp) ->
                handleResponse(resp)
        )
        return 

    $scope.block = () ->
        handleResponse = (resp) ->
            if resp.result == 'ok'
                $scope.$apply(() ->
                    $scope.user.relationship = Hotot.RELATIONSHIP.BLOCKED
                )
            else
                unlockFollowButton()
        lockFollowButton()
        hotot.bus.sendMessage(
            {
                role: 'column', cmd: "block_people", content: {serv: majorAccount.serv, slot_name: majorAccount.name, user_name: $scope.user.name}
            }, (resp) ->
                handleResponse(resp)
        )
        return

    unblock = () ->
        handleResponse = (resp) ->
            if resp.result == 'ok'
                $scope.$apply(() ->
                    $scope.user.relationship = Hotot.RELATIONSHIP.STRANGER
                )
            else
                unlockFollowButton()
        lockFollowButton()
        hotot.bus.sendMessage(
            {
                role: 'column', cmd: "unblock_people", content: {serv: majorAccount.serv, slot_name: majorAccount.name, user_name: $scope.user.name}
            }, (resp) ->
                handleResponse(resp)
        )
        return

    timeout = (name) ->
        now = Date.now() 
        ret = if now - timers[name] > 60000 then false else true
        timers[name] = now
        return ret

    $scope.markSpam = () ->
        handleResponse = (resp) ->
            if resp.result == 'ok'
                $scope.$apply(() ->
                    $scope.user.relationship = Hotot.RELATIONSHIP.BLOCKED
                )
            else
                unlockFollowButton()
        lockFollowButton()
        hotot.bus.sendMessage(
            {
                role: 'column', cmd: "mark_spam_people", content: {serv: majorAccount.serv, slot_name: majorAccount.name, user_name: $scope.user.name}
            }, (resp) ->
                handleResponse(resp)
        )
        return

    $scope.followButtonAction = ->
        if $scope.followButton.disabled 
            return
        switch $scope.followButton.cls
            when 'edit'
                editMode()
            when 'non_following'
                follow()
            when 'following'
                unfollow()
            when 'blocked'
                unblock()
            else
                return

    $scope.selectTab = (name) ->          
        if currentColumn.name != name and not timeout(name)
            hotot.bus.sendMessage(
                {
                    role: 'column', cmd: "do_load_people_#{name}", content: {serv: majorAccount.serv, slot_name: majorAccount.name, win_id: win.id, user_name: $scope.user.name}
                }, (resp) ->
                    handleResponse(resp)
            )
        for col, idx in $scope.columns
            if col.name == name
                $scope.columns[idx].show = true
                currentColumn = $scope.columns[idx]
            else
                $scope.columns[idx].show = false
        console.log "Click #{name}"
        return

    $scope.getTabCls = (index) ->
        return if $scope.columns[index].show then 'selected' else ''

    $scope.followButtonMouseEnter = ->
        if $scope.followButton.disabled 
            return
        switch $scope.user.relationship
            when Hotot.RELATIONSHIP.FOLLOWING, Hotot.RELATIONSHIP.FRIENDS
                $scope.followButton.label = 'Unfollow'
            when Hotot.RELATIONSHIP.FOLLOWED, Hotot.RELATIONSHIP.STRANGER
                $scope.followButton.label = 'Follow'
            when Hotot.RELATIONSHIP.BLOCKED
                $scope.followButton.label = 'Unblock'
            when Hotot.RELATIONSHIP.SELF
                $scope.followButton.label = 'Edit Profile'
            when Hotot.RELATIONSHIP.UNKNOWN
                if $scope.user.following
                    $scope.followButton.label = 'Unfollow'
                else
                    $scope.followButton.label = 'Follow'

    $scope.followButtonMouseLeave = ->
        if $scope.followButton.disabled 
            return
        unlockFollowButton()

    $scope.getTabCount = (colName) ->
        switch colName
            when 'timeline'
                return $scope.user.statuses_count
            when 'following'
                return $scope.user.friends_count
            when 'follower'
                return $scope.user.followers_count
            when 'favorite'
                return $scope.user.favorites_count
            else 
                return ''

    $scope.mention = ->
        hotot.bus.sendMessage({
            role: 'column', cmd: "mention_people", content: {serv: majorAccount.serv, slot_name: majorAccount.name, name: $scope.user.name}
        })

    $scope.openMessageDialog = ->
        hotot.bus.sendMessage({
            role: 'column', cmd: "message_people", content: {serv: majorAccount.serv, slot_name: majorAccount.name, name: $scope.user.name}
        })
        return

    $scope.addToColumn = ->
        params = [$scope.user.name]
        handleResponse = (resp) ->
            if resp.result and resp.result == 'ok'
                console.log "OK"
                window.close()
            else
                console.log "Error, reason: #{resp.reason}"
            return
        hotot.bus.sendMessage(
            {
                'role': 'columns_dialog', 
                'cmd': "create_column", 
                'content': {account: majorAccount, type: currentColumn.type, params: params}
            }, (resp) ->
                handleResponse(resp)
        )
        return

    $scope.hasWebsite = ->
        return $scope.user.url != null

    $scope.hasDescription = ->
        return $scope.user.description != null

    $scope.getVCardStyles = ->
        if not notSetBg
            return {'background-image': 'url(' + $scope.user.background + ')'}
        else
            return {'background-image': 'url(/images/mask.png)'}
])

app.controller('PeopleColumnCtrl', ['$scope', 'Cache', ($scope, Cache) ->
    $scope.placeholder = 
        text: 'loading...'
        details: 'please wait a moment'
        show: true
    $scope.items = []
    $scope.peopleList = []
    delegatedListeners = {}
    majorAccount = null
    column = {}
    $scope.settings = null
    now = null
    win = hotot.window.current()


    hotot.bus.onMessage.addListener((request, sender, senderResponse) ->
        if request.recipient != win.id
            return
        console.log request
        if request.cmd == 'set_people_account'
            majorAccount = request.content.major_account
        if request.cmd == "set_people_#{column.name}"
            if request.result == 'error'
                setError('failed to load content', request.reason)
            else
                if request.cmd == 'set_people_follower' or request.cmd == 'set_people_following'
                    $scope.$apply(() ->
                        $scope.settings = request.content.settings
                        setPeopleList(request.content.people_list)
                    )
                else
                    $scope.$apply(() ->
                        $scope.settings = request.content.settings
                        setTimeline(request.content.items)
                    )

    )

    setError = (error, reason) ->
        $scope.$apply(() ->
            $scope.placeholder.text = error
            $scope.placeholder.details = reason
            $scope.placeholder.show = true
        )

    setTimeline = (items) ->
        $scope.items = items
        if $scope.items.length == 0
            $scope.placeholder.text = 'no more content'
            $scope.placeholder.details = ':)'
            $scope.placeholder.show = true
        else
            $scope.placeholder.show = false
        now = new Date()

    setPeopleList = (peopleList) ->
        $scope.peopleList = peopleList
        if $scope.peopleList.length == 0
            $scope.placeholder.text = 'no more people'
            $scope.placeholder.details = ':)'
        else
            $scope.placeholder.show = false
        now = new Date()

    follow = (people)->
        handleResponse = (resp) ->
            if resp.result == 'ok'
                $scope.$apply(() ->
                    people.following = true
                )
        hotot.bus.sendMessage(
            {
                role: 'column', cmd: "follow_people", content: {serv: majorAccount.serv, slot_name: majorAccount.name, user_name: people.name}
            }, (resp) ->
                handleResponse(resp)
        )
        return

    unfollow = (people)->
        handleResponse = (resp) ->
            if resp.result == 'ok'
                $scope.$apply(() ->
                    people.following = false
                )
        hotot.bus.sendMessage(
            {
                role: 'column', cmd: "unfollow_people", content: {serv: majorAccount.serv, slot_name: majorAccount.name, user_name: people.name}
            }, (resp) ->
                handleResponse(resp)
        )
        return 

    $scope.hasItems = ->
        return if $scope.items.length != 0 then true else false

    $scope.hasPeople = ->
        return if $scope.peopleList.length != 0 then true else false

    $scope.hasContent = ->
        return $scope.hasPeople() or $scope.hasItems()

    $scope.initColumn = (col) ->
        column = col
        $scope.items = Cache.cache[column.name]
        $scope.placeholder.text = column.default_placeholder_text
        $scope.placeholder.details = ':)'
        delegatedClick('user_link', onUserlinkClick)
        return

    # overlayed
    delegatedClick = (cls, callback) ->
        if delegatedListeners.hasOwnProperty(cls)
            delegatedListeners[cls] = null
        delegatedListeners[cls] = callback
        return 

    onUserlinkClick = (evt) ->
        username = Hotot.getNameFromURL(evt.target.href)
        hotot.bus.sendMessage({
            role: 'column', cmd: "do_view_people", content: {serv: majorAccount.serv, slot_name: majorAccount.name, user_name: username}
        })
        evt.preventDefault()

    $scope.onDelegatedClick = (evt) ->
        for cls in evt.target.classList
            if delegatedListeners.hasOwnProperty(cls)
                delegatedListeners[cls](evt)
                return false
        return true

    $scope.openMediaPreview = (item) ->
        hotot.bus.sendMessage({
            role: 'column', cmd: "do_preview_media", content: {media: item.media}
        })

    $scope.getPeopleFollowCls = (people) ->
        if people.following
            return 'red'
        else
            if people.protected
                return ''
            else
                return 'blue'

    $scope.getPeopleFollowStatus = (people) ->
        if people.following
            return 'is following'
        else
            return 'not follow yet'

    $scope.getPeopleOpLabel = (people) ->
        if people.following
            return 'Unfollow'
        else
            if people.protected
                return 'Request'
            else
                return 'Follow'

    $scope.doPeopleOp = (people, evt) ->
        if people.following
            unfollow(people)
        else
            if people.protected
                return true
            else
                follow(people)
        evt.preventDefault()
        return

    $scope.doItemReply = (item) ->
        hotot.bus.sendMessage({
            role: 'column', cmd: "do_reply_item", content: {serv: majorAccount.serv, slot_name: majorAccount.name, item: item}
        })

    $scope.doItemFav = (item) ->
        hotot.bus.sendMessage({
            role: 'column', cmd: "do_fav_item", content: {serv: majorAccount.serv, slot_name: majorAccount.name, item: item}
        }, (resp) ->
            if resp.result == 'ok'
                item.favorited = resp.favorited
            else
                console.log "Failed to fav item"
        )

    $scope.doItemRepost = (item) ->
        hotot.bus.sendMessage({
            role: 'column', cmd: "do_repost_item", content: {serv: majorAccount.serv, slot_name: majorAccount.name, item: item}
        }, (resp) ->
            if resp.result == 'ok'
                item.reposted = resp.reposted
                if item.reposted == true
                    item.rt_id = resp.item.rt_id
                else 
                    item.rt_id = ''
            else
                console.log "Failed to reposted item"
        )

    $scope.doItemQuote = (item) ->
        hotot.bus.sendMessage({
            role: 'column', cmd: "do_quote_item", content: {serv: majorAccount.serv, slot_name: majorAccount.name, item: item}
        })

    $scope.doItemDelete = (item) ->
        hotot.bus.sendMessage({
            role: 'column', cmd: "do_delete_item", content: {serv: majorAccount.serv, slot_name: majorAccount.name, item: item}
        }, (resp) ->
            if resp.result == 'ok'
                pos = -1
                # @TODO use bsearch
                for it, i in $scope.items
                    if it.id == item.id
                        pos = i
                        break
                if pos != -1
                    $scope.items.splice(pos, 1)
            else
                console.log "Failed to delete item"
        )
        return

    # common method for column
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

    $scope.loadAvatar = (item) ->
        Hotot.fetchImage(item.avatar_url, (data) ->
            $scope.$apply(() ->
                item.avatar_data = window.webkitURL.createObjectURL(data)
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
        if $scope.settings
            return {'line-height': $scope.settings.line_height.value, 'font-size': $scope.settings.font_size.value + 'pt'}    
        return {}

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
