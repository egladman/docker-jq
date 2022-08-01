# docker-jq

A tiny ~2.5MB statically linked jq docker image with wide architecture support

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

## Acknowledgement

- https://github.com/stedolan/jq
