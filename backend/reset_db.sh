#!/usr/bin/env bash
# Apaga a base de dados local e recria o esquema na próxima arrancagem da API.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
DB="${RIDE4FREE_DB_PATH:-$ROOT/ride4free.db}"

if [[ -f "$DB" ]]; then
  rm -f "$DB"
  echo "Removido: $DB"
else
  echo "Nenhuma base de dados em: $DB"
fi

cd "$ROOT"
if [[ -x ./venv/bin/python ]]; then
  ./venv/bin/python -c "import database as db; db.init_db(); print('Base de dados recriada.')"
elif command -v python3 >/dev/null 2>&1; then
  python3 -c "import database as db; db.init_db(); print('Base de dados recriada.')"
else
  echo "Reinicia ./start.sh para criar a base de dados."
fi
