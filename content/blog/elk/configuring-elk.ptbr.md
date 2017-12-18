+++
date = "2016-01-08"
title = "Instalando ELK Stack"
tags = [ "elk", "infraestructure", "elasticsearch", "kibana", "filebeat" ]
categories = [
  "infraestructure",
  "elk",
]

draft = true
+++

## Elasticsearch
#### Configurando
Descomentar opção de network.host e setar para todas as redes.

{{< highlight bash >}}
# ---------------------------------- Network -----------------------------------
#
# Set the bind address to a specific IP (IPv4 or IPv6):
#
network.host: 127.0.0.1
#
# Set a custom port for HTTP:
#
http.port: 9200
{{< / highlight >}}
