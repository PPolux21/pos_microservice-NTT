# Lab 6

## Objetivo

Cerrar el gate de calidad: prueba Mockito de stock insuficiente, smoke de integración con Testcontainers + SQL Server, `mvn verify` en verde y criterio de que el build falla si una regla de negocio regresa, con discusión honesta de cobertura.

## Cambios realizados

- `src/test/java/com/masterclass/inventory/service/InventoryServiceTest.java` (creado): 3 tests Mockito estilo `SaleServiceTest` — `adjust OUT` por encima del stock → `BusinessException` con stock intacto y sin `save`; tipo inválido (`SALE`) → `BusinessException` sin tocar repositorios; `replenish` suma stock y guarda el movimiento.
- `src/test/java/com/masterclass/inventory/integration/ProductApiIntegrationTest.java` (modificado): el smoke `contextStarts` (solo assert de puerto) ahora crea categoría → 201, crea producto → 201 con SKU, y busca `?q=SMK-001` → 200 con 1 fila, vía `TestRestTemplate` con Basic `admin/admin123` contra SQL Server en Testcontainers (`create-drop`).
- `pom.xml` (modificado): propiedad `docker.api.version=1.44` + Surefire `systemPropertyVariables api.version` (ver Validación); JaCoCo 0.8.12 con `prepare-agent` y `report` en `verify` (solo reporte, sin umbral que falle el build — decisión consciente, ver cobertura).
- Sin cambios de producción.

## Cómo cumple el laboratorio

- Regla de stock insuficiente cubierta dos veces (venta e inventario) con `verify(..., never()).save(...)`.
- Smoke real levanta contenedor MSSQL, contexto Spring y prueba el API de punta a punta.
- `mvn verify` corre unitarios + integración + empaqueta + genera `target/site/jacoco/index.html`.
- Regresión probada: al quitar el chequeo de stock de `SaleService`, `SaleServiceTest` falla y el build cae (revertido tras la prueba).

## Validación

- `mvn -B verify` → `Tests run: 5, Failures: 0, Errors: 0`, BUILD SUCCESS (3 InventoryServiceTest + 1 SaleServiceTest + 1 IT de ~73 s con imagen ya descargada).
- Hallazgo de entorno (resuelto): Testcontainers 1.21.3 fija API Docker 1.32 y Docker 29 exige ≥ 1.40 (`client version 1.32 is too old`), por lo que el IT fallaba con `Could not find a valid Docker environment`. Diagnosticado inspeccionando el bytecode (`DockerClientProviderStrategy` → `VERSION_1_32`); la variable de entorno no lo sobrescribe, pero la system property sí: `-Dapi.version=1.44`, fijada en el pom y sobreescribible con `-Ddocker.api.version=...`.
- Cobertura JaCoCo medida: instrucciones 700/1470 (~48 %), ramas 21/48, métodos 41/103. Qué significa y qué NO garantiza: con este codebase (clases de 1-2 líneas) la cobertura de línea es casi ruido; el 48 % refleja que solo hay 4 unitarios + 1 smoke (mappers y servicios parcialmente tocados por el IT). Una métrica alta NO probaría: concurrencia sobre el último stock, constraints CHECK de la DB, orden init→app en compose, auth/seguridad, ni el contrato de tipos de movimiento más allá de los casos escritos. Por eso no se puso umbral `check` que falle el build: sería una falsa garantía.
