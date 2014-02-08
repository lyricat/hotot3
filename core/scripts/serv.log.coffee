root = exports ? this

root.app.factory('Logger', ['$rootScope', ($rootScope) ->
    Logger = {}
    Logger.capacity = 1000
    Logger.logs = []

    Logger.add = (type, message) ->
        this.logs.push({type: type, message: "[#{type}] #{(new Date()).toLocaleTimeString()} #{message}"})
        hotot.bus.sendMessage(
             {'role': 'logger', 'cmd': "log", 'content': {type: type, message: message}}
        )
        Logger.trim()
        return

    Logger.info = (message) ->
        this.add('info', message)
        return

    Logger.warn = (message) ->
        this.add('warn', message)
        return

    Logger.error = (message) ->
        this.add('error', message)
        return

    Logger.trim = () ->
        if this.logs.length > this.capacity
            this.logs.splice(0, this.capacity/2)
        return
 
    return Logger
])
