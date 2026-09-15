+++
type = "blog"
date = "2026-07-24"
title = "Terraform e YAML - Modularização e Configurações Dinâmicas"
slug = "terraform-yaml-modularizacao"
tags = [ "terraform", "cloud", "iac", "yaml" ]
categories = [
  "infrastructure",
  "terraform",
]

draft = false
+++

## 1. Introdução: Elevando a Abstração no Terraform

No Artigo 1 desta série, exploramos os fundamentos da separação de código e dados no Terraform utilizando arquivos YAML e a função `yamldecode`. Aprendemos a carregar configurações básicas por ambiente, o que já representa um avanço significativo na organização de projetos de Infraestrutura como Código (IaC). No entanto, à medida que a infraestrutura se torna mais complexa, a simples leitura de um arquivo YAML pode não ser suficiente para manter a modularidade e evitar a duplicação de código.

<!--more-->

Este segundo artigo aprofundará nas técnicas intermediárias, focando em como combinar a flexibilidade do YAML com os poderosos recursos de modularização do Terraform. Abordaremos a passagem de configurações YAML para módulos, o uso do meta-argumento `for_each` para provisionamento dinâmico de recursos e módulos, e a aplicação de funções como `lookup` e condicionais para lidar com a variabilidade e opcionalidade dos dados de configuração.

## 2. Modularização com Dados YAML

A modularização é um pilar fundamental para a construção de infraestruturas escaláveis e manuteníveis no Terraform. Módulos permitem encapsular um conjunto de recursos relacionados, tornando-os reutilizáveis em diferentes partes do seu projeto ou em outros projetos. Ao combinar módulos com dados YAML, podemos criar componentes de infraestrutura altamente configuráveis.

### 2.1. Estrutura de Projeto com Módulos

Vamos expandir a estrutura de diretórios do Artigo 1 para incluir um módulo de exemplo:

```plaintext
. (root do projeto)
├── main.tf
├── variables.tf
├── outputs.tf
├── environments/
│   ├── dev.yaml
│   ├── staging.yaml
│   └── prod.yaml
└── modules/
    └── webserver/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### 2.2. Definindo o Módulo `webserver`

O módulo `webserver` será responsável por provisionar uma instância de servidor web (por exemplo, uma instância AWS EC2). Ele receberá suas configurações como variáveis de entrada.

**`modules/webserver/variables.tf`:**

```terraform
variable "instance_type" {
  description = "O tipo de instância EC2 para o servidor web."
  type        = string
}

variable "ami_id" {
  description = "O ID da AMI para o servidor web."
  type        = string
}

variable "server_name_prefix" {
  description = "Prefixo para o nome do servidor."
  type        = string
}

variable "instance_count" {
  description = "Número de instâncias a serem provisionadas."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags adicionais para o servidor web."
  type        = map(string)
  default     = {}
}
```

**`modules/webserver/main.tf`:**

```terraform
resource "aws_instance" "web" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = merge(
    var.tags,
    {
      Name = "${var.server_name_prefix}-${count.index + 1}"
    }
  )

  # Para este exemplo, assumimos que o provedor AWS está configurado no root
  # provider = aws
}
```

**`modules/webserver/outputs.tf`:**

```terraform
output "instance_ids" {
  value       = aws_instance.web[*].id
  description = "IDs das instâncias EC2 provisionadas pelo módulo."
}

output "public_ips" {
  value       = aws_instance.web[*].public_ip
  description = "IPs públicos das instâncias EC2 provisionadas pelo módulo."
}
```

### 2.3. Integrando o Módulo com Configurações YAML

Agora, no `main.tf` principal, podemos chamar o módulo `webserver` e passar as configurações carregadas do YAML como variáveis para o módulo.

**`main.tf` (atualizado):**

```terraform
variable "environment" {
  description = "O ambiente para o qual a infraestrutura será provisionada."
  type        = string
  default     = "dev"
}

locals {
  env_config = yamldecode(file("${path.module}/environments/${var.environment}.yaml"))
}

module "webserver_instance" {
  source             = "./modules/webserver"
  instance_type      = local.env_config.instance_type
  ami_id             = local.env_config.ami_id
  server_name_prefix = local.env_config.server_name_prefix
  instance_count     = local.env_config.instance_count
  tags               = local.env_config.tags
}

output "webserver_public_ips" {
  value = module.webserver_instance.public_ips
}
```

Com esta abordagem, o módulo `webserver` é genérico e reutilizável, e suas configurações são totalmente externalizadas para os arquivos YAML, permitindo que o mesmo módulo seja usado em diferentes ambientes com parâmetros distintos.

## 3. Provisionamento Dinâmico com `for_each` e YAML

O meta-argumento `for_each` é uma ferramenta poderosa para criar múltiplos recursos ou módulos a partir de um mapa ou conjunto de strings. Quando combinado com dados estruturados de um arquivo YAML, ele permite provisionar infraestruturas dinâmicas e escaláveis, evitando a repetição de blocos de código Terraform. [2]

### 3.1. Cenário: Múltiplos Buckets S3 com Configurações Variáveis

Imagine a necessidade de criar vários buckets S3, cada um com configurações específicas (ACL, versionamento, tags, etc.), que variam por ambiente ou por finalidade. O `for_each` é ideal para isso.

**`environments/dev.yaml` (adicionando configuração de S3):**

```yaml
region: us-east-1
instance_type: t2.micro
ami_id: ami-0abcdef1234567890
server_name_prefix: dev-web
instance_count: 1
tags:
  Environment: Development
  Project: MyWebApp
  Owner: DevTeam

