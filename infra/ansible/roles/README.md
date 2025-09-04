# Ansible Roles

Este diretório contém as roles do Ansible para configuração modular dos serviços.

## Roles Disponíveis

- `common/` - Configurações básicas do sistema
- `docker/` - Instalação e configuração do Docker
- `defectdojo/` - Configuração específica do DefectDojo
- `nginx/` - Proxy reverso e balanceamento de carga
- `ssl/` - Certificados SSL/TLS
- `monitoring/` - Configuração de monitoramento
- `backup/` - Rotinas de backup automatizado

## Estrutura de uma Role

```
role_name/
├── tasks/main.yml          # Tarefas principais
├── handlers/main.yml       # Handlers para restart de serviços
├── templates/             # Templates Jinja2
├── files/                 # Arquivos estáticos
├── vars/main.yml          # Variáveis da role
├── defaults/main.yml      # Valores padrão
└── meta/main.yml          # Metadados e dependências
```

## Como Criar uma Nova Role

```bash
ansible-galaxy init roles/nova_role
```
