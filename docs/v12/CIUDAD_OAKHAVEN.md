# Ciudad completa de Oakhaven — maqueta, M0: contrato, cargador y pruebas (16/11, EXPERIMENTAL [P])

Lo que hizo M0 (el agente de contrato y cargador del plan §6) sobre el plano aprobado como propuesta
(`docs/v12/CIUDAD_OAKHAVEN_PLAN.md`). Es la BASE para los cuatro agentes de maqueta: cada uno rellena sus sectores en
`aethelgard/zonas3d/ciudad/sectores/<id>/` sin tocar lo compartido. Todo es PROPUESTA [P] salvo lo marcado [C].

- **Solo desde el banco de pruebas de Auditoría**: caso «Ciudad de Oakhaven (maqueta, en pruebas)». APAGADA en todo lo
  demás. No sustituye ni toca Oakhaven 3D, la 2D, el barrio ni las partidas.
- **Maqueta de bloques** de los 8 sectores, recorrible de punta a punta con Kael y el grupo (controles normales), a escala
  de los personajes, con carga por proximidad y maqueta lejana. Sin interiores, sin vecinos, sin misiones.
- **Superficie andable medida** (rejilla de 0,25 m, `prueba_ciudad_plano`): **10 689 m²** (plan: ≈ 10 500-11 500; el barrio,
  1 055). Por sector: Puerta del Sur 866 · Plaza del Tapiz 2 141 · Oficios 1 017 · Terrazas 1 796 · Pasajes 360 ·
  Cuervo 1 348 · Barrio Alto 2 226 · Ribera 935. Desnivel de −2 a 16 m. OJO: son trazados MÍNIMOS (calles y plazas
  anchas); la cifra cambiará cuando los agentes de maqueta pongan casas, patios y callejones (la regla del plan §1 es
  1 000-1 700 m² por sector).

## 1. Archivos

| Archivo | Qué es | De quién |
|---|---|---|
| `zonas3d/ciudad/plano.gd` | El ACUERDO: cajas, cotas y vecinos de los sectores, `CONEXIONES` (borde, ancho y cota), anclas globales, grafo global, cámara, `andable`/`altura`/`sector_de` de toda la ciudad | **Compartido** (M0; cambios, solo el coordinador) |
| `zonas3d/ciudad/trazado_comun.gd` | Funciones comunes de los trazados (formatos del barrio), cajas que se dibujan, regla de visibilidad | **Compartido** |
| `zonas3d/ciudad/blockout.gd` | Geometría del blockout (prismas de suelo, cajas, materiales) | **Compartido** |
| `zonas3d/ciudad/sector.gd` | Script común de las sub-escenas de sector: construye el blockout, los choques y los rótulos; aclara lo ocultable | **Compartido** |
| `zonas3d/ciudad/cargador.gd` | Carga por proximidad y maqueta lejana | **Compartido** |
| `zonas3d/ciudad/ciudad.gd` + `ciudad.tscn` | La escena (extiende `prototipos/vista3d.gd`) | **Compartido** |
| `zonas3d/ciudad/sectores/<id>/trazado.gd` | Lo que hay DENTRO del sector | **Del agente de ese sector** |
| `zonas3d/ciudad/sectores/<id>/sector.tscn` | La sub-escena (`id` = el del sector); más adelante, su modelo horneado | **Del agente de ese sector** |
| `pruebas/prueba_ciudad_plano.gd`, `prueba_ciudad_cargador.gd` | Las pruebas | Compartido |
| `banco_pruebas.gd`, `recursos.gd`, `export_presets.cfg`, `pruebas/prueba_banco_pruebas.gd`, `pruebas/lista_pruebas.txt` | Integración (caso del banco, meta, APAGADOS, presets, recuento) | **Compartidos del proyecto** |

Reparto (plan §6): A → `puerta_sur` y `plaza_tapiz`; B → `oficios` y `ribera`; C → `pasajes` y `cuervo`; D → `terrazas`
y `barrio_alto`. La biblioteca de Blender va en `zonas3d/ciudad/kit/` (aún no existe).

## 2. El plano (`plano.gd`)

