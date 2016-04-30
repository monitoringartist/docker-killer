FROM alpine:latest
MAINTAINER Jan Garaj info@monitoringartist.com

COPY docker-image-files /

RUN \
  chmod +x /test.sh && \
  apk --update add bash iperf gcc musl-dev && \
  gcc membomb.c -o /membomb && \
  gcc forkbomb.c -o /forkbomb && \
  apk del gcc musl-dev&& \
  rm -rf /var/cache/apk/*

EXPOSE 5001
CMD ["help"]
ENTRYPOINT ["/test.sh"]
