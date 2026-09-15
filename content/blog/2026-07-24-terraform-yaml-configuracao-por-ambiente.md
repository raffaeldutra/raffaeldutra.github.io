+++
type = "blog"
date = "2026-07-24"
title = "Terraform e YAML - Introdução e Configuração Básica por Ambiente"
slug = "terraform-yaml-configuracao-por-ambiente"
tags = [ "terraform", "cloud", "iac", "yaml" ]
categories = [
  "infrastructure",
  "terraform",
]

draft = false
+++

## 1. Desafio Multi-Ambiente

A Infraestrutura como Código (IaC) revolucionou a forma como gerenciamos e provisionamos recursos de TI. Ferramentas como o Terraform permitem descrever a infraestrutura desejada em arquivos de configuração, que podem ser versionados, revisados e implantados de forma automatizada e consistente. Essa abordagem traz inúmeros benefícios, como a redução de erros manuais, a aceleração do provisionamento e a garantia de que o ambiente de produção seja idêntico ao de desenvolvimento.

<!--more-->

No entanto, um desafio comum em projetos de IaC é a gestão de configurações que variam entre diferentes ambientes, como desenvolvimento (dev), homologação (staging) e produção (prod). Cada ambiente pode exigir tipos de instâncias diferentes, tamanhos de disco, regiões da nuvem, ou tags específicas. Manter essas diferenças sem duplicar excessivamente o código da infraestrutura é crucial para a manutenibilidade e escalabilidade do projeto.

Este artigo, o primeiro de uma série, apresentará os conceitos fundamentais de como desacoplar o código Terraform dos dados de configuração, utilizando arquivos YAML. Abordaremos a estrutura básica do projeto, a criação de arquivos YAML específicos por ambiente e o uso da função `yamldecode` do Terraform para carregar e interpretar esses dados.

## 2. Por Que Separar Código e Dados?

Separar o código da infraestrutura dos seus dados de configuração oferece vantagens significativas:

- **Reusabilidade:** O mesmo código Terraform pode ser usado para provisionar infraestrutura em múltiplos ambientes, apenas alterando o arquivo de dados de entrada.

- **Manutenibilidade:** Alterações em configurações específicas de um ambiente não exigem modificações no código principal do Terraform, reduzindo o risco de introduzir bugs.

- **Clareza:** Os arquivos de configuração YAML são geralmente mais legíveis para não-desenvolvedores ou para quem precisa apenas entender os parâmetros de um ambiente, sem se aprofundar na lógica do Terraform.

