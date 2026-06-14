# Eve Deployment Guide

Project topic: **Design and implementation of an ai system for personalized learning and academic progress tracking**.

This deployment setup hosts Eve as one web service:

- Flutter builds into static web files during deployment.
- FastAPI serves both the API routes and the Flutter web interface.
- The browser automatically calls the same hosted origin, so no ngrok URL is needed.

## Recommended Platform

Use Render with the included `Dockerfile` and `render.yaml`.

Reason: Eve combines Flutter and Python. Docker gives the host a reproducible build environment that can build Flutter first and then run FastAPI in production.

## Files Used

- `Dockerfile` builds the Flutter web app and starts the FastAPI server.
- `.dockerignore` keeps local build folders, uploads, API keys, and temporary tunnel files out of the deployment image.
- `render.yaml` defines the Render web service and prompts for the private OpenAI key.

## Deployment Steps

1. Create a private GitHub repository for the project.
2. Upload or push the project folder to the repository.
3. Confirm that `.env`, `storage/`, `.tools/`, and local tunnel files are not uploaded.
4. Open Render and create a new Blueprint from the GitHub repository.
5. When Render asks for `OPENAI_API_KEY`, paste the API key in Render's private environment variable field.
6. Keep `EVE_OPENAI_MODEL` as `gpt-5.4-mini` for the demo unless you intentionally want a more expensive model.
7. Deploy the service.
8. After deployment, test:

```text
https://your-render-service.onrender.com/api/health
https://your-render-service.onrender.com/
```

Expected health result:

```json
{
  "status": "ok",
  "service": "eve-esui-ai",
  "version": "1.0.0",
  "ai_mode": "openai_responses"
}
```

## Notes For Defense

- The OpenAI API key is not stored in the codebase. It is supplied as a private production environment variable.
- Eve can still run in local fallback mode if no API key is configured, but the hosted defense demo should use `openai_responses`.
- Runtime files such as uploaded attachments, local SQLite progress, and knowledge gap logs are demo runtime data. In a production school deployment, these should move to a managed database and persistent object storage.
