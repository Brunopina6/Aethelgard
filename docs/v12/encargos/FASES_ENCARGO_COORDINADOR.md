# Fases del encargo coordinador (13/11) — documento de tareas vivo

- **Encargo literal:** `ENCARGO_COORDINADOR_13_11.md`, en esta carpeta.
- **Directiva de continuidad:** `DIRECTIVA_CONTINUIDAD_14_11.md`.
- **Al terminar cada fase:** marcarla aquí, apuntar las decisiones y los especialistas, pasar sus pruebas, hacer
  commit y resumirla en el RELEVO de `docs/v12/RETOMAR.md`.
- **Después de una compactación:** retomar desde la primera fase sin «HECHA».

**Límites que se aplican a todas las fases** (los literales están en el encargo):
- nada de fusiones con `main` ni `desarollo`, push forzado ni releases;
- no tocar las partidas reales;
- no borrar nada;
- trabajar sobre copias de los FBX y los ZIP.

**GitHub:** solo se sube la fase 3A, el orbe comprobado. El resto se queda en commits locales.

| Fase | Contenido (sección del encargo) | Verificación | Estado |
|---|---|---|---|
| 1 | Inspección y protección: etiqueta, ZIP extraídos, PDF leídos, Silver Sentinel identificado | `D:\REBELUM_entrada_13_11\INSPECCION_PASO1.md` | **HECHA** (14/11, `36fee13`) |
| 2 | Desbloqueos que impidan desarrollar o probar | Batería en verde en el PC | **HECHA**: no hay ninguno. Validado `ed59483`; coordinación y `proteger.sh` activos |
| 3A | Orbe nativo de Érebo (sección 4): opción de Auditoría APAGADA, sincronizada con el agarre del orbe y con limpieza | Prueba nueva, batería completa, capturas activado/desactivado | **HECHA** (14/11): commit local `5c045b7`; batería 160 · 0; `docs/v12/EREBO_ORBE_V12.md`. **SIN SUBIR**, por la decisión de GitHub (ver «Decisiones»); la rama `claude/v12-orbe-solo` @ `a4db536` (solo el orbe sobre `ed59483`) está lista para subirse |
| 3B | Solo Lya invoca: quitar la Invocación a Kael y migrar sin perder progreso | Prueba de menús y migración | pendiente |
| 3C | Mejorar UNA magia representativa | Capturas y prueba | pendiente |
| 4 | Menús y permisos de los héroes y catálogo de habilidades; recursos Eclipse, Compás e Inscripciones (máximo 3) | Pruebas de combate | pendiente |
| 5 | Piloto de Nix desde su FBX: reducir la malla (LOD0 de 7-10 mil triángulos), rig con mechones, vestuario canónico | Blender, reimportación en Godot y capturas | pendiente |
| 6 | Capa de Garon como pieza independiente con huesos propios; se conserva la original | Capturas en movimiento | pendiente |
| 7 | Primera experiencia jugable: misiones de Oakhaven, caravana, secundaria nueva, secreto, cerradura rúnica, gremio 13 frente a 15 | Pruebas de misión | pendiente |
| 8 | Oficios, armas especiales y minijuegos (primero la cerradura) | Pruebas | pendiente |
| 9 | Enemigos y arsenal: piloto `meshy_e01` Custodio (idle, walk, Prensa del Umbral), después e02-e04 y los comunes; 32 conjuntos | Prueba de ataques y GLB reimportado | pendiente |
| 10 | Historias personales y mundo vivo | Pruebas | pendiente |
| 11 | Gráficos y rendimiento (matas recortadas apagadas, mipmaps experimentales) | Medida en el PC; el Redmi, solo con autorización | continua |
| 12 | APK de Auditoría SIN instalar y guion de pruebas para el Redmi (v2 y v3 de pie; NPC de Oakhaven) | SHA-256 y guion | pendiente |
| 13 | Matriz por elemento y entrega con continuidad | Documento | pendiente |

## Especialistas activos

Lanzados el 14/11 hacia las 01:40, como subagentes de la sesión coordinadora:

| Especialista | Carpeta | Rama (local) | Archivos que toca | Fase |
|---|---|---|---|---|
| Nix (piloto desde el FBX) | `D:\Aethelgard_v12_nix_piloto` y `D:\REBELUM_entrada_13_11\nix_trabajo\` | `claude/v12-nix-piloto` (desde `710fdae`) | modelo, rig y escena de Nix; `docs/v12/NIX_PILOTO_FBX.md` | 5 |
| Capa de Garon | `D:\Aethelgard_v12_capa_garon` y `D:\REBELUM_diagnostico\v12\capa_garon\` | `claude/v12-capa-garon` (desde `710fdae`) | `garon_3d.gd`, `garon_v2_3d.gd`, sus pruebas y `docs/v12/CAPA_GARON_V12.md` | 6 |

La copia principal `D:\Aethelgard_v12` la usa solo el coordinador (fases 3A, 3B, 3C y 4). Las ramas de los
especialistas se integran copiando archivos, nunca con fusiones.

**Si la sesión se corta:** mira en cada carpeta `git log claude/rebelum-v12..<rama>` y `git status`, y retoma o
integra lo que esté probado.

## Decisiones registradas

- **14/11, instrucciones complementarias** (`INSTRUCCIONES_COMPLEMENTARIAS_14_11.md`; prevalecen sobre el prompt de
  expansión):
  - **Pelo de Nix:** «gris RECOGIDO». Se suma al canon de la capucha, el mechón superior y los dos delanteros.
  - **Medias de Nix:** con motivos dorados asimétricos (ramas u hojas en una, geométricos en la otra).
  - **Garon:** sus armas dobles forman un par con un único bloque de estadísticas y pasivas.
  - **Paquete:** «90 habilidades» = 24 + 18 + 18 + 6 + 24.
  - **Orden:** las complementarias ponen Nix y la capa (4) antes que los permisos (5). El coordinador los pone al
    revés y pide ajustar solo por dependencias reales.
    - Se sigue el orden del coordinador para 3B (solo Lya invoca), que forma parte de la sección del orbe.
    - Las fases 4 a 6 se pueden reordenar si hay una dependencia.
- **14/11, subida a GitHub:** el remoto está en `ed59483` y en local hay 3 commits solo de documentación (`b9d094a`,
  `36fee13`, `710fdae`) antes del orbe.
  - Un push normal subiría también esos tres, y la autorización cubre ÚNICAMENTE el orbe.
  - Subir solo el orbe exigiría reordenar la historia local, que equivale a un rebase prohibido.
  - **Decisión registrada para el usuario:** subir los 4 commits juntos (los 3 solo tocan documentación), o
    autorizar que se reordene la historia local. Mientras tanto, el orbe queda en commit local.
  - **Alternativa preparada sin publicar nada:** la rama local `claude/v12-orbe-solo` @ `a4db536` contiene `ed59483`
    más solo los 8 archivos del orbe, idénticos a los probados en `5c045b7`.
    - Se sube con `git push origin claude/v12-orbe-solo:claude/rebelum-v12`, un avance normal sin forzar.
    - Después, la rama local tendría que rehacer sus commits de documentación encima de esa base, y eso requiere
      la autorización del usuario.

- **14/11, Nix:** el canon vigente (capucha, pelo gris ceniza con dos mechones, emblema del Ojo de Horus) manda
  sobre el diseño anterior del PDF (sombrero, pelo ciruela).
  - Del PDF se conservan las mecánicas y los presupuestos.
  - El Silver Sentinel es su cuerpo base.
