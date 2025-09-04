# SEC-LLM Monorepo

Este repositório contém:
- **app/**: DefectDojo application 
- **infra/**: AWS infrastructure (Terraform)
- **docs/**: Documentation

## Quick Start

### Deploy Infrastructure
```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```

### Deploy Application  
```bash
cd infra
./build-and-push.sh
./deploy.sh
```

