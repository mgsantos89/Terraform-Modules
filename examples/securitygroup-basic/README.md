# Exemplo: `securitygroup-basic`

Cria um **Security Group** usando o módulo [`SecurityGroup`](../../modules/SecurityGroup), com:

| Direção | Regra | Protocolo / Porta | Origem / Destino |
|---------|-------|-------------------|------------------|
| Entrada | `ssh` | TCP 22 | `0.0.0.0/0` |
| Entrada | `http` | TCP 80 | `0.0.0.0/0` |
| Saída | `all_ipv4` | Todos (`-1`) | `0.0.0.0/0` |

O grupo recebe o nome `<prefixo_projeto>-sg` e as tags `Environment`, `Project` e `ManagedBy = "Terraform"`.

> 🔐 **SSH aberto para a internet é só para laboratório.** Antes de usar este exemplo em qualquer ambiente real, restrinja o `cidr_ipv4` da regra `ssh` ao seu IP (`x.x.x.x/32`) ou troque o SSH pelo [SSM Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html). Veja [Restringindo o SSH](#restringindo-o-ssh).

---

## 📋 Pré-requisitos

- Terraform `>= 1.5`
- Credenciais AWS configuradas (`aws configure`, `AWS_PROFILE` ou variáveis de ambiente)
- Permissão para criar Security Groups e regras na conta
- Uma **VPC** existente

> 💡 Para listar as VPCs da região:
> ```bash
> aws ec2 describe-vpcs --query "Vpcs[].{ID:VpcId,CIDR:CidrBlock,Default:IsDefault}" --output table
> ```

---

## 📁 Arquivos

| Arquivo | Versionado | Descrição |
|---------|:----------:|-----------|
| `module.tf` | ✅ | Chamada do módulo `SecurityGroup` com as regras |
| `variables.tf` | ✅ | Variáveis do exemplo |
| `example.tfvars` | ✅ | Modelo de valores, com placeholders |
| `providers.tf` | ❌ | Configuração do provider AWS. **Você cria** (passo 2) |
| `local.tfvars` | ❌ | Seus valores reais. **Você cria** (passo 3) |

---

## 🚀 Passo a passo

### 1. Copie o exemplo

```bash
git clone https://github.com/mgsantos89/Terraform-Modules.git
cp -r Terraform-Modules/examples/securitygroup-basic ./meu-sg
cd meu-sg
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
vpc_id          = "vpc-xxxxxxxxxxxxxxxxx"
prefixo_projeto = "meu-projeto"
environment     = "dev"
```

| Variável | Obrigatória | Padrão | Descrição |
|----------|:-----------:|--------|-----------|
| `vpc_id` | ✅ | — | ID da VPC onde o grupo será criado |
| `prefixo_projeto` | ✅ | — | Prefixo do projeto. Vira o nome `<prefixo>-sg` e a tag `Project` |
| `environment` | | `test` | Ambiente (tag `Environment`) |

### 4. Rode o Terraform

```bash
terraform init
terraform plan  -var-file=local.tfvars
terraform apply -var-file=local.tfvars
```

O `plan` deve mostrar **4 recursos**: o Security Group, 2 regras de entrada e 1 regra de saída.

### 5. Veja o resultado

O exemplo não tem `outputs.tf`. Para ver os dados do grupo:

```bash
terraform state show module.security_group.aws_security_group.this
terraform state list | grep security_group_
```

Se preferir que os valores apareçam ao final do `apply`, crie um `outputs.tf`:

```hcl
output "security_group_id"   { value = module.security_group.security_group_id }
output "security_group_name" { value = module.security_group.security_group_name }
output "security_group_arn"  { value = module.security_group.security_group_arn }
```

### 6. Destrua o ambiente

```bash
terraform destroy -var-file=local.tfvars
```

> Se o grupo ainda estiver anexado a alguma instância ou ENI, o `destroy` vai ficar esperando até ela ser removida.

---

## 🔧 Customizando as regras

Cada regra é um item do mapa `ingress_rules` ou `egress_rules`. A **chave** (`ssh`, `http`...) é só um identificador: ela vira o endereço do recurso no state, por exemplo `module.security_group.aws_vpc_security_group_ingress_rule.this["ssh"]`.

> ⚠️ Renomear uma chave **destrói e recria** a regra. Escolha nomes estáveis.

Em cada regra, informe `ip_protocol` e **exatamente um** destes campos de origem/destino: `cidr_ipv4`, `cidr_ipv6`, `referenced_security_group_id` ou `prefix_list_id`.

### Saída: o que acontece se eu não declarar nada?

**Nada sai.** A AWS cria todo Security Group com uma regra que libera toda a saída, mas o Terraform remove essa regra quando cria o grupo. Por isso o exemplo declara `all_ipv4` explicitamente.

Liberar tudo (o exemplo já faz isso no IPv4; a regra IPv6 só é necessária se a VPC usar IPv6):

```hcl
egress_rules = {
  all_ipv4 = {
    description = "Allow all outbound IPv4"
    ip_protocol = "-1"
    cidr_ipv4   = "0.0.0.0/0"
  }

  all_ipv6 = {
    description = "Allow all outbound IPv6"
    ip_protocol = "-1"
    cidr_ipv6   = "::/0"
  }
}
```

> Com `ip_protocol = "-1"`, **não** informe `from_port` nem `to_port`.

Saída restrita, por exemplo só HTTPS:

```hcl
egress_rules = {
  https = {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr_ipv4   = "0.0.0.0/0"
  }
}
```

> 💡 Não é preciso liberar DNS para o resolver da própria VPC: o Security Group não filtra esse tráfego. A regra de DNS (UDP/TCP 53) só faz diferença se você usa um servidor DNS externo.

### Restringindo o SSH

Adicione a variável no `variables.tf`:

```hcl
variable "ssh_allowed_cidr" {
  description = "CIDR liberado para SSH (ex.: seu IP /32)"
  type        = string
}
```

Use-a na regra `ssh` do `module.tf`:

```hcl
    ssh = {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = var.ssh_allowed_cidr
    }
```

E informe o valor no `local.tfvars`:

```hcl
ssh_allowed_cidr = "203.0.113.10/32"
```

> Para descobrir o seu IP público: `curl -s https://checkip.amazonaws.com`

### Outros tipos de regra

```hcl
ingress_rules = {
  # HTTPS também via IPv6
  https_v6 = {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr_ipv6   = "::/0"
  }

  # Tráfego vindo de outro Security Group (ex.: um load balancer)
  from_alb = {
    description                  = "App port from ALB"
    from_port                    = 8080
    to_port                      = 8080
    ip_protocol                  = "tcp"
    referenced_security_group_id = "sg-xxxxxxxxxxxxxxxxx"
  }

  # Intervalo de portas
  app_range = {
    from_port   = 3000
    to_port     = 3010
    ip_protocol = "tcp"
    cidr_ipv4   = "10.0.0.0/16"
  }

  # Ping (ICMP echo request: from_port = tipo, to_port = código)
  ping = {
    from_port   = 8
    to_port     = 0
    ip_protocol = "icmp"
    cidr_ipv4   = "10.0.0.0/16"
  }
}
```

---

## 🔗 Usando com o EC2

Passe o output `security_group_id` para o módulo [`EC2`](../../modules/EC2):

```hcl
module "ec2" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EC2?ref=main"

  name      = "${var.prefixo_projeto}-web"
  ami_id    = var.ami_id
  subnet_id = var.subnet_id

  security_group_ids = [module.security_group.security_group_id]
}
```

Veja também o exemplo [ec2-basic](../ec2-basic/README.md).

---

## 🔁 Replicando

### Vários Security Groups no mesmo projeto

Chame o módulo uma vez por grupo:

```hcl
module "sg_web" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/SecurityGroup?ref=main"
  name   = "${var.prefixo_projeto}-web-sg"
  vpc_id = var.vpc_id
  # ingress_rules / egress_rules ...
}

module "sg_db" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/SecurityGroup?ref=main"
  name   = "${var.prefixo_projeto}-db-sg"
  vpc_id = var.vpc_id

  ingress_rules = {
    postgres_from_web = {
      from_port                    = 5432
      to_port                      = 5432
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.sg_web.security_group_id
    }
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
