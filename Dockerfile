FROM rust AS builder

RUN apt update && apt install -y git rustc cargo clang llvm pkg-config nettle-dev libpcsclite-dev sqop

RUN cargo install rsop
RUN git clone --depth 1 https://gitlab.com/sequoia-pgp/openpgp-interoperability-test-suite /app

COPY config.json /app/config.json
WORKDIR /app

RUN echo $PATH
RUN cargo run -- --html-out results.html

FROM scratch AS html
COPY --from=builder /app/results.html /index.html

FROM alpine AS server

ENV \
    # Show full backtraces for crashes.
    RUST_BACKTRACE=full
RUN apk add --no-cache \
      tini busybox-extras \
    && rm -rf /var/cache/* \
    && mkdir /var/cache/apk

RUN adduser -D static
USER static
WORKDIR /home/static

COPY --from=builder /app/results.html index.html

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["busybox-extras", "httpd", "-f", "-v", "-p", "8080"]

EXPOSE 8080
