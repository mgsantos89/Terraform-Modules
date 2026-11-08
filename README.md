# Terraform Modules

Coleção de módulos Terraform reutilizáveis para **AWS**, criados e mantidos por [@mgsantos89](https://github.com/mgsantos89).

O objetivo é ter blocos de infraestrutura pequenos, documentados e prontos para usar nos seus projetos, sem reescrever o mesmo código toda vez.

> ⚠️ **Projeto em construção.** Novos módulos estão sendo adicionados e a interface (variáveis e outputs) pode mudar até a primeira versão estável (`v1.0.0`).

---

## 📦 Módulos disponíveis

| Módulo | Descrição | Exemplo |
|--------|-----------|---------|
| [`EC2`](./modules/EC2) | Instância EC2 com disco raiz `gp3` criptografado, security groups, key pair e tags | [`ec2-basic`](./examples/ec2-basic) |
| [`EIP`](./modules/EIP) | Elastic IP (VPC), com associação opcional a uma instância EC2 | [`eip-allocation`](./examples/eip-allocation) |
| [`SecurityGroup`](./modules/SecurityGroup) | Security Group com regras de entrada e saída declaradas por mapa (IPv4, IPv6, SG ou prefix list) | [`securitygroup-basic`](./examples/securitygroup-basic) |

### `EC2`

Cria uma `aws_instance` com volume raiz `gp3`, criptografado e removido junto com a instância.

**Inputs**

| Variável | Tipo | Padrão | Obrigatória | Descrição |
|----------|------|--------|:-----------:|-----------|
| `name` | `string` | — | ✅ | Nome da instância (tag `Name`) |
| `ami_id` | `string` | — | ✅ | ID da AMI |
| `subnet_id` | `string` | — | ✅ | ID da subnet onde a instância será criada |
| `instance_type` | `string` | `"t3.micro"` | | Tipo da instância |
| `associate_public_ip_address` | `bool` | `false` | | Associa um IP público automático |
| `security_group_ids` | `list(string)` | `[]` | | IDs dos security groups |
| `key_name` | `string` | `null` | | Nome do key pair para acesso SSH |
| `root_volume_size` | `number` | `8` | | Tamanho do disco raiz em GB |
| `tags` | `map(string)` | `{}` | | Tags adicionais |

**Outputs:** `instance_id`, `public_ip`, `private_ip`

### `EIP`

Cria um `aws_eip` no domínio `vpc`. Se `instance_id` for informado, também cria a `aws_eip_association`.

**Inputs**

| Variável | Tipo | Padrão | Obrigatória | Descrição |
|----------|------|--------|:-----------:|-----------|
| `name` | `string` | — | ✅ | Nome do Elastic IP (tag `Name`) |
| `instance_id` | `string` | `null` | | ID da instância EC2 a associar. Se ficar `null`, o IP só é alocado |
| `tags` | `map(string)` | `{}` | | Tags adicionais |

**Outputs:** `allocation_id`, `public_ip`, `association_id` (`null` quando não há associação)

### `SecurityGroup`

Cria um `aws_security_group` e uma regra `aws_vpc_security_group_ingress_rule` ou `aws_vpc_security_group_egress_rule` para cada item dos mapas `ingress_rules` e `egress_rules`. Usa `create_before_destroy`, então trocar o grupo não deixa recursos sem Security Group no meio do caminho.

> ⚠️ **Não existe saída liberada por padrão.** A AWS cria todo Security Group com uma regra que libera toda a saída, mas o Terraform remove essa regra. Se `egress_rules` ficar vazio, **nenhum tráfego de saída é permitido**.

**Inputs**

| Variável | Tipo | Padrão | Obrigatória | Descrição |
|----------|------|--------|:-----------:|-----------|
| `name` | `string` | — | ✅ | Nome do Security Group (tag `Name`) |
| `vpc_id` | `string` | — | ✅ | ID da VPC |
| `description` | `string` | `"Managed by Terraform"` | | Descrição do grupo. Mudar este valor recria o grupo |
| `ingress_rules` | `map(object)` | `{}` | | Regras de entrada (formato abaixo) |
| `egress_rules` | `map(object)` | `{}` | | Regras de saída (formato abaixo) |
| `tags` | `map(string)` | `{}` | | Tags aplicadas ao grupo e às regras |

**Formato de cada regra**

| Campo | Obrigatório | Descrição |
|-------|:-----------:|-----------|
| `ip_protocol` | ✅ | `tcp`, `udp`, `icmp`, `icmpv6` ou `-1` (todos) |
| `from_port` / `to_port` | | Intervalo de portas. **Omita** quando `ip_protocol = "-1"` |
| `description` | | Descrição da regra |
| `cidr_ipv4` | ⚠️ | CIDR IPv4 de origem ou destino |
| `cidr_ipv6` | ⚠️ | CIDR IPv6 de origem ou destino |
| `referenced_security_group_id` | ⚠️ | ID de outro Security Group |
| `prefix_list_id` | ⚠️ | ID de uma managed prefix list |

⚠️ Informe **exatamente um** dos quatro campos de origem/destino em cada regra.

**Outputs:** `security_group_id`, `security_group_name`, `security_group_arn`

---

## 🚀 Como usar

Referencie o módulo direto do GitHub:

```hcl
module "ec2" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EC2?ref=main"

  name      = "minha-instancia"
  ami_id    = "ami-xxxxxxxxxxxxxxxxx"
  subnet_id = "subnet-xxxxxxxxxxxxxxxxx"
}
```

> 💡 **Fixe uma versão em ambientes reais.** Hoje os exemplos usam `?ref=main`, que pode mudar a qualquer momento. Quando houver tags publicadas, prefira `?ref=vX.Y.Z`.

O passo a passo completo (provider, variáveis, `init`/`plan`/`apply`/`destroy`) está no README de cada exemplo:

- [examples/ec2-basic](./examples/ec2-basic/README.md)
- [examples/eip-allocation](./examples/eip-allocation/README.md)
- [examples/securitygroup-basic](./examples/securitygroup-basic/README.md)

### Combinando módulos

Os outputs de um módulo podem ser usados como entrada de outro:

```hcl
module "sg" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/SecurityGroup?ref=main"
  # ...
}

module "ec2" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EC2?ref=main"
  # ...
  security_group_ids = [module.sg.security_group_id]
}

module "eip" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/EIP?ref=main"
  # ...
  instance_id = module.ec2.instance_id
}
```

---

## 📁 Estrutura do repositório

```
.
├── modules/
│   ├── EC2/                   # Módulo de instância EC2
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── EIP/                   # Módulo de Elastic IP
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── SecurityGroup/         # Módulo de Security Group
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── examples/
│   ├── ec2-basic/             # Exemplo de uso do módulo EC2
│   │   ├── module.tf
│   │   ├── variables.tf
│   │   ├── example.tfvars
│   │   └── README.md
│   ├── eip-allocation/        # Exemplo de uso do módulo EIP
│   │   ├── module.tf
│   │   ├── variables.tf
│   │   ├── example.tfvars
│   │   └── README.md
│   └── securitygroup-basic/   # Exemplo de uso do módulo SecurityGroup
│       ├── module.tf
│       ├── variables.tf
│       ├── example.tfvars
│       └── README.md
├── .gitignore
└── README.md
```

### Arquivos locais (não versionados)

O [`.gitignore`](./.gitignore) impede que estes arquivos sejam versionados, porque podem conter dados sensíveis:

| Arquivo | Para que serve |
|---------|----------------|
| `providers.tf` | Configuração do provider AWS (região, perfil). Cada pessoa cria o seu |
| `*.tfvars` (exceto `example.tfvars`) | Valores reais das variáveis, por exemplo um `local.tfvars` |
| `*.tfstate`, `*.tfstate.*` | State do Terraform |
| `.terraform/`, `.terraform.lock.hcl` | Providers e módulos baixados pelo `terraform init` |

---

## ✅ Requisitos

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.5`
- Provider [`hashicorp/aws`](https://registry.terraform.io/providers/hashicorp/aws/latest) `5.x` (testado com `5.38.0`)
- Credenciais AWS configuradas (`aws configure`, `AWS_PROFILE` ou variáveis de ambiente)
- Uma VPC existente, com subnet para a instância EC2

---

## 🧭 Convenções

- **Versionamento:** [Semantic Versioning](https://semver.org/lang/pt-BR/) via tags Git (`vMAJOR.MINOR.PATCH`)
- **Formatação:** `terraform fmt -recursive` antes de cada commit
- **Validação:** `terraform validate` em cada módulo e exemplo
- **Providers:** versão sempre fixada em `required_providers`
- **Sem segredos no código:** nenhuma credencial, chave ou token é versionada
- **Tags padrão:** os exemplos aplicam `Environment`, `Project` e `ManagedBy = "Terraform"`

---

## 🤝 Contribuindo

Sugestões, issues e pull requests são bem-vindos!

1. Faça um fork do repositório
2. Crie uma branch: `git checkout -b feat/nome-do-modulo`
3. Adicione o módulo em `modules/<Nome>` e um exemplo em `examples/<nome-do-exemplo>` com README
4. Rode `terraform fmt -recursive` e `terraform validate`
5. Abra um Pull Request descrevendo a mudança

---

## 📄 Licença

Distribuído sob a licença [MIT](./LICENSE).