Ejes: x al este, z al SUR, y arriba, metros; origen en el centro de la fuente de la Plaza del Tapiz. La ciudad sube hacia
el norte (Puerta del Sur 0, Árbol 16): la cámara, al sur y sin girar, mira cuesta arriba.

| # | id | Sector | Caja x | Caja z | Cotas | Agente |
|---|---|---|---|---|---|---|
| 1 | `puerta_sur` | Puerta del Sur y Caravanas | −30..45 | 62..95 | 0..1 | A |
| 2 | `plaza_tapiz` | Plaza del Tapiz y Gran Mercado | −30..45 | −15..62 | 0..4 | A |
| 3 | `oficios` | Calle de los Oficios (y la Colina del Crematorio, solo por fuera) | 45..105 | −15..55 | 3..10 | B |
| 4 | `terrazas` | Las Terrazas | −100..−30 | −92..−5 | 3..12 | D |
| 5 | `pasajes` | Pasajes Viejos | −100..−30 | 50..95 | 1..2 | C |
| 6 | `cuervo` | Patio del Cuervo | −100..−30 | −5..50 | 2..3 | C |
| 7 | `barrio_alto` | Barrio Alto de las Raíces | −30..60 | −92..−15 | 4..16 | D |
| 8 | `ribera` | La Ribera Baja | 45..110 | 55..95 | −2..3 | B |

Ajustes respecto al plan (M0): en el plan las cajas 1 (−45..45) y 5 (−65..5) se solapaban en z 55..92; ahora la 5 ocupa
entero el suroeste y la 1 queda entre la 5 y la 8, y la Calle Mayor baja dentro de la 2 hasta z 62. La 3 llega a z −15
para tocar a la 7 (Subida de la Colina); la colina (x 60..105, z −92..−15) la dibuja la 3 y no es andable. La cota de la 7
empieza en 4 (la escalinata de la Calle del Árbol sale de la plaza alta) y la 8 llega a 3 (lo alto de la Escalera del
Molino).

**CONEXIONES** (el acuerdo de bordes; cada lado, LLANO a la cota en todo el ancho y al menos 1 m hacia dentro):

| id | Nombre | Sectores | Borde | Tramo | Ancho | Cota |
|---|---|---|---|---|---|---|
| `calle_mayor` | Calle Mayor [C] | 1 ↔ 2 | z = 62 | x −4..4 | 8 | 0 |
| `calle_arbol` | Calle del Árbol [P] | 2 ↔ 7 | z = −15 | x −5..5 | 10 | 4 |
| `calle_cuervo` | Calle del Cuervo [C] | 2 ↔ 6 | x = −30 | z 20..26 | 6 | 2 |
| `calle_mercado` | Calle del Mercado [C] | 2 ↔ 3 | x = 45 | z 20..26 | 6 | 3 |
| `escaleras_terrazas` | Escaleras de las Terrazas [P] | 6 ↔ 4 | z = −5 | x −62..−58 | 4 | 3 |
| `terrazas_altas` | Escaleras de las Terrazas, arriba [P] | 4 ↔ 7 | x = −30 | z −64..−60 | 4 | 12 |
| `paso_botica` | Paso Cubierto de la Botica [P] | 5 ↔ 2 | x = −30 | z 54..57 | 3 (pasaje) | 2 |
| `subida_colina` | Subida de la Colina [C] | 3 ↔ 7 | z = −15 | x 50..54 | 4 | 10 |
| `rampa_carros` | Rampa de los Carros [P] | 1 ↔ 8 | x = 45 | z 76..82 | 6 | 0 |
| `pasaje_velas` | Pasaje de las Velas [P] | 6 ↔ 5 | z = 50 | x −70..−68 | 2 (pasaje) | 2 |
| `arco_pasajes` | Arco de los Pasajes [P] | 5 ↔ 1 | x = −30 | z 80..83 | 3 | 1 |
| `escalera_molino` | Escalera del Molino [P] | 3 ↔ 8 | z = 55 | x 60..63 | 3 | 3 |

