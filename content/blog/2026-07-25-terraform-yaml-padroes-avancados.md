+++
type = "blog"
date = "2026-07-25"
title = "Terraform e YAML - Padrões Avançados e Escalabilidade"
slug = "terraform-yaml-padroes-avancados"
tags = [ "terraform", "cloud", "iac", "yaml" ]
categories = [
  "infrastructure",
  "terraform",
]

draft = false
+++

## 1. Introdução: Rumo à Infraestrutura como Código de Nível Empresarial

Nos artigos anteriores desta série, estabelecemos os fundamentos da separação de código e dados no Terraform com YAML (Artigo 1) e exploramos técnicas intermediárias de modularização e provisionamento dinâmico (Artigo 2). Agora, no terceiro e último artigo, mergulharemos em padrões avançados que são essenciais para gerenciar infraestruturas complexas e escaláveis em ambientes corporativos. O foco será em como lidar com hierarquias de configuração intrincadas, mesclar dados de forma inteligente e integrar essa abordagem em fluxos de trabalho de CI/CD.

<!--more-->

À medida que a infraestrutura cresce, a necessidade de abstração e automação se torna ainda mais crítica. Este artigo abordará:

- **Deep Merge de Configurações:** Como combinar dados de múltiplos arquivos YAML de forma hierárquica, onde configurações mais específicas sobrescrevem as mais genéricas.

- **Gerenciamento de Múltiplos Arquivos YAML:** Estratégias para organizar e carregar configurações de diferentes escopos (global, ambiente, serviço, região).

- **Integração com CI/CD:** Como automatizar o processo de implantação de infraestrutura usando essa abordagem em pipelines de integração contínua e entrega contínua.

## 2. Deep Merge de Configurações: Mesclando Dados Hierarquicamente

Um dos maiores desafios ao gerenciar configurações em múltiplos níveis (global, ambiente, serviço) é a necessidade de mesclar mapas de formaprofunda, onde valores de níveis mais baixos (mais específicos) sobrescrevem ou complementam valores de níveis mais altos (mais genéricos ou padrões). A função `merge` nativa do Terraform realiza uma mesclagem superficial, o que significa que ela apenas mescla o primeiro nível de chaves, e se uma chave existir em ambos os mapas, o valor do segundo mapa prevalece. Para mapas aninhados, isso não é suficiente. [1]

### 2.1. O Desafio do `merge` Superficial

Considere a seguinte estrutura de configuração:

**`config/global.yaml`:**

```yaml
webserver:
  instance_type: t2.micro
  min_size: 1
  max_size: 5
  tags:
    Project: MyWebApp
    ManagedBy: Terraform
database:
  engine: postgres
  version: "13"
  storage: 50
```

**`config/environments/prod.yaml`:**

```yaml
webserver:
  instance_type: m5.large
  max_size: 10
  tags:
    Environment: Production
```

Se aplicarmos um `merge` superficial diretamente:

```terraform
locals {
  global_config = yamldecode(file("${path.module}/config/global.yaml"))
  prod_config   = yamldecode(file("${path.module}/config/environments/prod.yaml"))

  # Mesclagem superficial
  merged_config_shallow = merge(local.global_config, local.prod_config)
}

output "shallow_merged_webserver_tags" {
  # Isso resultaria apenas em { Environment = "Production" }, perdendo Project e ManagedBy
  value = local.merged_config_shallow.webserver.tags
}
```

O resultado de `merged_config_shallow.webserver.tags` seria apenas `{ Environment = "Production" }`, pois o mapa `tags` do `prod_config` sobrescreveria completamente o mapa `tags` do `global_config`. Os valores `Project` e `ManagedBy` seriam perdidos. Isso não é o comportamento desejado para umdeep merge.

### 2.2. Implementando um Deep Merge

Para realizar um deep merge, precisamos de uma lógica que itere recursivamente sobre os mapas aninhados, aplicando a mesclagem em cada nível. O Terraform não possui uma função `deep_merge` nativa, mas a comunidade desenvolveu módulos que abstraem essa complexidade ou podemos construir uma lógica manual para casos específicos. [2]

Uma abordagem comum é usar um módulo auxiliar ou construir a lógica de mesclagem manualmente para cada nível aninhado que precisa de um deep merge. Por exemplo, para as tags do `webserver`:

