root = exports ? this

BuildModel = (id, properties) ->
    model = {}
    model.id = id
    model.properties = properties
    model.listeners = []

    model.build = (kvPairs) ->
        inst = {}
        for k, v of kvPairs
            if model.hasOwnProperty(k)
                inst[k] = v
        return inst

    model.init = () ->
        hotot.storage.onChanged.addListener((changes, areaName) ->
            model.notify(changes, areaName)
        )
        model.initGlobalListener()

    model.initGlobalListener = () ->
        hotot.bus.onMessage.addListener((message, sender, respond) ->
            # console.log('control', ev)
            cmd = message.cmd
            if model.care and model.care.indexOf(cmd) != -1 # ignore careless messages
                console.info("Model #{model.id} receives a message: #{win} #{cmd} #{content}")
                win = message.win
                content = message.content
                if model.crack
                    model.crack(win, cmd, content, respond)
                return true
        )

    model.change = (callback) ->
        model.listeners.push(callback)

    model.notify = (changes, areaName) ->
        if changes.hasOwnProperty(model.id)
            cc = changes[model.id]
            for callback in model.listeners
                callback(cc.oldValue, cc.newValue)

    model.single = (cond, callback) ->
        hotot.storage.local.get(model.id, (result) ->
            items = result[model.id]
            if items
                for item in items
                    if cond
                        if cond(item)
                            if callback then callback(item)
                            return
                        else
                            continue
                    else
                        if callback then callback(item)
                        return
            if callback then callback(null)
        )
        return 

    model.select = (cond, callback) ->
        hotot.storage.local.get(model.id, (result) ->
            items = result[model.id]
            ret = []
            if items
                for item in items
                    if cond 
                        if cond(item)
                            ret.push(item)
                    else
                        ret.push(item)
                if callback then callback(ret)
            else
                if callback then callback([])
        )

    model.all = (callback) ->
        hotot.storage.local.get(model.id, (result) ->
            items = result[model.id]
            if items
                if callback then callback(items)
            else
                if callback then callback([])
        )

    model.size = (callback) ->
        hotot.storage.local.get(model.id, (result) ->
            items = result[model.id]
            if items
                if callback then callback(items.length)
            else
                if callback then callback(0)
        )

    model.save = (item, callback) ->
        hotot.storage.local.get(model.id, (result) ->
            items = result[model.id]
            if items
                items.push(item)
            else
                items = [item]
            pair = {}
            pair[model.id] = items
            if callback
                hotot.storage.local.set(pair, callback)
            else
                hotot.storage.local.set(pair)
        )
        return

    model.saveMany = (newItems, callback) ->
        hotot.storage.local.get(model.id, (result) ->
            items = result[model.id]
            if items
                items = items.concat(newItems)
            else
                items = newItems
            pair = {}
            pair[model.id] = items
            if callback
                hotot.storage.local.set(pair, callback)
            else
                hotot.storage.local.set(pair)
        )
        return

    model.replace = (value, callback) ->
        pair = {}
        pair[model.id] = value
        if callback
            hotot.storage.local.set(pair, callback)
        else
            hotot.storage.local.set(pair)
        return

    model.delete = (cond, callback) ->
        hotot.storage.local.get(model.id, (result) ->
            items = result[model.id]
            if items
                items = items.filter((x) ->
                    return if cond then not cond(x) else false
                )
                pair = {}
                pair[model.id] = items
                hotot.storage.local.set(pair, ()-> 
                    if callback then callback({})
                )
            else
                if callback then callback({})
        )
        return

    return model

root.app.factory('HototColumn', () ->
    HototColumn = BuildModel(
        'HOTOT_COLUMN_STORAGE', 
        [
            "serv", "slot_name", "type", "name", "display_name",
            "update_interval",
            "auto_refresh", "notification", "with_sound",
            "position_mode", "param1", "param2"
            "mute",
        ]
    )

    HototColumn.care = ['add_column', 'remove_column']

    HototColumn.crack = (role, cmd, content, respond) ->
        switch cmd
            when 'add_column'
                HototColumn.handleAdd(content.column, respond)
            when 'remove_column'
                HototColumn.handleRemove(content.serv, content.slot_name, content.name, respond)

    HototColumn.handleAdd = (column, respond) ->
        HototColumn.exists(column.serv, column.slot_name, column.name, (result) ->
            if result
                respond({result: 'error', reason: "Column #{column.serv}/#{column.slot_name}/#{column.name} already exists."})
            else
                HototColumn.save(column, () ->
                    respond({result: 'ok'})
                )
        )
        return

    HototColumn.handleRemove = (serv, slotName, name, respond) ->
        HototColumn.remove(serv, slotName, name, () -> 
            respond({result: 'ok'})
        )
        return

    HototColumn.addColumn = (column, callback) ->
        HototColumn.exists(column.serv, column.slot_name, column.name, (exist) ->
            if not exist
                HototColumn.save(column, ()-> callback(true))
            else
                callback(false)
        )
        return

    HototColumn.removeColumn = (serv, slotName, name, callback) ->
        HototColumn.remove(serv, slotName, name, callback)
        return

    HototColumn.getBySlot = (serv, slotName, callback) ->
        HototColumn.select((item) -> 
                item.serv == serv and item.slot_name == slotName
            ,
            callback
        )

    HototColumn.remove = (serv, slotName, name, callback) ->
        HototColumn.delete((item) ->
                item.serv == serv and item.slot_name == slotName and item.name == name
            ,
            callback
        )

    HototColumn.removeBySlot = (serv, slotName, callback) ->
        HototColumn.delete((item) ->
                item.serv == serv and item.slot_name == slotName
            ,
            callback
        )
        return

    HototColumn.exists = (serv, slotName, name, callback) ->
        HototColumn.single((item) -> 
                item.name == name and item.serv == serv and item.slot_name == slotName
            ,
            (item) ->
                if item
                    if callback then callback(true)
                else
                    if callback then callback(false)
        )

    HototColumn.updateColumn = (newColumn, callback) ->
        HototColumn.all((cols) ->
            pos = -1
            for col, i in cols
                if col.serv == newColumn.serv and col.slot_name == newColumn.slot_name and col.name == newColumn.name
                    pos = i
                    break
            if pos != -1
                cols.splice(pos, 1, newColumn)
                HototColumn.replace(cols, callback)
            else
                callback()
        )

    return HototColumn
)

