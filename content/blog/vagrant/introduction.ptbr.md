+++
title = "Vagrant o que é?"
date = "2018-07-19"
tags = [ "vagrant", "infraestrutura", "desenvolvimento" ]
categories = [
  "desenvolvimento",
  "vagrant"
]
+++

Bom, pra mim é um framework/library para trabalhar com automação no nível de "infraestrutura", sem precisar reproduzir todos os passos manualmente em uma interface gráfica.

<!--more-->

Vagrant é nada mais do que uma mão na roda na hora de ter aquele ambiente de desenvolvimento ou ainda de testes. Com ele é possível ter diferentes Máquinas Virtuais, rodando obviamente os mais diversos Sistemas Operacionais.


### Vagrant e VirtualBox

Por exemplo, se utilizar VirtualBox e quiser criar uma máquina com Ubuntu, teria que abrir o VirtualBox e clicar em cada passo para criar esta VM. Clicar em criar disco, selecionar o tamanho, processador, memória e etc. Usando Vagrant, você automatiza esses passos de maneira relativamente simples.

### Onde se encaixa ?

Eu vou tentar resumir Vagrant em três ocasisões que pra mim encaixam perfeitamente.

1 - Você tem vários projetos, seja PHP, Java ou qualquer outra linguagem. Como você isola esses ambientes em sua máquina? Aqui evitamos encher a nossa máquina com tantas ferramentas diferentes.

2 - Você precisa fazer testes em Linux e Windows, seja para testar sua automação com scripts, com Puppet/Ansible ou qualquer outra ferramenta.

3 - Você quer reproduzir o mesmo cenário várias e várias vezes sem esforço.

Aqui vou relatar um problema no nivel de desenvolvimento, porém quando você sacara a ideia, um mundo se abre para outras ideias. Vamos lá.

Portando você tem aplicações rodando com PHP 5.2 com Apache, outros projetos com Nginx com PHP 5.3 e em Ubuntu, Debian, Slackware e o que mais que seja, mas o "mais legal" é que, cada um tem suas peculiaridades, no caso uma extensão do PHP aqui, um rewrite ali e etc. Com [Vagrant](http://www.vagrantup.com/), você pode rapidamente criar um ambiente ou vários ambientes em poucos minutos.

A pessoa que trabalhará com você ou no ambiente de infra, não precisa gastar energia/tempo/stress configurando e vendo as peculiaridades de cada projeto. Então simplesmente criamos uma box onde você pode simplesmente sair distribuindo para sua equipe de desenvolvimento e todos terão o mesmo ambiente de desenvolvimento, com as mesmas versões e de pacotes para os projetos, sem aquela desculpa de que funciona na minha máquina.

### Ambiente

Então você criou uma box com os seguintes pacotes:

* PHP 5.5
* Apache 2.2
* MySQL 5.5
* Nginx 1.4
* PostgreSQL 9.0

E agora deseja realmente começar a desenvolver algum código. Se o PHP, Apache e banco de dados estão na box (VM), nada mais lógico imaginar que todo o seu código fica "hospedado" nessa máquina, certo ? Poxa, se isso é verdade, eu teria que desenvolver todo meus códigos na box, através de VIM ou outro editor de texto, mas não!

O Vagrant usa NFS/AutoFS para montar do seu computador para a VM o(s) diretório(s) onde há seus códigos fontes; Portando se você usa Netbeans, Eclipse, Text Mate e afins, você pode normalmente utilizar esses editores como se fosse todo o desenvolvimento feito em localhost, no caso com todos os pacotes instalados como se fosse na sua máquina real.

### Algumas perguntas e respostas:

1. O que é uma box ? - Uma box é simplesmente uma VM (Virtual Machine/Máquina Virtual que você instala;
2. Eu desenvolvo em Ruby e estou acostumado a usar a porta 3000 chamando na URL http://localhost:3000, como faço ? - O Vagrant tem Port Forward, então você redireciona a porta do Vagrant para atender em seu localhost normalmente;
3. Posso ter quantas boxes ? - Quantas quiser, sõ tenha hardware.
4. Serve apenas para desenvolvimento ? - Use como quiser, para desenvolvimento para testes de Serviços de Rede e etc;
