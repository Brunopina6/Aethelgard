# Lya · Magia blanca e invocación (V12, piloto del 13/11/2026)

Especificación del usuario: `D:\REBELUM_diagnostico\v12\expansion\encargos_13_11\Aethelgard_Lya_Magia_Blanca.pdf`
(12/11/2026, «diseño propuesto»). Este documento dice cómo se adapta al juego real y qué hay hecho. La magia negra es
de Nix (otra especialista): no se toca.

Código: `aethelgard/combate_acciones_v12.gd` (el mismo módulo que la esgrima de Garon) con enganches de una línea en
`combate.gd`; opción en Ajustes, bloque «Combate». Clips: `personajes/heroes_v2/lya/lya_v2_combate_v12.glb`.
Prueba: `aethelgard/pruebas/prueba_acciones_v12.gd`.

**Interruptor:** `magia_blanca_v12` (APAGADO): `Engine.set_meta("magia_blanca_v12", true)`, `-- magia_blanca_v12` o
Ajustes › Combate › «Magia blanca v12 de Lya: sí» (`[combate] blanca`). Apagado: ni pestaña BLANCA, ni Aurel en
INVOCACIÓN, ni cuenta de turnos de Lya; la huella del combate es la misma.

## 1. Encaje con lo que Lya ya tiene

Lya ya cura (Cura, Bendición, Gracia Divina), regenera (arte Segundo Aliento), revive (Lumbre de Retorno) e invoca a
Érebo con la Armonía llena. El piloto no duplica nada de eso y **reusa sus piezas**, no un sistema paralelo:

| Pieza del juego | La usa |
|---|---|
| Estado «aliento» de las artes (`Artes.dar_aliento`, cura al empezar su turno; se renueva, no se suma) | Manantial Interior |
| «barrera» de las artes (absorbe en `_quitar_pv` antes que los PV) | Custodia del Pulso (con su duración de 3 turnos) |
| Lo que limpia la Cura (`Humbaba.al_curar`: la corrupción) | Restitución Plena |
| `Artes.revivir` + `_revivir_visual` (los de la Lumbre de Retorno) | Aurel |
| La lista INVOCACIÓN (hoy solo Érebo) | Aurel, debajo de Érebo |

**M** (potencia de curación): la misma cuenta que la Cura (`dano × magia_mult + magia_extra`) con base 50 (la Cura I
cura 45). Sin variación aleatoria (la Cura tira ±3; aquí no se gasta azar).

## 2. Conversión de turnos

Igual que en `GARON_ESGRIMA_V12.md`: el combate es ATB por turnos, «turno propio» = cada vez que a ese héroe le toca
(se cuenta al empezar su turno). Diferencias con el documento, por usar lo que existe:

* «Regeneración al fin de sus próximos 3 turnos» → al **empezar** cada uno de sus 3 turnos siguientes (el gancho del
  Segundo Aliento, antes de abrir su menú). Mismo número de curas.
* Barrera «3 turnos» → se apaga al empezar el 3.er turno del protegido después de lanzarla (si no se gastó antes).
* CD 3 de Restitución → apagada durante los 3 turnos siguientes de Lya («Lista dentro de X turnos de Lya»).
* Invocación «una vez por combate» → marca del combate (`c12_aurel_usada`). El «CD global de invocación de 2 turnos»
  no hace falta mientras Aurel sea la única invocación nueva; Érebo sigue con su Armonía, como siempre.

Costes: los del documento. Su referencia de 100 PM al final coincide con el juego (`grupo.gd`: unos 100-120 PM a nivel
50; Lya empieza con ~46). Sin desbloqueo por nivel en el piloto: con pocos PM salen apagadas con su motivo.

## 3. El piloto (básica · estado · culminante, e invocación)

| ID | Nombre | Coste | Efecto en el juego | Clip (perfil) | Efecto visual y sonido |
|---|---|---|---|---|---|
| lya_09 | Manantial Interior (estado) | 14 PM | A un aliado en pie: regenera 0,45 M al empezar cada uno de sus 3 turnos siguientes. Relanzarlo renueva, no suma. | `c12_manantial` 1,8 s (P03): giro lento de muñeca junto al pecho y la abre al aliado | tres brotes verdes que suben; sonido del Aliento |
| lya_15 | Custodia del Pulso (básica de defensa) | 20 PM | A un aliado: barrera de 1,60 M durante 3 turnos suyos; absorbe antes que los PV; no se apila (queda la mayor). | `c12_custodia` 1,8 s (P03): cierra la mano sobre un sello pequeño | seña de guardia y rótulo «Custodia N»; sonido de guardia |
| lya_21 | Restitución Plena (culminante) | 40 PM | A un aliado en pie: toda la vida y le quita la corrupción. No revive. CD 3. | `c12_restitucion` 3,2 s (P07): alza el cetro y traza una línea descendente | pilar de cura y destello cálido sobre él (sin blanco a pantalla completa) |
| lya_24 | Aurel, Faro Peregrino (invocación) | 48 PM | Solo Lya, una vez por combate, en INVOCACIÓN: los caídos vuelven con el 25 % de su vida (fuera de la cola, barra a 0) y los vivos se curan 1,20 M. Sin limpieza ni PM. | `c12_aurel` 3,6 s (P08): planta el cetro y abre el brazo | un faro de piedra con franjas y linterna sobre dos patas de ave, detrás del grupo, 1,9 s (visible ~1,2 s); su haz barre hacia los enemigos; sin modelo, sin luz, sin texturas: dibujo 2D |

