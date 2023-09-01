FROM debian:bookworm-slim

RUN apt update && apt dist-upgrade -y && apt install -y mocha node-supertest node-he

RUN mkdir /test

COPY *.test.js /test/

CMD [ "mocha", "-t", "30000", "/test/*.test.js" ]
