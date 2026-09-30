# Lab 5

## Objetivo

Responder preguntas operativas desde datos persistidos: productos con bajo stock, valor total del inventario, ventas diarias e historial de movimientos.

## Cambios realizados

- `src/main/java/com/masterclass/inventory/repository/ProductRepository.java` (modificado): agregadas `findLowStock()` (JPQL `status=ACTIVE AND currentStock <= reorderLevel`, a nivel DB) y `totalInventoryValue()` (`sum(unitPrice * currentStock)`), más el import `java.math.BigDecimal` que faltaba (sin él, la app no arrancaba: `ClassNotFoundException: BigDecimal` al inspeccionar el repositorio).
- `src/main/java/com/masterclass/inventory/service/ReportService.java` (modificado): `lowStock()` usa `findLowStock()` en vez de filtrar `findAll()` en memoria; nuevo `inventoryValue()` que devuelve el total agregado (con `ZERO` si no hay productos) y el conteo; mapeo fila→DTO extraído a `toReport()` privado; import no usado de `ProductStatus` eliminado.
- `src/main/java/com/masterclass/inventory/dto/ReportDtos.java` (modificado): nuevo `InventoryValueReport(totalValue, productCount)`.
- `src/main/java/com/masterclass/inventory/controller/ReportController.java` (modificado): nuevo `GET /api/v1/reports/inventory-value`.
- Sin cambios: `GET /inventory`, `GET /daily-sales?date=` (ya consultaba `findSalesBetween`) e historial `GET /inventory/movements/{productId}` (ya usaba query del repositorio).

## Cómo cumple el laboratorio

- Bajo stock: solo `RCE-001` (12 ≤ 15) calculado en la base de datos, no en memoria.
- Valor del inventario: total agregado `634.18` (358.80 + 143.20 + 104.70 + 27.48) más conteo de productos, con detalle por producto en `/inventory` (`stockValue` por fila).
- Ventas diarias: 0 transacciones antes de vender, 1 transacción / 2.99 después, leído de `sales` persistidas.
- Historial: movimientos `SALE` visibles por producto tras la venta.

## Validación

- `mvn -B package` → BUILD SUCCESS; `mvn -B test -Dtest=SaleServiceTest` → 1/1 verde.
- App real contra el SQL Server del Lab 1, 7 escenarios vía `curl` todos exactos: low-stock solo RCE-001; inventory-value `{"totalValue":634.18,"productCount":4}`; inventory 4 filas; daily de hoy `0/0` antes y `1/2.99` después de `POST /sales {P1×1}`; historial de P1 con el movimiento `SALE`.
- Limpieza vía `sqlcmd`: borradas ventas/detalles/movimientos de prueba y restaurado stock de P1 a 120; seed prístino (0 ventas, 0 movimientos). App detenida tras validar.