```terraform
locals {
  global_config = yamldecode(file("${path.module}/config/global.yaml"))
  env_config    = yamldecode(file("${path.module}/config/environments/${var.environment}.yaml"))

  # Mesclagem profunda para as tags do webserver
  merged_webserver_tags = merge(
    lookup(local.global_config.webserver, "tags", {}),
    lookup(local.env_config.webserver, "tags", {})
  )

  # Mesclagem profunda para o bloco webserver
  merged_webserver_config = merge(
    local.global_config.webserver,
    lookup(local.env_config, "webserver", {}),
    {
      tags = local.merged_webserver_tags
    }
  )

  # Configuração final, aplicando deep merge onde necessário
  final_config = merge(
    local.global_config,
    local.env_config,
    {
      webserver = local.merged_webserver_config
    }
  )
}

output "deep_merged_webserver_tags" {
  value = local.final_config.webserver.tags
  # Resultado esperado: { Project = "MyWebApp", ManagedBy = "Terraform", Environment = "Production" }
}

output "deep_merged_webserver_instance_type" {
  value = local.final_config.webserver.instance_type
  # Resultado esperado para prod: m5.large
}

output "deep_merged_database_storage" {
  value = local.final_config.database.storage
  # Resultado esperado para prod: 50 (não sobrescrito no prod.yaml)
}
```

Neste exemplo, usamos `lookup` para garantir que, se um bloco como `webserver` ou `tags` não existir no `env_config`, um mapa vazio seja usado para evitar erros. Em seguida, aplicamos `merge` sequencialmente para construir a configuração final, garantindo que as tags sejam mescladas profundamente.

Para um deep merge mais genérico e reutilizável, especialmente em estruturas de dados muito aninhadas, é altamente recomendável utilizar módulos da comunidade. O módulo `cloudposse/config/yaml` [3] é um exemplo popular que oferece funcionalidades de deep merge para arquivos YAML, simplificando significativamente a lógica no seu `main.tf`.

## 3. Gerenciamento de Múltiplos Arquivos YAML para Hierarquias Complexas

Em projetos grandes, ter um único arquivo YAML por ambiente pode se tornar impraticável. É comum dividir as configurações em múltiplos arquivos, organizados por escopo (global, ambiente, serviço, região, etc.). Isso melhora a organização, a legibilidade e a colaboração.

### 3.1. Estrutura de Diretórios Hierárquica

Considere a seguinte estrutura de diretórios para gerenciar configurações de forma mais granular:

```plaintext
. (root)
├── main.tf
├── config/
│   ├── global.yaml
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── base.yaml
│   │   │   └── services/
│   │   │       ├── webapp.yaml
│   │   │       └── database.yaml
│   │   └── prod/
│   │       ├── base.yaml
│   │       └── services/
│   │           ├── webapp.yaml
│   │           └── database.yaml
│   └── services/
│       ├── defaults/
│       │   ├── webapp.yaml
│       │   └── database.yaml
│       └── overrides/
│           ├── webapp-prod.yaml
│           └── database-dev.yaml
```

Nesta estrutura, podemos ter:

- `global.yaml`: Configurações que se aplicam a todos os ambientes e serviços.

- `environments/<env>/base.yaml`: Configurações base para um ambiente específico, que podem sobrescrever o `global.yaml`.

- `environments/<env>/services/*.yaml`: Configurações específicas de serviço dentro de um ambiente, que sobrescrevem as configurações base do ambiente e as globais.

- `services/defaults/*.yaml`: Padrões para serviços que podem ser usados como base.

- `services/overrides/*.yaml`: Sobrescritas pontuais para serviços em ambientes específicos, com a maior precedência.

### 3.2. Carregando e Mesclando Múltiplos Arquivos YAML

Para carregar e mesclar esses múltiplos arquivos de forma hierárquica, você precisará de uma lógica mais elaborada no seu `main.tf` (ou em um `locals.tf` dedicado). Isso geralmente envolve:

1. Identificar todos os arquivos YAML relevantes para o ambiente atual.

1. Ler o conteúdo de cada arquivo usando `file()` e `yamldecode()`.

1. Aplicar uma sequência de `merge` (ou um deep merge mais sofisticado) para combinar os mapas, respeitando a precedência (do mais genérico para o mais específico).

