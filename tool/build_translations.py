"""Build the offline UTF-8 dictionaries from localization_catalog.tsv."""
import csv
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
codes = ['en', 'es', 'pt', 'tr', 'fr', 'de', 'id', 'vi']
catalogs = {code: {} for code in codes}
with (root / 'tool/localization_catalog.tsv').open(encoding='utf-8') as stream:
    for line, row in enumerate(csv.reader(stream, delimiter='|'), 1):
        if not row or row[0].startswith('#'):
            continue
        if len(row) != 8:
            raise ValueError(f'Line {line}: expected 8 columns, got {len(row)}')
        row = [value.strip().replace('\\n', '\n') for value in row]
        if row[0] in catalogs['en']:
            raise ValueError(f'Duplicate source on line {line}: {row[0]}')
        for code, value in zip(codes, row):
            if not value:
                raise ValueError(f'Empty {code} translation on line {line}')
            catalogs[code][row[0]] = value
target = root / 'assets/l10n'
target.mkdir(exist_ok=True, parents=True)
for code, catalog in catalogs.items():
    (target / f'{code}.json').write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'Built {len(catalogs["en"])} messages in {len(codes)} languages.')
