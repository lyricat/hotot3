
 # A JavaScript implementation for Sina Weibo's OAuth(OAuth 2.0)
 # Version 0.1 Copyright Shellex Wai<5h3ll3x@gmail.com> 2009 - 2013.
 # Distributed under the MIT License
 # See http://oauth.net/ for details.
root = exports ? this

root.app.factory('OAuth2', ['$http', ($http) ->
    buildFn = () ->
        lib = {}
        lib.oauth_base = 'https://api.weibo.com/oauth2/'
        lib.access_token_url = 'access_token'
        lib.user_auth_url = 'authorize'
        lib.key = ''
        lib.secret = ''
        lib.access_token = null
        lib.redirect_uri = 'https://api.weibo.com/oauth2/default.html'

        lib.get_auth_url = () ->
            return "#{lib.oauth_base}#{lib.user_auth_url}?client_id=#{lib.key}&redirect_uri=#{lib.redirect_uri}&display=wap&forcelogin=true"

        lib.get_access_token = (pin, on_success, on_error) ->
            params = 
                client_id: lib.key
                client_secret: lib.secret
                grant_type: 'authorization_code'
                redirect_uri: lib.redirect_uri
                code: pin
            $http({method: 'POST', url: lib.oauth_base + lib.access_token_url, data: params}).
                success((data, status, headers, config) ->
                    lib.access_token = data
                    if on_success then on_success(data)
                ).
                error((data, status, headers, config) ->
                    if on_error then on_error(data)
                )
            return
        return lib
    return buildFn
])
