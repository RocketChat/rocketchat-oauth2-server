oauthserver = Npm.require('oauth2-server')
express = Npm.require('express')

# WebApp.rawConnectHandlers.use app
# JsonRoutes.Middleware.use app


class OAuth2Server
	constructor: (@config={}) ->
		@app = express()

		@routes = express()

		@model = new Model(@config)

		@oauth = oauthserver
			model: @model
			grants: ['authorization_code', 'refresh_token']
			debug: @config.debug

		@publishAuhorizedClients()
		@initRoutes()

		return @


	publishAuhorizedClients: ->
		Meteor.publish 'authorizedOAuth', ->
				if not @userId?
					return @ready()

				return Meteor.users.find
					_id: @userId
				,
					fields:
						'oauth.authorizedClients': 1

				return user?


	initRoutes: ->
		self = @
		debugMiddleware = (req, res, next) ->
			if self.config.debug is true
				console.log '[OAuth2Server]', req.method, req.url
			next()

		# Transforms requests which are POST and aren't "x-www-form-urlencoded" content type
		# and they pass the required information as query strings
		transformRequestsNotUsingFormUrlencodedType = (req, res, next) ->
			if not req.is('application/x-www-form-urlencoded') and req.method is 'POST'
				if self.config.debug is true
					console.log '[OAuth2Server]', 'Transforming a request to form-urlencoded with the query going to the body.'
				req.headers['content-type'] = 'application/x-www-form-urlencoded'
				req.body = Object.assign {}, req.body, req.query
			next()

		@app.all '/oauth/token', debugMiddleware, transformRequestsNotUsingFormUrlencodedType, @oauth.grant()

		@app.get '/oauth/authorize', debugMiddleware, Meteor.bindEnvironment (req, res, next) ->
			client = self.model.Clients.findOne({ active: true, clientId: req.query.client_id })
			if not client?
				return res.redirect '/oauth/error/404'

			if client.redirectUri isnt req.query.redirect_uri
				return res.redirect '/oauth/error/invalid_redirect_uri'

			next()

		@app.post '/oauth/authorize', debugMiddleware, Meteor.bindEnvironment (req, res, next) ->
			if not req.body.token?
				return res.sendStatus(401).send('No token')

			user = Meteor.users.findOne
				'services.resume.loginTokens.hashedToken': Accounts._hashLoginToken req.body.token

			if not user?
				return res.sendStatus(401).send('Invalid token')

			req.user =
				id: user._id

			next()


		@app.post '/oauth/authorize', debugMiddleware, @oauth.authCodeGrant (req, next) ->
			if req.body.allow is 'yes'
				Meteor.users.update req.user.id, {$addToSet: {'oauth.authorizedClients': @clientId}}

			next(null, req.body.allow is 'yes', req.user)

		@app.use @routes

		@app.all '/oauth/*', @oauth.errorHandler()
