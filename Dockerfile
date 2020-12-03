# Dockerfile
FROM swift:5.3
RUN apt-get update
RUN apt-get install libsqlite3-dev