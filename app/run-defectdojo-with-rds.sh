#!/bin/bash

# Script para executar DefectDojo localmente conectando ao RDS AWS
# Execute: ./run-defectdojo-with-rds.sh

set -e

echo "🚀 Iniciando DefectDojo com RDS AWS..."

# Verificar se o arquivo .env.local existe
if [ ! -f ".env.local" ]; then
    echo "❌ Arquivo .env.local não encontrado!"
    echo "Certifique-se de que o arquivo .env.local está no diretório app/"
    exit 1
fi

# Verificar conectividade com RDS
echo "🔍 Testando conectividade com RDS..."
if command -v psql &> /dev/null; then
    echo "Testando conexão com PostgreSQL..."
    PGPASSWORD=MySecurePassword123! psql -h sec-llm-infra-defectdojo-postgres.cmrkgu8kcrq9.us-east-1.rds.amazonaws.com -U defectdojo -d defectdojo -c "SELECT version();" || echo "⚠️ Teste de conexão falhou, mas continuando..."
else
    echo "⚠️ psql não encontrado. Instalando cliente PostgreSQL..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y postgresql-client
    elif command -v brew &> /dev/null; then
        brew install postgresql
    else
        echo "ℹ️ Instale o cliente PostgreSQL manualmente se necessário"
    fi
fi

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose down -v

# Remover volumes locais do postgres (não precisamos mais)
echo "🧹 Limpando volumes locais do PostgreSQL..."
docker volume rm defectdojo_postgres 2>/dev/null || true

# Construir e executar com RDS
echo "🏗️ Construindo e iniciando containers com RDS..."
docker-compose up --build -d

# Aguardar inicialização
echo "⏳ Aguardando inicialização..."
sleep 30

# Verificar status
echo "📊 Status dos containers:"
docker-compose ps

# Verificar logs do inicializador
echo "📋 Logs do inicializador:"
docker-compose logs initializer

# Verificar se está funcionando
echo "🌐 Testando acesso local..."
sleep 10
if curl -s http://localhost:8080 > /dev/null; then
    echo "✅ DefectDojo está rodando!"
    echo ""
    echo "🎯 Acesso:"
    echo "  URL: http://localhost:8080"
    echo "  Usuário: admin"
    echo "  Senha: DefectDojoMVP2024!"
    echo ""
    echo "🔍 Comandos úteis:"
    echo "  docker-compose logs -f          # Ver logs em tempo real"
    echo "  docker-compose ps               # Status dos containers"
    echo "  docker-compose restart          # Reiniciar serviços"
    echo "  docker-compose down             # Parar tudo"
else
    echo "❌ DefectDojo não está respondendo. Verifique os logs:"
    echo "docker-compose logs"
fi
