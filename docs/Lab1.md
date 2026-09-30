# Lab 1

## Objetivo

Levantar el contenedor de SQL Server, ejecutar el script de esquema y el script de seed, y validar las categorías y productos iniciales con sus constraints (PK, FK, UNIQUE, NOT NULL, CHECK).

## Cambios realizados

- `sql/01-schema.sql` (modificado): tablas e índices idempotentes (`IF OBJECT_ID` / `IF NOT EXISTS` en `sys.indexes`); agregados los CHECKs `ck_products_status` (`ACTIVE,INACTIVE,DISCONTINUED`) y `ck_movements_type` (`REPLENISHMENT,ADJUSTMENT_IN,ADJUSTMENT_OUT,SALE`); bloque `ALTER TABLE ... WITH NOCHECK` que agrega esos CHECKs a volúmenes creados con el script anterior.
- `sql/02-seed-data.sql` (modificado): seed idempotente (`IF NOT EXISTS` por `name`/`sku`); `category_id` resuelto por nombre mediante variables en lugar de valores IDENTITY hardcodeados (`1-4`).
- `sql/03-init.sh` (modificado): `set -euo pipefail` y mensajes de progreso al aplicar cada script.
- `docker-compose.yml` (modificado): eliminado el volumen `./sql:/docker-entrypoint-initdb.d` del servicio `sqlserver` (la imagen MSSQL lo ignora; el bootstrap lo ejecuta `sqlserver-init`).

## Cómo cumple el laboratorio

- El flujo `sqlserver (healthy)` → `sqlserver-init` aplica esquema y seed de forma re-ejecutable: el seed deja 4 categorías y 4 productos sin duplicados.
- Los constraints exigidos quedan en la base de datos: PK IDENTITY, FK categorías/productos, UNIQUE en `categories.name` y `products.sku`, NOT NULL, CHECKs de stock (`>= 0`), cantidad de movimientos/detalles (`> 0`), más los nuevos CHECKs de `status` y `movement_type`.
- Criterio de aceptación: se puede consultar `products` con su categoría y explicar cada constraint a partir de su definición en `01-schema.sql` y de los errores observados al violarlos.

## Validación

- Bootstrap limpio verificado: `docker compose down -v`, `docker compose up -d sqlserver`, esperar `healthy`, `docker compose run --rm sqlserver-init` → 4 categorías, 4 productos, 6 CHECKs.
- Idempotencia verificada: segundo `docker compose run --rm sqlserver-init` → sigue 4/4, sin errores ni duplicados.
- Constraints verificados con `sqlcmd` (inserts que deben fallar): SKU duplicado → `uk_products_sku` (Msg 2627); `category_id` inexistente → `fk_products_categories`; stock negativo → `ck_products_stock`; `status='BROKEN'` → `ck_products_status`; `movement_type='HACK'` → `ck_movements_type` (todos Msg 547); conteos finales intactos (4 productos, 0 movimientos).
