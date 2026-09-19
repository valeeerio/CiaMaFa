#!/usr/bin/env bash
# Lancia CiaMaFa con la configurazione di env.json.
# Uso: ./run.sh            -> simulatore "iPhone 17 Pro"
#      ./run.sh <device>   -> altro device (nome o id di `flutter devices`)
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f env.json ]; then
  echo "env.json mancante: copia env.example.json in env.json e compila i valori." >&2
  exit 1
fi

exec flutter run -d "${1:-iPhone 17 Pro}" --dart-define-from-file=env.json