- **Princípio DRY (Don't Repeat Yourself):** Evita a duplicação de blocos de código Terraform que seriam idênticos, exceto pelos valores de suas variáveis.

## 3. Pré-requisitos

Para acompanhar este tutorial, você precisará de:

- **Terraform CLI:** Versão 0.13 ou superior, pois a função `yamldecode` foi introduzida nesta versão. [1]

- **Conhecimento Básico:** Familiaridade com os conceitos de Terraform (recursos, variáveis, outputs) e a sintaxe YAML.

## 4. Estrutura de Projeto Básica

Uma estrutura de diretórios bem organizada é o primeiro passo para uma gestão eficaz. Para este nível introdutório, sugerimos a seguinte organização:

```plaintext
. (root do projeto)
├── main.tf
├── variables.tf
├── outputs.tf
└── environments/
    ├── dev.yaml
    ├── staging.yaml
    └── prod.yaml
```

- `main.tf`: Contém a lógica principal do Terraform, incluindo a leitura dos arquivos YAML e a definição dos recursos.

- `variables.tf`: Declaração de variáveis globais, como a variável que selecionará o ambiente.

- `outputs.tf`: Define os valores que serão exibidos após a aplicação do Terraform.

- `environments/`: Um diretório dedicado para armazenar os arquivos YAML, um para cada ambiente.

## 5. Definindo Configurações por Ambiente com YAML

Vamos criar arquivos YAML simples para representar as configurações de três ambientes: `dev`, `staging` e `prod`. Estes arquivos conterão pares chave-valor que o Terraform utilizará.

### `environments/dev.yaml`

Este arquivo define as configurações para o ambiente de desenvolvimento. Geralmente, são recursos menores e mais econômicos.

```yaml
region: us-east-1
instance_type: t2.micro
ami_id: ami-0abcdef1234567890 # Exemplo de AMI ID
server_name_prefix: dev-web
instance_count: 1
tags:
  Environment: Development
  Project: MyWebApp
  Owner: DevTeam
```

### `environments/staging.yaml`

Para o ambiente de homologação, podemos ter recursos um pouco mais robustos, mas ainda não em escala de produção.

```yaml
region: us-west-2
instance_type: t2.medium
ami_id: ami-0fedcba9876543210 # Exemplo de AMI ID
server_name_prefix: staging-web
instance_count: 2
tags:
  Environment: Staging
  Project: MyWebApp
  Owner: QAteam
```

### `environments/prod.yaml`

O ambiente de produção terá as configurações mais robustas e otimizadas para desempenho e alta disponibilidade.

```yaml
region: eu-west-1
instance_type: m5.large
ami_id: ami-0123456789abcdef0 # Exemplo de AMI ID
server_name_prefix: prod-web
instance_count: 3
tags:
  Environment: Production
  Project: MyWebApp
  Owner: OpsTeam
```

## 6. Carregando e Utilizando Configurações YAML no Terraform

Agora, vamos integrar esses arquivos YAML ao nosso código Terraform. O `main.tf` será responsável por ler o arquivo YAML do ambiente selecionado e disponibilizar seus dados para uso.

### `variables.tf`

Primeiro, definimos uma variável para selecionar o ambiente. É uma boa prática fornecer um valor padrão.

```terraform
variable "environment" {
  description = "O ambiente para o qual a infraestrutura será provisionada (dev, staging, prod)"
  type        = string
  default     = "dev" # Valor padrão para desenvolvimento
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "O ambiente deve ser 'dev', 'staging' ou 'prod'."
  }
}
```

### `main.tf`

Neste arquivo, usaremos `yamldecode` e `file()` para carregar as configurações e um bloco `resource` de exemplo para demonstrar seu uso.

```terraform
# Carrega o conteúdo do arquivo YAML do ambiente selecionado
locals {
  env_config = yamldecode(file("${path.module}/environments/${var.environment}.yaml"))
}

# Exemplo de um recurso AWS EC2 utilizando as configurações do YAML
resource "aws_instance" "web_server" {
  count         = local.env_config.instance_count # Número de instâncias do YAML
  ami           = local.env_config.ami_id
  instance_type = local.env_config.instance_type

  tags = merge(
    local.env_config.tags,
    {
      Name = "${local.env_config.server_name_prefix}-${count.index + 1}"
    }
  )

  # Para este exemplo, assumimos que o provedor AWS está configurado
  # provider = aws
}
```

**Explicação:**

- O bloco `locals` é usado para definir `env_config`, que armazena o mapa resultante da decodificação do YAML. `path.module` garante que o caminho para o diretório `environments` seja relativo ao `main.tf`.

- O recurso `aws_instance` utiliza `local.env_config.instance_count` para o meta-argumento `count`, `local.env_config.ami_id` e `local.env_config.instance_type` para configurar as instâncias.

- As `tags` são mescladas: as tags definidas no YAML (`local.env_config.tags`) são combinadas com uma tag `Name` gerada dinamicamente, que inclui o prefixo do servidor e um índice para cada instância.

### `outputs.tf`

Para verificar se as configurações foram aplicadas corretamente, podemos definir alguns outputs.

```terraform
output "current_environment" {
  value       = var.environment
  description = "O ambiente atual provisionado."
}

output "provisioned_instance_ids" {
  value       = aws_instance.web_server[*].id
  description = "IDs das instâncias EC2 provisionadas."
}

output "provisioned_instance_types" {
  value       = aws_instance.web_server[*].instance_type
  description = "Tipos das instâncias EC2 provisionadas."
}

output "provisioned_instance_tags" {
  value       = aws_instance.web_server[*].tags
  description = "Tags das instâncias EC2 provisionadas."
}
```

## 7. Executando o Terraform com Diferentes Ambientes

Para aplicar as configurações de um ambiente específico, você pode passar a variável `environment` ao Terraform de algumas maneiras:

### Via Linha de Comando (`-var`)

Esta é a forma mais direta para testes ou implantações pontuais:

```bash
# Para o ambiente de desenvolvimento
terraform plan -var="environment=dev"
terraform apply -var="environment=dev"

# Para o ambiente de homologação
terraform plan -var="environment=staging"
terraform apply -var="environment=staging"

# Para o ambiente de produção
terraform plan -var="environment=prod"
terraform apply -var="environment=prod"
```

### Via Arquivo de Variáveis (`-var-file`)

Para um fluxo de trabalho mais estruturado, você pode criar arquivos `.tfvars` específicos para cada ambiente. Por exemplo, crie `dev.tfvars`, `staging.tfvars` e `prod.tfvars` na raiz do projeto.

**`dev.tfvars`:**

```yaml
environment = "dev"
```

**`staging.tfvars`:**

```yaml
environment = "staging"
```

**`prod.tfvars`:**

```yaml
environment = "prod"
```

Então, execute o Terraform apontando para o arquivo de variáveis desejado:

```bash
# Para o ambiente de desenvolvimento
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# Para o ambiente de homologação
terraform plan -var-file="staging.tfvars"
terraform apply -var-file="staging.tfvars"

# Para o ambiente de produção
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

## 8. Conclusão do Nível Introdutório

Neste primeiro artigo, estabelecemos a base para a separação de código e dados no Terraform usando arquivos YAML. Aprendemos a estruturar o projeto, definir configurações específicas por ambiente em YAML e carregá-las no Terraform usando `yamldecode`. Esta abordagem inicial já proporciona uma melhor organização e flexibilidade em comparação com a codificação rígida de valores. No próximo artigo, exploraremos técnicas intermediárias para modularizar ainda mais a infraestrutura e lidar com cenários mais dinâmicos.

---

*Imagem de capa: Logo oficial do Terraform — [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Terraform-logo.png)*

**Referências:**

1. [yamldecode - Functions - Configuration Language | Terraform by HashiCorp](https://developer.hashicorp.com/terraform/language/functions/yamldecode)

---

*Publicado originalmente em [dev.to/apsis-cc](https://dev.to/apsis-cc/terraform-e-yaml-introducao-e-configuracao-basica-por-ambiente-25bg).*

