# Ansible Playbooks

Este diretório contém os playbooks do Ansible para automação da infraestrutura.

## Playbooks Disponíveis

- `deploy-defectdojo.yml` - Deploy completo do DefectDojo
- `update-system.yml` - Atualizações de sistema
- `backup.yml` - Rotinas de backup
- `monitoring.yml` - Configuração de monitoramento

## Como Executar

```bash
# Deploy completo
ansible-playbook -i inventories/production.yml playbooks/deploy-defectdojo.yml

# Apenas atualizações
ansible-playbook -i inventories/production.yml playbooks/update-system.yml

# Com tags específicas
ansible-playbook -i inventories/production.yml playbooks/deploy-defectdojo.yml --tags "database"
```

## Variáveis

As variáveis podem ser definidas em:
- `group_vars/` - Variáveis por grupo
- `host_vars/` - Variáveis por host específico