Um exemplo simplificado de como você poderia carregar e mesclar arquivos para um ambiente específico:

```terraform
variable "environment" {
  description = "O ambiente alvo."
  type        = string
  default     = "dev"
}

locals {
  # 1. Carrega a configuração global
  global_config = yamldecode(file("${path.module}/config/global.yaml"))

  # 2. Carrega a configuração base do ambiente
  env_base_path   = "${path.module}/config/environments/${var.environment}/base.yaml"
  env_base_config = fileexists(local.env_base_path) ? yamldecode(file(local.env_base_path)) : {}

  # 3. Carrega configurações de serviço específicas do ambiente
  env_service_configs = {
    for f in fileset("${path.module}/config/environments/${var.environment}/services", "*.yaml") :
    basename(f, ".yaml") => yamldecode(file("${path.module}/config/environments/${var.environment}/services/${f}"))
  }

  # Mesclagem inicial: global + base do ambiente
  merged_base_config = merge(local.global_config, local.env_base_config)

  # Mesclagem final: base mesclada + configurações de serviço (deep merge seria necessário aqui)
  # Esta é uma mesclagem superficial para fins de demonstração.
  # Para um deep merge completo de todos os serviços, a lógica seria mais complexa.
  final_env_config = merge(local.merged_base_config, local.env_service_configs)
}

output "final_config_example" {
  value = local.final_env_config
}
```

Neste exemplo, `fileset` é usado para encontrar todos os arquivos YAML dentro do diretório de serviços do ambiente, e um `for` expression os carrega em um mapa. A mesclagem final ainda precisaria de uma lógica de deep merge para lidar com mapas aninhados dentro das configurações de serviço. Módulos como o `cloudposse/config/yaml` são projetados para lidar com essa complexidade de forma mais elegante e robusta, permitindo que você especifique uma ordem de precedência para os arquivos YAML e ele se encarregue do deep merge. [3]

## 4. Integração com CI/CD: Automatizando Implantações Multi-Ambiente

A verdadeira força da separação de código e dados com YAML se manifesta quando integrada a um pipeline de Integração Contínua/Entrega Contínua (CI/CD). Isso permite automatizar o provisionamento e a atualização da infraestrutura para diferentes ambientes de forma segura e consistente.

### 4.1. Fluxo de Trabalho Típico em CI/CD

Um pipeline de CI/CD para Terraform com configurações YAML pode seguir os seguintes passos:

1. **Trigger:** Um push para o repositório Git (ou um merge request) aciona o pipeline.

1. **Checkout:** O código Terraform e os arquivos YAML são clonados.

1. **Seleção de Ambiente:** O pipeline determina o ambiente alvo (ex: `dev`, `staging`, `prod`) com base no branch, tag, ou uma variável de pipeline.

1. **Inicialização do Terraform:** `terraform init` é executado para baixar provedores e módulos.

1. **Validação:** `terraform validate` verifica a sintaxe e a consistência do código.

1. **Planejamento:** `terraform plan -var="environment=<ambiente>"` (ou `-var-file`) é executado para gerar um plano de execução. Este plano pode ser revisado manualmente (em ambientes de produção) ou automaticamente aprovado.

1. **Aplicação:** `terraform apply -var="environment=<ambiente>"` (ou `-var-file`) é executado para aplicar as mudanças na infraestrutura.

1. **Testes Pós-Implantação:** Testes automatizados podem ser executados para verificar a funcionalidade da infraestrutura provisionada.

### 4.2. Exemplo de Pipeline (GitHub Actions)

```yaml
name: Terraform Multi-Environment Deployment

on:
  push:
    branches:
      - main
      - develop

env:
  AWS_REGION: us-east-1 # Região padrão, pode ser sobrescrita pelo YAML

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.x.x

      - name: Determine Environment
        id: set_env
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "ENVIRONMENT=prod" >> "$GITHUB_OUTPUT"
          elif [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
            echo "ENVIRONMENT=dev" >> "$GITHUB_OUTPUT"
          else
            echo "ENVIRONMENT=staging" >> "$GITHUB_OUTPUT"
          fi

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        id: plan
        run: terraform plan -var="environment=${{ steps.set_env.outputs.ENVIRONMENT }}" -out=tfplan
        continue-on-error: true

      - name: Terraform Apply
        if: success() && github.ref == 'refs/heads/main' # Auto-apply apenas para main (produção)
        run: terraform apply -auto-approve tfplan

      - name: Terraform Apply (Manual Approval for other environments)
        if: success() && github.ref != 'refs/heads/main'
        run: |
          echo "Para aplicar as mudanças no ambiente ${{ steps.set_env.outputs.ENVIRONMENT }}, execute manualmente:"
          echo "terraform apply tfplan"
          # Em um pipeline real, você usaria um passo de aprovação manual aqui
```

