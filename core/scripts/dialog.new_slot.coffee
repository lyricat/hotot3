DialogCtrl = ($scope) ->
    return

AuthPageCtrl = ($scope, $routeParams) ->
    $scope.service = $routeParams.service
    $scope.error_box = 
        show: false
        text: ''
    $scope.signin_button = 
        label: ''
        cls: ''
    working = false
    resetAuthButton = () =>
        $scope.signin_button.label = 'Sign In'
        $scope.signin_button.cls = ''
        working = false
    resetAuthButton()
    $scope.auth = (username, password) =>
        if working
            hotot.bus.sendMessage({role: 'new_slot_dialog', cmd: 'cancel_auth', content: {}})
            return
        working = true
        $scope.error_box.show = false
        $scope.signin_button.label = 'Processing'
        $scope.signin_button.cls = 'processing'
        hotot.bus.sendMessage(
            {role: 'new_slot_dialog', cmd: "auth", content: { serv: $scope.service, username: username, password: password }},
            (response) ->
                if response.result == 'error'
                    $scope.error_box.text = response.reason
                    $scope.error_box.show = true
                    resetAuthButton()
                    $scope.$apply()
                else
                    resetAuthButton()
                    $scope.$apply()
                    if response.result == 'ok'
                        window.close()
        )
    $scope.hoverSignInButton = ->
        if working
            $scope.signin_button.label = 'Cancel'
            
    $scope.noHoverSignInButton = ->
        if working
            $scope.signin_button.label = 'Processing'
    return

OAuthPageCtrl = ($scope, $routeParams) ->
    $scope.service = $routeParams.service
    $scope.authorizeURL = ''
    $scope.username = ''
    $scope.password = ''
    $scope.service = $routeParams.service
    $scope.error_box = 
        show: false
        text: ''
    $scope.signin_button = 
        label: ''
        cls: ''
    working = false
    webview = null
    step = 1

    resetAuthButton = () =>
        $scope.signin_button.label = 'Sign In'
        $scope.signin_button.cls = ''
        working = false

    startAutoFill = (username, password) ->
        if webview
            webview.executeScript({code:'document.getElementById("userId").value="'+username+'"'})
            webview.executeScript({code:'document.getElementById("passwd").value="'+password+'"'})
            setTimeout(() ->
                    webview.executeScript({code: 'document.forms[0].submit()'})
                    step = 2
                , 500
            )

    getPINCode = ->
        if webview
            console.log(webview.location.search)
            step = 1

    $scope.initPage = () ->
        resetAuthButton()

    $scope.webviewLoadcommit = (evt) ->
        console.log('webview commit!')
        webview = document.getElementById('webview')
        if step == 2
            # console.log evt
            code = evt.url.substring(evt.url.indexOf('?code=')+6)
            resetAuthButton()
            hotot.bus.sendMessage(
                {role: 'new_slot_dialog', cmd: "oauth_with_pin", content: { serv: $scope.service, username: $scope.username, password: $scope.password, pin: code}},
                (response) ->
                    if response.result == 'error'
                        $scope.error_box.text = response.reason
                        $scope.error_box.show = true
                    else
                        if response.result == 'ok'
                            window.close()
                    $scope.$apply()
            )
        return

    $scope.webviewLoadstop = (evt) ->
        console.log('webview loaded!')
        webview = document.getElementById('webview')
        if step == 1
            setTimeout(() ->
                    startAutoFill($scope.username, $scope.password)
                , 500
            )
        return

    $scope.auth = (username, password)->
        working = true
        $scope.error_box.show = false
        $scope.signin_button.label = 'Processing'
        $scope.signin_button.cls = 'processing'
        hotot.bus.sendMessage(
            {role: 'new_slot_dialog', cmd: "oauth_get_authorize_url", content: { serv: $scope.service, username: $scope.username}},
            (response) ->
                if response.result == 'error'
                    $scope.error_box.text = response.reason
                    $scope.error_box.show = true
                else
                    $scope.authorizeURL = response.content.url
                $scope.$apply()
        )

    $scope.getAuthorizeURL = ->
        return $scope.authorizeURL

this.app = angular.module('HototNewSlotDialog', []).
config(['$routeProvider', ($routeProvider) ->
    $routeProvider.
        when('/page/:service/auth', { templateUrl: '../partials/new_slot_auth_page.html',   controller: ['$scope', '$routeParams', AuthPageCtrl]}).
        when('/page/:service/oauth', { templateUrl: '../partials/new_slot_oauth_page.html', controller: ['$scope', '$routeParams', OAuthPageCtrl]}).
        when('/page/:service/building', { templateUrl: '../partials/new_slot_building_page.html', controller: ['$scope', '$routeParams', AuthPageCtrl]}).
        otherwise({redirectTo: '/page/twitter/auth'});
]).controller('DialogCtrl', DialogCtrl)
bindDriective(this.app, ['MISC'])

