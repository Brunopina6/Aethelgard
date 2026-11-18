# Cencerrante en el combate (V12, 19/11/2026)

**Estado: implementado y APAGADO, pendiente de decisión del usuario y de verlo en el Redmi.** No sale en el juego normal.

La campana de pastor con patas del bestiario (T-097, ficha 01, segunda bestia: «apoyo en un camino abandonado»). El
modelo, los 7 clips (`enemigos/cencerrante/`, `cencerrante_3d.gd`), sus sonidos (`sonido.gd`, tanda 4) y sus dos pruebas
de modelo ya estaban en la V12; faltaba engancharlo al combate. Ficha:
`D:\REBELUM_diagnostico\entradas\2026-11-09_bestiario\REBELUM_Bestiario\Fichas_e_integracion.txt`, líneas 19-23.

## Cómo se enciende

- Interruptor de sesión **`cencerrante_v12`** (`Engine.set_meta("cencerrante_v12", true)` o `-- cencerrante_v12`).
  Apagado por defecto y fuera de la partida guardada.
- Banco de pruebas de Auditoría: caso nuevo **«Cencerrante: toque de alarma y campanada (prueba)»** (`banco_pruebas.gd`,
  clave `cencerrante`, GRUPOS[31], Kael, Lya y Garon). Enciende el interruptor solo en ese caso; al salir se quita.
- Combates de prueba: **GRUPOS[31]** (Cencerrante y un Zarzalín: el refuerzo) y **GRUPOS[32]** (solo: su propia
  campanada). No están en `AL_AZAR_POR_TAMANO` y quedan por encima de `GRUPOS_AL_AZAR`: nunca salen al azar.
- Apagado, `preparar()` no cambia nada: si alguien pide a mano el grupo 31 o 32, el Cencerrante es «agresivo» (los
  patrones de siempre) y sus golpes se ven con la campanada baja. No hay tiradas nuevas.

## Qué hace encendido (`aethelgard/combate_cencerrante.gd`)

Mismo patrón que Zarzalín y Velaria: IA en `turno()`, el daño en `combate.gd _animar_golpe` (su impacto, una vez) y la
presentación en `cencerrante_3d.gd`.

- **toque_de_alarma**, UNA activación por combate (la ficha: «el aviso y el refuerzo deben tener límite de una
  activación»). La campana toma impulso (`cencerrante_aviso_alarma`) y repica (señal `aviso` del modelo a 0,733 s →
  `cencerrante_alarma`). Ningún daño.
  - **Con aliados vivos**: el siguiente golpe del aliado de más ataque va reforzado (×1,3). Se ve «▲ Reforzado» sobre su
    vida hasta que golpea; el refuerzo se gasta en ese golpe (`reforzar()`, al empezar `_animar_golpe`, con el número
    «¡Reforzado!»). El Cencerrante **no** prepara nada para sí.
  - **Solo**: prepara **su propio** ataque («⚠ Cargando», la señal de aviso encima, el cartel dice a quién va) y el
    turno siguiente da la campanada preparada (×1,6). Defender la deja a la mitad, como cualquier golpe; Garon puede
    cubrir. Nadie se refuerza.
- **campanada_baja**: se acerca a saltitos hasta donde la boca de la campana llega al héroe en el impacto (su frente
  medido en el clip de reposo + `alcance()`), suena `cencerrante_aviso_campanada` al empezar el clip y el impacto (daño
  y `cencerrante_campanada`) va UNA vez en el ancla del clip (0,533 s). Vuelve a su sitio.
- Probabilidades: con aliados, su primer turno es el toque (1,0); solo, 0,4 por turno (la del aviso del Zarzalín).

**Cifras PROPUESTAS, sin equilibrar:** PV 70, ataque 10, velocidad 12, exp 18, oro 14; `MULT_REFUERZO` 1,3,
`MULT_PROPIA` 1,6, `PROB_TOQUE_CON_ALIADOS` 1,0, `PROB_TOQUE_SOLO` 0,4. Encuadre (ventana 840 × 560, 2,0 m de alto de
vista mirando a 0,8 m; `caida` 1,3 s) de la propuesta de animaciones, **sin ver en el Redmi**.

## Cambios en archivos

- `aethelgard/combate_cencerrante.gd` (nuevo) y su `.uid`.
- `aethelgard/combate.gd`: precarga del módulo; `MODELOS["cencerrante"]`, `ENEMIGOS["cencerrante"]`, GRUPOS[31] y [32],
  `ANIM["cencerrante"]`; ganchos «V12, Cencerrante» en `_elegir_enemigos` (preparar), `_turno_enemigo` (su IA),
  `_animar_golpe` (refuerzo y animación de la campanada), `_sonidos_bestia` (su señal `aviso` es el repique:
  `cencerrante_alarma`; con el nombre genérico pedía `cencerrante_aviso_toque`, que no existe) y `_actualizar`
  («▲ Reforzado»). Sin la marca del refuerzo y sin el interruptor, nada de esto cambia un combate de siempre.
