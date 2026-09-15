+++
type = "blog"
date = "2026-09-15"
title = "Grafana Avançado - Dashboards como Código, Variáveis e Boas Práticas"
slug = "grafana-dashboards-como-codigo"
tags = [ "grafana", "prometheus", "monitoring", "observability", "iac" ]
categories = [
  "monitoring",
  "grafana",
]

draft = false
+++

Nos artigos anteriores desta série, subimos Prometheus e Grafana, criamos dashboards manualmente pela interface e configuramos alertas. Isso funciona bem para exploração, mas tem um problema: dashboards criados só pela UI vivem apenas no banco de dados do Grafana. Se o container for recriado sem um volume persistente, ou se alguém apagar um painel sem querer, o trabalho se perde. Neste último artigo, vamos tratar dashboards como qualquer outro artefato de infraestrutura: versionado em Git.

<!--more-->

## 1. Por Que Tratar Dashboards Como Código

Dashboards criados manualmente na interface têm as mesmas desvantagens que configurações de infraestrutura feitas manualmente:

- Não há histórico de quem mudou o quê e por quê.
- É fácil um ambiente (produção) divergir de outro (staging) sem ninguém perceber.
- Recriar o Grafana do zero significa recriar todos os dashboards manualmente.

O Grafana resolve isso com **provisionamento via arquivos**: data sources e dashboards podem ser definidos em YAML/JSON e carregados automaticamente na inicialização, sem intervenção manual.

## 2. Provisionando o Data Source via Arquivo

Em vez de cadastrar o data source do Prometheus pela UI (como fizemos no segundo artigo), crie `provisioning/datasources/prometheus.yml`:

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
```

O campo `editable: false` é proposital: impede que alguém altere a configuração pela UI e gere divergência com o que está versionado no Git.

## 3. Provisionando Dashboards via Arquivo

Primeiro, diga ao Grafana onde procurar os arquivos de dashboard. Crie `provisioning/dashboards/dashboards.yml`:

```yaml
apiVersion: 1

providers:
  - name: "infraestrutura"
    orgId: 1
    folder: "Infraestrutura"
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    options:
      path: /var/lib/grafana/dashboards
```

Agora, qualquer arquivo JSON de dashboard colocado em `/var/lib/grafana/dashboards` dentro do container será carregado automaticamente na pasta "Infraestrutura", e recarregado a cada 30 segundos se o arquivo mudar.

Suba o Grafana montando os três diretórios:

```bash
docker run \
  --detach \
  --name grafana \
  --publish 3000:3000 \
  --volume $(pwd)/provisioning/datasources:/etc/grafana/provisioning/datasources \
  --volume $(pwd)/provisioning/dashboards:/etc/grafana/provisioning/dashboards \
  --volume $(pwd)/dashboards:/var/lib/grafana/dashboards \
  grafana/grafana-oss:latest
```

## 4. De Onde Vem o JSON do Dashboard

Você não precisa escrever o JSON do dashboard na mão. O caminho mais prático:

1. Crie o dashboard normalmente pela interface (como fizemos no segundo artigo desta série).
2. Vá em **Dashboard settings > JSON Model**.
3. Copie o conteúdo e salve como `dashboards/prometheus-visao-geral.json` no seu repositório.

A partir desse ponto, qualquer ajuste feito na UI pode ser reexportado e commitado — o dashboard vira um artefato versionado, revisável em pull request como qualquer outro código.

## 5. Variáveis de Template

Um dos recursos mais úteis do Grafana é permitir que o mesmo dashboard sirva para múltiplos ambientes ou instâncias, sem duplicar painéis. Em **Dashboard settings > Variables > Add variable**:

- **Nome:** `instancia`
- **Tipo:** `Query`
- **Data source:** Prometheus
- **Query:** `label_values(up, instance)`

Isso cria um menu suspenso no topo do dashboard listando todas as instâncias monitoradas. Nos painéis, a query passa a usar a variável:

```promql
rate(process_cpu_seconds_total{instance="$instancia"}[5m])
```

Combine com **Multi-value** e **Include All option** habilitados na variável para permitir selecionar várias instâncias (ou todas) de uma vez — útil em painéis comparativos.

### Repeating Panels

Ainda mais poderoso: em vez de escolher uma instância por vez, é possível configurar um painel para **repetir automaticamente** para cada valor da variável (**Panel options > Repeat options > Repeat by variable**). Com isso, um único painel configurado vira uma grade de gráficos, um por instância, sem trabalho manual.

## 6. Boas Práticas para Manter Isso Sustentável

- **Um repositório (ou diretório) dedicado para observabilidade:** `monitoring/prometheus/`, `monitoring/grafana/dashboards/`, junto com o resto da infraestrutura como código.
- **Revisão em pull request:** mudanças em regras de alerta e dashboards merecem o mesmo cuidado que mudanças em código de aplicação — um alerta mal calibrado pode gerar tanto ruído quanto a ausência dele.
- **Nomeie painéis pelo que eles respondem, não pela métrica:** "Latência acima do SLO?" comunica mais do que "http_request_duration_seconds".
- **Evite dashboards genéricos demais:** um dashboard que tenta servir a todos os times normalmente não serve bem a nenhum. Prefira dashboards focados, usando variáveis para cobrir a variação dentro de um mesmo domínio.
- **Centralize alertas de infraestrutura no Alertmanager (visto no artigo anterior) e reserve o Grafana Alerting para casos que dependem de visualizações específicas do próprio Grafana.**

## 7. Conclusão da Série

Ao longo destes quatro artigos, saímos de um Prometheus rodando sozinho até uma stack de observabilidade completa: coleta de métricas, exporters, alertas com Alertmanager e dashboards versionados como código no Grafana. Prometheus e Grafana resolvem bem esse conjunto de problemas justamente porque cada peça é simples e focada — mas a soma delas é uma das combinações mais usadas em monitoramento de infraestrutura hoje em dia, seja num único servidor ou num cluster Kubernetes inteiro.