**La invocación es pequeña y segura**, por eso está hecha: es un dibujo 2D (dos nodos `_dibujo`, uno aditivo para la
luz), se cura y revive con funciones que ya existen, no se queda en escena y no cambia a Érebo. Lo que sí cambia con
el interruptor: la orden INVOCACIÓN de Lya se abre también cuando Aurel está disponible aunque la Armonía no esté
llena (Érebo sigue apagado con su motivo de siempre). Apagado, la orden y la lista son las de siempre.

## 4. Las 24 acciones: hecho / pendiente y adaptación

Estados: **D** diseñado (PDF) · **G** generado (clip) · **I** integrado · **P** probado en PC · **A** validado en
Android (nada). INV = invocación (solo Lya).

| ID | Acción | Rango | Coste | Estado | Adaptación propuesta al juego real |
|---|---|---|---|---|---|
| lya_01 | Lumbre Serena | I | 4 | D | Es una Cura más barata (0,90 M = 45): la dejaría sin sentido. Reprecio o no añadirla. |
| lya_02 | Agua de Albor | I | 4 | D | Veneno y Quemadura no afectan hoy a los héroes: omitir hasta que existan. |
| lya_03 | Hilo de Regreso | I | 5 | D | «Lento» no existe en los héroes: queda cura 0,55 M; poco valor frente a Cura. |
| lya_04 | Savia, Brote Guardián | I | 10 | D | INV. Barrera 0,75 M al grupo 2 turnos: la barrera con duración de la Custodia, a todos. Cierva vegetal dibujada como Aurel. |
| lya_05 | Velo Límpido | II | 8 | D | Ceguera, Silencio y Confusión no existen en los héroes: omitir. |
| lya_06 | Prisma de Sosiego | II | 9 | D | Cura 1,45 M; la «resistencia a estados» no existe: omitir esa parte. |
| lya_07 | Préstamo del Alba | II | 7 | D | Los enemigos no tienen PM: omitir o darles PM (decisión de diseño). |
| lya_08 | Orien, Pez del Manantial | II | 16 | D | INV. Cura 1,10 M al grupo; Quemadura no afecta a héroes. Cerca de Bendición: diferenciar. |
| lya_09 | Manantial Interior | III | 14 | D G I P | Hecha (arriba). |
| lya_10 | Nudo Deshecho | III | 12 | D | El análogo real son las raíces de Humbaba (pierde el turno): limpiarlas. |
| lya_11 | Arca de Rocío | III | 16 | D | Igual que Bendición (16 PM, 45 al grupo): no añadir tal cual. |
| lya_12 | Eiren, Ave del Umbral Claro | III | 22 | D | INV. Revive a uno con 25-45 %: `Artes.revivir` con la banda; choca con Lumbre de Retorno (decidir). |
| lya_13 | Trasvase Compasivo | IV | 3+X | D | Necesita elegir la cantidad (8-16): una fila por cantidad o un selector. |
| lya_14 | Círculo de Claridad | IV | 22 | D | Limpia un estado por aliado: hoy solo corrupción y raíces de Humbaba. |
| lya_15 | Custodia del Pulso | IV | 20 | D G I P | Hecha (arriba). |
| lya_16 | Thalen, Custodio del Vado | IV | 28 | D | INV. Barrera 0,90 M al grupo + −15 % a los golpes a todos 2 turnos (enganche como la Guardia en Cruz). |
| lya_17 | Bendición de la Aurora | V | 30 | D | Cura 2,40 M + hasta dos estados (corrupción, raíces). |
| lya_18 | Cosecha de Éter | V | 18 | D | Igual que lya_07: los enemigos no tienen PM. |
| lya_19 | Santuario de Seda | V | 28 | D | −10 % de daño recibido al grupo 2 turnos (enganche en `reducir`); la resistencia a estados no existe. |
| lya_20 | Mirea, Tejedora del Alba | V | 36 | D | INV. Cura 1,50 M al grupo + un estado por aliado. |
| lya_21 | Restitución Plena | VI | 40 | D G I P | Hecha (arriba). |
| lya_22 | Voto del Último Latido | VI | 38 | D | Con la «brasa» de las artes (Última Brasa: se levanta una vez) a 1 PV, 2 turnos, no a sí misma, CD 4. |
| lya_23 | Pacto del Cauce | VI | 8 | D | Reserva de 24 PM que persiste en la partida y solo se repone al descansar: toca el guardado (`grupo.gd`, fuera de este encargo). |
| lya_24 | Aurel, Faro Peregrino | VI | 48 | D G I P | Hecha (arriba), en INVOCACIÓN. |

Para ampliar: la pestaña BLANCA con páginas (`_paginar`, 3 por página) o una pestaña por rango; las invocaciones en la
lista INVOCACIÓN (categoría propia, como pide el documento), con el CD global de 2 turnos cuando haya más de una.

## 5. Límites honrados

* **Probado en PC** (`prueba_acciones_v12`, sin ventana, protagonistas de siempre y v2): PM insuficientes, objetivo
  (aliados en pie; Aurel sin objetivo), una sola aplicación y un solo cobro, Manantial que se renueva, Custodia que no
  se apila y se apaga a los 3 turnos, Restitución hasta el máximo con la corrupción fuera y su CD, Aurel una vez,
  solo Lya, levanta al caído, cura 1,20 M como mucho, y INVOCACIÓN que vuelve a cerrarse.
* **No** validado en el Redmi. Coste visual: sprites y polígonos 2D del combate, ninguna luz ni partícula nueva.
* Aurel es un dibujo 2D de piloto, no un modelo: si se aprueba la idea, el espíritu definitivo debería salir de
  Blender con el mismo cuidado que los personajes (y su ficha en `docs/recursos.md`; hoy no usa recursos externos).
