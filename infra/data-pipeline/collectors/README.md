# Data Pipeline - Collectors

Este diretório contém os coletores de dados para o pipeline de segurança.

## Coletores Disponíveis

- `vulnerability_scanner.py` - Coleta resultados de scanners de vulnerabilidade
- `log_collector.py` - Coleta logs de sistemas de segurança
- `api_collector.py` - Coleta dados via APIs de ferramentas de segurança
- `file_watcher.py` - Monitora arquivos de relatórios

## Configuração

Os coletores são configurados através de arquivos YAML:

```yaml
collectors:
  vulnerability_scanner:
    enabled: true
    interval: 3600  # segundos
    sources:
      - nessus
      - openvas
      - nuclei
```

## Execução

```bash
python collectors/vulnerability_scanner.py --config config.yaml
```
