# Informe: expansión del mundo y evolución de personajes (12-13/11/2026)

Todo está medido en el PC. **Nada está validado en Android**: el Redmi no estaba conectado. Todo lo nuevo va
**APAGADO** tras su interruptor o elegible en Ajustes; lo único encendido por defecto son las optimizaciones sin cambio
visible y el arreglo de la capa de Garon, que pidió el usuario.

## GitHub

- **Rama:** `origin/claude/rebelum-v12`, publicada el 12/11 con autorización expresa del usuario.
  - Primera subida: `d8a65d3`; se han ido subiendo los hitos probados, sin force.
- **Ramas compartidas:** `main` sigue en `d4b2d16`. No se ha hecho merge con `main` ni con `desarollo`, ni se ha creado ningún release.
- **Punto de recuperación:** etiqueta local `v12-antes-expansion` (= `d8a65d3`).

## Qué se hizo (commit · cómo se enciende · documento)

| Trabajo | Commit | Interruptor / Ajustes | Documento |
|---|---|---|---|
| Accesorios v12: 11 objetos con rareza y efectos tácticos | `16edd37` | `accesorios_v12` | `ACCESORIOS_V12.md` |
| Firmamento de los Ecos (Orbes Cristalinos): 3 conceptos, tableros de Kael, Lya y Garon | `fa80e3e` | `orbes_v12`; Auditoría: Ajustes | `FIRMAMENTO_DE_LOS_ECOS.md` |
| Rendimiento 1: orden de dibujo del Gran Bosque, primer combate sin parón, menús precargados | `b3c4e0f` | encendido (misma imagen) | `memory/agents/rendimiento_v12_rend2.md` |
| Centinela del Anillo | `b3c4e0f` | `enemigos_v12` | `memory/agents/combate_v12_enemigos.md` |
| Rendimiento 2: primer diálogo sin parón; mipmaps de hojas | `c07d761` | diálogo encendido; mipmaps `gb_hojas_mipmaps` apagado | ídem |
| Protagonistas v3 (geometría propia) | `c07d761` | Ajustes «Protagonistas: v3» | `DIRECCION_HEROES_V3.md` |
| Oakhaven vivo y familia de NPC chibi v2 | `2694dcf` | `mundo_vivo_v12`; Ajustes | `INVENTARIO_MUNDO.md` |
| Animación de combate v12, sin deslizamiento y con fases | `2694dcf` | Ajustes «Combate» (con los v2) | `COMBATE_TACTICO_V12.md` |
| Gólem de ámbar y sincronía del golpe a todos de los jefes | `2694dcf` | `enemigos_v12`; la sincronía, encendida | — |
| Bramavidrio v5, «la v4 resuelta» | `c4c64e1` | Ajustes «Bramavidrio» opción 5 | `memory/agents/animaciones_v12_bramavidrio5.md` |
| Línea de turnos visible | `22045b3` | Ajustes «Combate» | — |
| Cumbres de Ciclópea 3D: sector 1, estatua, ventisca y refugios | `01b6ac3`, `04077ef` | `ciclopea3d`; Ajustes | `INVENTARIO_MUNDO.md` §8 |
| Gorthor v12: la Hoguera del Devorador | `01b6ac3` | `enemigos_v12` | — |
| Esgrima de Garon y magia blanca de Lya (pilotos de 3 acciones) | `04077ef` | `esgrima_v12`, `magia_blanca_v12` | `GARON_ESGRIMA_V12.md`, `LYA_MAGIA_BLANCA_V12.md` |
| Nix v2, cuarta heroína en prototipo, con 3 hechizos | `04077ef` | `nix_v12` | `NIX_V12.md` |
| Errores del motor «material is null» y del ratón sin ventana | `04077ef` | encendido | — |
| **Capa de Garon** bien puesta (original, v2 y v3) | `cefed0a` | **encendido** | `memory/agents/animaciones_v12_combate2.md` |
| Bestiario: Peón de Linde y Velador de Corteza v2 | `e9329fd` | `enemigos_v12` | `BESTIARIO_V12.md` |

**Baterías:** la última completa de la rama dio 153 superadas · 2 fallidas · 72 manuales; los dos fallos (afinidades y
memoria de audio) quedaron arreglados en `e9329fd`. Las partidas reales no cambiaron en ninguna pasada.

## Lo que hay que validar en el Redmi (por prioridad)

1. **Gran Bosque en medio:** si no llega a 30, probar `gb_matas_casco` y `gb_hojas_mipmaps`.
2. **Sin parones:** primer combate, primer diálogo y primera apertura de menús.
3. **Capa de Garon:** en combate y en exploración.
4. **Opciones apagadas, encendiéndolas una a una:**
   - Ciclópea 3D (bajo y medio; ventisca y arroyo helado);
   - Oakhaven vivo (plaza, mercado, forja);
   - línea de turnos;
   - animación de combate v12;
   - enemigos v12, sobre todo tres Peones: cada enemigo dibuja su propia ventana;
   - Nix;
   - Firmamento (fluidez y gestos táctiles).

## Decisiones del usuario pendientes

- **Firmamento:** qué concepto, cómo se obtienen los orbes (7 propuestas), precios y si el saldo es común.
- **Accesorios:** dónde se consigue cada uno; la Reliquia del Confino.
- **Qué opciones se encienden:** mundo vivo, animación v12, línea de turnos, enemigos v12, esgrima y magia blanca, Ciclópea 3D.
- **Nix y Naira:** ¿sustituye, se reparten o conviven? Si conviven, «Eclipse» coincide con la firma de Naira.
- **Bramavidrio:** v5, v4 o v2.
- **Héroes v3:** ¿se sigue con la geometría propia? De cerca están por debajo de los v2, pero no dependen de Meshy.
- **Reglas de combate:**
  - si Defender vale contra el golpe devastador de los jefes;
  - el «Retroceso» del bestiario;
  - desbloqueo por nivel de las técnicas nuevas;
  - si Aurel pasa a modelo 3D.
- **Ampliaciones:** los otros 8 enemigos del bestiario, las 15 técnicas restantes de Garon, las 21 de Lya y los 21 hechizos de Nix.

## Límites conocidos (dichos con franqueza)

- **Modelos hechos por guion:** Nix, NPC, bestiario y héroes v3 quedan por debajo del pintado de los héroes de Meshy cuando se ven de cerca.
- **Sonidos nuevos:** los niveles se midieron, pero no se escucharon.
- **Tiempos de fotograma del PC:** casi todos salieron con decenas de Godot de otros especialistas abiertos a la vez; sirven las comparaciones de dibujos y memoria, no los milisegundos.
