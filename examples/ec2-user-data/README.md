# Exemplo: `ec2-user-data`

Cria uma instância EC2 usando o módulo [`EC2`](../../modules/EC2) e a configura no primeiro boot com **User Data**:

- Script em [`scripts/user-data.sh.tftpl`](./scripts/user-data.sh.tftpl), renderizado com `templatefile()`
- Instala e sobe o **nginx**, com uma página mostrando o nome, o ambiente, o Instance ID e a AZ
- **IMDSv2 obrigatório** (`metadata_http_tokens = "required"`), e o próprio script lê a metadata usando token
- `user_data_replace_on_change = true`: se o script mudar, a instância é **recriada** para que ele rode de novo
- IP público automático, disco raiz `gp3` de 10 GB criptografado e tags padrão

---

## 📋 Pré-requisitos

- Terraform `>= 1.5`
- Credenciais AWS configuradas (`aws configure`, `AWS_PROFILE` ou variáveis de ambiente)
- Uma **subnet pública** (com rota para Internet Gateway), já que o script baixa pacotes
- Um **Security Group** liberando a porta **80** de entrada para testar a página (veja [securitygroup-basic](../securitygroup-basic/README.md))
- O ID de uma AMI **Amazon Linux 2023** (o script usa `dnf`)

---

## 📁 Arquivos

| Arquivo | Versionado | Descrição |
|---------|:----------:|-----------|
| `module.tf` | ✅ | Chamada do módulo `EC2` com User Data e IMDSv2 |
| `scripts/user-data.sh.tftpl` | ✅ | Template do script executado no primeiro boot |
| `variables.tf` | ✅ | Variáveis do exemplo |
| `outputs.tf` | ✅ | `instance_id`, `public_ip` e `url` |
| `example.tfvars` | ✅ | Modelo de valores, com placeholders |
| `providers.tf` | ❌ | Configuração do provider AWS. **Você cria** (passo 2) |
| `local.tfvars` | ❌ | Seus valores reais. **Você cria** (passo 3) |

---

## 🚀 Passo a passo

### 1. Copie o exemplo

```bash
git clone https://github.com/mgsantos89/Terraform-Modules.git
cp -r Terraform-Modules/examples/ec2-user-data ./meu-ec2-user-data
cd meu-ec2-user-data
```

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

| Variável | Obrigatória | Padrão | Descrição |
|----------|:-----------:|--------|-----------|
| `instance_name` | ✅ | — | Nome da instância (tag `Name` e título da página) |
| `ami_id` | ✅ | — | ID da AMI Amazon Linux 2023 |
| `subnet_id` | ✅ | — | ID da subnet pública |
| `prefixo_projeto` | ✅ | — | Prefixo do projeto (tag `Project`) |
| `security_group_ids` | | `[]` | SGs da instância (libere a porta 80) |
| `instance_type` | | `t3.micro` | Tipo da instância |
| `environment` | | `test` | Ambiente (tag `Environment` e texto da página) |

> 💡 AMI recente do Amazon Linux 2023:
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

### 5. Teste

Aguarde 1 a 2 minutos para o script terminar e acesse o output `url`:

```bash
curl "$(terraform output -raw url)"
```

Se a página não responder, confira o log do User Data na instância (via SSH ou SSM Session Manager):

```bash
sudo cat /var/log/cloud-init-output.log
```

Para conferir que o IMDSv2 está sendo exigido:

```bash
aws ec2 describe-instances --instance-ids "$(terraform output -raw instance_id)" \
  --query 'Reservations[0].Instances[0].MetadataOptions'
```

### 6. Destrua o ambiente

```bash
terraform destroy -var-file=local.tfvars
```

---

## 🔧 Como o User Data funciona no módulo

| Variável do módulo | Padrão | Descrição |
|--------------------|--------|-----------|
| `user_data` | `null` | Script em texto puro (shell ou cloud-init) |
| `user_data_base64` | `null` | Conteúdo já em base64 (ex.: data source `cloudinit_config` com gzip). Não use junto com `user_data` |
| `user_data_replace_on_change` | `false` | `true` recria a instância quando o script muda. Com `false`, a mudança é gravada sem recriar, mas **o script não roda de novo** |
| `metadata_http_tokens` | `"required"` | `"required"` exige IMDSv2. `"optional"` aceita também IMDSv1 |
| `metadata_http_put_response_hop_limit` | `1` | Use `2` se containers (Docker/EKS) na instância precisarem acessar a metadata |

> ⚠️ **Não coloque segredos no User Data.** O conteúdo fica salvo em texto no state do Terraform e qualquer processo na instância consegue ler pela metadata. Busque senhas e tokens durante a execução do script, no **SSM Parameter Store** ou no **Secrets Manager**, usando uma IAM Role da instância.

> ⚠️ O User Data roda **apenas no primeiro boot**. Reiniciar a instância não executa o script de novo.

### Script inline em vez de arquivo

Para scripts curtos, dá para usar heredoc direto no `module.tf`:

```hcl
user_data = <<-EOT
  #!/bin/bash
  dnf install -y htop
EOT
```
