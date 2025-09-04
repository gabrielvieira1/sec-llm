#!/usr/bin/env python3
"""
Vulnerability Classifier Training Script
Treina modelo para classificação automática de vulnerabilidades
"""

import pandas as pd
import yaml
import joblib
import logging
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.preprocessing import StandardScaler, LabelEncoder
import argparse


class VulnerabilityClassifier:
    def __init__(self, config_path):
        self.config = self._load_config(config_path)
        self.setup_logging()
        self.model = None
        self.scaler = StandardScaler()
        self.label_encoder = LabelEncoder()

    def _load_config(self, config_path):
        """Carrega configuração do arquivo YAML"""
        with open(config_path, 'r') as f:
            return yaml.safe_load(f)

    def setup_logging(self):
        """Configura logging"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)

    def load_data(self):
        """Carrega dados de treinamento"""
        self.logger.info("Carregando dados...")

        train_path = self.config['data']['train_path']
        self.data = pd.read_csv(train_path)

        self.logger.info(f"Dados carregados: {self.data.shape}")
        return self.data

    def preprocess_data(self):
        """Pré-processa dados para treinamento"""
        self.logger.info("Pré-processando dados...")

        # Selecionar features configuradas
        features = self.config['data']['features']
        X = self.data[features]
        y = self.data['severity']  # Target variable

        # Tratar valores faltantes
        X = X.fillna(X.mean())

        # Normalizar features numéricas
        X_scaled = self.scaler.fit_transform(X)

        # Codificar labels
        y_encoded = self.label_encoder.fit_transform(y)

        return X_scaled, y_encoded

    def train_model(self, X, y):
        """Treina o modelo"""
        self.logger.info("Iniciando treinamento...")

        # Split train/validation
        val_split = self.config['training']['validation_split']
        X_train, X_val, y_train, y_val = train_test_split(
            X, y, test_size=val_split, random_state=42, stratify=y
        )

        # Configurar modelo
        model_config = self.config['model']['parameters']
        self.model = RandomForestClassifier(**model_config)

        # Treinar
        self.model.fit(X_train, y_train)

        # Cross-validation
        cv_folds = self.config['training']['cross_validation']
        cv_scores = cross_val_score(self.model, X_train, y_train, cv=cv_folds)

        self.logger.info(
            f"CV Score: {cv_scores.mean():.4f} (+/- {cv_scores.std() * 2:.4f})")

        # Validação
        y_pred = self.model.predict(X_val)

        # Métricas
        self.logger.info("Classification Report:")
        print(classification_report(y_val, y_pred))

        return self.model

    def save_model(self, output_path):
        """Salva modelo treinado"""
        self.logger.info(f"Salvando modelo em {output_path}")

        model_data = {
            'model': self.model,
            'scaler': self.scaler,
            'label_encoder': self.label_encoder,
            'features': self.config['data']['features']
        }

        joblib.dump(model_data, output_path)
        self.logger.info("Modelo salvo com sucesso!")

    def run_training(self):
        """Executa pipeline completo de treinamento"""
        # Carregar dados
        self.load_data()

        # Pré-processar
        X, y = self.preprocess_data()

        # Treinar
        self.train_model(X, y)

        # Salvar
        output_path = self.config.get(
            'output_path', 'models/vulnerability_classifier.pkl')
        self.save_model(output_path)


def main():
    parser = argparse.ArgumentParser(
        description='Train vulnerability classifier')
    parser.add_argument('--config', required=True, help='Path to config file')
    args = parser.parse_args()

    trainer = VulnerabilityClassifier(args.config)
    trainer.run_training()


if __name__ == "__main__":
    main()
