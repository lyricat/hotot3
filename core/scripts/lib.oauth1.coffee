
 # A JavaScript implementation for twitter's OAuth(OAuth 1.0)
 # Version 1.1 Copyright Shellex Wai<5h3ll3x@gmail.com> 2009 - 2013.
 # Distributed under the MIT License
 # See http://oauth.net/ for details.
root = exports ? this

root.app.factory('OAuth1', ['$http', ($http) ->
    buildFn = () ->
        lib = {}
        lib.oauth_base = 'https://api.twitter.com/oauth/'
        lib.sign_oauth_base = 'https://api.twitter.com/oauth/'
        lib.use_same_sign_oauth_base = false
        lib.request_token_url = 'request_token'
        lib.access_token_url = 'access_token'
        lib.user_auth_url = 'authorize'
        lib.key = ''
        lib.secret = ''
        lib.request_token = null
        lib.access_token = null

        lib.timestamp = () ->
            t = (new Date()).getTime()
            return Math.floor(t / 1000)

        lib.nonce = (length) ->
            return Math.random().toString().substring(2)

        lib.form_signed_url = (url, token, method, params) ->
            url = url + '?' + lib.form_signed_params(url, token, method, params)
            return url

        lib.form_signed_params = (url, token, method, addition_params, use_dict) ->
            kwargs = 
                oauth_consumer_key: lib.key
                oauth_signature_method: 'HMAC-SHA1'
                oauth_version: '1.0'
                oauth_timestamp: lib.timestamp()
                oauth_nonce: lib.nonce()

            if addition_params != null
                angular.extend(kwargs, addition_params)

            service_key = lib.secret + '&'
            if token != null
                kwargs['oauth_token'] = token['oauth_token']
                service_key = service_key + Hotot.quote(token['oauth_token_secret'])

            # normalize_params
            params = Hotot.normalizeParams(kwargs)
            message = Hotot.quote(method) + '&' + Hotot.quote(url) + '&' + Hotot.quote(params)

            # sign
            b64pad = '='
            signature = b64_hmac_sha1(service_key, message)
            kwargs['oauth_signature'] = signature + b64pad
            if use_dict
                return kwargs
            else
                return Hotot.normalizeParams(kwargs)

        lib.get_request_token = (on_success, on_error) ->
            sign_base = if lib.use_same_sign_oauth_base then lib.oauth_base else lib.sign_oauth_base
            url = lib.oauth_base + lib.request_token_url + '?' + lib.form_signed_params(sign_base + lib.request_token_url, null, 'GET', null)
            $http({method: 'GET', url: url}).
                success((data, status, headers, config) ->
                    token_info = data
                    lib.request_token = Hotot.unserializeDict(token_info)
                    if on_success then on_success(data)
                ).
                error((data, status, headers, config) ->
                    if on_error then on_error(data)
                )

        lib.get_auth_url = () ->
            return lib.oauth_base + lib.user_auth_url + '?oauth_token' + '=' + lib.request_token['oauth_token']

        lib.get_access_token = (pin, on_success, on_error) ->
            if lib.request_token == {}
                return
            sign_base = if lib.use_same_sign_oauth_base then lib.oauth_base else lib.sign_oauth_base
            addition_params = {
                'oauth_verifier': pin
            }
            params = lib.form_signed_params(sign_base + lib.access_token_url, lib.request_token, 'GET', addition_params)
            $http({method: 'GET', url: lib.oauth_base + lib.access_token_url + '?' + params}).
                success((data, status, headers, config) ->
                    token_info = data
                    lib.access_token = Hotot.unserializeDict(token_info)
                    if on_success then on_success(data)
                ).
                error((data, status, headers, config) ->
                    if on_error then on_error(data)
                )
            return
        return lib
    return buildFn
])

