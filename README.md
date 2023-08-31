# WEB APP DEPLOY

The development version of a DReAM package that deploys a web app to ECS secured
with Auth0 oidc sidecar.

## Usage

```shell
dream add webapp_deploy
```

## Integration in [Remix](https://remix.run) app
- Define the following function in your app:

```ts
// app/lib/auth.ts

import { fetch, redirect } from '@remix-run/node'

export default async function authenticate(request: Request) {
  const auth = await fetch(process.env.AUTH_ENDPOINT!, {
    headers: {
      cookie: request.headers.get("Cookie") || "",
    }
  })
  if (auth.status !== 200) {
    throw redirect("/auth/login?state=" + encodeURIComponent(new URL(request.url).pathname))
  }
  return auth.json()
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
- In your loaders, use the authenticate function to authenticate requests:

```tsx
export async function loader({request}: LoaderArgs) {
  const {
    accessToken,
    userInfo: {sub: userId, email, name}
  } = await authenticate(request)

  // ...

  return json({
    //...
  })
}
```

- Add the following Error Boundary to your root component to properly handle redirects to login page:

```tsx
// app/root.tsx

// ...

export function ErrorBoundary() {
  const error = useRouteError();

  useEffect(() => {
    if(isRouteErrorResponse(error)) {
      if (error.status === 404 && error.data.includes("/auth/login")) {
        window.location.href = "/auth/login?state=" + encodeURIComponent(window.location.pathname)
      }
    }
  }, [error])

  return (
          <></>
  );
}
```

## Example usage with Next.js (App Router)

### Using companion npm package `@hereya/auth-proxy-client-next`

- Install the package:

```shell
npm install @hereya/auth-proxy-client-next
```

- Get user in a server component:

```tsx
// src/app/page.tsx
import {AuthProxyClient} from '@hereya/auth-proxy-client-next';

const proxy = new AuthProxyClient();

export default async function Home() {
    const user = await proxy.getUser()

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

- Emit authenticated requests from a server component:

```tsx
// src/app/page.tsx
import {AuthProxyClient} from '@hereya/auth-proxy-client-next';

const proxy = new AuthProxyClient();

export default async function Home() {
    const data: { result: string } = await proxy.request(
        process.env.API_URL!, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({foo: 'bar'}),
        }
    ).then(response => response.json())

    return (
        <main>
            <h3>Welcome</h3>

            <p>{data.result}</p>

            <div>
                <a href="/auth/logout">
                    Logout
                </a>
            </div>
        </main>
    )
}
```

`request` method accepts the same arguments as `fetch` and an optional
third argument which is the current page path. This is used for redirecting the
user after login if she is not connected.

### Manual integration

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
