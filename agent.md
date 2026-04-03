# Agent Skills & Context References

Este documento define las skills del agente y referencias a documentación clave del proyecto sin centralizar todo el contexto.

## 🎯 Skills Disponibles

### Skill: Product Knowledge
**Descripción**: Conocimiento sobre el producto Lubricentros App
**Referencias**:
- #[[file:docs/product.md]] - Visión y características del producto
- #[[file:docs/roadmap.md]] - Roadmap y planificación
- #[[file:mobile/FASE2_IMPLEMENTACION.md]] - Plan de implementación Fase 2

**Cuándo usar**: Cuando necesites entender el contexto del negocio, features planificadas, o visión del producto.

---

### Skill: Architecture & Technical Design
**Descripción**: Arquitectura del sistema y decisiones técnicas
**Referencias**:
- #[[file:docs/architecture.md]] - Arquitectura general del sistema
- #[[file:docs/api.md]] - Diseño de API
- #[[file:docs/database.md]] - Esquema y diseño de base de datos

**Cuándo usar**: Cuando necesites entender la estructura técnica, patrones arquitectónicos, o diseño de componentes.

---

### Skill: Security Guidelines
**Descripción**: Guías y estándares de seguridad
**Referencias**:
- #[[file:docs/security-guidelines.md]] - Guías de seguridad generales
- #[[file:.kiro/specs/authentication/password-security-architecture.md]] - Arquitectura de seguridad de passwords
- #[[file:.kiro/specs/authentication/SECURITY-IMPLEMENTATION.md]] - Implementación de seguridad

**Cuándo usar**: Cuando trabajes con autenticación, autorización, datos sensibles, o necesites validar prácticas de seguridad.

---

### Skill: Authentication Implementation
**Descripción**: Sistema de autenticación y gestión de usuarios
**Referencias**:
- #[[file:.kiro/specs/authentication/requirements.md]] - Requisitos de autenticación
- #[[file:.kiro/specs/authentication/design.md]] - Diseño del sistema de auth
- #[[file:.kiro/specs/authentication/tasks.md]] - Tareas de implementación

**Cuándo usar**: Cuando trabajes con login, registro, sesiones, o gestión de usuarios.

---

### Skill: Loading System Implementation
**Descripción**: Sistema de indicadores de carga y estados asíncronos
**Referencias**:
- #[[file:.kiro/specs/loading/requirements.md]] - Requisitos del sistema de loading
- #[[file:.kiro/specs/loading/design.md]] - Diseño de componentes de loading
- #[[file:.kiro/specs/loading/tasks.md]] - Tareas de implementación
- #[[file:mobile/lib/widgets/loading/README.md]] - Documentación de componentes

**Cuándo usar**: Cuando trabajes con estados de carga, spinners, overlays, o feedback visual de operaciones asíncronas.

---

### Skill: Mobile Development (Flutter)
**Descripción**: Desarrollo de la aplicación móvil Flutter
**Referencias**:
- #[[file:mobile/README.md]] - Setup y configuración del proyecto móvil
- #[[file:mobile/CREDENCIALES_DEV.md]] - Credenciales de desarrollo
- #[[file:mobile/lib/theme/app_theme.dart]] - Sistema de theming

**Cuándo usar**: Cuando trabajes con la app Flutter, widgets, providers, o configuración móvil.

---

### Skill: Backend Development (Go)
**Descripción**: Desarrollo del backend en Go
**Referencias**:
- #[[file:backend/cmd/api/main.go]] - Entry point del API
- #[[file:backend/internal/database/db.go]] - Configuración de base de datos
- #[[file:backend/migrations/001_initial_schema.sql]] - Schema inicial

**Cuándo usar**: Cuando trabajes con el API backend, endpoints, middleware, o base de datos.

---

## 📋 Uso de Skills

### Cómo Referenciar
Usa la sintaxis `#[[file:ruta/al/archivo.md]]` para cargar documentos bajo demanda.

### Principios
1. **Carga bajo demanda**: Solo carga el contexto necesario para la tarea actual
2. **Referencias explícitas**: Usa referencias de archivos en lugar de copiar contenido
3. **Modularidad**: Cada skill es independiente y enfocada
4. **Mantenibilidad**: Actualiza referencias cuando cambien los archivos

### Ejemplo de Uso
```
Para trabajar en autenticación:
1. Activa Skill: Authentication Implementation
2. Carga #[[file:.kiro/specs/authentication/requirements.md]]
3. Implementa según el diseño en #[[file:.kiro/specs/authentication/design.md]]
```

---

## 🔄 Estado Actual del Proyecto

**Última actualización**: Ver #[[file:PROGRESO_ACTUALIZADO.md]]

**Specs Activos**:
- Authentication: En progreso
- Loading: Tarea 1 completada, resto pendiente

---

## 📝 Notas

- Este archivo sirve como índice de conocimiento del agente
- No centraliza el contexto, solo lo referencia
- Permite cargar información específica según la tarea
- Mantiene el contexto del agente ligero y enfocado
