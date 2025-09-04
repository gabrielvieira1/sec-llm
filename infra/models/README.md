# ML Models

Este diretório contém os modelos de machine learning para análise de vulnerabilidades.

## Estrutura

- `notebooks/` - Jupyter notebooks para experimentação e análise
- `training/` - Scripts de treinamento de modelos
- `models/` - Modelos treinados e salvos
- `evaluation/` - Scripts de avaliação de modelos

## Modelos Disponíveis

### 1. Vulnerability Classification
- **Objetivo**: Classificar vulnerabilidades por tipo e severidade
- **Modelo**: Random Forest / XGBoost
- **Features**: CVE description, CVSS metrics, affected components

### 2. Risk Assessment
- **Objetivo**: Avaliar risco baseado em contexto
- **Modelo**: Neural Networks
- **Features**: Environment data, asset criticality, threat intelligence

### 3. False Positive Detection
- **Objetivo**: Identificar falsos positivos automaticamente
- **Modelo**: SVM / Deep Learning
- **Features**: Scanner output, historical data, context

## Pipeline de ML

```
Raw Data → Feature Engineering → Model Training → Validation → Deployment
```

## Como Usar

```bash
# Treinar modelo
python training/train_vulnerability_classifier.py --config config.yaml

# Avaliar modelo
python evaluation/evaluate_model.py --model models/vuln_classifier.pkl

# Fazer predições
python inference/predict.py --input data.json --model models/vuln_classifier.pkl
```
