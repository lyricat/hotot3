SHIFT = 16
CTRL = 17 
OPTION = 18
CMD = 91
MAC_CTRL = 17
UP = 38
DOWN = 40
class HotkeyUtils
    @SHIFT = SHIFT
    @CTRL = CTRL # dont use ctrl directly
    @OPTION = OPTION
    @CMD = CMD
    @MAC_CTRL = MAC_CTRL
    @UP = UP
    @DOWN = DOWN

    @listeners = {}

    @SPECIAL_KEYS = {
        SHIFT: null, CTRL: null, OPTION: null, CMD: null, MAC_CTRL: null,
        UP: null, DOWN: null
    }

    @ALPHASET = (keyCode) ->
        return 65 <= keyCode and keyCode <= 90

    @NUMBER = (keyCode) ->
        return 48 <= keyCode and keyCode <= 57

    @crack = (evt) ->
        keys = []
        if Hotot.detectOS() == 'osx'
            if evt.metaKey then keys.push(@CMD)
        else
            if evt.ctrlKey then keys.push(@CMD)
        if evt.shiftKey then keys.push(@SHIFT)
        if evt.altKey then keys.push(@OPTION)
        if evt.keyCode
            keyCode = evt.keyCode
            if @SPECIAL_KEYS.hasOwnProperty(evt.keyCode) or @ALPHASET(evt.keyCode) or @NUMBER(evt.keyCode)
                keys.push(evt.keyCode)
            else 
                return
        keys.sort()
        keys = keys.join(' ')
        if @listeners.hasOwnProperty(keys)
            for lis in @listeners[keys]
                evt.preventDefault()
                lis(evt)
        return

    @register = (keys, callback) ->
        _keys = []
        for key in keys
            if typeof key == "number"
                _keys.push(key)
            else if typeof key == 'string'
                _keys.push(key.charCodeAt(0))
        _keys.sort()
        _keys = _keys.join(' ')
        if @listeners.hasOwnProperty(_keys)
            @listeners[_keys].push(callback)
        else
            @listeners[_keys] = [callback]
        return

root = exports ? this
root.HotkeyUtils = HotkeyUtils
