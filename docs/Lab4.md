# Lab 4

## Objetivo

Registrar una venta multi-item que valide producto existente y activo, valide stock, calcule subtotales y total con precios del servidor, reduzca inventario y genere movimientos, todo de forma transaccional (sin ventas parcialmente persistidas).

## Cambios realizados

- Ningún cambio de código: el slice ya cumplía el laboratorio y se reutilizó tal cual (`service/SaleService.java` con `@Transactional`, `dto/SaleDtos.java` con `SaleRequest @NotEmpty` e items `@Positive`, `controller/SaleController.java` con `POST /api/v1/sales` 201, `mapper/SaleMapper.java`, entidades `Sale` con `cascade=ALL, orphanRemoval` y `SaleDetail`).
- Flujo existente verificado: por cada ítem valida existencia (404), `status==ACTIVE` (409), stock suficiente (409); `subtotal = unitPrice × quantity` con el precio de la base de datos (no el del cliente); `total` acumulado; `decreaseStock()` + fila `SALE` (`pos-terminal`) por ítem; `sales.save()` al final dentro de la misma transacción.

## Cómo cumple el laboratorio

- Venta multi-item creada con subtotales y total correctos, inventario reducido por ítem y movimientos `SALE` generados.
- Si un ítem falla (inexistente, inactivo o sin stock), el `@Transactional` revierte todo: no queda venta, ni detalles, ni movimientos, ni descuento de stock de los ítems previos (probado con fallo en el segundo ítem).
- Producto inactivo (baja lógica del Lab 2) es rechazado con 409.

## Validación

- `mvn -B test -Dtest=SaleServiceTest` → BUILD SUCCESS, 1/1 verde (incluye el caso de stock insuficiente sin `save`).
- App real contra el SQL Server del Lab 1: `POST /sales {P1×2, P2×3}` → 201 con `totalAmount: 11.35` (5.98 + 5.37), stocks 120→118 y 80→77; `POST {P3×1, P4×999}` → 409 y conteo de ventas sigue en 1 con P3 intacto en 30 (rollback); `DELETE /products/4` → 204 y `POST {P4×1}` → 409 `Product is not active`; historial con 2 movimientos `SALE`; tabla `sales`/`sale_details` verificada vía `sqlcmd` (1 venta, 2 detalles con subtotales).
- Limpieza vía `sqlcmd`: borradas ventas/detalles/movimientos de prueba, restaurado stock 120/80 y `status='ACTIVE'` en P4; seed prístino (0 ventas, 0 movimientos) para los siguientes labs. App detenida tras validar.
