+++
date = "2016-01-08"
title = "Instalando ELK Stack"
tags = [ "elk", "infraestructure", "elasticsearch", "kibana", "filebeat" ]
categories = [
  "infraestructure",
  "elk",
]

+++

A stack ELK normalmente é utilizada como um centralizador de logs, ou seja, um log server.

A ideia é simples, o Elasticsearch é um banco de dados voltado para pesquisa/leitura, enquanto o Logstash é um "parseador" de informações no qual você pode entrar com as informações e formatar na forma que desejar. Kibana é um dashboard que consome informações do Elasticsearch.

<!--more-->

Nesta instalação, não iremos utilizar Logstash, pois nossa abordagem é de utilizar Filebeat para envio de informações/logs para o Elasticsearch. Filebeat é um "shipper" e apenas isso, mas para utilizar é necessário que seu log já esteja com informaçõa parseada corretamente, ou seja, seu log deve estar em um formato já "aceitável" para que você o consiga visualizar no Kibana.

Vamos instalar a Stack e depois iremos fazer uma cofiguração simples.

### Ambiente utilizado

* Linux: **Ubuntu Linux Server 16.04 LTS**
* Memória: **3072**
* Elasticsearch e Kibana na versão 5

### Resumo:

* Instalando Java
* Adicionando repositórios
* Instalando Elasticsearch
  * Inicializando Elasticsearch
* Instalando Kibana
  * Inicializando Kibana
* Instalando Logstash
  * Inicializando Logstash
* Instalando Filebeat
  * Inicializando Filebeat
* Importando dashboards para o Kibana

### Instalando Java

```bash
sudo -E add-apt-repository ppa:openjdk-r/ppa --yes
sudo apt-get update
sudo apt-get install --yes --no-install-recommends openjdk-8-jdk
```

### Adicionando repositórios
O bloco abaixo é para baixar adicionar o repositório do Elastic ao sistema. Este processo é realizado uma única vez para instalação dos componentes.

```bash
sudo apt-get install --yes --no-install-recommends apt-transport-https
sudo wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
sudo apt-get update
```

### Instalando Elasticsearch

```bash
sudo apt-get install --yes --no-install-recommends elasticsearch
```

### Inicializando Elasticsearch

```bash
sudo systemctl start elasticsearch
```

#### Instalando Kibana

```bash
sudo apt-get install --yes --no-install-recommends kibana
```

### Inicializando Kibana

```bash
sudo systemctl start kibana
```

#### Enviando template
Para enviar o template manualmente, utilize o comando abaixo:

```bash
curl -u elastic:changeme -XPUT 'http://localhost:9200/_template/filebeat' -d@/etc/filebeat/filebeat.template.json
```

#### Importando dashboards para o Kibana
Kibana tem uma série de dashboards prontos para uso, caso houver a necessidade de utilizar, use o comando abaixo

```bash
wget https://artifacts.elastic.co/downloads/beats/beats-dashboards/beats-dashboards-5.4.1.zip
/usr/share/metricbeat/scripts/import_dashboards -file beats-dashboards-5.4.1.zip -es http://localhost:9200
```
