root = exports ? this
root.app.controller('TabsFrameCtrl', ['$scope', ($scope) ->
    $scope.select = (idx) ->
        for v, i in $scope.tabSelected
            $scope.tabSelected[i] = ''
        $scope.tabSelected[idx] = 'selected'
    $scope.initTabs = (num) ->
        $scope.tabSelected = []
        for i in [0..num]
            $scope.tabSelected[i] = ''
        $scope.tabSelected[0] = 'selected'
])

