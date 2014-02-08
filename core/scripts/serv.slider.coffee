root = exports ? this

root.app.factory('SliderService', ['$rootScope', 'HototCache', 'HototColumn', 'HototSlot', 'ConnManager', 'AppService', 'HototDaemon'
($rootScope, HototCache, HototColumn, HototSlot, ConnManager, AppService, HototDaemon) ->
    SliderService = {}
    SliderService.cmd = ''
    SliderService.columnTable = {}
    SliderService.slotList = []
    SliderService.curSlotIdx = 0
    SliderService.currentSlot = null
    SliderService.stateChangeListeners = []
    SliderService.value = null

    SliderService.broadcast = (cmd, value) ->
        this.cmd = cmd
        console.info('Slider Service deliver a message', this.cmd)
        switch cmd
            when 'update'
                $rootScope.$broadcast('SliderUpdate')
            when 'change_slot'
                $rootScope.$broadcast('SliderChangeSlot')
            when 'move_to_top'
                this.currentCol = value
                $rootScope.$broadcast('SliderToTop')
            when 'scroll_column'
                this.currentCol = value.column
                this.itemId = value.item_id
                this.scrollDirection = value.direction
                $rootScope.$broadcast('SliderScrollColumn')
            when 'delete_column'
                this.deleteParams = value
                $rootScope.$broadcast('SliderDeleteColumn')
            when 'update_column_mute'
                this.updateColumnMuteParams = value
                $rootScope.$broadcast('SliderUpdateColumnMute')
            when 'no_more_slot'
                $rootScope.$broadcast('SliderNoMoreSlot')
            when 'move_to_column'
                this.currentColIdx = value
                $rootScope.$broadcast('SliderMoveToColumn')
            when 'delete_slot'
                this.deletedSlotParams = value
                $rootScope.$broadcast('SliderDeleteSlot')

    SliderService.init = () ->
        makeColumns = (slot) ->
            formalizer = ConnManager.getProto(slot.serv).formalizeColumn
            HototColumn.getBySlot(slot.serv, slot.name, (columns) -> 
                ret = ColumnUtils.makeColumnOrder(formalizer, slot.columns, columns)
                columns = ret[0]
                slot.columns = ret[1]
                HototSlot.modify(slot)
                key = "#{slot.serv}/#{slot.name}"
                SliderService.columnTable[key] = {
                    columns: columns
                    activeStatus: []
                    currentIdx: 0
                    activeOffset: 0
                }
                SliderService.columnTable[key].activeStatus = [ '' for i in [0...columns.length] ]
                if SliderService.columnTable[key].currentIdx > SliderService.columnTable[key].columns.length - 1
                    SliderService.columnTable[key].currentIdx = SliderService.columnTable[key].columns.length - 1
                else if SliderService.columnTable[key].currentIdx < 0
                    SliderService.columnTable[key].currentIdx = 0
                SliderService.columnTable[key].activeStatus[SliderService.columnTable[key].currentIdx] = 'active'
                return
            )

        loadSlots = (slots) ->
            for slot in slots
                slot.avatar = 'images/default_profile_image.jpg'
                # handle slots
                key = "#{slot.serv}/#{slot.name}"
                SliderService.slotList.push({
                        key: key,
                        slot: slot,
                        visibility: false
                        open: false
                        smOpen: false
                    }
                )
                # handle columns
                makeColumns(slot)
            if slots.length != 0
                SliderService.curSlotIdx = 0
                SliderService.slotList[SliderService.curSlotIdx].visibility = true
            if SliderService.slotList.length != 0
                SliderService.slotList[0].open = true
            if SliderService.slotList.length != 0
                SliderService.currentSlot = SliderService.slotList[0].slot
                SliderService.broadcast('change_slot')

        HototSlot.all(loadSlots)
        return

    SliderService.clear = () ->
        SliderService.slotList.length = 0

    SliderService.stateChanged = (callback) ->
        SliderService.stateChangeListeners.push(callback)

    SliderService.sync = () ->
        for lis in SliderService.stateChangeListeners
            lis()

    SliderService.getSlotColumnNum = ->
        if SliderService.slotList.length != 0
            if SliderService.curSlotIdx > SliderService.slotList.length - 1
                SliderService.curSlotIdx = SliderService.slotList.length - 1
            else if SliderService.curSlotIdx < 0
                SliderService.curSlotIdx = 0
            return SliderService.slotList[SliderService.curSlotIdx].slot.columns.length
        return 0

    SliderService.updateActiveOffset = (idx, maxColNum) ->
        total = SliderService.getSlotColumnNum()
        key = SliderService.slotList[SliderService.curSlotIdx].key
        colObj = SliderService.columnTable[key]
        fixedIdx = idx
        if idx + maxColNum >= total
            fixedIdx = total - maxColNum
        colObj.activeOffset = fixedIdx
        if fixedIdx == idx and 0 <= fixedIdx - parseInt(maxColNum/2)
            colObj.activeOffset = fixedIdx - parseInt(maxColNum/2)
        if colObj.activeOffset == -1
            colObj.activeOffset = 0
        this.sync()
        return 

    SliderService.updateActiveStatus = (maxColNum)->
        if not SliderService.curSlotIdx == -1 then return
        currentSlotObj = SliderService.slotList[SliderService.curSlotIdx]
        key = currentSlotObj.key
        colObj = SliderService.columnTable[key]
        for i in [0 ... colObj.columns.length]
            if colObj.activeOffset <= i and i < maxColNum + colObj.activeOffset
                colObj.activeStatus[i] = 'active'
                colObj.columns[i].notifyStatus = false
            else
                colObj.activeStatus[i] = ''
        return

    SliderService.currentSlotObject = () ->
        if not SliderService.curSlotIdx == -1
            return null
        else
            return SliderService.slotList[SliderService.curSlotIdx]

    SliderService.currentColumnTableObject = ->
        s = this.currentSlotObject()
        if s
            return SliderService.columnTable[s.key]
        return null

    # I don't use database changed listeners because the listeners are
    # too simple to recognize what fields of the data changes.
    # So, all operations about columns and slots are managed by this service
    # don't use the interfaces of service.storage directly.
    SliderService.addColumn = (serv, slotname, type, params, callback) ->
        _updateModel = (col) ->
            key = "#{serv}/#{slotname}"
            SliderService.columnTable[key].columns.push(col)
            for slotWrapper in SliderService.slotList
                slot = slotWrapper.slot
                if slot.serv == serv and slot.name == slotname
                    slot.columns.push(col.name)
                    break
            SliderService.broadcast('update')
            return
        proto = ConnManager.getProto(serv)
        column = proto.buildColumn(type, slotname, params)
        if column == null then return
        HototSlot.get(serv, slotname, (slot)->
            if slot
                HototColumn.addColumn(column, (result) ->
                    slot.columns.push(column.name)
                    HototSlot.modify(slot)
                    _updateModel(column)
                    if callback then callback(true, column)
                )
            else
                if callback then callback(false, "specified slot doesn't exist.")
        )
        return

    # Notice: call it only when you add a new slot
    SliderService.addDefaultColumns = (serv, slotname, callback) ->
        _updateModel = (cols) ->
            key = "#{serv}/#{slotname}"
            SliderService.columnTable[key].columns = cols
            for slotWrapper in SliderService.slotList
                slot = slotWrapper.slot
                if slot.serv == serv and slot.name == slotname
                    for col in cols
                        slot.columns.push(cols)
                    break
            return
        proto = ConnManager.getProto(serv)
        types = proto.getDefaultColumnTypes()
        HototSlot.get(serv, slotname, (slot)->
            if slot
                cols = []
                colNames = []
                for type in types
                    col = proto.buildColumn(type.type, slotname, type.params)
                    cols.push(col)
                    colNames.push(col.name)
                HototColumn.saveMany(cols, (result)-> 
                    slot.columns = colNames
                    HototSlot.modify(slot)
                    _updateModel(cols)
                    if callback then callback(true)
                )
            else
                if callback then callback(false, "specified slot doesn't exist.")
        )
        return

    SliderService.removeColumn = (serv, slotname, colname, callback) ->
        _updateModel = () ->
            key = "#{serv}/#{slotname}"
            for col, i in SliderService.columnTable[key].columns
                if col.name == colname and col.slot_name == slotname and col.serv == serv
                    SliderService.columnTable[key].columns.splice(i, 1)
                    break
            for slotWrapper in SliderService.slotList
                slot = slotWrapper.slot
                if slot.serv == serv and slot.name == slotname
                    pos = slot.columns.indexOf(colname)
                    if pos != -1
                        slot.columns.splice(pos, 1)
                        break
            SliderService.broadcast('update')
            return
        HototSlot.get(serv, slotname, (slot)->
            if slot
                SliderService.broadcast('delete_column', {serv: serv, slot_name: slotname, name: colname})
                HototColumn.removeColumn(serv, slotname, colname, (result) ->
                    pos = slot.columns.indexOf(colname)
                    if pos != -1
                        slot.columns.splice(pos, 1)
                    HototSlot.modify(slot)
                    _updateModel()
                    if callback then callback(true, colname)
                )
            else
                if callback then callback(false, "specified slot doesn't exist.")
        )
        return

    # this function should only be called in the callback of SliderService.removeSlot.
    SliderService.removeColumnBySlot = (serv, slotName, callback) ->
        _updateModel = () ->
            return
        SliderService.broadcast('delete_column', {serv: serv, slot_name: slotName, name: '*'})
        HototColumn.removeBySlot(serv, slotName, () ->
            _updateModel()
            if callback then callback(true)
        )
        return

    SliderService.updateColumn = (column, callback) ->
        _updateModel =  ->
            key = "#{column.serv}/#{column.slot_name}"
            for col, i in SliderService.columnTable[key].columns
                if col.name == column.name and col.slot_name == column.slot_name and col.serv == column.serv
                    SliderService.columnTable[key].columns.splice(i, 1, column)
                    break
            return
        HototColumn.exists(column.serv, column.slot_name, column.name, (ok)->
            if ok
                HototColumn.updateColumn(column, () ->
                    _updateModel(column)
                    if callback then callback(true)
                )
            else
                if callback then callback(false, "specified column doesn't exist.")
        )
        return

    SliderService.updateColumnMute = (serv, slotname, colname, mute, callback) ->
        _updateModel = (column) ->
            key = "#{serv}/#{slotname}"
            for col, i in SliderService.columnTable[key].columns
                if col.name == colname and col.slot_name == slotname and col.serv == serv
                    SliderService.columnTable[key].columns.splice(i, 1, column)
                    SliderService.broadcast('update_column_mute', {serv: serv, slot_name: slotname, name: colname, mute: mute})
                    break
            return
        HototColumn.exists(serv, slotname, colname, (ok)->
            if ok
                column = SliderService.getColumn(serv, slotname, colname)
                if column
                    column.mute = mute
                    HototColumn.updateColumn(column, () ->
                        _updateModel(column)
                        if callback then callback(true)
                    )
                else 
                    if callback then callback(false, "specified column doesn't exist.")
            else
                if callback then callback(false, "specified column doesn't exist.")
        )
        return

    SliderService.getColumn = (serv, slotname, colname) ->
        key = "#{serv}/#{slotname}"
        for col in SliderService.columnTable[key].columns
            if col.name == colname
                return col
        return null

    SliderService.moveColumn = (start, drop) ->
        slotObj = SliderService.currentSlotObject()
        _updateModel = ->
            columns = SliderService.columnTable[slotObj.key].columns
            cn = columns.splice(start, 1)
            columns.splice(drop, 0, cn[0])
            SliderService.broadcast('update')
        if slotObj
            slot = slotObj.slot
            if start == drop
                return
            if drop < 0 or drop >= slot.columns.length
                return
            # move [start + 1, drop] forward
            # or
            # move [drop, start - 1] toward
            tn = slot.columns.splice(start, 1)
            slot.columns.splice(drop, 0, tn[0])
            HototSlot.modify(slot, () ->
                _updateModel()
            )
            # console.log "move [#{start}, #{drop}], [#{start}, #{drop}]", slot
        return

    SliderService.setColumnNotifyStatus = (serv, slotname, colname) ->
        key = "#{serv}/#{slotname}"
        colObj = SliderService.columnTable[key]
        for col, i in colObj.columns
            if col.name == colname and colObj.activeStatus[i] != 'active'
                col.notifyStatus = true
                return
        return

    SliderService.clearColumnNotifyStatus = (serv, slotname, colname) ->
        key = "#{serv}/#{slotname}"
        for col, i in SliderService.columnTable[key].columns
            if col.name == colname
                col.notifyStatus = false
                return
        return

    SliderService.addSlot = (slot, callback) ->
        _updateModel = ->
            key = "#{slot.serv}/#{slot.name}"
            SliderService.columnTable[key] =
                columns: []
                activeStatus: []
                currentIdx: 0
                activeOffset: 0
            SliderService.slotList.push({
                key: key
                slot: slot
                visibility: false
                open: false
                smOpen: false
            })
            SliderService.curSlotIdx = SliderService.slotList.length
            SliderService.currentSlot = slot
            SliderService.broadcast('change_slot')
            SliderService.broadcast('update')
            return
        HototSlot.exists(slot.serv, slot.name, (result) ->
            if result
                if callback then callback(false, "specified column does exist.")
            else
                HototSlot.save(slot, () ->
                    # add defaults columns
                    SliderService.addDefaultColumns(slot.serv, slot.name)
                    _updateModel()
                    if callback then callback(true)
                )
        )
        return

    # this function doesn't remove columns owned by the deleted slot.
    # the invoker has the duty to remove them manually.
    SliderService.removeSlot = (serv, slotname, callback) ->
        _updateModel = ->
            key = "#{serv}/#{slotname}"
            SliderService.columnTable[key].columns.length = 0
            SliderService.columnTable[key].activeStatus.length = 0
            delete SliderService.columnTable[key]
            for slotWrapper, idx in SliderService.slotList
                slot = slotWrapper.slot
                if slot.serv == serv and slot.name == slotname
                    SliderService.slotList.splice(idx, 1)
                    if SliderService.curSlotIdx == idx
                        SliderService.curSlotIdx -= 1
                    break
            SliderService.broadcast('update')
            return
        HototSlot.exists(serv, slotname, (result) ->
            if result
                SliderService.broadcast('delete_slot', {serv: serv, name: slotname})
                HototSlot.remove(serv, slotname, () ->
                    _updateModel()
                    HototSlot.all((slots) ->
                        if slots.length == 0
                            SliderService.broadcast('no_more_slot')
                    )
                    if callback then callback(true)
                )
            else
                if callback then callback(false, "specified column doesn't exist.")
        )
        return

    SliderService.updateSlot = (slot, callback) ->
        _updateModel = ->
            for slotWrapper, idx in SliderService.slotList
                sl = slotWrapper.slot
                if sl.serv == slot.serv and sl.name == slot.name
                    SliderService.slotList[idx].slot = slot
                    break
            return
        HototSlot.exists(slot.serv, slot.name, (result) ->
            if result
                HototSlot.modify(slot, () ->
                    _updateModel()
                    if callback then callback(true)
                )
            else
                if callback then callback(false, "specified column doesn't exist.")
        )
        return

    SliderService.updateSlotAvatar = (serv, slotname, avatar_url) ->
        for slotWrapper, idx in SliderService.slotList
            sl = slotWrapper.slot
            if sl.serv == serv and sl.name == slotname
                Hotot.fetchImage(avatar_url, (data) ->
                    SliderService.slotList[idx].slot.avatar = window.webkitURL.createObjectURL(data)
                )
                break
        return

    SliderService.updateSlotProfile = (serv, slotname, profile) ->
        for slotWrapper, idx in SliderService.slotList
            sl = slotWrapper.slot
            if sl.serv == serv and sl.name == slotname
                SliderService.slotList[idx].slot.profile = profile
                break
        return

    SliderService.getSlot = (serv, slotname) ->
        for slotWrapper, idx in SliderService.slotList
            sl = slotWrapper.slot
            if sl.serv == serv and sl.name == slotname
                return SliderService.slotList[idx].slot
        return null

    SliderService.triggerSlideTo = (idx) ->
        SliderService.broadcast('move_to_column', idx - 1)

    SliderService.triggerSlidePrev = () ->
        idx = SliderService.columnTable[SliderService.slotList[SliderService.curSlotIdx].key].currentIdx
        if 0 <= idx - 1
            SliderService.broadcast('move_to_column', idx - 1)

    SliderService.triggerSlideNext = () ->
        idx = SliderService.columnTable[SliderService.slotList[SliderService.curSlotIdx].key].currentIdx
        SliderService.broadcast('move_to_column', idx + 1)

    SliderService.selectPrevItem = () ->
        key = SliderService.slotList[SliderService.curSlotIdx].key
        serv = SliderService.currentSlot.serv
        slotname = SliderService.currentSlot.name
        colIdx = SliderService.columnTable[key].currentIdx
        col = SliderService.columnTable[key].columns[colIdx]
        colKey = "#{serv}/#{slotname}/#{col.name}"
        if not col.selectedItem
            if HototCache.cache[colKey] and HototCache.cache[colKey].length > 0
                col.selectedItem = HototCache.cache[colKey][0]
            else
                return
        item = col.selectedItem
        ret = HototCache.findById([colKey], item.id)
        if ret[0] != null
            idx = ret[1] - 1
            if idx < 0
                nextItem = HototCache.cache[colKey][0]
            else 
                nextItem = HototCache.cache[colKey][idx]
            SliderService.selectItem(serv, slotname, col.name, nextItem)
            SliderService.broadcast('scroll_column', {column: col, item_id: nextItem.id, direction: 1})

    SliderService.selectNextItem = () ->
        key = SliderService.slotList[SliderService.curSlotIdx].key
        serv = SliderService.currentSlot.serv
        slotname = SliderService.currentSlot.name
        colIdx = SliderService.columnTable[key].currentIdx
        col = SliderService.columnTable[key].columns[colIdx]
        colKey = "#{serv}/#{slotname}/#{col.name}"
        if not col.selectedItem
            if HototCache.cache[colKey] and HototCache.cache[colKey].length > 0
                col.selectedItem = HototCache.cache[colKey][0]
            else 
                return
        item = col.selectedItem
        ret = HototCache.findById([colKey], item.id)
        if ret[0] != null
            idx = ret[1] + 1
            if idx >= HototCache.cache[colKey].length
                nextItem = HototCache.cache[colKey][HototCache.cache[colKey].length-1]
            else 
                nextItem = HototCache.cache[colKey][idx]
            SliderService.selectItem(serv, slotname, col.name, nextItem)
            SliderService.broadcast('scroll_column', {column: col, item_id: nextItem.id, direction: 2})

    SliderService.selectItem = (serv, slotname, colname, item) ->
        key = "#{serv}/#{slotname}"
        moveToTop = (i)->
            colKey = key+'/'+colname
            if HototCache.cache[colKey] and HototCache.cache[colKey].length > 0
                SliderService.columnTable[key].columns[i].selectedItem = HototCache.cache[colKey][0]
                SliderService.columnTable[key].columns[i].selectedItem.selected = true
        for col, i in SliderService.columnTable[key].columns
            if SliderService.columnTable[key].columns[i].selectedItem
                SliderService.columnTable[key].columns[i].selectedItem.selected = false
            if col.name == colname
                if item
                    if item.constructor == String
                        if item == 'TOP' then moveToTop(i)
                    else if item.constructor == Object
                        SliderService.columnTable[key].columns[i].selectedItem = item
                        SliderService.columnTable[key].columns[i].selectedItem.selected = true
                else 
                    if SliderService.columnTable[key].columns[i].selectedItem
                        SliderService.columnTable[key].columns[i].selectedItem.selected = true
                    else
                        moveToTop(i)
        return

    SliderService.getSelectedItem = ->
        key = SliderService.slotList[SliderService.curSlotIdx].key
        for col, i in SliderService.columnTable[key].columns
            if col.selectedItem and col.selectedItem.selected == true
                return col.selectedItem
        return null

    SliderService.selectFirstItem = ->
        key = SliderService.slotList[SliderService.curSlotIdx].key
        serv = SliderService.currentSlot.serv
        slotname = SliderService.currentSlot.name
        colIdx = SliderService.columnTable[key].currentIdx
        col = SliderService.columnTable[key].columns[colIdx]
        colKey = "#{serv}/#{slotname}/#{col.name}"
        if HototCache.cache[colKey].length != 0
            nextItem = HototCache.cache[colKey][0]
            SliderService.selectItem(serv, slotname, col.name, nextItem)
            SliderService.broadcast('scroll_column', {column: col, item_id: nextItem.id, direction: 1})
        return

    SliderService.selectLastItem = ->
        key = SliderService.slotList[SliderService.curSlotIdx].key
        serv = SliderService.currentSlot.serv
        slotname = SliderService.currentSlot.name
        colIdx = SliderService.columnTable[key].currentIdx
        col = SliderService.columnTable[key].columns[colIdx]
        colKey = "#{serv}/#{slotname}/#{col.name}"
        if HototCache.cache[colKey].length != 0
            nextItem = HototCache.cache[colKey][HototCache.cache[colKey].length - 1]
            SliderService.selectItem(serv, slotname, col.name, nextItem)
            SliderService.broadcast('scroll_column', {column: col, item_id: nextItem.id, direction: 2})
        return

    return SliderService
])
