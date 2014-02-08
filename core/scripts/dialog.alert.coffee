app = angular.module('HototAlertDialog', [])
app.controller('AlertCtrl', ['$scope', ($scope) ->
    buttons = []
    hotot.bus.onMessage.addListener((request, sender, senderResponse) ->
        if not request.cmd
            return
        if request.cmd == 'reset_alert'
            reset(request.content.logs)
    )

    reset = (logs) ->
        $scope.$apply(() ->
        )

    $scope.onButtonClick = (btn) ->
        return

    $scope.getButtons = ->
        return []

    return
])
