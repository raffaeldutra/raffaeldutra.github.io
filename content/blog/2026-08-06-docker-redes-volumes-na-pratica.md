+++
type = "blog"
date = "2026-08-06"
title = "Docker - Redes e Volumes na Prática"
slug = "docker-redes-volumes-na-pratica"
tags = [ "docker", "networking", "storage", "devops" ]
categories = [
  "docker",
  "infrastructure",
]

draft = false
+++

Uma aplicação real raramente vive sozinha num único container: ela precisa falar com um banco de dados, com um cache, com outros serviços — e precisa que certos dados sobrevivam a um restart. Redes e volumes são as peças do Docker que resolvem exatamente isso, e são também as que mais geram confusão em quem está começando.

<!--more-->

## 1. Por Que o Container "Esquece" Tudo

Por padrão, tudo que um container escreve no seu próprio sistema de arquivos vive na camada gravável daquele container. Quando o container é removido (`docker rm`), essa camada some junto — inclusive dados de um banco de dados que estava rodando ali dentro. Isso não é um bug, é o comportamento esperado: containers são pensados para ser descartáveis.

Para dados que precisam sobreviver, existem **volumes**.

## 2. Volumes: Named Volumes vs. Bind Mounts

Existem duas formas principais de persistir dados fora da camada gravável do container:

### Named Volumes

Gerenciados pelo próprio Docker, vivem num local controlado por ele (normalmente em `/var/lib/docker/volumes`), sem você precisar saber o caminho exato:

```bash
# Cria um volume nomeado
docker volume create dados-postgres

# Usa o volume ao subir o container
docker run \
  --detach \
  --name postgres \
  --volume dados-postgres:/var/lib/postgresql/data \
  --env POSTGRES_PASSWORD=exemplo \
  postgres:16-alpine
```

Mesmo removendo o container (`docker rm -f postgres`) e criando outro apontando para o mesmo volume, os dados continuam lá.

### Bind Mounts

Apontam diretamente para um caminho do sistema de arquivos do host — úteis principalmente em desenvolvimento, para refletir mudanças de código em tempo real dentro do container:

```bash
docker run \
  --detach \
  --name app-dev \
  --volume $(pwd)/src:/app/src \
  --publish 3000:3000 \
  node:20-alpine \
  node /app/src/server.js
```

Qualquer alteração salva em `./src` na máquina host aparece instantaneamente dentro do container — não é preciso rebuildar a imagem a cada mudança.

**Regra prática:** named volumes para dados que o Docker deve gerenciar (bancos de dados, filas), bind mounts para desenvolvimento local e para expor configuração/código do host.

## 3. Redes: Como Containers Se Encontram

Ao instalar o Docker, uma rede chamada `bridge` já existe por padrão, mas containers nela só se enxergam por IP — nada muito prático. A solução é criar redes próprias:

```bash
docker network create minha-app
```

Containers na mesma rede customizada se resolvem **pelo nome do container**, via DNS interno do Docker:

```bash
docker run \
  --detach \
  --name postgres \
  --network minha-app \
  --volume dados-postgres:/var/lib/postgresql/data \
  --env POSTGRES_PASSWORD=exemplo \
  postgres:16-alpine

docker run \
  --detach \
  --name api \
  --network minha-app \
  --publish 8080:8080 \
  --env DATABASE_HOST=postgres \
  minha-api:latest
```

Dentro do container `api`, o host `postgres` resolve automaticamente para o IP correto do container do banco — sem precisar descobrir ou fixar IPs manualmente. É esse mecanismo de DNS interno que torna prático conectar múltiplos containers entre si.

## 4. Publicando Portas vs. Comunicação Interna

Vale separar dois conceitos que se confundem:

- **`--publish` (ou `-p`)** expõe uma porta do container para fora do host — necessário quando algo de fora da máquina (um navegador, outro serviço) precisa acessar o container.
- **Comunicação entre containers na mesma rede** não precisa de `--publish` nenhum: o container `api` acessa `postgres:5432` diretamente pela rede interna, mesmo sem essa porta estar publicada para o host.

Publicar portas desnecessariamente aumenta a superfície exposta da máquina — normalmente só o serviço "de borda" (o proxy reverso, ou a própria API) precisa de uma porta publicada.

## 5. Inspecionando o Que Está Rodando

Alguns comandos úteis para depurar rede e volumes:

```bash
# Lista redes existentes
docker network ls

# Detalhes de uma rede, incluindo containers conectados
docker network inspect minha-app

# Lista volumes
docker volume ls

# Detalhes de um volume, incluindo o caminho real no host
docker volume inspect dados-postgres
```

## 6. Conclusão

Redes customizadas resolvem a comunicação entre containers de forma simples e legível (por nome, não por IP), e volumes resolvem o problema de dados que precisam sobreviver além do ciclo de vida de um container específico. No próximo e último artigo desta série, vamos parar de subir containers um por um manualmente e usar o Docker Compose para orquestrar tudo isso — rede, volumes e múltiplos serviços — a partir de um único arquivo.
