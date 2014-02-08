root = exports ? this

root.app.factory('RelationService', ['$rootScope', 'HototRelationships', 'Logger', ($rootScope, HototRelationships, Logger) ->
    RelationService = {}
    RelationService.relation = {}
    RelationService.init = ->
        RelationService.loads()
        Logger.info("init Relationships Service")
        hotot.bus.onMessage.addListener((message, sender, respond) ->
            # console.log('control', ev)
            cmd = message.cmd
            switch cmd
                when 'load_relationships'
                    RelationService.loads()
                when 'save_relationships'
                    RelationService.dumps()
            return true
        )
        RelationService.autoDumps()

    RelationService.bind = (serv, slotname) ->
        key = "#{serv}/#{slotname}"
        if not this.relation.hasOwnProperty(key)
            this.relation[key] =
                following_ids: {}
                users: {}
                idIndex: {}
        return this.relation[key]

    RelationService.unbind = (serv, slotname) ->
        key = "#{serv}/#{slotname}"
        if this.relation.hasOwnProperty(key)
            delete this.relation[key]
        return

    RelationService.add = (serv, slotname, users) ->
        key = "#{serv}/#{slotname}"
        if this.relation.hasOwnProperty(key)
            for user in users
                username = user.name.toLowerCase()
                this.relation[key].users[username] = user
                this.relation[key].users[username].createTime = Date.now()
                this.relation[key].idIndex[user.id] = this.relation[key].users[username]
                if this.relation[key].following_ids.hasOwnProperty(user.id)
                    this.relation[key].users[username].following = true
        return

    RelationService.updateFollowingIds = (serv, slotname, ids) ->
        key = "#{serv}/#{slotname}"
        if this.relation.hasOwnProperty(key)
            for id in ids
                if id.constructor == Number
                    id = id.toString()
                if RelationService.relation[key].idIndex.hasOwnProperty(id)
                    RelationService.relation[key].idIndex[id].following = true
                this.relation[key].following_ids[id] = null

    RelationService.isFollowing = (serv, slotname, user) ->
        key = "#{serv}/#{slotname}"
        if this.relation.hasOwnProperty(key)
            if this.relation[key].following_ids.hasOwnProperty(user.id)
                return true
        return false

    RelationService.setRelationship = (serv, slotname, name, rel) ->
        key = "#{serv}/#{slotname}"
        if this.relation.hasOwnProperty(key)
            name = name.toLowerCase()
            if this.relation[key].users.hasOwnProperty(name)
                return this.relation[key].users[name].relationship = rel
        return null

    RelationService.find = (serv, slotname, piece) ->
        result = []
        filterProc = (name, piece) -> name.toLowerCase().indexOf(piece.toLowerCase()) != -1
        process = (key) ->
            rel = RelationService.relation[key]
            for name, user of rel.users
                if filterProc(name, piece)
                    result.push(user)
        if slotname == '*'
            for key, rel of this.relation
                process(key)
        else
            key = "#{serv}/#{slotname}"
            if this.relation.hasOwnProperty(key)
                process(key)
        return result

    RelationService.getByName = (serv, slotname, name) ->
        key = "#{serv}/#{slotname}"
        if this.relation.hasOwnProperty(key)
            name = name.toLowerCase()
            if this.relation[key].users.hasOwnProperty(name)
                return this.relation[key].users[name]
        return null

    RelationService.getById = (serv, slotname, id) ->
        key = "#{serv}/#{slotname}"
        if this.relation.hasOwnProperty(key)
            if this.relation[key].idIndex.hasOwnProperty(id)
                return this.relation[key].idIndex[id]
        return null

    RelationService.autoDumps = ->
        setInterval(RelationService.dumps, 60000)

    RelationService.dumps = ->
        relation = {}
        for key, rel of RelationService.relation
            relation[key] = {
                idIndex: {}
                following_ids: {}
                users: rel.users
            }
        HototRelationships.dumps(relation)
        return

    RelationService.loads = ->
        HototRelationships.loads((rels) ->
            a = []
            for key, rel of rels
                for k, v of rel.users
                    a.push(rel.users[k])
                Logger.info("load relationships: #{key}, count=#{a.length}")
                RelationService.relation[key] = rel
        )
        return

    return RelationService
])
