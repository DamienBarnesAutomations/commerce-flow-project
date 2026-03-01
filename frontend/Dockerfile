# Stage 1: Build
FROM node:20-alpine AS build-stage
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Declare each ARG so Vite can see them during build
ARG VITE_API_BASE_URL
ARG VITE_IMAGE_BASE_URL
ARG VITE_GET_PRODUCTS_WEBHOOK
ARG VITE_RECORD_SALES_WEBHOOK
ARG VITE_DAILY_SALES_WEBHOOK
ARG VITE_APP_TITLE
ARG VITE_APP_ICON
ARG VITE_LOGO
ARG VITE_CURRENCY

RUN npm run build


# Stage 2: Serve
FROM nginx:alpine
COPY --from=build-stage /app/dist /usr/share/nginx/html/pos
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]