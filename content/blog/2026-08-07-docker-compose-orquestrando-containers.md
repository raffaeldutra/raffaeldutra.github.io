+++
type = "blog"
date = "2026-08-07"
title = "Docker Compose - Orquestrando Múltiplos Containers"
slug = "docker-compose-orquestrando-containers"
tags = [ "docker", "docker-compose", "devops", "ci-cd" ]
categories = [
  "docker",
  "infrastructure",
]

draft = false
+++

Nos artigos anteriores desta série, subimos containers, criamos redes e volumes manualmente, um comando `docker run` de cada vez. Funciona, mas não escala: numa aplicação real com banco de dados, cache, API e worker, decorar (ou repetir) todos aqueles comandos vira um problema. O Docker Compose resolve isso descrevendo toda a stack num único arquivo declarativo.

<!--more-->

## 1. De Comandos Soltos para Um Arquivo Declarativo

Tudo que vimos até aqui — `--network`, `--volume`, `--publish`, `--env` — tem um equivalente direto no Compose, só que declarado em YAML e versionado junto com o código. Em vez de lembrar (ou documentar à parte) a sequência exata de comandos para subir o ambiente, qualquer pessoa do time roda `docker compose up` e tem tudo funcionando.

## 2. Um `compose.yaml` Básico

Vamos recriar a stack API + Postgres do artigo anterior, agora como Compose:

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: exemplo
    volumes:
      - dados-postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 5

  api:
    build: .
    environment:
      DATABASE_HOST: postgres
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  dados-postgres:
```

Repare no que o Compose já resolve para você:

- **Rede:** por padrão, o Compose cria uma rede exclusiva para o projeto e conecta todos os serviços nela — o `api` já enxerga `postgres` pelo nome, sem precisar criar rede manualmente.
- **Volumes nomeados:** declarados uma vez em `volumes:`, referenciados pelo nome nos serviços.
- **`build: .`** diz para o Compose construir a imagem a partir do `Dockerfile` no diretório atual, em vez de puxar de um registry.

## 3. `depends_on` com Healthcheck

Um erro comum é achar que `depends_on` espera o serviço "estar pronto". Sem `condition`, ele só espera o **container iniciar**, não que a aplicação dentro dele esteja de fato aceitando conexões — o Postgres pode ainda estar inicializando quando a API já tenta se conectar.

O bloco `healthcheck` no serviço `postgres`, combinado com `condition: service_healthy` no `depends_on` da `api`, resolve isso: o Compose só sobe a `api` depois que o healthcheck do Postgres reportar sucesso.

## 4. Comandos do Dia a Dia

```bash
# Sobe todos os serviços em background
docker compose up --detach

# Mostra o status dos serviços
docker compose ps

# Acompanha os logs de todos os serviços (ou de um específico)
docker compose logs --follow
docker compose logs --follow api

# Reconstrói a imagem de um serviço após mudanças no Dockerfile
docker compose build api

# Para e remove containers, rede e (opcionalmente) volumes
docker compose down
docker compose down --volumes
```

`docker compose down --volumes` remove também os volumes nomeados — útil para começar do zero em desenvolvimento, perigoso se usado sem pensar num ambiente com dados reais.

## 5. Variando Configuração por Ambiente

Uma prática comum é manter um `compose.yaml` base e um `compose.override.yaml` (carregado automaticamente pelo Compose) só com o que muda em desenvolvimento:

```yaml
# compose.override.yaml
services:
  api:
    volumes:
      - ./src:/app/src
    environment:
      DEBUG: "true"
```

Em produção, você ignora o override (`docker compose --file compose.yaml up`) ou usa um arquivo de produção explícito. Isso evita duplicar a definição inteira do serviço só para trocar duas ou três configurações entre ambientes.

## 6. Profiles: Serviços Opcionais

Nem todo serviço precisa subir sempre. `profiles` permite marcar serviços como opcionais, ativados só quando necessário — por exemplo, uma ferramenta de administração do banco que só faz sentido em desenvolvimento:

```yaml
services:
  pgadmin:
    image: dpage/pgadmin4
    profiles: ["debug"]
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@exemplo.com
      PGADMIN_DEFAULT_PASSWORD: admin
```

```bash
# Sobe só os serviços padrão (sem o pgadmin)
docker compose up --detach

# Sobe incluindo os serviços do profile "debug"
docker compose --profile debug up --detach
```

## 7. Conclusão da Série

Ao longo destes quatro artigos, saímos de `docker run hello-world` até uma stack multi-serviço orquestrada por um único `compose.yaml`, passando por Dockerfiles otimizados com cache e multi-stage builds, e por redes e volumes explicados de forma que fazem sentido na prática. Esse é o conjunto mínimo de conhecimento que separa "sei rodar um container" de "sei containerizar uma aplicação real" — e é a base sobre a qual ferramentas de orquestração maiores, como Kubernetes, constroem seus próprios conceitos.
