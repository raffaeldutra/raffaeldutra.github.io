+++
date = "2017-02-27"
title = "Docker Introduction"
tags = [ "docker", "infraestructure", "automation", "development" ]
categories = [
  "development",
  "docker"
]
+++

## What's Docker?
By definition on [https://opensource.com/resources/what-docker](https://opensource.com/resources/what-docker):

> Docker is a tool designed to make it easier to create, deploy, and run applications by using containers. Containers allow a developer to package up an application with all of the parts it needs, such as libraries and other dependencies, and ship it all out as one package.

<!--more-->

Here is an image that represent the Docker "stack" technology.

<!--more-->

![Docker](http://19yw4b240vb03ws8qm25h366.wpengine.netdna-cdn.com/wp-content/uploads/Docker-API-infographic-container-devops-nordic-apis.png)

So, that means you can put all the necessary technology into a container, at least you should, and why you should? Because that's on the "pillars" of containerization.

## Okay, but how it works?

Docker is nothing new in terms of containers, but the opposite, containers exists since the first release on August/2008, but before that (Kernel 2.6.27) LXC exists and it was full functional at Kernel 2.6.29. Okay, but we are talking about Docker, not LXC.

Yeap, you are right! Now let's talks about LXC :-)

## What's LXC?

LXC is about "what resources you want to isolate", so let's take a look how we can isolate the SSHD service -  [http://lxc.sourceforge.net/man/lxc.html](http://lxc.sourceforge.net/man/lxc.html).

> The default configuration is to isolate the pids, the sysv ipc and the mount points. If you want to run a simple shell inside a container, a basic configuration is needed, especially if you want to share the rootfs. If you want to run an application like sshd, you should provide a new network stack and a new hostname. If you want to avoid conflicts with some files eg. /var/run/httpd.pid, you should remount /var/run with an empty directory. If you want to avoid the conflicts in all the cases, you can specify a rootfs for the container. The rootfs can be a directory tree, previously bind mounted with the initial rootfs, so you can still use your distro but with your own /etc and /home

Here is an example of directory tree for sshd:

<pre class="prettyprint">
[root@lxc sshd]$ tree -d rootfs
|rootfs
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

And here the mount points associate with it:

<pre class="prettyprint">
[root@lxc sshd]$ cat fstab

/lib /home/root/sshd/rootfs/lib none ro,bind 0 0
/bin /home/root/sshd/rootfs/bin none ro,bind 0 0
/usr /home/root/sshd/rootfs/usr none ro,bind 0 0
/sbin /home/root/sshd/rootfs/sbin none ro,bind 0 0

</pre>

## LXC components

LXC is currently made of a few separate components:

* The liblxc library:
* Several language bindings for the API:
 - python3
 - lua
 - Go
 - ruby
 - python2
 - Haskell
* A set of standard tools to control the containers
* Distribution container templates

Docker until version 0.9 has been used LXC as default driver to communicate with API Kernel, but since them, it is been using libcontainer, a pure Go library which was developed to access the Kernel’s container APIs directly, without any other dependencies.

So, LXC is a Kernel "component/module/technology" that allow us to creat a virtual environment closed and limited. As LXC executes that process isolated, an "abstraction", that process when need to runs again in other machine with LXC support, the process will be executed normally and behaving as same way as originally.

Process is what we calling isolation whom we're talking about until now, like in the SSHD example before. SSH was isolated/closed like it was a process and it is independent (just dependent from LXC), so it could be execute from anywhere
