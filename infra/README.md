# DefectDojo MVP on AWS

Este projeto deploys o DefectDojo na AWS usando uma arquitetura simples para MVP com **ECS (EC2 Spot instances)**, **ECR**, **RDS PostgreSQL** e **ElastiCache Redis**.

## 🏗️ Arquitetura Simplificada

- **ECS com EC2 Spot Instances**: 2-3 instâncias spot para reduzir custos
- **ECR**: Repositórios para imagens Django e Nginx
- **RDS PostgreSQL**: Banco de dados principal (db.t3.micro)
- **ElastiCache Redis**: Cache e message broker (cache.t3.micro)
- **Default VPC**: Usando VPC padrão para simplicidade
- **Security Groups**: Permissões básicas apenas

## 🚀 Deploy Rápido

### 1. Pré-requisitos

```bash
# Instalar Terraform
# Configurar AWS CLI
aws configure

# Clonar o repositório com submodules
git clone --recurse-submodules <seu-repo>
cd sec-llm-infra
```

### 2. Deploy da Infraestrutura

```bash
# Deploy completo
export TF_VAR_db_password="sua-senha-segura"
./deploy.sh apply

# Apenas planejar (sem aplicar)
./deploy.sh plan

# Destruir infraestrutura
./deploy.sh destroy
```

### 3. Build e Push das Imagens

```bash
# Construir e enviar imagens para ECR
./build-and-push.sh
```

### 4. Acessar a Aplicação

Após o deploy:
1. Vá no console AWS ECS para ver as instâncias
2. Pegue o IP público de uma instância EC2
3. Acesse: `http://<ip-publico-da-instancia>`
4. Login padrão: `admin/admin`

## 📁 Estrutura do Projeto

```
sec-llm-infra/
├── deploy.sh              # Script principal de deploy
├── build-and-push.sh      # Script para build das imagens
├── terraform/
│   ├── main.tf            # Configuração principal
│   ├── variables.tf       # Variáveis
│   ├── outputs.tf         # Outputs
│   └── modules/
│       ├── security/      # IAM roles e Security Groups
│       ├── ecr/          # Repositórios ECR
│       ├── rds/          # Banco PostgreSQL
│       ├── redis/        # Cache Redis
│       └── ecs/          # Cluster ECS com Spot instances
└── django-DefectDojo/    # Submodule do DefectDojo
```

## ⚙️ Configurações MVP

### Custos Otimizados
- **EC2 Spot Instances**: Até 90% de desconto
- **Instâncias pequenas**: t3.small, db.t3.micro, cache.t3.micro
- **Backups mínimos**: 1 dia para RDS
- **Logs**: 3 dias de retenção

### Simplificações
- **Ambiente único**: Sem separação dev/prod
- **Default VPC**: Sem custom networking
- **Security básico**: Apenas o necessário
- **No SSL**: HTTP apenas (pode adicionar depois)
- **No Load Balancer**: Acesso direto via IP das instâncias

## 🔧 Customizações

Edite `terraform/variables.tf` para ajustar:

```hcl
variable "instance_type" {
  default = "t3.small"  # Mudar tipo da instância
}

variable "min_size" {
  default = 2  # Mín instâncias
}

variable "max_size" {
  default = 3  # Máx instâncias
}
```

## 📊 Monitoramento

- **CloudWatch**: Logs em `/ecs/defectdojo-mvp`
- **ECS Console**: Status dos containers
- **EC2 Console**: Status das instâncias Spot

## 🆘 Troubleshooting

### Instâncias não sobem
```bash
# Verificar logs
aws logs tail /ecs/defectdojo-mvp --follow

# Verificar service
aws ecs describe-services --cluster defectdojo-mvp-cluster --services defectdojo-mvp-service
```

### Spot instances terminadas
- AWS pode terminar instâncias Spot se o preço aumentar
- ECS vai tentar lançar novas instâncias automaticamente
- Para maior estabilidade, mude para `on_demand_percentage = 50`

### Imagens não encontradas
```bash
# Re-executar build e push
./build-and-push.sh

# Verificar repositórios ECR
aws ecr describe-repositories
```

## 💰 Custos Estimados (MVP)

- **EC2 Spot** (2x t3.small): ~$15-20/mês
- **RDS** (db.t3.micro): ~$15/mês  
- **ElastiCache** (cache.t3.micro): ~$12/mês
- **ECR**: ~$1/mês
- **CloudWatch**: ~$5/mês

**Total estimado**: ~$50/mês

## ⚠️ Importante para Produção

Este é um setup **MVP simplificado**. Para produção:

- [ ] Adicionar HTTPS/SSL
- [ ] Implementar Load Balancer
- [ ] Configurar backup adequado
- [ ] Implementar monitoring robusto  
- [ ] Separar ambientes (dev/staging/prod)
- [ ] Implementar CI/CD completo
- [ ] Configurar auto-scaling mais robusto
- [ ] Implementar VPC customizada
- [ ] Adicionar WAF e security headers

## 📋 Checklist de Deploy

- [ ] AWS CLI configurado
- [ ] Variável `TF_VAR_db_password` definida
- [ ] Executar `./deploy.sh plan` para revisar
- [ ] Executar `./deploy.sh apply` para criar infraestrutura
- [ ] Executar `./build-and-push.sh` para deploy das imagens
- [ ] Verificar ECS service no console AWS
- [ ] Pegar IP público da instância EC2
- [ ] Acessar DefectDojo e configurar usuário admin
