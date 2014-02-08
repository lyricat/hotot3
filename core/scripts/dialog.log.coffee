app = angular.module('HototLogDialog', [])
app.controller('LogCtrl', ['$scope', ($scope) ->
    $scope.log = []
    capacity = 1000
    hotot.bus.onMessage.addListener((request, sender, senderResponse) ->
        if not request.cmd
            return
        if request.cmd == 'log'
            append(request.content.type, request.content.message)
        if request.cmd == 'reset_log'
            reset(request.content.logs)
    )

    reset = (logs) ->
        $scope.$apply(() ->
            $scope.logs = logs
        )

    append = (type, message) ->
        $scope.$apply(() ->
            $scope.logs.push({
                type: type,
                message: "[#{type}] #{(new Date()).toLocaleTimeString()} #{message}"
            })
        )
        trim()

    trim = ->
        if $scope.log.length > capacity
            $scope.log.splice(0, capacity/2)
    return
])
