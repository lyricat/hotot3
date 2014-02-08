root = exports ? this

root.app.factory('DialogService', ['AppService', 'HototSlot', 'HototColumn', 'HototDraft', 'Logger', 'MessageService', 'ConnManager', 'SettingsService', 'SliderService'
(AppService, HototSlot, HototColumn, HototDraft, Logger, MessageService, ConnManager, SettingsService, SliderService) ->
    DialogService = {}
    DialogService.dialogArgs = 
        'compose': { url: 'dialogs/compose.html', w: 460, h: 164, frame: 'chrome', resizable: false }
        'new_slot': {id: 'new_slot', url: 'dialogs/new_slot.html', w: 560, h: 340, frame: 'chrome', resizable: false }
        'settings': {id: 'settings', url: 'dialogs/settings.html', w: 640, h: 440, frame: 'chrome', resizable: false }
        'columns': {id: 'columns', url: 'dialogs/columns.html', w: 440, h: 440, frame: 'chrome', resizable: true }
        'message': {id: 'message', url: 'dialogs/message.html', w: 560, h: 340, frame: 'chrome', resizable: false }
        'log': {id: 'log', url: 'dialogs/log.html', w: 640, h: 440, frame: 'chrome', resizable: true }
        'preview': { url: 'dialogs/preview.html', w: 640, h: 440, frame: 'chrome', resizable: true }
        'people': { url: 'dialogs/people.html', w: 400, h: 600, frame: 'chrome', resizable: true}
        'profile': {id: 'profile', url: 'dialogs/profile.html', w: 400, h: 360, frame: 'chrome', resizable: false}

    DialogService.isNative = true

    DialogService.open = (name, overlayArgs, callback) ->
        open = if DialogService.isNative then DialogService.openNativeDialog else DialogService.openSimulativeDialog
        if not DialogService.dialogArgs.hasOwnProperty(name)
            return null
        args = angular.extend(DialogService.dialogArgs[name], {})
        if overlayArgs
            args.w = overlayArgs.w or args.w
            args.h = overlayArgs.h or args.h
            args.id = overlayArgs.id or undefined
        return open(name, args, callback)

    DialogService.openNativeDialog = (name, args, callback) ->
        left = parseInt(screen.width/2 - args.w/2)
        top = parseInt((screen.height/2 - args.h/2)*0.8)
        hotot.window.create(
            args.url + "?" + Date.now(),
            {
                id: args.id,
                type: "shell",
                width: args.w,
                height: args.h,
                top: top,
                left: left,
                frame: args.frame,
                resizable: args.resizable,
            }
            ,
            callback)

    # public
    DialogService.openComposeDialog = (majorAccount, context={}, media=null, callback) ->
        id = 'compose-' + Hotot.generateUUID()
        accounts = []
        for slotObj in SliderService.slotList
            accounts.push(slotObj.slot)
        HototDraft.all((drafts) ->
            DialogService.open(
                'compose'
                {id: id}
                (win) -> 
                    setTimeout(() ->
                            hotot.bus.sendMessage(
                                {
                                    recipient: id,
                                    role: 'main', 
                                    cmd: "reset_composer", 
                                    content: {
                                        major_account: majorAccount, 
                                        accounts: accounts, 
                                        context: context, 
                                        drafts: drafts, 
                                        media: media,
                                    }
                                }
                            )
                        , 100
                    )
                    if callback then callback(win)
                    return
            )
        )
        return

    DialogService.openColumnsDialog = (majorAccount, callback) ->
        accounts = []
        columnMap = {}
        for slotObj in SliderService.slotList
            accounts.push(slotObj.slot)
        HototColumn.all((columns) -> 
            for col in columns
                slotKey = "#{col.serv}/#{col.slot_name}"
                if columnMap.hasOwnProperty(slotKey)
                    columnMap[slotKey].push(col)
                else
                    columnMap[slotKey] = [col]
            for acc in accounts
                slotKey = "#{acc.serv}/#{acc.name}"
                proto = ConnManager.getProto(acc.serv)
                ret = ColumnUtils.makeColumnOrder(proto.formalizeColumn, acc.columns, columnMap[slotKey])
                columnMap[slotKey] = ret[0]
            DialogService.open('columns', {}, (win) -> 
                setTimeout(() ->
                        hotot.bus.sendMessage({
                            'role': 'dialog_service',
                            'cmd': "reset_columns_dialog",
                            'content': {
                                column_map: columnMap, 
                                column_types: proto.getColumnTypes(),
                                accounts: accounts, 
                                major_account: majorAccount,
                                global_mute: SettingsService.getMute()
                            }
                        })
                    , 200
                )
                if callback then callback(win)
            )
        )
        return

    DialogService.openPeopleDialog = (majorAccount, user, callback) ->
        id = 'people-' + Hotot.generateUUID()
        win = DialogService.open('people', {id: id}, (win) ->
            setTimeout(() ->
                    hotot.bus.sendMessage(
                        {
                            recipient: id,
                            role: 'main', 
                            cmd: "set_people_account", 
                            content: {
                                major_account: majorAccount
                            }
                        }
                    )
                , 100
            )
            if user
                setTimeout(() ->
                        hotot.bus.sendMessage(
                            {
                                recipient: id,
                                role: 'main', 
                                cmd: "set_people_user", 
                                content: { user: user }
                            }
                        )
                    , 100
                )
            callback(win)
        )

    DialogService.openProfileDialog = (majorAccount, callback) ->
        accounts = []
        for slotObj in SliderService.slotList
            accounts.push(slotObj.slot)
        DialogService.open('profile', {}, (win) -> 
            setTimeout(() ->
                    hotot.bus.sendMessage(
                        {
                            role: 'main', 
                            cmd: "reset_profile", 
                            content: {
                                major_account: majorAccount, 
                                accounts: accounts, 
                            }
                        }
                    )
                , 100
            )
        )
        return

    DialogService.openNewSlotDialog = ->
        win = DialogService.open('new_slot')

    DialogService.openSettingsDialog = ->
        settings = SettingsService.settings
        accounts = []
        for slotObj in SliderService.slotList
            accounts.push(slotObj.slot)
        DialogService.open('settings', {}, (win) ->
            setTimeout(() ->
                    hotot.bus.sendMessage(
                        {
                            'role': 'main', 
                            'cmd': "reset_settings", 
                            'content': {
                                'settings': settings, 
                                'accounts': accounts
                            }
                        }
                    )
                , 100
            )
        )

    DialogService.openMessageDialog = (majorAccount, context={}) ->
        accounts = []
        for slotObj in SliderService.slotList
            accounts.push(slotObj.slot)
        conversations = MessageService.conversations
        DialogService.open('message', {}, (win) ->
            setTimeout(() ->
                    hotot.bus.sendMessage(
                         {'win': 'main', 'cmd': "reset_message", 'content': 
                            {
                                conversations: conversations,
                                accounts: accounts,
                                major_account: majorAccount,
                                context: context
                             }
                         }
                    )
                , 100
            )
        )
        return

    DialogService.openLogDialog = ->
        logs = Logger.logs
        win = DialogService.open('log', {}, (win) ->
            setTimeout(() ->
                    hotot.bus.sendMessage(
                         {'win': 'main', 'cmd': "reset_log", 'content': {'logs': logs}}
                    )
                , 100
            )
        )
        return

    DialogService.openPreviewDialog = (opts, media) ->
        id = 'preview-' + Hotot.generateUUID()
        win = DialogService.open('preview', {id: id}, (win) ->
            setTimeout(() ->
                    hotot.bus.sendMessage(
                         {role: 'main', recipient: id, cmd: "reset_preview", content: {opts: opts, media: media}}
                    )
                , 100
            )
        )
        return

    return DialogService
])
