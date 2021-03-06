# Página pessoal

[![Build Status](https://travis-ci.org/raffaeldutra/raffaeldutra.github.io.svg?branch=develop)](https://travis-ci.org/raffaeldutra/raffaeldutra.github.io) [![pipeline status](https://gitlab.com/raffaeldutra/raffaeldutra.github.io/badges/develop/pipeline.svg)](https://gitlab.com/raffaeldutra/raffaeldutra.github.io/commits/develop)

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
docker run --rm \
-v $(pwd):/src \
-v $(pwd)/public:/src/public raffaeldutra/docker-gohugo
```

<a name="como-rodar-um-servidor"></a>
## Como rodar um servidor

Aqui é possível rodar Hugo em modo servidor

```bash
docker run -it \
-v $(pwd):/src \
-p 1313:1313 raffaeldutra/docker-gohugo /gohugo.sh -s
```

Você também pode passar a variável BASEURL.
```bash
docker run -it \
-v $(pwd):/src \
-e BASEURL=192.168.25.55 \
-p 1313:1313 raffaeldutra/docker-gohugo /gohugo.sh -s
```

## AWS Credenciais

```shell
[rafaeldutra-me]
aws_access_key_id = XXXXXX
aws_secret_access_key = YYYYYY
```

## Terraform backend

Se quiser guardar o estado do terraform em um bucket, criei primeiramente este bucket "na mão", no caso abaixo foi utilizado o nome de `terraform-rafaeldutra-me` como bucket.

Após criado o bucket, aplique uma política de acesso ao bucket/objeto, como exemplo abaixo:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::xxxxxx:root"
                ]
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::terraform-rafaeldutra-me/terraform.tfstate"
        }
    ]
}
```

## Terraform Bucket (S3)

Para saber como o `plan` do Terraform abaixo funciona, acesse o fonte do Terraform no diretório que se encontra na raíz do projeto.

Uma vez definido o nome do seu bucket, execute o `plan` e depois o aplique:

```shell
terraform plan
```

```shell
terraform apply -auto-approve
```
