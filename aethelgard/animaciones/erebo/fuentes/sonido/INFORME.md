# Sonido de la invocación cinematográfica de Érebo (V12)

14/11/2026, especialista de sonido. Tiempos tomados de `D:\Aethelgard_v12\docs\v12\EREBO_CINEMATICA_V12.md` (§2, §3 y §5).
Nada de esto está en el repositorio ni en ninguna copia de trabajo.

## Entregables (en `D:\REBELUM_diagnostico\erebo_cine\sonido\`)

| Archivo | Qué es |
|---|---|
| `erebo_cine_completa.wav` | 20,000 s exactos (882 000 muestras), estéreo, 44 100 Hz, 16 bits |
| `erebo_cine_abreviada.wav` | 6,800 s exactos (299 880 muestras), mismo formato |
| `stems/<versión>_latidos.wav`, `_zumbido_motivo.wav`, `_efectos.wav`, `_ambiente.wav` | Capas separadas, misma duración y ganancia maestra, **antes del limitador** |
| `procedencia.csv` | 87 filas: cada tramo usado de la biblioteca (ruta, desde–hasta, SHA-256, licencia, uso) |
| `medidas.json`, `verificacion.txt` | Medidas del proceso y verificación independiente releyendo los WAV del disco |
| `forma_onda_completa.png`, `forma_onda_abreviada.png` | Forma de onda (violeta: pico; magenta: RMS), marcas de los eventos y líneas de −1 dBFS |
| `guion/` | Los scripts que lo generan todo (Python de Blender 5.2, numpy; deterministas) |

Regenerar: `"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P guion\componer.py -- <carpeta>`
y después `-P guion\medir.py -- <carpeta>`.

## Medidas (comprobado ejecutando, 14/11, releyendo los archivos)

| | Completa | Abreviada |
|---|---|---|
| Pico de muestra / pico real (×4) | −1,30 dBFS / −1,20 dBTP | −2,57 dBFS / −2,57 dBTP |
| Sonoridad integrada (BS.1770, medidor propio) | −16,0 LUFS | −16,0 LUFS |
| Corto plazo máx. (3 s) | −14,2 LUFS | −15,4 LUFS |
| RMS total | −17,6 dBFS | −17,7 dBFS |
| Reducción máx. del limitador | 1,3 dB | 0 dB (no actúa) |
| Agarre (mayor subida de nivel, banda completa) | 9,8503 s (+0,3 ms) | 2,6003 s (+0,3 ms) |
| Silencio tras el agarre | 9,96–10,095 s: −96 dBFS RMS (solo el tramado) | 2,68–2,745 s: −96 dBFS RMS |
| Reanuda | 10,099 s | 2,749 s |
| Pausa casi muda (sin el latido) | 16,45–16,69 s: −50 dBFS RMS | 4,93–4,985 s: −49 dBFS RMS |
| Latido único de la pausa | 16,700 s | 4,990 s |
| Liberación | 17,000 s (−0,2 ms) | 5,150 s (+0,3 ms) |
| Últimos 200 ms antes del fundido | −20 dBFS RMS (la ráfaga suena) | −18,6 dBFS RMS |
| Primera / última muestra | 0 / 0 (sin clic; fundido final de 50 ms) | 0 / 0 (fundido de 40 ms) |

Suma de stems frente a la mezcla: abreviada idéntica (−87 dBFS de diferencia); completa difiere solo donde actúa el
limitador (diferencia RMS −49 dBFS, pico −17 dBFS en los dos golpes).

## Qué suena en cada plano (completa)

| Plano | Sonido |
|---|---|
| P1 0–3,8 | Negro con la cueva húmeda (goteo y viento interior) entrando. Latidos graves a 0,3 / 1,4 / 2,4 / 3,1 / 3,6, cada vez más fuertes (latido real muy filtrado + golpe de tambor sintético). Zumbido del orbe desde 0,6 (re, voces desafinadas que baten). Siete campanillas de runa de 2,0 a 3,14, con las notas del motivo en agudo, girando de un lado a otro. Temblor desde 3,0 (textura «Tremor» + rumor sintético a 11 Hz) |
| P2 3,8–8,0 | Ráfaga grave de la sombra (soplido sintético + «Twisted Vocal» grave + remolino de viento filtrado). Cuero y tela al salir las manos (3,95 / 4,7), crujidos de garras (4,4 / 4,75 / 5,05), ropa al incorporarse (5,45), capa (6,05), cabeza (6,9). Entra el bordón de re. **Motivo** re 5,4 – la♭ 6,1 – sol 6,8 y, a 7,4, el acorde de las tres notas con un destello metálico sintético sobre la máscara. Coro difuso (voces al revés, filtradas) muy bajo |
| P3 8,0–11,6 | Brazo que se tiende (capa); latidos de tensión 8,45 / 9,0 / 9,45; subida (riser) hasta el agarre; cinco crujidos al cerrar los dedos (9,25…9,78, el pulgar al final). 30 ms hundidos antes del golpe. **9,85: golpe** (boom + sub 64→30 Hz + cristal que se agrieta) durante 90 ms y **silencio total hasta 10,1**. A 10,1 el golpe «continúa» donde se congeló, las siete runas suenan de golpe, chisporroteo de grietas, arco eléctrico y siseo que sube hasta 11,6. El zumbido sube medio tono (magenta) |
| P4 11,6–15,4 | Vórtice de viento al revés que gira en estéreo cada vez más deprisa, subgrave de las sombras, voces al revés girando, aspiraciones al revés que desembocan en las dos sacudidas (12,5 y 13,8: boom + capa). El zumbido baja y a 15,0 se apaga cayendo una octava; cristal oscuro y sordo (el orbe muerto) |
| P5 15,4–19,0 | Gruñido de presión sintético que sube (la♭1 → re♭2, filtro que se abre, aspereza) más un riser; **a 16,4 corte seco**: casi nada (cueva a −14 dB) y **un único latido a 16,7**. Aspiración al revés en los últimos 130 ms. **17,0: estallido** (boom, impacto, sub 72→28 Hz, onda grave, cristal que estalla, astillas a izquierda y derecha) con el **acorde del motivo** sintetizado y un *braam* en re de la biblioteca. Cola de restos de cristal |
| P6 19,0–20,0 | Ráfaga que se aleja (paso con efecto Doppler + soplido grave que baja y se va al centro), destello a 19,7 (campanillas al revés que desembocan en un brillo metálico). Termina sonando, con 50 ms de fundido |

