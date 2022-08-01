ARG REGISTRY=docker.io/
ARG ALPINE_VERSION=3.16
ARG UID=5355
ARG NPROC=4
ARG DESTDIR=/out


FROM ${REGISTRY}alpine:${ALPINE_VERSION} AS builder

RUN set -eux; \
    apk add \
        --no-cache \
        autoconf \
        automake \
        bison \
        gcc \
        git \
        musl-dev \
        libtool \
        make \
    ;


FROM builder as jq-rootfs

ARG DESTDIR
RUN mkdir -p ${DESTDIR}/sbin


FROM builder as jq-build

ARG JQ_VERSION=1.6
ARG JQ_GIT_PREFIX=https://github.com/stedolan
ARG JQ_GIT_TAG=jq-${JQ_VERSION}
ARG DESTDIR
ARG NPROC

RUN set -eux; \
    git clone --recursive -j${NPROC} ${JQ_GIT_PREFIX}/jq src; \
    cd src; \
    git reset --hard $JQ_GIT_TAG; \
    autoreconf -fi; \
    ./configure \
      --prefix="" \
      --with-oniguruma=builtin \
      --disable-docs \
    ; \
    make -j${NPROC} LDFLAGS=-all-static; \
    make install

FROM scratch

ARG DESTDIR
ARG UID

COPY --from=jq-rootfs ${DESTDIR} /
COPY --from=jq-build ${DESTDIR}/bin/ /sbin

USER $UID

CMD ["/sbin/jq"]
