FROM asonix/diesel-cli:v1.4.0-r0-arm64v8 AS diesel

FROM arm64v8/rust:1.42.0-buster AS builder


# Set up git remote
ARG TAG
ARG GIT_REPOSITORY
ARG BUILD_DATE

RUN git clone -b master https://git.asonix.dog/asonix/ap-relay /opt/relay
WORKDIR /opt/relay
RUN cargo install --path .

FROM arm64v8/ubuntu:20.04
#FROM ubuntu:20.04

RUN apt-get update && apt install -y libpq5 git cargo

ARG UID=991
ARG GID=991


RUN \
 mkdir -p /opt/relay && \
 addgroup --gid "${GID}" relay && \
 adduser \
    --disabled-password \
    --gecos "" \
    --ingroup relay \
    --uid "${UID}" \
    relay

COPY --from=diesel /usr/local/bin/diesel /usr/local/bin/diesel
COPY --from=builder /usr/local/cargo/bin/relay /usr/local/bin/relay
COPY --from=builder /opt/relay/migrations /opt/relay/migrations

RUN chown -R relay:relay /opt/relay

USER relay
WORKDIR /opt/relay

EXPOSE 8080

CMD ["relay"]
