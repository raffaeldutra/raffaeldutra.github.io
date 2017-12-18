+++
title = "Vagrant o que é ?"
date = "2017-12-15"

draft = true
+++

Hoje falaremos sobre o fantástico Vagrant.

### O que é ?

Vagrant nada mais nada menos do que uma baita (RS tchê) mão na roda na hora de ter aquele ambiente de desenvolvimento ou ainda de testes. Com ele é possível ter diferentes Máquinas Virtuais rodando obviamente os mais diversos Sistemas Operacionais.

Vejamos um caso, você contrata uma excelente pessoa para trabalhar com você, pois é claro você está cheio de trabalho e não aguenta mais ficar sem jogar um BF4 ou um GTA V nas noites da sua semana e também o dia inteiro no Sábado, porém há tantos projetos e cada caso é sempre, é claro, um caso.

Portando você tem aplicações rodando com PHP 5.2 com Apache, outros projetos com Nginx com PHP 5.3 e em Ubuntu, Debian, Slackware e o que mais que seja, mas o "mais legal" é que, cada um tem suas peculiaridades, no caso uma extensão do PHP aqui, um rewrite ali e etc. Com [Vagrant](http://www.vagrantup.com/), você pode rapidamente criar um ambiente ou vários ambientes em poucos minutos.

Então a pessoa que trabalhará com você não precisa gastar energia/tempo/stress configurando e vendo as peculiaridades de cada projeto, simplesmente crie a sua box (ou se você já tem uma) e crie o seu pacote da box e era isso! Uma vez que você fez isso, pode simplesmente sair distribuindo para sua equipe de desenvolvimento e todos terão o mesmo ambiente de desenvolvimento, com as mesmas versões e Sistema Operacional (não aqui inclusivo Windows) que os projetos, sem aquela desculpa (nem sempre é também) de que funciona na minha máquina.

### Ambiente

Então você criou uma box com os seguintes pacotes:

* PHP 5.5
* Apache 2.2
* MySQL 5.5
* Nginx 1.4
* PostgreSQL 9.0

E agora deseja realmente começar a desenvolver algum código. Se o PHP, Apache e Banco de dados estão na box (VM), nada mais lógico imaginar que todo o seu código fica "hospedado" nessa máquina, certo ? Poxa, se isso é verdade, eu teria que desenvolver todo meus códigos na box, através de VIM ou outro editor de texto, mas não!

O Vagrant usa NFS/AutoFS para montar do seu computador para a VM o(s) diretório(s) onde há seus códigos fontes; Portando se você usa Netbeans, Eclipse, Text Mate e afins, você pode normalmente utilizar esses editores como se fosse todo o desenvolvimento feito em localhost, no caso com todos os pacotes instalados como se fosse na sua máquina real.

### Algumas perguntas e respostas:

1.  O que é uma box ? :: Uma box é simplesmente uma VM (Virtual Machine/Máquina Virtual que você instala;
2.  Eu desenvolvo em Ruby e estou acostumado a usar a porta 3000 chamando na URL http://localhost:3000, como faço ? :: O Vagrant tem Port Forward, então você redireciona a porta do Vagrant para atender em seu localhost normalmente;
3.  Posso ter quantas box ? :: Quantas quiser
4.  Serve apenas para desenvolvimento ? :: Use como quiser, para desenvolvimento para testes de Serviços de Rede e etc;

No próximo post, vamos falar sobre a instalação (já vasto em documentação pela internet :-)
