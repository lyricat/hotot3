root = exports ? this
root.app.controller('NavigatorCtrl', ['$scope', 'SliderService', 'AppService', 'HototSlot', 'HototColumn', 'Logger',
($scope, SliderService, AppService, HototSlot, HototColumn, Logger) ->
    $scope.columnTable = SliderService.columnTable
    $scope.slotList = SliderService.slotList

    $scope.$on('AppResize', () ->
        resize(AppService.mainWidth, AppService.maxColNum)
        $scope.$apply()
    )

    $scope.$on('SliderUpdate', () ->
        $scope.$digest()
    )

    $scope.$on('SliderChangeSlot', () ->
        changeSlot(SliderService.currentSlot)
    )

    $scope.$on('SliderMoveToColumn', () ->
        slideTo(SliderService.currentColIdx)
    )

    $scope.navigate = (index, col) ->
        slideTo(index)
        return

    $scope.toTop = (col) ->
        SliderService.broadcast('move_to_top', col)
        return

    $scope.getVisibilityState = (slot) ->
        return if slot.visibility then '' else 'folding'

    changeSlot = (newSlot) ->
        for slotWrapper, idx in $scope.slotList
            slot = slotWrapper.slot
            if slot.name == newSlot.name and slot.serv == newSlot.serv
                SliderService.curSlotIdx = idx
                slotWrapper.visibility = true
            else
                slotWrapper.visibility = false
        Logger.info("Change Slot #{SliderService.curSlotIdx}")
        SliderService.sync()

    resize = (mainWidth, maxColNum) ->
        slotColNum = SliderService.getSlotColumnNum()
        if slotColNum < maxColNum
            maxColNum = slotColNum
        if maxColNum > 0
            # update active pages' style
            idx = $scope.columnTable[$scope.slotList[SliderService.curSlotIdx].key].currentIdx
            SliderService.updateActiveOffset(idx, maxColNum)           
            SliderService.updateActiveStatus(maxColNum)
            # use timeout to delay...
            setTimeout(() ->
                    $scope.$apply(() ->
                        SliderService.sync()
                    )
                , 100
            )


    slideTo = (idx, col) =>
        #* = 3 columns as example = 
        #* idx:         0   1   2   3   4   5
        #* fixed_idx:   0   1   2   3   3   3
        #* active_page_offset:   0   0   1   2   3   3
        #* active_pages:  012 012 123 234 345 335
        #*/
        maxColNum = AppService.maxColNum
        slotColNum = SliderService.getSlotColumnNum()
        if slotColNum < maxColNum
            maxColNum = slotColNum
        if idx == -1
            idx = 0
        if $scope.slotList.length != 0
            SliderService.curSlotIdx = if SliderService.curSlotIdx == -1 then 0 else SliderService.curSlotIdx
        $scope.columnTable[$scope.slotList[SliderService.curSlotIdx].key].currentIdx = idx
        SliderService.updateActiveOffset(idx, maxColNum)           
        # update active pages
        SliderService.updateActiveStatus(maxColNum)
        col = $scope.columnTable[$scope.slotList[SliderService.curSlotIdx].key].columns[idx]
        setTimeout(() ->
                SliderService.selectItem(SliderService.currentSlot.serv, SliderService.currentSlot.name, col.name)
            , 500
        )
        return

    $scope.getNavStyles = ->
        # if SliderService.currentSlot
        #     len = SliderService.currentSlot.columns.length * 32
        #     return {'width': len + 'px', 'margin-left': -1*Math.round(len/2) + 'px'}    
        return {}

    $scope.getNavMaskStyles = ->
        # slotObj = SliderService.currentSlotObject()
        # if slotObj and $scope.columnTable[slotObj.key]
        #     left = $scope.columnTable[slotObj.key].activeOffset * 32
        #     len = AppService.maxColNum * 32
        #     return {'width': len + 'px', '-webkit-transform': 'translateX('+left + 'px)'}    
        return {}

    $scope.getNavMaskIconCls = ->
        slotObj = SliderService.currentSlotObject()
        if slotObj
            obj = $scope.columnTable[slotObj.key]
            return obj.columns[obj.activeOffset].icon_name
        return ""


    return
]) 
