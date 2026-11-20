# SaaS Lubricentros

Sistema integral diseñado para digitalizar y optimizar la gestión operativa de lubricentros en Argentina (control de cambios de aceite, historial vehicular, stock y turnos).

---

## Stack Tecnológico

* **Mobile:** Flutter + SQLite *(soporte offline-first / caché local)*
* **Backend:** Go (Golang) — API REST
* **Base de Datos:** Supabase (PostgreSQL en la nube)
* **Infraestructura / Deploy:** Render

---

## 📁 Estructura del Proyecto

```text
├── mobile/     # Aplicación móvil en Flutter (cliente)
├── backend/    # API REST desarrollada en Go
├── docs/       # Documentación técnica y scripts SQL
└── scripts/    # Scripts de automatización y auditoría de seguridad
- See: `docs/security-guidelines.md` for complete guidelines

## Documentación

Ver carpeta `/docs` para más detalles sobre arquitectura, API y base de datos.
