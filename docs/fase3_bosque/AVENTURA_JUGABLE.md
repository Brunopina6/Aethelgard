# EL BOSQUE QUE NO RECUERDA — diseño y contrato técnico (fase 3, 10/11/2026)

Aventura de Pastos Verdes 3D tras la misión del corte alfa (empieza con el hito `pv_14`). Rama
`claude/rebelum-bosque-fase3` (`D:\Aethelgard_fase3`), desde `integracion-experimental` @ `5678bfa`.

## Canon (comprobado con la biblia, que es propuesta, y con los textos del juego)

- **La niebla es el olvido que avanza** (biblia, opción A, y la frase de carga «La niebla no perdona a nadie…
  salvo a uno»). El Guardián del Bosque es un espíritu antiguo de raíces que vela el bosque del noreste. Un jirón de
  niebla le ha hecho **olvidar su juramento**, y su olvido se contagia: árboles marcados, animales que no reconocen su
  sendero y vecinos que recuerdan cosas que nunca pasaron.
- **No se menciona a Érebo** ni que guarde recuerdos o corazones (prohibido antes del acto III). Tampoco nada de
  Final Fantasy X.
- **El centinela del mirador** (la estatua) sigue siendo lo que es: los textos no lo cambian. El orbe del altar no se
  usa (sin canon claro).
- **Voces:** las de `docs/narrativa/voces_heroes.md`. Kael, directo; Lya, curiosa y sabia en magia; Garon, parco y
  protector.

## Etapas e hitos (progreso.gd, clave «hitos»; todo se guarda)

| Etapa | Hito | Qué pasa | Objetivo en pantalla |
|---|---|---|---|
| I | `bq_inicio` | Tras `pv_14`, el árbol junto al puesto de Tilo amanece **marcado**: corteza gris y runas pálidas que laten. Tilo (`bq_tilo_1`) jura que ayer hubo tormenta (no la hubo) y pide mirarlo. | «Examina el árbol marcado.» |
| I | `bq_arbol` | Examinar el árbol: Lya nota magia que «borra», y el rastro sigue hacia el norte (`bq_arbol`). Abre la alquimia de Lya (`bq_alquimia`). | «Busca más señales del olvido (0/3).» |
| II | `bq_pista_planta` | Lirios cenicientos junto al río: flores vivas sin color ni olor (`bq_pista_planta`). | contador de pistas |
| II | `bq_pista_rastro` | Surcos de raíces que cruzan el camino hacia las ruinas. Garon aparta unas ramas caídas y abre la **senda oculta** (`bq_senda`). | contador |
| II | `bq_pista_inscripcion` | Inscripción en las ruinas, al final de la senda: «Quien vela no olvida». Lya la lee (`bq_pista_inscripcion`). | contador |
| II | `bq_pistas` | Con las tres, Lya entiende qué pasa (`bq_pistas`). Se abre su investigación «La savia que recuerda». | «Investiga con Lya (Alquimia).» |
| III | — | Recolectar y fabricar el **Elixir de savia purificada** (opcional para vencer). | «Prepara el elixir o ve al claro del noreste.» |
| IV | `bq_guardian_visto` | En el claro del noreste, el Guardián dormido despierta (`bq_guardian`). Combate fijo `pastos_guardian`. | «Enfréntate al Guardián del Bosque.» |
| V | `bq_resuelto` | El resultado se guarda en «decisiones» como `guardian_bosque` = `purificado` o `derrotado`. | «Vuelve a Oakhaven.» |

## Exploración (Pastos Verdes 3D)

**Pistas, recolección y senda:**
- **Tres pistas en sitios distintos:**
  - los lirios, junto al barranco del río;
  - los surcos, en el camino del este tras el puente;
  - la inscripción, en las ruinas a las que lleva la senda.
- **Tres materiales recolectables** (un destello cada uno; cada punto se coge una vez y queda apuntado en
  «cofres_abiertos», `bq_rec_*`):
  - **Hierba lunar:** 4 puntos, cerca del agua;
  - **Musgo de piedra:** 3 puntos, en rocas;
  - **Savia clara:** 2 puntos, en árboles sanos.
- **Senda oculta:** ramas caídas que solo se pueden apartar tras la pista del rastro (Garon), y llevan a las ruinas
  con la inscripción y un punto de savia.

**Interacciones y personajes:**
- **Interacción ambiental útil:** el **manantial** de las ruinas. Beber cura al grupo una vez por visita y llena la
  cantimplora de Lya, que da un ingrediente del elixir.
- **Personaje que evoluciona:** Tilo, con diálogos según la etapa (antes, durante y después, y según el desenlace).
- **Acontecimiento sin combate:** un ciervo de niebla cruza el claro y se desvanece al acercarse, la primera vez que
  se llega a la senda.

**Recompensas y recorrido:**
- **Recompensa por explorar:** un cofre al final de la senda, con una Esencia de enfoque y monedas, una sola vez.
- **Ruta lógica:** árbol marcado (junto a Tilo) → lirios (río) → surcos (este) → senda → ruinas → claro del
  noreste (el Guardián).

## Alquimia de Lya (pantalla «ALQUIMIA»)

**Cuándo aparece:** se abre con `bq_alquimia`, con un botón en Pastos Verdes 3D y en el menú del juego, y Lya en el
grupo.

**Pestañas:** Recetas · Investigar · Materiales.
- Se ve lo que hay y lo que falta.
- Fabricar gasta y da el objeto (todo o nada; `talleres.gd`).
- Botones grandes, para el ratón y para el dedo.