- `aethelgard/combate_afinidades.gd`: fila NEUTRA (la ficha no trae afinidades).
- `aethelgard/recursos.gd`: su carpeta pasa de «prototipo sin enganchar» (`""`) a depender de `cencerrante_v12`
  (apagado, sigue fuera de la precarga).
- `aethelgard/banco_pruebas.gd`: caso `cencerrante` y su interruptor en `METAS_SESION`.
- Pruebas: `prueba_cencerrante_combate.gd` (nueva, en `lista_pruebas.txt`); `prueba_banco_pruebas.gd` (18 casos, el caso
  del Cencerrante en B y su interruptor en E); `prueba_meshy_e01.gd` (GRUPOS tiene 33 entradas).

El parche a medias de `D:\Aethelgard_combate` (sin commit, +25 líneas en `combate.gd`) se leyó solo como referencia y no
se copió: usaba los índices 11 y 12 de GRUPOS (ya ocupados en la V12), llamaba a un `_turno_cencerrante` que no existía y
no tenía interruptor.

## Pruebas (19/11/2026, `ejecutar_pruebas.ps1 -Solo`, datos aislados)

Primera pasada de la prueba nueva (`2026-11-19_002314`): **FALLIDA** por la propia prueba, no por el juego: en A los
héroes atacaban primero al Cencerrante y caía antes de su segundo turno.

```
FALLO: A: no se vio la campanada baja: { "toque_aliado": 1, "refuerzo_gastado": 1, "campanada": 0, "toque_solo": 0, "preparada": 0, "defendida": 0 }
FALLOS: 1
```

Corregida la prueba (en A los héroes atacan primero al Zarzalín), `2026-11-19_002346`:

```
prueba_cencerrante_combate SUPERADA     6,1 s
OK: U: apagado; A: toque con aliado una vez, refuerzo gastado por el Zarzalín, 3 campanadas; B (semilla 20261119, 1 toque); C: apagado, 2 turnos con la campanada { "toque_aliado": 1, "refuerzo_gastado": 1, "campanada": 3, "toque_solo": 1, "preparada": 1, "defendida": 1 }
FALLOS: 0
```

`2026-11-19_002411`:

```
prueba_cencerrante_modelo SUPERADA     1,8 s
prueba_zarzalin_combate SUPERADA       4 s
prueba_velaria_combate SUPERADA     3,8 s
prueba_meshy_e01     SUPERADA    10,6 s
prueba_banco_pruebas SUPERADA    20,1 s

SUPERADAS 5 · FALLIDAS 0 · MANUALES 1 · NO SEGURAS 0
partida.save real: sin cambios · carpeta real de datos: sin cambios · proyecto: sin cambios · otros Godot: 0
```

(La MANUAL es `prueba_cencerrante_fotos`, con ventana y capturas: no se ejecutó.)

`2026-11-19_002503`:

```
prueba_integridad    SUPERADA     8,6 s
prueba_cargas        SUPERADA     9,2 s
prueba_escalado      SUPERADA     6,6 s
prueba_magia_negra   SUPERADA       8 s
prueba_enemigos_v12  SUPERADA     9,1 s

SUPERADAS 5 · FALLIDAS 0 · MANUALES 0 · NO SEGURAS 0
partida.save real: sin cambios · carpeta real de datos: sin cambios · proyecto: sin cambios · otros Godot: 0
```

Qué comprueba `prueba_cencerrante_combate`: U (apagado: interruptor, `preparar()`, solo sus grupos, nada al azar,
precarga, afinidades, catálogo de sonidos, `reforzar()` ×1,3 una sola vez y sin la marca nada); A (con el Zarzalín: el
toque una vez en todo el combate, sin daño ni impacto, el Zarzalín «▲ Reforzado», el Cencerrante sin preparar nada, el
refuerzo se pone una vez y se gasta en el turno del Zarzalín con un solo impacto, campanadas de un impacto, ganan los
héroes y cae con su derrota; sonidos del toque y del repique una vez, el repique en el fotograma de la señal, cada
campanada con su aviso antes y su impacto una vez en su fotograma); B (solo: el toque prepara su campanada, sin daño y
sin reforzar a nadie; la preparada golpea una vez; defendida, a la mitad o menos; nunca dos toques); C (apagado en su
grupo: nunca toca ni refuerza, sus golpes son la campanada, como mucho uno por turno).

## Lo que queda

- **Decisión del usuario**: las cifras propuestas; si el Cencerrante entra algún día en encuentros normales (dónde, y
  con qué compañeros: hoy solo el Zarzalín en el grupo de prueba); sus afinidades (fila neutra); el botín de la ficha
  («Badajo agrietado», no añadido: no existe el objeto).
- **Redmi**: ver el caso del banco (encuadre 840 × 560, legibilidad del «▲ Reforzado» y del toque, rendimiento con dos
  bestias 3D en pantalla). Sin probar en el móvil.
- `prueba_cencerrante_fotos` (con ventana) no se ejecutó en esta tanda.
