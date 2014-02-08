this.app = angular.module('HototMessageDialog', ['ngSanitize'])
bindDriective(this.app, ['KEY'])
this.app.controller('MessageCtrl', ['$scope', ($scope) ->
    $scope.conversations = []
    $scope.currentConversation = null
    $scope.majorAccount = null
    $scope.currentSlot = null
    $scope.slots = []
    textBox = null
    chatBox = null
    currentSlotKey = ''
    currentRecipient = null
    $scope.add_con_box =
        show: false
        recipient: ''
        text: ''
        
    hotot.bus.onMessage.addListener((request, sender, senderResponse) ->
        if not request.cmd
            return
        if request.cmd == 'reset_message'
            console.log request
            $scope.majorAccount = request.content.major_account
            $scope.slots = request.content.accounts
            constructConversations(request.content.conversations)
            for slot, i in $scope.slots
                if slot.name == $scope.majorAccount.name and slot.serv = $scope.majorAccount.serv
                    $scope.$apply(() ->
                        $scope.selectSlot(slot, i)
                    )
                    break
            document.querySelector('.text_box').focus()
            textBox = angular.element(document.querySelector('.text_box'))
            chatBox = document.querySelector('.messages')
            setTimeout(() ->
                    chatBox.scrollTop = chatBox.scrollHeight
                , 500
            )
            if request.content.context and request.content.context.name
                $scope.$apply(() ->
                    $scope.add_con_box.recipient = request.content.context.name
                    $scope.add_con_box.text = ''
                    $scope.add_con_box.show = true
                )
        else if request.cmd == "new_messages"
            serv = request.content.serv
            slotName = request.content.slot_name
            messages = request.content.messages
            target = null
            if $scope.majorAccount.name == slotName and $scope.majorAccount.serv == serv
                for message in messages
                    # @FIXME here:
                    # only deal with message others send to me and message i send.
                    ret = $scope.selectConversationByName(message.sender.name, message.recipient.name)
                    con = ret[0]
                    pos = ret[1]
                    if con == null
                        user = if message.recipient.name == $scope.majorAccount.name then message.sender else message.recipient
                        target = 
                            last_update: msg.timestamp
                            user: user
                            messages: [message]
                        $scope.$apply(() ->
                            $scope.conversations[currentSlotKey].unshift(target)
                        )
                    else
                        target = con
                        target.last_update = message.timestamp
                        target.messages.push(message)
                        $scope.$apply(() ->
                            $scope.conversations[currentSlotKey].splice(pos, 1)
                            $scope.conversations[currentSlotKey].unshift(target)
                        )
            setTimeout(() ->
                    chatBox.scrollTop = chatBox.scrollHeight
                , 500
            )
    ) 
                        

    $scope.selectConversationByName = (senderName, recipientName) ->
            pos = -1
            for con, i in $scope.conversations[currentSlotKey]
                if con.user.name == senderName or con.user.name == recipientName
                    pos = i
                    break
            if pos == -1
                return [null, -1]
            else
                return [con, pos]

    $scope.selectSlot = (slot, index) ->
        console.log "select slot #{slot.serv}/#{slot.name}"
        $scope.currentSlot = $scope.slots[index]
        currentSlotKey = "#{$scope.currentSlot.serv}/#{$scope.currentSlot.name}"
        if $scope.currentSlot
            if $scope.conversations[currentSlotKey].length != 0
                $scope.selectConversation($scope.conversations[currentSlotKey][0])
        return


    constructConversations = (_cons) ->
        cons = []
        for slotKey, _slotCons of _cons
            slotCons = []
            for key, con of _slotCons
                con.messages.reverse()
                slotCons.push(con)
            slotCons.sort((a, b) -> 
                return b.last_update - a.last_update
            )
            cons[slotKey] = slotCons
        $scope.$apply(() ->
            $scope.conversations = cons
        )

    $scope.selectConversation = (con) ->
        $scope.currentConversation = con
        currentRecipient = con.user
        setTimeout(() ->
                chatBox.scrollTop = chatBox.scrollHeight
            , 200
        )

    $scope.getCurrentConversations = () ->
        return $scope.conversations[currentSlotKey]

    $scope.getMessageDirection = (msg) ->
        if msg.sender.name == $scope.majorAccount.name
            return 'right'
        return ''

    $scope.handleKeyUp = (evt) ->
        return

    $scope.handleKeyDown = (evt) ->
        # shortcut binding Enter
        if evt.keyCode == 13
            $scope.post()
            return false

    $scope.post = () ->
        text = textBox.val()
        if text.trim().length != 0
            hotot.bus.sendMessage(
                {win: 'message_dialog', cmd: "drop", content: {account: $scope.majorAccount, recipient: currentRecipient, text: text}}
            )
            textBox.val('')
        return false

    $scope.loadAvatar = (user) ->
        Hotot.fetchImage(user.avatar_url, (data) ->
            $scope.$apply(() ->
                user.avatar_data = window.webkitURL.createObjectURL(data)
            )
        )

    $scope.addConversation = ->
        $scope.add_con_box.show = true

    $scope.discard = ->
        $scope.add_con_box.show = false

    $scope.sendMessage = () ->
        text = $scope.add_con_box.text
        recipient = $scope.add_con_box.recipient
        if text.trim().length != 0 and recipient.trim().length
            hotot.bus.sendMessage(
                {
                    win: 'message_dialog', cmd: "drop", content: {account: $scope.majorAccount, recipient: {name: recipient}, text: text}
                }, (resp) ->
                    $scope.add_con_box.recipient = ''
                    $scope.add_con_box.text = ''
                    currentSlotKey = "#{$scope.currentSlot.serv}/#{$scope.currentSlot.name}"
                    if $scope.currentSlot and $scope.conversations[currentSlotKey].length != 0
                            $scope.selectConversation($scope.conversations[currentSlotKey])
            )
        $scope.add_con_box.show = false


    return
])
