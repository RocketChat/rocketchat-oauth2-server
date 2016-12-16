# History

## 2.0.0 - 2016/01/08

- Rename all athorizedClients to authorizedClients (please update your users DB too)
- Allow `refresh_token` as a Grant Type
- Transform any requests to `/oauth/token` that is `POST` and isn't `application/x-www-form-urlencoded`, merging the body and the query strings. See [pull request #5](https://github.com/RocketChat/rocketchat-oauth2-server/pull/5) for more details.

## 1.4.0 - 2016/01/08

- Redirect user to `/oauth/error/404` instead of `/oauth/404`
- Redirect user to `/oauth/error/invalid_redirect_uri` if uri does not match

## 1.3.0 - 2016/01/08

- Redirect user to `/oauth/404` if client does not exists or is inactive

## 1.2.0 - 2016/01/07

- Return only clients with `active: true`

## 1.1.1 - 2015/01/06

- Only process errors for oauth routes

## 1.1.0 - 2015/01/05

- Allow pass collection object instead collection name

## 1.0.1 - 2015/12/31

- Added more debug logs

## 1.0.0 - 2015/12/31

- Initial implementation
