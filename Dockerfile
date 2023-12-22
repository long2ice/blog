FROM klakegg/hugo:ext AS builder
COPY . /src
WORKDIR /src
RUN hugo --minify

FROM nginx:alpine
COPY --from=builder /src/public /usr/share/nginx/html
CMD ["nginx", "-g", "daemon off;"]
