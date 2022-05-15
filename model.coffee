AccessTokens = undefined
RefreshTokens = undefined
Clients = undefined
AuthCodes = undefined
debug = undefined
accessTokenLifetime = undefined

getAccessTokenHelper = Meteor.bindEnvironment (bearerToken, callback) ->
	try
		token = AccessTokens.findOne { accessToken: bearerToken }
		tokenObj = {
			accessToken: token.accessToken,
			accessTokenExpiresAt: token.expires,
			client: {
				id: token.clientId
			}
			user: {
				id: token.userId
			}
		}
		callback null, tokenObj
	catch e
		callback e

getRefreshTokenHelper = Meteor.bindEnvironment (refreshToken, callback) ->
	try
		token = RefreshTokens.findOne {
			refreshToken: refreshToken
		}
		tokenObj = {
			refreshToken: token.refreshToken,
			refreshTokenExpiresAt: token.expires,
			client: {
				id: token.clientId
			}
			user: {
				id: token.userId
			}
		}
		callback null, tokenObj
	catch e
		callback e

getAuthorizationCodeHelper = Meteor.bindEnvironment (authCode, callback) ->
	try
		code = AuthCodes.findOne {
			authCode: authCode
		}
		codeObj = {
			code: code.code,
			expiresAt: code.expires,
			client: {
				id: code.clientId,
			},
			user: {
				id: code.userId
			}
		}
		callback null, codeObj
	catch e
		callback e

getClientHelper = Meteor.bindEnvironment (clientId, clientSecret, callback) ->
	try
		if not clientSecret?
			client = Clients.findOne { active: true, clientId: clientId }
		else
			client = Clients.findOne { active: true, clientId: clientId, clientSecret: clientSecret }
		if client
			clientObj = {
					id: client.clientId
					grants: ['authorization_code', 'refresh_token']
					redirectUris: if typeof client.redirectUri is 'string' then [client.redirectUri] else client.redirectUri
			}
			callback(null, clientObj)
		else
			callback(null)
	catch e
		callback(e)
	
saveTokenHelper = Meteor.bindEnvironment (token, client, user, callback) ->
	try
		accessTokenId = AccessTokens.insert {
			accessToken: token.accessToken
			clientId: client.id
			userId: user.id
			expires: token.accessTokenExpiresAt
		}
		refreshTokenId = undefined
		if token.refreshToken
			refreshTokenId = RefreshTokens.insert {
				refreshToken: token.refreshToken
				clientId: client.id
				userId: user.id
				expires: token.refreshTokenExpiresAt
			}
		
		tokenObj = {
			accessToken: token.accessToken,
			accessTokenExpiresAt: token.accessTokenExpiresAt,
			refreshToken: token.refreshToken,
			refreshTokenExpiresAt: token.refreshTokenExpiresAt,
			client,
			user
		}
		callback null, tokenObj
	catch e
		callback e

saveAuthorizationCodeHelper = Meteor.bindEnvironment (code, client, user, callback) ->
	try
		code1 = AuthCodes.upsert {
				authCode: code.authorizationCode,
			}, {
				authCode: code.authorizationCode
				clientId: client.id
				userId: user.id
				expires: code.expiresAt
			}
		if code1.numberAffected > 0
			codeObj = {
				authorizationCode: code.authorizationCode,
				expiresAt: code.expiresAt,
				redirectUri: code.redirectUri
				client,
				user
			}
			callback null, codeObj
		else
			throw new Meteor.Error("Unexpected Error")
	catch e
		callback e

revokeAuthorizationCodeHelper = Meteor.bindEnvironment (code, callback) ->
	try
		authCode = AuthCodes.findOne {
			authCode: code.code
		}
		if authCode
			AuthCodes.remove {
				authCode: code.code
			}
			callback null, true
		else
			callback null, false
	catch e
		callback e

revokeTokenHelper = Meteor.bindEnvironment (token, callback) ->
	try
		refreshToken = RefreshTokens.findOne {
			refreshToken: token.refreshToken
		}
		if refreshToken
			RefreshTokens.remove {
				refreshToken: token.refreshToken
			}
			callback null, true
		else
			callback null, false
	catch
		callback e

@Model = class Model
	constructor: (config = {}) ->
		config.accessTokensCollectionName ?= 'oauth_access_tokens'
		config.refreshTokensCollectionName ?= 'oauth_refresh_tokens'
		config.clientsCollectionName ?= 'oauth_clients'
		config.authCodesCollectionName ?= 'oauth_auth_codes'

		@debug = debug = config.debug

		@AccessTokens = AccessTokens = config.accessTokensCollection or new Meteor.Collection config.accessTokensCollectionName
		@RefreshTokens = RefreshTokens = config.refreshTokensCollection or new Meteor.Collection config.refreshTokensCollectionName
		@Clients = Clients = config.clientsCollection or new Meteor.Collection config.clientsCollectionName
		@AuthCodes = AuthCodes = config.authCodesCollection or new Meteor.Collection config.authCodesCollectionName
		@accessTokenLifetime = accessTokenLifetime = config.accessTokenLifetime

	getAccessToken: (bearerToken, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in getAccessToken (bearerToken:', bearerToken, ')'
		getAccessTokenHelper(bearerToken, callback)

	getRefreshToken: (refreshToken, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in getRefreshToken (refreshToken: ' + refreshToken + ')'
		getRefreshTokenHelper(refreshToken, callback)

	getAuthorizationCode: (authCode, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in getAuthCode (authCode: ' + authCode + ')'
		getAuthorizationCodeHelper(authCode, callback)

	getClient: (clientId, clientSecret, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in getClient (clientId:', clientId, ', clientSecret:', clientSecret, ')'
		getClientHelper(clientId, clientSecret, callback)

	saveToken: (token, clientId, user, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in saveAccessToken (token:', token, ', clientId:', clientId, ', user:', user, ')'
		saveTokenHelper(token, clientId, user, callback)

	saveAuthorizationCode: (code, client, user, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in saveAuthorizationCode (code:', code, ', user:', user, ')'
		saveAuthorizationCodeHelper(code, client, user, callback)
	
	revokeToken: (token, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in revokeToken (token: ' + token + ')'
		revokeTokenHelper(token, callback)

	revokeAuthorizationCode: (code, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in revokeAuthorizationCode (code: ' + code + ')'
		revokeAuthorizationCodeHelper(code, callback)

	grantTypeAllowed: (clientId, grantType, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in grantTypeAllowed (clientId:', clientId, ', grantType:', grantType + ')'
		callback(false, grantType in ['authorization_code', 'refresh_token'])
