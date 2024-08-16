FROM debian:bookworm-slim

RUN apt-get update && apt-get upgrade -y && apt-get install -y mocha node-supertest node-he node-express

RUN mkdir /test

COPY *.test.js /test/

CMD [ "mocha", "-t", "30000", "/test/*.test.js" ]
