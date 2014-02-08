root = exports ? this

root.app.factory('ColumnsState', ['$rootScope', ($rootScope) ->
    ColumnsState = {}
    ColumnsState.state = {}
    ColumnsState.bind = (key, posMode) ->
        if not this.state.hasOwnProperty(key)
            this.state[key] =
                position_mode: posMode
                since_id: ''
                max_id: ''
                previous_cursor: ''
                next_cursor: ''
                page: ''
        return this.state[key]

    ColumnsState.unbind = (key) ->
        if this.state.hasOwnProperty(key)
            delete this.state[key]
        return

    ColumnsState.get = (key) ->
        if this.state.hasOwnProperty(key)
            return this.state[key]
        return null

    ColumnsState.save = (key) ->
        return 

    ColumnsState.save = (key) ->
        return 

    return ColumnsState
])
