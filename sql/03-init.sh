#!/usr/bin/env bash
set -euo pipefail
echo "[init] Applying 01-schema.sql..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -i /docker-entrypoint-initdb.d/01-schema.sql
echo "[init] Applying 02-seed-data.sql..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -i /docker-entrypoint-initdb.d/02-seed-data.sql
echo "[init] Done."
