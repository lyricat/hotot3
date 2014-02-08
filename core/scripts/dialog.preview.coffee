app = angular.module('HototPreviewDialog', [])
bindDriective(app, ['MISC'])
app.controller('PreviewCtrl', ['$scope', ($scope) ->
    $scope.slider = 
        show: true
        offset: -25
    $scope.previewer = 
        data: ''
        title: ''
        scale: 0.92
        show: false
        placeholder_show: true
    $scope.media = []
    currentIndex = 0
    holding = false
    win = null
    offsetY = 0
    offsetX= 0
    win = hotot.window.current()
    pic = null

    hotot.bus.onMessage.addListener((request, sender, senderResponse) ->
        if request.recipient != win.id
            return
        if request.cmd == 'reset_preview'
            reset(request.content.opts, request.content.media)
            pic = document.querySelector('.previewer img')
    )

    loadFirstMedia = () ->
        if $scope.media.length != 0
            Hotot.fetchImage($scope.media[0].url, (data) ->
                $scope.$apply(() ->
                    $scope.previewer.data = window.webkitURL.createObjectURL(data)
                )
            )

    loadSlider = () ->
        loadThumb = (m) ->
            Hotot.fetchImage(m.thumb_url, (data) ->
                $scope.$apply(() ->
                    m.thumb_data = window.webkitURL.createObjectURL(data)
                )
            )
        loadPhoto = (m) ->
            Hotot.fetchImage(m.url, (data) ->
                $scope.$apply(() ->
                    m.data = window.webkitURL.createObjectURL(data)
                )
            )
        for m, i in $scope.media
            if not m.thumb_data
                loadThumb(m)
            if not m.data
                loadPhoto(m)
        if $scope.media.length < 2
            $scope.slider.show = false 

    setCurrent = (index) ->
        if index > $scope.media.length - 1
            index = $scope.media.length - 1
        if index < 0
            index = 0
        $scope.slider.offset = - (index * 50) - 25
        currentIndex = index
        $scope.previewer.show = false
        $scope.previewer.placeholder_show = true
        $scope.previewer.data = $scope.media[index].data

    $scope.onMousedown = (evt) ->
        win = hotot.window.current()
        bounds = win.getBounds()
        offsetX = evt.screenX - bounds.left 
        offsetY = evt.screenY - bounds.top
        holding = true
        return

    $scope.onMouseup = (evt) ->
        holding = false
        return

    $scope.onMousemove = (evt) ->
        if holding
            win.moveTo(evt.screenX - offsetX, evt.screenY - offsetY)
        return

    $scope.previewerShow = ->
        return if $scope.previewer.show then '' else 'hide'

    $scope.previewerLoaded = (evt) ->
        $scope.previewer.show = true
        $scope.previewer.placeholder_show = false
        sH = 1
        sW = 1
        if pic 
            if pic.naturalHeight > document.height
                sH = (0.0+document.height)/pic.naturalHeight
            if pic.naturalWidth > document.width
                sW = (0.0+document.width)/pic.naturalWidth
        $scope.previewer.scale = if sH < sW then sH else sW

    $scope.getSliderStyles = ->
        return {'margin-left': $scope.slider.offset + 'px'}

    $scope.enableSlider = ->
        return $scope.media.length > 1

    $scope.select = (index) ->
        setCurrent(index)
        return

    $scope.close = ->
        window.close()
        return

    $scope.download = ->
        hotot.fs.chooseEntry({type: 'saveFile', suggestedName: 'download', accepts:[{description: 'Image Types',mimeTypes: ["image/jpeg", "image/png", "image/gif"], extensions:['jpg', 'png', 'gif']}], acceptsAllTypes:true}, (fileEntry) ->
            fileEntry.createWriter((writer) ->
                    writer.onerror = (e) ->
                        console.log "write error", e
                    writer.onwriteend = (e) ->
                        console.log 'write complete'
                    Hotot.fetchImage($scope.media[currentIndex].data, (blob) ->
                        writer.write(blob)
                    )
                ,
                    (e) -> console.log "write error", e
            )
        )
        return

    $scope.share = ->
        hotot.bus.sendMessage(
             {'win': 'previewer', 'cmd': "share_media", 'content': {'media': $scope.media[currentIndex]}}
        )

    $scope.zoomIn = ->
        $scope.previewer.scale += 0.3
        return

    $scope.zoomOut = ->
        $scope.previewer.scale -= 0.3
        if $scope.previewer.scale < 0.1
            $scope.previewer.scale = 0.1
        return

    $scope.previewerStyles = ->
        if pic
            return {'height': ($scope.previewer.scale * pic.naturalHeight) + 'px', 'width': ($scope.previewer.scale * pic.naturalWidth) + 'px'}

    reset = (opts, media) ->
        $scope.$apply(() ->
            $scope.opts = opts
            $scope.media = media
            loadSlider()
            loadFirstMedia()
        )

    return
])
