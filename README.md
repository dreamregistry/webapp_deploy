# WEB APP DEPLOY

The development version of a DReAM package that deploys a web app to ECS secured
with Auth0 oidc sidecar.

## Usage

```shell
dream add webapp_deploy
```

## Available endpoints

This package deploys an authentication service sidecar that exposes some
endpoints to
use inside your app:

- `/auth/login`: login through Cognito
- `/auth/logout`: logout through Cognito
- `AUTH_ENDPOINT` environment variable contains the full url for
  authenticating requests. You need to forward cookies to this endpoint with
  a `GET` request. Upon successful authentication, you will receive a `200`
  response status code with the following body:

```yaml
{
  "accessToken": "<access_token>",
  "userInfo": {
    "sub": "<user_id>",
    "email_verified": "<true | false>",
    "name": "<user's full name>",
    "email": "<user's email>",
    "username": "<user's username>"
  },
  "expiresAt": <unix_timestamp> # in seconds.
}
```

If the user is not authenticated, you will receive a `401` response status code.
This endpoint has to be called server-side.
