FROM alpine:3.15.0

ENV LOG_DIR=logs

RUN apk add --update-cache bash python3 nmap curl \
    && rm -rf /var/cache/apk/*    

WORKDIR /nmap
RUN mkdir scripts $LOG_DIR
COPY ./scripts scripts/

CMD ./scripts/run_scan.sh