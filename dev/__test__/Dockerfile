FROM debian:bullseye-slim

RUN apt update && apt dist-upgrade -y && apt install -y mocha node-supertest node-he

RUN mkdir /test

COPY *.test.js /test/

CMD [ "mocha", "/test/*.test.js" ]
