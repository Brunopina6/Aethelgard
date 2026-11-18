# Mar de Cristal: el agua del oasis ya no se pisa (19/11, C-2 / PC-14)

Región **EN PRUEBAS** (`modo3d.gd:33`). Pendiente anotado en `docs/v12/INFORME_NOCHE_12_11.md:92` («en la orilla oeste
del oasis se puede pisar el agua») y `docs/memory/agents/graficos_v12_desierto2.md:118` («lo prohibido acaba a 4,6 m»).

## 1. Qué pasaba (medido)

- `trazado.gd` prohibía un círculo de `RADIO_ESTANQUE` = 4,6 m alrededor del oasis (74, 72).
- El agua que se ve es el disco de `terreno.gd` (`RADIO_AGUA` = 6 m, cara de arriba a −0,595 m). Asoma allí donde la
  arena de la malla (triángulos de 1,5 m) queda por debajo.
- Medido en la escena con rayos a la malla de choque, cada 2°, el agua visible llega **de 5,00 a 6,00 m** del centro.
  Llega a 6 m (todo el disco) en la orilla oeste y el suroeste.
- Por eso se podía pisar una franja de agua de 0,4 a 1,4 m **alrededor de todo el estanque**, la más ancha al oeste.
  Andando hacia el centro, Kael se paraba a 4,78 m del centro, con los pies a −0,899 m (30 cm bajo el agua), y el grupo
  se metía detrás.
