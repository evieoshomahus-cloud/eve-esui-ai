# OpenAI API Integration Plan

## Decision

Eve now supports an optional OpenAI Responses API layer behind the FastAPI backend.

The Flutter app never stores or sends the OpenAI API key. The key is read only by the backend through the `OPENAI_API_KEY` environment variable or the local `.env` file.

## Runtime Modes

- `local_fallback`: Eve uses deterministic local RAG responses when no API key is configured.
- `openai_responses`: Eve uses retrieved ESUI context, authorized role context, and OpenAI to produce more natural ChatGPT-style responses.

## Local Environment Setup

Copy `.env.example` to `.env` and put the real key there:

```text
OPENAI_API_KEY=your_api_key_here
EVE_OPENAI_MODEL=gpt-5.4-mini
```

Then start the backend:

```powershell
python -m uvicorn api.eve_core.main:app --host 127.0.0.1 --port 8010 --reload
```

`EVE_OPENAI_MODEL` is optional. The backend defaults to `gpt-5.4-mini` because it balances response quality, cost, and speed for a student-facing assistant.

## Safe Response Flow

```text
User message
  -> prompt-injection screening
  -> role and identity verification
  -> student/lecturer data-scope enforcement
  -> ESUI RAG retrieval
  -> authorized private context assembly
  -> OpenAI Responses API
  -> answer with sources and model audit metadata
```

## Security Rule

Never put `OPENAI_API_KEY` in Flutter, Android resources, web files, screenshots, or the final report. It belongs only in backend environment variables, local `.env`, or a secure production secret manager.
