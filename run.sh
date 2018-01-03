#!/usr/bin/env sh

if [ "${1}" = "-p" ]; then
    /go/bin/hugo --layoutDir /src/layouts --config /src/config.toml --themesDir /src/themes --contentDir /src/content --ignoreCache --destination /src/public

elif [ "${1}" = "-s" ]; then
    while [ true ]
    do
        /go/bin/hugo server --watch true --bind 0.0.0.0 --config /src/config.toml --layoutDir /src/layouts --themesDir /src/themes --contentDir /src/content  --ignoreCache --disableFastRender
    
        sleep 1
    done
fi
