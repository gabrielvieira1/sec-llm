#!/bin/bash

# Script para limpar recursos RDS criados pelo setup-rds-for-defectdojo.sh

set -e

echo "🗑️ Limpando recursos RDS do DefectDojo..."

# Verificar se arquivo de informações existe
if [ ! -f "rds-info.txt" ]; then
    echo "❌ Arquivo rds-info.txt não encontrado"
    echo "Este arquivo é criado pelo setup-rds-for-defectdojo.sh"
    exit 1
fi

# Ler informações do arquivo
source rds-info.txt

echo "📋 Recursos que serão deletados:"
echo "  - RDS Instance: $RDS_INSTANCE_ID"
echo "  - Security Group: $SECURITY_GROUP_ID"  
echo "  - DB Subnet Group: $DB_SUBNET_GROUP"
echo ""

read -p "⚠️ Confirma a exclusão? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelado pelo usuário"
    exit 1
fi

echo "🗄️ Deletando instância RDS..."
aws rds delete-db-instance \
    --db-instance-identifier $RDS_INSTANCE_ID \
    --skip-final-snapshot \
    --region us-east-1

echo "⏳ Aguardando instância ser deletada..."
aws rds wait db-instance-deleted --db-instance-identifier $RDS_INSTANCE_ID --region us-east-1

echo "🌐 Deletando DB Subnet Group..."
aws rds delete-db-subnet-group \
    --db-subnet-group-name $DB_SUBNET_GROUP \
    --region us-east-1

echo "🔒 Deletando Security Group..."
aws ec2 delete-security-group \
    --group-id $SECURITY_GROUP_ID \
    --region us-east-1

# Limpar arquivos locais
echo "📁 Removendo arquivos de configuração..."
rm -f rds-info.txt

echo ""
echo "✅ Recursos RDS removidos com sucesso!"
echo ""
echo "🔧 Restaurar configuração local:"
echo "1. Remover docker-compose.override.yml"
echo "2. Usar: docker-compose up -d (com postgres local)"
