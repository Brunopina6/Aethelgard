# Inventario de zonas y su paso a 3D

**Fecha:** 2026-11-09 (23:20). **Fuente:** observado en el código de `integracion-experimental` @ `16c6965`
(`mapa.gd`: lugares del mapa; `modo3d.gd`: `REGIONES`, `EN_PRUEBAS` y `EQUIVALENTES`). Lo de rendimiento viene de
medidas reales en el Redmi (Mali-G57) del mismo día; lo demás, del PC.

El objetivo aprobado es que todas las ciudades, pueblos, regiones y posadas sean 3D jugable al nivel de Pastos Verdes
(D-076, en `DECISIONS.md` de la rama `memoria-desarrollo`), sin crear lugares nuevos fuera del diseño aprobado y sin borrar la versión 2D
hasta que la 3D esté verificada (se elige en Ajustes mientras está «en pruebas»).

| Índice | Lugar | Tipo | Hoy | Estado del 3D |
|---|---|---|---|---|
| 10 | Pastos Verdes | región | **3D** (`zonas3d/pastos_verdes_3d.tscn`) | Jugable: misión PV-02 a PV-14, grupo, cofre, combates, notas. En el Redmi: perfil bajo a 30 FPS estables; medio 23-25 (en optimización) |
| 2 | Garganta del Diablo | mazmorra | 2D y **3D en pruebas** (Ajustes → Garganta del Diablo) | Pulida entera (T-102): puentes, cascada, arena de Gorthor, sonidos y comentarios. Pendiente de medir en el Redmi |
| 0 | Oakhaven | ciudad | 2D hecha a mano, con arte, vecinos vivos, posada y servicios | **En curso** (T-103, gráficos, rama `area-oakhaven3d`): entrada → plaza, un vecino y la posada recorrible |
| 1 | Gran Bosque Verde | lugar | 2D (zona generada) | Pendiente. Propuesto como siguiente: es el vecino de Pastos Verdes y Oakhaven en el recorrido |
| 3 | Cumbres de Ciclópea | lugar | 2D | Pendiente |
| 4 | Mar de Arena de Calid | lugar | 2D | Pendiente |
| 5 | Sunken City | ciudad | 2D | Pendiente (segunda ciudad) |
| 6 | Valle de los Ecos | lugar | 2D | Pendiente |
| 7 | Templo Sumergido de Atlantis | lugar | 2D | Pendiente |
| 8 | Abismo de Ceniza | lugar | 2D | Pendiente |
| 9 | Portal del Vacío | portal | 2D | Pendiente |

## Orden propuesto

Según el recorrido de la historia y las dependencias jugables:
1. **Oakhaven 3D** (en curso): ciudad y posada, con los datos ya preparados por narrativa (`ciudades/oakhaven_posada.gd`,
   `ciudades/oakhaven_vida.gd`) y sonido (Oakhaven vivo).
2. **Gran Bosque Verde 3D**: región natural al lado de Pastos Verdes; reutiliza su vegetación, agua y cámara.
3. **Sunken City** (segunda ciudad) y después las regiones lejanas, una a una.

## Requisitos de cada zona 3D (de la directiva del usuario)

Arquitectura con personalidad, calles y plazas coherentes, vegetación y agua, NPC con rutinas, fauna, luz y ambiente,
interacciones, misiones y eventos, navegación y colisiones, combates y cambios de escena, y guardado compatible con las
partidas antiguas (`progreso.restaurar()` y `modo3d.escena_equivalente()`). Presupuesto para que el perfil **medio**
también dé 30 FPS estables en el Mali-G57: del orden del bajo de Pastos Verdes (unos 100-150 dibujos y 200-300k
triángulos por vista), sin rebajar el alto.
