+++
type = "blog"
date = "2026-09-13"
title = "Grafana - Instalação, Data Sources e Primeiros Dashboards"
slug = "grafana-instalacao-dashboards"
tags = [ "grafana", "prometheus", "monitoring", "observability", "dashboards" ]
categories = [
  "monitoring",
  "grafana",
]

draft = false
+++

No artigo anterior desta série, subimos um Prometheus local e fizemos as primeiras consultas em PromQL direto na interface web dele. Funciona, mas não é exatamente o que você quer mostrar numa reunião ou deixar aberto num monitor da equipe. É aqui que entra o Grafana: a ferramenta que transforma séries temporais em painéis visuais, alertas e histórico navegável.

<!--more-->

## 1. Por Que Grafana e Não Só o Prometheus?

O Prometheus tem uma interface web própria, mas ela é pensada para debug e exploração rápida de métricas — não para visualização contínua. O [Grafana](https://grafana.com/) resolve esse problema com:

- Painéis (*panels*) configuráveis: gráficos de série temporal, gauges, tabelas, heatmaps, contadores.
- Suporte a múltiplas fontes de dados ao mesmo tempo (Prometheus, Loki, PostgreSQL, CloudWatch, etc.), permitindo correlacionar métricas de origens diferentes num único dashboard.
- Sistema de variáveis para dashboards reutilizáveis (ex: trocar o ambiente ou a instância sem editar o painel).
- Alerta nativo (Grafana Alerting), que pode complementar ou até substituir o Alertmanager em alguns cenários.

## 2. Subindo o Grafana

Assim como fizemos com o Prometheus, o caminho mais rápido para testar é via Docker:

```bash
docker run \
  --detach \
  --name grafana \
  --publish 3000:3000 \
  grafana/grafana-oss:latest
```

Acesse `http://localhost:3000`. O login padrão é `admin` / `admin` — o Grafana vai pedir para trocar a senha no primeiro acesso.

> **Dica:** se o Prometheus também estiver rodando em container (como no artigo anterior), coloque os dois na mesma rede Docker (`docker network create monitoring` e `--network monitoring` em ambos) para que o Grafana consiga resolver o hostname `prometheus` em vez de depender do IP da máquina host.

## 3. Configurando o Data Source do Prometheus

Com o Grafana no ar:

1. Vá em **Connections > Data sources > Add data source**.
2. Selecione **Prometheus**.
3. Em **Connection > Prometheus server URL**, informe o endereço do seu Prometheus (ex: `http://prometheus:9090` se estiverem na mesma rede Docker, ou `http://host.docker.internal:9090` no Docker Desktop).
4. Clique em **Save & test**. Uma mensagem confirmando "Successfully queried the Prometheus API" indica que a conexão está funcionando.

A partir daqui, qualquer dashboard criado no Grafana pode consultar esse data source usando PromQL — exatamente as mesmas consultas que vimos no artigo anterior.

## 4. Criando o Primeiro Dashboard

Vá em **Dashboards > New > New Dashboard > Add visualization** e escolha o data source do Prometheus.

### Painel 1: Status dos alvos (Stat)

Na query, use:

```promql
up
```

Troque o tipo de visualização de **Time series** para **Stat**. Em **Panel options > Value mappings**, mapeie `0` para "DOWN" (cor vermelha) e `1` para "UP" (cor verde). Isso dá um indicador rápido de saúde dos alvos monitorados.

### Painel 2: Uso de CPU ao longo do tempo (Time series)

```promql
rate(process_cpu_seconds_total{job="prometheus"}[5m])
```

Mantenha a visualização como **Time series** — é o tipo ideal para acompanhar tendências e picos ao longo do tempo.

### Painel 3: Total de séries armazenadas (Gauge)

```promql
prometheus_tsdb_head_series
```

Escolha **Gauge** e defina um valor máximo razoável em **Panel options > Standard options > Max**, para visualizar o quão perto do limite esperado o Prometheus está.

Depois de adicionar os painéis, clique em **Save dashboard**, dê um nome (ex: "Prometheus — Visão Geral") e salve numa pasta (**folder**) dedicada, em vez de deixar solto na raiz.

## 5. Boas Práticas Iniciais de Organização

Antes de sair criando dezenas de dashboards, vale adotar algumas convenções desde o início:

- **Pastas por domínio ou time:** `infra/`, `aplicacao/`, `banco-de-dados/`, em vez de uma lista plana difícil de navegar.
- **Nomenclatura consistente:** prefixe com o sistema monitorado, ex: "API — Latência" em vez de só "Latência".
- **Um dashboard, um propósito:** é tentador colocar tudo num painel só; dashboards focados são mais fáceis de manter e de interpretar sob pressão (durante um incidente, ninguém quer garimpar 40 painéis).
- **Tags nos dashboards:** o Grafana permite marcar dashboards com tags (ex: `prometheus`, `producao`), o que ajuda muito na busca conforme a quantidade cresce.

## 6. Conclusão

Com o data source configurado e o primeiro dashboard no ar, o Prometheus deixou de ser só uma fonte de números numa interface de debug e virou parte de um painel de observabilidade de verdade. No próximo artigo da série, vamos voltar ao Prometheus para configurar exporters, regras de alerta e o Alertmanager — a parte que avisa você antes que o usuário perceba o problema.
