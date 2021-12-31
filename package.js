Package.describe({
	name: 'rocketchat:oauth2-server',
	version: '3.0.0',
	summary: 'OAuth 2 Server package',
	git: 'https://github.com/RocketChat/rocketchat-oauth2-server.git'
});

Package.onUse(function(api) {
	api.versionsFrom('2.5');

	api.use('coffeescript');

	api.addFiles('model.coffee', 'server');
	api.addFiles('oauth.coffee', 'server');

	api.export('OAuth2Server');
});

Npm.depends({
	"oauth2-server": "2.4.1",
	"express": "4.13.3"
});

Package.onTest(function(api) {

});
