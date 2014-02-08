app = angular.module('HototColumnsDialog', [])
bindDriective(app, ['DND', 'MISC'])
app.controller('ColumnsCtrl', ['$scope', ($scope) ->
    $scope.column_map = {}
    $scope.selectedColumn = null
    $scope.column_types = {selected: null, types: []}
    $scope.slots = []
    $scope.currentSlot = null
    $scope.column_mute_text = ''
    $scope.global_mute_text = ''
    $scope.global_mute = []
    majorAccount = null
    currentSlotKey = ''
    dragStartIndex = 0
    $scope.add_column_box =
        show: false
        param_show: false
        params: []

    hotot.bus.onMessage.addListener((request, sender, senderResponse) =>
        if not request.cmd
            return
        if request.cmd == 'reset_columns_dialog'
            content = request.content
            console.log content
            majorAccount = content.major_account
            
            $scope.$apply(() ->
                $scope.column_map = content.column_map
                $scope.column_types.types = content.column_types
                $scope.slots = content.accounts
                $scope.global_mute = content.global_mute
                $scope.global_mute_text = $scope.global_mute.join(', ')
            )
            for slot, i in $scope.slots
                if slot.name == majorAccount.name and slot.serv = majorAccount.serv
                    $scope.$apply(() ->
                        $scope.selectSlot(slot, i)
                    )
                    break
    )

    $scope.$watch('global_mute', () ->
        $scope.global_mute_text = $scope.global_mute.join(', ')
    )

    $scope.selectSlot = (slot, index) ->
        console.log "select slot #{slot.serv}/#{slot.name}"
        $scope.currentSlot = $scope.slots[index]
        currentSlotKey = "#{$scope.currentSlot.serv}/#{$scope.currentSlot.name}"
        if $scope.currentSlot
            if $scope.column_map[currentSlotKey].length != 0
                $scope.selectColumn(0)
        return

    $scope.selectColumn = (index) ->
        if $scope.selectedColumn
            $scope.selectedColumn.selected = false
        console.log "select col #{$scope.column_map[currentSlotKey][index].name}"
        $scope.selectedColumn = $scope.column_map[currentSlotKey][index]
        $scope.selectedColumn.selected = true
        $scope.add_column_box.show = false
        $scope.column_mute_text = $scope.selectedColumn.mute.join(', ')
        return

    $scope.getCurrentColumns = () ->
        return $scope.column_map[currentSlotKey]

    $scope.getColumnStyles = (col) ->
        return if col.selected then 'selected' else ''

    $scope.changeColumnType = ->
        if $scope.column_types.selected != null
            $scope.add_column_box.param_show = true
            $scope.add_column_box.params = $scope.column_types.selected.params

    $scope.addDynamicColumn = ->
        $scope.add_column_box.show = true

    $scope.cancelCreating = ->
        $scope.add_column_box.show = false

    $scope.createColumn = ->
        handleResponse = (resp) ->
            if resp.result and resp.result == 'ok'
                $scope.$apply(()->
                    $scope.column_map[currentSlotKey].push(resp.content.column)
                    $scope.add_column_box.show = false
                )
            else
                console.log "Error, reason: #{resp.reason}"
            return
        if $scope.column_types.selected
            type = $scope.column_types.selected
            if type.singleton
                for col in $scope.column_map[currentSlotKey]
                    if col.type == type.type
                        # singleton
                        console.log "Error, reason: column #{type.type} has already exists"
                        $scope.add_column_box.show = false
                        return
            params = []
            for pa in $scope.add_column_box.params
                params.push(pa.value.trim())
            if type.params.length != 0 and params.length == 0 
                return
            hotot.bus.sendMessage(
                {
                    'role': 'columns_dialog', 
                    'cmd': "create_column", 
                    'content': {account: majorAccount, type: type.type, params: params}
                }, (resp) ->
                    handleResponse(resp)
            )
        return

    $scope.deleteColumn = ()->
        handleResponse = (resp) ->
            if resp.result == 'ok'
                pos = -1
                for col, i in $scope.column_map[currentSlotKey]
                    if col.name == resp.content.name
                        pos = i
                        break
                if pos != -1
                    $scope.$apply(()->
                        $scope.column_map[currentSlotKey].splice(pos, 1)
                    )
            else
                console.log "Error, reason: #{resp.reason}"
            return
        if $scope.selectedColumn != null
            hotot.bus.sendMessage(
                {
                    'role': 'columns_dialog', 
                    'cmd': "delete_column", 
                    'content': {account: majorAccount, name: $scope.selectedColumn.name}
                }, (resp) ->
                    handleResponse(resp)
            )
        return

    $scope.toggleNotifyColumn = () ->
        handleResponse = (resp) ->
            if resp.result == 'ok'
                $scope.$apply(() ->
                    $scope.selectedColumn.notification = resp.content.value
                )
            else
                console.log "Error, reason: #{resp.reason}"
        if $scope.selectedColumn == null
            return
        if $scope.selectedColumn.notification
            hotot.bus.sendMessage(
                {
                    'role': 'columns_dialog', 
                    'cmd': "column_notify_off", 
                    'content': {account: majorAccount, name: $scope.selectedColumn.name}
                }, (resp)->
                    handleResponse(resp)
            )
        else
            hotot.bus.sendMessage(
                {
                    'role': 'columns_dialog', 
                    'cmd': "column_notify_on", 
                    'content': {account: majorAccount, name: $scope.selectedColumn.name}
                }, (resp) ->
                    handleResponse(resp)
            )
        return

    $scope.dragNavStart = (evt) ->
        li = angular.element(evt.target)
        li.addClass('blink')
        name = li.attr('col-name')
        dragStartIndex = getIndexByAttrs(name)
        console.log 'start at ', dragStartIndex, name
        return
 
    $scope.dragNavEnter = (evt) ->
        btn = angular.element(evt.target)
        li = btn.parent()
        li.addClass('over')
        console.log 'drag enter'
        return
  
    $scope.dragNavOver = (evt) ->
        if evt.preventDefault
            evt.preventDefault()                # Necessary. Allows us to drop.
        evt.dataTransfer.dropEffect = 'move'    # See the section on the DataTransfer object.        
        return

    $scope.dragNavLeave = (evt) ->
        btn = angular.element(evt.target)
        li = btn.parent()
        li.removeClass('over')
        console.log 'drag leave'
        return

    $scope.dragNavEnd = (evt) ->
        li = angular.element(evt.target)
        li.removeClass('blink')
        console.log 'drag end'
        return

    $scope.dropNav = (evt) ->
        btn = angular.element(evt.target)
        li = btn.parent()
        li.removeClass('over')
        name = li.attr('col-name')
        index = getIndexByAttrs(name)
        console.log 'drop at ', index
        if dragStartIndex != -1 and index != -1
            moveColumn(dragStartIndex, index)  
            console.log dragStartIndex, index      
            hotot.bus.sendMessage(
                {
                    'role': 'columns_dialog', 
                    'cmd': "move_column", 
                    'content': {account: majorAccount, start: dragStartIndex, drop: index}
                }, (resp) ->
                    handleResponse(resp)
            )
            return
        if evt.stopPropagation
            evt.stopPropagation()   # stops the browser from redirecting.
        return

    formalize = (mute) ->
        mute = mute.map((x)-> x.trim())
        mute = mute.filter((x) -> x.length != 0)
        return mute

    $scope.saveColumnMute = (evt) ->
        mute = $scope.column_mute_text.split(',')
        mute = formalize(mute)
        if $scope.selectedColumn
            col = $scope.selectedColumn
            hotot.bus.sendMessage(
                {
                    'role': 'columns_dialog', 
                    'cmd': "save_column_mute", 
                    'content': {account: majorAccount, col_name: col.name, mute: mute}
                }, (resp) ->
                    console.log(resp)
                    col.mute = mute
            )
        return

    $scope.saveGlobalMute = (evt) ->
        mute = $scope.global_mute_text.split(',')
        mute = formalize(mute)
        hotot.bus.sendMessage(
            {
                'role': 'columns_dialog', 
                'cmd': "save_global_mute", 
                'content': { mute: mute }
            }, (resp) ->
                console.log(resp)
                $scope.global_mute = mute
        )
        return

    getIndexByAttrs = (name) ->
        for col, i in $scope.column_map[currentSlotKey]
            if col.name == name
                return i
        return -1

    moveColumn = (start, drop) ->
        cn = $scope.column_map[currentSlotKey].splice(start, 1)
        $scope.column_map[currentSlotKey].splice(drop, 0, cn[0])

    $scope.getNotifyState = (col) ->
        return if $scope.selectedColumn and $scope.selectedColumn.notification then "mono-icon-volume-on" else "mono-icon-volume-off"
    return
])
this.app = app
