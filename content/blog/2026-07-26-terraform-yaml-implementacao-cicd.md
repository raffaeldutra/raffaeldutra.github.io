+++
type = "blog"
date = "2026-07-26"
title = "Terraform e YAML - Implementação Prática em Projetos de CI/CD"
slug = "terraform-yaml-implementacao-cicd"
tags = [ "terraform", "cloud", "iac", "yaml" ]
categories = [
  "infrastructure",
  "terraform",
]

draft = false
+++

## 1. Introdução: Conectando IaC e Automação

Nos artigos anteriores desta série, exploramos a poderosa combinação de Terraform e YAML para gerenciar configurações de infraestrutura em múltiplos ambientes, desde os conceitos básicos até padrões avançados de deep merge e modularização. No entanto, a verdadeira força da Infraestrutura como Código (IaC) se manifesta quando integrada a um pipeline de Integração Contínua e Entrega Contínua (CI/CD). É no CI/CD que a promessa de provisionamento automatizado, consistente e seguro da infraestrutura se torna realidade.

<!--more-->

Este artigo se aprofundará na implementação prática desses conceitos em um projeto real de CI/CD. Abordaremos a estrutura ideal do repositório, as etapas essenciais de um pipeline, estratégias de branching, considerações de segurança e as melhores práticas para garantir que sua infraestrutura seja implantada de forma eficiente e confiável.

## 2. Estrutura do Repositório para CI/CD Eficaz

Uma estrutura de repositório bem definida é crucial para a organização e automação em um ambiente de CI/CD. Ela deve refletir a separação entre código Terraform e dados YAML, além de acomodar múltiplos ambientes e serviços.

```plaintext
. (root do repositório)
├── README.md
├── .github/workflows/ # Ou .gitlab-ci/, .azure-pipelines/, etc.
│   └── terraform.yml
├── terraform/ # Código Terraform genérico e módulos
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── vpc/
│       │   ├── main.tf
│       │   └── variables.tf
│       └── webserver/
│           ├── main.tf
│           └── variables.tf
└── config/ # Dados de configuração YAML por ambiente/serviço
    ├── global.yaml
    ├── environments/
    │   ├── dev/
    │   │   ├── base.yaml
    │   │   └── services/
    │   │       ├── webapp.yaml
    │   │       └── database.yaml
    │   ├── staging/
    │   │   ├── base.yaml
    │   │   └── services/
    │   │       ├── webapp.yaml
    │   │       └── database.yaml
    │   └── prod/
    │       ├── base.yaml
    │       └── services/
    │           ├── webapp.yaml
    │           └── database.yaml
    └── services/
        ├── defaults/
        │   ├── webapp.yaml
        │   └── database.yaml
        └── overrides/
            ├── webapp-prod.yaml
            └── database-dev.yaml
```

**Explicação da Estrutura:**

- **`terraform/`**: Contém todo o código HCL (HashiCorp Configuration Language) que define a infraestrutura. Este código deve ser o mais genérico possível, utilizando variáveis para aceitar as configurações dos arquivos YAML. Os módulos (`modules/`) encapsulam recursos reutilizáveis.

- **`config/`**: Armazena todos os arquivos YAML que contêm os dados de configuração específicos. A organização hierárquica (`global`, `environments`, `services`) permite uma gestão granular e a aplicação de deep merge, conforme discutido no Artigo 3.

- **`.github/workflows/`**: Contém as definições do pipeline de CI/CD (neste exemplo, usando GitHub Actions). O arquivo `terraform.yml` orquestrará as etapas de validação, planejamento e aplicação do Terraform.

## 3. O Pipeline de CI/CD: Etapas Essenciais

Um pipeline de CI/CD robusto para Terraform deve incluir etapas que garantam a qualidade, segurança e consistência das implantações. Vamos detalhar as etapas cruciais, usando GitHub Actions como exemplo, mas os princípios se aplicam a qualquer plataforma de CI/CD.

### 3.1. Definição do Pipeline (`.github/workflows/terraform.yml`)