**Considerações para CI/CD:**

- **Segurança:** Utilize segredos do CI/CD (GitHub Secrets, GitLab CI/CD Variables) para armazenar credenciais sensíveis (chaves AWS, etc.). Nunca as exponha diretamente nos arquivos de configuração ou no código.

- **Aprovações Manuais:** Para ambientes de produção, é uma boa prática exigir aprovação manual antes de executar o `terraform apply`.

- **State Locking:** Certifique-se de que seu backend Terraform (ex: S3 com DynamoDB) esteja configurado para state locking para evitar conflitos em execuções concorrentes.

- **Testes:** Integre testes de infraestrutura (ex: Terratest, InSpec) ao seu pipeline para validar a infraestrutura provisionada após o `apply`.

## 5. Boas Práticas e Considerações Finais

- **Validação de Esquema YAML:** Para configurações complexas, considere usar ferramentas externas (ex: `yamllint`, `json-schema` com `yq`) ou scripts personalizados para validar o esquema dos seus arquivos YAML. Isso pode pegar erros de digitação ou estrutura antes mesmo do Terraform ser executado.

- **Segurança de Segredos:** Reforçando, nunca armazene informações sensíveis diretamente em arquivos YAML versionados. Utilize soluções como AWS Secrets Manager, HashiCorp Vault, Azure Key Vault ou variáveis de ambiente para gerenciar segredos de forma segura. O YAML deve conter apenas referências ou metadados para esses segredos.

- **Modularização Agressiva:** Quanto mais genéricos e reutilizáveis forem seus módulos Terraform, mais eficaz será a sua estratégia de configuração baseada em YAML. Pense em seus módulos como blocos de construção que são configurados pelos dados YAML.

- **Nomenclatura Consistente:** Adote uma convenção de nomenclatura clara para seus arquivos e diretórios de configuração YAML (ex: `global.yaml`, `dev.yaml`, `prod.yaml`, `service-a.yaml`).

- **Documentação:** Mantenha uma documentação clara sobre a estrutura dos seus arquivos YAML e como as configurações são mescladas e aplicadas.

## 6. Conclusão da Série

Esta série de artigos demonstrou como o Terraform, em conjunto com arquivos YAML, oferece uma abordagem poderosa e flexível para gerenciar infraestruturas como código em múltiplos ambientes. Desde os conceitos introdutórios de `yamldecode` até padrões avançados como deep merge, gerenciamento de múltiplos arquivos e integração com CI/CD, a externalização de configurações permite construir sistemas mais manuteníveis, escaláveis e alinhados com as melhores práticas de DevOps. Ao dominar essas técnicas, você estará apto a projetar e implementar arquiteturas de infraestrutura robustas que se adaptam às crescentes demandas de qualquer organização.

---

*Imagem de capa: Logo oficial do Terraform — [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Terraform-logo.png)*

**Referências:**

1. [merge - Functions - Configuration Language | Terraform by HashiCorp](https://developer.hashicorp.com/terraform/language/functions/merge)

1. [Merging complex objects? - Terraform Discuss](https://discuss.hashicorp.com/t/merging-complex-objects/2312)

1. [Submodule: deepmerge - cloudposse/config/yaml | Terraform Registry](https://registry.terraform.io/modules/cloudposse/config/yaml/0.5.0/submodules/deepmerge)

1. [fileset - Functions - Configuration Language | Terraform by Hashicorp](https://developer.hashicorp.com/terraform/language/functions/fileset)

1. [GitHub Actions: Workflow syntax for GitHub Actions - GitHub Docs](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

---

*Publicado originalmente em [dev.to/apsis-cc](https://dev.to/apsis-cc/terraform-e-yaml-padroes-avancados-e-escalabilidade-28aa).*

