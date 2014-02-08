root = exports ? this

root.app.factory('HototBus', ['$rootScope', 'AppService', 'NotifyService', 'DialogService', 'SliderService', 'RelationService', 'HototSlot', 'HototColumn', 'HototDraft', 'ConnManager','HototDaemon','SettingsService', 'Logger', 'MessageService'
($rootScope, AppService, NotifyService, DialogService, SliderService, RelationService, HototSlot, HototColumn, HototDraft, ConnManager,HototDaemon,SettingsService, Logger, MessageService) ->
    HototBus = {}
    HototBus.msgMap = {}
    HototBus.message = null
    HototBus.igniteAttachment = 
        base64_data: null
        raw_data: null
        filename: ""
        type: ""
        size: ""
        file: null
    HototBus.stopAuth = false

    HototBus.register = (cmd, callback) ->
        if HototBus.msgMap.hasOwnProperty(cmd)
            HototBus.msgMap[cmd].push(callback)
        else
            HototBus.msgMap[cmd] = [callback]

    HototBus.init = () ->
        Logger.info("init message bus")
        notify = (win, cmd, content, respond) ->
            if HototBus.msgMap.hasOwnProperty(cmd)
                for callback in HototBus.msgMap[cmd]
                    callback(win, cmd, content, respond)

        hotot.bus.onMessage.addListener((message, sender, respond) ->
            # console.log('control', ev)
            win = message.win
            cmd = message.cmd
            content = message.content
            # console.log "Messagebus receives a message:", win, cmd, content
            HototBus.crack(win, cmd, content, respond)
            notify(win, cmd, content, respond)
            return true
        )

    HototBus.crack = (win, cmd, content, respond) ->
        switch cmd
            when 'auth'
                HototBus.auth(content.serv, content.username, content.password, respond)
            when 'oauth_get_authorize_url'
                HototBus.getOAuthAuthorizeURL(content.serv, content.username, respond)
            when 'oauth_with_pin'
                HototBus.OAuthPIN(content.serv, content.username, content.password, content.pin, respond)
            when 'cancel_auth'
                HototBus.stopAuth = true
            when 'auto_complete'
                HototBus.autoComplete(content.serv, content.text, respond)
            when 'ignite'
                HototBus.ignite(content, respond)
            when 'drop'
                HototBus.drop(content, respond)
            when 'update_profile'
                HototBus.updateProfile(content, respond)
            when 'update_avatar'
                HototBus.updateAvatar(content, respond)
            when 'share_media'
                HototBus.shareMedia(content.media, respond)
            when 'delete_draft'
                HototBus.deleteDraft(content.uuid, respond)
            when 'create_draft'
                HototBus.createDraft(content, respond)
            when 'create_account'
                HototBus.requestCreateAccount()
            when 'delete_account'
                HototBus.deleteAccount(content.serv, content.slot_name, respond)
            when 'create_column'
                HototBus.createColumn(content, respond)
            when 'delete_column'
                HototBus.deleteColumn(content, respond)
            when 'move_column'
                HototBus.moveColumn(content, respond)
            when 'save_column_mute'
                HototBus.saveColumnMute(content.account, content.col_name, content.mute, respond)
            when 'save_global_mute'
                HototBus.saveGlobalMute(content.mute, respond)
            when 'column_notify_on'
                HototBus.toggleColumnNotification(content, true, respond)
            when 'column_notify_off'
                HototBus.toggleColumnNotification(content, false, respond)
            when 'whisper'
                HototBus.whisper(content.key, content.value, respond)
            when 'follow_people'
                HototBus.followPeople(content.serv, content.slot_name, content.user_name, respond)
            when 'unfollow_people'
                HototBus.unfollowPeople(content.serv, content.slot_name, content.user_name, respond)
            when 'block_people'
                HototBus.blockPeople(content.serv, content.slot_name, content.user_name, respond)
            when 'unblock_people'
                HototBus.unblockPeople(content.serv, content.slot_name, content.user_name, respond)
            when 'mark_spam_people'
                HototBus.markSpamPeople(content.serv, content.slot_name, content.user_name, respond)
            when 'mention_people'
                HototBus.mentionPeople(content.serv, content.slot_name, content.name, respond)
            when 'message_people'
                HototBus.messagePeople(content.serv, content.slot_name, content.name, respond)
            when 'do_reply_item'
                HototBus.doReplyItem(content.serv, content.slot_name, content.item, respond)
            when 'do_fav_item'
                HototBus.doFavItem(content.serv, content.slot_name, content.item, respond)
            when 'do_repost_item'
                HototBus.doRepostItem(content.serv, content.slot_name, content.item, respond)
            when 'do_quote_item'
                HototBus.doQuoteItem(content.serv, content.slot_name, content.item, respond)
            when 'do_delete_item'
                HototBus.doDeleteItem(content.serv, content.slot_name, content.item, respond)
            when 'do_preview_media'
                HototBus.doPreviewMedia(content.media, respond)
            when 'do_view_people'
                HototBus.doViewPeople(content.serv, content.slot_name, content.user_name, respond)
            when 'do_load_people_timeline'
                HototBus.doLoadPeopleTimeline(content.serv, content.slot_name, content.user_name, content.win_id, respond)
            when 'do_load_people_follower'
                HototBus.doLoadPeopleFollower(content.serv, content.slot_name, content.user_name, content.win_id, respond)
            when 'do_load_people_following'
                HototBus.doLoadPeopleFollowing(content.serv, content.slot_name, content.user_name, content.win_id, respond)
            when 'do_load_people_favorite'
                HototBus.doLoadPeopleFavorite(content.serv, content.slot_name, content.user_name, content.win_id, respond)


    HototBus.createColumn = (content, respond) ->
        account = content.account
        type = content.type
        params = content.params
        SliderService.addColumn(account.serv, account.name, type, params, (ok, msg) ->
            if ok
                console.log "create column done."
                respond({result: 'ok', content: {column: msg}})
            else
                console.log "create column failed, error: #{msg}"
                respond({result: 'error', reason: "failed to create the column"})
        )
        return

    HototBus.deleteColumn = (content, respond) ->
        account = content.account
        name = content.name
        SliderService.removeColumn(account.serv, account.name, name, (ok, msg) ->
            if ok
                console.log "delete column #{account.serv}/#{account.name}/#{name} done."
                respond({result: 'ok', content: {name: name}})
            else
                console.log "delete column #{account.serv}/#{account.name}/#{name} failed, error: #{msg}"
                respond({result: 'error', reason: "failed to delete the column"})
        )
        return

    HototBus.moveColumn = (content, respond) ->
        account = content.account
        start = content.start
        drop = content.drop
        SliderService.moveColumn(start, drop)  

    HototBus.saveColumnMute = (account, colname, mute, respond) ->
        SliderService.updateColumnMute(account.serv, account.name, colname, mute, (ret, msg) ->
            if ret == true
                respond({result: 'ok'})
            else
                respond({result: 'error', reason: msg})
        )
        return

    HototBus.saveGlobalMute = (mute, respond) ->
        SettingsService.setMute(mute)
        respond({result: 'ok'})
        return

    HototBus.toggleColumnNotification = (content, value, respond) ->
        account = content.account
        name = content.name
        column = SliderService.getColumn(account.serv, account.name, name)
        column.notification = value
        SliderService.updateColumn(column, (ok, msg) ->
            if ok
                console.log "update column #{account.serv}/#{account.name}/#{name} done."
                respond({result: 'ok', content: {value: value}})
            else
                console.log "update column #{account.serv}/#{account.name}/#{name} failed, error: #{msg}"
                respond({result: 'error', reason: "failed to update the column"})
        )
        return 

    HototBus.deleteDraft = (uuid, respond) ->
        HototDraft.remove(uuid, () ->
            HototDraft.all((drafts)->
                respond({result: 'ok', content: {drafts: drafts}})
            )
        )
        return

    HototBus.createDraft = (content, respond) ->
        draft = HototDraft.buildDefaults()
        draft.text = content.text
        if content.context
            draft.context_type = content.context.type
            draft.context_text = content.context.text
            draft.context_id = content.context.id
        HototDraft.save(draft, () ->
            HototDraft.all((drafts)->
                respond({result: 'ok', content: {drafts: drafts}})
            )
        )
        return

    HototBus.requestCreateAccount = ->
        DialogService.openNewSlotDialog()
        return

    HototBus.deleteAccount = (serv, slotName) ->
        SliderService.removeSlot(serv, slotName, (ok) ->
            if ok
                HototSlot.all((accounts) ->
                    hotot.bus.sendMessage(
                        {
                            'win': 'main', 
                            'cmd': "reset_settings", 
                            'content': {
                                'settings': SettingsService.settings, 
                                'accounts': accounts
                            }
                        }
                    )
                )
                client = ConnManager.getConn(serv, slotName)
                HototColumn.getBySlot(serv, slotName, (columns) ->
                    for col in columns
                        if client.supportStream and client.supportSubStream[col.name]
                            HototDaemon.unbindStream(serv, slotName, col.name, col.name)
                        HototDaemon.unbind(serv, slotName, name)
                )
                HototDaemon.unbindVerifier(serv, slotName)  
                SliderService.removeColumnBySlot(serv, slotName, () ->)
        )
        return

    HototBus.autoComplete = (serv, text, respond) ->
        users = RelationService.find(serv, '*', text)
        respond({result: 'ok', items: users})

    HototBus.ignite = (content, respond) ->
        ok = (item) ->
            return
        err = () ->
            HototBus.createDraft(content, respond)
            Logger.info('Failed to update status, save as draft')
            return
        for account in content.accounts
            conn = ConnManager.getConn(account.serv, account.name)
            if conn
                if content.has_attachment
                    content.attachment.data = Hotot.dataURL2Uint8Array(content.attachment.base64_data)
                conn.handleComposerResult(content, ok, err)
            else
                Logger.info('conn is not available')

    HototBus.whisper = (key, value, respond) ->
        SettingsService.setForbiddens(key, value)
        NotifyService.notify("Whisper: #{key}=#{value}", "You may need to restart to take effects")

    HototBus.followPeople = (serv, slot_name, screen_name, respond) ->
        conn = ConnManager.getConn(serv, slot_name)
        conn.handleFollow(screen_name, (user) ->
            user = RelationService.getByName(serv, slot_name, screen_name)
            if user != null
                switch user.relationship
                    when Hotot.RELATIONSHIP.FOLLOWED
                        RelationService.setRelationship(serv, slot_name, user.name, Hotot.RELATIONSHIP.FRIENDS)
                        user.relationship = Hotot.RELATIONSHIP.FRIENDS
                    when Hotot.RELATIONSHIP.STRANGER
                        RelationService.setRelationship(serv, slot_name, user.name, Hotot.RELATIONSHIP.FOLLOWING)
                        user.relationship = Hotot.RELATIONSHIP.FOLLOWING
            respond({result: 'ok', content: {user: user}})
        )
        return 

    HototBus.unfollowPeople = (serv, slot_name, screen_name, respond) ->
        conn = ConnManager.getConn(serv, slot_name)
        conn.handleUnfollow(screen_name, (user) ->
            user = RelationService.getByName(serv, slot_name, screen_name)
            if user != null
                switch user.relationship
                    when Hotot.RELATIONSHIP.FOLLOWING
                        RelationService.setRelationship(serv, slot_name, user.name, Hotot.RELATIONSHIP.STRANGER)
                        user.relationship = Hotot.RELATIONSHIP.STRANGER
                    when Hotot.RELATIONSHIP.FRIENDS
                        RelationService.setRelationship(serv, slot_name, user.name, Hotot.RELATIONSHIP.FOLLOWED)
                        user.relationship = Hotot.RELATIONSHIP.FOLLOWED
            respond({result: 'ok', content: {user: user}})
        )
        return

    HototBus.blockPeople = (serv, slot_name, screen_name, respond) ->
        conn = ConnManager.getConn(serv, slot_name)
        conn.handleBlock(screen_name, (user) ->
            user = RelationService.getByName(serv, slot_name, screen_name)
            if user != null
                RelationService.setRelationship(serv, slot_name, user.name, Hotot.RELATIONSHIP.BLOCKED)
                user.relationship = Hotot.RELATIONSHIP.BLOCKED
            respond({result: 'ok', content: {user: user}})
        )
        return 

    HototBus.unblockPeople = (serv, slot_name, screen_name, respond) ->
        conn = ConnManager.getConn(serv, slot_name)
        conn.handleUnblock(screen_name, (user) ->
            user = RelationService.getByName(serv, slot_name, screen_name)
            if user != null
                RelationService.setRelationship(serv, slot_name, user.name, Hotot.RELATIONSHIP.STRANGER)
                user.relationship = Hotot.RELATIONSHIP.STRANGER
            respond({result: 'ok', content: {user: user}})
        )
        return

    HototBus.markSpamPeople = (serv, slot_name, screen_name, respond) ->
        conn = ConnManager.getConn(serv, slot_name)
        conn.handleMarkSpam(screen_name, (user) ->
            user = RelationService.getByName(serv, slot_name, screen_name)
            if user != null
                RelationService.setRelationship(serv, slot_name, user.name, Hotot.RELATIONSHIP.BLOCKED)
                user.relationship = Hotot.RELATIONSHIP.BLOCKED
            respond({result: 'ok', content: {user: user}})
        )
        return

    HototBus.mentionPeople = (serv, slot_name, name, respond) ->
        DialogService.openComposeDialog(SliderService.currentSlot, {response: "@#{name} "})
        return

    HototBus.messagePeople = (serv, slot_name, name, respond) ->
        DialogService.openMessageDialog(SliderService.currentSlot, {name: name})
        return

    HototBus.doPreviewMedia = (media, respond) ->
        opts = {}
        DialogService.openPreviewDialog(opts, media)

    HototBus.doViewPeople = (serv, slot_name, user_name, respond) ->
        rel = Hotot.RELATIONSHIP.UNKNOWN
        user = RelationService.getByName(serv, slot_name, user_name)
        slot = SliderService.getSlot(serv, slot_name)
        if slot == null then return
        client = ConnManager.getConn(serv, slot_name)
        timeout = (time) -> Date.now() - time > 3600000 # 1 hour.
        if user != null
            # @TODO should compare user.name with myself.name, not slot.name
            if Hotot.sameName(user.name, slot.name)
                user.relationship = Hotot.RELATIONSHIP.SELF
                rel = user.relationship
        DialogService.openPeopleDialog(slot, user, (win) ->
            if user == null or timeout(user.createTime)
                client.getUser(user_name, (user) ->
                    RelationService.add(serv, slot_name, [user])
                    if RelationService.isFollowing(serv, slot_name, user)
                        user.following = true
                    hotot.bus.sendMessage({recipient: win.id, role: 'column', cmd: "set_people_user", content: {'user': user}})
                )
            if rel == Hotot.RELATIONSHIP.UNKNOWN
                client.getRelationship(slot.name, user_name, (rel) ->
                    RelationService.setRelationship(serv, slot_name, user_name, rel)
                    hotot.bus.sendMessage({recipient: win.id, role: 'column', cmd: "set_people_relationship", content: {'rel': rel}})
                )
            client.handleColumnLoad(
                    type: 'people'
                    params: [user_name, '']
                    position_arg1: ''
                    position_arg2: ''
                , (items) -> 
                    hotot.bus.sendMessage({recipient: win.id, role: 'column', cmd: "set_people_timeline", content: {items: items, settings: SettingsService.settings}})
                , (data) ->
                    details = if data.constructor == String then data else JSON.stringify(data)
                    hotot.bus.sendMessage({recipient: win.id, role: 'column', cmd: "set_people_timeline", result: 'error', reason: details})
            )
        )

    HototBus.doLoadPeopleTimeline = (serv, slot_name, user_name, win_id, respond) ->
        client = ConnManager.getConn(serv, slot_name)
        client.handleColumnLoad(
                type: 'people'
                params: [user_name, '']
                position_arg1: ''
                position_arg2: ''
            , (items) -> 
                hotot.bus.sendMessage({recipient: win_id, role: 'column', cmd: "set_people_timeline", content: {items: items, settings: SettingsService.settings}})
            , (data) ->
                details = if data.constructor == String then data else JSON.stringify(data)
                hotot.bus.sendMessage({recipient: win_id, role: 'column', cmd: "set_people_timeline", result: 'error', reason: details})
        )
        return

    HototBus.doLoadPeopleFollower = (serv, slot_name, user_name, win_id, respond) ->
        client = ConnManager.getConn(serv, slot_name)
        client.handleColumnLoad(
                type: 'follower'
                params: [user_name, '']
                position_arg1: '-1'
                position_arg2: ''
            , (people_list) -> 
                hotot.bus.sendMessage({recipient: win_id, role: 'column', cmd: "set_people_follower", content: {people_list: people_list, settings: SettingsService.settings}})
            , (data) ->
                details = if data.constructor == String then data else JSON.stringify(data)
                hotot.bus.sendMessage({recipient: win_id, role: 'column', cmd: "set_people_follower", result: 'error', reason: details})
        )
        return

    HototBus.doLoadPeopleFollowing = (serv, slot_name, user_name, win_id, respond) ->
        client = ConnManager.getConn(serv, slot_name)
        client.handleColumnLoad(
                type: 'following'
                params: [user_name, '']
                position_arg1: '-1'
                position_arg2: ''
            , (people_list) -> 
                hotot.bus.sendMessage({recipient: win_id, role: 'column', cmd: "set_people_following", content: {people_list: people_list, settings: SettingsService.settings}})
            , (data) ->
                details = if data.constructor == String then data else JSON.stringify(data)
                hotot.bus.sendMessage({recipient: win_id, role: 'column', cmd: "set_people_following", result: 'error', reason: details})
        )
        return

    HototBus.doLoadPeopleFavorite = (serv, slot_name, user_name, win_id, respond) ->
        client = ConnManager.getConn(serv, slot_name)
        client.handleColumnLoad(
                type: 'favorite'
                params: [user_name, '']
                position_arg1: ''
                position_arg2: ''
            , (items) -> 
                hotot.bus.sendMessage({recipient: win_id, role: 'column', cmd: "set_people_favorite", content: {items: items, settings: SettingsService.settings}})
            , (data) ->
                details = if data.constructor == String then data else JSON.stringify(data)
                hotot.bus.sendMessage({recipient: win_id, role: 'column', cmd: "set_people_favorite", result: 'error', reason: details})
        )
        return

    HototBus.doReplyItem = (serv, slot_name, item, respond) ->
        slot = SliderService.getSlot(serv, slot_name)
        if slot == null then return
        DialogService.openComposeDialog(slot, 
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
        return

    HototBus.doQuoteItem = (serv, slot_name, item, respond) ->
        slot = SliderService.getSlot(serv, slot_name)
        if slot == null then return
        DialogService.openComposeDialog(slot, 
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

    HototBus.doFavItem = (serv, slot_name, item, respond) ->
        ok1 = () ->
            respond({result: 'ok', favorited: true})
        ok2 = () ->
            respond({result: 'ok', favorited: false})
        err = () ->
            respond({result: 'error', reason: 'Failed to fav item.'})
        client = ConnManager.getConn(serv, slot_name)
        if item.favorited
            client.handleUndoFav(item.id, ok2, err)
        else
            client.handleFav(item.id, ok1, err)

    HototBus.doRepostItem = (serv, slot_name, item, respond) ->
        ok1 = () ->
            respond({result: 'ok', reposted: true, item: item})
        ok2 = () ->
            respond({result: 'ok', reposted: false, item: item})
        err = () ->
            respond({result: 'error', reason: 'Failed to repost item.'})
        client = ConnManager.getConn(serv, slot_name)
        if item.favorited
            client.handleUndoRepost(item.rt_id, ok2, err)
        else
            client.handleRepost(item.id, ok1, err)

    HototBus.doDeleteItem = (serv, slot_name, item, respond) ->
        ok = () ->
            respond({result: 'ok'})
        err = () ->
            return
        client = ConnManager.getConn(serv, slot_name)
        client.handleDelete(item.id, ok, err)

    HototBus.doPreviewMedia = (media) ->
        opts = {}
        DialogService.openPreviewDialog(opts, media)

    HototBus.drop = (content, respond) ->
        ok = (msg) ->
            return
        err = () ->
            Logger.info('Failed to post message, save as draft')
            return
        if content.account
            conn = ConnManager.getConn(content.account.serv, content.account.name)
            if conn
                conn.handleMessagerResult(content, ok, err)
            else
                Logger.info('conn is not available')

    HototBus.updateProfile = (content, respond) ->
        ok = (profile) ->
            SliderService.updateSlotProfile(content.account.serv, content.account.name, profile)
            respond({result: 'ok', profile: profile})
            return
        err = () ->
            Logger.info('Failed to update profile')
            return
        if content.account
            conn = ConnManager.getConn(content.account.serv, content.account.name)
            if conn
                conn.handleUpdateProfile(content.profile, ok, err)
            else
                Logger.info('conn is not available')

    HototBus.updateAvatar = (content, respond) ->
        ok = (profile) ->
            # WORKAROUND: twitter responds the profile with old avatar url
            conn.verify(
                (updatedProfile) -> 
                    SliderService.updateSlotAvatar(content.account.serv, content.account.name, updatedProfile.avatar_url)
                    SliderService.updateSlotProfile(content.account.serv, content.account.name, updatedProfile)
                    respond({result: 'ok', profile: updatedProfile})
                , () ->
                    respond({result: 'ok', profile: profile})
            )
            return
        err = () ->
            Logger.info('Failed to update profile')
            return
        if content.account
            conn = ConnManager.getConn(content.account.serv, content.account.name)
            if conn
                content.avatar.data = Hotot.dataURL2Uint8Array(content.avatar.base64_data)
                conn.handleUpdateAvatar(content.avatar, ok, err)
            else
                Logger.info('conn is not available')

    HototBus.shareMedia = (media, respond) ->
        DialogService.openComposeDialog(SliderService.currentSlot, {}, media)
        return

    HototBus.getOAuthAuthorizeURL = (serv, username, respond) ->
        proto = ConnManager.getProto(serv)
        conn = ConnManager.createConn(serv, username)
        if conn
            url = conn.getAuthorizeURL()
            if url 
                respond({result: 'ok', content: {url: url}})
            else
                respond({result: 'error', reason: 'Failed to get Authorize URL.'})            
        else
            respond({result: 'error', reason: 'Failed to create connection.'})
        return

    HototBus.authPassProc = (serv, username, password, proto, conn) =>
        settings = {}
        angular.extend(settings, proto.getSettings())
        slot = HototSlot.buildDefaults(serv, username)
        slot.auth_type = conn.authType
        slot.password = if conn.authType == 'oauth' then "" else password
        slot.access_token = conn.accessToken
        slot.key = conn.key
        slot.secret = conn.secret
        slot.columns = []
        slot.settings = settings
        SliderService.addSlot(slot)

    HototBus.OAuthPIN = (serv, username, password, pin, respond) ->
        checkConn = (proto, conn) =>
            if HototBus.stopAuth
                respond({result: 'canceled', reason: ''})
                HototBus.stopAuth = false
                return
            console.log 'check conn'
            setTimeout(
                () =>
                    if conn.state == 1
                        HototSlot.exists(serv, username, (result) ->
                            if result
                                respond({result: 'error', reason: 'Account already exists.'})
                            else
                                HototBus.authPassProc(serv, username, password, proto, conn)
                                # console.log "Pass", conn.accessToken
                                respond({result: 'ok'})
                        )
                    else if conn.state == 0
                        checkConn(proto, conn)
                    else
                        respond({result: 'error', reason: 'Failed to add account, reason: ' + conn.err })
                ,
                    3000
            )

        HototSlot.exists(serv, username, (result) ->
            if result
                respond({result: 'error', reason: 'Account already exists.'})
            else
                proto = ConnManager.getProto(serv)
                conn = ConnManager.createConn(serv, username)
                if conn
                    conn.authPIN(pin)
                    checkConn(proto, conn)
                else
                    respond({result: 'error', reason: 'Failed to create connection.'})
        )
        return

    HototBus.auth = (serv, username, password, respond) ->
        checkConn = (proto, conn) =>
            if HototBus.stopAuth
                respond({result: 'canceled', reason: ''})
                HototBus.stopAuth = false
                return
            console.log 'check conn'
            setTimeout(
                () =>
                    if conn.state == 1
                        HototSlot.exists(serv, username, (result) ->
                            if result
                                respond({result: 'error', reason: 'Account already exists.'})
                            else
                                HototBus.authPassProc(serv, username, password, proto, conn)
                                respond({result: 'ok'})
                        )
                    else if conn.state == 0
                        checkConn(proto, conn)
                    else
                        respond({result: 'error', reason: 'Failed to add account, reason: ' + conn.err })
                ,
                    3000
            )

        HototSlot.exists(serv, username, (result) ->
            if result
                respond({result: 'error', reason: 'Account already exists.'})
            else
                proto = ConnManager.getProto(serv)
                conn = ConnManager.createConn(serv, username)
                if conn
                    conn.auth(username, password)
                    checkConn(proto, conn)
                else
                    respond({result: 'error', reason: 'Failed to create connection.'})
        )

    return HototBus
])
