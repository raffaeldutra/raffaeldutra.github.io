# Página pessoal

![!](https://img.shields.io/travis/raffaeldutra/raffaeldutra.github.io.svg) ![!](https://img.shields.io/travis/raffaeldutra/raffaeldutra.github.io/develop.svg)

Olá, se alguma coisa no meu site te interessou, como o modelo do meu currículo, páginas e etc, sinta-se a vontade para clonar este repositório e adaptar para suas necessidadaes.  

Utilizei apenas Docker e GoHugo para criar este blog/página e abaixo deixo instuções de como rodar a página em sua máquina local.

O deploy fica por sua conta. Eu utilizei o próprio Github pages para hospedagem e um domínio comprado no GoDaddy.

## Sumário

- [Docker](#docker)
    - [TL;DR (Too Long, Didn't Read)](#tldr-too-long-didnt-read)
    - [Como obter Docker?](#como-obter-docker)
    - [Como criar uma imagem](#como-criar-uma-imagem)
    - [Como publicar o site](#como-publicar-o-site)
    - [Como rodar um servidor](#como-rodar-um-servidor)

## TL;DR (Too Long, Didn't Read)

Baixe Docker com o comando mágico (funciona somente em Sistemas Operacionais). Windows, sorry :-)

```bash
curl -fsSL https://get.docker.com/ | sh
```

<a name="como-obter-docker"></a>
## Como obter Docker?

- [Link para documentação oficial](https://docs.docker.com/install/)
    - [Instalando em Windows](https://docs.docker.com/docker-for-windows/install/)
    - [Instalando em Debian](https://docs.docker.com/install/linux/docker-ce/debian/)
    - [Instalando em Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
    - [Instalando em MacOS](https://docs.docker.com/docker-for-mac/install/)

<a name="como-criar-imagem"></a>
## Imagem utilizada

O projeto da imagem se encontra aqui com sua devida documentação: [https://github.com/raffaeldutra/docker-gohugo](https://github.com/raffaeldutra/docker-gohugo).

Esta imagem tem build com trigger automática diretamente do Github. Atente para a tag que deseja utilizar.

<a name="como-publicar-site"></a>
## Como publicar o site

Publicação de código, ou seja, transforma todos os arquivos.md para HTML

```bash
docker run -it \
-v $(pwd):/src \
-v $(pwd)/public:/src/public raffaeldutra/docker-gohugo
```

<a name="como-rodar-um-servidor"></a>
## Como rodar um servidor

Aqui é possível rodar Hugo em modo servidor

```bash
docker run -it \
-v $(pwd):/src \
-v $(pwd)/public:/src/public \
-p 1313:1313 raffaeldutra/docker-gohugo /gohugo.sh -s
```
