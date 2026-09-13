FROM alpine:3.20

RUN apk add --no-cache \
    ffmpeg \
    nginx \
    ttf-dejavu \
    tzdata \
    bash

ENV TZ=UTC

COPY nginx.conf /etc/nginx/nginx.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
    && mkdir -p /out

EXPOSE 80 1234/udp

ENTRYPOINT ["/entrypoint.sh"]
