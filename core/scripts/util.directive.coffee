root = exports ? this
root.bindDriective = (app, evtCat) ->
    # DND
    for name in evtCat
        switch name
            when 'DND'
                bindDNDDriective(app)
            when 'KEY'
                bindKEYDriective(app)
            when 'SCROLL'
                bindSCROLLDriective(app)
            when 'MOUSE'
                bindMOUSEDriective(app)
            when 'ANI'
                bindANIDriective(app)
            when 'MISC'
                bindMISCDriective(app)
    return

bindDNDDriective = (app) ->
    app.directive('onDragstart', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onDragstart)
            elm.bind('dragstart', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt)
                )
            )
    ).directive('onDragenter', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onDragenter)
            elm.bind('dragenter', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt);
                )
            )
    ).directive('onDragover', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onDragover)
            elm.bind('dragover', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt);
                )
            )
    ).directive('onDragleave', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onDragleave)
            elm.bind('dragleave', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt);
                )
            )
    ).directive('onDragend', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onDragend)
            elm.bind('dragend', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt);
                )
            )
    ).directive('onDrop', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onDrop)
            elm.bind('drop', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt);
                )
            )
    )

bindKEYDriective = (app) ->
    app.directive('onKeydown', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onKeydown)
            elm.bind('keydown', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt);
                )
            )
    ).directive('onKeyup', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onKeyup)
            elm.bind('keyup', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt);
                )
            )
    )

bindMOUSEDriective = (app) ->
    app.directive('onMousewheel', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onMousewheel)
            elm.bind('mousewheel', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt)
                )
            )
    )

bindSCROLLDriective = (app) ->
    app.directive('whenScrollstop', () ->
        (scope, elm, attrs) ->
            _timer = null
            fn = scope.$eval(attrs.whenScrollstop)
            elm.bind('scroll', (evt) ->
                if _timer != null
                    clearTimeout(_timer)
                _timer = setTimeout(() ->
                    scope.$apply(() ->
                        fn.call(scope, evt)
                    )
                , 1000
                )
            )
    ).directive('whenScrolling', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.whenScrolling)
            elm.bind('scroll', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt)
                )
            )
    ).directive('whenScrollbottom', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.whenScrollbottom)
            checkBounds = (evt) ->
                if elm[0].scrollTop + elm[0].clientHeight == elm[0].scrollHeight
                    scope.$apply(() ->
                        fn.call(scope, evt)
                    )
            elm.bind('scroll', checkBounds)
    ).directive('whenScrolltop', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.whenScrolltop)
            checkBounds = (evt) ->
                if elm[0].scrollTop == 0
                    scope.$apply(() ->
                        fn.call(scope, evt)
                    )
            elm.bind('scroll', checkBounds)
    )

bindANIDriective = (app) ->
    app.directive('onAnimationend', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onAnimationend)
            elm.bind('webkitAnimationEnd', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt)
                )
            )
    ).directive('onAnimationstart', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onAnimationstart)
            elm.bind('webkitAnimationStart', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt);
                )
            )
    )

bindMISCDriective = (app) ->
    # other useful dom event
    app.directive('onLoaded', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onLoaded)
            elm.bind('load', (evt) ->
                    scope.$apply(() ->
                        fn.call(scope, evt)
                    )
                )
    ).directive('onDomloaded', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onDomloaded)
            elm.bind('DOMContentLoaded', (evt) ->
                    scope.$apply(() ->
                        fn.call(scope, evt)
                    )
                )
    ).directive('onFocus',  () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onFocus)
            elm.bind('focus', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt)
                )
            )
    ).directive('onBlur', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onBlur)
            elm.bind('blur', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt)
                )
            )
    ).directive('onLoadstop', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onLoadstop)
            elm.bind('loadstop', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt);
                )
            )
    ).directive('onLoadcommit', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onLoadcommit)
            elm.bind('loadcommit', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt);
                )
            )
    ).directive('onError', () ->
        (scope, elm, attrs) ->
            fn = scope.$eval(attrs.onError)
            elm.bind('error', (evt) ->
                scope.$apply(() ->
                    fn.call(scope, evt);
                )
            )
    )