class ColumnUtils
    @COMPARE_MODE_ID = 0
    @COMPARE_MODE_TIME = 1
    @COMPARE_MODE_ID_MIXED = 2
    @COMPARE_MODE_TIME_MIXED = 3 #defaults
    @compareTimestamp = (it1, it2) ->
        ts1 = it1.timestamp
        ts2 = it2.timestamp
        if ts1 == ts2 
            return 0
        else 
            return if ts1 < ts2 then -1 else 1

    @compareId = (id1, id2) ->
        if id1.length < id2.length
            return -1
        else if id2.length < id1.length
            return 1
        else
            if id1 == id2 
                return 0
            else 
                return if id1 < id2 then -1 else 1

    @compareItemId = (it1, it2) ->
        id1 = it1.id
        id2 = it2.id
        return ColumnUtils.compareId(id1, id2)

    @getNext = (totalSize, current, reversion) ->
        # reversion == true means from top to down
        nextIndex = -1
        if totalSize == 0 # empty
            return -1
        if current == -1
            nextIndex = if reversion then 0 else totalSize - 1
        else
            if reversion
                nextIndex = if current == totalSize - 1 then -1 else current + 1
            else
                nextIndex = if current == 0 then -1 else current - 1
        return nextIndex

   # column controller should supports following methods:
    # - append
    # - appendMany
    # - prepend
    # - prependMany
    # - insert: called by daemon, push update, insert one item to correct position
    # - insertMany: same to above, insert several items to correct position
    @append = (can, item) =>
        can.push(item)

    @prepend = (can, item) =>
        can.unshift(item)

    @appendMany = (can, items) => 
        for it in items
            can.push(it)

    @prependMany = (can, items) =>
        for it in items
            can.unshift(it)

    @insert = (can, item, opts) =>
        # console.log 'insert', item.text
        reversion = true # from top to bottom by defaults
        compareMode = @COMPARE_MODE_TIME_MIXED
        compareProcMajor = @compareTimestamp
        compareProcMinor = @compareItemId
        if opts
            if opts.hasOwnProperty('reversion') then reversion = opts.reversion
            if opts.hasOwnProperty('compare_mode') then compareMode = opts.compare_mode
        if compareMode == @COMPARE_MODE_ID or compareMode == @COMPARE_MODE_ID_MIXED
            compareProcMajor = @compareItemId
            compareProcMinor = @compareTimestamp
        nextIndex = @getNext(can.length, -1, reversion)
        while true
            # console.log 'next index', nextIndex
            if nextIndex == -1 # empty
                # insert to end of container
                # or the top of the container,
                # according to argument `reversion`
                if reversion
                    @prepend(can, item)
                else
                    @append(can, item)
                return 1
            else # not empty
                nextOne = can[nextIndex]
                cmpRet = compareProcMajor(nextOne, item)
                # console.log cmpRet, nextOne.id, item.id
                if cmpRet == 0 
                    if compareMode == @COMPARE_MODE_ID_MIXED or compareMode == @COMPARE_MODE_TIME_MIXED
                        # nextOne.timestamp == item.timestamp
                        subRet = compareProcMinor(nextOne, item)
                        if subRet == 0
                            # console.log 'duplicate, dump'
                            return 0
                        else if cmpRet == -1
                            # nextOne.id < item.id
                            if reversion
                                can.splice(nextIndex, 0, item)
                                return 1
                            else
                                nextIndex = @getNext(can.length, nextIndex, reversion)
                                if nextIndex == -1
                                    # console.log 'meet top'
                                    can.unshift(item)
                                    return 1
                                # console.log 'too big, try upper one:', nextIndex
                        else 
                            # nextOne.timestamp > item.timestamp
                            if reversion
                                nextIndex = @getNext(can.length, nextIndex, reversion)
                                if nextIndex == -1
                                    # console.log 'meet bottom'
                                    can.push(item)
                                    return 1
                                # console.log 'too small, try lower one:', nextIndex
                            else
                                can.splice(nextIndex + 1, 0, item)
                                return 1
                    else
                        return 0
                else if cmpRet == -1
                    # nextOne.timestamp < item.timestamp
                    if reversion
                        can.splice(nextIndex, 0, item)
                        return 1
                    else
                        nextIndex = @getNext(can.length, nextIndex, reversion)
                        if nextIndex == -1
                            # console.log 'meet top'
                            can.unshift(item)
                            return 1
                        # console.log 'too big, try upper one:', nextIndex
                else
                    # nextOne.timestamp > item.timestamp
                    if reversion
                        nextIndex = @getNext(can.length, nextIndex, reversion)
                        if nextIndex == -1
                            # console.log 'meet bottom'
                            can.push(item)
                            return 1
                        # console.log 'too small, try lower one:', nextIndex
                    else
                        can.splice(nextIndex + 1, 0, item)
                        return 1
        return 0

    @insertMessage = (can, item) ->
        can.push(item)
        return 1

    @makeColumnOrder = (formalizer, columnsOrder, columns) ->
        out = []
        outNames = []
        for orderName in columnsOrder
            for col in columns
                if col.name == orderName
                    out.push(formalizer(col))
                    outNames.push(orderName)
                    break
        return [out, outNames]

    @mergeAttachments = (dst, src) ->
        if src.has_attachments
            dst.attachments = dst.attachments.concat(src.attachments)
            dst.has_attachments = true
            if dst.attachments_label.length == 0
                dst.attachments_label = src.attachments_label
        return dst

root = exports ? this
this.ColumnUtils = ColumnUtils
