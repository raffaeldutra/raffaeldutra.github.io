+++
date = "2017-02-27"
title = "Introdução ao Docker"
tags = [ "docker", "infraestrutura", "automação", "desenvolvimento" ]
categories = [
  "development",
  "docker"
]
+++

## O que é Docker?

Por definição em [https://opensource.com/resources/what-docker](https://opensource.com/resources/what-docker):

> Docker é uma ferramenta feita para rapidamente, criar, fazer deploy e roda aplicações ussando containers. Containers deixam o desenvolvedor para fazer o pacote da aplicação com todas suas partes necessárias, como bibliotecas e outras dependências, e lançar tudo isso como um único pacote.

Aqui está uma imagem que representa a "pilha" de tecnologia do Docker.

![Docker](https://calm.io/wp-content/uploads/2016/webinar/deploying_docker_containers_in_production/img/what-is-vm-diagram.png)

Então, isso signifia que você pode colocar toda a tecnologia necesária em um container, pelo menos você deveria, e por qual motivo você deveria? Pelo motivo que isso é um dos "pilares" da conternerização.

## Okay, mas como isso funciona?

Docker não é nenhuma novidade em termos de container, mas o oposto, containers existem desde o primeiro release que aconteceu em Agosto de 2008, mas antes disso ainda (Kernel 2.6.27) o LXC existia e ele era totalmente funcional no Kernel 2.6.29.

Okay, mas nós estamos falando de Docker e não LXC. Sim, você está certo! Agora vamos falar sobre LXC :-)

## O que é LXC?

LXC é sobre "quais recursos você quer isolar", então vamos dar uma olhada em como podemos isolar um serviço SSHD -  [http://lxc.sourceforge.net/man/lxc.html](http://lxc.sourceforge.net/man/lxc.html).

> A configuração padrão é isolar os pids, o sysv ipc a os pontos de montagens (mount points). Se você quer rodar um simples shell dentro de um container, uma básica configuração é necessária, especialmente se você quer compartilhar o rootfs. Se você quer rodr uma aplicação como o sshd, você deve remontar o /var/run com um diretório em branco. Se você quer evitar conflitos de todos os casos, você pode especificar um rootfs para o container. O rootfs pode ser um diretório em árvore, previamente montada com um rootfs inicial, então você pode ainda pode usar su distro mas com seu próprio /etc e /home

Aqui temos um exemplo de um diretório listado em formato de árvore para o sshd:

<pre class="prettyprint">
[root@lxc sshd]$ tree -d rootfs

rootfs
|-- bin
|-- dev
|   |-- pts
|   `-- shm
|       `-- network
|-- etc
|   `-- ssh
|-- lib
|-- proc
|-- root
|-- sbin
|-- sys
|-- usr
`-- var
    |-- empty
    |   `-- sshd
    |-- lib
    |   `-- empty
    |       `-- sshd
    `-- run
        `-- sshd

</pre>

E aqui temos os pontos de montagens associados com ele:

<pre class="prettyprint">
[root@lxc sshd]$ cat fstab

/lib /home/root/sshd/rootfs/lib none ro,bind 0 0
/bin /home/root/sshd/rootfs/bin none ro,bind 0 0
/usr /home/root/sshd/rootfs/usr none ro,bind 0 0
/sbin /home/root/sshd/rootfs/sbin none ro,bind 0 0

</pre>

## LXC components

LXC é atualmente feito de alguns componentes separados:

* A biblioteca liblxc:
* Várias linguagens para API:
 - python3
 - lua
 - Go
 - ruby
 - python2
 - Haskell
* Um conjunto de ferramentas para controlar containers.
* Distribuição de templates de container.

Docker até a versão 0.9 era baseada em LXC como driver default para comunicar com o Kernel API, mas desde então vem utilizando libcontainer, uma biblioteca em Go puramente desenvolvida para acessar às APIs do container em Kernel, sem qualquer outra dependência.

Portanto, LXC é um "componente/módulo/tecnologia" do Kernel Linux que permite ciar um ambiente virtual fechado e limitado. Como o LXC executa este processo isolado, uma "abstração", este processo quando precisar ser executado novamente em outra máquina com suporte a LXC do kernel, o processo será executado normalmente e se comportando da mesma maneira originalmente.

Processo é o que chamamos do isolamento que estavámos falando até o momento, como foi o exemplo do SSHD acima. SSH foi isolado/fechado como se fosse um processo e como ele fica independente (apenas dependente do LXC), pode ser executado em qualquer lugar.
