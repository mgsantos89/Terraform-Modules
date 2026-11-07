# Terraform Modules

Coleção de módulos Terraform reutilizáveis, criados e mantidos por [@mgsantos89](https://github.com/mgsantos89).

O objetivo é ter blocos de infraestrutura pequenos, documentados e versionados, que você pode usar direto nos seus projetos sem reescrever o mesmo código toda vez.

> ⚠️ **Projeto em construção.** Os módulos ainda estão sendo adicionados e a interface (variáveis/outputs) pode mudar até a primeira versão estável (`v1.0.0`).

---

## 📦 Módulos disponíveis

| Módulo | Provider | Descrição | Status |
|--------|----------|-----------|--------|
| _em breve_ | — | — | 🚧 |

<!--
Exemplo de linha quando um módulo for adicionado:
| [`aws-vpc`](./modules/aws-vpc) | AWS | VPC com subnets públicas/privadas e NAT Gateway | ✅ Estável |
-->

---

## 🚀 Como usar

Referencie o módulo direto do GitHub, **sempre fixando uma versão** (tag) com `?ref=`:

```hcl
module "exemplo" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/<nome-do-modulo>?ref=v0.1.0"

  # variáveis do módulo
  name = "meu-recurso"
  tags = {
    Environment = "dev"
  }
}
```

Depois:

```bash
terraform init
terraform plan
```

> 💡 Evite usar `?ref=main` em ambientes reais: a branch pode mudar a qualquer momento. Prefira sempre uma tag.

---

## 📁 Estrutura do repositório

```
.
├── modules/
│   └── <nome-do-modulo>/
│       ├── main.tf          # Recursos principais
│       ├── variables.tf     # Variáveis de entrada
│       ├── outputs.tf       # Saídas do módulo
│       ├── versions.tf      # Versões do Terraform e providers
│       ├── README.md        # Documentação do módulo
│       └── examples/        # Exemplos de uso
└── README.md
```

Cada módulo tem seu próprio `README.md` com descrição, inputs, outputs e exemplos.

---

## ✅ Requisitos

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.5`
- Credenciais configuradas para o provider que o módulo utiliza (AWS, Azure, GCP, etc.)

As versões exatas de cada provider ficam no `versions.tf` de cada módulo.

---

## 🧭 Convenções

- **Versionamento:** [Semantic Versioning](https://semver.org/lang/pt-BR/) via tags Git (`vMAJOR.MINOR.PATCH`).
- **Formatação:** todo código passa por `terraform fmt -recursive`.
- **Validação:** `terraform validate` em cada módulo antes do commit.
- **Providers:** versões sempre fixadas em `required_providers`.
- **Sem segredos no código:** nenhuma credencial, chave ou token é versionada. Use variáveis, variáveis de ambiente ou um secret manager.
- **Documentação:** inputs/outputs podem ser gerados com [terraform-docs](https://terraform-docs.io/).

---

## 🤝 Contribuindo

Sugestões, issues e pull requests são bem-vindos!

1. Faça um fork do repositório
2. Crie uma branch: `git checkout -b feat/nome-do-modulo`
3. Rode `terraform fmt -recursive` e `terraform validate`
4. Abra um Pull Request descrevendo a mudança

---

## 📄 Licença

Distribuído sob a licença [MIT](./LICENSE).
