# Lab 7

## Objetivo

Dejar un runtime contenerizado donde una máquina limpia con solo Docker levante el stack completo: imagen de la app, compose con SQL Server, health endpoint, Swagger y una venta contra la DB del contenedor.

## Cambios realizados

- `.dockerignore` (creado): excluye `.git`, `target`, `.vscode`, `docs`, `ci`, `*.log` y `path.java` del contexto de build.
- `docker-compose.yml` (modificado): `inventory-service` ahora espera a `sqlserver-init` con `service_completed_successfully` (antes solo esperaba al SQL healthy, con riesgo de arrancar antes del schema frente a `ddl-auto: validate`); healthcheck propio con `wget --spider /actuator/health` (busybox de Alpine, sin paquetes extra); `restart: unless-stopped`.
- `src/main/java/com/masterclass/inventory/security/SecurityConfig.java` (modificado, 1 línea): agregado `/swagger-ui.html` al `permitAll`. La ruta custom de springdoc (`springdoc.swagger-ui.path`) no matchea el patrón `/swagger-ui/**`, así que el Swagger documentado devolvía 401. Detectado al validar este lab.
- Sin cambios en `Dockerfile` (multistage Maven + JRE Alpine ya válido).

## Cómo cumple el laboratorio

- `docker compose down -v` + `docker compose build` + `docker compose up -d` desde cero: `sqlserver` healthy → `sqlserver-init` exited 0 (schema + seed) → `inventory-service` healthy. Orden garantizado por `depends_on`.
- `/actuator/health` → `UP` (público, también usado por el healthcheck del compose).
- Swagger abre sin auth (302 → 200 en `/swagger-ui/index.html`); `/v3/api-docs` expone los 13 paths.
- Venta `P2×2 + P3×1` → 201 con total 7.07; verificado en la DB del contenedor: stocks 80→78 y 30→29, 1 fila en `sales`, 2 movimientos `SALE`.

## Validación

- Tests unitarios previos al build: `SaleServiceTest` + `InventoryServiceTest` → 4/4 verde.
- Comandos: `docker compose down -v`, `docker compose build` (exit 0), `docker compose up -d`, espera a `healthy` en `inventory-pos-service` (~40 s), `curl /actuator/health`, `curl -L /swagger-ui.html` → 200, `POST /api/v1/sales` con Basic `admin/admin123`, conteo vía `sqlcmd` en `grocery-sqlserver`.
- Limpieza: borradas ventas/movimientos de prueba y restaurado el seed (120/80/30/12); stack dejado corriendo y healthy. Credenciales `sa` en claro: solo para laboratorio.
