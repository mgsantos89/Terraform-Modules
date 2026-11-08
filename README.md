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

---

## 📁 Estrutura do repositório

```
.
├── modules/
│   ├── EC2/                   # Módulo de instância EC2
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── EIP/                   # Módulo de Elastic IP
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── examples/
│   ├── ec2-basic/             # Exemplo de uso do módulo EC2
│   │   ├── module.tf
│   │   ├── variables.tf
│   │   ├── example.tfvars
│   │   └── README.md
│   └── eip-allocation/        # Exemplo de uso do módulo EIP
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
- Uma VPC com subnet existente para a instância EC2

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
