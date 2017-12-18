+++
title = "Vagrant parte 2"
date = "2014-06-10"

draft = true
+++

<span style="font-size: 0.875em; line-height: 1.5;">Para instalar Vagrant, você precisa do Virtual Box, pois é por ele que suas boxes são criadas</span>

### Instalando em ambiente Gnu/Linux Debian Wheezy

Baixando o Virtual Box Para baixar, temos duas opções

1.  Adicionar o repositório ao seu sources.list;
2.  Baixar apenas o pacote diretamente.

#### Opção 1

Na opção 1, faríamos o seguinte:

```shell
frodo[pts/9]~# vi /etc/apt/sources.list
```

Adicionar o seguinte conteúdo:

```shell
frodo[pts/9]~# deb http://download.virtualbox.org/virtualbox/debian wheezy contrib
```

Agora combinamos dois comandos em apenas um para baixamos e registramos a chave:

```shell
frodo[pts/9]~# wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -
```

Atualizamos o repositório recém adicionado e vamos instalar o VirtualBox

```shell
frodo[pts/9]~# apt-get update
4256 frodo[pts/9]~# apt-get install virtualbox-4.3
```

A saída (na teoria) deveria ser essa

```shell
frodo[pts/9]~# apt-get install virtualbox-4.3
Lendo listas de pacotes... Pronto
Construindo árvore de dependências
Lendo informação de estado... Pronto
Os pacotes extra a seguir serão instalados:
  libqt4-network libqt4-opengl libqt4-xml libqtcore4 libqtdbus4 libqtgui4 libsdl-ttf2.0-0
Pacotes sugeridos:
  qt4-qtconfig
Os NOVOS pacotes a seguir serão instalados:
  libqt4-network libqt4-opengl libqt4-xml libqtcore4 libqtdbus4 libqtgui4 libsdl-ttf2.0-0 virtualbox-4.3
0 pacotes atualizados, 8 pacotes novos instalados, 0 a serem removidos e 10 não atualizados.
É preciso baixar 76,9 MB de arquivos.
Depois desta operação, 187 MB adicionais de espaço em disco serão usados.
Você quer continuar [S/n]?
```

Após baixar e instalar. temos que instalar os pacotes dkms, para ter certeza que o VirtualBox tenha os módulos do Kernel instalados como o (_vboxdrv_, _vboxnetflt_ and _vboxnetad)._ Para instalar, simplesmente faremos:

```shell
frodo[pts/9]~# apt-get install dkms
```

#### Opção 2

Na opção 2, iremos baixar o pacote do Virtual Box e instalar diretamente pela linha de comando. Baixando o pacote

```shell
wget http://download.virtualbox.org/virtualbox/4.3.0/virtualbox-4.3_4.3.0-89960~Debian~wheezy_amd64.deb
```

Instalando o pacote:

```shell
frodo[pts/9]~# dpkg -i virtualbox-4.3_4.3.0-89960~Debian~wheezy_amd64.deb
```

### Vagrant

Vamos baixar o tal do Vagrant

```shell
frodo[pts/9]~# wget http://files.vagrantup.com/packages/a40522f5fabccb9ddabad03d836e120ff5d14093/vagrant_1.3.5_x86_64.deb
```

Vamos instalar

```shell
frodo[pts/9]~# dpkg -i vagrant_1.3.5_x86_64.deb
Desempacotando vagrant (de vagrant_1.3.5_x86_64.deb) ...
Configurando vagrant (1:1.3.5) ...
```

A partir de agora você pode escolher qual box deseja usar para começar seu ambiente, no site [http://www.vagrantbox.es/](http://www.vagrantbox.es/) é possível encontrar uma boa lista de Sistemas com os mais variados pacotes já instalados, ou ainda, apenas o Sistema em sí. Eu aqui utilizei um Debian 7.2 com apenas os adicionais para o VirtualBox com o comando abaixo:

```shell
frodo[pts/9]~# vagrant box add debian72 https://dl.dropboxusercontent.com/u/197673519/debian-7.2.0.box
Downloading or copying the box...
Progress: 0% (Rate: 115k/s, Estimated time remaining: 1:00:51))
```

Espere o download ser concluído e o Vagrant estará instaldo. Quando tudo tiver terminado, você pode simplesmente levantar a sua máquina com o comando _vagrant up_

```shell
frodo[pts/9]~# vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
[default] Clearing any previously set forwarded ports...
[default] Creating shared folders metadata...
[default] Clearing any previously set network interfaces...
[default] Preparing network interfaces based on configuration...
[default] Forwarding ports...
[default] -- 22 => 2222 (adapter 1)
[default] Booting VM...
[default] Waiting for machine to boot. This may take a few minutes...
[default] Machine booted and ready!
[default] Mounting shared folders...
[default] -- /vagrant
```

Agora, para acessar está máquina, use o comando _vagrant ssh_

```shell
frodo[pts/9]~# vagrant ssh
```

Pronto, agora instale o que quiser dentro da box normalmente com o _apt-get_ No próximo post veremos como provisionar suas máquinas para que você tenha um ambiente sempre automatizado.
