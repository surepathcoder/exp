# Serve the pre-built Flutter web app with Nginx
# Build locally first: flutter build web --release --no-tree-shake-icons
FROM nginx:alpine

COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
