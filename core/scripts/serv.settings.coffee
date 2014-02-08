root = exports ? this

root.app.factory('SettingsService', ['$rootScope', 'Logger', 'HototSettings', 'HototForbiddens', 'HototMute', 
($rootScope, Logger, HototSettings, HototForbiddens, HototMute) ->
    SettingsService = {}
    SettingsService.settings = {}

    SettingsService.broadcast = (cmd, value) ->
        this.cmd = cmd
        console.info('Settings Service deliver a message', this.cmd)
        switch cmd
            when 'update_mute'
                this.updateMuteParams = value
                $rootScope.$broadcast('SettingsUpdateMute')
        return

    SettingsService.reset = ->
        SettingsService.settings = {
            language: { label: 'Language', type: 'combo_list', value: 'auto', value_type: 'String', list: [
                    {value: 'auto', text: 'Auto'}, 
                    {value: 'en', text: 'English'}, 
                    {value: 'zh_CN', text: '简体中文'},
                ]
            },
            font_size: {label: 'Font Size', type: 'range', value: 9, value_type: 'Number', max: 16, min: 6, step: 0.5},
            line_height: {label: 'Line Height', type: 'range', value: 1.4, value_type: 'Number',  max: 2.0, min: 1.0, step: 0.1},
            accounts: [],
            preview_media: {label: 'Preview Embedded Media', type: 'checkbox', value: true, value_type: 'Boolean'},
            readlater_services: { label: 'Read Later Services', type: 'combo_list', value: 'none', value_type: 'String', list: [
                    {value: 'pocket', text: 'Pocket'}, 
                    {value: 'instapaper', text: 'Instapaper'},
                    {value: 'none', text: 'None'}, 
                ]
            },
        }
        SettingsService.forbiddens = {
            theme: {value:'auto', default:'auto'}
        }
        SettingsService.mute = []

    SettingsService.setForbiddens = (key, value) ->
        if this.forbiddens.hasOwnProperty(key)
            if value == null
                this.forbiddens[key].value = this.forbiddens[key].default
            else
                this.forbiddens[key].value = value
            HototForbiddens.dumps(SettingsService.forbiddens)
        return value

    SettingsService.getForbiddens = (key) ->
        if this.forbiddens.hasOwnProperty(key)
            return this.forbiddens[key].value
        return null

    SettingsService.setMute = (mute) ->
        HototMute.dumps(mute, () ->
            SettingsService.mute = mute
            SettingsService.broadcast('update_mute', {mute: SettingsService.mute})
        )

    SettingsService.getMute = () ->
        return SettingsService.mute

    SettingsService.init = ->
        SettingsService.reset()
        SettingsService.loads()
        Logger.info("init Settings Service")
        hotot.bus.onMessage.addListener((message, sender, respond) ->
            # console.log('control', ev)
            cmd = message.cmd
            content = message.content
            switch cmd
                when 'change_settings'
                    if SettingsService.settings.hasOwnProperty(content.key)
                        switch SettingsService.settings[content.key].value_type
                            when 'Number'
                                val = Number(content.value)
                            when 'Boolean'
                                val = Boolean(content.value)
                            else
                                val = content.value
                        SettingsService.settings[content.key].value = val
                when 'load_settings'
                    SettingsService.loads()
                when 'save_settings'
                    SettingsService.dumps()
            return true
        )
        SettingsService.autoDumps()

    SettingsService.loads = ->
        HototForbiddens.loads((_forbiddens) ->
            if _forbiddens
                for key, value of _forbiddens
                    if SettingsService.forbiddens.hasOwnProperty(key)
                        SettingsService.forbiddens[key] = value
        )
        HototSettings.loads((_settings) ->
            if _settings
                for field, fv of _settings
                    if SettingsService.settings.hasOwnProperty(field)
                        tmpl = SettingsService.settings[field]
                        if fv.value and fv.value.constructor.name == tmpl.value_type
                            SettingsService.settings[field].value = fv.value
        )
        HototMute.loads((_mute) ->
            if _mute
                SettingsService.mute = _mute
        )
        return

    SettingsService.autoDumps = ->
        setInterval(SettingsService.dumps, 60000)

    SettingsService.dumps = ->
        HototSettings.dumps(SettingsService.settings)
        HototForbiddens.dumps(SettingsService.forbiddens)
        HototMute.dumps(SettingsService.mute)
        return

    return SettingsService
])
