# WEB APP DEPLOY

The development version of a DReAM package that deploys a web app to ECS secured
with Auth0 oidc sidecar.

## Usage

```shell
dream add webapp_deploy
```

## Example usage with NextJS (App Router)

```typescript
// src/app/auth.ts

import {headers} from 'next/headers';
import {redirect} from 'next/navigation';

export async function authenticate(currentPath = '/') {
    const auth = await fetch(process.env.AUTH_ENDPOINT!, {
        headers: {
            cookie: headers().get('cookie') ?? '',
        }
    })
    if (auth.status !== 200) {
        return redirect('/auth/login?state=' + encodeURIComponent(currentPath))
    }

    const {
        userInfo: {sub: id, email, name, nickname},
        accessToken
    } = await auth.json() as AuthInfo
    return {user: {id, email, name, nickname}, accessToken}
}

export async function getUser(currentPath = '/') {
    const {user} = await authenticate(currentPath)
    return user
}

export type UserInfo = {
    sub: string
    email: string
    name: string
    nickname: string
    email_verified: boolean
    picture: string
    updated_at: string
}

export type AuthInfo = {
    accessToken: string
    expiresAt: number
    userInfo: UserInfo
}
```

In your server component:

```tsx
// src/app/page.tsx
export default async function Home() {
    const user = await getUser()

    return (
        <main>
            <h3>Welcome {user.name}</h3>

            <div>
                <a href="/auth/logout">
                    Logout
                </a>
            </div>
        </main>
    )
}
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
    "username": "<user's username>",
    "nickname": "<user's nickname>",
  },
  "expiresAt": <unix_timestamp> # in seconds.
}
```

If the user is not authenticated, you will receive a `401` response status code.
This endpoint has to be called server-side.
