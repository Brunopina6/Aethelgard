# ARQUITECTURA — mapa actual y plan de crecimiento (fases 4 y 6)

Conservador a propósito: aquí se describe cómo separar y ampliar sin romper nada. En código solo se ha hecho lo que se
pudo demostrar seguro con pruebas (ver CAMBIOS.md). Todo lo demás es plan, sin mecánicas nuevas.

## 1. combate.gd hoy (4596 líneas, 180 funciones, `integracion-experimental` @ `2889213`)

| Líneas | Sección | Qué hace | Candidato a módulo |
|---|---|---|---|
| 1-489 | datos y estado | MODELOS, ENEMIGOS, NIVELES_MAGIA, EMBUIR, estado, cola, actor | **Datos** → recursos (`.tres`) o un módulo de datos, con los mismos ids y valores |
| 490-713 | interfaz | HUD, registro, barras, zonas de toque | Presentación |
| 714-1189 | personajes articulados | modelos 2D/3D, poses | Presentación |
| 1190-1602 | bucle ATB, IA, Congelación | turnos, cola, `_turno_enemigo`, patrones | **ATB** (sin tocar reglas) e **IA** |
| 1603-2190 | menús del jugador, Garon | órdenes, objetivo, Esgrima, Embuir, Guardia | Órdenes |
| 2191-2704 | artes | Alba, Escarcha, Lumbre, M4 | Artes (ya hay `artes.gd` para los datos) |
| 2705-3106 | jefes | fases, rendición, decisión | IA de jefes |
| 3107-3739 | animaciones y efectos | | Presentación |
| 3740-4439 | magias (efectos) | | Presentación de magia |
| 4440-4596 | fin y textos | victoria, recompensas, vuelta | **Recompensas** |

**Hecho (10/11):** `combate_formulas.gd` con `dano_fisico` y `dano_magia` (mismo azar). `combate.gd` conserva
`_dano_fisico` y `_dano_magia`. Huella antes y después: `725aef4a…`, 9 de 9 combates.

**Regla para seguir:** un módulo cada vez, sin estado propio al principio (funciones estáticas que reciben lo que
necesitan), con la huella (`prueba_combate_huella`) y los invariantes (`prueba_combate_seguro`) antes y después. Si la
huella cambia, se deshace. Orden propuesto: fórmulas (hecho) → recompensas → IA de enemigos normales → datos.

## 2. Datos independientes (armas, armaduras, magias, habilidades, enemigos)

Hoy viven en constantes de `combate.gd` (ENEMIGOS, NIVELES_MAGIA), `inventario.gd`, `equipo_extra.gd` y `artes.gd`.
Plan: una carpeta `datos/` con un recurso por tipo (`Resource` con `@export`) y un cargador que devuelva los mismos
diccionarios que hoy usa el código, para no cambiar ningún llamador. Se pasa una tabla cada vez con una prueba que
compare la tabla vieja y la nueva campo a campo (si difieren en algo, no se activa).

## 3. Eventos del juego

Hoy cada sistema llama a otros directamente (`progreso.poner_hito`, `Sonido.efecto`, señales de Dialogic). Plan: un
autoload pequeño de señales tipadas (`hito_puesto(id)`, `combate_terminado(resultado)`, `objeto_conseguido(id)`,
`dialogo_terminado(id)`), emitidas **además** de lo que ya hay, y nuevos sistemas que escuchen sin cambiar a los que ya
funcionan. No se ha creado: sin un oyente real sería código sin uso.

## 4. Misiones robustas

Plan: que cada recompensa de misión quede apuntada en la partida con un id (como ya hacen cofres y hallazgos,
`cofres_abiertos`), para que darla dos veces sea imposible, y una prueba que recorra cada misión de Pastos Verdes y
Oakhaven desde cualquier hito comprobando que siempre hay un paso siguiente (sin bloqueos). Ya existe protección
parecida para PV-03/PV-05 (`prueba_orden_pv03`).

## 5. Progresión modular (talleres de Lya, Kael y Garon)

Sin mecánicas nuevas. Contrato propuesto para cuando se aprueben: un recurso `Receta` (id, taller, materiales, coste,
resultado) y un `Taller` con `puede(receta, partida) -> String` (motivo si no) y `aplicar(receta, partida)`, que
guarde lo hecho por id en la partida (formato versionado: `progreso.FORMATO`). Los botines ya existentes (Corteza
espinosa…) serían sus primeros materiales.

## 6. Identificadores y guardados

**Hecho (10/11):** `progreso.FORMATO` (las partidas guardan su versión; las antiguas son la 1 y cargan igual) y
`regiones.gd` (id estable de cada lugar ↔ índice). Falta, cuando haga falta: guardar el id además del índice y migrar.
