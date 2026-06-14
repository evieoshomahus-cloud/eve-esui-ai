# Eve ESUI AI Backend

Run the backend:

```powershell
python -m uvicorn api.eve_core.main:app --host 127.0.0.1 --port 8010 --reload
```

Primary endpoints:

- `GET /api/health`
- `GET /api/users`
- `POST /api/chat`
- `POST /api/admissions/estimate`
- `GET /api/student/{user_id}/dashboard`
- `GET /api/lecturer/{user_id}/insights`

The current model mode is a local RAG orchestrator. It is intentionally deterministic for defense demonstrations, but the service boundary can later connect to OpenAI, Azure OpenAI, Gemini, Claude, or a self-hosted model.

## Optional OpenAI Responses API Mode

```powershell
$env:OPENAI_API_KEY="your_api_key_here"
$env:EVE_OPENAI_MODEL="gpt-5.4-mini"
python -m uvicorn api.eve_core.main:app --host 127.0.0.1 --port 8010 --reload
```

If `OPENAI_API_KEY` is absent, Eve uses the local fallback generator.
