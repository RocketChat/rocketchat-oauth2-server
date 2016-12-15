AccessTokens = undefined
RefreshTokens = undefined
Clients = undefined
AuthCodes = undefined
debug = undefined

@Model = class Model
	constructor: (config={}) ->
		config.accessTokensCollectionName ?= 'oauth_access_tokens'
		config.refreshTokensCollectionName ?= 'oauth_refresh_tokens'
		config.clientsCollectionName ?= 'oauth_clients'
		config.authCodesCollectionName ?= 'oauth_auth_codes'

		@debug = debug = config.debug

		@AccessTokens = AccessTokens = config.accessTokensCollection or new Meteor.Collection config.accessTokensCollectionName
		@RefreshTokens = RefreshTokens = config.refreshTokensCollection or new Meteor.Collection config.refreshTokensCollectionName
		@Clients = Clients = config.clientsCollection or new Meteor.Collection config.clientsCollectionName
		@AuthCodes = AuthCodes = config.authCodesCollection or new Meteor.Collection config.authCodesCollectionName


	getAccessToken: Meteor.bindEnvironment (bearerToken, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in getAccessToken (bearerToken:', bearerToken, ')'

		try
			token = AccessTokens.findOne accessToken: bearerToken
			callback null, token
		catch e
			callback e


	getClient: Meteor.bindEnvironment (clientId, clientSecret, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in getClient (clientId:', clientId, ', clientSecret:', clientSecret, ')'

		try
			if not clientSecret?
				client = Clients.findOne { active: true, clientId: clientId }
			else
				client = Clients.findOne { active: true, clientId: clientId, clientSecret: clientSecret }
			callback null, client
		catch e
			callback e


	grantTypeAllowed: (clientId, grantType, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in grantTypeAllowed (clientId:', clientId, ', grantType:', grantType + ')'

		return callback(false, grantType in ['authorization_code', 'refresh_token'])


	saveAccessToken: Meteor.bindEnvironment (token, clientId, expires, user, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in saveAccessToken (token:', token, ', clientId:', clientId, ', user:', user, ', expires:', expires, ')'

		try
			tokenId = AccessTokens.insert
				accessToken: token
				clientId: clientId
				userId: user.id
				expires: expires

			callback null, tokenId
		catch e
			callback e


	getAuthCode: Meteor.bindEnvironment (authCode, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in getAuthCode (authCode: ' + authCode + ')'

		try
			code = AuthCodes.findOne authCode: authCode
			callback null, code
		catch e
			callback e


	saveAuthCode: Meteor.bindEnvironment (code, clientId, expires, user, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in saveAuthCode (code:', code, ', clientId:', clientId, ', expires:', expires, ', user:', user, ')'

		try
			codeId = AuthCodes.upsert
				authCode: code
			,
				authCode: code
				clientId: clientId
				userId: user.id
				expires: expires

			callback null, codeId
		catch e
			callback e


	saveRefreshToken: Meteor.bindEnvironment (token, clientId, expires, user, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in saveRefreshToken (token:', token, ', clientId:', clientId, ', user:', user, ', expires:', expires, ')'

		try
			tokenId = RefreshTokens.insert
				refreshToken: token
				clientId: clientId
				userId: user.id
				expires: expires

				callback null, tokenId
		catch e
			callback e


	getRefreshToken: Meteor.bindEnvironment (refreshToken, callback) ->
		if debug is true
			console.log '[OAuth2Server]', 'in getRefreshToken (refreshToken: ' + refreshToken + ')'

		try
			token = RefreshTokens.findOne refreshToken: refreshToken
			callback null, token
		catch e
			callback e
