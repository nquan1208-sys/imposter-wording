# Admin

Admin dashboard built with Vue 3 and Vite.

Environment setup and Supabase commands are documented in
[`docs/admin-supabase-environment-guide.md`](../docs/admin-supabase-environment-guide.md).

## Environments

The admin app uses Vite modes and Supabase projects as follows:

| Environment | Vite mode | Env file | Supabase target |
| --- | --- | --- | --- |
| Local | `localdev` | `.env.local` | Local Supabase CLI stack |
| Dev | `development` | `.env.development.local` | `imposter-word` cloud project |
| Prod | `production` | `.env.production.local` | Production cloud project (not configured yet) |

The `*.local` files are ignored by Git. Copy `.env.example` to create one.
`.env.production` is a tracked empty guard so a production build cannot
silently fall back to the local Supabase project.
`VITE_*` values are bundled into the browser; use only the Supabase publishable
key in this Vue app. Never use `service_role` or a Supabase secret key here.

## Development

```sh
yarn install

# Local Supabase stack
yarn dev:local

# Shared dev Supabase project
yarn dev:development
```

## Production build

```sh
# Production Supabase project
yarn build:production

# Other explicit modes
yarn build:local
yarn build:development
```
