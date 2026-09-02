#!/usr/bin/env sh
# Rafael Dutra <raffaeldutra@gmail.com> — http://rafaeldutra.me
#
# Atalho para rodar o Hugo dentro do container hugomods/hugo.
#   ./gohugo.sh -s   -> servidor com live-reload em http://localhost:1313
#   ./gohugo.sh -p   -> build estático em ./public
set -e

IMAGE="${HUGO_IMAGE:-hugomods/hugo:latest}"
RUN="docker run --rm -v $(pwd):/src -w /src"

case "${1:--s}" in
  -p)
    $RUN "$IMAGE" sh -c "hugo mod get github.com/zetxek/adritian-free-hugo-theme && hugo mod npm pack && npm install && hugo --gc --minify"
    ;;
  -s)
    $RUN -p 1313:1313 "$IMAGE" sh -c "hugo mod get github.com/zetxek/adritian-free-hugo-theme && hugo mod npm pack && npm install && hugo server --bind 0.0.0.0 --baseURL http://localhost:1313"
    ;;
  *)
    echo "uso: $0 [-s|-p]" >&2
    exit 1
    ;;
esac