root.app.factory('HototSlot', () ->
    HototSlot = BuildModel(
        'HOTOT_SLOT_STORAGE', 
        [
            "serv", "name", "display_name", "auth_type", "password",
            "access_token", "key", "secret", "columns", "settings"
        ]
    )

    HototSlot.get = (serv, slotName, callback) ->
        HototSlot.single((slot) -> 
                slot.serv == serv and slot.name == slotName
            ,
            callback
        )

    HototSlot.buildDefaults = (serv, name) ->
        # @TODO better builder
        slot = 
            serv: serv
            name: name
            display_name: name
            auth_type: ""
            password: ""
            access_token: ""
            key: ""
            secret: ""
            columns: []
            settings: {}
        return slot

    HototSlot.remove = (serv, slotName, callback) ->
        HototSlot.delete((item) ->
                item.serv == serv and item.name == slotName
            ,
            callback
        )

    HototSlot.exists = (serv, slotName, callback) ->
        HototSlot.single((item) -> 
                item.serv == serv and item.name == slotName
            ,
            (item) ->
                if item
                    if callback then callback(true)
                else
                    if callback then callback(false)
        )

    HototSlot.modify = (newSlot, callback) ->
        HototSlot.all((slots) ->
            pos = -1
            for slot, i in slots
                if slot.serv == newSlot.serv and slot.name == newSlot.name
                    pos = i
                    break
            if pos != -1
                slots.splice(pos, 1, newSlot)
                HototSlot.replace(slots, callback)
            else
                callback()
        )

    return HototSlot
)

root.app.factory('HototDraft', () ->
    HototDraft = BuildModel(
        'HOTOT_DRAFT_STORAGE', 
        [
            "uuid", "text", "context_type", "context_text", "context_id"
        ]

    )
    HototDraft.buildDefaults = () ->
        draft = 
            uuid: Hotot.generateUUID()
            text: ""
            context_type: ""
            context_id: ""
            context_text: ""
        return draft

    HototDraft.remove = (uuid, callback) ->
        HototDraft.delete((item) ->
                item.uuid == uuid
            ,
            () ->
                if callback then callback()
        )
    return HototDraft
)

root.app.factory('HototSettings', () ->
    HototSettings = BuildModel(
        'HOTOT_SETTINGS_STORAGE', 
        [
            "settings"
        ]
        
    )

    HototSettings.loads = (callback)->
        HototSettings.single((item) -> 
                true
            ,
            (settings) ->
                if callback then callback(settings)
        )
        return

    HototSettings.dumps = (settings, callback) ->
        HototSettings.replace([settings], (settings) ->
            if callback then callback()
        )
        return

    HototSettings.buildDefaults = () ->
        return {}

    return HototSettings
)

root.app.factory('HototForbiddens', () ->
    HototForbiddens = BuildModel(
        'HOTOT_FORBIDDENS_STORAGE', 
        [
            "forbiddens"
        ]
        
    )

    HototForbiddens.loads = (callback)->
        HototForbiddens.single((item) -> 
                true
            ,
            (forbiddens) ->
                if callback then callback(forbiddens)
        )
        return

    HototForbiddens.dumps = (forbiddens, callback) ->
        HototForbiddens.replace([forbiddens], () ->
            if callback then callback()
        )
        return

    return HototForbiddens
)

root.app.factory('HototRelationships', () ->
    HototRelationships = BuildModel(
        'HOTOT_RELATIONSHIPS_STORAGE', 
        [
            "relationships"
        ]
        
    )

    HototRelationships.loads = (callback)->
        HototRelationships.single((item) -> 
                true
            ,
            (relationships) ->
                if callback then callback(relationships)
        )
        return

    HototRelationships.dumps = (relationships, callback) ->
        HototRelationships.replace([relationships], () ->
            if callback then callback()
        )
        return

    return HototRelationships
)

root.app.factory('HototMute', () ->
    HototMute = BuildModel(
        'HOTOT_MUTE_STORAGE', 
        [
            "mute"
        ]
        
    )

    HototMute.loads = (callback)->
        HototMute.single((item) -> 
                true
            ,
            (mute) ->
                if callback then callback(mute)
        )
        return

    HototMute.dumps = (mute, callback) ->
        HototMute.replace([mute], () ->
            if callback then callback()
        )
        return

    return HototMute
)

root.app.factory('HototColumnState', () ->
    HototColumnState = BuildModel(
        'HOTOT_COLUMN_STATE_STORAGE', 
        [
            "mute"
        ]
        
    )

    HototColumnState.loads = (callback)->
        HototColumnState.single((item) -> 
                true
            ,
            (mute) ->
                if callback then callback(mute)
        )
        return

    HototColumnState.dumps = (mute, callback) ->
        HototColumnState.replace([mute], () ->
            if callback then callback()
        )
        return

    return HototColumnState
)