# Exemplo: `placementgroups`

Cria **três Placement Groups**, um para cada estratégia, usando o módulo [`PlacementGroup`](../../modules/PlacementGroup):

| Módulo | Nome criado | Estratégia | Configuração |
|--------|-------------|------------|--------------|
| `placement_group_1` | `<prefixo>-highperformance-pg` | `cluster` | — |
| `placement_group_2` | `<prefixo>-critical-pg` | `spread` | `spread_level = "rack"` (padrão do módulo) |
| `placement_group_3` | `<prefixo>-distributed-pg` | `partition` | 2 partições (padrão da AWS, porque `partition_count` não foi informado) |

Todos recebem as tags `Name`, `Environment`, `Project` e `ManagedBy = "Terraform"`.

> 💰 Placement Groups **não têm custo**. Você paga só pelas instâncias colocadas neles.

---

## 🧠 Entendendo as estratégias

```
cluster                      spread                       partition
┌──────────────────┐         ┌────┐ ┌────┐ ┌────┐         ┌─ P1 ─┐ ┌─ P2 ─┐ ┌─ P3 ─┐
│ ▣ ▣ ▣ ▣ ▣ ▣ ▣ ▣  │         │ ▣  │ │ ▣  │ │ ▣  │         │ ▣ ▣  │ │ ▣ ▣  │ │ ▣ ▣  │
│   (mesmo rack)   │         └────┘ └────┘ └────┘         │ ▣ ▣  │ │ ▣ ▣  │ │ ▣ ▣  │
└──────────────────┘          1 instância por rack        └──────┘ └──────┘ └──────┘
  1 AZ, mais rápido           máx. 7 por AZ                racks separados por partição
```

| | `cluster` | `spread` | `partition` |
|-|-----------|----------|-------------|
| **Objetivo** | Desempenho de rede | Isolar falhas por instância | Isolar falhas por grupo de instâncias |
| **Zonas de disponibilidade** | Uma só | Várias | Várias |
| **Limite** | Depende da capacidade da AZ | 7 instâncias em execução por AZ | 7 partições por AZ |
| **Risco** | Se o rack falhar, caem todas | Pouca escala | Falha de rack afeta só uma partição |
| **Exemplos** | HPC, ML distribuído, big data | Banco primário e réplica, controladores | Kafka, Cassandra, HDFS, HBase |

**Dicas**

- **`cluster`**: use o mesmo tipo de instância e suba todas de uma vez. Se faltar capacidade na AZ, o lançamento falha com `InsufficientInstanceCapacity`. Prefira tipos com rede aprimorada (ENA).
- **`spread`**: `spread_level = "host"` só funciona em **AWS Outposts**. Na Region, use `rack`, que é o padrão do módulo.
- **`partition`**: a instância pode escolher a partição com `partition_number`, ou deixar a AWS distribuir.

---

## 📋 Pré-requisitos

- Terraform `>= 1.5`
- Credenciais AWS configuradas (`aws configure`, `AWS_PROFILE` ou variáveis de ambiente)
- Permissão para criar Placement Groups (`ec2:CreatePlacementGroup`, `ec2:DeletePlacementGroup`, `ec2:DescribePlacementGroups`)

---

## 📁 Arquivos

| Arquivo | Versionado | Descrição |
|---------|:----------:|-----------|
| `module.tf` | ✅ | As três chamadas do módulo `PlacementGroup` |
| `variables.tf` | ✅ | Variáveis do exemplo |
| `example.tfvars` | ✅ | Modelo de valores, com placeholders |
| `providers.tf` | ❌ | Configuração do provider AWS. **Você cria** (passo 2) |
| `local.tfvars` | ❌ | Seus valores reais. **Você cria** (passo 3) |

---

## 🚀 Passo a passo

### 1. Copie o exemplo

```bash
git clone https://github.com/mgsantos89/Terraform-Modules.git
cp -r Terraform-Modules/examples/placementgroups ./meu-placement-group
cd meu-placement-group
```

> Para usar no seu próprio projeto, basta copiar os arquivos `module.tf` e `variables.tf`. O módulo é baixado direto do GitHub pelo `source`.

### 2. Crie o `providers.tf`

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.72.0"
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
| `prefixo_projeto` | ✅ | — | Prefixo dos nomes dos grupos e tag `Project` |
| `environment` | | `test` | Ambiente (tag `Environment`) |

> O nome de um Placement Group precisa ser único na região. Se já existir um grupo com o mesmo nome, o `apply` falha.

