# ML Notebooks

Este diretório contém notebooks Jupyter para experimentação e análise de dados de segurança.

## Notebooks Disponíveis

- `data_exploration.ipynb` - Análise exploratória de dados de vulnerabilidades
- `feature_engineering.ipynb` - Criação e seleção de features
- `model_training.ipynb` - Treinamento de modelos de classificação
- `vulnerability_analysis.ipynb` - Análise detalhada de vulnerabilidades
- `risk_assessment.ipynb` - Modelos de avaliação de risco

## Setup do Ambiente

```bash
# Instalar dependências
pip install jupyter pandas scikit-learn matplotlib seaborn

# Iniciar Jupyter
jupyter lab
```

## Datasets

Os notebooks utilizam datasets de:
- CVE National Vulnerability Database
- DefectDojo exported data
- Scanner outputs (Nessus, Nuclei, etc.)
- Threat intelligence feeds

## Best Practices

1. **Versionamento**: Use nbstripout para limpar outputs
2. **Documentação**: Mantenha células markdown explicativas
3. **Reproducibilidade**: Use seeds aleatórias fixas
4. **Performance**: Profile código intensivo
5. **Visualização**: Use plots informativos e claros
