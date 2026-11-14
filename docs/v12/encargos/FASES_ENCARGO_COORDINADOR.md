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
| 3A | Orbe nativo de Érebo (sección 4): opción de Auditoría APAGADA, sincronizada con el agarre del orbe y con limpieza | Prueba nueva, batería completa, capturas activado/desactivado | pendiente (SIGUIENTE) |
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

Ninguno (comprobado el 14/11 con `coordinacion.py` y la lista de sesiones). Cuando se lance uno, apuntar aquí su
carpeta (`D:\Aethelgard_v12_<area>`), su rama `claude/v12-<area>` y los archivos que toca.

## Decisiones registradas

- **14/11, Nix:** el canon vigente (capucha, pelo gris ceniza con dos mechones, emblema del Ojo de Horus) manda
  sobre el diseño anterior del PDF (sombrero, pelo ciruela).
  - Del PDF se conservan las mecánicas y los presupuestos.
  - El Silver Sentinel es su cuerpo base.
