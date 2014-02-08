root = exports ? this

root.app.factory('MessageService', ['$rootScope', 'SliderService', 'HototSlot', 'HototCache', 'ColumnsState', 'HototDaemon', 'ConnManager', 'Logger'
($rootScope, SliderService, HototSlot, HototCache, ColumnsState, HototDaemon, ConnManager, Logger) ->
    MessageService = {}
    MessageService.conversations = {}
    MessageService.states = {}
    MessageService.badge = {}
    firstTime = {}
    
    MessageService.init = ->
        HototSlot.all((slots) ->
            for slot in slots
                MessageService.bind(slot.serv, slot.name)
        )
        return

    insertMessage = (cans, user, msg) ->
        if cans.hasOwnProperty(user.name)
            opts = {compare_mode: ColumnUtils.COMPARE_MODE_TIME}
            if cans[user.name].last_update < msg.timestamp
                cans[user.name].last_update = msg.timestamp
            return ColumnUtils.insert(cans[user.name].messages, msg, opts)
        cans[user.name] = 
            last_update: msg.timestamp
            user: user
            messages: [msg]
        return 1

    constructConverationsUniversal = (cans, messages) ->
        tot = 0
        for msg in messages
            user = null
            if msg.sender.name == SliderService.currentSlot.name
                user = msg.recipient
            else if msg.recipient.name == SliderService.currentSlot.name
                user = msg.sender
            if user
                tot += insertMessage(cans, user, msg)
        Logger.info("Insert #{tot} items into Message List")
        return tot

    constructConverationsIncoming = (cans, incomes) ->
        tot = 0
        for msg in incomes
            if msg.sender
                user = msg.sender
                tot += insertMessage(cans, user, msg)
        Logger.info("Insert #{tot} items into Message List")
        return tot

    constructConverationsSent = (cans, sents) ->
        tot = 0
        for msg in sents
            if msg.recipient
                user = msg.recipient
                tot += insertMessage(cans, user, msg)
        Logger.info("Insert #{tot} items into Message List")
        return tot

    updateState = (key, items) ->
        if items.length != 0
            switch MessageService.states[key].position_mode
                when 'id'
                    MessageService.states[key].since_id = items[0].id
        return

    getNewIncomes = (key, items) ->
        news = []
        for msg, i in items
            ret = ColumnUtils.compareId(MessageService.states[key].since_id, msg.id) 
            console.log MessageService.states[key].since_id, msg.id
            if ret == -1
                news.push(msg)
            else
                break
        return news

    liveTimeFetch = (keySlot, keyIncoming, keySent, client)->
        posArg1 = ''
        posArg3 = ''
        if not MessageService.conversations.hasOwnProperty(keySlot)
            MessageService.conversations[keySlot] = {}
        cans = MessageService.conversations[keySlot]
        switch MessageService.states[keyIncoming].position_mode
            when 'id'
                posArg1 = MessageService.states[keyIncoming].since_id
            when 'page'
                pasArg1 = MessageService.states[keyIncoming].page
        switch MessageService.states[keySent].position_mode
            when 'id'
                posArg3 = MessageService.states[keySent].since_id
            when 'page'
                pasArg3 = MessageService.states[keySent].page
        client.handleColumnLoad(
                type: 'incoming_message'
                position_arg1: posArg1
            , (incomes) -> 
                constructConverationsIncoming(cans, incomes)
                if not firstTime[keySlot]
                    newIncomes = getNewIncomes(keyIncoming, incomes)
                    # console.log newIncomes, newIncomes.length
                    MessageService.setBadge(keySlot, newIncomes.length)
                if firstTime[keySlot]
                    firstTime[keySlot] = false
                updateState(keyIncoming, incomes)
                client.handleColumnLoad(
                        type: 'sent_message'
                        position_arg1: posArg3
                    , (sents) -> 
                        constructConverationsSent(cans, sents)
                        updateState(keySent, sents)
                )
        )
        return

    MessageService.setBadge = (keySlot, count) ->
        if count != 0
            MessageService.badge[keySlot] += 1
        return

    MessageService.clearBadge = (keySlot) ->
        MessageService.badge[keySlot] = 0
        return

    MessageService.getNewMessageCount = (serv, slotName) ->
        keySlot = "#{serv}/#{slotName}"
        return MessageService.badge[keySlot]

    MessageService.clearNewMessageCount = (serv, slotName) ->
        keySlot = "#{serv}/#{slotName}"
        return MessageService.clearBadge(keySlot)

    MessageService.bind = (serv, slotName) ->
        client = ConnManager.getConn(serv, slotName)
        proto = ConnManager.getProto(serv)
        colIncoming = "incoming_message"
        colSent = "sent_message"
        keyIncoming = "#{serv}/#{slotName}/#{colIncoming}"
        keySent = "#{serv}/#{slotName}/#{colSent}"
        keyPrefix = "#{serv}/#{slotName}"
        # bind to column state
        MessageService.states[keyIncoming] = ColumnsState.bind(keyIncoming, proto.getColumnPositionMode(colIncoming))
        MessageService.states[keySent] = ColumnsState.bind(keySent, proto.getColumnPositionMode(colSent))
        # bind to daemon
        HototDaemon.bind(keyPrefix, proto.messageUpdateInterval, () ->
            liveTimeFetch(keyPrefix, keyIncoming, keySent, client)
        )
        # bind to stream 
        if client.supportStream and client.supportSubStream['message']
            HototDaemon.bindStream(serv, slotName, 'message', 'message', (items) ->
                incomes = []
                for msg in items
                    if msg.sender.name != SliderService.currentSlot.name
                        incomes.push(msg)
                MessageService.setBadge(keyPrefix, incomes.length)
                updateState(keyIncoming, incomes)
                MessageService.add(serv, slotName, items)
            )
        MessageService.badge[keyPrefix] = 0
        firstTime[keyPrefix] = true
        return

    MessageService.unbind = (serv, slotName) ->
        client = ConnManager.getConn(serv, slotName)
        colIncoming = "incoming_message"
        colSent = "sent_message"
        keyIncoming = "#{serv}/#{slotName}/#{colIncoming}"
        keySent = "#{serv}/#{slotName}/#{colSent}"
        keyPrefix = "#{serv}/#{slotName}"
        ColumnsState.unbind(keyIncoming)
        ColumnsState.unbind(keySent)
        HototCache.unbind(keyIncoming)
        HototCache.unbind(keySent)
        if client.supportStream and client.supportSubStream['message']
            HototDaemon.unbindStream(serv, slotName, 'message', 'message')
        HototDaemon.unbind(keyPrefix)
        delete MessageService.states[keyIncoming]
        delete MessageService.states[keySent]
        delete MessageService.conversations[keyPrefix]
        return

    MessageService.add = (serv, slotName, messages) ->
        keyPrefix = "#{serv}/#{slotName}"
        if not MessageService.conversations.hasOwnProperty(keyPrefix)
            MessageService.conversations[keyPrefix] = {}
        cans = MessageService.conversations[keyPrefix]
        constructConverationsUniversal(cans, messages)
        hotot.bus.sendMessage(
             {'role': 'MessageService', 'cmd': "new_messages", 'content': {serv: serv, slot_name: slotName, messages: messages}}
        )
        return

    return MessageService
])
