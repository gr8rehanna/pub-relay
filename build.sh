#!/usr/bin//env bash

DEFAULT_TAG=master
DEFAULT_REPOSITORY=https://git.asonix.dog/asonix/ap-relay

BUILD_DATE=$(date)
VERSION=$1
TAG=${2:-$DEFAULT_TAG}
GIT_REPOSITORY=${3:-$DEFAULT_REPOSITORY}

function require() {
    if [ "$1" = "" ]; then
        echo "input '$2' required"
        print_help
        exit 1
    fi
}

function print_help() {
    echo "build.sh"
    echo ""
    echo "Usage:"
    echo "	build.sh [version] [tag] [repository]"
    echo ""
    echo "Args:"
    echo "	version: The version of the current container"
    echo "	tag: The tag or branch of the relay to include (optional, defaults to asonix/downstream)"
    echo "	repository: The git repository to fetch the relay from (optional, defaults to https://git.asonix.dog/asonix/ap-relay)"
}

function build_image() {
    IMAGE=$1
    ARCH=$2

    docker build \
        --pull \
        --no-cache \
        --build-arg BUILD_DATE="${BUILD_DATE}" \
        --build-arg TAG="${TAG}" \
        --build-arg VERSION="${VERSION}" \
        --build-arg GIT_REPOSITORY="${GIT_REPOSITORY}" \
        -f "Dockerfile.${ARCH}" \
        -t "${IMAGE}:$(echo ${TAG} | sed 's/\//-/g')-${VERSION}-${ARCH}" \
        -t "${IMAGE}:latest-${ARCH}" \
        -t "${IMAGE}:latest" \
        .

    docker push "${IMAGE}:$(echo ${TAG} | sed 's/\//-/g')-${VERSION}-${ARCH}"
    docker push "${IMAGE}:latest-${ARCH}"
    docker push "${IMAGE}:latest"
}

require "$VERSION" "version"

set -xe

build_image asonix/relay arm64v8
