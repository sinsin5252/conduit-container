FROM python:3.5.2-alpine

WORKDIR /backend

RUN apk add --no-cache \
    postgresql-dev \
    gcc \
    musl-dev

COPY conduit-backend .
COPY entrypoint-backend.sh .

RUN  pip install -r requirements.txt && \
    chmod +x entrypoint-backend.sh

EXPOSE 8000

ENTRYPOINT ["./entrypoint-backend.sh"]