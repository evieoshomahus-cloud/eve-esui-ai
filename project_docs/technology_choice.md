# Technology Choice: Flutter, Not Node, for the Client

## Decision

Eve will use Flutter for the user-facing client and Python FastAPI for the AI backend.

## Why Flutter Is the Better Client Choice

Flutter is the better choice for Eve's front end because the original product vision includes a downloadable app from Google Play Store, while also needing a responsive interface for defense demonstrations and possible web deployment. Flutter allows one codebase to target Android and Web, with a consistent interface across phones, tablets, and desktop browsers.

## Why Node Is Not the Best Direct Alternative

Node.js is excellent for backend APIs and real-time services, but it is not a mobile UI framework. A Node-only system would still need a separate mobile framework such as React Native, Flutter, Kotlin, or Swift to reach Google Play. For this project, choosing Flutter avoids that split at the client layer.

## Why Python FastAPI Remains the Backend

The AI side of the system needs retrieval, guardrails, evaluation, data processing, and future model integration. Python has the strongest ecosystem for AI/ML, RAG, embeddings, model evaluation, and data science. FastAPI provides a clean REST interface that Flutter can consume.

## Final Architecture

```text
Flutter app
  -> FastAPI backend
    -> Guardrail layer
    -> RAG retrieval layer
    -> Role-based access layer
    -> Student/lecturer/admission services
    -> Future LLM provider adapter
```

## Report Wording

Flutter was selected for the client application because it supports cross-platform mobile and web development from one codebase, which aligns with the proposed deployment of Eve as a Play Store application and a responsive university support platform. Node.js was considered, but it is primarily a backend runtime rather than a complete mobile UI framework. Python FastAPI was selected for the backend because Python provides mature AI, machine learning, retrieval, and data-processing libraries required for Retrieval-Augmented Generation and guardrail evaluation.

