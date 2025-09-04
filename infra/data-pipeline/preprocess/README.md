# Data Pipeline - Preprocessing

Este diretório contém os scripts de pré-processamento de dados de segurança.

## Processadores Disponíveis

- `normalize_data.py` - Normaliza dados de diferentes fontes
- `enrich_data.py` - Enriquece dados com informações adicionais
- `deduplicate.py` - Remove duplicatas de vulnerabilidades
- `categorize.py` - Categoriza vulnerabilidades por severidade e tipo

## Fluxo de Processamento

```
Raw Data → Normalize → Enrich → Deduplicate → Categorize → Clean Data
```

## Configuração

```yaml
preprocessing:
  normalize:
    enabled: true
    mapping_file: "mappings/cvss_mapping.yaml"
  
  enrich:
    enabled: true
    threat_intel_api: "https://api.threatintel.com"
    
  deduplicate:
    enabled: true
    similarity_threshold: 0.85
```

## Execução

```bash
# Processar todos os dados
python preprocess/pipeline.py --input data/raw --output data/processed

# Processar apenas normalização
python preprocess/normalize_data.py --config config.yaml
```