s3_buckets:
  app-logs:
    name: myapp-dev-logs-bucket
    acl: private
    versioning: true
    tags:
      Purpose: Logs
  app-assets:
    name: myapp-dev-assets-bucket
    acl: public-read
    versioning: false
    website_enabled: true
    tags:
      Purpose: Assets
```

### 3.2. Utilizando `for_each` no `main.tf`

```terraform
# ... (variáveis e locals existentes)

resource "aws_s3_bucket" "app_buckets" {
  for_each = local.env_config.s3_buckets

  bucket = each.value.name
  acl    = each.value.acl

  versioning {
    enabled = lookup(each.value, "versioning", false)
  }

  # Bloco dinâmico para configuração de website, se presente
  dynamic "website" {
    for_each = lookup(each.value, "website_enabled", false) ? [1] : []
    content {
      index_document = "index.html"
      error_document = "error.html"
    }
  }

  tags = each.value.tags
}

output "s3_bucket_names" {
  value = [for bucket in aws_s3_bucket.app_buckets : bucket.id]
}
```

**Explicação:**

- `for_each = local.env_config.s3_buckets`: O Terraform iterará sobre o mapa `s3_buckets` definido no YAML. Para cada chave (ex: `app-logs`, `app-assets`), um recurso `aws_s3_bucket` será criado.

- `each.value`: Dentro do bloco `resource`, `each.value` refere-se ao mapa de configurações para o bucket atual (ex: `{ name: myapp-dev-logs-bucket, acl: private, ... }`).

## 4. Lidando com Opcionalidade e Valores Padrão: `lookup` e Condicionais

Nem todas as configurações em YAML serão obrigatórias para todos os recursos ou módulos. Para lidar com atributos opcionais e fornecer valores padrão, o Terraform oferece funções como `lookup` e expressões condicionais.

### 4.1. A Função `lookup`

A função `lookup(map, key, default)` permite acessar um valor em um mapa. Se a `key` não existir, ela retorna o `default` fornecido, evitando erros. [3]

No exemplo do S3 acima, `lookup(each.value, "versioning", false)` garante que, se `versioning` não estiver definido no YAML para um bucket, o valor padrão `false` será usado, em vez de causar um erro.

### 4.2. Expressões Condicionais (`? :`)

Expressões condicionais (`condition ? true_val : false_val`) são úteis para decidir qual valor usar com base em uma condição. [4]

No bloco `dynamic "website"` do exemplo do S3, `lookup(each.value, "website_enabled", false) ? [1] : []` é uma expressão condicional. Se `website_enabled` for `true` (ou não estiver presente e o `lookup` retornar `false`), o `for_each` do bloco `dynamic` receberá uma lista com um elemento (`[1]`), fazendo com que o bloco `website` seja criado. Caso contrário, receberá uma lista vazia (`[]`), e o bloco `website` não será criado. Isso permite que a configuração do website seja opcional no YAML.

## 5. Conclusão do Nível Intermediário

Neste segundo artigo, avançamos na utilização de Terraform com YAML, explorando como a modularização e o provisionamento dinâmico podem ser aprimorados. A combinação de módulos, `for_each`, `lookup` e expressões condicionais permite criar infraestruturas mais flexíveis, reutilizáveis e adaptáveis a diferentes cenários e ambientes. Com essas técnicas, você pode reduzir significativamente a duplicação de código e gerenciar configurações complexas de forma mais eficiente.

No próximo e último artigo desta série, mergulharemos em padrões avançados, como o deep merge de configurações, a gestão de múltiplos arquivos YAML para hierarquias complexas e a integração com fluxos de CI/CD, para construir arquiteturas de IaC verdadeiramente escaláveis.

---

*Imagem de capa: Logo oficial do Terraform — [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Terraform-logo.png)*

**Referências:**

1. [yamldecode - Functions - Configuration Language | Terraform by HashiCorp](https://developer.hashicorp.com/terraform/language/functions/yamldecode)

1. [for_each - Meta-Arguments - Configuration Language | Terraform by HashiCorp](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each)

1. [lookup - Functions - Configuration Language | Terraform by HashiCorp](https://developer.hashicorp.com/terraform/language/functions/lookup)

1. [Conditional Expressions - Configuration Language | Terraform by HashiCorp](https://developer.hashicorp.com/terraform/language/expressions/conditionals)

---

*Publicado originalmente em [dev.to/apsis-cc](https://dev.to/apsis-cc/terraform-e-yaml-modularizacao-e-configuracoes-dinamicas-2opb).*

