+++
date = "2017-12-05"
title = "Configuração de ambiente PHP em Docker"
tags = [ "docker", "infraestructure", "automation", "development", "php" ]
categories = [
  "development",
  "docker",
  "php"
]

draft = false
+++

Quando pensamos em ambientes de configuração para desenvolvimento, o que nós pensamos? em nada! digo, a maioria pensa em codificar e apenas isso. Não se pensa no amanhã e o primeiro a reclamar quem é? você mesmo quando o seu sistema "funciona na minha máquina" não funciona naquele deploy em produção, não é mesmo?

<!--more-->

O amanhã é importante para que possamos evoluir o sistema junto com a infraestrutura e é claro, ter certeza absoluta que o sistema que está funcionando em sua máquina, funcionará no no deploy em produção e assim você poderá progredir "coisas" de forma granular.

### Objetivo

Vamos iniciar em como montar o lego com Docker, ou seja, teremos alguns serviços rodando ao mesmo tempo.

Primeiramente faremos tudo manual e ver o PHP FPM funcionando juntamente com um Webserver em dois containers isolados, após isso (em outro post) vamos escrever código para o Docker Compose e desenvolver código através dele.

Resumindo:

* Criamos arquivos de configuração que serão utilizados nos containers
* Criaremos um container para PHP FPM
* Criaremos um container para o Webserver
* Vamos linkar dos dois containers
* Acessaremos em uma url e veremos o PHP funcionando

### PHP

Quando se trata de containers, a ideia é que eles sejam mais leves possíveis e simples de utilizar. Com essa ideia em mente, poderíamos baixar uma infinidade de imagens baseadas em PHP, porém a que eu recomendo sempre são as imagens baseadas em alpine.

Então vamos iniciar baixando a imagem para PHP 7.2 trabalhando em modo FPM, com o comando:

{{< highlight bash >}}
docker pull php:7.2-fpm-alpine3.6
{{< / highlight >}}

As imagens para PHP você poderá visualizar neste endereço: [https://hub.docker.com/_/php](https://hub.docker.com/_/php)

### Nginx

Como nossa ideia é trabalhar com web, nada mais justo de que termos um servidor Web, certo? existem inúmeras soluções para web, desde o mais conhecido mundialmente como o Apache, LightHTTPD, Cherokee, Caddy e etc.

Para nossa solução, iremos utilizar o também conhecido mundialmente Nginx.

Nginx tem um footprint super baixo e funciona em qualquer máquina simples. Primeiramente vamos baixar a imagem Docker do serviço.

{{< highlight bash >}}
docker pull nginx:1.13.7-alpine
{{< / highlight >}}

### Criando arquivos

Vamos primeiramente criar um estrutura de diretórios para mantermos uma organização e depois passaremos para o arquivo php e depois o arquivo com a configuração para o Nginx, isso apenas para testarmos o funcionamento do processo.

Crie a seguinte estrutura de diretórios em sua máquina

{{< highlight bash >}}
mkdir -p {php,nginx/conf.d}
{{< / highlight >}}

O comando acima irá resultar na seguinte estrutura:

{{< highlight bash>}}
$ tree
.
├── nginx
│   └── conf.d
└── php

3 directories, 0 files

{{< / highlight >}}

#### arquivo.php
Vamos criar o arquivo.php com o conteúdo

{{< highlight php >}}
<?php
phpinfo();
{{< / highlight >}}

e salvar em php/arquivo.php

#### php.conf

Arquivo de configuração necessário para o PHP rodar no nginx.
Salve este arquivo em nginx/php/php.conf


{{< highlight bash >}}
server {
    listen       80;
    server_name  localhost;

    root   /usr/share/nginx/html;
    index  index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    location ~ \.php$ {
        try_files $uri /index.php =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php72:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
{{< / highlight >}}

### Rodando a Stack

Para um primeiro momento, iremos executar a stack manualmente.

O comando abaixo irá rodar PHP 7.2 em modo FPM adicionando o arquivo.php que criamos anteriormente.
{{< highlight bash "linenos=inline" >}}
docker run   \
--detach     \
--name php72 \
--volume $(pwd)/php/arquivo.php:/usr/share/nginx/html/index.php \
php:7.2-fpm-alpine3.6
{{< / highlight >}}

* Linha 2: modo detach permite que o container execute em background
* Linha 3: nome que queremos dar para o container
* Linha 4: aqui montamos o arquivo.php para **/usr/share/nginx/html/index.php** dentro do container
* Linha 5: nome da imagem php que vamos utilizar

O comando abaixo irá levantar outro container com um Webserver Nginx.
{{< highlight bash "linenos=inline" >}}
  docker run \
  --detach \
  --name nginx \
  --link=php72:php72 \
  --volume $(pwd)/nginx/conf.d/php.conf:/etc/nginx/conf.d/default.conf \
  --volume $(pwd)/php/arquivo.php:/usr/share/nginx/html/index.php \
  --publish 20000:80 \
  nginx:1.13.7-alpine
{{< / highlight >}}

* Linha 2: modo detach permite que o container execute em background
* Linha 3: nome que queremos dar para o container
* Linha 4: aqui fazemos um link com o container chamado de php72
* Linha 5: aqui montamos o php.conf para **/etc/nginx/conf.d/default.php** dentro do container
* Linha 6: aqui montamos o arquivo.php para **/usr/share/nginx/html/index.php** dentro do container
* Linha 7: publicamos a porta 20000, com esta porta que conseguimos conectar em http://localhost:20000, e ela envia requisições para a porta 80 (container Nginx)
* Linha 8: nome da imagem nginx que vamos utilizar

Agora acesse no seu browser http://localhost:20000 e verifique o phpinfo.

### Problemas

O nosso ambiente funcionou, porém temos alguns problemas usando este método:

* Atualizações dos containers começam a ficar trabalhosas
* Vários comandos são repetidos durante o uso de linha de comando.
* Rastreio de código, pois o código da nossa "infraestrutura" está baseada em comandos.

### Solução

Quem sabe agora podemos avançar um pouco na nossa solução?

Temos que resolver os problemas mencionados acima e vamos resolver utilizando outro componente do Docker, vamos utilizar o Docker Compose.