- Capturas «antes»: `D:\REBELUM_diagnostico\oasis_18_11\antes\` (8 PNG, bajo y alto, más el registro).

## 2. El arreglo

- **`aethelgard/zonas3d/mar_cristal/trazado.gd`**
  - Constantes nuevas: `RADIO_AGUA` 6,0, `NIVEL_AGUA` −0,595, `PASO_MALLA` 1,5 (las mismas que `terreno.gd`; la prueba
    comprueba que coinciden), `PIE` 0,3 y `RUMBOS` 72.
  - `altura_malla(x, z)`: la altura de la arena tal como la dibuja y la choca `terreno.gd` (mismos triángulos).
  - `radio_orilla(o)`: hasta dónde se ve el agua en ese rumbo.
    - La orilla se mide una vez, en 72 tramos de 5°. En cada tramo se miran 5 rumbos y se guarda el más lejano.
    - Cuesta 31,6 ms en el PC, sin ventana. La región la mide al cargar, para no dar un tirón al llegar al agua.
    - Después, cada `prohibido` junto al agua cuesta 0,77 µs.
  - `prohibido` ya no deja pisar el agua visible ni a menos de `PIE` (0,3 m) de ella. Antes era el círculo de 4,6 m;
    ahora la zona prohibida acaba entre 5,55 y 6,3 m, según el rumbo.
  - `RADIO_ESTANQUE` no cambia: lo siguen usando el decorado de la orilla (juncos, palmeras, orilla mojada) y `paisaje.gd`.
- **`aethelgard/zonas3d/mar_cristal_3d.gd`**
  - `_crear_escenario` mide la orilla al cargar.
  - `_colocar_kael`: una partida guardada dentro del agua (era posible antes del arreglo) saca a Kael a la orilla seca
    por el mismo rumbo, en vez de dejarlo bloqueado. Antes de esto, `_vigilar_atasco` lo devolvía siempre al mismo
    punto prohibido.
- **Lo que no cambia:**
  - Ni el aspecto ni el decorado.
  - Los 27 matorrales de `paisaje.gd`, que usa `T.prohibido` para colocarlos, salen igual: 0 de 27 cambian. Lo comprobé
    repitiendo sus candidatos con la misma semilla.
  - Los cristales están a más de 20 m del oasis.
  - Ni los encuentros (`ritmo`) ni el buscador.

## 3. Pruebas

### Aserciones nuevas

En `prueba_mar_cristal`, fase D1 (`orilla` / `orilla2`), medida con la malla de choque y el disco de verdad:

- las constantes de `trazado.gd` son las de `terreno.gd`;
- el punto (68,4, 72), en la orilla oeste, está bajo el agua y no se pisa;
- cada 2°, el agua visible y los puntos a 0,25 m de ella no se pisan;
- la orilla seca, a 0,8 m, sí se pisa (no se cierra el paso alrededor);
- Kael anda hacia el centro desde el oeste, el suroeste y el sur, y se para sobre la arena seca, a menos de 1 m del agua.
  Al este y al norte la hondonada ya era demasiado empinada para bajar; eso no cambia;
- una posición guardada en el agua sale a la orilla seca.

### Reproducción

La regla de antes con las aserciones nuevas, `2026-11-19_003417`: **FALLIDA**, 20 fallos. Extracto literal:

```
FALLO: D1: [bajo] en la orilla oeste se pisa el agua (68.4, 72.0)
FALLO: D1: [bajo] se pisa el agua del oasis (o a menos de 0,25 m) en 360 sitios: ["0° a 5.50 m", "0° a 5.85 m", ...]
FALLO: D1: [bajo] andando desde el oeste hacia el estanque, Kael acaba en el agua ((69.21597, -0.899315, 72.0), a 4.78 m del centro; suelo -0.899, agua -0.595)
FALLO: D1: [bajo] una posición guardada en el agua no se saca a la orilla ((68.5, -0.816401, 72.0))
```

En esa pasada la prueba también comprobaba el este y el norte. Allí salió «suelo nan» porque el rayo arrancaba por
debajo de Kael. Lo corregí, y quité esos dos lados porque Kael no puede bajar por ellos.

### Primer intento del arreglo

Medía la orilla en 72 rumbos sueltos, `2026-11-19_003508`: **FALLIDA**.

```
FALLO: D1: [bajo] se pisa el agua del oasis (o a menos de 0,25 m) en 2 sitios: ["44° a 5.80 m", "54° a 5.85 m"]
```

Entre dos rumbos medidos, la orilla de la malla sobresalía. Ahora cada tramo de 5° guarda lo más lejano de sus 5 rumbos.

### Resultados con el arreglo

Todas las pasadas con `ejecutar_pruebas.ps1 -Solo`, con los datos aislados. En las cuatro: «partida.save real: sin
cambios · carpeta real de datos: sin cambios · proyecto: sin cambios · otros Godot: 0».

| Pasada | Prueba | Resultado |
|---|---|---|
| `2026-11-19_003552` | `prueba_mar_cristal` | SUPERADA, 9,6 s |
| `2026-11-19_003810` | `prueba_cargas` | SUPERADA, 9,3 s |
| `2026-11-19_003810` | `prueba_buscador` | SUPERADA, 1,7 s |
| `2026-11-19_003810` | `prueba_mc_rincon` | SUPERADA, 6,8 s |
| `2026-11-19_003839` | `prueba_desierto_prototipos` | SUPERADA, 1,9 s |
| `2026-11-19_003839` | `prueba_naira_mision` | SUPERADA, 11,1 s |
| `2026-11-19_003839` | `prueba_encuentro_desierto` | SUPERADA, 28,2 s |
| `2026-11-19_003934` | `prueba_zona3d` | SUPERADA, 5,6 s |
| `2026-11-19_003934` | `prueba_integridad` | SUPERADA, 8,5 s |

En `prueba_mar_cristal` (`2026-11-19_003552`):

```
D1: [bajo] el agua del oasis llega de 5.00 a 6.00 m del centro
D1: [alto] el agua del oasis llega de 5.00 a 6.00 m del centro
FALLOS: 0
```

### Capturas (`fotos_mc_oasis`, nueva, con ventana; MANUAL)

- Antes: pasada `2026-11-19_003157`, en `D:\REBELUM_diagnostico\oasis_18_11\antes\`.
- Después: pasada `2026-11-19_003725`, en `D:\REBELUM_diagnostico\oasis_18_11\despues\`.

Dónde se para Kael (literal del registro; igual en bajo y alto):

| Toma | Antes | Después |
|---|---|---|
| 1_oeste / 2_oeste_cerca | `a 4.78 m del centro, suelo -0.899, agua -0.595` | `a 6.30 m del centro, suelo -0.481, agua -0.595` |
| 3_suroeste | `a 4.95 m del centro, suelo -0.844, agua -0.595` | `a 6.46 m del centro, suelo -0.370, agua -0.595` |
| 4_sur | `a 4.79 m del centro, suelo -0.817, agua -0.595` | `a 6.30 m del centro, suelo -0.329, agua -0.595` |

Revisadas `alto_2_oeste_cerca` (antes y después) y `bajo_4_sur` (después).

- Antes, Kael está metido en el agua.
- Después, Kael y el grupo quedan en la arena, en el borde del agua.

## 4. Lo que queda

- **Implementado; falta mirarlo en el Redmi.** Hay que comprobar:
  - que en el teléfono la orilla se siente natural, sin pararse demasiado lejos del agua;
  - que los 31,6 ms de medir la orilla (en el PC) no se notan al cargar la región.
- La región sigue EN PRUEBAS. Para sacarla de pruebas faltan, además, la validación del perfil bajo en el Redmi y lo que
  diga `docs/v12/INVENTARIO_MUNDO.md:147`.
- `docs/v12/INVENTARIO_MUNDO.md:86` todavía dice «Kael pisa el agua en el borde oeste». Lo actualiza quien lleva el
  inventario.
- No decidido, y fuera de este arreglo: al este y al norte, la hondonada es demasiado empinada para bajar al agua. Ya era
  así antes.
