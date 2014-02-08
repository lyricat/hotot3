root = exports ? this
root.app.directive('accountSelector', () ->
    return {
        restrict: 'E',
        transclude: true,
        scope: {slots: '=', current: '=', selection: '=', useAddButton: '@', multiSelection: '@', onChanged: '=', onAdd: '='},
        controller: ($scope, $element) ->
            $scope.useAddButton = true
            $scope.multiSelection = false
            $scope.selection = null
            $scope.getCurrentAvatar = () ->
                if $scope.current and $scope.current.avatar
                    return $scope.current.avatar 
                return ''

            $scope.isAddButtonShow = ->
                return $scope.useAddButton

            $scope.selectSlot = (index) ->
                if not $scope.multiSelection
                    for i in [0...$scope.slots.length]
                        $scope.slots[i].selected = false
                    $scope.slots[index].selected = true
                    $scope.current = $scope.selection = $scope.slots[index]
                else
                    if $scope.slots[index].selected
                        if $scope.selection.length == 1 # don't allow to remove disselect
                            $scope.current = $scope.slots[0]
                        else
                            $scope.slots[index].selected = false
                            for c, i in $scope.selection
                                if c.name == $scope.slots[index].name and c.serv == $scope.slots[index].serv
                                    $scope.selection.splice(i, 1)
                                    break
                    else 
                        $scope.slots[index].selected = true
                        $scope.selection.push($scope.slots[index])
                if $scope.onChanged
                    $scope.onChanged($scope.selection, index)

            $scope.addSlot = ->
                if $scope.onAdd
                    $scope.onAdd()

            $scope.getSlotSelectedStyle = (slot) ->
                return if slot.selected then 'selected' else ''

            $scope.getAvatar = (slot) ->
                return slot.avatar

        ,
        link: (scope, element, attrs, ctrl) ->
            scope.$watch('current', ()->
                if scope.current and not scope.current.selected
                    scope.current.selected = true
            )
            return
        ,
        template:
            """
            <div class="account_selector">
                <img class="icon" ng-src="{{getCurrentAvatar()}}"/>
                <div class="popup_menu">
                    <i class="helper up"></i>
                    <div class="accounts">
                        <a class="slot" ng-repeat="slot in slots" ng-init="initSlot(slot)" title="{{slot.name}}@{{slot.serv}}" ng-click="selectSlot($index)" ng-class="getSlotSelectedStyle(slot)">
                            <img class="icon" ng-src="{{getAvatar(slot)}}" />
                            <span class="mask"></span>
                        </a>
                        <a class="add_slot" ng-click="addSlot($event)" ng-show="isAddButtonShow()">
                            <i class="mono-icon-plus"></i>
                        </a>
                    </div>
                    <div class="bottom" ng-transclude>
                    </div>
                    <i class="sharp up"></i>
                </div>
            </div>
            """
        ,
        replace: true
    }
)