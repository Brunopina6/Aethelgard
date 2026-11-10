# Sonido · V9: identidad sonora del Guardián del Bosque y audio del orbe del altar

## 2026-11-10, 18:50 · rama `claude/v9-sonido-guardian` (copia `D:\Aethelgard_v9_sonido-guardian`)

Encargo (directiva V9: «identidad sonora de cada jefe» y «audio del altar»): que el Guardián del Bosque Olvidado deje de
sonar con lo genérico de los jefes y que el orbe del altar tenga su visión y su cierre. **No he podido escuchar nada. No
se ha usado el Redmi.** Base: `45724ea`. Todo con datos aislados.

### 1. Qué se ha hecho

- **El Guardián, un árbol viejo que despierta** (15 derivados en `audio/efectos/guardian/`):
  - título del jefe en lugar de «jefe»: golpe hueco de tronco con retumbar grave y crujido largo;
  - entrada (su clip «entrada»): madera arrastrada sobre el suelo del bosque, ramas y un gemido al desperezarse;
  - voz, familia nueva «corteza»: crujido y gruñido grave al alzar la rama, corteza que se desgarra al recibir y un
    crujido largo con gemido al caer. El gruñido es de criatura (yeti, ×0,75-0,85), por debajo, para que se lea como
    voz y no como un mueble;
  - latigazo de rama (señal «impacto» del modelo) y raíces que brotan con tierra, piedras y astillas (golpe cargado);
  - latido en lugar de «carga_jefe»: dos latidos lentos y graves con el tronco que se tensa;
  - rugido de corteza en lugar de «fase2»: la corteza se abre hacia 0,98 s, cuando el modelo muestra la coraza (0,93 s);
  - derrumbe al caer (las rodillas tocan la tierra hacia 1,2 s; el clip, 1,1 s), una vez y nunca si se purifica;
  - purificación con el Elixir: un cuenco tibetano una octava abajo, un colchón suave y campanillas (cálido y luminoso).
- **Tratamiento de su combate** (`sonido.gd`, `TRATAMIENTOS`). No hay música de jefe con licencia libre en el proyecto
  (solo `musica_combate_normal.mp3`, de licencia pendiente; la de Suno no entra), así que no se añade música: se trata
  la que suene. Al principio del bus Musica, un paso bajo y un volumen (baratos: sin reverberación ni cambio de tono);
  por Ambiente, un bucle de bosque antiguo (árboles que crujen con viento y un zumbido solemne, 30 s a 22 050 Hz).
  Etapas: inicio (2,8 kHz, −2 dB; bosque a −8), fase 2 (9 kHz; bosque −13), calma al purificar (abierta, −3 dB; bosque
  −6) y fin (el bosque se apaga con la victoria o la derrota). Se quita solo al irse el combate o cambiar de escena.
- **El orbe del altar:** `orbe_vision` (una copa de cristal frotada que resuena, con un colchón de sueño y campanillas)
  en lugar de «misterio», y `orbe_cierra` (otra copa, más grave, que se apaga) al cerrarse la visión.
- **Mezcla y límites:** bus Efectos (el bosque, Ambiente). Prioridades: título, rugido y purificación 4 (bajan golpes y
  pasos mientras suenan, como «jefe»); entrada, latido, raíces, derrumbe y caída 3; latigazo, voz de ataque y de herido
  2. La voz va en el grupo «voz» (dos a la vez como mucho) y una por enemigo; variantes sin repetir y tono leve; esperas
  mínimas por efecto. Limitador del Master y música que se aparta, los de la tanda 7.
- **Licencias:** todos los originales y capas, de los paquetes GDC de Sonniss 2016, 2017, 2018, 2019 y 2023 (PDF de
  licencia en la raíz de cada paquete, vistos de nuevo hoy). Nada de CC0 nuevo, nada de Suno. 18 filas nuevas en
  `docs/audio/efectos_procedencia.csv`; 187 de 187 originales intactos.
- **Herramienta:** `prueba_efectos_preparar.gd` ya no escribe el CSV si no encuentra la biblioteca, ni pierde la fila de
  una receta que no pudo rehacer. Pasó en la primera pasada (los argumentos llegaron juntos y dejó el CSV con solo la
  cabecera); lo restauré con `git restore` (el archivo no tenía cambios míos) antes de seguir.

### 2. Cambios en archivos de otros (solo llamadas a Sonido, como pedía el encargo)

- `combate.gd`:
  - `_presentar`: con el Guardián, `Sonido.efecto("guardian_bosque_jefe", {"en": self})` (el combate es el dueño del
    tratamiento); los demás jefes siguen con «jefe» (4 líneas en lugar de 1);
  - `_turno_guardian`: «carga_jefe» → «guardian_bosque_carga»;
  - `_cambio_fase_bosque`: «fase2» → «guardian_bosque_fase2»;
  - `_usar_elixir`: `Sonido.efecto("guardian_bosque_purificar")` tras «pocion»;
  - `_anim_guardian`: `_voz(o, "ataque")` al empezar (la voz del Guardián al alzar la rama);
  - `_restablecer_color`: al principio, el derrumbe una vez si el Guardián cae y no está purificado (`_sonar`, 3
    líneas con su condición). Es el único sitio común a cualquier forma de caer (golpe o magia).
- `zonas3d/bosque_pastos.gd`, `_vision`: «misterio» → «orbe_vision», y «orbe_cierra» al cerrarse.
- La entrada y los impactos no necesitan cambios: `combate.gd` ya pedía «<clave>_entrada» y convertía las señales
  «impacto» del modelo en «guardian_bosque_ataque» y «guardian_bosque_golpe». La señal «aviso» pide
  «guardian_bosque_aviso_golpe», que **a propósito no existe** (el latido ya lo pide `combate.gd`, también con el
  dibujo 2D de respaldo, y sonaría dos veces).

