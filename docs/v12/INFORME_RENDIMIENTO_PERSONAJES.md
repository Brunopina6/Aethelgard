# Informe: rendimiento, personajes y estabilidad (12/11/2026, sesión sin teléfono)

Rama LOCAL `claude/rebelum-v12` en `D:\Aethelgard_v12`. Sin push, fusiones, releases ni instalaciones.
Punto de recuperación: etiqueta `v12-antes-rendimiento-personajes` (= `fadb5fa`).
**Todo lo medido aquí es del PC.** Nada se ha comprobado en Android: ver §9.

## 1. Mejoras y commits

| Commit | Qué | Efecto medido (PC, medio) |
|---|---|---|
| `e283167` | Herramienta de medida reproducible y la vuelta del combate sin rehacer el terreno | Vuelta del combate de Bramavidrio 1833 → 890 ms; a Pastos 1615 → 1178 ms |
| `cb82455` | Humbaba (APAGADO) y héroes v2 pulidos, elegibles en Ajustes | Ver §4 y §5 |
| `ca71cd7` | Texturas de los héroes v2 comprimidas para la GPU | Memoria de vídeo con los v2: 213 → 111 MB; cargas como las de los originales |
| `21dd706` | Texturas de Garon, el goblin y el Guardián de piedra comprimidas | Memoria de vídeo en combate 138 → 114 MB |

1. **Terreno guardado entre entradas** (`zonas3d/mar_cristal/terreno.gd`, `prototipos/sendero_puente.gd`).
   - **Medido:** el `_ready` de la región se desglosó con marcas de tiempo temporales.
     - Mar de Cristal: la arena y la falda (mallas hechas vértice a vértice en GDScript) suponían 935 ms de 1,07 s de su escenario.
     - Pastos Verdes: el terreno, 370 ms.
     - Ambos salían idénticos en cada entrada, también al volver de cada combate.
   - **Arreglo:** se guardan con su forma de choque en `Recursos`, grupo «zona».
     - El grupo se libera al salir al mapa del mundo; no se libera al ir y volver de un combate.
     - La clave incluye lo único de lo que dependen: alturas y tipo de material en el desierto, y el guion de la escena en Pastos.
   - **Coste:** ~14 MB de memoria estática mientras se está en Pastos y sus combates (2-4 MB en el Mar de Cristal).
2. **Texturas sin comprimir** (`*.import`, `compress/mode` de 0 a 2, VRAM S3TC/ETC2).
   - **Afectadas:**
     - las de los héroes v2: 8 texturas de 2048 px; las normales con compresión de normales;
     - `garon_0.png` y `goblin_0.png` (2048 px), que venían así desde el primer commit, mientras que la de Kael ya estaba comprimida;
     - las del Guardián de piedra.
   - **Sin diferencia visible:** comparadas en capturas del combate real ampliadas ×2 (`D:\REBELUM_diagnostico\rendimiento\2026-11-12_heroes\*.png`).
   - **Se dejan sin comprimir:**
     - las de Érebo, porque salen en primeros planos de la invocación;
     - los atlas de las caras de los v2, por la nitidez de los ojos.
3. **Herramienta de medida** (`pruebas/medir_escenas.gd`, `.ps1` y `resumir_medidas.ps1`; anotada en `lista_pruebas.txt`). Mide:
   - primera carga y carga repetida;
   - reposo y actividad: mediana, p95, p99 y tirones;
   - dibujos y primitivas;
   - memoria por ciclo, para detectar lo que se retiene.
   - Se lanza un proceso por escena y perfil, con datos aislados, y se apunta qué otros procesos corrían.

## 2. Rendimiento antes y después (PC)

