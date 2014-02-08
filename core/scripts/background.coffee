
# application entry
start = ->
    chrome.storage.local.get("WINDOW_BOUNDS", (result) ->
        bounds = result['WINDOW_BOUNDS']
        if bounds and bounds.length != 0
            if bounds.width < 342
                bounds.width = 342
            if bounds.width > window.screen.availWidth
                bounds.width = window.screen.availWidth
            if bounds.height < 500
                bounds.height = 500
            if bounds.height > window.screen.availHeight
                bounds.height = window.screen.availHeight
            if bounds.top < window.screen.availTop
                bounds.top = window.screen.availTop
            if bounds.top > window.screen.availHeight - bounds.height
                bounds.top = window.screen.availHeight - bounds.height
            if bounds.left < window.screen.availLeft
                bounds.left = window.screen.availLeft
            if bounds.left > window.screen.availWidth - bounds.width
                bounds.left = window.screen.availWidth - bounds.width
        else
            bounds = {
                width: 342
                height: 500
                left: parseInt(window.screen.availWidth - 342)/2
                top: parseInt(window.screen.availHeight - 500)/2
            }
        chrome.app.window.create('index.html', {
            'width': bounds.width,
            'height': bounds.height,
            'minWidth': 300+42,
            'minHeight': 500,
            'hidden': true,
            'frame': 'chrome'
            }, (win) ->
                win.moveTo(bounds.left, bounds.top)
        )
    )

chrome.app.runtime.onLaunched.addListener(start)
