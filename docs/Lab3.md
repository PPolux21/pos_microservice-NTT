# Lab 3

## Objetivo

Implementar reposición y ajuste de inventario garantizando que todo cambio de stock genera un movimiento, que los tipos de ajuste inválidos se rechazan y que el stock nunca queda bajo cero, con stock y movimientos consistentes.

## Cambios realizados

- `src/main/java/com/masterclass/inventory/service/InventoryService.java` (modificado, único archivo del lab):
  - `move()` pasa de `public` a `private`: las únicas entradas son `replenish()` (fija `REPLENISHMENT`) y `adjust()` (solo acepta `ADJUSTMENT_IN`/`ADJUSTMENT_OUT`, otro tipo → `BusinessException` 409). Nadie externo puede mutar stock saltándose la validación de tipos (verificado: sin llamadores externos).
  - Guard `if (qty <= 0) throw new BusinessException(...)` en `move()`: convierte un posible 500 (violación del CHECK `ck_movements_qty`) en 409 limpio.
- Sin archivos nuevos: el diseño ya cumplía los invariantes y se reutilizó (`move()` actualiza stock y siempre hace `movements.save(...)` dentro del mismo `@Transactional`; pre-chequeo `currentStock < qty` → 409 antes de `decreaseStock()`; `@Positive` en `InventoryDtos`; historial en `GET /inventory/movements/{productId}`).

## Cómo cumple el laboratorio

- Cada mutación escribe su fila (`REPLENISHMENT` / `ADJUSTMENT_IN` / `ADJUSTMENT_OUT`): si falla el `save`, el `@Transactional` revierte también el cambio de stock.
- Tipo inválido (`SALE` u otro en `/adjustment`) → 409 `Invalid adjustment type`, sin tocar stock.
- `ADJUSTMENT_OUT` por encima del stock → 409 `Insufficient stock...`, stock intacto (triple barrera: chequeo del servicio → `Product.decreaseStock()` → CHECK `ck_products_stock` en DB).
- Consistencia verificada extremo a extremo contra la API real (ver Validación).

## Validación

- `mvn -B compile` y `mvn -B test -Dtest=SaleServiceTest` → BUILD SUCCESS, 1/1 verde.
- App levantada con `java -jar target/inventory-pos-service-1.0.0.jar` contra el SQL Server del Lab 1 (`/actuator/health` → `UP`; además confirma que el fallo de arranque visto en `path.java` era del classpath del IDE en Windows, no del proyecto).
- Escenarios vía `curl` (Basic `admin/admin123`): replenish +10 al producto 1 → 201, stock 120→130; adjust OUT 5 → 201, stock →125; adjust OUT 9999 → 409 con stock intacto; adjust tipo `SALE` → 409; `GET /movements/1` con las 2 filas; `GET /products/1` con `currentStock: 125` (= 120+10−5).
- Limpieza posterior vía `sqlcmd`: borrados los movimientos de prueba y restaurado `current_stock=120`; seed queda prístino (120/80/30/12, 0 movimientos) para los siguientes labs. App detenida tras validar.
- Nota de diseño: sin bloqueo pesimista ni `@Version`; dos ajustes concurrentes sobre el último stock podrían colisionar (la DB impide el negativo vía CHECK). Documentado como riesgo aceptado para el curso, sin sobreingeniería.
