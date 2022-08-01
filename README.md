# docker-jq

A tiny ~3.5MB statically linked jq docker image (with busybox).

Supports all upstream alpine platforms:

- `linux/amd64`
- `linux/arm64`
- `linux/arm/v7`
- `linux/arm/v6`
- `linux/386`
- `linux/ppc64le`
- `linux/s390x`
- `linux/riscv64`

## Pull

### ghcr.io

```
docker pull ghcr.io/egladman/jq:1.6
```

### docker.io

```
docker pull docker.io/egladman/jq:1.6
```

## Usage

```
docker run --rm jq:1.6 jq --version
```

## Build

```
make image
```

## Acknowledgements

- https://github.com/stedolan/jq
