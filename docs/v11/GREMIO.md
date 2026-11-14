# V11 · Gremio de aventureros y reconstrucción de Oakhaven (hito C)

Rama LOCAL `claude/rebelum-v11`. Probado **solo en el PC** (sin ventana y con datos aislados, más capturas con
ventana). Nada se ha probado en el Redmi. Los nombres y los textos son **PROPUESTA** (sin canon).

## Qué hay

### El tablón del gremio (commit `142b72b`)

- **Dónde:** en la plaza de Oakhaven 2D, junto a la fuente, en la casilla (37, 23). Kael se acerca y el botón dice
  «Leer el tablón».
- **La ventana:**
  - rango y reputación, con lo que falta para el siguiente rango;
  - cada contrato con su texto, lo que pide y el premio;
  - un botón: Aceptar, el progreso (2 / 3), Cobrar, Hecho o el rango que falta.
- **Controles:** el dedo, el ratón, y Esc, Atrás de Android o «Cerrar» para salir. Mientras está abierta, Kael no anda;
  al cerrarla se guarda.

### Contratos de tres tipos, no solo matar

| Contrato | Rango | Tipo | Pide | Premio |
|---|---|---|---|---|
| Plaga de limos | Bronce | derrotar | 3 Slimes | 40 monedas, +2 |
| Musgo para la botica | Bronce | entregar | 2 Musgo de piedra | 30 monedas, Poción, +2 |
| Un favor a la botica | Bronce | cumplir | acabar «La fórmula desaparecida» | 20 monedas, +2 |
| Hachas en el camino | Plata | derrotar | 2 Grimfang | 70 monedas, +3 |
| Ojos en la Garganta | Plata | cumplir | ganar en el nido de la Garganta | 110 monedas, Éter, +4 |
| El encargo del maestro | Oro | entregar | 1 Mineral rúnico | 150 monedas, +5 |

- **Rangos:** Bronce (0 de reputación), Plata (6) y Oro (13; era 15 y no se podía alcanzar: ver `docs/v12/OAKHAVEN_JUGABLE_V12.md`). Subir de rango abre contratos nuevos y proyectos.
- **Derrotar:** solo cuentan los enemigos caídos en combates **ganados** después de aceptar el contrato.
- **Entregar:** al cobrar se gasta lo entregado.
- **Cumplir:** usa las condiciones de `encargos.gd`, así que conecta el gremio con los encargos y los combates fijos que
  ya existían.
- **Una sola vez:** cada contrato se cobra una vez.
- **Guardado:** el gremio va en la partida (clave `gremio`). Una partida antigua empieza en Bronce, sin errores.

### Primer proyecto de reconstrucción (commit `fbab55c`)

- **«Los braseros de la plaza»:** pide rango Plata y cuesta 100 monedas y 2 Musgo de piedra.
- Se paga en el tablón, en «Proyectos de la ciudad».
- Desde ese momento, **dos braseros con fuego y luz** arden junto al tablón:
  - aparecen nada más pagarlo y cada vez que se entra en la ciudad;
  - es un cambio que se ve, no solo un aviso.
- Se paga una sola vez y queda en la partida.

## Pruebas

- `prueba_gremio` (nueva) comprueba:
  - los tres tipos de contrato;
  - el cobro una sola vez;
  - Bronce a Plata, que abre contratos;
  - guardar y cargar, y una partida antigua;
  - que un combate de verdad ganado cuenta los limos;
  - la ventana (botones, Aceptar y Atrás) y «Leer el tablón» en la ciudad;
  - el proyecto: rango, coste, una vez, guardado y los dos braseros en la plaza.
- Siguen pasando `prueba_oakhaven`, `prueba_ciudad_datos`, `prueba_oakhaven_rutinas`, `prueba_oakhaven_arte` y
  `prueba_oakhaven_ciudad_arte`, con el tablón en la plaza.
- Capturas en `D:\REBELUM_diagnostico\fase2\2026-11-11_v11_fotos_gremio\fotos3`: la plaza con el tablón y los braseros,
  y la ventana.

## Pendiente

- En el Redmi: leer el tablón con el dedo, desplazar la lista y cobrar.
- **Más proyectos con consecuencias de juego:**
  - un puente o una fundición que abra equipo nuevo;
  - el gremio mejorado (más contratos);
  - una ruta comercial que cambie la tienda.
- **Contratos de rescate, escolta, investigación y desapariciones**, con su historia (pide narrativa).
- El tablón en Oakhaven 3D (hoy solo está en la 2D, que es la de siempre en el móvil).
- Un maestro o maestra del gremio con diálogo, rutina y retrato.

- Batería completa en `fbab55c`: **106 superadas, 0 fallidas, 43 manuales y 0 no seguras** (carpeta `pruebas/2026-11-11_014928` de `D:\REBELUM_diagnostico`).
