root = exports ? this
root.app = angular.module('Hotot', ['ngSanitize'], ['$httpProvider', ($httpProvider) ->
    # Use x-www-form-urlencoded Content-Type
    $httpProvider.defaults.headers.post['Content-Type'] = 'application/x-www-form-urlencoded;charset=utf-8'

    # Override $http service's default transformRequest
    $httpProvider.defaults.transformRequest = [ 
        (data) ->
            param = (obj) ->
                query = []
                for name, value of obj
                    if value != undefined and value != null 
                        query.push(Hotot.quote(name) + '=' + Hotot.quote(value))
                return query.join('&')
            if data and data.constructor == Object # don't use angular.isObject
                ret = param(data)
            else
                ret = data
            if ret == undefined
                ret = ''
            return ret
    ]
])
bindDriective(root.app, ['KEY', 'MISC', 'MOUSE', 'ANI', 'SCROLL', 'DND'])
root.app.run(['HototSlot', 'HototColumn', 'HototBus', 'ConnManager', 'ProtoTwitter', 'ProtoWeibo', 'MessageService', 'SettingsService', 'RelationService', 'SliderService',
(HototSlot, HototColumn, HototBus, ConnManager, ProtoTwitter, ProtoWeibo, MessageService, SettingsService, RelationService, SliderService) ->
    HototBus.init()
    HototSlot.init()
    HototColumn.init()
    ConnManager.addProto('twitter', ProtoTwitter)
    ConnManager.addProto('weibo', ProtoWeibo)
    ConnManager.init()
    MessageService.init()
    SettingsService.init()
    RelationService.init()
    SliderService.init()
])
