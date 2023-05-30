FROM rust:1-alpine3.17 AS builder

RUN apk add --no-cache openssl libc-dev openssl-dev protobuf protobuf-dev

RUN mkdir -p /opt/aode-relay
WORKDIR /opt/aode-relay

ADD . /opt/aode-relay

RUN cargo build --release


FROM alpine:3.17

RUN apk add --no-cache openssl ca-certificates tini

ENTRYPOINT ["/sbin/tini", "--"]

COPY --from=builder /opt/aode-relay/target/release/relay /usr/bin/aode-relay

# Some base env configuration
ENV HOSTNAME relay.wansaw.com
ENV ADDR 0.0.0.0
ENV PORT 8080
ENV DEBUG true
ENV VALIDATE_SIGNATURES true
ENV HTTPS true
ENV PRETTY_LOG true
ENV PUBLISH_BLOCKS true
ENV SLED_PATH /opt/aode-relay/sled/db-0.34
ENV RUST_LOG debug
ENV RESTRICTED_MODE true
ENV LOCAL_DOMAINS wansaw.com
ENV TELEGRAM_TOKEN 5820884837:AAHfAXMz58JsHZL5MMKNTuqPTosXNB8gddo
ENV TELEGRAM_ADMIN_HANDLE amigr8
ENV FOOTER_BLURB <b>Footer Goes Here</b>
ENV LOCAL_BLURB <p>NEW Welcome to my cool relay where I have cool relay things happening. I hope you enjoy your stay</p>
# Since this container is intended to run behind reverse proxy
# we don't need HTTPS in here.
#ENV HTTPS false

CMD ["/usr/bin/aode-relay"]