```yaml
name: Terraform Infrastructure Deployment

on:
  push:
    branches:
      - main
      - develop
      - feature/*
  pull_request:
    branches:
      - main
      - develop

env:
  TF_VAR_aws_region: us-east-1 # Variável de ambiente padrão para a região AWS

jobs:
  terraform:
    runs-on: ubuntu-latest
    environment: # Define ambientes para proteção e segredos
      name: ${{ github.ref == 'refs/heads/main' && 'production' || (github.ref == 'refs/heads/develop' && 'staging' || 'development') }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.TF_VAR_aws_region }}

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
            echo "ENVIRONMENT=staging" >> "$GITHUB_OUTPUT"
          else
            echo "ENVIRONMENT=dev" >> "$GITHUB_OUTPUT"
          fi

      - name: Terraform Init
        id: init
        run: terraform init -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" -backend-config="key=${{ steps.set_env.outputs.ENVIRONMENT }}/terraform.tfstate" -backend-config="region=${{ env.TF_VAR_aws_region }}"

      - name: Terraform Validate
        id: validate
        run: terraform validate

      - name: Terraform Plan
        id: plan
        run: terraform plan -var="environment=${{ steps.set_env.outputs.ENVIRONMENT }}" -out=tfplan
        continue-on-error: true # Permite que o pipeline continue para exibir o plano mesmo com erros

      - name: Show Terraform Plan
        run: terraform show -no-color tfplan

      - name: Terraform Apply (Auto-approve for main branch)
        if: success() && github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve tfplan

      - name: Terraform Apply (Manual approval for develop/feature branches)
        if: success() && github.ref != 'refs/heads/main'
        run: |
          echo "Para aplicar as mudanças no ambiente ${{ steps.set_env.outputs.ENVIRONMENT }}, execute manualmente:"
          echo "terraform apply tfplan"
          # Em um pipeline real, você usaria um passo de aprovação manual ou um ambiente de revisão aqui

      - name: Post-deployment Tests (Optional)
        if: success()
        run: |
          echo "Executando testes pós-implantação..."
          # Ex: InSpec, Terratest, ou scripts de validação de API
```

### 3.2. Detalhamento das Etapas do Pipeline

1. **`Checkout code`**: Clona o repositório para o ambiente do executor do pipeline.

1. **`Configure AWS Credentials`**: Configura as credenciais para o provedor de nuvem (AWS neste caso) usando segredos do CI/CD. É crucial que essas credenciais tenham as permissões mínimas necessárias para o ambiente alvo. [1]

1. **`Setup Terraform`**: Instala a versão específica do Terraform CLI no executor.

1. **`Determine Environment`**: Esta etapa é fundamental. Ela define qual ambiente (dev, staging, prod) será alvo da implantação com base na branch atual. Por exemplo, `main` para produção, `develop` para staging e branches de `feature/*` para desenvolvimento. O output `ENVIRONMENT` será usado nas etapas subsequentes.

1. **`Terraform Init`**: Inicializa o diretório de trabalho do Terraform. Aqui, configuramos o backend remoto (ex: S3) para armazenar o estado do Terraform. O `key` do backend é dinamicamente definido para isolar os estados por ambiente (`${{ steps.set_env.outputs.ENVIRONMENT }}/terraform.tfstate`). Isso garante que cada ambiente tenha seu próprio arquivo de estado, evitando conflitos. [2]

1. **`Terraform Validate`**: Verifica a sintaxe dos arquivos de configuração e a validade dos argumentos. É uma verificação rápida e essencial para pegar erros básicos antes de prosseguir.

1. **`Terraform Plan`**: Gera um plano de execução, mostrando quais recursos serão adicionados, modificados ou destruídos. O `-var="environment=..."` garante que o plano seja gerado com base nas configurações YAML do ambiente correto. O `-out=tfplan` salva o plano para ser usado na etapa de `apply`. É uma boa prática que esta etapa seja sempre executada, mesmo que o `apply` exija aprovação manual. [3]

1. **`Show Terraform Plan`**: Exibe o conteúdo do plano gerado. Isso é útil para revisões de código e para que os desenvolvedores e operadores possam entender as mudanças propostas antes da aplicação.

1. **`Terraform Apply (Auto-approve for main branch)`**: Aplica o plano gerado. Para a branch `main` (produção), pode-se configurar para ser `auto-approve` após a revisão do plano, ou, mais comumente, exigir uma aprovação manual para maior segurança. A condição `if: success() && github.ref == 'refs/heads/main'` garante que o `apply` automático só ocorra na branch principal e apenas se as etapas anteriores foram bem-sucedidas.

1. **`Terraform Apply (Manual approval for develop/feature branches)`**: Para branches de desenvolvimento ou staging, o `apply` pode ser manual ou condicionado a um processo de revisão. Em ambientes de CI/CD mais avançados, esta etapa pode ser substituída por um ambiente de revisão efêmero ou um passo de aprovação manual explícito.

1. **`Post-deployment Tests (Optional)`**: Após a implantação, é crucial executar testes automatizados para validar a funcionalidade da infraestrutura. Ferramentas como InSpec, Terratest ou scripts personalizados podem verificar se os recursos foram provisionados corretamente e estão operacionais. [4]

## 4. Estratégias de Branching e Fluxo de Trabalho

A escolha da estratégia de branching impacta diretamente como o CI/CD interage com seus ambientes. As mais comuns são:

