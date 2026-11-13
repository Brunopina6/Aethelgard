# Personajes V12 · Nix, cuarta heroína y maga negra (PROTOTIPO APAGADO)

## 13/11/2026, 02:25 · rama LOCAL `claude/v12-nix` (`D:\Aethelgard_v12_nix`), desde `dc167b0`

Sin push, merge ni rebase. Encargo: `D:\REBELUM_diagnostico\v12\expansion\encargos_13_11\Aethelgard_Nix_Maga_Negra.pdf`
(leído entero, 16 págs.; también el de Lya y el de Garon para el reparto de magias) y la lámina del usuario
`D:\REBELUM_diagnostico\v12\expansion\nix\referencia_nix_usuario.webp` (referencia; no entra en el juego). Documento
de diseño y conversión al ATB: `docs/v12/NIX_V12.md` (con la pregunta Nix/Naira para el usuario).

**Interruptor:** `nix_v12` (grupo.gd), APAGADO. `Engine.set_meta("nix_v12", true)` o `-- nix_v12`; con él,
`Grupo.unir("Nix")` y, si va entre los activos, entra en el combate (sitio de Lya, Garon o Kael, el primero libre).

### Estado por etapas (honestidad)

| | Diseñado | Generado | Importado | Integrado | Probado (PC) | Validado en Android |
|---|---|---|---|---|---|---|
| Modelo 3D, atlas, cara, LOD | sí | sí (Blender por guion) | sí (Godot 4.7.2, texturas VRAM) | sí (tras `nix_v12`) | sí | **no** (Redmi ausente) |
| 22 clips | sí | sí | sí | 14 los usa el combate | sí (hojas + combate real) | no |
| Piloto de 3 hechizos + Eclipse + espera | sí | — | — | sí (ruta de la magia negra) | sí | no |
| Menú Formación (retrato) | sí | sí | sí | sí | no probado a mano | no |
| Catálogo de 24, exploración, diálogos | diseñado en el PDF | no | no | no | no | no |

### 1. Modelo (prioridad 1, hecho)

- `aethelgard/fuente/crear_nix.py` + módulos `crear_nix_diseno.py` (geometría), `crear_nix_texturas.py` (UV y
  horneado), `crear_nix_clips.py` (clips), `crear_nix_final.py` (cara, unión, LOD, clips, hojas, GLB),
  `crear_nix_hojas.py` (láminas), `crear_nix_retrato.py` (retrato del menú). Orden:
  `blender -b --factory-startup -P fuente/crear_nix.py -- D:/Aethelgard_v12_nix/aethelgard <evidencias> [modelo|sin_render|sin_glb]`
  (≈ 10 min con hojas). Reutiliza SIN tocarlos `geometria_v3.py`, `cara_v3.py` (la forma de ojo «almendra» se añade
  en tiempo de ejecución), `rig_comun.py`, `biblioteca_clips.py` y `escena.py`.
- Esqueleto de Lya re-proporcionado (piernas ×0,78, brazos ×0,9, cadera −17,6 cm; orientaciones intactas) + `arma_d`
  deformante (el bastón va pesado a él). 51 huesos deformantes en el GLB (los que mueven la malla, menos: dedos y
  cadenas de Lya sin pesos). ≤ 4 pesos por vértice.
- Triángulos: **LOD0 9 775 + cara 188 = 9 963** (7-10 mil ✓), **LOD1 4 397** (3,5-5 mil ✓), **LOD2 1 954** (1,5-2,5
  mil ✓). Atlas 1024 (color, metal/rugosidad G/B, relieve) + atlas de cara 1024×768. GLB 5,1 MB; texturas extraídas
  VRAM (ETC2/ASTC y S3TC; la cara, sin pérdida, como los v2). Material: `heroe_v2.gdshader` (el de los v2).
- Bugs propios encontrados y corregidos: la medida de la pierna en ejes locales del FBX (no bajaba la cadera); el
  bastón no seguía la mano (`arma_d` no deformante); la cara proyectaba sombra en el horneado (cuadros en la piel);
  las mallas de los demás héroes de la hoja de grupo dejaban sus 60 acciones dentro del GLB de Nix (8,7 → 5,1 MB; la
  prueba ahora exige que solo haya clips de su contrato); un puntero de UV caducado tras el modo edición tumbaba a
  Blender de vez en cuando (código 127 sin registro).

### 2. Clips (hecho)

Mapa real en `aethelgard/personajes/nix/nix_clips.json` y tabla en `NIX_V12.md`: reposo, guardia, andar, correr
(captura), magia_lanzar (P01, 1,4 s, sale a 0,7), magia_estado (P02, 1,6 s, 0,8), magia_culminante (P07, 3,2 s, 1,6),
magia_concentrar, recibir_golpe (0,35 s), defender (1 s) + defensa, victoria (2 s, se toca el ala del sombrero),
derribo (1,5 s, de rodillas) + derrota, levantarse, ataque, hablar, hablar_b, asentir, interactuar, saltar, girar.
Hojas de contacto: `D:\REBELUM_diagnostico\v12\expansion\nix\modelo\clip_*.png`.