### 3. Commits (rama `claude/v9-sonido-guardian`)

| Commit | Qué |
|---|---|
| `197d640` | Derivados (`guardian/`, `ambiente/bosque_antiguo`, `mundo/orbe_*`), recetas y CSV de procedencia |
| `5735c5e` | `sonido.gd`: catálogo, familia «corteza», `TRATAMIENTOS` y `tratamiento()` |
| `fcde764` | Las llamadas en `combate.gd` y `zonas3d/bosque_pastos.gd` |
| `c4a627f` | Pruebas: `prueba_audio_guardian` (+ `.uid`), `lista_pruebas.txt`, `prueba_audio_memoria`, `prueba_efectos`, `prueba_efectos_senal` («mezclas=9») |
| `20f9094` | `docs/audio/inventario_sonidos.md` (sección V9) y `docs/recursos.md` |
| (este) | Inventario con la señal medida e informe |

### 4. Pruebas (todas con datos aislados; importación aislada antes, `project.godot` restaurado)

- **Tanda** (10/11, 18:33, con `20f9094` salvo los documentos): `prueba_audio_guardian`, `prueba_efectos`,
  `prueba_audio_memoria`, `prueba_guardian_bosque`, `prueba_audio`, `prueba_combate_huella` y `prueba_bosque_pastos`:
  **7 superadas, 0 fallidas**. Partida real, carpeta real y proyecto, sin cambios (había Godot de otras copias; ninguno
  sobre la mía). Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-10_183339\resumen.md`.
- `prueba_audio_guardian` (nueva, muda): las 14 claves cargan (QOA mono, su frecuencia), no saturan, caben en su
  presupuesto (920 KB en total, 1 250 de presupuesto) y tienen fila de procedencia de un paquete con licencia y su
  línea en el inventario; voz «corteza» sin cambiar la familia de los demás; el tratamiento por etapas y que se quita
  (el bus Musica queda como estaba); y dos combates de verdad con el modelo 3D: título en lugar de «jefe», entrada,
  voz y latigazo, latido en lugar de «carga_jefe», raíces al descargar, rugido en lugar de «fase2», derrumbe una sola
  vez y ninguno al purificarlo (con su sonido).
  - La primera pasada falló por dos cosas mías: faltaba el inventario (lo escribí después a propósito, con las
    medidas) y un `is` sobre un nodo ya liberado en `_trata_vigente` (corregido: primero `is_instance_valid`).
- `prueba_audio_memoria`: todo el audio, **20,36 MB** de RAM (presupuesto 21; antes 19,47).
- `prueba_efectos_senal` con ventana y el driver real (MANUAL, 0 fallos): cada efecto solo y la pelea por buses sin y
  con tratamiento. Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-10_183540\resumen.md`.
- `prueba_efectos_preparar … comprobar`: 187 de 187 originales intactos.

### 5. Evidencias

- Muestras con índice y qué escuchar primero: `D:\REBELUM_diagnostico\sonido_muestras\2026-11-10_guardian\indice.md`
  (13 efectos solos y 5 mezclas `buses_v9_*`; cada bus por separado en `D:\REBELUM_diagnostico\pruebas\2026-11-10_183540\prueba_efectos_senal\`).
- Niveles y tablas: `docs/audio/inventario_sonidos.md`, sección V9. Lo principal, medido con la misma pelea:

| Mezcla | Música (RMS) | Bosque antiguo | Efectos sobre la música (mediana) | Pico del Master |
|---|---|---|---|---|
| sin tratamiento | −23,9 | — | −4,3 dB | −3,8 |
| fase 1, con tratamiento | −25,6 | −34,0 | −1,4 dB | −4,2 |
| fase 2 | −24,9 | −35,6 | −2,7 dB | −4,2 |

- Derivados (pico / RMS / duración) y la FFT del bucle (por encima de 11 025 Hz, −63 dB): en el inventario.

### 6. Límites

- **Nadie lo ha oído.** Lo más dudoso: si el gruñido de yeti bajo la madera suena a monstruo genérico; si el latido se
  lee como corazón de árbol o como efecto de miedo; si la música con paso bajo suena «dentro del bosque» o solo
  apagada; y si la copa de cristal del orbe resulta demasiado aguda.
- `corteza_ataque` salió 8 dB más baja en la grabación (RMS −41,9) por la propia prueba: sonó justo después de la
  purificación (prioridad 4, que baja lo demás); en el juego, ≈ −34. No es un fallo del juego.
- La mezcla está medida por nivel (RMS), no por bandas. La música medida es la del combate de siempre (licencia
  pendiente), solo en local.
- Con el dibujo 2D de respaldo (si el modelo 3D no carga) no suenan la entrada, el latigazo ni las raíces (vienen de las
  señales del modelo); el título, el tratamiento, el latido, el rugido, la voz, el derrumbe y la purificación sí.
- **Pendiente en Redmi:** cómo se oye en el altavoz del móvil y el coste real del paso bajo en el bus Musica (no medido:
  sin medidas de rendimiento mientras trabajan otros especialistas).

### 7. Siguiente paso

- **Usuario:** escuchar el índice de hoy, sobre todo la voz, el latido y la pelea sin y con tratamiento.
- **Coordinador:** integrar la rama. Los cambios en `combate.gd` y `bosque_pastos.gd` son solo las llamadas de la sección
  2; si alguien más toca esas funciones, ojo al fusionar.
- Si se consigue música de jefe con licencia libre, el tratamiento vale tal cual (actúa sobre el bus Musica).
