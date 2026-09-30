# Lab 2

## Objetivo

Exponer el slice vertical de producto (entidad + DTOs, repositorio + mapper, servicio, controlador) con creación, búsqueda, actualización y desactivación lógica, validado en Swagger.

## Cambios realizados

- `src/main/java/com/masterclass/inventory/service/ProductService.java` (modificado): `update` ahora rechaza SKU duplicado (`if (!p.getSku().equals(r.sku()) && products.existsBySku(r.sku())) throw new BusinessException("SKU already exists")`), igual que ya hacía `create`. Sin este guard, actualizar al SKU de otro producto violaba `uk_products_sku` en la base de datos y devolvía 500 en lugar de 409.
- Sin archivos nuevos: entidad (`entity/Product.java`), DTOs (`dto/ProductDtos.java`), repositorio (`repository/ProductRepository.java` con `existsBySku` y `search`), mapper (`mapper/ProductMapper.java`), controlador (`controller/ProductController.java` con `POST/GET/GET{id}/PUT/DELETE /api/v1/products`), validaciones Bean Validation y manejo de errores (`BusinessException` → 409, `NotFoundException` → 404) ya existían y se reutilizaron sin cambios.

## Cómo cumple el laboratorio

- Crear: `POST /api/v1/products` valida `@Valid`, rechaza SKU duplicado (409) y categoría inexistente (404).
- Buscar: `GET /api/v1/products?q=` busca por nombre/SKU vía `ProductRepository.search`; sin `q` lista todo.
- Actualizar: `PUT /api/v1/products/{id}` reemplaza campos editables con la misma validación de SKU que la creación (fix de este lab).
- Desactivar: `DELETE /api/v1/products/{id}` hace baja lógica (`status=INACTIVE`, 204), sin borrar la fila, por lo que el historial de movimientos/ventas se conserva.

## Validación

- `mvn -B compile` → exit 0.
- `mvn -B test -Dtest=SaleServiceTest` → `Tests run: 1, Failures: 0, Errors: 0` (sin regresiones en el servicio vecino).
- `ProductApiIntegrationTest` falla en este entorno con `Could not find a valid Docker environment` (`UnixSocketClientProviderStrategy ... BadRequestException Status 400`); verificado que falla idéntico en el árbol limpio sin mis cambios (preexistente: incompatibilidad Testcontainers 1.21.3/docker-java con Docker 29.8, ocurre en `beforeAll` antes de cargar código de la app). No causado por este lab; queda para Lab 6/7.
- Verificación manual pendiente vía Swagger (`http://localhost:8080/swagger-ui.html`, Basic `admin/admin123`): crear, buscar con `?q=milk`, actualizar cambiando el SKU al de otro producto (debe dar 409), `DELETE` y comprobar `status=INACTIVE`.
