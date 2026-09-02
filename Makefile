# Atalhos para subir a stack local do site (Hugo + Docker).
# Rode `make` ou `make help` para ver os alvos disponíveis.

COMPOSE     ?= docker compose
HUGO_IMAGE  ?= hugomods/hugo:latest
export HUGO_IMAGE

.DEFAULT_GOAL := help
.PHONY: help up serve down restart logs shell ps pull deps build preview clean

help: ## Mostra esta ajuda
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

up: ## Sobe o servidor Hugo com live-reload em http://localhost:1313
	$(COMPOSE) up server

serve: up ## Apelido para `make up`

down: ## Derruba a stack e remove os containers
	$(COMPOSE) --profile build --profile preview down

restart: ## Reinicia o servidor Hugo
	$(COMPOSE) restart server

logs: ## Acompanha os logs do servidor Hugo
	$(COMPOSE) logs -f server

shell: ## Abre um shell dentro do container do servidor
	$(COMPOSE) exec server sh

ps: ## Lista os containers da stack
	$(COMPOSE) ps

pull: ## Baixa/atualiza a imagem do Hugo
	$(COMPOSE) pull

deps: ## Baixa o tema (Hugo Module) e instala as dependências npm
	$(COMPOSE) run --rm build sh -c "hugo mod get github.com/zetxek/adritian-free-hugo-theme && hugo mod npm pack && npm install"

build: ## Gera o site estático em ./public
	$(COMPOSE) run --rm build

preview: build ## Faz o build e serve ./public via nginx em http://localhost:8080
	$(COMPOSE) up nginx

clean: ## Remove artefatos de build (public/ e resources/)
	docker run --rm -v "$(CURDIR)":/src alpine rm -rf /src/public /src/resources
