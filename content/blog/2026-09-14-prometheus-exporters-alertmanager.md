+++
type = "blog"
date = "2026-09-14"
title = "Prometheus na Prática - Exporters, Regras de Alerta e Alertmanager"
slug = "prometheus-exporters-alertmanager"
tags = [ "prometheus", "alertmanager", "monitoring", "observability", "node_exporter" ]
categories = [
  "monitoring",
  "prometheus",
]

draft = false
+++

Até agora, nesta série, monitoramos o próprio Prometheus e visualizamos isso no Grafana — útil para aprender, mas pouco interessante na prática: você quer métricas do servidor, da aplicação, do banco de dados. E métricas sozinhas não acordam ninguém às 3h da manhã; para isso existem regras de alerta e o Alertmanager.

<!--more-->

## 1. Exporters: Coletando Métricas de Sistemas de Terceiros

Nem todo sistema fala o formato de métricas do Prometheus nativamente. Para esses casos existem os **exporters**: processos independentes que leem dados de um sistema (SO, banco de dados, fila, etc.) e os expõem num endpoint `/metrics` no formato que o Prometheus entende.

O exemplo mais comum é o [`node_exporter`](https://github.com/prometheus/node_exporter), que expõe métricas de sistema operacional Linux: CPU, memória, disco, rede.

```bash
docker run \
  --detach \
  --name node-exporter \
  --publish 9100:9100 \
  --pid host \
  --volume /:/host:ro,rslave \
  prom/node-exporter:latest \
  --path.rootfs=/host
```

Depois de subir, `curl http://localhost:9100/metrics` já mostra centenas de métricas, como `node_cpu_seconds_total` e `node_memory_MemAvailable_bytes`.

## 2. Monitorando Múltiplos Alvos

Atualize o `prometheus.yml` (do primeiro artigo desta série) para incluir o novo alvo:

```yaml
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "node"
    static_configs:
      - targets: ["node-exporter:9100"]
        labels:
          ambiente: "producao"
          servico: "host-principal"
```

O bloco `labels` dentro de `static_configs` adiciona rótulos extras a todas as séries coletadas desse job — muito útil para diferenciar ambientes (`producao`, `staging`) ou identificar a qual serviço um host pertence, sem precisar alterar o exporter.

Para ambientes maiores, listar alvos manualmente não escala. Nesses casos, o Prometheus suporta descoberta automática (*service discovery*) para Kubernetes, Consul, EC2, entre outros — um assunto que dá pano pra manga o suficiente para um artigo à parte.

## 3. Escrevendo Regras de Alerta

Regras de alerta ficam num arquivo separado, referenciado pelo `prometheus.yml`:

```yaml
rule_files:
  - "alert.rules.yml"
```

Exemplo de `alert.rules.yml` com dois alertas comuns:

```yaml
groups:
  - name: infraestrutura
    rules:
      - alert: InstanciaIndisponivel
        expr: up == 0
        for: 2m
        labels:
          severidade: critica
        annotations:
          summary: "Instância {{ $labels.instance }} está indisponível"
          description: "O alvo {{ $labels.instance }} do job {{ $labels.job }} não responde há mais de 2 minutos."

      - alert: UsoAltoDeCPU
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
        for: 10m
        labels:
          severidade: aviso
        annotations:
          summary: "CPU acima de 85% em {{ $labels.instance }}"
          description: "Uso médio de CPU nos últimos 10 minutos ultrapassou o limite configurado."
```

Alguns pontos importantes:

- **`expr`** é uma expressão PromQL comum — se ela resultar em uma série temporal (mesmo que o valor seja "verdadeiro"), o alerta é considerado ativo.
- **`for`** evita alarme falso: a condição precisa se manter verdadeira pelo tempo definido antes do alerta disparar de fato (ele fica em estado `pending` até lá).
- **`labels`** classificam o alerta (ex: severidade), permitindo roteamento diferente no Alertmanager.
- **`annotations`** com `{{ $labels.instance }}` usam templating do Go para incluir contexto dinâmico na mensagem — essencial para não receber um alerta genérico sem saber qual instância está com problema.

Você pode validar a sintaxe das regras antes de aplicar:

```bash
promtool check rules alert.rules.yml
```

## 4. Configurando o Alertmanager

O Prometheus dispara o alerta, mas quem decide para onde ele vai — e evita que a mesma pessoa receba dez notificações idênticas em um minuto — é o [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/).

Primeiro, aponte o Prometheus para ele em `prometheus.yml`:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["alertmanager:9093"]
```

Um `alertmanager.yml` básico, roteando alertas críticos para um canal e o restante para outro:

```yaml
route:
  receiver: "equipe-padrao"
  group_by: ["alertname", "servico"]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - matchers:
        - severidade = "critica"
      receiver: "equipe-oncall"

receivers:
  - name: "equipe-padrao"
    # configure aqui o receiver real (Slack, e-mail, etc.)

  - name: "equipe-oncall"
    # configure aqui o receiver de urgência (PagerDuty, telefone, etc.)
```

- **`group_by`** agrupa alertas relacionados numa única notificação, em vez de uma mensagem por série temporal afetada.
- **`group_wait`** espera um pouco antes de enviar a primeira notificação de um grupo novo, dando chance de agrupar alertas que cheguem quase juntos.
- **`repeat_interval`** evita spam: um alerta que continua ativo só é reenviado depois desse intervalo.
- **`routes`** permite desviar alertas com determinados labels (aqui, `severidade = "critica"`) para um receiver diferente do padrão.

Suba o Alertmanager e conecte na mesma rede dos outros containers:

```bash
docker run \
  --detach \
  --name alertmanager \
  --publish 9093:9093 \
  --volume $(pwd)/alertmanager.yml:/etc/alertmanager/alertmanager.yml \
  prom/alertmanager:latest
```

## 5. Conclusão

Com exporters coletando dados de sistemas reais, regras de alerta definindo o que é "problema" e o Alertmanager decidindo para quem avisar, o Prometheus deixa de ser só um painel de números e passa a fazer parte ativa da operação. No último artigo desta série, voltamos ao Grafana para ver como versionar dashboards como código e usar variáveis para torná-los reutilizáveis entre ambientes.
