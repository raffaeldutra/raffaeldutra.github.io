+++
type = "blog"
date = "2026-08-04"
title = "Docker - Containers, Imagens e Primeiros Passos"
slug = "docker-containers-imagens-primeiros-passos"
tags = [ "docker", "containers", "infraestructure", "devops" ]
categories = [
  "docker",
  "infrastructure",
]

draft = false
+++

"Funciona na minha máquina" é provavelmente a frase mais repetida — e mais frustrante — em qualquer time de desenvolvimento. O Docker não resolve todo problema de infraestrutura, mas resolve muito bem esse: empacotar uma aplicação com tudo que ela precisa para rodar, de um jeito que se comporta igual em qualquer lugar.

<!--more-->

## 1. Container Não É Máquina Virtual

É comum comparar containers com máquinas virtuais, mas a diferença é fundamental. Uma VM virtualiza hardware inteiro e roda um sistema operacional completo por cima de um hypervisor. Um container compartilha o kernel do sistema operacional host e isola apenas processos, rede e sistema de arquivos — usando recursos do próprio Linux como *namespaces* (isolamento de visão: PIDs, rede, filesystem) e *cgroups* (limites de uso de CPU, memória, etc.).

Na prática, isso significa:

- **Containers sobem em milissegundos**, não minutos — não há um SO inteiro para inicializar.
- **Menor overhead:** dezenas de containers podem rodar na mesma máquina onde caberiam poucas VMs.
- **Isolamento é mais fraco que o de uma VM:** containers compartilham o kernel do host, então o modelo de segurança é diferente (e vale entender isso antes de rodar workloads não confiáveis lado a lado).

## 2. Imagem vs. Container

Dois termos que se confundem no início:

- **Imagem:** um pacote read-only com tudo que a aplicação precisa — binários, bibliotecas, código, configuração padrão. É construída a partir de um `Dockerfile` e fica armazenada em camadas.
- **Container:** uma instância em execução de uma imagem, com uma camada gravável por cima. Você pode criar vários containers a partir da mesma imagem, cada um com seu próprio estado em tempo de execução.

Pense na imagem como a "planta" e o container como a "casa construída" — você pode construir quantas casas quiser a partir da mesma planta.

## 3. Instalando e Testando

Com o Docker instalado ([docs.docker.com/get-docker](https://docs.docker.com/get-started/get-docker/)), confirme que está tudo certo:

```bash
docker version
docker run hello-world
```

O comando `docker run hello-world` baixa uma imagem mínima, cria um container a partir dela, executa e mostra uma mensagem de confirmação — um bom teste de fumaça pra saber se o daemon do Docker está respondendo corretamente.

## 4. Comandos do Dia a Dia

Subindo um servidor Nginx e explorando os comandos básicos:

```bash
# Sobe um container Nginx em background, publicando a porta 8080
docker run --detach --name meu-nginx --publish 8080:80 nginx:alpine

# Lista containers em execução
docker ps

# Mostra os logs do container
docker logs meu-nginx

# Abre um shell dentro do container em execução
docker exec -it meu-nginx sh

# Para o container (ele continua existindo, só não está rodando)
docker stop meu-nginx

# Remove o container definitivamente
docker rm meu-nginx
```

Alguns detalhes que ajudam a entender o que está acontecendo:

- `--detach` (ou `-d`) roda o container em background, devolvendo o terminal.
- `--publish 8080:80` (ou `-p`) mapeia a porta 8080 do host para a porta 80 dentro do container — sem isso, o serviço fica acessível só de dentro do container.
- `docker ps -a` (com `-a`) mostra containers parados também, não só os em execução.
- `docker stop` envia um sinal de término gracioso; `docker rm` de fato apaga o container e sua camada gravável.

## 5. Imagens: De Onde Vêm e Onde Ficam

Imagens vêm de um *registry* — o mais comum é o [Docker Hub](https://hub.docker.com/), mas empresas normalmente rodam um registry privado (ECR, GCR, Harbor, GitLab Registry). Comandos úteis:

```bash
# Lista imagens baixadas localmente
docker images

# Baixa uma imagem sem rodar container
docker pull postgres:16-alpine

# Remove uma imagem não utilizada
docker rmi postgres:16-alpine
```

Prefira sempre imagens com uma tag específica (`postgres:16-alpine`) em vez de `latest`. A tag `latest` muda de conteúdo ao longo do tempo, o que torna builds difíceis de reproduzir — o mesmo `docker pull postgres:latest` pode trazer versões diferentes em momentos diferentes.

## 6. Conclusão

Entender a diferença entre imagem e container, e dominar os comandos básicos de ciclo de vida (`run`, `ps`, `logs`, `exec`, `stop`, `rm`), já é o suficiente para explorar aplicações containerizadas no dia a dia. No próximo artigo desta série, vamos escrever nossos próprios `Dockerfile`s e entender como o cache de camadas afeta — para melhor ou para pior — o tempo de build.
