#!/bin/sh
docker run --rm -it -u $(id -u):$(id -g) --name hugo-shell -v $(pwd):/src klakegg/hugo:ext-debian shell
