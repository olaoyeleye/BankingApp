FROM postgres:15

ENV POSTGRES_DB=bankingdb
ENV POSTGRES_USER=bankuser
ENV POSTGRES_PASSWORD=bankpass

COPY init.sql /docker-entrypoint-initdb.d/init.sql