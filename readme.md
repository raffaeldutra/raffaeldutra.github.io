# Página pessoal — rafaeldutra.me

Site pessoal / currículo construído com [Hugo](https://gohugo.io) e o tema
[Adritian](https://github.com/zetxek/adritian-free-hugo-theme) (instalado como
Hugo Module).

Sinta-se à vontade para clonar e adaptar às suas necessidades. O deploy fica por
sua conta — aqui é usado GitHub Pages (branch `master`) com domínio próprio.

## Requisitos

- **Hugo extended ≥ 0.158** e **Node 20+** — ou apenas **Docker**.

## Rodar localmente

### Com Docker (sem instalar nada)

```bash
make up            # servidor com live-reload em http://localhost:1313
make build         # gera o site estático em ./public
make preview       # build + nginx servindo ./public em http://localhost:8080
```

Ou diretamente:

```bash
docker run --rm -p 1313:1313 -v "$PWD":/src -w /src hugomods/hugo:latest \
  sh -c "hugo mod get github.com/zetxek/adritian-free-hugo-theme && hugo mod npm pack && npm install && hugo server --bind 0.0.0.0"
```

### Com Hugo + Node instalados

```bash
hugo mod get github.com/zetxek/adritian-free-hugo-theme
hugo mod npm pack
npm install
hugo server            # http://localhost:1313
hugo --gc --minify     # build de produção em ./public
```

## Estrutura de conteúdo

| Caminho | O quê |
|---|---|
| `content/home/` | Seções da home (shortcodes do tema) |
| `content/footer/` | Formulário de contato do rodapé |
| `content/experience/` | Um arquivo por cargo (`jobTitle`, `company`, `duration`, …) |
| `content/education/` | Formação (`university`, `year`, `degree`) |
| `content/skills/_index.md` | Skills técnicas (`skill_categories`) |
| `content/cv/` | Currículo para impressão + downloads e ementas de cursos |
| `content/blog/` | Posts |
| `content/presentations/` | Palestras |
| `hugo.toml` | Configuração (idiomas pt-br/en, menus, params do tema) |
| `data/homepage.yml` | Overrides opcionais das seções da home |
| `i18n/pt-br.yaml`, `i18n/en.yaml` | Strings da interface |

## Deploy

Push na branch `develop` dispara `.github/workflows/github-deploy.yml`, que
builda com Hugo extended + npm e publica `public/` na branch `master`
(GitHub Pages). O domínio vem de `static/CNAME`.
