
class AbsColumn

    @loadFeaturePic = (item) ->
        Hotot.fetchImage(item.feature_pic_url, (data) ->
            $scope.$apply(() ->
                item.feature_pic_data = window.webkitURL.createObjectURL(data)
            )
        )
        return

root = exports ? this
this.AbsColumn = AbsColumn