### 3. Magia negra: piloto (hecho)

Ascuas de Nácar (básica), Aguja de Invierno (estado) y Colapso del Firmamento (culminante) en `magia_negra.gd`
(datos) + `personajes/nix/nix_combate.gd` (Eclipse, espera, probabilidad). Conversión en `NIX_V12.md` §2
(dano = coeficiente × 35; Lento del juego; espera en turnos propios; Arcano sin elemento; ×3/n con 4 o más).
Efectos: los de la magia negra ya presupuestados para Android (ascua, aguja_glacial, colapso_astral) con colores
propios; sonidos: los de su elemento.

### 4. Integración (hecho, apagada)

`personajes/nix/nix_3d.gd` (hereda de `maga_3d.gd`), `nix_ayudante.gd` (hereda del ayudante v2),
`nix_cara.gdshader`. Enganches en compartidos (todos marcados «V12, Nix»):
- `grupo.gd`: HEROES["Nix"] (provisional), RECLUTAS, ORDEN, CRECIMIENTO, `nix_v12()`, `disponible()`.
- `combate.gd`: MODELOS["nix3d"] y su distancia, RECLUTAS_COMBATE y SITIO_DE_RECLUTA; `_siguiente_turno` (espera al
  empezar su turno y fin de su defensa), `_menu_escuela` (orden del menú), `_lanzar_negra` (sellos y espera al
  confirmar), `_resolver_negra` (su gesto por hechizo; sello al acabar), `_golpe_negra` (marca de alcance;
  probabilidad del estado con «Falla»), `_defender` (su clip). Unas 30 líneas.
- `magia_negra.gd`: `NixC`, nombres, elementos, colores, descripciones, `ORDEN_MENU` (TODAS no cambia: la prueba de
  Naira la compara), DE_RECLUTA["Nix"], sus 3 HECHIZOS, DESCRIPCION, SONIDO, el motivo y el prefijo de sellos en
  `filas_escuela`, `reparto_area` en `dano_base`, 3 iconos.
- `menus.gd`: RETRATOS["Nix"].
- `docs/recursos.md`: fila de Nix y de la referencia del usuario («licencia sin registrar»).

### 5. Pruebas (PC, aisladas)

`ejecutar_pruebas.ps1 -Solo prueba_nix_v12,prueba_combate_huella,prueba_naira_combate,prueba_magia_negra,prueba_grupo_reserva,prueba_audio_magia_negra`
→ **6 SUPERADAS · 0 FALLIDAS**, partida real sin cambios. Resumen:
`D:\REBELUM_diagnostico\v12\expansion\nix\pruebas\2026-11-13_021432\resumen.md`. La huella del combate (C0) es la
misma con el interruptor apagado. `prueba_nix_v12` (nueva, al final de la lista): reglas (interruptor, datos, 3
hechizos, área, sellos, espera de 4 turnos, Lento ≈ 70 % con semilla fija), combate real Kael + Lya + Nix (sitio,
modelo, clips de su contrato y ninguno ajeno, cara, LOD, bastón en su hueso, menú con el Colapso apagado y su motivo,
Ascuas, Aguja, 3 sellos, Colapso preparado y suelto a todos con un sonido, espera, defensa, golpe, victoria) y sin
interruptor el combate de siempre. `fotos_nix_v12` (ventana): fotos en Godot.

### 6. Evidencias

