+++
date = "2017-03-08"
title = "docker run"
tags = [ "docker", "infraestructure", "automation", "development", "docker run" ]
categories = [
  "development",
  "docker"
]
draft = true
+++

## docker run  
Ao rodar uma opção do comando docker, como por exemplo o comando abaixo *docker run hello-world*, caso a imagem não se encontre em seu computador local, ele automaticamente tenta baixar a imagem de um repositório, que neste contexto, se localiza em [https://hub.docker.com/explore/](https://hub.docker.com/explore/).

<!--more-->

Como mencionado, verifique que na saída ele não conseguiu encontrar a imagem localmente *Unable to find image 'hello-world:latest' locally*, portando, foi baixar ela remotamente.

<pre class="prettyprint">
# docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
78445dd45222: Pull complete
Digest: sha256:c5515758d4 ...
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://cloud.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/engine/userguide/
</pre>

O comando *docker run* também tem suas opções, você pode fazer o seguinte:

<pre class="prettyprint">
# docker run --help

Usage:  docker run [OPTIONS] IMAGE [COMMAND] [ARG...]

Run a command in a new container

Options:
      --add-host list                         Add a custom host-to-IP mapping (host:ip) (default [])
  -a, --attach list                           Attach to STDIN, STDOUT or STDERR (default [])
      --blkio-weight uint16                   Block IO (relative weight), between 10 and 1000, or 0 to disable (default 0)
      --blkio-weight-device weighted-device   Block IO weight (relative device weight) (default [])
      --cap-add list                          Add Linux capabilities (default [])
      --cap-drop list                         Drop Linux capabilities (default [])
      --cgroup-parent string                  Optional parent cgroup for the container
      --cidfile string                        Write the container ID to the file
      --cpu-count int                         CPU count (Windows only)
      --cpu-percent int                       CPU percent (Windows only)
      --cpu-period int                        Limit CPU CFS (Completely Fair Scheduler) period
      --cpu-quota int                         Limit CPU CFS (Completely Fair Scheduler) quota
      .....
</pre>

Vou destacar entre as inúmeras opções as mais utilizadas para o aprendizado.

<pre class="prettyprint">
  -d, --detach             Run container in background and print container ID
  -i, --interactive        Keep STDIN open even if not attached
  -t, --tty                Allocate a pseudo-TTY
</pre>

Okay, agora que sabemos que podemos sempre consultar opções do comando *docker run*, vamos evoluir um pouco e utilizarmos uma imagem debian.

<pre class="prettyprint">
# docker run -itd debian bash
Unable to find image 'debian:latest' locally
latest: Pulling from library/debian
693502eb7dfb: Pull complete
Digest: sha256:52af198afd8c264f1035206ca66a5c48e602afb32dc912ebf9e9478134601ec4
Status: Downloaded newer image for debian:latest
1927699cdcdfd76afe94b6596149205e85abe32cb27a632328250e0d8554d9b5
</pre>

Pronto, temos uma nova imagem em localhost onde o container que foi levantado é o com id número: *1927699cdcdfd76afe94b659614* (e o hash continua).
