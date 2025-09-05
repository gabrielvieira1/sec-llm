#!/bin/bash

# Script para criar RDS PostgreSQL via AWS CLI e gerar configuração para DefectDojo
# Execute: ./setup-rds-for-defectdojo.sh

set -e

# Configurações
RDS_INSTANCE_ID="defectdojo-postgres-$(date +%Y%m%d%H%M%S)"
RDS_USERNAME="defectdojo"
RDS_PASSWORD="MySecurePassword123!"
RDS_DB_NAME="defectdojo"
RDS_INSTANCE_CLASS="db.t3.micro"
AWS_REGION="us-east-1"

echo "🚀 Criando RDS PostgreSQL para DefectDojo..."
echo "📋 Configurações:"
echo "  - Instance ID: $RDS_INSTANCE_ID"
echo "  - Username: $RDS_USERNAME"
echo "  - Database: $RDS_DB_NAME"
echo "  - Instance Class: $RDS_INSTANCE_CLASS"
echo "  - Region: $AWS_REGION"
echo ""

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ AWS CLI não está configurado ou sem permissões"
    echo "Execute: aws configure"
    exit 1
fi

# Obter VPC padrão
echo "🔍 Obtendo informações da VPC padrão..."
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --region $AWS_REGION --query 'Vpcs[0].VpcId' --output text)

if [ "$DEFAULT_VPC" = "None" ] || [ -z "$DEFAULT_VPC" ]; then
    echo "❌ VPC padrão não encontrada"
    exit 1
fi

echo "✅ VPC padrão: $DEFAULT_VPC"

# Obter subnets da VPC padrão
echo "🔍 Obtendo subnets..."
SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC" --region $AWS_REGION --query 'Subnets[].SubnetId' --output text)
SUBNET_LIST=$(echo $SUBNETS | tr ' ' ',')

echo "✅ Subnets encontradas: $SUBNET_LIST"

# Criar security group para RDS
echo "🔒 Criando Security Group para RDS..."
SG_ID=$(aws ec2 create-security-group \
    --group-name "defectdojo-rds-sg-$(date +%Y%m%d%H%M%S)" \
    --description "Security group for DefectDojo RDS PostgreSQL" \
    --vpc-id $DEFAULT_VPC \
    --region $AWS_REGION \
    --query 'GroupId' \
    --output text)

echo "✅ Security Group criado: $SG_ID"

# Adicionar regra para PostgreSQL (aberto para desenvolvimento)
echo "🔐 Configurando regras de segurança..."
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 5432 \
    --cidr 0.0.0.0/0 \
    --region $AWS_REGION

echo "✅ Regra PostgreSQL adicionada (porta 5432 aberta)"

# Criar DB subnet group
echo "🌐 Criando DB Subnet Group..."
DB_SUBNET_GROUP="defectdojo-subnet-group-$(date +%Y%m%d%H%M%S)"

aws rds create-db-subnet-group \
    --db-subnet-group-name $DB_SUBNET_GROUP \
    --db-subnet-group-description "Subnet group for DefectDojo PostgreSQL" \
    --subnet-ids $SUBNETS \
    --region $AWS_REGION

echo "✅ DB Subnet Group criado: $DB_SUBNET_GROUP"

# Criar RDS instance
echo "🗄️ Criando instância RDS PostgreSQL..."
echo "⏳ Isso pode levar 5-10 minutos..."

aws rds create-db-instance \
    --db-instance-identifier $RDS_INSTANCE_ID \
    --db-instance-class $RDS_INSTANCE_CLASS \
    --engine postgres \
    --engine-version 16.4 \
    --master-username $RDS_USERNAME \
    --master-user-password $RDS_PASSWORD \
    --allocated-storage 20 \
    --storage-type gp2 \
    --vpc-security-group-ids $SG_ID \
    --db-subnet-group-name $DB_SUBNET_GROUP \
    --db-name $RDS_DB_NAME \
    --publicly-accessible \
    --no-multi-az \
    --storage-encrypted \
    --backup-retention-period 0 \
    --no-deletion-protection \
    --region $AWS_REGION

echo "✅ Instância RDS criada: $RDS_INSTANCE_ID"
echo "⏳ Aguardando instância ficar disponível..."

# Aguardar instância ficar disponível
aws rds wait db-instance-available --db-instance-identifier $RDS_INSTANCE_ID --region $AWS_REGION

echo "✅ Instância RDS está disponível!"

# Obter endpoint da instância
RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier $RDS_INSTANCE_ID \
    --region $AWS_REGION \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

RDS_PORT=$(aws rds describe-db-instances \
    --db-instance-identifier $RDS_INSTANCE_ID \
    --region $AWS_REGION \
    --query 'DBInstances[0].Endpoint.Port' \
    --output text)

# Construir URL do banco
DATABASE_URL="postgresql://$RDS_USERNAME:$RDS_PASSWORD@$RDS_ENDPOINT:$RDS_PORT/$RDS_DB_NAME"

echo ""
echo "🎉 RDS PostgreSQL criado com sucesso!"
echo ""
echo "📋 Informações da instância:"
echo "  - Instance ID: $RDS_INSTANCE_ID"
echo "  - Endpoint: $RDS_ENDPOINT"
echo "  - Port: $RDS_PORT"
echo "  - Database URL: $DATABASE_URL"
echo ""

