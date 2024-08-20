FROM debian:bookworm-slim

RUN apt-get update && apt-get upgrade -y && apt-get install -y node-express

COPY index.js /

CMD ["node","/index.js"]
