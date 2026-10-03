# Reglas de Versionado Semántico (SemVer) & Gestión Documental

## 1. Clasificación de Cambios (SemVer)

El formato estándar es:
`v[MAJOR].[MINOR].[PATCH]`

### Patch (1.0.X)
* Correcciones menores de redacción o erratas en las instrucciones y guías.
* Bug fixes no disruptivos en código o configuración.
* Ajustes de estilo o interfaz que no modifican contratos ni flujos.
* Mantenimiento de dependencias a nivel de parche.

### Minor (1.X.0)
* Nuevas referencias, guías o mejoras compatibles añadidas al directorio de la skill o de la documentación.
* Nuevas funcionalidades, endpoints o características compatibles hacia atrás en la plataforma.
* Nuevas integraciones de clientes o módulos sin romper compatibilidad.
* Soporte para nuevos proveedores o extensiones manteniendo valores por defecto seguros.

### Major (X.0.0)
* Cambios drásticos en el comportamiento o en la estructura de activación de skills o agentes.
* Cambios en los parámetros de entrada/salida (breaking changes).
* Modificaciones incompatibles en contratos de red, proxy inverso o esquemas de base de datos.
* Eliminación o deprecación de APIs centrales previamente soportadas.

---

## 2. Gestión de la Documentación por Versiones

Al incrementar la versión de la plataforma o de las skills:
1. **Instantánea congelada**: Generar `docs/vX.Y.Z/` duplicando el árbol actual de `docs/` (excluyendo subdirectorios de versiones anteriores).
2. **Compatibilidad con GitHub Pages & Docsify**:
   * Asegurar la existencia de `.nojekyll` tanto en `docs/` como en `docs/vX.Y.Z/` para evitar que Jekyll descarte directorios con guiones bajos o archivos estáticos.
   * Generar `README.md` como réplica de `index.md` para resolver rutas raíz de Docsify sin 404s.
3. **Navegación y Dropdown**:
   * Actualizar `docs/_navbar.md` para incluir la nueva versión en la cabecera.
   * Actualizar el selector interactivo de versiones en `docs/index.html`.
4. **Historial de Cambios**:
   * Añadir sección en `docs/operations/changelog.md` y `CHANGELOG.md` categorizando Enhancements (Minor), Bug Fixes (Patch) o Breaking Changes (Major).
5. **Sincronización en Código**:
   * Actualizar `frontend/lib/core/constants/api_constants.dart` (`ApiConstants.appVersion`).
   * Actualizar `frontend/pubspec.yaml` (`version: X.Y.Z+<build>`).
6. **Recompilación y Despliegue**:
   * Ejecutar `./scripts/build-portal.sh` para refrescar los artefactos web de Caddy.
   * Verificar el workflow de GitHub Actions (`.github/workflows/deploy-docs.yml`).
