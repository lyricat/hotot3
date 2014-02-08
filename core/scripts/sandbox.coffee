class Controller
  constructor: (@sandboxSelector) ->
    @ready = false
    @msgTable = {}
    @sandbox = $(@sandboxSelector).get(0)

  register: () ->
    window.addEventListener("message",
      (ev) =>
        # console.log('control', ev)
        id = ev.data.id
        result = ev.data.result
        state = ev.data.state
        if @msgTable.hasOwnProperty(id)
          if state == 0
            @msgTable[id](result)
          else
            console.log("error ##{state}: #{result}")
          delete @msgTable[id]
    )
    @checkSandbox()
      
  checkSandbox: =>
    if not @ready
      @mandate('ok?', null, (result)=>
        @ready = true
      )
      setTimeout(@checkSandbox, 100)

  s4: () ->
    (((1+Math.random())*0x10000)|0).toString(16).substring(1)

  mandate: (cmd, context, callback) ->
    id = @s4()
    @msgTable[id] = callback
    @postMessage(id, cmd, context)

  postMessage: (id, cmd, context) ->
    msg = {id: id, cmd: cmd, context: context}
    # console.log('post message to sandbox', msg)
    if @sandbox.contentWindow
      @sandbox.contentWindow.postMessage(msg, "*")

root = exports ? self
root.SandBoxCtrl = Controller

