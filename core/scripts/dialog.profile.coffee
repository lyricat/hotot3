app = angular.module('HototProfileDialog', [])
bindDriective(app, ['DND', 'MISC'])
app.controller('ProfileCtrl', ['$scope', ($scope) ->
    $scope.slots = []
    $scope.currentSlot = null
    $scope.newAvatar = {}
    majorAccount = null
    notSetBg = true
    master = {}
    $scope.uploadButton = 
        label: 'Upload'
        disabled: false
    $scope.saveButton = 
        label: 'Save Changes'

    hotot.bus.onMessage.addListener((request, sender, senderResponse) =>
        if not request.cmd
            return
        if request.cmd == 'reset_profile'
            content = request.content
            majorAccount = content.major_account
            $scope.$apply(() ->
                $scope.slots = content.accounts
                $scope.user = majorAccount.user
            )
            for slot, i in $scope.slots
                if slot.name == majorAccount.name and slot.serv = majorAccount.serv
                    $scope.$apply(() ->
                        $scope.currentSlot = slot
                        $scope.selectSlot(slot, i)
                    )
                    break
    )

    $scope.selectSlot = (slot, index) ->
        master = {}
        angular.extend(master, slot.profile)
        return

    $scope.updateProfile = () ->
        handleResponse = (resp) ->
            if resp.result == 'ok'
                window.close()
            else
                console.log "Error, reason: #{resp.reason}"
            $scope.saveButton.disabled = false
            $scope.saveButton.label = 'Save Changes'

        $scope.saveButton.disabled = true
        $scope.saveButton.label = 'Saving...'
        hotot.bus.sendMessage(
            {
                'role': 'profile_dialog', 
                'cmd': "update_profile", 
                'content': {account: $scope.currentSlot, profile: $scope.currentSlot.profile}
            }, (resp) ->
                $scope.$apply(()->
                    handleResponse(resp)
                )
        )
        return

    $scope.isUnchanged = (profile) ->
        return angular.equals(profile, master) and not $scope.saveButton.disabled

    loadFile = (file) ->
        # if not Hotot.imageTest(file.name)
        #     console.log "not a image file"
        #     return false
        $scope.newAvatar.filename = file.name
        $scope.newAvatar.type = file.type
        $scope.newAvatar.size = file.size
        reader = new FileReader()
        reader.onerror = (err) -> 
            console.log "failed to load file", err
        reader.onloadend = (e) ->
            $scope.$apply(() ->
                $scope.newAvatar.base64_data = e.target.result
                $scope.newAvatar.base64_data_bk = e.target.result
                uploadAvatar()
            )
        reader.readAsDataURL(file)
        return false

    uploadAvatar = () ->
        current = $scope.currentSlot
        handleResponse = (resp) ->
            if resp.result == 'ok'
                current.profile = resp.profile
                Hotot.fetchImage(current.profile.avatar_url, (data) ->
                    $scope.$apply(()->
                        current.avatar = window.webkitURL.createObjectURL(data)
                    )
                )
            else
                console.log "Error, reason: #{resp.reason}"
            $scope.uploadButton.disabled = false
            $scope.uploadButton.label = 'upload'

        $scope.uploadButton.disabled = true
        $scope.uploadButton.label = 'uploading...'
        hotot.bus.sendMessage(
            {
                'role': 'profile_dialog', 
                'cmd': "update_avatar", 
                'content': {account: current, avatar: $scope.newAvatar}
            }, (resp) ->
                $scope.$apply(()->
                    handleResponse(resp)
                )
        )
        return

    $scope.updateAvatar = (evt) ->
        hotot.fs.chooseEntry({type: 'openFile'}, (fileEntry) ->
            if fileEntry
                fileEntry.file((file) -> loadFile(file))
        )
        return

    $scope.fetchAvatar = () ->
        if $scope.currentSlot
            Hotot.fetchImage($scope.currentSlot.profile.avatar_url, (data) ->
                $scope.currentSlot.avatar = window.webkitURL.createObjectURL(data)
            )

])
this.app = app
