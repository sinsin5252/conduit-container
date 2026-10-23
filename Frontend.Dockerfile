# Builder
FROM node:24.21-alpine AS builder

WORKDIR /frontend

COPY conduit-frontend/package*.json .
RUN npm ci

COPY conduit-frontend .

RUN npm install -g @angular/cli && npm run build

# Runner
FROM nginx:1.31-alpine AS runner

RUN rm /etc/nginx/conf.d/default.conf
COPY angular.conf /etc/nginx/conf.d/
COPY --from=builder /frontend/dist/angular-conduit /usr/share/nginx/html/

EXPOSE 80
