# A. INFORME DE RENDIMIENTO — Fase 2 (10/11/2026)

**Antes:** `integracion-experimental` @ `0d06bd1`. **Después:** `claude/rebelum-optimizacion-fase2` @ `8381d75`.

**Dónde se midió:**
- Todo en el PC de desarrollo, con datos aislados.
- **El Redmi no estaba disponible** (el usuario se lo llevó y pidió no usar ADB), así que no hay ninguna medida del
  teléfono de esta fase. Lo marcado «no medido» no se ha medido.

## Tabla comparativa

| Medida | Antes | Después | Cómo |
|---|---|---|---|
| Archivos precargados al arrancar | 791 | 699 | `pruebas/medir_precarga.gd`, sin ventana |
| Peso importado de la precarga (perfil alto) | 276,6 MB | 181,3 MB | ídem |
| Peso importado de la precarga (perfil bajo) | 276,6 MB | 177,6 MB | ídem, `perfil=bajo` |
| Cargar la lista uno a uno (sin ventana) | 4,0 s | 3,3 s | ídem |
| **Arranque en el PC hasta «TOCA PARA EMPEZAR»** (con ventana) | 12,5-12,6 s (5 pasadas) | **11,6-11,7 s** (5 pasadas) | `carga.gd` «Carga terminada en X s», pasadas alternadas |
| **Memoria máxima del juego en el PC durante el arranque** | 1212-1213 MB | **925-939 MB** | memoria privada del proceso de Godot, 2 pasadas cada uno |
| Primera apertura en el Redmi (61 s el 10/11) | — | no medido | sin teléfono |
| Aperturas posteriores en el Redmi (22-25 s) | — | no medido | sin teléfono |
| Entrada en Pastos Verdes 3D en el Redmi (~24 s la primera) | — | no medido | sin teléfono |
| Entradas sucesivas en regiones | — | no medido | sin teléfono |
| FPS por perfil (Redmi: bajo 30,1 · medio 27,4 · alto 10,3 · combate 59,9) | — | no medido | sin teléfono |
| Tiempo de transición entre escenas | — | no medido | sin teléfono |
| Tamaño de la APK de pruebas «Auditoría» | 292 917 900 bytes (v387, `94a6592`) | 293 074 534 bytes (v418, `ddcc1d3`) | compilación local; +153 KB por lo integrado de los especialistas: esta fase no cambia qué va en la APK |

**Archivos de las medidas:**
- `D:\REBELUM_diagnostico\fase2\` (precarga y texturas);
- `D:\REBELUM_diagnostico\fase2\arranque\` (arranques con ventana).

## Qué cambió y por qué ayuda

La pantalla de carga precarga casi todo `res://` y **lo retiene en memoria toda la partida**. Se quitaron de esa lista
tres grupos de cosas que no se usaban:
1. **Texturas que ningún modelo usa** (−62,7 MB en la raíz):
   - Godot saca las imágenes de cada FBX como `<modelo>_N.png`, pero los modelos solo dependen de algunas:
     - Kael, Garon y Grimfang usan `_0` y `_1`; sus `_2` y `_3` no las usa nadie;
     - Érebo no usa ninguna `_0`;
     - Lya (Meshy) solo usa `_0`.
   - Además, ocho texturas de dos FBX de Meshy que ya no existen.
   - Comprobado cargando cada modelo y leyendo sus dependencias (`pruebas/medir_texturas_modelos.gd`).
2. **Oakhaven 3D de otro perfil:** se precargaban a la vez los edificios completos y los ligeros, y cada perfil usa
   solo unos. Ahora, solo los del perfil en uso: −13 modelos; en el perfil bajo, de 8,8 a 2,7 MB.
3. **`vegetacion_prueba/` y `pruebas/`:** nunca van en la APK. Solo alargaban el arranque del PC.

**Qué cabe esperar en el Redmi** (a confirmar midiendo):
- en la APK no están `vegetacion_prueba/`, `pruebas/` ni las `_0` de Érebo, así que allí la mejora es menor que en el
  PC;
- aun así, unas 13 texturas grandes y 13 modelos menos que cargar y mantener en memoria de vídeo.

**Sin tirones nuevos:**
- todo lo que se quitó no lo usa nadie;
- la otra versión de Oakhaven solo se cargaría si el jugador cambia de perfil en Ajustes, y entonces al entrar en la
  región, con la pantalla en negro.

## 3D en Android y calidad adaptable

- **Calidad adaptable:** el sistema de perfiles Automática / Baja / Media / Alta, con límite de FPS, histéresis y lo
  manual por encima de lo automático, lo hizo el especialista de rendimiento. Se integró hoy en
  `integracion-experimental` (`4cb20cc`):
  - tiene su prueba (`prueba_calidad_auto`) y pasa en la batería;
  - el perfil alto no cambia;
  - el medio pasa al «candidato B», medido en el Redmi el 09/11 (30,3 FPS, p95 34,3 ms, frente a 27,1 FPS).
  - **Falta validarlo en el Redmi:** que la Automática elija bien, que no oscile y que no cambie en combate.
- **Optimizaciones del 3D** (llamadas de dibujo, sombras, vegetación, agua, LOD): **no se ha cambiado nada en esta
  fase.** Sin el teléfono no se puede demostrar que una mejora no empeora la imagen ni los FPS, y la norma es «calidad
  visual primero». Lo que conviene medir primero en el Redmi está en `FASE3_TALLERES.md`, al final.

## Intentos descartados

- **Cargar después del menú lo del combate** (modelos de los héroes, Érebo, música): reduciría el arranque, pero la
  carga en segundo plano podría dar tirones en el mapa o en el primer combate. Sin el Redmi no se puede medir, y la
  orden pide no cambiar una carga larga por tirones. Queda propuesto, con la medida que lo decidiría.
- **Sacar de la APK las texturas sin uso:** la APK sería más pequeña, pero hace falta compilar e instalar para
  comprobar que nada las echa de menos. Queda propuesto.
