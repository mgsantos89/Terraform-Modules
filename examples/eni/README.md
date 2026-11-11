# Exemplo: `eni`

Cria uma **Elastic Network Interface (ENI)** secundária usando o módulo [`ENI`](../../modules/ENI).

Por padrão a interface é só **criada** na subnet, sem anexo. Anexar a uma instância EC2, fixar IPs privados e associar Security Groups são opções explicadas [mais abaixo](#-opções-avançadas).

A ENI recebe o nome `<prefixo_projeto>-eni` e as tags `Environment`, `Project` e `ManagedBy = "Terraform"`.

> 💡 **Quando usar uma ENI secundária:** separar tráfego de gerência e de dados, ter um IP privado fixo que pode ser movido entre instâncias (failover) ou colocar uma instância em duas subnets da mesma AZ.

---

## 📋 Pré-requisitos

- Terraform `>= 1.5`
- Credenciais AWS configuradas (`aws configure`, `AWS_PROFILE` ou variáveis de ambiente)
- Uma VPC existente com uma subnet para a ENI
- Para anexar a uma instância: a instância precisa estar na **mesma AZ** da subnet e o tipo de instância precisa suportar mais de uma interface

---

## 📁 Arquivos

| Arquivo | Versionado | Descrição |
|---------|:----------:|-----------|
| `module.tf` | ✅ | Chamada do módulo `ENI` |
| `variables.tf` | ✅ | Variáveis do exemplo |
| `example.tfvars` | ✅ | Modelo de valores, com placeholders |
| `providers.tf` | ❌ | Configuração do provider AWS. **Você cria** (passo 2) |
| `local.tfvars` | ❌ | Seus valores reais. **Você cria** (passo 3) |

---

## 🚀 Passo a passo

### 1. Copie o exemplo

```bash
git clone https://github.com/mgsantos89/Terraform-Modules.git
cp -r Terraform-Modules/examples/eni ./minha-eni
cd minha-eni
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
prefixo_projeto    = "meu-projeto"
subnet_id          = "subnet-xxxxxxxxxxxxxxxxx"
security_group_ids = ["sg-xxxxxxxxxxxxxxxxx"]
environment        = "dev"
```

| Variável | Obrigatória | Padrão | Descrição |
|----------|:-----------:|--------|-----------|
| `prefixo_projeto` | ✅ | — | Prefixo do projeto. Vira o nome `<prefixo>-eni` e a tag `Project` |
| `subnet_id` | ✅ | — | ID da subnet onde a ENI será criada |
| `environment` | | `test` | Ambiente (tag `Environment`) |
| `security_group_ids` | | `[]` | Lista de IDs dos Security Groups. Vazio usa o Security Group default da VPC |

### 4. Rode o Terraform

```bash
terraform init
terraform plan  -var-file=local.tfvars
terraform apply -var-file=local.tfvars
```

### 5. Veja o resultado

O exemplo não tem `outputs.tf`. Para ver a ENI criada:

```bash
terraform state show module.eni.aws_network_interface.this
```

Se preferir que os valores apareçam ao final do `apply`, crie um `outputs.tf`:

```hcl
output "eni_id"        { value = module.eni.eni_id }
output "private_ips"   { value = module.eni.private_ips }
output "mac_address"   { value = module.eni.mac_address }
output "attachment_id" { value = module.eni.attachment_id }
```

### 6. Destrua o ambiente

```bash
terraform destroy -var-file=local.tfvars
```

---

## 🔧 Opções avançadas

O `module.tf` já traz `private_ips`, `instance_id` e `device_index` comentados.

### IPs privados fixos

Por padrão a AWS escolhe um IP livre da subnet. Para fixar um ou mais IPs, descomente `private_ips` e use endereços que pertençam ao CIDR da subnet:

```hcl
  private_ips = [
    "10.0.1.100",
    "10.0.1.101"
  ]
```

> ⚠️ Mudar `private_ips` depois de criada pode recriar a ENI. Confira o `plan` antes do `apply`.

### Security Groups

Se `security_group_ids` ficar vazio (padrão), a ENI recebe o Security Group **default** da VPC. Para usar os seus, informe a lista no `local.tfvars`:

```hcl
security_group_ids = ["sg-xxxxxxxxxxxxxxxxx", "sg-yyyyyyyyyyyyyyyyy"]
```

Para criar o grupo junto, use o módulo [`SecurityGroup`](../../modules/SecurityGroup) e passe `[module.sg.security_group_id]`.

### Anexando a uma instância EC2

Quando `instance_id` é informado, o módulo também cria um `aws_network_interface_attachment`. O `device_index` padrão é `1` (a interface primária da instância é sempre a `0`, por isso o módulo não aceita valores menores que `1`).

```hcl
module "ec2" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EC2?ref=main"

  name      = "${var.prefixo_projeto}-web"
  ami_id    = var.ami_id
  subnet_id = var.subnet_id
}

module "eni" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/ENI?ref=main"

  name      = "${var.prefixo_projeto}-eni"
  subnet_id = var.subnet_id

  instance_id  = module.ec2.instance_id
  device_index = 1
}
```

> 💡 Para anexar a uma instância que já existe, crie uma variável `instance_id` e informe `i-xxxxxxxxxxxxxxxxx` no `local.tfvars`.

### `source_dest_check`

Fica `true` por padrão: a ENI só aceita tráfego cujo destino ou origem seja ela mesma. Use `false` apenas quando a instância encaminha tráfego de terceiros (NAT instance, firewall, VPN, roteador).

---

## 🔁 Replicando

### Várias ENIs no mesmo projeto

Use `for_each` no módulo:

```hcl
module "eni" {
  source   = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/ENI?ref=main"
  for_each = toset(["mgmt", "data"])

  name      = "${var.prefixo_projeto}-${each.key}-eni"
  subnet_id = var.subnet_id

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}
```

> Se anexar várias ENIs na mesma instância, cada uma precisa de um `device_index` diferente.

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