**Datos** en `res://datos/` (fase 2):

| Tipo | id | Clave de inventario | Detalle |
|---|---|---|---|
| material | `hierba_lunar` | «Hierba lunar» | venta 6 |
| material | `musgo_piedra` | «Musgo de piedra» | venta 5 |
| material | `savia_clara` | «Savia clara» | venta 9 |
| receta | `pocion_restauradora` | → «Poción» ×1 | Hierba lunar ×2, sin investigación |
| receta | `esencia_enfoque` | → «Esencia de enfoque» ×1 | Musgo ×1 + Hierba lunar ×1, investigación `lya_enfoque` |
| receta | `elixir_savia` | → «Elixir de savia purificada» ×1 | Savia clara ×1 + Hierba lunar ×1 + Musgo ×1, investigación `lya_savia` |
| investigación | `lya_enfoque` | «Concentración arcana» | requisito Musgo de piedra ×1 (tener); 1 paso, se completa al estudiar |
| investigación | `lya_savia` | «La savia que recuerda» | requisito hito `bq_pistas`; 2 pasos (cada combate ganado avanza 1); además, **ventaja**: la magia de Lya hace ×1,25 al Guardián |

**Objetos con efecto real** (combate.gd, OBJETOS_COMBATE):
- **Poción:** la de siempre, +60 PV.
- **Esencia de enfoque:** la magia del héroe hace ×1,3 durante sus 3 turnos siguientes.
- **Elixir de savia purificada:** sobre el Guardián, en su segunda fase, **lo purifica** (desenlace A). En la primera
  fase no lo gasta: «Aún está demasiado fuerte».

## El Guardián del Bosque Olvidado (combate.gd)

**Ficha:**
- enemigo `guardian_bosque`, grupo fijo propio y combate fijo `pastos_guardian`;
- jefe con `fases`, título y la música de jefe;
- modelo 3D propio (`enemigos/guardian_bosque/`, hecho con Blender y sin recursos de pago) o, mientras tanto, el
  respaldo 2D del guardián teñido de verde.

**Fase 1, «El despertar de las raíces»:**
- Latigazo de raíz (físico, a uno);
- Esporas (magia natural, a todos, flojas);
- **Raíces que aprisionan:** avisa un turno antes con el sistema de patrones (cartel, «Cargando», señal dibujada),
  golpe fuerte; Defender lo reduce a la mitad.

**Fase 2, «El corazón del bosque»** (al 50 %):
- **Coraza de raíces:** el daño físico a la mitad y débil al fuego (×1,5);
- más rápido;
- **Juicio del bosque**, cargado: a todos y fuerte.
- La transición se reconoce: destello verde, tinte, partículas de hojas y el texto «¡El corazón del bosque despierta!».

**Al terminar:**
- **Derrota:** reintento seguro (el combate fijo no cuenta como ganado y el grupo vuelve curado). El Guardián sigue
  ahí.
- **Desenlace A, purificar** (Elixir en la fase 2):
  - `decisiones.guardian_bosque = "purificado"`;
  - recompensa: el accesorio **Brote del Guardián**, regeneración (efecto `regen` existente);
  - el bosque florece: los árboles marcados recuperan el verde y las flores, el claro tiene un manantial nuevo y el
    ciervo vuelve.
- **Desenlace B, derrotar** (vida a 0):
  - `"derrotado"`;
  - recompensa: el material **Corazón de roble** ×1 (venta alta) y el arma de Garon «Raíz de hierro» si existe
    hueco; si no, monedas;
  - el claro queda en silencio: un tocón enorme, las marcas se apagan pero los árboles siguen grises.
- **Persistencia:**
  - «combates_ganados» impide repetir el combate;
  - «decisiones» guarda el desenlace;
  - las recompensas se apuntan en «cofres_abiertos» (`bq_premio_*`) y no se duplican.

## Oakhaven reacciona

- **Doña Encina** (raíces del Árbol), con diálogos según el desenlace: `oak_encina_bosque_purificado` y
  `oak_encina_bosque_derrotado`.
- **Consecuencia funcional:**
  - si se purificó, Encina vende **Hierba lunar** y **Savia clara** (tienda pequeña, completa);
  - si se derrotó, compra el Corazón de roble a buen precio y vende Hierba lunar.

## Diálogos (dialogos/bosque/*.dtl; personajes existentes)

| Diálogo | Cuándo |
|---|---|
| `bq_tilo_1` | arranque de la aventura (Tilo y la tormenta que no hubo) |
| `bq_arbol` | examinar el árbol marcado |
| `bq_pista_planta` | examinar los lirios |
| `bq_pista_rastro` | examinar los surcos |
| `bq_senda` | Garon aparta las ramas |
| `bq_pista_inscripcion` | examinar la inscripción |
| `bq_pistas` | la conclusión de Lya |
| `bq_guardian` | antes del combate |
| `bq_purificado` | tras el desenlace A |
| `bq_derrotado` | tras el desenlace B |
| `bq_tilo_durante` | Tilo durante la aventura |
| `bq_tilo_purificado` | Tilo tras el desenlace A |
| `bq_tilo_derrotado` | Tilo tras el desenlace B |
| `oak_encina_bosque_purificado` | Encina en Oakhaven, desenlace A |
| `oak_encina_bosque_derrotado` | Encina en Oakhaven, desenlace B |

Cada diálogo tiene 2-6 líneas, sin explicaciones técnicas.
