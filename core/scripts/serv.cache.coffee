root = exports ? this

root.app.factory('HototCache', ['$rootScope', ($rootScope) ->
    HototCache = {}
    HototCache.capacity = 100
    HototCache.visibleRegion = 32
    HototCache.cache = {}
    HototCache.comments = {}

    HototCache.bind = (key) ->
        if not this.cache.hasOwnProperty(key)
            this.cache[key] = []
        return this.cache[key]

    HototCache.unbind = (key) ->
        if this.cache.hasOwnProperty(key)
            delete this.cache[key]
        return

    HototCache.add = (key, item) ->
        if this.cache.hasOwnProperty(key)
            this.cache[key].push(item)
        return

    HototCache.fetch = (key, item) ->
        if this.cache.hasOwnProperty(key)
            return this.cache[key]
        return []

    HototCache.trim = (key) ->
        if this.cache.hasOwnProperty(key)
            if this.cache[key].length > this.capacity
                for i in [this.capacity/2 ... this.cache[key].length]
                    if this.comments.hasOwnProperty(this.cache[key][i].id)
                        delete this.comments[this.cache[key][i].id]
                this.cache[key].splice(this.capacity/2, this.capacity/2)
        return

    HototCache.compress = (key) ->
        if this.cache.hasOwnProperty(key)
            if this.cache[key].length > this.visibleRegion
                for i in [this.visibleRegion ... this.cache[key].length]
                    this.cache[key][i].hide = true
        return

    HototCache.expand = (key) ->
        if this.cache.hasOwnProperty(key)
            if this.cache[key].length > this.visibleRegion
                for i in [this.visibleRegion ... this.cache[key].length]
                    this.cache[key][i].hide = false
        return

    HototCache.findById = (keys, id) ->
        # @TODO use bsearch
        for key in keys
            if this.cache.hasOwnProperty(key)
                for item, idx in this.cache[key]
                    if item.id == id
                        return [item, idx]
        return [null, -1]

    HototCache.getComments = (key, id) ->
        if this.comments.hasOwnProperty(key)
            if this.comments[key].hasOwnProperty(id)
                return [this.comments[key][id].state, this.comments[key][id].data]
        return [0, []]

    HototCache.setComments = (key, id, state, comments) ->
        if not this.comments.hasOwnProperty(key)
            this.comments[key] = {}
        if not this.comments[key].hasOwnProperty(id)
            this.comments[key][id] = {}
        this.comments[key][id].state = state # 0 = fold, 1 = open, 2 = loading
        this.comments[key][id].data = comments
        return

    HototCache.getCommentsState = (key, id) ->
        if this.comments.hasOwnProperty(key)
            if this.comments[key].hasOwnProperty(id)
                return this.comments[key][id].state
        return 0

    HototCache.setCommentsState = (key, id, state) ->
        if not this.comments.hasOwnProperty(key)
            this.comments[key] = {}
        if not this.comments[key].hasOwnProperty(id)
            this.comments[key][id] = {}
        this.comments[key][id].state = state
        return 

    return HototCache
])
