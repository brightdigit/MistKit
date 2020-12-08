# Dockerfile
ARG TAG=latest
FROM swift:${TAG}
RUN apt-get update && apt-get install --no-install-recommends -y libsqlite3-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
