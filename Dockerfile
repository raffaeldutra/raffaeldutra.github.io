# Ambiente de desenvolvimento local do site (Hugo extended + Go + Node).
# Uso:
#   docker build -t rd-site .
#   docker run --rm -p 1313:1313 -v "$PWD":/src rd-site
FROM hugomods/hugo:latest

WORKDIR /src
COPY . /src

# Baixa o tema (Hugo Module) e instala as dependências de build (Bootstrap, etc.)
RUN hugo mod get github.com/zetxek/adritian-free-hugo-theme \
 && hugo mod npm pack \
 && npm install

EXPOSE 1313
CMD ["hugo", "server", "--bind", "0.0.0.0", "--baseURL", "http://localhost:1313"]
