# 🚀 Roadmap de Implementação DefectDojo MVP - AWS ECS

## **Pré-requisitos ✅**
- [x] AWS_ROLE_ARN configurado no GitHub Secrets
- [x] S3 bucket "sec-llm-infra-terraform-state" criado
- [ ] DB_PASSWORD configurado no GitHub Secrets

## **Fase 1: Recursos Base (Segurança + ECR)**
### **Objetivo**: Criar security groups e repositórios ECR
**Duração estimada**: 5-10 min
**Custo**: $0 (ECR tem 500MB free tier)

### **Recursos criados**:
```
✅ Security Groups:
   - ECS Security Group (portas 80, 443, 8080)
   - RDS Security Group (porta 5432 - apenas ECS)
   - Redis Security Group (porta 6379 - apenas ECS)

✅ ECR Repositories:
   - defectdojo-mvp/django
   - defectdojo-mvp/nginx

✅ IAM Roles:
   - ECS Execution Role
   - ECS Task Role
   - EC2 Instance Role
```

**Como testar**:
1. Executar workflow com `action: plan`
2. Verificar plan - deve mostrar ~15 recursos
3. Aplicar com `action: apply`

---

## **Fase 2: Banco de Dados (RDS)**
### **Objetivo**: Criar PostgreSQL RDS
**Duração estimada**: 15-20 min (RDS demora para criar)
**Custo**: ~$15-20/mês (db.t3.micro)

### **Recursos criados**:
```
✅ RDS PostgreSQL:
   - Engine: PostgreSQL 16
   - Instance: db.t3.micro
   - Storage: 20GB gp2
   - Backup: 1 dia
   - Multi-AZ: Não (MVP)
   - Encryption: Sim
```

**Pontos de atenção**:
- ⚠️ RDS demora ~15 minutos para ficar available
- ⚠️ Verifique se o security group permite conexão do ECS
- ⚠️ Senha deve estar em GitHub Secrets

---

## **Fase 3: Cache (Redis) - OPCIONAL**
### **Objetivo**: Criar ElastiCache Redis (opcional para MVP)
**Duração estimada**: 10-15 min
**Custo**: ~$15/mês (cache.t3.micro)

### **Recursos criados**:
```
✅ ElastiCache Redis:
   - Node type: cache.t3.micro
   - Engine: Redis 7
   - Subnet group: default VPC
   - Security group: apenas ECS
```

**Configuração**:
- Para MVP: `enable_redis = false` (usar Redis local no container)
- Para produção: `enable_redis = true`

---

## **Fase 4: Container Service (ECS)**
### **Objetivo**: Criar cluster ECS com EC2 Spot instances
**Duração estimada**: 10-15 min
**Custo**: ~$20-30/mês (2x t3.small spot)

### **Recursos criados**:
```
✅ ECS Cluster:
   - Nome: defectdojo-mvp-cluster
   - Capacity Provider: EC2 Spot

✅ Launch Template:
   - Instance Type: t3.small
   - AMI: ECS-optimized
   - User Data: ECS agent config

✅ Auto Scaling Group:
   - Min: 2, Max: 3, Desired: 2
   - Spot instances (60-70% economia)

✅ ECS Service:
   - Task Definition: Django + Nginx
   - Target Group + Load Balancer
   - Health checks
```

**Pontos de atenção**:
- ⚠️ Instâncias Spot podem ser terminadas (aceitar para MVP)
- ⚠️ Verificar se ECS agent consegue se conectar
- ⚠️ Health checks podem falhar inicialmente

---

## **Cronograma de Testes**

### **🔄 Teste 1: Security + ECR (AGORA)**
```bash
# No GitHub Actions
action: plan (verificar ~15 recursos)
action: apply (auto_approve: true)
```
**Resultado esperado**: ECR repos criados, Security Groups funcionais

### **🔄 Teste 2: RDS (Após Teste 1)**
```bash
# Comentar módulo ECS temporariamente no main.tf
# module "ecs" { ... } → # module "ecs" { ... }
action: plan (verificar +8 recursos)
action: apply 
```
**Resultado esperado**: RDS PostgreSQL disponível em ~15 min

### **🔄 Teste 3: ECS (Após RDS pronto)**
```bash
# Descomentar módulo ECS
# # module "ecs" { ... } → module "ecs" { ... }
action: plan (verificar +15 recursos)
action: apply
```
**Resultado esperado**: Cluster ECS com instâncias rodando

### **🔄 Teste 4: Deploy Aplicação**
```bash
# Ativar build de imagens
build_images: true
action: apply
```
**Resultado esperado**: DefectDojo acessível via Load Balancer

---

## **Monitoramento & Troubleshooting**

### **Comandos úteis AWS CLI**:
```bash
# Verificar cluster ECS
aws ecs list-clusters
aws ecs describe-clusters --clusters defectdojo-mvp-cluster

# Verificar instâncias EC2
aws ec2 describe-instances --filters "Name=tag:Project,Values=defectdojo-mvp"

# Verificar RDS
aws rds describe-db-instances --db-instance-identifier defectdojo-mvp-db

# Verificar ECR
aws ecr describe-repositories
```

### **Logs importantes**:
- ECS Task logs: CloudWatch Logs
- ECS Agent logs: /var/log/ecs/ecs-agent.log
- Application logs: CloudWatch Logs

---

## **Custos Estimados (us-east-1)**

| Serviço | Configuração | Custo/mês |
|---------|-------------|-----------|
| EC2 Spot | 2x t3.small | $15-20 |
| RDS | db.t3.micro | $15-20 |
| ElastiCache | cache.t3.micro | $15 (opcional) |
| Load Balancer | ALB | $18 |
| ECR | 1GB storage | $1 |
| **Total MVP** | | **$49-74/mês** |

---

## **Próximos Passos**

1. **Criar DB_PASSWORD secret** no GitHub
2. **Executar Teste 1**: Security + ECR
3. **Validar recursos** criados no AWS Console
4. **Prosseguir incrementalmente** conforme roadmap
5. **Monitorar custos** no AWS Cost Explorer

**Ready para começar? Execute o primeiro teste! 🚀**
