# syntax=docker/dockerfile:1

FROM ghcr.io/cirruslabs/flutter:stable AS flutter_builder

WORKDIR /app/eve_app
COPY eve_app/pubspec.yaml eve_app/pubspec.lock ./
RUN flutter pub get
COPY eve_app/ ./
RUN flutter build web --release --pwa-strategy=none --web-resources-cdn --no-wasm-dry-run

FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=8010

WORKDIR /app

COPY api/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

COPY api ./api
COPY knowledge ./knowledge
COPY assets ./assets
COPY --from=flutter_builder /app/eve_app/build/web ./eve_app/build/web

RUN mkdir -p storage/uploads

EXPOSE 8010

CMD ["sh", "-c", "uvicorn api.eve_core.main:app --host 0.0.0.0 --port ${PORT:-8010}"]
