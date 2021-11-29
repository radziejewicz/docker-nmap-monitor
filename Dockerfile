FROM debian:buster-slim

ENV LOG_DIR=logs

RUN apt-get update && apt-get install -y --no-install-recommends \
	bash python nmap ndiff curl ca-certificates \
    && apt-get purge -y \
	&& rm -rf /var/lib/apt/lists/* 

WORKDIR /nmap
RUN mkdir scripts $LOG_DIR
COPY ./scripts scripts/

CMD ./scripts/run_scan.sh