+++
type = "blog"
date = "2026-09-12"
title = "Prometheus - Introdução, Arquitetura e Primeiros Passos"
slug = "prometheus-introducao-arquitetura"
tags = [ "prometheus", "monitoring", "observability", "metrics" ]
categories = [
  "monitoring",
  "prometheus",
]

draft = false
+++

Monitorar infraestrutura e aplicações deixou de ser um "extra" há muito tempo. Sem visibilidade sobre o que está acontecendo em produção, qualquer incidente vira uma investigação às cegas. O Prometheus se tornou o padrão de fato para coleta de métricas no ecossistema cloud native, e entender sua arquitetura é o primeiro passo antes de sair colocando dashboards bonitos em cima dele.

<!--more-->

## 1. O Que é o Prometheus

O [Prometheus](https://prometheus.io/) é um sistema de monitoramento e alerta open source, criado originalmente no SoundCloud e hoje mantido pela Cloud Native Computing Foundation (CNCF). Diferente de ferramentas mais antigas baseadas em *push* (onde cada serviço envia métricas para um coletor central), o Prometheus funciona majoritariamente em modelo *pull*: ele mesmo vai até os alvos (*targets*) e coleta ("faz scrape") das métricas periodicamente.

Essa escolha de design traz algumas vantagens práticas:

- **Simplicidade operacional:** você não precisa configurar cada aplicação para "saber" para onde enviar métricas; basta expor um endpoint HTTP.
- **Facilidade de debug:** dá para acessar o endpoint de métricas de um serviço manualmente (`curl`) e ver exatamente o que o Prometheus está coletando.
- **Detecção natural de indisponibilidade:** se o Prometheus não consegue fazer scrape de um alvo, isso já é um sinal (métrica `up == 0`).

## 2. Modelo de Dados

O Prometheus armazena tudo como **séries temporais** identificadas por um nome de métrica e um conjunto de pares chave-valor chamados *labels*. Por exemplo:

```text
http_requests_total{method="GET", handler="/api/users", status="200"} 27183
```

- `http_requests_total` é o nome da métrica.
- `method`, `handler` e `status` são labels que permitem filtrar e agregar os dados.
- `27183` é o valor coletado naquele instante.

Existem quatro tipos principais de métrica:

- **Counter:** valor que só cresce (ex: total de requisições). Reinicia para zero quando o processo reinicia.
- **Gauge:** valor que sobe e desce livremente (ex: uso de memória, número de conexões ativas).
- **Histogram:** distribui observações em *buckets* (ex: latência de requisições), permitindo calcular percentis.
- **Summary:** parecido com o histogram, mas calcula quantis diretamente no cliente.

## 3. Arquitetura

Uma instalação típica do Prometheus envolve alguns componentes:

```text
┌─────────────┐      scrape       ┌──────────────────┐
│  Aplicação   │ <──────────────── │  Prometheus       │
│  /metrics    │                   │  Server           │
└─────────────┘                   └─────────┬─────────┘
                                             │
┌─────────────┐      scrape                 │ alertas
│  Exporter    │ <───────────────────────────┤
│ (node_exp.)  │                             ▼
└─────────────┘                   ┌──────────────────┐
                                   │  Alertmanager     │
                                   └──────────────────┘
```

- **Prometheus Server:** o coração do sistema. Faz scrape dos alvos, armazena as séries temporais em seu banco local (TSDB) e avalia regras de alerta.
- **Exporters:** processos auxiliares que expõem métricas de sistemas que não falam o formato do Prometheus nativamente (ex: `node_exporter` para métricas de SO, `mysqld_exporter` para MySQL).
- **Alertmanager:** recebe alertas disparados pelo Prometheus e cuida de agrupamento, deduplicação e roteamento (e-mail, Slack, PagerDuty, etc.).
- **Service Discovery:** em ambientes dinâmicos (Kubernetes, EC2, Consul), o Prometheus descobre alvos automaticamente em vez de depender de uma lista estática.

Vamos falar de exporters e Alertmanager com mais profundidade em um próximo artigo desta série.

## 4. Subindo um Prometheus Local

Para experimentar sem instalar nada na máquina, o jeito mais rápido é via Docker. Crie um arquivo `prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
```

Esse `scrape_config` mínimo faz o Prometheus monitorar a si mesmo — ele expõe suas próprias métricas internas em `/metrics`.

Suba o container montando o arquivo de configuração:

```bash
docker run \
  --detach \
  --name prometheus \
  --publish 9090:9090 \
  --volume $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:latest
```

Acesse `http://localhost:9090` e você verá a interface web do Prometheus. Em **Status > Targets** você confirma que o alvo `prometheus` está com status `UP`.

## 5. Primeiras Consultas com PromQL

O PromQL (Prometheus Query Language) é a linguagem usada para consultar as séries temporais. Algumas consultas básicas para começar:

```promql
# Verifica se os alvos estão respondendo (1 = up, 0 = down)
up

# Taxa de uso de CPU do próprio processo do Prometheus, por segundo
rate(process_cpu_seconds_total[5m])

# Quantidade de séries temporais armazenadas
prometheus_tsdb_head_series
```

A função `rate()` é uma das mais usadas: ela calcula a taxa de variação por segundo de um counter dentro de uma janela de tempo (nesse caso, 5 minutos). É essencial para transformar contadores sempre-crescentes em métricas legíveis, como "requisições por segundo".

## 6. Conclusão

Com o Prometheus rodando localmente e as primeiras consultas PromQL na mão, já dá para entender por que ele se tornou o padrão para monitoramento em ambientes cloud native: modelo de dados simples, coleta via pull e uma linguagem de consulta poderosa. No próximo artigo desta série, vamos conectar o Grafana ao Prometheus para transformar essas métricas em dashboards visuais.
