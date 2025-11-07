FROM debian:trixie-slim

RUN apt-get update && apt-get upgrade -y && apt-get install -y mocha node-supertest node-he

RUN mkdir /test && \
    useradd -u 1000 -M -s /bin/bash testuser && \
    chown testuser:testuser /test

COPY *.test.js /test/

USER testuser

CMD [ "mocha", "--exit", "-t", "30000", "/test/*.test.js" ]
