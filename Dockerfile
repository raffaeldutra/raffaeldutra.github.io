FROM raffaeldutra/docker-gohugo:latest

COPY . /src

CMD [ "/gohugo.sh", "-s" ]
