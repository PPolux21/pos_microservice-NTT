# Lab 8

## Objetivo

Pipeline que en pull request compile, pruebe y valide (incluido el build Docker) sin publicar, y en `main` construya, tagee y publique una imagen rastreable en el registry.

## Cambios realizados

- `.github/workflows/ci.yml` (creado, pipeline activo): triggers `pull_request` y `push` solo sobre `main`; `permissions: contents: read`; job `verify` (`checkout`, `setup-java` temurin 21 + caché Maven, `mvn -B verify`); job `image` (`needs: verify`) que siempre hace `docker build`, y solo con `event_name == push` hace login y `tag + push`.
- `ci/github-actions.yml` (eliminado): borrador inactivo fuera de `.github/`; además usaba versiones inexistentes (`checkout@v7`, `setup-java@v6`), trigger sin acotar ramas y un solo job que mezclaba todo. Se fijaron `checkout@v4`, `setup-java@v4`, `login-action@v3`.
- Tags en `main` (ambos pusheados, ambos rastreables): `sha-<full-sha>` (commit exacto) y `1.0.<run_number>` (versión humano-legible, correlacionable al run de Actions).
- Sin cambios de producción ni de tests.

## Cómo cumple el laboratorio

- PR a `main`: corre `verify` (unitarios + IT Testcontainers, que funciona en el runner gracias al `api.version` fijado en el pom en el Lab 6) y valida `docker build`; los pasos de login/push están condicionados a `push`, así que un PR nunca publica.
- Push a `main`: tras el gate verde, publica `USER/inventory-pos-service:sha-<sha>` y `:1.0.<run>`. Cualquiera de los dos tags lleva a la versión/commit concreto.
- Secrets requeridos (crear en GitHub → Settings → Secrets and variables → Actions): `DOCKERHUB_USERNAME` (usuario/cuenta destino) y `DOCKERHUB_TOKEN` (access token de Docker Hub con permisos de escritura, no la contraseña).

## Validación

- YAML parseado y estructura verificada (2 jobs, `image needs verify`, condicionales `push` solo en login/push).
- `mvn -B verify` sobre el árbol actual → 5/5 verde, BUILD SUCCESS (el gate que correrá el job `verify`).
- `docker build` ya probado en el Lab 7 (exit 0 desde estado limpio); el `Dockerfile` no cambió desde entonces salvo código ya validado.
- Pendiente del lado del repositorio remoto (no ejecutable desde aquí): crear los 2 secrets, abrir un PR de prueba (debe correr sin push) ymergear (debe publicar ambos tags, verificables con `docker pull`).
