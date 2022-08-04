ARG REGISTRY=docker.io/
ARG ALPINE_VERSION=edge
ARG UID=5355
ARG NPROC=
ARG DESTDIR=/out
ARG VARIANT=core

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


FROM builder as core-addon

ARG DESTDIR
RUN set -eux; \
    mkdir -p ${DESTDIR}


FROM builder as busybox-addon

ARG DESTDIR
RUN set -eux; \
    mkdir -p ${DESTDIR}/bin; \
    /bin/busybox.static --install "${DESTDIR}/bin"


FROM ${VARIANT}-addon as selected-addon


FROM builder as runtime-rootfs

ARG DESTDIR
RUN set -eux; \
    mkdir -p ${DESTDIR}/bin


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
    if [ $(echo $JQ_VERSION | awk '{split($0,a,"."); print a[3]}') = '0' ]; then \
       # The upstream project tags their releases in a wierd way :(
       JQ_GIT_TAG=jq-$(echo $JQ_VERSION | awk '{split($0,a,"."); print a[1]"."a[2]}'); \
    fi; \
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

COPY --from=runtime-rootfs ${DESTDIR}/ /
COPY --from=jq-build ${DESTDIR}/bin/ /bin
COPY --from=selected-addon ${DESTDIR}/ /

USER $UID

CMD ["/bin/jq"]
