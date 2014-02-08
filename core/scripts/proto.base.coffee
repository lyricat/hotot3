root = exports ? this

root.app.factory('Proto', ['$http', 'Logger', ($http, Logger) ->
    Proto = {}
    Proto.successHandler = (data, status, headers, config) ->
        pos = config.url.indexOf('?') 
        if pos != -1
            url = config.url.substring(0, pos)
        else
            url = config.url
        Logger.info("#{status} #{config.method} #{url}")

    Proto.defaultErrorHandler = (data, status, headers, config) ->
        pos = config.url.indexOf('?') 
        if pos != -1
            url = config.url.substring(0, pos)
        else
            url = config.url
        Logger.error("#{status} #{config.method} #{url}")
    return Proto
])