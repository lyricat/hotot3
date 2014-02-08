root = exports ? this

root.app.factory('AppService', ['$rootScope', ($rootScope) ->
    AppService = {}
    AppService.cmd = ''
    AppService.winWidth = 0
    AppService.winHeight = 0
    AppService.mainWidth = 0
    AppService.mainHeight = 0
    AppService.maxColNum = 1
    AppService.keywords = ''

    AppService.broadcast = (cmd, values) ->
        this.cmd = cmd
        for k, v of values
            if this.hasOwnProperty(k)
                this[k] = v
        switch cmd
            when 'resize'
                $rootScope.$broadcast('AppResize')
            when 'trigger_resize'
                $rootScope.$broadcast('AppTriggerResize')
            when 'search'
                $rootScope.$broadcast('AppSearch')
            when 'leave_search_mode'
                $rootScope.$broadcast('leaveSearchMode')

    return AppService
])