# Criar arquivo .env.local atualizado
echo "📝 Criando arquivo .env.local..."
cat > .env.local << EOF
# DefectDojo Local Development com RDS AWS
# Arquivo gerado automaticamente em $(date)

# Database Configuration (AWS RDS)
DD_DATABASE_URL=$DATABASE_URL

# DefectDojo Configuration
DD_DEBUG=True
DD_ALLOWED_HOSTS=*
DD_SECRET_KEY=hhZCp@D28z!n@NED*yB!ROMt+WzsY*iq
DD_CREDENTIAL_AES_256_KEY=&91a*agLqesc*0DJ+2*bAbsUZfR*4nLw

# Admin User Configuration
DD_ADMIN_USER=admin
DD_ADMIN_MAIL=admin@defectdojo.local
DD_ADMIN_PASSWORD=DefectDojoMVP2024!
DD_ADMIN_FIRST_NAME=Admin
DD_ADMIN_LAST_NAME=User
DD_INITIALIZE=true

# Redis Configuration (local)
DD_CELERY_BROKER_URL=redis://redis:6379/0

# Media files
DD_MEDIA_ROOT=/app/media

# Timezone
DD_TIME_ZONE=America/Sao_Paulo
EOF

# Criar docker-compose.override.yml atualizado
echo "📝 Atualizando docker-compose.override.yml..."
cat > docker-compose.override.yml << EOF
# docker-compose.override.yml para desenvolvimento local com RDS AWS
# Este arquivo sobrescreve as configurações do docker-compose.yml principal
# Arquivo gerado automaticamente em $(date)

services:
  # Remove o container postgres local (usaremos o RDS)
  postgres:
    profiles:
      - disabled  # Desabilita o postgres local
  
  # Configurações para usar RDS externo
  uwsgi:
    env_file:
      - .env.local
    environment:
      DD_DATABASE_URL: $DATABASE_URL
      DD_DEBUG: "True"
      DD_ALLOWED_HOSTS: "*"
    # Remove dependência do postgres local
    depends_on:
      initializer:
        condition: service_completed_successfully
      redis:
        condition: service_started

  celerybeat:
    env_file:
      - .env.local
    environment:
      DD_DATABASE_URL: $DATABASE_URL
    # Remove dependência do postgres local
    depends_on:
      initializer:
        condition: service_completed_successfully
      redis:
        condition: service_started

  celeryworker:
    env_file:
      - .env.local
    environment:
      DD_DATABASE_URL: $DATABASE_URL
    # Remove dependência do postgres local
    depends_on:
      initializer:
        condition: service_completed_successfully
      redis:
        condition: service_started

  initializer:
    env_file:
      - .env.local
    environment:
      DD_DATABASE_URL: $DATABASE_URL
      DD_ADMIN_USER: admin
      DD_ADMIN_MAIL: admin@defectdojo.local
      DD_ADMIN_PASSWORD: DefectDojoMVP2024!
      DD_ADMIN_FIRST_NAME: Admin
      DD_ADMIN_LAST_NAME: User
      DD_INITIALIZE: "true"
    # Remove dependência do postgres local - inicializador se conecta diretamente ao RDS
EOF

echo "✅ Arquivos de configuração atualizados!"

# Testar conectividade
echo ""
echo "🔍 Testando conectividade com RDS..."
if command -v psql &> /dev/null; then
    PGPASSWORD=$RDS_PASSWORD psql -h $RDS_ENDPOINT -U $RDS_USERNAME -d $RDS_DB_NAME -c "SELECT version();" && echo "✅ Conexão com RDS funcionando!"
else
    echo "ℹ️ psql não encontrado. Instale para testar a conexão:"
    echo "   Ubuntu/Debian: sudo apt-get install postgresql-client"
    echo "   macOS: brew install postgresql"
fi

# Salvar informações para cleanup futuro
cat > rds-info.txt << EOF
# Informações do RDS criado em $(date)
RDS_INSTANCE_ID=$RDS_INSTANCE_ID
SECURITY_GROUP_ID=$SG_ID
DB_SUBNET_GROUP=$DB_SUBNET_GROUP
DATABASE_URL=$DATABASE_URL
ENDPOINT=$RDS_ENDPOINT
PORT=$RDS_PORT

# Para deletar os recursos:
# aws rds delete-db-instance --db-instance-identifier $RDS_INSTANCE_ID --skip-final-snapshot --region $AWS_REGION
# aws rds delete-db-subnet-group --db-subnet-group-name $DB_SUBNET_GROUP --region $AWS_REGION  
# aws ec2 delete-security-group --group-id $SG_ID --region $AWS_REGION
EOF

echo ""
echo "🎯 Próximos passos:"
echo "1. Execute: docker-compose up -d"
echo "2. Acesse: http://localhost:8080"
echo "3. Login: admin / DefectDojoMVP2024!"
echo ""
echo "📁 Arquivos criados/atualizados:"
echo "  - .env.local"
echo "  - docker-compose.override.yml"
echo "  - rds-info.txt (informações para limpeza)"
echo ""
echo "🗑️ Para deletar o RDS depois:"
echo "   ./cleanup-rds.sh"
