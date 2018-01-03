### To build
docker build -t raffaeldutra/gohugo .


### To publish
docker run -it -v $(pwd):/src -v $(pwd)/public:/src/public -p 1313:1313 raffaeldutra/gohugo

### To run a server
docker run -it -v $(pwd):/src -v $(pwd)/public:/src/public -p 1313:1313 raffaeldutra/gohugo /run.sh -s
