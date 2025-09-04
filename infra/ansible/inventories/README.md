# Ansible Inventories

Este diretório contém os inventários do Ansible para diferentes ambientes.

## Estrutura

- `production.yml` - Inventário para ambiente de produção
- `staging.yml` - Inventário para ambiente de staging  
- `development.yml` - Inventário para ambiente de desenvolvimento

## Exemplo de Uso

```bash
ansible-playbook -i inventories/production.yml playbooks/deploy.yml
```

## Configuração

Os inventários definem:
- Hosts e grupos de servidores
- Variáveis específicas por ambiente
- Configurações de conexão SSH
