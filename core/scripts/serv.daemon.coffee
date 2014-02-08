root = exports ? this

root.app.factory('HototDaemon', ['$rootScope', 'Logger', 
($rootScope, Logger) ->
    daemon = {}
    daemon.funcMap = {}
    daemon.streamListeners = {}
    daemon.slotVerifiers = {}
    daemon.watchers = {}
    daemon.working = true
    daemon.timerInterval = 60000 # default, 60 sec per loop
    daemon.tick = 0


    daemon.bind = (key, interval, callback) ->
        if daemon.funcMap.hasOwnProperty(key)
            delete daemon.funcMap[key]
        else # first time run
            callback()
        daemon.funcMap[key] = {interval:interval, callback:callback}
        return true

    daemon.unbind = (key) ->
        if daemon.funcMap.hasOwnProperty(key)
            delete daemon.funcMap[key]

    daemon.bindVerifier = (serv, slotName, callback) ->
        key = "#{serv}/#{slotName}"
        if daemon.slotVerifiers.hasOwnProperty(key)
            delete daemon.slotVerifiers[key]
        else # first time run
            callback()
        daemon.slotVerifiers[key] = callback
        return true

    daemon.unbindVerifier = (serv, slotName) ->
        key = "#{serv}/#{slotName}"
        if daemon.slotVerifiers.hasOwnProperty(key)
            daemon.slotVerifiers[key]

    daemon.verifySlots = (tick)->
        for key, verifier of daemon.slotVerifiers
            if verifier and tick % 600 == 0 # verify each slots per 10 minutes
                verifier()
        return

    daemon.poll = (key) ->
      if daemon.funcMap.hasOwnProperty(key)
          daemon.funcMap[key].callback()

    daemon.checkPoll = (tick) ->
        for key, func of daemon.funcMap
            if func and tick % (Math.ceil(func.interval / 60) * 60) == 0
                func.callback()
        return

    daemon.bindStream = (serv, slotName, colName, name, callback) ->
        key = "#{serv}/#{slotName}"
        streamKey = "#{serv}/#{slotName}/#{name}"
        if daemon.watchers.hasOwnProperty(key)
            daemon.watchers[key].bind(name, streamKey, callback)
        else
            daemon.streamListeners[key].push([streamKey, callback])

    daemon.unbindStream = (serv, slotName, colName, name) ->
        key = "#{serv}/#{slotName}"
        streamKey = "#{serv}/#{slotName}/#{name}"
        if daemon.watchers.hasOwnProperty(key)
            daemon.watchers[key].unbind(name, streamKey)

    daemon.registerStream = (serv, slotName, watcher) ->
        key = "#{serv}/#{slotName}"
        if daemon.watchers.hasOwnProperty(key)
            return false
        else
            daemon.watchers[key] = watcher
            daemon.streamListeners[key] = []
            return true

    daemon.checkStreams = ->
        for key, watcher of daemon.watchers
            if watcher.running
                # the watchers have responsibility about following:
                # - check the stream state, if it's broken, try to reconnect it.
                # - check the queue states, to make sure all JSON objects pass to invokers are vaild (@TODO)
                watcher.cleanup()
            else
                watcher.start()
                watcher.updateBinding(daemon.streamListeners[key])

    daemon.run = ->
        Logger.info("Daemon runs, tick=#{daemon.tick}")
        if daemon.working
            daemon.verifySlots(daemon.tick)
            daemon.checkPoll(daemon.tick)
            daemon.checkStreams()
            Hotot.saveBounds()
        daemon.tick += daemon.timerInterval/1000
        if daemon.tick == 3600 # reset timer per hour
            daemon.tick = 0
        setTimeout(
            () ->
                daemon.run()
            , daemon.timerInterval
        )

    return daemon

])
