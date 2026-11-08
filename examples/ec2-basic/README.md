# Exemplo: `ec2-basic`

Cria uma instância EC2 usando o módulo [`EC2`](../../modules/EC2), com:

- IP público automático (`associate_public_ip_address = true`)
- Disco raiz `gp3` de **10 GB**, criptografado
- Tags padrão: `Name`, `Environment`, `Project` e `ManagedBy = "Terraform"`

---

## 📋 Pré-requisitos

- Terraform `>= 1.5`
- Credenciais AWS configuradas (`aws configure`, `AWS_PROFILE` ou variáveis de ambiente)
- Permissão para criar instâncias EC2 na conta
- Uma **subnet** existente (de preferência pública, já que a instância recebe IP público)
- O **ID de uma AMI** válida na região escolhida

---

## 📁 Arquivos

| Arquivo | Versionado | Descrição |
|---------|:----------:|-----------|
| `module.tf` | ✅ | Chamada do módulo `EC2` |
| `variables.tf` | ✅ | Variáveis do exemplo |
| `example.tfvars` | ✅ | Modelo de valores, com placeholders |
| `providers.tf` | ❌ | Configuração do provider AWS. **Você cria** (passo 2) |
| `local.tfvars` | ❌ | Seus valores reais. **Você cria** (passo 3) |

---

## 🚀 Passo a passo

### 1. Copie o exemplo

```bash
git clone https://github.com/mgsantos89/Terraform-Modules.git
cp -r Terraform-Modules/examples/ec2-basic ./meu-ec2
cd meu-ec2
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
instance_name   = "web-01"
ami_id          = "ami-xxxxxxxxxxxxxxxxx"
instance_type   = "t3.micro"
subnet_id       = "subnet-xxxxxxxxxxxxxxxxx"
prefixo_projeto = "meu-projeto"
environment     = "dev"
```

| Variável | Obrigatória | Padrão | Descrição |
|----------|:-----------:|--------|-----------|
| `instance_name` | ✅ | — | Nome da instância (tag `Name`) |
| `ami_id` | ✅ | — | ID da AMI |
| `subnet_id` | ✅ | — | ID da subnet |
| `prefixo_projeto` | ✅ | — | Prefixo do projeto (tag `Project`) |
| `instance_type` | | `t3.medium` | Tipo da instância |
| `environment` | | `test` | Ambiente (tag `Environment`) |

> 💡 Para descobrir uma AMI recente do Amazon Linux 2023 na sua região:
> ```bash
> aws ssm get-parameter \
>   --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
>   --query Parameter.Value --output text
> ```

### 4. Rode o Terraform

```bash
terraform init
terraform plan  -var-file=local.tfvars
terraform apply -var-file=local.tfvars
```

### 5. Veja o resultado

O exemplo não tem `outputs.tf`. Para ver os dados da instância:

```bash
terraform state show module.ec2.aws_instance.this
```

Se preferir que os valores apareçam ao final do `apply`, crie um `outputs.tf`:

```hcl
output "instance_id" { value = module.ec2.instance_id }
output "public_ip"   { value = module.ec2.public_ip }
output "private_ip"  { value = module.ec2.private_ip }
```

### 6. Destrua o ambiente

```bash
terraform destroy -var-file=local.tfvars
```

---

## 🔧 Customizando

O `module.tf` já fixa alguns valores. Você pode mudar direto nele ou transformar em variável:

```hcl
module "ec2" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EC2?ref=main"

  # ...

  associate_public_ip_address = false               # sem IP público
  root_volume_size            = 20                  # disco maior
  security_group_ids          = ["sg-xxxxxxxx"]     # SGs existentes
  key_name                    = "meu-key-pair"      # acesso SSH
}
```

Todas as opções do módulo estão no [README principal](../../README.md#ec2).

### Replicando para vários ambientes

Use um arquivo de variáveis e um state separado para cada ambiente, por exemplo com workspaces:

```bash
terraform workspace new dev
terraform apply -var-file=dev.tfvars

terraform workspace new prod
terraform apply -var-file=prod.tfvars
```

### Fixando a versão do módulo

O `source` usa `?ref=main`. Em ambientes reais, troque por uma tag assim que houver uma publicada (por exemplo `?ref=v1.0.0`) e rode `terraform init -upgrade`.

---

## 🔗 Combinando com o EIP

Para dar um IP fixo a esta instância, use o módulo [`EIP`](../../modules/EIP) passando o `instance_id`. Veja [eip-allocation](../eip-allocation/README.md#-associando-a-uma-instância-ec2).
