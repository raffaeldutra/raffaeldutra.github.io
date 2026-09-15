+++
type = "blog"
date = "2026-08-05"
title = "Dockerfile na Prática - Camadas, Cache e Multi-Stage Builds"
slug = "dockerfile-camadas-cache-multi-stage"
tags = [ "docker", "dockerfile", "ci-cd", "devops" ]
categories = [
  "docker",
  "infrastructure",
]

draft = false
+++

No artigo anterior desta série, rodamos containers a partir de imagens prontas. Mas o valor real do Docker aparece quando você empacota a sua própria aplicação. Um `Dockerfile` mal escrito gera imagens gigantes e builds lentos; um bem escrito aproveita cache de camadas e produz imagens enxutas. A diferença está em entender como o Docker constrói uma imagem por dentro.

<!--more-->

## 1. Imagens São Feitas de Camadas

Cada instrução de um `Dockerfile` (`RUN`, `COPY`, `ADD`) cria uma nova camada, empilhada sobre a anterior. Camadas são cacheadas: se uma instrução e tudo que veio antes dela não mudaram, o Docker reaproveita o resultado em vez de executar de novo.

Isso tem uma implicação prática direta: **a ordem das instruções importa**. Coloque o que muda com menos frequência no topo do arquivo, e o que muda a cada build (como o código-fonte) por último.

## 2. Um Dockerfile Ingênuo (E Por Que Ele é Lento)

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "server.js"]
```

O problema aqui: `COPY . .` copia todo o código-fonte antes do `npm install`. Qualquer mudança em qualquer arquivo — inclusive um `README.md` — invalida o cache dessa camada e força o `npm install` a rodar de novo, baixando todas as dependências do zero.

## 3. Reordenando para Aproveitar o Cache

```dockerfile
FROM node:20-alpine
WORKDIR /app

# Copia só o necessário para instalar dependências
COPY package.json package-lock.json ./
RUN npm install --production

# Só agora copia o restante do código
COPY . .

CMD ["node", "server.js"]
```

Agora, `npm install` só roda de novo quando `package.json` ou `package-lock.json` mudam — mudanças no código da aplicação não invalidam essa camada. Em projetos com muitas dependências, essa reordenação sozinha pode derrubar o tempo de build de minutos para segundos.

## 4. O `.dockerignore`

Assim como o `.gitignore`, um `.dockerignore` evita que arquivos desnecessários entrem no contexto de build — o que acelera o envio do contexto para o daemon e evita camadas infladas por acidente:

```text
node_modules
.git
*.log
.env
dist
```

Esquecer o `.dockerignore` é uma causa comum de imagens gigantes e, pior, de segredos (`.env`) parando dentro da imagem sem querer.

## 5. Multi-Stage Builds

Um problema recorrente: a imagem final carrega ferramentas de build que não são necessárias em produção (compiladores, dependências de desenvolvimento, código-fonte não compilado). *Multi-stage builds* resolvem isso usando múltiplos `FROM` no mesmo `Dockerfile`, onde só o necessário é copiado para o estágio final:

```dockerfile
# Estágio 1: build
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

# Estágio 2: imagem final, só com o resultado do build
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
```

O estágio final não contém o Node.js, o `node_modules` nem o código-fonte — só os arquivos estáticos gerados pelo build, servidos por um Nginx enxuto. O resultado costuma ser uma redução drástica no tamanho final da imagem, além de reduzir a superfície de ataque (menos ferramentas instaladas, menos CVEs para se preocupar).

## 6. Boas Práticas Que Fazem Diferença

- **Prefira imagens `-alpine` ou `-slim`** quando a aplicação permitir — imagens base menores significam menos superfície de ataque e downloads mais rápidos.
- **Combine `RUN` relacionados em uma única instrução** quando fizer sentido, usando `&&`, para evitar camadas intermediárias desnecessárias:
  ```dockerfile
  RUN apt-get update && \
      apt-get install --yes --no-install-recommends curl && \
      rm -rf /var/lib/apt/lists/*
  ```
- **Nunca copie segredos com `COPY`** — use `--secret` do BuildKit ou variáveis de ambiente injetadas em tempo de execução, nunca embutidas na imagem.
- **Fixe versões das imagens base** (`node:20.11-alpine` em vez de `node:latest`) para builds reprodutíveis.
- **Rode como usuário não-root** sempre que possível:
  ```dockerfile
  RUN adduser --disabled-password appuser
  USER appuser
  ```

## 7. Conclusão

Entender camadas e cache transforma o `Dockerfile` de um script de instalação em uma ferramenta de build eficiente, e multi-stage builds resolvem o problema clássico de imagens de produção carregando peso desnecessário. No próximo artigo desta série, vamos sair da imagem isolada e entrar em redes e volumes — como containers conversam entre si e como persistir dados além do ciclo de vida de um container.
