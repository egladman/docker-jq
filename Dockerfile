ARG REGISTRY=docker.io/
ARG ALPINE_VERSION=edge
ARG UID=5355
ARG NPROC=
ARG DESTDIR=/out


FROM ${REGISTRY}alpine:${ALPINE_VERSION} as builder

RUN set -eux; \
    apk add \
        --no-cache \
        autoconf \
        automake \
        bison \
        busybox-static \
        gcc \
        git \
        musl-dev \
        libtool \
        make \
    ;


FROM builder as jq-rootfs

ARG DESTDIR
RUN set -eux; \
    mkdir -p \
      ${DESTDIR}/bin \
      ${DESTDIR}/sbin \
    ; \
    /bin/busybox.static --install "${DESTDIR}/bin"


FROM builder as jq-build

ARG JQ_VERSION=1.6
ARG JQ_GIT_PREFIX=https://github.com/stedolan
ARG JQ_GIT_TAG=jq-${JQ_VERSION}
ARG DESTDIR
ARG NPROC

RUN set -eux; \
    git_opts=""; \
    if [ -n "$NPROC" ]; then \
       git_opts="-j${NPROC}"; \
    fi; \
    git clone --recursive $git_opts ${JQ_GIT_PREFIX}/jq src; \
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
COPY --from=jq-build ${DESTDIR}/bin/ /bin

USER $UID

CMD ["/bin/jq"]