- Modelo (Blender): `D:\REBELUM_diagnostico\v12\expansion\nix\modelo\` — `nix_lamina_referencia.png` (la referencia
  del usuario arriba y Nix de frente, perfil y espalda debajo), `nix_junto_al_grupo.png` (con Kael, Lya y Garon v2 a
  la escala del combate), `nix_vistas_reposo.png`, `nix_vistas_guardia.png`, `nix_lod.png`, `clip_*.png`, texturas
  `nix_color/orm/normal(_2048).png`, `nix_cara_atlas.png`, `nix.blend`.
- Juego (Godot, PC): `D:\REBELUM_diagnostico\v12\expansion\nix\juego\combate_nix.mp4` (66 s, el combate A de la prueba
  a 10 fps), `hoja_combate.jpg`, `tira_nix.jpg`, `hoja_cerca_godot.jpg` y `cerca\*.png` (cuerpo, 8 expresiones, LOD a
  6, 12 y 22 m).

### 7. Límites

- **Nada validado en Android** ni medido en el Redmi (ausente). Sin medidas de rendimiento (otros especialistas
  trabajaban en el PC).
- Calidad de cerca: mejor que los v3 (texturas horneadas, relieve, cara) pero con menos detalle pintado que los
  originales de Meshy; la luz de mi escena de fotos (`fotos_nix_v12`) satura la piel y el marfil (es la escena, no el
  combate: en el combate se ve bien).
- No hechos: huesos secundarios de sombrero y capa (la capa estira un poco con los brazos en alto: victoria y ritual);
  strafe/turn/stagger/hit_back/equip_idle; exploración 3D (`grupo_3d.gd`), esperas, diálogos, voz y sonidos propios;
  arma en el inventario; los otros 21 hechizos.
- La INVOCACIÓN del menú común sigue saliendo como para Kael (Érebo lo invoca Lya); Nix no tiene invocación propia.

### 8. Siguiente paso y peticiones

- Que el usuario vea las láminas y el vídeo y decida **Nix/Naira** (`NIX_V12.md` §4).
- Coordinador: añadir a `docs/versiones/licencias_pendientes.txt` la línea de Nix (esqueleto y clips de captura
  derivados del rig de Lya/Meshy), como la de los héroes v3.
- Siguiente iteración: huesos secundarios horneados, catálogo por rangos con elemento por hechizo, acompañante en
  exploración y medida en el Redmi.

## 13/11/2026, 02:55 · segunda pasada (v2): la silueta de la referencia

Encargo del coordinador: el modelo v1 se alejaba mucho de la lámina del usuario. Mismas reglas; solo el generador y
los archivos de Nix. **La v1 se conserva** en `aethelgard/personajes/nix/v1/` (`.gdignore`: `nix_v1.glb`,
`nix_clips_v1.json`, `nix_retrato_v1.png` y la copia de sus guiones `crear_nix*_v1.py`) y sus evidencias en
`D:\REBELUM_diagnostico\v12\expansion\nix\modelo_v1\`. Detalle de los cambios: `docs/v12/NIX_V12.md` §0.

- **Hoja v1 / v2 / referencia con las mismas cámaras** (frente, perfil y espalda, ortográficas fijas para las dos
  versiones): `D:\REBELUM_diagnostico\v12\expansion\nix\comparar\hoja_v1_v2_referencia.jpg` (guion nuevo
  `fuente/crear_nix_comparar.py`).
- Cambios: sombrero enorme (ala de 0,98 m, ondulada, caída a su izquierda y alzada a su derecha con la muesca de media
  luna honda, canto lavanda levantado, copa más alta con la punta doblada atrás, cinta ancha con rebordes, dos
  hebillas «#» y broche redondo grande con la luna); piernas ×0,66 y más gruesas, caderas anchas, cabeza mayor, botas
  anchas con suela gruesa y vuelta, guantes ×1,36; melena con volumen, siete mechones en capas, flequillo de lado desde
  la raya junto al mechón gris; faldón en dos alturas con picos, ribete de cobre, franja y forro lilas; capa en tres
  paños con picos y el rombo; peto crema con forma y botones; cara con sombra de ojos, raya alargada y media sonrisa;
  bastón con la luna de hierro (picos) alrededor del cristal y la barra de cobre.
- **Bastón contra sombrero** (pedido por la especificación): comprobación nueva `fuente/crear_nix_verificar.py`, dentro
  del generador (aristas del bastón contra triángulos del sombrero, 16 instantes por clip). El ala nueva chocaba en 15
  de 20 clips; tras rehacer las poses altas y el bastonazo (de lado), **0 choques** (`modelo\nix_baston_sombrero.json`;
  `nix_clips.json` lo apunta). La parte de arriba del bastón es más corta (la luna queda junto al ala).
- Presupuesto: LOD0 **9 779 + cara 184 = 9 963** triángulos; LOD1 4 400; LOD2 1 955. GLB 5,4 MB.
- `nix_3d.gd`: el punto de la magia (cristal) se lee del JSON (`largo_cristal` 0,438 m).

Pruebas (aisladas, PC): `prueba_nix_v12`, `prueba_combate_huella`, `prueba_naira_combate`, `prueba_magia_negra`,
`prueba_grupo_reserva`, `prueba_audio_magia_negra` → **6 SUPERADAS · 0 FALLIDAS**, partida real sin cambios
(`D:\REBELUM_diagnostico\v12\expansion\nix\pruebas\2026-11-13_025103\resumen.md`).

Evidencias v2: `...\nix\modelo\` (vistas, lámina con la referencia, `nix_junto_al_grupo.png`, `clip_*.png`, LOD,
texturas), `...\nix\juego_v2\combate_nix_v2.mp4` (66 s), `tira_nix.jpg`, `hoja_cerca_godot.jpg` y `cerca\*.png`.

Límites: sigue sin validar en Android. Con los brazos chibi la mano no llega al ala: la victoria pone la mano en la
cadera. De cerca, las texturas procedurales siguen por debajo del pintado de los héroes de Meshy; la escena de fotos
de Godot satura el lavanda y la piel (en el combate se ve bien). El pelo aún acaba en picos algo duros en el flequillo.
