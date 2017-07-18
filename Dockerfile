FROM golang


RUN go get github.com/kardianos/govendor
RUN govendor get github.com/gohugoio/hugo
RUN go install github.com/gohugoio/hugo

COPY ./run.sh /run.sh
VOLUME /src/public

CMD ["/run.sh", "-p"]
