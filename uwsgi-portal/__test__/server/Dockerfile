FROM debian:trixie-slim

RUN apt-get update && apt-get upgrade -y && apt-get install -y node-express

RUN useradd -u 1000 -M -s /bin/bash testuser

COPY index.js /

USER testuser

CMD ["node","/index.js"]
