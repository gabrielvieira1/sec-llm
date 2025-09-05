# DefectDojo Deployment Guide - Workflows Unificados 🚀

## 📋 Workflows Disponíveis

### 1. **deployment-manager.yml** - Gerenciador Principal de Deploy
**Uso**: Controle total sobre o que você quer deployar

#### Opções de Deploy:
```yaml
deployment_type:
  - "infrastructure-only"     # Apenas Terraform (EC2 + RDS)
  - "application-only"        # Apenas aplicação (modo rápido)
  - "application-full"        # Aplicação completa com verificações
  - "full-deployment"         # Infraestrutura + Aplicação completa
```

#### Como Usar:
1. **GitHub** → **Actions** → **"DefectDojo Deployment Manager"**
2. **Run workflow** → Escolher tipo de deployment
3. Configurar opções conforme necessário

### 2. **app-deploy-unified.yml** - Deploy Unificado de Aplicação
**Uso**: Deploy direto da aplicação com duas opções

#### Modos Disponíveis:
```yaml
deployment_mode:
  - "fast"        # Deploy rápido (5-10 minutos)
  - "complete"    # Deploy completo (15-20 minutos)
```

#### Como Usar:
1. **GitHub** → **Actions** → **"DefectDojo Application Deploy - Unified"**
2. **Run workflow** → Escolher modo (fast/complete)
3. Configurar opções avançadas se necessário

### 3. **terraform-deploy.yml** - Deploy Apenas da Infraestrutura
**Uso**: Gerenciamento direto do Terraform

---

## 🎯 Cenários de Uso

### 🚀 **Deploy Completo (Primeira Vez)**
```yaml
Workflow: deployment-manager.yml
deployment_type: "full-deployment" 
terraform_action: "apply"
terraform_auto_approve: false
```
**Resultado**: EC2 + RDS + DefectDojo completo
**Tempo**: ~25-30 minutos

---

### ⚡ **Deploy Rápido da Aplicação (Desenvolvimento)**
```yaml
Workflow: app-deploy-unified.yml
deployment_mode: "fast"
force_rebuild: false
```
**Resultado**: Deploy apenas da pasta app/ (rápido)
**Tempo**: ~5-10 minutos

---

### 🔧 **Deploy Completo da Aplicação (Produção)**
```yaml
Workflow: app-deploy-unified.yml
deployment_mode: "complete"
force_rebuild: true
```
**Resultado**: Deploy completo com todas verificações
**Tempo**: ~15-20 minutos

---

### 🏗️ **Apenas Infraestrutura (Terraform)**
```yaml
Workflow: deployment-manager.yml
deployment_type: "infrastructure-only"
terraform_action: "apply"
```
**Resultado**: Apenas EC2 + RDS (sem aplicação)
**Tempo**: ~10-15 minutos

---

## 📊 Comparativo dos Workflows

| Workflow | Infraestrutura | Aplicação | Tempo | Uso |
|----------|----------------|-----------|-------|-----|
| **deployment-manager.yml** | ✅ Opcional | ✅ Opcional | Variável | Controle total |
| **app-deploy-unified.yml** | ❌ Auto-discover | ✅ Fast/Complete | 5-20 min | Deploy app |
| **terraform-deploy.yml** | ✅ Terraform only | ❌ | 10-15 min | Infra only |

---

## 🔄 Fluxo de Desenvolvimento Recomendado

### 1️⃣ **Setup Inicial** (Uma vez)
```yaml
deployment-manager.yml
└── deployment_type: "full-deployment"
    ├── terraform_action: "apply"
    └── terraform_auto_approve: false
```

### 2️⃣ **Desenvolvimento Diário** (Iterativo)
```yaml
app-deploy-unified.yml
└── deployment_mode: "fast"
    ├── force_rebuild: false
    └── force_restart: false
```

### 3️⃣ **Deploy de Produção** (Releases)
```yaml
app-deploy-unified.yml
└── deployment_mode: "complete"
    ├── force_rebuild: true
    └── force_restart: true
```

### 4️⃣ **Destruir Ambiente** (Cleanup)
```yaml
deployment-manager.yml
└── deployment_type: "infrastructure-only"
    └── terraform_action: "destroy"
```

---

## ⚙️ Opções de Configuração

### **Opções Gerais**
- `instance_name_filter`: Filtro para encontrar EC2 (padrão: "defectdojo")
- `force_rebuild`: Forçar rebuild das imagens Docker
- `force_restart`: Forçar restart dos serviços
- `skip_health_checks`: Pular verificações de saúde (mais rápido)

### **Opções Terraform**
- `terraform_action`: plan/apply/destroy
- `terraform_auto_approve`: Auto-aprovar mudanças

### **Opções de Deploy**
- `deployment_mode`: fast/complete
- `deployment_type`: infrastructure-only/application-only/application-full/full-deployment

---

## 🔐 Secrets Necessários

```yaml
AWS_ROLE_ARN: arn:aws:iam::ACCOUNT:role/GitHubActions-DefectDojo
DB_PASSWORD: MySecurePassword123!
EC2_PRIVATE_KEY: |
  -----BEGIN PRIVATE KEY-----
  [conteúdo completo da chave]
  -----END PRIVATE KEY-----
```

---

## 📋 Benefícios da Nova Estrutura

### ✅ **Flexibilidade Total**
- Deploy apenas infra
- Deploy apenas app (rápido/completo)  
- Deploy completo
- Qualquer combinação

### ✅ **Workflows Unificados**
- **app-deploy-unified.yml** combina fast + complete
- **deployment-manager.yml** orquestra tudo
- Menos duplicação de código

### ✅ **Modo de Desenvolvimento**
- Deploy rápido (5-10 min) para iterações
- Deploy completo (15-20 min) para releases
- Auto-discovery de infraestrutura

### ✅ **Controle Granular**
- Escolha exata do que deployar
- Opções avançadas para cada cenário
- Feedback claro sobre o progresso

---

## 🎉 Casos de Uso Práticos

### 📝 **Desenvolvendo uma Feature**
1. Fazer mudanças no código da pasta `app/`
2. Commit + Push
3. Run workflow: `app-deploy-unified.yml` → `deployment_mode: fast`
4. Testar em 5-10 minutos

### 🚀 **Release para Produção**
1. Code review + merge
2. Run workflow: `app-deploy-unified.yml` → `deployment_mode: complete`
3. Deploy com todas verificações em 15-20 minutos

### 🔧 **Mudança na Infraestrutura**
1. Modificar arquivos Terraform
2. Run workflow: `deployment-manager.yml` → `deployment_type: infrastructure-only`
3. Aplicar mudanças de infra
4. Depois: `deployment_type: application-only` para re-deploy da app

### 🏗️ **Ambiente do Zero**
1. Run workflow: `deployment-manager.yml` → `deployment_type: full-deployment`
2. Aguardar 25-30 minutos
3. DefectDojo completo pronto para uso

---

## 📊 Resumo dos Tempos

| Operação | Tempo | Workflow |
|----------|-------|----------|
| Deploy app (rápido) | 5-10 min | `app-deploy-unified` (fast) |
| Deploy app (completo) | 15-20 min | `app-deploy-unified` (complete) |
| Deploy infra | 10-15 min | `deployment-manager` (infra-only) |
| Deploy completo | 25-30 min | `deployment-manager` (full) |

🎯 **Resultado**: Flexibilidade total com workflows otimizados para cada cenário de uso!
