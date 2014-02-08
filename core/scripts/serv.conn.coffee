root = exports ? this

root.app.factory('ConnManager', ['HototSlot', 'HototDaemon', 'AppService', 
(HototSlot, HototDaemon, AppService) -> 
    ConnManager = {}
    ConnManager.protocols = {}
    ConnManager.clients = {}

    ConnManager.init = ()->
        HototSlot.all((slots) ->
            for slot in slots
                conn = ConnManager.createConn(slot.serv, slot.name)
                conn.config(slot)
            HototDaemon.run()
        )

    ConnManager.createConn = (serv, name) ->
        if ConnManager.protocols.hasOwnProperty(serv)
            key = serv + '/' + name
            client = new ConnManager.protocols[serv]()
            ConnManager.clients[key] = client
            # @BUG the streaming should be slot specified.
            if client.supportStream
                HototDaemon.registerStream(serv, name, client.buildWatcher())
            return client

    ConnManager.getConn = (serv, slotName) ->
        key = serv + '/' + slotName
        if ConnManager.clients.hasOwnProperty(key)
            return ConnManager.clients[key]
        return null    

    ConnManager.getProto = (serv) ->
        if ConnManager.protocols.hasOwnProperty(serv)
            return ConnManager.protocols[serv]
        return null

    ConnManager.addProto = (serv, protocol) ->
        ConnManager.protocols[serv] = protocol

    return ConnManager
])