- **GitFlow:** Utiliza branches `main` (produção), `develop` (staging) e `feature/*` (desenvolvimento). Cada merge para `develop` aciona a implantação em staging, e merges para `main` acionam a implantação em produção. Exige um gerenciamento de branches mais rigoroso.

- **Trunk-Based Development:** Foca em uma única branch principal (`main`) com commits frequentes e pequenos. Ambientes são diferenciados por tags ou variáveis. Mais ágil, mas exige alta confiança nos testes automatizados.

Para a abordagem de Terraform com YAML, o GitFlow (ou uma variação dele) é frequentemente preferido, pois mapeia naturalmente as branches aos ambientes, simplificando a lógica de seleção de ambiente no pipeline.

## 5. Considerações de Segurança no Pipeline de CI/CD

A segurança é primordial ao automatizar a implantação de infraestrutura.

- **Princípio do Menor Privilégio:** As credenciais de nuvem usadas pelo pipeline devem ter apenas as permissões mínimas necessárias para provisionar e gerenciar os recursos do ambiente alvo. Nunca use credenciais de administrador.

- **Segredos do CI/CD:** Armazene todas as informações sensíveis (chaves de API, segredos de nuvem, tokens) como segredos no seu sistema de CI/CD (ex: GitHub Secrets, GitLab CI/CD Variables, Azure Key Vault). Nunca as coloque diretamente nos arquivos do repositório.

- **State Locking e Backend Remoto:** Utilize um backend remoto (ex: AWS S3 com DynamoDB, Azure Storage Account, HashiCorp Consul) para armazenar o estado do Terraform. Configure o state locking para evitar que múltiplas execuções do Terraform corrompam o estado simultaneamente. [5]

- **Revisão de Código e Planos:** Implemente revisões de código (Pull Requests/Merge Requests) para todas as mudanças no código Terraform e nos arquivos YAML. Exija que o plano do Terraform seja revisado antes de ser aplicado, especialmente em ambientes de produção.

- **Ferramentas de Análise Estática:** Integre ferramentas como `terraform validate`, `tflint`, `checkov` ou `terrascan` ao seu pipeline para identificar problemas de sintaxe, segurança e conformidade antes da implantação. [6]

## 6. Boas Práticas e Dicas Adicionais

- **Idempotência:** Garanta que suas configurações Terraform sejam idempotentes, ou seja, que a aplicação repetida do mesmo plano resulte no mesmo estado da infraestrutura, sem efeitos colaterais indesejados.

- **Rollback:** Tenha uma estratégia clara de rollback. Em caso de falha na implantação, como você reverte para um estado anterior estável? O Terraform Cloud e outras ferramentas oferecem funcionalidades de rollback, mas é importante entender como elas funcionam com seu pipeline.

- **Monitoramento e Alerta:** Configure monitoramento e alertas para a infraestrutura provisionada. Isso ajuda a identificar problemas rapidamente após uma implantação.

- **Documentação:** Mantenha a documentação atualizada sobre a estrutura do repositório, o funcionamento do pipeline e as convenções de configuração YAML.

- **Testes de Infraestrutura:** Além dos testes pós-implantação, considere testes de unidade e integração para seus módulos Terraform usando ferramentas como Terratest. [4]

## 7. Conclusão

A integração de Terraform com arquivos YAML em um pipeline de CI/CD é uma prática fundamental para qualquer equipe que busca excelência em DevOps. Ao estruturar seu repositório de forma inteligente, definir um pipeline robusto com etapas claras, adotar estratégias de branching adequadas e priorizar a segurança, você pode automatizar o provisionamento de infraestrutura de forma consistente, escalável e confiável. Esta abordagem não apenas acelera o ciclo de entrega, mas também eleva a qualidade e a resiliência de seus ambientes, permitindo que as equipes se concentrem na inovação em vez de tarefas manuais repetitivas.

---

*Imagem de capa: Logo oficial do Terraform — [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Terraform-logo.png)*

**Referências:**

1. [Configuring AWS Credentials in GitHub Actions - AWS](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)

1. [Terraform State - HashiCorp Learn](https://developer.hashicorp.com/terraform/language/state)

1. [Terraform CLI: terraform plan - HashiCorp Learn](https://developer.hashicorp.com/terraform/cli/commands/plan)

1. [Terratest: Go library for testing Terraform, Packer, Docker, and more](https://terratest.gruntwork.io/)

1. [State Locking - Terraform Documentation](https://developer.hashicorp.com/terraform/language/state/locking)

1. [Static Analysis for Terraform - HashiCorp Learn](https://developer.hashicorp.com/terraform/tutorials/cli/static-analysis)

---

*Publicado originalmente em [dev.to/apsis-cc](https://dev.to/apsis-cc/terraform-e-yaml-implementacao-pratica-em-projetos-de-cicd-5h97).*

