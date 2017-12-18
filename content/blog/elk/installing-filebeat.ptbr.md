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

Para ambientes Windows
Download dos arquivos
Faça o download do arquivo aqui e escolha a arquitetura do sistema.
Instalando
Extrair o conteúdo do zip  para C:\
Renomeie o diretório filebeat-<version>-windows para Filebeat.
Abra um PowerShell prompt como Administrador e selecione "Rodar como Administrador" ou "Run as administrator".
Do PowerShell prompt, rode os seguintes comandos para instalar Filebeat no Windows como serviço.

PS > cd C:\Filebeat
PS C:\Filebeat> .\install-service-filebeat.ps1
Configurando filebeat
Editar arquivo: C:\filebeat\filebeat.yml e adicionar o seguinte conteúdo.
#=========================== Filebeat prospectors =============================

filebeat.prospectors:

- input_type: log
  json.keys_under_root: true

  paths:
    - c:\nginx\logs\access.json

#================================ General =====================================
tags: ["nginx", "proxy"]

#-------------------------- Elasticsearch output ------------------------------
output.elasticsearch:
  hosts: ["cansapp170.sa.agcocorp.com:9200"]
  username: "elastic"
  password: "changeme"
Para ambientes Linux
Instalando
Para configurar o proxy do apt-get, clique aqui
Para configurar o repositório do Elastic, clique aqui.
Para instalar Filebeat em ambiente Ubuntu 14.04, clique aqui.
Para instalar Filebeat em ambiente Ubuntu 16.04, clique aqui.
Arquivo de configuração de exemplo
filebeat.prospectors:
- input_type: log
  json.keys_under_root: true
  paths:
    - /var/log/algumarquivo.log # Arquivo que será consumido para envio do Filebeat.
  fields:
    app_name: rundeck

#Para onde será enviado os logs.
output.elasticsearch:
  hosts: ["cansapp170dv.sa.agcocorp.com:9200"]
  username: "elastic"
  password: "changeme"

  ### Filebeat em Ubuntu 16.04

  #### Inicializando Logstash
  {{< highlight bash >}}
  sudo systemctl start logstash
  {{< / highlight >}}

  ### Instalando Filebeat
  {{< highlight bash >}}
  sudo apt-get install --yes --no-install-recommends filebeat
  {{< / highlight >}}

  #### Inicializando filebeat
  {{< highlight bash >}}
  sudo systemctl start filebeat
  {{< / highlight >}}


### Logstash/Filebeat em Ubuntu 14.04
Dependendo do contexto do cenário, instalar filebeat ou logstash. Tudo depende da necessidade do log que será enviado ao servidor.

#### Para instalar Filebeat
{{< highlight bash >}}
sudo apt-get install --yes --no-install-recommends --force-yes --allow-unauthenticated filebeat
{{< / highlight >}}

#### Para instalar Logstash
{{< highlight bash >}}
sudo apt-get install --yes --no-install-recommends --force-yes --allow-unauthenticated logstash
{{< / highlight >}}