Reglas del acuerdo (las comprueba `prueba_ciudad_plano`): cajas sin solapes; cada SUELO dentro de la caja de su sector;
ningún bloque sólido sobre lo andable de otro sector; conexiones a su cota y llanas; sin saltos de más de 0,3 m entre
casillas vecinas de 0,25 m (también dentro de un sector: las escaleras son rampas continuas, ≤ 40 % para que Kael suba; los
niveles distintos se separan con muro, pretil o vacío); todo andable alcanzable desde la Puerta del Sur; Kael visible
desde la cámara (§3).

**Anclas globales** (`ANCLAS`, puntos en el suelo): `inicio` (patio de caravanas), `puerta_sur`, una referencia por sector
(`ref_<id>`: la puerta, la fuente, la forja, el lavadero, el Patio de las Velas, la taberna, el pie del Árbol, la torre) y
los lugares RESERVADOS del plan §3 (sistemas sin implementar): `reserva_rastreadores_caravanas`,
`reserva_rastreadores_almacen`, `reserva_piezas_patio`, `reserva_piezas_taller`, `reserva_feria_plaza`,
`reserva_feria_patio`. `ancla("<sector>/<ancla>")` da las de un trazado. Las entradas previstas de edificios son las
`PUERTAS` de los trazados (`puertas()`: hoy 11).

**Grafo global** (`grafo()`): `s_<sector>` (su referencia) y `c_<conexión>` (centro del borde); topológico (no son
tramos rectos). Dentro de cada sector manda su `GRAFO` local (tramos rectos, como el barrio).

**Cámara**: la del barrio y la muestra (10,8 m sobre el foco, 14,2 m al sur, 25°, campo 38°, sin girar). Diferencia: el
foco sigue la altura ENTERA de Kael (el barrio usa ×0,6: allí solo había 1,4 m de desnivel). Sin zona, el foco es Kael;
las `CAMARA_ZONAS` de los trazados (modos «x», «eje», «libre» del barrio) se mezclan por su peso.

## 3. Contrato de un trazado de sector

El MISMO que `zonas3d/barrio/trazado.gd`, en coordenadas de ciudad, con estas constantes y funciones:

- `ID`, `SUELOS` `[sector, Rect2, eje "" | "x" | "z", cota al principio, cota al final]` (principio = oeste o norte),
  `BLOQUES` `[id, sector, Rect2, base, alto, tipo, sólido]`, `OCULTABLES` (ids), `ANCLAS` (con `referencia`), `PUERTAS`
  (`fuera`, `mira`, `radio`, `texto`, `ancla` del umbral y `nombre`), `GRAFO`, `CAMARA_ZONAS`.
- Funciones: `suelo_en`, `bloque_en`, `andable`, `altura`, `sector_de`, `ancla` (envoltorios de `trazado_comun.gd`).
- Tipos de bloque: `casa` (con tejado), `muro`, `bajo`, `puerta`, `decor`, `terreno`, `arbol`, `cubierta` (lo que pasa
  POR ENCIMA de lo andable: soportales, pasos cubiertos, lonjas, arcos, dinteles) y `copa`.

**Visibilidad de Kael** (la cámara está siempre al SUR): lo que corte el rayo de la cámara a su cabeza (1,5 m) tiene que
ser ocultable: las `cubierta` y `copa` siempre lo son; una casa o muro al sur de lo andable hay que ponerlo en
`OCULTABLES` (la escena lo dibuja aparte y lo aclara, copia medio transparente, mientras tapa; también lo que quede a
menos de 6 m de la cámara: junto a la muralla sur la cámara queda encima de la puerta y sus torres). Los bloques finos (≤ 0,6 m
por los dos lados: pilares, postes) no cuentan. Ningún SUELO más alto puede quedar al sur de Kael. Para que no haga falta
aclarar demasiado: lo alto, al norte de cada calle; en las terrazas, la banda entre dos niveles es `terreno` con la tapa a
la cota de arriba (las casas tienen la fachada en ella). En la maqueta los tejados no tienen vuelo (`VUELO_TEJADO = 0`):
con alero, la fachada de una calle de norte a sur tapaba la franja pegada a ella.