**Abreviada:** lo mismo comprimido: latidos 0,06 / 0,55; runas 0,12–0,52; capa a 0,82; motivo 0,80 / 1,05 / 1,30 y acorde con destello a 1,45;
dedos 2,25–2,56; agarre 2,6 con 60 ms de golpe y silencio hasta 2,75; vórtice con una sacudida a 3,6; orbe muerto a 4,0;
gruñido 4,2–4,9; pausa con latido a 4,99; liberación 5,15; ráfaga desde 6,22 y destello a 6,65.

## Identidad sonora (original, sintetizada)

- **Motivo:** re3 (146,8 Hz) – la♭2 (103,8 Hz) – sol2 (98 Hz), descendente y con el semitono final; timbre de metal
  oscuro hecho con armónicos (tres voces desafinadas ±7 céntimos, filtro que se abre al atacar y se cierra), suboctava
  y reverberación por convolución con una sala sintética. En la máscara suena como acorde (re + la♭ + sol: tritono y
  semitono); en la liberación, más grande y abierto (re2 + la♭2 + sol2 + re3) sobre el *braam* en re.
- **Bordón:** re2 + re1, sintetizado; crece desde 3,8 y se corta en seco a 16,4.
- **Zumbido del orbe:** re3 y re4 con voces que baten y un trémolo que se acelera; **no** late al ritmo de los latidos
  (velocidades distintas e independientes) y no hay ningún latido «dentro» del orbe: los latidos son de tensión y
  siguen los tiempos del guion. Nada sugiere siluetas ni recuerdos (acto III).
- **Runas:** campanillas inarmónicas sintetizadas con las notas del motivo (re, la♭, sol) en agudo.

## Licencias

- **Todo lo de la biblioteca es de los paquetes GDC de Sonniss 2016, 2017, 2018, 2019, 2020 y 2023** (30 archivos;
  `procedencia.csv`). El PDF de licencia de esos seis paquetes es **el mismo archivo** (SHA-256
  `d5da822dce9462890c4cc84663e7bb461f8cff434850a4b8144e9b89cb3b516c`); lo leí entero el 14/11: licencia mundial, sin
  regalías, uso en proyectos personales y comerciales **sin atribución**, sincronización con juegos, editar y
  reproducir como parte de la producción; prohibido vender los sonidos tal cual o atribuirse su autoría.
- **No usé** el paquete de 2024 (su licencia añade una cláusula «NO AI TRAINING OR USAGE»: no es entrenamiento, pero lo
  evité para no depender de esa lectura), ni el de 2015, ni TomMusic, ni la colección CC0, ni los
  `aethelgard/sonidos/erebo_*.wav` del juego (su origen está sin registrar en `docs/versiones/licencias_pendientes.txt`),
  ni nada de Suno ni música ajena. Lo sintetizado (motivo, bordón, zumbido, runas, destellos, gruñido, subgraves,
  soplidos) es original de estos scripts.

## Límites (lo que no se pudo hacer o comprobar)

- **No puedo oír.** Todo está medido, no escuchado: el equilibrio, que las voces al revés sean de verdad ininteligibles,
  que el «Twisted Vocal» y el latido no suenen demasiado literales, y el carácter del motivo los tiene que juzgar el
  usuario con auriculares y en el altavoz del Redmi.
- **Sonoridad:** medidor BS.1770 propio (ponderación K aplicada en frecuencia; con un seno de 1 kHz da −3,05 LUFS frente
  a −3,01 de la norma). Sin medidor externo.
- **9,85 s y 5,15 s caen a mitad de fotograma** a 30 fps (fotogramas 295,5 y 154,5): el golpe empieza exactamente en
  ese instante, dentro del fotograma 295 (o 154) que está en pantalla. 17,0, 16,7, 16,4, 2,6 y 4,9 sí son límites de
  fotograma.
- **Ogg Vorbis** puede subir el pico real unas décimas al codificar: comprobar el pico tras unir el audio al `.ogv`
  (margen actual 1,2 dB en la completa). No he codificado ni unido nada al vídeo, ni lanzado Godot.
- Las sacudidas (booms con ataque lento) dan su subida más fuerte 6–20 ms después de la marca (32 ms en la abreviada):
  menos de un fotograma.
- Los silencios no son ceros exactos: llevan el tramado de 16 bits (≈ −96 dBFS RMS).
