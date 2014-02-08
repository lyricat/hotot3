root = exports ? this

root.app.factory('NotifyService', ['$rootScope', 'Logger', ($rootScope, Logger) ->
    NotifyService = {}
    NotifyService.notifications = []
    NotifyService.notify = (title, summary, timeout=3000, type="native") ->
        if type == 'native'
            opts = {title: title, summary: summary, timeout: timeout}
            hotot.notifications.create("", opts)

    return NotifyService
])