### 4. Rode o Terraform

```bash
terraform init
terraform plan  -var-file=local.tfvars
terraform apply -var-file=local.tfvars
```

O `plan` deve mostrar **3 recursos** `aws_placement_group`, um por módulo.

### 5. Confira o resultado

```bash
aws ec2 describe-placement-groups \
  --filters Name=tag:Project,Values=meu-projeto \
  --query "PlacementGroups[].{Nome:GroupName,Estrategia:Strategy,Particoes:PartitionCount,Nivel:SpreadLevel,Estado:State}" \
  --output table
```

Se preferir que os valores apareçam ao final do `apply`, crie um `outputs.tf`:

```hcl
output "placement_groups" {
  value = {
    cluster   = module.placement_group_1.placement_group_name
    spread    = module.placement_group_2.placement_group_name
    partition = module.placement_group_3.placement_group_name
  }
}
```

### 6. Destrua o ambiente

```bash
terraform destroy -var-file=local.tfvars
```

> Um Placement Group só pode ser removido quando estiver vazio. Se ainda houver instâncias nele, termine ou mova as instâncias antes.

---

## 🔧 Customizando

### Definindo o número de partições

```hcl
module "placement_group_3" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/PlacementGroup?ref=main"

  name            = "${var.prefixo_projeto}-distributed-pg"
  strategy        = "partition"
  partition_count = 3 # de 1 a 7
}
```

> `partition_count` é ignorado nas outras estratégias, e `spread_level` só vale para `spread`.

### Criando só o grupo que você precisa

As três chamadas são independentes. Apague as que não for usar no `module.tf`.

### Mudando a estratégia de um grupo existente

A AWS não permite alterar um Placement Group. Mudar `strategy`, `partition_count` ou `spread_level` **destrói e recria** o grupo, e isso só funciona se ele estiver vazio.

---

## 🔗 Usando com instâncias EC2

> ℹ️ O módulo [`EC2`](../../modules/EC2) deste repositório **ainda não aceita placement group**. Por enquanto, use um `aws_instance` direto.

Instâncias em um grupo `cluster`:

```hcl
resource "aws_instance" "hpc" {
  count = 3

  ami             = var.ami_id
  instance_type   = "c5n.large"
  subnet_id       = var.subnet_id
  placement_group = module.placement_group_1.placement_group_name

  tags = { Name = "${var.prefixo_projeto}-hpc-${count.index}" }
}
```

Instâncias em um grupo `partition`, escolhendo a partição:

```hcl
resource "aws_instance" "kafka" {
  count = 2

  ami                        = var.ami_id
  instance_type              = "m5.large"
  subnet_id                  = var.subnet_id
  placement_group            = module.placement_group_3.placement_group_name
  placement_partition_number = count.index + 1 # partição 1, 2...

  tags = { Name = "${var.prefixo_projeto}-kafka-${count.index}" }
}
```

> Nem todo tipo de instância é aceito em todas as estratégias. Tipos burstable (`t2`, `t3`...) não podem ser usados em `cluster`, por exemplo. Consulte a [documentação da AWS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/placement-groups.html).

---

## 🔁 Replicando

### Vários grupos com `for_each`

Em vez de três blocos `module`, use um mapa:

```hcl
locals {
  placement_groups = {
    highperformance = { strategy = "cluster" }
    critical        = { strategy = "spread" }
    distributed     = { strategy = "partition", partition_count = 3 }
  }
}

module "placement_group" {
  source   = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/PlacementGroup?ref=main"
  for_each = local.placement_groups

  name            = "${var.prefixo_projeto}-${each.key}-pg"
  strategy        = each.value.strategy
  partition_count = lookup(each.value, "partition_count", null)

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }
}
```

> Se você já aplicou o exemplo com os três blocos, trocar por `for_each` muda os endereços no state e o Terraform vai recriar os grupos. Para evitar isso, use blocos [`moved`](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring).

### Vários ambientes

Use um arquivo de variáveis e um state separado para cada ambiente, com prefixos diferentes para os nomes não colidirem:

```bash
terraform workspace new dev
terraform apply -var-file=dev.tfvars

terraform workspace new prod
terraform apply -var-file=prod.tfvars
```

### Fixando a versão do módulo

O `source` usa `?ref=main`. Em ambientes reais, troque por uma tag assim que houver uma publicada (por exemplo `?ref=v1.0.0`) e rode `terraform init -upgrade`.
