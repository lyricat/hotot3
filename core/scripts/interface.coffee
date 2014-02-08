platform = 0
PLATFORM_CHROME_OS = 0
PLATFORM_MAC = 1

# the follow functions use wrapper form instead of link form to prevent api changes

storageAddChangedListener = (callback) ->
    if platform == PLATFORM_CHROME_OS
        return chrome.storage.onChanged.addListener(callback)
    return null

storageLocalGet = (id, callback) ->
    if platform == PLATFORM_CHROME_OS
        return chrome.storage.local.get(id, callback)
    return null

storageLocalSet = (pair, callback) ->
    if platform == PLATFORM_CHROME_OS
        return chrome.storage.local.set(pair, callback)
    return null

# @TODO the createOptions and the window object should be wrapped up
windowCreate = (page, opts, callback) ->
    if platform == PLATFORM_CHROME_OS
        if not callback
            return chrome.app.window.create(page, opts)
        return chrome.app.window.create(page, opts, callback)
    return null

windowCurrent = ->
    if platform == PLATFORM_CHROME_OS
        return chrome.app.window.current()
    return null

windowAddClosedListener = (callback) ->
    if platform == PLATFORM_CHROME_OS
        return chrome.app.window.onClosed.addListener(callback)
    return null

busAddMessageListener = (callback) ->
    if platform == PLATFORM_CHROME_OS
        return chrome.runtime.onMessage.addListener(callback)
    return null

busSendMessage = (message, callback) ->
    if platform == PLATFORM_CHROME_OS
        if not callback
            return chrome.runtime.sendMessage(message)
        return chrome.runtime.sendMessage(message, callback)
    return null

notificationsCreate = (id, opts, callback) ->
    if platform == PLATFORM_CHROME_OS
        _opts = {
          type: "basic",
          title: opts.title,
          message: opts.summary,
          eventTime: opts.timeout,
          iconUrl: "../icons/128x128/apps/hotot.png"
        }
        if not callback
            return chrome.notifications.create(id, _opts, ()->)
        return chrome.notifications.create(id, _opts, callback)
    return null

runtimeReload = ->
    if platform == PLATFORM_CHROME_OS
        return chrome.runtime.reload()
    return null

fsChooseEntry = (opts, callback)->
    if platform == PLATFORM_CHROME_OS
        if not callback
            return chrome.fileSystem.chooseEntry(opts, ()->)
        return chrome.fileSystem.chooseEntry(opts, callback)
    return null
    
hotot =
    storage:
        onChanged: 
            addListener: storageAddChangedListener
        local:
            get: storageLocalGet
            set: storageLocalSet
    window:
        onClosed:
            addListener: windowAddClosedListener
        create: windowCreate
        current: windowCurrent
    bus: {
        onMessage:
            addListener: busAddMessageListener
        sendMessage: busSendMessage
    }
    fs: {
        chooseEntry: fsChooseEntry
    }
    notifications:
        create: notificationsCreate
    runtime:
        reload: runtimeReload

this.hotot = hotot