**Condiciones de medida:**
- **Equipo:** Ryzen 7 4800H y RTX 3050 portátil, Godot 4.7.2 Compatibility.
- **Imagen:** 1280×720, sin sincronía vertical ni tope de FPS, `--fixed-fps 30` (el mismo recorrido siempre).
- **Ciclos:** 3 en medio y 2 en bajo y alto.
- **Antes:** `fadb5fa`, en `D:\REBELUM_diagnostico\rendimiento\2026-11-12_base\`.
- **Después:** `21dd706`, en `...\2026-11-12_despues\` (tabla completa en `tabla_antes_despues.md`).
- **Otros procesos:** ningún otro Godot ni Blender con carga durante la pasada de medio del «antes» ni durante el «después».
- **Ruido:** las primeras cargas varían ±20 % entre pasadas; las repetidas y la memoria, poco.

| Escena (medio) | Carga repetida (ms) | Vuelta del combate (ms) | Fotograma activo med / p95 (ms) | Dibujos | Memoria de vídeo (MB) |
|---|---|---|---|---|---|
| Portada (hasta «TOCA PARA EMPEZAR») | 548 → 490 | — | — | 85 → 85 | — |
| Pastos Verdes | **1246 → 709** | — | 3,55 / 5,09 → 3,30 / 3,84 | 116 → 116 | **105 → 86** |
| Garganta | 879 → 622 | — | 4,04 / 5,55 → 3,97 / 5,06 | 191 → 191 | **117 → 86** |
| Oakhaven | 1971 → 1836 | — | 3,61 / 5,35 → 3,47 / 4,25 | 87 → 87 | 108 → 97 |
| Gran Bosque Verde | 924 → 785 | — | 3,89 / 5,03 → 3,74 / 4,59 | 176 → 176 | 82 → 71 |
| Mar de Cristal | **1453 → 419** | — | 3,19 / 4,37 → 3,20 / 3,87 | 58 → 58 | 75 → 64 |
| Combate de Bramavidrio | 641 → 515 | **1833 → 775** | 3,63 / 6,68 → 3,50 / 4,64 | 88 → 88 | 120 → 110 |
| Combate de tres (Pastos) | 768 → 538 | **1615 → 1051** | 4,37 / 6,37 → 3,79 / 5,37 | 103 → 105 | **140 → 114** |

- **Primera carga** (proceso nuevo, datos nuevos):
  - el arranque hasta «TOCA PARA EMPEZAR» pasa de 10,8 a 9,9 s;
  - con la caché de zonas ya creada (segundo arranque), 5,6 s desde que el motor está listo (`medir_cargas.gd`);
  - las regiones, entre 2,5 y 3,3 s sin cambios fuera del ruido.
- **Memoria al salir** (escena vacía, 3 ciclos): no crece de un ciclo a otro en ninguna escena y no quedan nodos huérfanos.
- **Bajo y alto:**
  - las mismas mejoras: el Mar de Cristal repetido 1532 → 443 en alto y 1497 → 444 en bajo; la vuelta del combate de Bramavidrio 1781 → 743 en alto y 1910 → 797 en bajo;
  - los dibujos y las primitivas no cambian;
  - el tiempo por fotograma, igual dentro del ruido (±0,3 ms).
- **Calidad por perfil:** no se ha rebajado nada; los tres perfiles conservan sus dibujos, primitivas, sombras y resolución.
- **Pastos y el combate de tres, p99 del reposo** (188 → 70 ms): no es una mejora del juego. La primera pasada «antes» no preparaba Dialogic como hace el arranque real (`carga.gd`) y medía su primer diálogo; la herramienta ya lo hace.

## 3. Cargas: qué se investigó

- **Combate de Bramavidrio:** la pantalla negra ya no existe. Del encuentro al combate, ~0,9 s de fundido del aviso más 0,1 s de `_ready` (`medir_cargas.gd`).
- **Vuelta del combate:** 1,1 s en negro. Era el `_ready` de la región, rehecho entero; arreglado en las dos regiones con más combates. Lo que sigue costando:
  - crear el grupo: 160-230 ms;
  - Kael: 35-115 ms;
  - la estatua del Guardián en Pastos: 50 ms.
- **Arranque:** 4,3 s se van en la fase de archivos (871 archivos, 184 MB importados que quedan en memoria toda la partida). No lo he tocado: hay que decidir qué se deja de precargar sin crear tirones, y eso requiere medirlo en el Redmi.
- **Primer combate de la partida:** hay dos tirones de 52-67 ms en el PC: la primera lista de objetivos y el primer número de daño con sus partículas. Sin arreglar.

## 4. Personajes (héroes v2: Kael, Lya y Garon)

- **Opción en Ajustes:** «Protagonistas: originales / v2 (prueba)». Por defecto, los originales. Los originales no se han tocado.
- **Hecho y verificado** por la especialista y revisado aquí en sus capturas:
  - **Victoria de Kael:** en el original, la empuñadura queda tras la cabeza (medido: 0,15 m y la hoja tapada al final). En la v2, el sable baja por un lado y acaba en diagonal: 0,28 m de distancia y nada tapado.
  - **Caras:** transparencia solo en ojos y boca; sin el ajuste de color AgX que dejaba los párpados como parches beis; expresión «decidido»; parpadeo distinto (Kael rápido cada 2,0-4,6 s, Lya lenta cada 3,4-6,8 s).
  - **Materiales:** piel, tela y cuero mates; borde de luz sin emisión; el metal refleja el ambiente de la región. A la distancia del juego, la mejora es sutil.
  - **Animaciones:**
    - el golpe de Lya tiene carga, pausa y seguimiento;
    - la magia de Kael lleva el sable en alto;
    - la victoria de Lya deja el cetro al lado.
    - Los instantes de impacto no cambian.
- **Rendimiento de los v2** (PC, medio, comparación intercalada en dos pasadas): tras comprimir sus texturas cuestan lo mismo que los originales.
  - Memoria de vídeo: 111 MB frente a 105.
  - Cargas: Pastos repetido 809 frente a 850 ms; entrada al combate 736 frente a 716 ms.
  - Fotograma: igual.
- **Evidencias:** `D:\REBELUM_diagnostico\animaciones\2026-11-13\heroes_pulido\`:
  - `comparaciones\`: el original a la izquierda y el v2 a la derecha, con el mismo encuadre, luz, perfil y pose, en combate y en las cinco regiones;
  - `videos\`: Kael, Lya y Garon, unos 15 s cada uno, grabados en Godot;
  - `diagnostico\`.
- **Límites:**
  - sin texturas ni geometría nuevas;
  - `hablar(animo)` sin enganchar a Dialogic;
  - el deslizamiento de pies, revisado a ojo y sin medir;
  - en las capturas de cerca de las regiones, los v2 se giran hacia la cámara y los originales no.

## 5. Humbaba (APAGADO, `humbaba_v12`)

- **Modelo:** 72 huesos y 23 clips; LOD de 35,9k, 19,2k y 12,0k triángulos.
- **Combate:** `combate_humbaba.gd`, con 7 ataques, 3 fases y el Réquiem.
- **Santuario:** en el Gran Bosque, solo con el interruptor; se ve con `-- grupo=17` o `-- humbaba_v12`.
- **Pendiente:**
  - tamaño en combate: 2,8 veces Kael, por el encuadre;
  - equilibrio: se gana a nivel 22 y el Gran Bosque es de nivel 4;
  - identidad sonora propia;
  - textos;
  - medirlo en el Redmi (35,9k triángulos y 72 huesos es mucho para el Mali-G57).
- **Informe:** `docs/memory/agents/animaciones_v12_humbaba.md`.

## 6. Bramavidrio, audio y controles

- **Bramavidrio:** no se ha tocado su anatomía ni sus ataques. La v4 (referencia del usuario) sigue elegible y no predeterminada, con el chorro desde la garganta. La vuelta de su combate ya no rehace el desierto.
- **Audio:**
  - las tres canciones siguen en sus funciones;
  - pruebas de música, título, clímax y Pastos superadas en la batería;
  - nada se ha escuchado en esta sesión: son pruebas de niveles y reproductores.
- **Controles:** no se han tocado. El tacto en Android sigue sin comprobar.

## 7. Pruebas

- **Batería tras integrar Humbaba y los héroes** (`cb82455`): **135 · 0 · 63 · 0**; partida real, carpeta real de datos y proyecto sin cambios.
- **Pruebas de regiones** tras la caché de terreno: 12/12.
- **Pruebas de modelos y combate** tras la compresión: 8/8. `prueba_heroes_v2`: superada.
- **Batería final** (`21dd706`): **135 · 0 · 63 · 0**, con la partida real y la carpeta real de datos sin cambios (`D:\REBELUM_diagnostico\pruebas\2026-11-12_171211\resumen.md`).
- **No ejecutado:** nada en Android; las pruebas «ventana» (MANUAL) no se han revisado una a una salvo las de los héroes.

## 8. Prototipos que siguen apagados

- Héroes v2 (se eligen en Ajustes).
- Bramavidrio v1, v3 y v4.
- Humbaba (`humbaba_v12`).
- Vidracrán (`encuentro_desierto_v12`).
- `magia_negra_v12`, `naira_v12`, `enemigos_v12` y `npc_desierto_v12`.
- Pastoral Pulse como predeterminada.
- La pantalla de inicio alternativa.

## 9. Verificaciones para el próximo día con el Redmi

1. **Vuelta del combate al Mar de Cristal y a Pastos:** cronometrar el negro, antes ~1,1 s en el PC.
2. **Memoria de vídeo y del proceso:** en combate de tres y en Pastos, comparada con la v656 (0,83 GB en combate).
3. **Héroes v2** (Ajustes → v2):
   - un combate de tres y Pastos: FPS, memoria y tiempos;
   - a ojo, la cara transparente, el borde de luz y la luz envolvente en Mali;
   - las texturas comprimidas en ETC2: Garon, el goblin y los v2.
4. **Bramavidrio v4:** FPS y aspecto en bajo y medio.
5. **Humbaba:** perfil bajo, FPS y memoria.
6. **Vidracrán y el rincón del Mar de Cristal.**
7. **Gran Bosque en medio:** seguía a 21-25 FPS en la v649.
8. **Tacto:** menús, diálogos y combate, sin dobles toques en las cargas.

## 10. Problemas pendientes

1. **Arranque:** 4,3 s de archivos en el PC; 184 MB precargados toda la partida.
2. **Crear el grupo** al entrar en cada región: 160-230 ms.
3. **Tirones del primer combate:** 52-67 ms en el PC.
4. **Gran Bosque en medio** en el Redmi.
5. **Humbaba:** equilibrio y escala.
6. **Decisiones del usuario:**
   - versión de Bramavidrio;
   - encender los héroes v2;
   - el resto de propuestas apagadas.

## 11. APK local (sin instalar ni publicar)

- **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261112-21dd706.apk`, 371,9 MB.
  - Paquete `com.aethelgard.auditoria`, versionCode 665, versionName `androidauditora-20261112-21dd706`.
- **Firma:** certificado SHA-256 `3413edcd8c11ec1ce77a64566da5ed17582b4a2b31b869ccaeb0a120d17785f3`, el de siempre (verificado con `apksigner`).
- **SHA-256 del APK:** `851583535ade16380ead6e5c0c2f6430823768710c972d33daa8a3c6dd1bafb2`.
- **Commit:** `21dd706`, el de la batería final 135 · 0 · 63 · 0.
- **Cómo probarla:** se instala a mano encima de la Auditoría (MIUI pide confirmación). En Ajustes:
  - «Protagonistas: v2 (prueba)» para los héroes v2;
  - «Bramavidrio» para la v4.
