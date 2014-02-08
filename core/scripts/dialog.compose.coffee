this.app = angular.module('HototComposeDialog', [])
this.app.controller('ComposeCtrl', ['$scope', ($scope) ->
    BASE_HEIGHT = 164
    CONTEXT_HEIGHT = 30
    EFFECT_HEIGHT = 50 + 6 
    CANDIDATE_HEIGHT = 32 + 6 
    timer = null
    inDetecting = false
    $scope.context_bar =
        height: 32
        show: false
        avatar_data: ''
        text: ''
    $scope.effects_bar =
        height: 32
        show: false
        offset: 0
        spinner_show: false
        spinner_label: 'loading'
    $scope.candidate_bar = 
        list: []
        show: false
    $scope.draft_list =
        show: false
        drafts: []
    $scope.account_list =
        show: false
    effectScroller = null
    candidateScroller = null

    $scope.effects = [
        {name: 'normal', icon_name: 'normal', display_name: 'Normal'}
        {name: 'vintage', icon_name: 'vintage', display_name: 'Vintage'}
        {name: 'lomo', icon_name: 'lomo', display_name: 'LOMO'}
        {name: 'warmAutumn', icon_name: 'autumn', display_name: 'Autumn'}
        {name: 'softenFace', icon_name: 'beauty', display_name: 'Beauty'}
        {name: 'sketch', icon_name: 'sketch', display_name: 'Sketch'}
        {name: 'softEnhancement', icon_name: 'enhance', display_name: 'Enhance'}
        {name: 'purpleStyle', icon_name: 'purple', display_name: 'Purple'}
        {name: 'soften', icon_name: 'soften', display_name: 'Soften'}
        {name: 'gray', icon_name: 'bw', display_name: 'B&W'}
        {name: 'strongEnhancement', icon_name: 'lighten', display_name: 'Lighten'}
    ]
    $scope.context = {}
    $scope.majorAccount = {}
    $scope.accounts = []
    $scope.currentSlot = null
    $scope.currentSelection = []
    $scope.props = {}
    $scope.props.remainCharNum = 140
    $scope.props.has_attachment = false
    $scope.props.attachment = {}

    $scope.selectedAccounts = {}
    textbox = document.querySelector('.text')
    win = hotot.window.current()

    regLinkProto = '([a-zA-Z]+:\\/\\/|www\\.)'
    regLinkPart1 = '[a-zA-Z0-9!\\*\';:=\\+\\$/%#\\[\\]\\?\\-_,~\\(\\)&\\.`@]'
    regLinkPart2 = '[a-zA-Z0-9!\':=\\+\\$/%#~\\(\\)&`@]'
    regLink = new RegExp("(#{regLinkProto}#{regLinkPart1}*#{regLinkPart2}+)", 'g')

    reset = () ->
        # @TODO context.type should only be handle in proto
        switch $scope.context.type 
            when 'reply'
                document.title = "Reply"
                $scope.context_bar.text = $scope.context.text
                $scope.context_bar.avatar_data = $scope.context.author_avatar_data
                mentions = $scope.context.mentions.filter((x) -> 
                    x.screen_name.toLowerCase() != $scope.context.author_name.toLowerCase() and x.screen_name.toLowerCase() != $scope.majorAccount.name.toLowerCase() 
                ).map((x) -> 
                    '@' + x.screen_name
                )
                mentions = if mentions.length == 0 then '' else mentions.join(' ') + ' '
                textbox.value = "@#{$scope.context.author_name} #{mentions}"
                expandUI('context')
                moveCursor(-1)
            when 'quote'
                document.title = "Quote"
                textbox.value = " QT @#{$scope.context.author_name}: #{$scope.context.text}"
                moveCursor(0)
        if $scope.context.response
            textbox.value = $scope.context.response
            moveCursor(-1)
        $scope.account_list.show = false
        $scope.accountsBarWidth = $scope.accounts.length * 30 + 2
        $scope.accountsBarMarginLeft = 0 - ($scope.accountsBarWidth + 10) / 2
        for acc, i in $scope.accounts
            key = "#{acc.serv}/#{acc.name}"
        # media
        document.querySelector('.text').focus()

    moveCursor = (pos) ->
        if not pos
            pos = 0
        if pos == -1
            pos = textbox.value.length
        box = document.querySelector('.text')
        box.focus()
        if box.setSelectionRange
            box.setSelectionRange(pos, pos)

    reloadDrafts = (response) ->
        if response.result == 'ok'
            $scope.draft_list.drafts = response.content.drafts

    getMessageLen = () ->
        text = textbox.value
        repUrl = (url) ->
            if url.length > 20
                return '01234567890123456789'
            else
                return url
        return text.replace(regLink, repUrl).length

    autocomp = (evt) ->
        keyCode = evt.keyCode
        clearInterval(timer)
        if inDetecting
            if keyCode == 13
                # Do username autocompletion because user pressed enter.
                if $scope.candidate_bar.list.length != 0
                    user = $scope.candidate_bar.list[0]
                    insertCandidate(user)
                    evt.preventDefault()
                stopDetecting()
                return false
            if keyCode == 27 # esc
                stopDetecting()
        if (keyCode <= 90 and 65 <= keyCode) or (48 <= keyCode and keyCode <= 57) or 95 == keyCode or keyCode == 8 or keyCode == 32 or keyCode == 229 # 229 for imeKey
            detect(evt)
        return

    detect = (evt) ->
        # start 
        inDetecting = true
        handleResult = (items) ->
            if items.length == 0
                foldUI('candidate')
                return
            $scope.candidate_bar.list.length = 0
            $scope.candidate_bar.list = items
            expandUI('candidate')
            setTimeout(() ->
                    candidateScroller.refresh()
                , 100
            )

        getInputText = (callback) ->
            # get the text after '@'
            setTimeout(() ->
                    text = textbox.value
                    # scan for '@' character
                    curPos = getCursorPos()
                    if evt.keyCode == 8 # backspace or delete
                        curPos += 1
                    headText = text.substring(0, curPos)
                    if evt.keyCode == 32 and headText[headText.length - 1] == ' '
                        $scope.$apply(() -> 
                            stopDetecting()
                        )
                        return
                    atIdx = headText.lastIndexOf('@')
                    if atIdx == -1 or atIdx == curPos
                        $scope.$apply(() -> 
                            stopDetecting()
                        )
                        return
                    if evt.keyCode == 8
                        inputText = headText.substring(atIdx + 1, curPos - 1) 
                    else
                        inputText = headText.substring(atIdx + 1, curPos)
                    if inputText.match(/^[\S]+$/g) == null
                        $scope.$apply(() -> 
                            stopDetecting()
                        )
                        return
                    console.log inputText
                    callback(inputText)
                , 
                    200
            )

        getInputText((inputText) ->
            hotot.bus.sendMessage(
                {
                    cmd: 'auto_complete', content: {serv: $scope.majorAccount.serv, text: inputText}
                }, (resp) -> 
                    if resp.result == 'ok'
                        $scope.$apply(() -> 
                            handleResult(resp.items)
                        )
            )
        )
        # handleResult(RelationService.find(serv, slotname, inputText));

    stopDetecting = () ->
        inDetecting = false
        foldUI('candidate')

    getCursorPos = () ->
        box = document.querySelector('.text')
        box.focus()
        if box.selectionStart or box.selectionStart == '0'
            return box.selectionStart
        return 0

    $scope.selectCandidate = (user) ->
        insertCandidate(user)

    selectCandidateByIndex = (index) ->
        if index < $scope.candidate_bar.list.length
            insertCandidate($scope.candidate_bar.list[index])

    insertCandidate = (user) ->
        text = textbox.value
        curPos = getCursorPos()  # location of the cursor
        headText = text.substring(0, curPos)
        atIdx = headText.lastIndexOf('@')
        if atIdx == -1 or atIdx == curPos
            return
        textbox.value = text.substring(0, atIdx + 1) + user.name + text.substring(curPos)
        textbox.selectionStart = atIdx + 1 + user.name.length
        textbox.selectionEnd = atIdx + 1 + user.name.length

    $scope.initCompose = ->
        setTimeout(() ->
                effectScroller = new iScroll('effects_bar',
                    { 
                        bounce: true,
                        momentum: false,
                        vScroll: false,
                        hScrollbar: false,
                        useTransition: true,
                    },
                )
                candidateScroller = new iScroll('candidate_bar',
                    { 
                        bounce: true,
                        momentum: false,
                        vScroll: false,
                        hScrollbar: false,
                        useTransition: true,
                    },
                )
            ,
                500
        )
        HotkeyUtils.register([HotkeyUtils.CMD, '1'], (evt) -> selectCandidateByIndex(0))
        HotkeyUtils.register([HotkeyUtils.CMD, '2'], (evt) -> selectCandidateByIndex(1))
        HotkeyUtils.register([HotkeyUtils.CMD, '3'], (evt) -> selectCandidateByIndex(2))
        HotkeyUtils.register([HotkeyUtils.CMD, '4'], (evt) -> selectCandidateByIndex(3))
        HotkeyUtils.register([HotkeyUtils.CMD, '5'], (evt) -> selectCandidateByIndex(4))
        return

    $scope.charNumWarm = ->
        return if $scope.props.remainCharNum < 16 then 'red' else ''

    $scope.pictureButtonCls = ->
        return if $scope.props.has_attachment then 'active' else ''

    $scope.mentionButtonCls = ->
        return if $scope.candidate_bar.show then 'active' else ''

    $scope.effectListStyles = ->
        return { width: "#{$scope.effects.length * 48}px", marginLeft: "#{$scope.effects_bar.offset}px"}

    $scope.scrollEffectsRight = ->
        winWidth = hotot.window.current().getBounds().width
        width = $scope.effects.length * 48
        page = Math.ceil(width / winWidth)
        num = parseInt(winWidth / 48)
        if $scope.effects_bar.offset - 48 * num > - winWidth * (page - 1)
            $scope.effects_bar.offset -= num * 48
        else
            $scope.effects_bar.offset = - winWidth * (page - 1)

    $scope.scrollEffectsLeft = ->
        winWidth = hotot.window.current().getBounds().width
        num = parseInt(winWidth / 48)
        if $scope.effects_bar.offset + 48 * num < 0
            $scope.effects_bar.offset += 48 * num
        else
            $scope.effects_bar.offset = 0

    $scope.showAccountsBar = ->
        $scope.account_list.show = true

    $scope.hideAccountsBar = ->
        $scope.account_list.show = false

    $scope.showDraftList = ->
        $scope.draft_list.show = true

    $scope.hideDraftList = ->
        $scope.draft_list.show = false

    $scope.hasDraft = ->
        return $scope.draft_list.drafts.length != 0

    $scope.saveDraft = ->
        text = textbox.value
        hotot.bus.sendMessage(
            {win: 'composer', cmd: "create_draft", content: {context: $scope.context, text: text}}
            , reloadDrafts
        )
        $scope.draft_list.show = false

    $scope.resumeDraft = (draft) ->
        textbox.value = draft.text
        $scope.context.id = draft.context_id
        $scope.context.text = draft.context_text
        $scope.context.type = draft.context_type
        switch draft.context_type 
            when 'reply'
                document.title = "Reply"
                $scope.context_bar.text = draft.context_text
                expandUI('context')
                moveCursor(-1)
            when 'quote'
                document.title = "Quote"
                moveCursor(0)
        $scope.draft_list.show = false
        hotot.bus.sendMessage(
            {win: 'composer', cmd: "delete_draft", content: {uuid: draft.uuid}}
            , reloadDrafts
        )
        document.querySelector('.text').focus()
        return

    $scope.deleteDraft = (draft) ->
        $scope.draft_list.show = false
        hotot.bus.sendMessage(
            {win: 'composer', cmd: "delete_draft", content: {uuid: draft.uuid}}
            , reloadDrafts
        )
        return

    $scope.post = () ->
        text = textbox.value
        pos = text.indexOf('-whisper')
        setForbiddens = false
        key = null
        value = null
        if pos == 0
            tmp = text.split(' ').filter((x) -> x.trim())
            if tmp.length == 3
                key = tmp[1]
                value = tmp[2]
                setForbiddens = true
            else if tmp.length == 2
                key = tmp[1]
                value = null
                setForbiddens = true
        if setForbiddens
            hotot.bus.sendMessage(
                { 
                    role: 'composer',
                    cmd: "whisper", 
                    content: { key: key, value: value }
                }
            )
        else
            accounts = []
            for acc in $scope.currentSelection
                accounts.push({serv: acc.serv, name: acc.name})
            hotot.bus.sendMessage(
                { 
                    win: 'composer',
                    cmd: "ignite", 
                    content: { 
                        accounts: accounts, context: $scope.context, 
                        text: text, has_attachment: $scope.props.has_attachment, 
                        attachment: $scope.props.attachment
                    }
                }
            )
        $scope.close()

    $scope.changeAccountSelection = (selection, index) =>
        console.log selection, index
        return

    $scope.handleKeyDown = (evt) ->
        if evt.metaKey or evt.ctrlKey
            # shortcut binding Ctrl+Enter or Command+Enter(Mac)
            if navigator.platform.indexOf('Mac') != -1
                if evt.metaKey and evt.keyCode == 13
                    $scope.post()
                    return false
                if evt.metaKey and evt.keyCode == 82
                    return false
            else
                if evt.ctrlKey and evt.keyCode == 13
                    $scope.post()
                    return false
            if evt.keyCode == 27 #esc
                $scope.close()
            HotkeyUtils.crack(evt)
        else 
            autocomp(evt)

    $scope.handleKeyUp = (evt) ->
        # @TODO 140 should be defined in proto
        $scope.props.remainCharNum = 140 - getMessageLen()
        return

    $scope.insertPicture = (evt) ->
        if $scope.props.has_attachment
            $scope.props.has_attachment = false
        else
            hotot.fs.chooseEntry({type: 'openFile'}, (fileEntry) ->
                if fileEntry
                    fileEntry.file((file) -> loadFile(file))
            )
        return

    $scope.applyEffect = (effect) ->
        if effect.name == 'normal' # reset
            $scope.props.attachment.base64_data = $scope.props.attachment.base64_data_bk
        else
            img = new Image()
            img.src = $scope.props.attachment.base64_data_bk
            $scope.effects_bar.spinner_show = true
            $scope.effects_bar.spinner_label = 'Processing ...'
            img.loadOnce(() -> 
                # 防止用onload事件注册后  replace会改变img的src导致onload事件再次触发形成循环
                ai = AlloyImage(this)
                ai.ps(effect.name).replace(this)
                $scope.$apply(()->
                    $scope.props.attachment.base64_data = img.src
                )
            )
        return

    $scope.attachmentLoaded = ->
        console.log "loaded"
        $scope.effects_bar.spinner_show = false
        return

    $scope.close = ->
        window.close()

    $scope.onFileDragover = (evt) ->
        return false

    $scope.onFileDragend = (evt) ->
        return false

    $scope.onFileDrop = (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        fileEntry = evt.dataTransfer.items[0].webkitGetAsEntry()
        if fileEntry
            fileEntry.file((file) -> loadFile(file))
        return false

    $scope.feedback = (evt) ->
        foldUI('effect')
        foldUI('context')
        textbox.value = "@HototApp ver#{Hotot.CURRENT_VERSION} #{Hotot.CURRENT_CODENAME} "
        moveCursor(-1)
        document.querySelector('.text').focus()

    $scope.mention = (evt) ->
        curPos = getCursorPos()
        text = textbox.value
        left = text.substring(0, curPos).trim()
        if left.length != 0 then left += ' '
        textbox.value = left + '@ ' + text.substring(curPos).trim()
        textbox.selectionStart = left.length + 1
        textbox.selectionEnd = left.length + 1
        document.querySelector('.text').focus()

    loadFile = (file) ->
        if not Hotot.imageTest(file.name)
            console.log "not a image file"
            return false
        $scope.props.attachment.filename = file.name
        $scope.props.attachment.type = file.type
        $scope.props.attachment.size = file.size
        reader = new FileReader()
        reader.onerror = (err) -> 
            console.log "failed to load file", err
        reader.onloadend = (e) ->
            $scope.$apply(() ->
                $scope.props.has_attachment = true
                $scope.props.attachment.base64_data = e.target.result
                $scope.props.attachment.base64_data_bk = e.target.result
            )
        # reader.readAsText(file)
        reader.readAsDataURL(file)
        return false

    expandUI = (uiName) ->
        win = hotot.window.current()
        bounds = win.getBounds()
        bounds.height = BASE_HEIGHT
        if $scope.context_bar.show then bounds.height += CONTEXT_HEIGHT
        if $scope.effects_bar.show then bounds.height += EFFECT_HEIGHT
        if $scope.candidate_bar.show then bounds.height += CANDIDATE_HEIGHT

        if uiName == 'context' and $scope.context_bar.show == false
            $scope.context_bar.show = true
            bounds.height += CONTEXT_HEIGHT
        else if uiName == 'effect' and $scope.effects_bar.show == false
            $scope.effects_bar.show = true
            bounds.height += EFFECT_HEIGHT
            if $scope.candidate_bar.show == true
                $scope.candidate_bar.show = false
                bounds.height -= CANDIDATE_HEIGHT
        else if uiName == 'candidate' and $scope.candidate_bar.show == false
            $scope.candidate_bar.show = true
            bounds.height += CANDIDATE_HEIGHT
            if $scope.effects_bar.show == true
                $scope.effects_bar.show = false
                bounds.height -= EFFECT_HEIGHT
        win.setBounds(bounds)
        return

    foldUI = (uiName) ->
        win = hotot.window.current()
        bounds = win.getBounds()
        bounds.height = BASE_HEIGHT
        if $scope.context_bar.show then bounds.height += CONTEXT_HEIGHT
        if $scope.effects_bar.show then bounds.height += EFFECT_HEIGHT
        if $scope.candidate_bar.show then bounds.height += CANDIDATE_HEIGHT

        if uiName == 'context' and $scope.context_bar.show == true
            $scope.context_bar.show = false
            bounds.height -= CONTEXT_HEIGHT
        else if uiName == 'effect' and $scope.effects_bar.show == true
            $scope.effects_bar.show = false
            bounds.height -= EFFECT_HEIGHT
        else if uiName == 'candidate' and $scope.candidate_bar.show == true
            $scope.candidate_bar.show = false
            bounds.height -= CANDIDATE_HEIGHT
        win.setBounds(bounds)
        return

    $scope.candidateBarStyles = -> 
        if $scope.candidate_bar.show
            return { 'height': (CANDIDATE_HEIGHT - 6) + 'px', 'margin-top': '6px' }
        else
            return { 'height': '0px', 'margin-top': '0px' }

    $scope.effectsBarStyles = -> 
        if $scope.effects_bar.show
            return { 'height': (EFFECT_HEIGHT - 6) + 'px', 'margin-top': '6px' }
        else
            return { 'height': '0px', 'margin-top': '0px' }

    hotot.bus.onMessage.addListener((request, sender, senderResponse) =>
        if request.recipient != win.id
            return
        if request.cmd == 'reset_composer'
            content = request.content
            console.log content
            $scope.$apply(() ->
                $scope.majorAccount = content.major_account
                $scope.accounts = content.accounts
                for acc, i in $scope.accounts
                    if acc.name == $scope.majorAccount.name and acc.serv == $scope.majorAccount.serv
                        $scope.currentSlot = $scope.accounts[i]
                        $scope.currentSelection = [$scope.accounts[i]]
                $scope.context = content.context
                $scope.draft_list.drafts = content.drafts
                if content.media != null
                    $scope.props.has_attachment = true
                    $scope.props.attachment.base64_data = content.media.data
                    $scope.props.attachment.base64_data_bk = content.media.data
                    $scope.props.attachment.filename = 'Untitled'
                    $scope.props.attachment.type = 'image'
                    $scope.props.attachment.size = 0
                    expandUI('effect')
                else
                    $scope.props.has_attachment = false
                reset()
            )
    )
    return

])
bindDriective(app, ['KEY', 'MISC', 'DND'])
this.app.directive('onAutocomp', () ->
    (scope, elm, attrs) ->
        fn = scope.$eval(attrs.onAutocomp)
        elm.bind('keydown', (evt) ->
            scope.$apply(() ->
                fn.call(scope, evt);
            )
        )
)