Ejemplo del nivel esperado: `sectores/plaza_tapiz/trazado.gd` (plaza en dos niveles 4/2 con escalinata y pretiles, la
fuente [C] con su pilón, la lonja con seis pilares y su tejado, puestos, el tablón del Gremio [C], el soportal de la Calle
Mayor con su planta encima, la Botica de Selene [C] y el Paso Cubierto bajo una casa, tres puertas previstas, grafo local
de 12 nodos, un riel de cámara en el paso cubierto). Los otros siete son MÍNIMOS: el suelo de sus calles principales a su
cota, sus bordes, algunos bloques de referencia (la Taberna del Cuervo [C], la forja, el Concejo [C], el Árbol Milenario
[C] con su copa a 30-50 m, la Torre de la Campana [C], el crematorio [C] con la puerta SELLADA y sin nada debajo…).

## 4. Cómo trabaja un agente de maqueta

1. Trabaja SOLO en `zonas3d/ciudad/sectores/<id>/` de sus sectores. Lo compartido (§1) no se toca: si hace falta cambiar
   un borde, una cota o una caja, se pide al coordinador (cambia `plano.gd` y avisa a los dos lados).
2. Rellena `trazado.gd`: suelos dentro de su caja, que lleguen a cada borde de sus conexiones a la cota y llanos ≥ 1 m;
   bloques (casas, muros, pretiles, soportales y pasos cubiertos como `cubierta`); `OCULTABLES` para lo que quede al sur
   de lo andable; anclas, puertas previstas, grafo local y, si hace falta, zonas de cámara (lejos de lo andable que no sea
   suyo: una zona que corta una plaza hace saltar el foco).
3. Pasa `prueba_ciudad_plano` (y `prueba_ciudad_cargador` si cambia algo de la escena): dice qué bloque tapa a Kael y dónde,
   qué casillas quedan sueltas, el mayor salto y la superficie de cada sector.
4. Recorre su sector en el banco (1600×720 y 1280×720) con clics y teclas.
5. Commits locales en su rama, nombrando cada archivo.

## 5. El cargador (`cargador.gd`) y los presupuestos

- Distancia en planta de Kael a la CAJA de cada sector: < **40 m** se pide su `sector.tscn` en un hilo
  (`ResourceLoader.load_threaded_request`); < **25 m** se monta; > **60 m** se desmonta y se suelta (histéresis de 35 m).
  El sector de Kael se monta siempre (si su carga no ha terminado, se espera: en las pruebas, la primera entrada y, según
  el hilo, alguna vez más cuando Kael se teletransporta; andando, la precarga llega antes).
- Límite por perfil: **bajo 3** (el actual y los más cercanos), **medio 5**, **alto 8**. Si sobran, quedan el actual y los
  más cercanos; uno montado tiene 5 m de ventaja (no se turnan dos sectores a la misma distancia) y uno cuya carga aún no
  ha terminado no echa a otro (en el bajo se desmontaba un vecino para dejar un hueco que nadie ocupaba).
- **Maqueta lejana**: una malla por sector (sus suelos y sus bloques de ≥ 1,5 m, sin choques ni rótulos), hecha al entrar
  desde los trazados; se ve mientras su sector no está montado. Así se ve siempre la ciudad (el Árbol desde cualquier
  sitio: su copa llega a 50 m).
- Nunca carga interiores: solo pide `sectores/<id>/sector.tscn`. Las puertas previstas dicen «Aún no se puede entrar (en
  obras).»; la Puerta del Sur avisa de que en la maqueta no se sale («Volver al banco»).
- Lo que se pisa y su cota salen del PLANO, no de los choques: Kael anda igual hacia un sector aún sin montar; los choques
  montados (uno por caja sólida y uno por suelo) paran ante lo sólido, sirven al toque en la pantalla y al grupo.
- Presupuesto del plan §5 (bajo ≤ 65 llamadas y ≤ 160 mil primitivas, PSS ≤ 950 MB, sin tirón al entrar en un sector):
  **SIN MEDIR** (encargo de M0: no medir rendimiento). Lo previsible: la maqueta lejana son 8 mallas; cada sector montado,
  una malla de blockout, una por cada ocultable y sus rótulos.

