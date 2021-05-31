#!/bin/sh
docker run --rm -it -u $(id -u):$(id -g) --name hugo-server -v $(pwd):/src -p 1313:1313 klakegg/hugo:ext-debian server
