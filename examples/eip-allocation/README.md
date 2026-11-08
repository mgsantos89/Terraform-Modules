# Exemplo: `eip-allocation`

Aloca um **Elastic IP** (domínio VPC) usando o módulo [`EIP`](../../modules/EIP).

Por padrão o IP é só **alocado**, sem associação. A associação a uma instância EC2 é opcional e está explicada [mais abaixo](#-associando-a-uma-instância-ec2).

O IP recebe o nome `<prefixo_projeto>-eip` e as tags `Environment`, `Project` e `ManagedBy = "Terraform"`.

> 💰 **Atenção a custos:** a AWS cobra por endereço IPv4 público, inclusive Elastic IPs alocados e não associados. Destrua o recurso quando não precisar mais.

---

## 📋 Pré-requisitos

- Terraform `>= 1.5`
- Credenciais AWS configuradas (`aws configure`, `AWS_PROFILE` ou variáveis de ambiente)
- Permissão para alocar Elastic IPs (fique atento à cota da conta, que por padrão é 5 por região)

---

## 📁 Arquivos

| Arquivo | Versionado | Descrição |
|---------|:----------:|-----------|
| `module.tf` | ✅ | Chamada do módulo `EIP` |
| `variables.tf` | ✅ | Variáveis do exemplo |
| `example.tfvars` | ✅ | Modelo de valores, com placeholders |
| `providers.tf` | ❌ | Configuração do provider AWS. **Você cria** (passo 2) |
| `local.tfvars` | ❌ | Seus valores reais. **Você cria** (passo 3) |

---

## 🚀 Passo a passo

### 1. Copie o exemplo

```bash
git clone https://github.com/mgsantos89/Terraform-Modules.git
cp -r Terraform-Modules/examples/eip-allocation ./meu-eip
cd meu-eip
```

> Para usar no seu próprio projeto, basta copiar os arquivos `module.tf` e `variables.tf`. O módulo é baixado direto do GitHub pelo `source`.

### 2. Crie o `providers.tf`

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.38.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # ajuste para a sua região
}
```

> 🔐 Não coloque `access_key` ou `secret_key` nesse arquivo. Use `AWS_PROFILE` ou variáveis de ambiente.

### 3. Crie o seu arquivo de variáveis

```bash
cp example.tfvars local.tfvars
```

Edite o `local.tfvars`:

```hcl
prefixo_projeto = "meu-projeto"
environment     = "dev"
```

| Variável | Obrigatória | Padrão | Descrição |
|----------|:-----------:|--------|-----------|
| `prefixo_projeto` | ✅ | — | Prefixo do projeto. Vira o nome `<prefixo>-eip` e a tag `Project` |
| `environment` | | `test` | Ambiente (tag `Environment`) |

### 4. Rode o Terraform

```bash
terraform init
terraform plan  -var-file=local.tfvars
terraform apply -var-file=local.tfvars
```

### 5. Veja o resultado

O exemplo não tem `outputs.tf`. Para ver o IP alocado:

```bash
terraform state show module.eip.aws_eip.this
```

Se preferir que os valores apareçam ao final do `apply`, crie um `outputs.tf`:

```hcl
output "allocation_id"  { value = module.eip.allocation_id }
output "public_ip"      { value = module.eip.public_ip }
output "association_id" { value = module.eip.association_id }
```

### 6. Destrua o ambiente

```bash
terraform destroy -var-file=local.tfvars
```

---

## 🔗 Associando a uma instância EC2

O `module.tf` já traz a linha `instance_id` comentada. Há duas formas de usá-la.

### Opção A: instância que já existe

Adicione a variável no `variables.tf`:

```hcl
variable "instance_id" {
  description = "ID da instância EC2 para associar o EIP"
  type        = string
  default     = null
}
```

Descomente a linha no `module.tf`:

```hcl
  instance_id = var.instance_id
```

E informe o valor no `local.tfvars`:

```hcl
instance_id = "i-xxxxxxxxxxxxxxxxx"
```

### Opção B: junto com o módulo EC2

Crie a instância e o EIP no mesmo projeto, ligando os dois pelo output `instance_id`:

```hcl
module "ec2" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EC2?ref=main"

  name      = "${var.prefixo_projeto}-web"
  ami_id    = var.ami_id
  subnet_id = var.subnet_id
}

module "eip" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EIP?ref=main"

  name        = "${var.prefixo_projeto}-eip"
  instance_id = module.ec2.instance_id
}
```

Nesse caso a instância pode ficar com `associate_public_ip_address = false`, já que o IP público vem do EIP. Veja também o exemplo [ec2-basic](../ec2-basic/README.md).

---

## 🔧 Replicando

### Vários IPs no mesmo projeto

Use `for_each` no módulo:

```hcl
module "eip" {
  source   = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EIP?ref=main"
  for_each = toset(["web", "api"])

  name = "${var.prefixo_projeto}-${each.key}-eip"

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}
```

### Vários ambientes

Use um arquivo de variáveis e um state separado para cada ambiente, por exemplo com workspaces:

```bash
terraform workspace new dev
terraform apply -var-file=dev.tfvars

terraform workspace new prod
terraform apply -var-file=prod.tfvars
```

### Fixando a versão do módulo

O `source` usa `?ref=main`. Em ambientes reais, troque por uma tag assim que houver uma publicada (por exemplo `?ref=v1.0.0`) e rode `terraform init -upgrade`.
