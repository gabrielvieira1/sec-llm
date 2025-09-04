#!/usr/bin/env python3
"""
Data Normalization Script
Normaliza dados de vulnerabilidades de diferentes fontes para formato padrão
"""

import json
import pandas as pd
import yaml
from datetime import datetime
from typing import Dict, List, Any


class DataNormalizer:
    def __init__(self, config_path: str):
        self.config = self._load_config(config_path)
        self.mapping = self._load_mapping()

    def _load_config(self, config_path: str) -> Dict:
        """Carrega configuração"""
        with open(config_path, 'r') as f:
            return yaml.safe_load(f)

    def _load_mapping(self) -> Dict:
        """Carrega mapeamentos de normalização"""
        mapping_file = self.config['preprocessing']['normalize']['mapping_file']
        with open(mapping_file, 'r') as f:
            return yaml.safe_load(f)

    def normalize_nessus_data(self, data: Dict) -> List[Dict]:
        """Normaliza dados do Nessus"""
        normalized = []

        for vulnerability in data.get('vulnerabilities', []):
            normalized_vuln = {
                'id': vulnerability.get('plugin_id'),
                'title': vulnerability.get('plugin_name'),
                'description': vulnerability.get('description'),
                'severity': self._map_severity(vulnerability.get('severity'), 'nessus'),
                'cvss_score': vulnerability.get('cvss_base_score'),
                'cve': vulnerability.get('cve', []),
                'solution': vulnerability.get('solution'),
                'references': vulnerability.get('see_also', []),
                'affected_hosts': vulnerability.get('hosts', []),
                'scanner': 'nessus',
                'scan_date': datetime.now().isoformat(),
                'raw_data': vulnerability
            }
            normalized.append(normalized_vuln)

        return normalized

    def normalize_nuclei_data(self, data: List[Dict]) -> List[Dict]:
        """Normaliza dados do Nuclei"""
        normalized = []

        for finding in data:
            normalized_vuln = {
                'id': finding.get('template-id'),
                'title': finding.get('info', {}).get('name'),
                'description': finding.get('info', {}).get('description'),
                'severity': self._map_severity(finding.get('info', {}).get('severity'), 'nuclei'),
                'cvss_score': self._extract_cvss_from_nuclei(finding),
                'cve': finding.get('info', {}).get('classification', {}).get('cve-id', []),
                'solution': finding.get('info', {}).get('remediation'),
                'references': finding.get('info', {}).get('reference', []),
                'affected_hosts': [finding.get('host')],
                'scanner': 'nuclei',
                'scan_date': finding.get('timestamp'),
                'raw_data': finding
            }
            normalized.append(normalized_vuln)

        return normalized

    def _map_severity(self, severity: str, scanner: str) -> str:
        """Mapeia severidade para padrão comum"""
        mapping = self.mapping.get('severity_mapping', {}).get(scanner, {})
        return mapping.get(severity.lower(), 'Unknown') if severity else 'Unknown'

    def _extract_cvss_from_nuclei(self, finding: Dict) -> float:
        """Extrai CVSS score dos dados do Nuclei"""
        classification = finding.get('info', {}).get('classification', {})
        cvss_metrics = classification.get('cvss-metrics')
        if cvss_metrics:
            # Parse CVSS metrics string para extrair score
            # Implementar parsing baseado no formato CVSS
            pass
        return 0.0

    def normalize_data(self, raw_data: Dict, scanner_type: str) -> List[Dict]:
        """Normaliza dados baseado no tipo de scanner"""
        if scanner_type == 'nessus':
            return self.normalize_nessus_data(raw_data)
        elif scanner_type == 'nuclei':
            return self.normalize_nuclei_data(raw_data)
        else:
            raise ValueError(f"Scanner type '{scanner_type}' not supported")

    def save_normalized_data(self, data: List[Dict], output_path: str):
        """Salva dados normalizados"""
        with open(output_path, 'w') as f:
            json.dump(data, f, indent=2, default=str)


if __name__ == "__main__":
    normalizer = DataNormalizer("config.yaml")

    # Exemplo de uso
    with open("raw_data/nessus_scan.json", 'r') as f:
        raw_data = json.load(f)

    normalized = normalizer.normalize_data(raw_data, "nessus")
    normalizer.save_normalized_data(
        normalized, "processed/normalized_data.json")
