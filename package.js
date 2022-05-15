Package.describe({
	name: 'rocketchat:oauth2-server',
	version: '4.0.0',
	summary: 'OAuth 2 Server package',
	git: 'https://github.com/RocketChat/rocketchat-oauth2-server.git'
});

Package.onUse(function(api) {
	api.versionsFrom('2.5');

	api.use('coffeescript@1.0.17');

	api.addFiles('model.coffee', 'server');
	api.addFiles('oauth.coffee', 'server');

	api.export('OAuth2Server');
});

Npm.depends({
	"express-oauth-server": "2.0.0",
	"express": "4.13.3"
});

Package.onTest(function(api) {

});
