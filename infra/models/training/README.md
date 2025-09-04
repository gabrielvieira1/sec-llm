# Training Scripts

Este diretório contém scripts para treinamento de modelos de machine learning.

## Scripts Disponíveis

- `train_classifier.py` - Treina classificador de vulnerabilidades
- `train_risk_model.py` - Treina modelo de avaliação de risco
- `train_fp_detector.py` - Treina detector de falsos positivos
- `hyperparameter_tuning.py` - Otimização de hiperparâmetros

## Configuração

Todos os scripts usam arquivos YAML para configuração:

```yaml
model:
  type: "random_forest"
  parameters:
    n_estimators: 100
    max_depth: 10
    random_state: 42

data:
  train_path: "data/train.csv"
  test_path: "data/test.csv"
  features:
    - cvss_score
    - cwe_id
    - description_length
    
training:
  validation_split: 0.2
  cross_validation: 5
  early_stopping: true
```

## Execução

```bash
# Treinamento básico
python train_classifier.py --config configs/classifier_config.yaml

# Com tuning de hiperparâmetros
python hyperparameter_tuning.py --config configs/tuning_config.yaml

# Avaliação do modelo
python evaluate.py --model models/trained_model.pkl --test-data data/test.csv
```

## Outputs

- Modelos treinados salvos em formato pickle/joblib
- Métricas de performance em JSON
- Gráficos de avaliação em PNG
- Logs detalhados de treinamento
