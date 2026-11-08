# Informes de los especialistas

Desde el 08/11/2026 a las 22:00, el desarrollo se organiza con un coordinador y cinco especialistas (D-069 en
`DECISIONS.md`, en la rama `memoria-desarrollo`). Su configuración está en `.claude/agents/especialista-*.md`.

| Informe | Especialista | Rama de trabajo |
|---|---|---|
| `sonido.md` | Sonido: efectos de la biblioteca del usuario, ambientes, buses y volúmenes | `area-sonido` |
| `animaciones.md` | Animaciones: poses, gestos y reacciones en diálogos 2D y 3D | `area-animaciones` |
| `graficos.md` | Gráficos: el mapamundi y la dirección visual | `area-graficos` |
| `narrativa.md` | Narrativa: diálogos, misiones y continuidad | `area-narrativa` |
| `combate.md` | Combate: estabilidad, respuesta y eventos sonoros | `area-combate` |

**Cada informe** añade una sección por entrega, con fecha y hora, sin borrar las anteriores:
- archivos modificados y commits;
- pruebas ejecutadas y resultados, con la ruta del resumen;
- evidencias con sus rutas;
- límites (lo que no se pudo comprobar y por qué);
- siguiente paso y cambios que necesita en archivos de otros.

**Reglas comunes:**
- Cada especialista trabaja en su copia de trabajo y su rama.
- Un archivo compartido tiene un solo responsable de edición a la vez.
- Los especialistas no hacen push. El coordinador revisa, integra en `integracion-experimental` y publica
  (D-070: ramas de trabajo del repositorio privado, nunca `main` ni `desarollo`, nunca force push).
- El estado global lo resume el coordinador en `SESSION_HANDOFF.md` y `TASKS.md` (T-082 a T-088).
