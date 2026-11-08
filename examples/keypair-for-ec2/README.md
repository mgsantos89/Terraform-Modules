# Exemplo: `keypair-for-ec2`

Cria um **Key Pair** para acesso SSH a instâncias EC2 usando o módulo [`KeyPair`](../../modules/KeyPair):

1. Gera uma chave **RSA 4096** com o provider `tls`
2. Registra a chave pública na AWS como Key Pair `<prefixo_projeto>-key`
3. Salva a chave privada em `keys/<prefixo_projeto>.pem`, com permissão `0600`

O Key Pair recebe as tags `Environment`, `Project` e `ManagedBy = "Terraform"`.

> 🔐 **Use apenas em laboratório e estudo.** A chave privada é gerada pelo Terraform e por isso fica gravada **em texto puro** no `terraform.tfstate` e no `terraform.tfstate.backup`. Quem tiver o state tem a chave. Detalhes em [Segurança](#-segurança).

---

## 📋 Pré-requisitos

- Terraform `>= 1.5`
- Credenciais AWS configuradas (`aws configure`, `AWS_PROFILE` ou variáveis de ambiente)
- Permissão para criar Key Pairs (`ec2:ImportKeyPair`, `ec2:DeleteKeyPair`, `ec2:DescribeKeyPairs`)
- Um cliente SSH, para usar a chave depois

---

## 📁 Arquivos

| Arquivo | Versionado | Descrição |
|---------|:----------:|-----------|
| `module.tf` | ✅ | Chamada do módulo `KeyPair` |
| `variables.tf` | ✅ | Variáveis do exemplo |
| `example.tfvars` | ✅ | Modelo de valores, com placeholders |
| `providers.tf` | ❌ | Configuração dos providers. **Você cria** (passo 2) |
| `local.tfvars` | ❌ | Seus valores reais. **Você cria** (passo 3) |
| `keys/*.pem` | ❌ | Chave privada gerada no `apply` |

---

## 🚀 Passo a passo

### 1. Copie o exemplo

```bash
git clone https://github.com/mgsantos89/Terraform-Modules.git
cp -r Terraform-Modules/examples/keypair-for-ec2 ./meu-keypair
cd meu-keypair
```

> Para usar no seu próprio projeto, basta copiar os arquivos `module.tf` e `variables.tf`. O módulo é baixado direto do GitHub pelo `source`.

### 2. Crie o `providers.tf`

Este módulo usa três providers: `aws`, `tls` (gera a chave) e `local` (grava o `.pem`).

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.72.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.4.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.9.1"
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
| `prefixo_projeto` | ✅ | — | Prefixo do projeto. Vira o nome do Key Pair (`<prefixo>-key`), do arquivo (`keys/<prefixo>.pem`) e a tag `Project` |
| `environment` | | `test` | Ambiente (tag `Environment`) |

> O nome do Key Pair precisa ser único na região. Se já existir um `<prefixo>-key`, o `apply` falha.

### 4. Rode o Terraform

```bash
terraform init
terraform plan  -var-file=local.tfvars
terraform apply -var-file=local.tfvars
```

O `plan` deve mostrar **3 recursos**: `tls_private_key`, `aws_key_pair` e `local_sensitive_file`.

A pasta `keys/` é criada automaticamente se não existir.

### 5. Confira o resultado

```bash
ls -l keys/
# -rw------- 1 user user 3243 ... meu-projeto.pem

aws ec2 describe-key-pairs --key-names meu-projeto-key
```

Se preferir que os valores apareçam ao final do `apply`, crie um `outputs.tf`:

```hcl
output "key_name"         { value = module.key_pair.key_name }
output "key_pair_id"      { value = module.key_pair.key_pair_id }
output "private_key_path" { value = module.key_pair.private_key_path }
```

### 6. Destrua o ambiente

```bash
terraform destroy -var-file=local.tfvars
```

O `destroy` remove o Key Pair da AWS **e apaga o `.pem` local**. Se ainda houver instâncias usando a chave, elas continuam rodando, mas você perde o acesso SSH a elas.

---

## 🔗 Usando com o EC2

Passe o output `key_name` para o módulo [`EC2`](../../modules/EC2) e libere a porta 22 com o módulo [`SecurityGroup`](../../modules/SecurityGroup):

```hcl
module "key_pair" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/KeyPair?ref=main"

  key_name         = "${var.prefixo_projeto}-key"
  private_key_path = "keys/${var.prefixo_projeto}.pem"
}

module "sg" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/SecurityGroup?ref=main"

  name   = "${var.prefixo_projeto}-sg"
  vpc_id = var.vpc_id

  ingress_rules = {
    ssh = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = var.ssh_allowed_cidr # seu IP /32
    }
  }

  egress_rules = {
    all_ipv4 = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}

module "ec2" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EC2?ref=main"

  name      = "${var.prefixo_projeto}-web"
  ami_id    = var.ami_id
  subnet_id = var.subnet_id

  associate_public_ip_address = true
  key_name                    = module.key_pair.key_name
  security_group_ids          = [module.sg.security_group_id]
}
```

Depois do `apply`, conecte:

```bash
ssh -i keys/meu-projeto.pem ec2-user@<IP_PUBLICO>
```

> O usuário depende da AMI: `ec2-user` (Amazon Linux), `ubuntu` (Ubuntu), `admin` (Debian).

Veja também os exemplos [ec2-basic](../ec2-basic/README.md) e [securitygroup-basic](../securitygroup-basic/README.md).

---

## 🔁 Replicando

### Uma chave por ambiente

O nome da chave e do arquivo vêm do `prefixo_projeto`. Use um arquivo de variáveis e um state separado para cada ambiente, com prefixos diferentes:

```bash
# dev.tfvars  -> prefixo_projeto = "meu-projeto-dev"
# prod.tfvars -> prefixo_projeto = "meu-projeto-prod"

terraform workspace new dev
terraform apply -var-file=dev.tfvars

terraform workspace new prod
terraform apply -var-file=prod.tfvars
```

### Várias chaves no mesmo projeto

```hcl
module "key_pair" {
  source   = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/KeyPair?ref=main"
  for_each = toset(["bastion", "app"])

  key_name         = "${var.prefixo_projeto}-${each.key}-key"
  private_key_path = "keys/${var.prefixo_projeto}-${each.key}.pem"
}
```

### Fixando a versão do módulo

O `source` usa `?ref=main`. Em ambientes reais, troque por uma tag assim que houver uma publicada (por exemplo `?ref=v1.0.0`) e rode `terraform init -upgrade`.

---

## 🔐 Segurança

| Risco | Como se proteger |
|-------|------------------|
| Chave privada em texto puro no state | Nunca versione o state (o `.gitignore` já bloqueia `*.tfstate*`). Fora do laboratório, use um backend remoto criptografado com acesso restrito, por exemplo S3 com SSE-KMS |
| `.pem` versionado por engano | O `.gitignore` bloqueia `keys/`, `*.pem` e `*.key`. Confira com `git status` antes de commitar |
| Chave compartilhada entre pessoas | Gere uma chave por pessoa ou por ambiente e não envie o `.pem` por chat ou e-mail |
| Porta 22 exposta | Restrinja o SSH ao seu IP (`/32`) ou use o [SSM Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html), que dispensa Key Pair e porta aberta |

Para ambientes reais, a alternativa mais segura é gerar a chave **fora** do Terraform (`ssh-keygen -t ed25519`) e importar só a chave pública com um `aws_key_pair`. Assim a chave privada nunca entra no state.
