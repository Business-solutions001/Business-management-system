# Backend Deployment

This NestJS app is a separate backend service. Vercel will not auto-host it just because the frontend is deployed there.

## Local setup

```bash
npm install
cp .env.example .env
npm run start:dev
```

Default local API URL:

```txt
http://localhost:3001/api
```

## Required environment variables

Create `backend/.env` with:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-or-service-key
JWT_SECRET=change-this-in-production
PORT=3001
FRONTEND_URL=http://localhost:5173
```

`FRONTEND_URL` can contain multiple comma-separated URLs, for example:

```env
FRONTEND_URL=http://localhost:5173,https://your-frontend.vercel.app
```

## Deploy backend

Recommended hosts:

- Railway
- Render
- Fly.io

Typical deploy settings:

- Root Directory: `backend`
- Install Command: `npm ci`
- Build Command: `npm run build`
- Start Command: `npm run start:prod`

Environment variables to add on the backend host:

- `SUPABASE_URL`
- `SUPABASE_KEY`
- `JWT_SECRET`
- `PORT`
- `FRONTEND_URL`

## Connect frontend to backend

After the backend is deployed, copy its public API base URL into the frontend env:

```env
VITE_API_URL=https://your-backend-domain.com/api
```

Then set the same frontend domain in the backend `FRONTEND_URL` variable so browser requests pass CORS.
