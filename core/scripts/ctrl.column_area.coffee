root = exports ? this
root.app.controller('ColumnAreaCtrl', ['$scope', 'SliderService', 'AppService', 'HototBus', 'HototSlot', 'HototColumn',
($scope, SliderService, AppService, HototBus, HototSlot, HototColumn) ->
    $scope.columnTable = SliderService.columnTable
    $scope.slotList = SliderService.slotList
    $scope.columnCommProps = {width:300, lastWidth:300, bodyHeight: '100%'}
    $scope.props = 
        areaHeight: 'auto'
        areaWidth: 'auto'
        columnAreaTransformX: ''

    maxColNum = 1
    currentSlotIdx = 0
    currentSlot = null

    resize = (mainWidth, mainHeight, maxColNum) ->
        slotColNum = SliderService.getSlotColumnNum()
        if slotColNum < maxColNum
            maxColNum = slotColNum
        if maxColNum > 0
            # adjust all views' width
            $scope.columnCommProps.width = parseInt(mainWidth/maxColNum)
            # adjust the last one
            $scope.columnCommProps.lastWidth = mainWidth - (maxColNum - 1) * $scope.columnCommProps.width
        $scope.columnCommProps.bodyHeight = mainHeight
        $scope.props.areaHeight = mainHeight
        $scope.props.areaWidth = mainWidth

    sync = ->
        colObj = SliderService.currentColumnTableObject()
        if colObj
            # do slide
            # $scope.props.cantainerMarginLeft = 0 - colObj.activeOffset * $scope.columnCommProps.width
            offset = 0 - colObj.activeOffset * $scope.columnCommProps.width
            $scope.props.columnAreaTransformX = 'translateX('+offset+'px)';


    SliderService.stateChanged(sync)

    $scope.$on('AppResize', () ->
        resize(AppService.mainWidth, AppService.mainHeight, AppService.maxColNum)
        $scope.$apply()
    )

    $scope.getColumnWidth = (isLastOne) ->
        val = if not isLastOne then $scope.columnCommProps.width else $scope.columnCommProps.lastWidth
        return {'width': val + 'px'}

    $scope.getAreaHeight = () ->
        return {'height': $scope.props.areaHeight + 'px', 'width': $scope.props.areaWidth + 'px'}

    $scope.getColumnBodyStyles = () ->
        sty = {'height': $scope.columnCommProps.bodyHeight + 'px'}
        if Hotot.detectOS() != 'osx'
            sty['overflow-y'] = 'auto'
        return sty

    $scope.getCantainerStyles = () ->
        return {'-webkit-transform': $scope.props.columnAreaTransformX}

    return
]) 
