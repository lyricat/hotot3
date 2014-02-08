this.app = angular.module('HototSettingsDialog', [])
this.app.controller('SettingsCtrl', ['$scope', ($scope) ->
    $scope.pages = 
        general:
            show: true
        account:
            show: false
        firewall:
            show: false
    $scope.settings = {}
    $scope.accounts = []

    reset = (content) ->
        console.log content
        $scope.settings = content.settings
        for obj, i in $scope.settings.language.list
            if $scope.settings.language.value == obj.value
                $scope.settings.language.value = $scope.settings.language.list[i]
                break
        for obj, i in $scope.settings.readlater_services.list
            if $scope.settings.readlater_services.value == obj.value
                $scope.settings.readlater_services.value = $scope.settings.readlater_services.list[i]
                break
        $scope.settings.line_height.value *= 10
        $scope.settings.line_height.min *= 10
        $scope.settings.line_height.max *= 10
        $scope.settings.line_height.step *= 10

        $scope.accounts = content.accounts
        if $scope.accounts.length != 0
            $scope.accounts[0].selected = true
        $scope.$apply()

    hotot.bus.onMessage.addListener((request, sender, senderResponse) ->
        if not request.cmd
            return
        if request.cmd == 'reset_settings'
            reset(request.content)
    )

    hotot.window.onClosed.addListener(()->
        hotot.bus.sendMessage({role: 'settings_dialog', cmd:'save_settings', content: {serv: _acc.serv, slot_name: _acc.name}})
    )

    $scope.selectPage = (idx) ->
        $scope.pages.general.show = false
        $scope.pages.account.show = false
        $scope.pages.firewall.show = false
        switch idx
            when 0
                $scope.pages.general.show = true
            when 1
                $scope.pages.account.show = true
            when 2
                $scope.pages.firewall.show = true
        return

    $scope.selectAccount = (acc) ->
        for _acc in $scope.accounts
            _acc.selected = false
        acc.selected = true
        return

    $scope.accountItemCls = (acc) ->
        return if acc.selected then 'selected' else ''

    $scope.accountDeleteButtonCls = ->
        return if $scope.accounts.length == 0 then 'disabled' else ''

    $scope.addAccount = ->
        hotot.bus.sendMessage({role: 'settings_dialog', cmd:'create_account', content: {}})
        return

    $scope.deleteAccount = ->
        if $scope.accounts.length == 0 then return
        for _acc in $scope.accounts
            if _acc.selected == true
                hotot.bus.sendMessage({role: 'settings_dialog', cmd:'delete_account', content: {serv: _acc.serv, slot_name: _acc.name}})
                if $scope.accounts.length == 1
                    window.close()
                break
        return

    changeSettings = (key) ->
        if $scope.settings.hasOwnProperty(key)
            if key == 'line_height'
                val = $scope.settings.line_height.value / 10.0
            else 
                val = $scope.settings[key].value
            hotot.bus.sendMessage({role: 'settings_dialog', cmd:'change_settings', content: {key: key, value: val}})

    $scope.changeLanguage = ->
        changeSettings('language')
        return

    $scope.changeFontsize = ->
        changeSettings('font_size')
        return

    $scope.changeLineheight = ->
        changeSettings('line_height')
        return

    $scope.changeMediaPreview = ->
        changeSettings('preview_media')
        return

    $scope.changeReadlaterService = ->
        changeSettings('readlater_services')
        return
])
