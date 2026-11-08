# Inventario de sonidos de AETHELGARD / REBELUM (rama `rebelum-alpha`)

**Actualizado el 2026-11-08 por la noche** (T-030, D-064 y D-067). Criterio de T-030: de cada sonido, el original, el
recurso que usa el juego, el evento, la licencia y la evidencia. Tres comprobaciones **por separado**:

- **Asignación:** el código pide la pista correcta (`prueba_musica`, `prueba_audio`; sin ventana, muda).
- **Señal:** sale sonido de verdad por el bus Master con el driver de audio real (`prueba_musica_senal`, con ventana:
  graba 5 s y mide el nivel). Los WAV grabados quedan para escucharlos.
- **Escucha:** una persona lo oye en el PC o en el Redmi. **Pendiente en todo** hasta que la haga el usuario.

## Ambientes (bus Ambiente), nuevos

Bucles de 32 s como mucho, hechos con `aethelgard/pruebas/herramientas/preparar_ambientes.gd`: el final se funde 2 s con el principio,
sonoridad media pareja (RMS ≈ 0,06) sin pasar de un pico de 0,9, guardados en WAV y comprimidos en QOA al importar.

| Recurso | Original (biblioteca del autor, colección CC0) | Fuente y licencia | Dónde suena | Señal (08/11) | Escucha |
|---|---|---|---|---|---|
| `audio/ambiente/pradera.wav` (28,7 s) | `15_nature_weather/birds_48kHz_16bit_30.69s_02_s39.wav` + viento bajo (`wind_…_60s_01_s20`, ×0,28) | isaiah658, «Ambient Bird Sounds» y Luke.RUSTLTD, «wind1» (OpenGameArt): **CC0**, comprobado en sus páginas | Pastos Verdes 3D y zonas de llanura (−6 dB), ciudades (−10 dB) | RMS −29,1 dBFS | Pendiente |
| `audio/ambiente/bosque.wav` (28,0 s) | `16_ambiences/forest_48kHz_16bit_30s_01_s29.wav` | Pixel-boy (Sparklin Labs), «Superpowers assets sound effects»: **CC0**, comprobado | Zonas de bosque (−6 dB) | RMS −30,9 dBFS | Pendiente. **Ojo:** el original venía muy bajo (×35 de ganancia): escuchar si se oye siseo |
| `audio/ambiente/viento.wav` (32,0 s) | `15_nature_weather/wind_48kHz_16bit_60s_02_s20.wav` | Luke.RUSTLTD, «wind1»: **CC0**, comprobado | Mapa del mundo (−14 dB), isla flotante, montaña, nieve y otras zonas (−10 dB) | RMS −38,7 dBFS (en el mapa) | Pendiente |
| `audio/ambiente/mazmorra.wav` (32,0 s) | `16_ambiences/dungeon_loop_48kHz_16bit_94.31s_01_s08.wav` | JaggedStone, «Loopable Dungeon Ambience»: **CC0**, comprobado | La Garganta (−6 dB) | RMS −34,7 dBFS | Pendiente |
| `audio/ambiente/desierto.wav` (32,0 s) | `16_ambiences/desert_48kHz_16bit_35.81s_01_s29.wav` | Pixel-boy, «Superpowers assets sound effects»: **CC0**, comprobado | Zonas de desierto (−8 dB) | RMS −34,1 dBFS | Pendiente |

La comprobación de licencias se hizo en el navegador el 2026-11-08: las cuatro páginas de OpenGameArt dicen
«License(s): CC0». El nombre del autor es el de `LICENSES.txt` de la colección.

## Música (bus Musica)

| Recurso | Origen | Licencia | Dónde suena | Asignación | Señal | Escucha |
|---|---|---|---|---|---|---|
| `musica_combate_normal.mp3` | Sin registrar | **Pendiente** (`licencias_pendientes.txt`) | Combate (`combate.gd`), con sus fundidos y la fase 2 de los jefes | Bus Musica (`prueba_audio`) | RMS −20,2 dBFS | Pendiente |
| Campanas de la cinemática del mirador | Hechas por código (`pastos_verdes_3d.gd`, `campana()`) | Propia | Cinemática del mirador (PV-07) | Bus Musica | Sin medir | Pendiente |
| Canciones de Pastos Verdes (Suno) | ZIP del autor | **No libres**: fuera del proyecto, de las APK y de GitHub | — | — | — | — |

Contextos sin pista con permiso (la carga, el mapa, las zonas): la capa de música queda en **silencio controlado**
(`musica.gd`). La carga da −120 dBFS: silencio de verdad.

## Efectos e interfaz (buses Efectos e Interfaz)

| Recurso | Origen | Licencia | Dónde suena | Bus |
|---|---|---|---|---|
| Tonos de los menús (tic, confirmar, clac) | Hechos por código (`menu_combate.gd`, `sonidos_ui()`) | Propia | Pantalla de carga y menú del combate | Interfaz |
| Muestras de los ajustes (campana, destello, tic, brisa) | Hechas por código (`sonido.gd`) | Propia | Pestaña «Ajustes» | El de cada fila |
| Sonido del cofre | Hecho por código (`pastos_verdes_3d.gd`, `sonido_cofre()`) | Propia | Cofre del árbol mágico | Efectos |
| 7 sonidos de Érebo (`sonidos/erebo_*`) | Sin registrar | **Pendiente** | Invocación de Érebo | Efectos |
| Sonidos al escribir de Dialogic (`typing1-5.wav`) | Complemento Dialogic | MIT (`addons/dialogic/LICENSE`) | Texto de los diálogos | Interfaz |

## Candidatos aún sin usar

- **Colección CC0** (500 archivos, 19 carpetas): pasos en hierba, tierra y piedra, puertas, objetos, golpes, magia y
  criaturas. Cada archivo lleva su fuente (`sNN`) en `LICENSES.txt`; antes de usarlo, comprobar la página como arriba.
- **Sonniss GDC Game Audio Bundle** (2015-2024): «ROYALTY-FREE… personally or commercially without attribution»
  (léeme de cada paquete). Útil para efectos de calidad.
- **«Free Fantasy SFX Pack» de TomMusic:** su léeme no dice la licencia. **No se usa** hasta comprobarla.
