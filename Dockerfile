# ====== STAGE 1: build ======
FROM python:3.12-alpine AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /build
COPY app/requirements.txt .
RUN apk add --no-cache build-base \
 && pip install --no-cache-dir --prefix=/install -r requirements.txt

# ====== STAGE 2: runtime ======
FROM python:3.12-alpine

# Usuario no root
RUN addgroup -S appgrp && adduser -S appuser -G appgrp
WORKDIR /app

# Dependencias desde el builder
COPY --from=builder /install /usr/local
# Código
COPY app/ /app/

EXPOSE 8080

# Healthcheck: si falla, exit 1 -> orquestador puede reiniciar
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD wget -qO- http://127.0.0.1:8080/health || exit 1

USER appuser
CMD ["gunicorn", "-b", "0.0.0.0:8080", "main:app"]
