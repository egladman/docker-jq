# docker-jq

A tiny ~2.5MB* statically linked jq docker image. Since jq only supports writing
to stdout a separate image tag is provided that comes packaged alongside
[busybox](https://busybox.net/).

*\* The busybox image variant adds an additional ~1MB to the image size.*

Supports *all* upstream [alpine](https://www.alpinelinux.org/) docker platforms:

- `linux/amd64`
- `linux/arm64`
- `linux/arm/v7`
- `linux/arm/v6`
- `linux/386`
- `linux/ppc64le`
- `linux/s390x`
- `linux/riscv64`

## Why

This is a purpose-built image that works great as a [Kubernetes](https://kubernetes.io/) init container.

## Pull

### [ghcr.io](https://github.com/egladman/docker-jq/pkgs/container/jq)

```
docker pull ghcr.io/egladman/jq:1.6
docker pull ghcr.io/egladman/jq:1.6-busybox
```

### [docker.io](https://hub.docker.com/r/egladman/jq)

```
docker pull docker.io/egladman/jq:1.6
docker pull docker.io/egladman/jq:1.6-busybox
```

## Usage

```
docker run --rm jq:1.6 jq --version
```

## Build

```
make image
make image IMG_VARIANT=busybox
```

## Acknowledgements

- https://github.com/stedolan/jq
