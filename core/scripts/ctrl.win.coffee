root = exports ? this
root.app.controller('WindowCtrl', ['$scope', 'SettingsService', 'Logger', 
($scope, SettingsService, Logger) ->
    holding = false
    win = null
    offsetY = 0
    offsetX = 0
    $scope.hasFocus = true

    $scope.titleBarCls = ''

    root.onfocus = ->
        $scope.$apply(()->
            $scope.hasFocus = true
        )

    root.onblur = ->
        $scope.$apply(()->
            $scope.hasFocus = false
        )

    $scope.initWinCtrl = () ->
        setTimeout(()->
                x = SettingsService.getForbiddens('theme')
                win = hotot.window.current()
                switch SettingsService.getForbiddens('theme')
                    when 'auto'
                        $scope.titleBarCls = if Hotot.detectOS() == 'osx' then 'osx' else 'other'
                    when 'osx', 'other'
                        $scope.titleBarCls = SettingsService.getForbiddens('theme')
                    else
                        $scope.titleBarCls = if Hotot.detectOS() == 'osx' then 'osx' else 'other'
            , 1000
        )
        return

    $scope.getTitleBarCls = () ->
        return $scope.titleBarCls + " " + if not $scope.hasFocus then 'lose_focus' else ''

    $scope.minimizeWindow = ->
        win.minimize()
        return

    $scope.normalizeWindow = ->
        if not win.isMaximized()
            win.maximize()
        else
            win.restore()
        return

    $scope.closeWindow = ->
        win.close()
        return

    $scope.fullscreenWindow = ->
        win.fullscreen()

])