## 6. La escena (`ciudad.gd`)

Extiende `prototipos/vista3d.gd` como el barrio. API de región: `kael`, `cam`, `perfil`, `avisar(texto, efecto, seg)`,
`guardar()` (solo en el banco: su archivo), `guardar_posicion()` (lugar **103**: 0-10 mapa, 99 banco, 100 mapamundi,
101 cueva, 102 barrio), `ocupado()`, `ancla(id)`, `sonda(p)` (provisional: sol 1, cielo 0,7), `iniciar_dialogo(ruta)`,
`volver_al_banco()` y «Guardar y recargar». Kael y el grupo con tocar/clic, arrastrar y teclas; tocar el suelo ignora lo
que esté a más de 1 m sobre lo que se pisa. Luz provisional del barrio en blockout. Fuera del banco vuelve a la carga sin
construir nada.

Integración (apagada por defecto): `banco_pruebas.gd` (`EXPLORAR["ciudad"]`, meta de sesión `ciudad_v12`, que la escena
se pone a sí misma), `recursos.gd` (`APAGADOS`: `res://zonas3d/ciudad/` → `ciudad_v12`: no se precarga), `export_presets.cfg`
(`zonas3d/ciudad/*` fuera de «Android prueba 3D» y «Android experimental»; la estable ya excluye `zonas3d/*`; la de
Auditoría la lleva, como el barrio).

## 7. Pruebas

```
powershell -ExecutionPolicy Bypass -File aethelgard/pruebas/ejecutar_pruebas.ps1 -Solo prueba_ciudad_plano,prueba_ciudad_cargador,prueba_banco_pruebas,prueba_barrio_trazado
```

- `prueba_ciudad_plano` (sin escena, ≈ 5 s): contrato, anclas y puertas, BFS de toda la ciudad, saltos, cada conexión,
  grafos, cámara, visibilidad de Kael cada metro (10 684 casillas de muestra; en 2 436 la escena aclara algo). Imprime
  `SUPERFICIE ANDABLE` y `VISIBILIDAD`.
- `prueba_ciudad_cargador` (con escena, ≈ 1 min): el cargador solo en bajo, medio y alto por una ruta de los 8 sectores
  (límite, sector de Kael siempre montado, nada más allá de 60 m, desmontes solo por distancia o límite, sin fugas de nodos,
  nunca interiores); la histéresis paso a paso; la escena en el banco (las 12 conexiones andadas en los dos sentidos con
  «destino», aclarado, puertas, guardar, vuelta al inicio sin fugas); fuera del banco; APAGADOS y presets.
- `prueba_banco_pruebas`: el banco pasa de 13 a 14 casos.

Comprobación visual (no es medida): 8 capturas de la maqueta a 1600×720 en el PC, perfil alto (inicio, plaza baja con la
casa del sur aclarada, plaza alta, soportal, terrazas, pie del Árbol, forja con «Entrar en la forja» y el rótulo «Forja (en
obras)», paso cubierto): el blockout se dibuja, Kael y el grupo se ven, lo ocultable se aclara. No están en el proyecto.

## 8. Pendiente y dudas

- La luz es la provisional del barrio en blockout: las fachadas claras salen casi blancas en el perfil alto. Es de la
  maqueta; el acabado traerá la suya.
- Medir en el PC por perfil (llamadas, primitivas, ms, memoria, tiempos de carga de sectores) y, cuando se conecte, el
  Redmi (guion propio). Nada medido aún.
- Recorrido con los controles normales a 1600×720 y 1280×720 por una persona (las pruebas andan con «destino», que es lo
  mismo que un toque, pero sin ventana).
- Los nombres nuevos [P] de M0 (Calle del Árbol, Escaleras de las Terrazas, Pasaje de las Velas, Arco de los Pasajes,
  Escalera del Molino, paseo del Concejo, terraza de las Raíces) se suman a las decisiones del plan §8.
- El barrio repartido en la ciudad (plan §4) y los vecinos por sector: fase de maqueta y de vida, no de M0.
