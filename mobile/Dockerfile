# Stage 1: Build the Flutter web application
FROM runatlantis/atlantis:latest AS build
# Note: typically we use a flutter image, but since we don't have an official one that's universally small, we use a community one or install flutter.
# For simplicity, let's use ghcr.io/cirruslabs/flutter:3.16.5
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release --no-tree-shake-icons


# Stage 2: Serve the application with Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
