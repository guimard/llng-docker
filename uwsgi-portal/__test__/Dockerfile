FROM debian:bookworm-slim

RUN apt-get update && apt-get upgrade -y && apt-get install -y mocha node-supertest node-he

RUN mkdir /test

COPY *.test.js /test/

CMD [ "mocha", "--exit", "-t", "30000", "/test/*.test.js" ]
