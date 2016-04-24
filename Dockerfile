FROM alpine:latest
MAINTAINER Jan Garaj info@monitoringartist.com

COPY docker-image-files /

RUN \
  chmod +x /test.sh && \
  apk --update add bash iperf vim gcc musl-dev && \
  gcc membomb.c -o /membomb.bin
  #apk del gcc musl-dev && \
  #rm -rf /var/cache/apk/*
  
EXPOSE 5001
CMD ["help"]
ENTRYPOINT ["/test.sh"]
