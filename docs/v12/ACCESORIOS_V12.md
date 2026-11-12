# Accesorios y equipamiento V12 — diseño y primera tanda

12/11/2026 · especialista de diseño RPG (accesorios) · rama `claude/v12-accesorios`.
Estado: **primera tanda implementada y APAGADA** (interruptor `accesorios_v12`). El resto, **propuesta** para el
usuario. Nada de aquí es canon: los nombres de lugares y personajes son los que ya tiene el juego o la biblia en
desarrollo, y los «dónde se consigue» son propuestas.

## 1. Qué hay hoy (y qué se reutiliza)

| Pieza | Dónde | Qué hace |
|---|---|---|
| 8 ranuras: arma, escudo, cabeza, cuerpo, pies, **anillo**, **amuleto**, **accesorio** | `inventario.gd` `RANURAS` | El menú Grupo las enseña todas sin desplazar (por eso no se añade una novena) |
| Protecciones con atributos (`bonus`) | `inventario.gd` `PROTECCIONES` | Anillo de fuerza (+3 Fuerza, 180), Anillo de rubí (+4 Magia, 200), Amuleto de vida (+3 Vitalidad, 220), Colgante de luna (+3 Espíritu) |
| Accesorios con efectos de combate | `equipo_extra.gd` `ACCESORIOS` + `EFECTOS` (tipo, tope y gancho) | 13 accesorios de la ranura Accesorio: Farol (35 de barra, 220), Diente (+8 % crítico), Moneda (+25 % monedas, 450), Pluma (12 % esquiva), Cinta de Lumi (5 % PV por turno), Brasa en frasco, corazas al empezar… |
| Disponibilidad por incremento | `HECHOS` y `disponible()` | Lo que no tiene su gancho hecho ni se vende ni se da |
| Tiendas por lugar | `EN_TIENDA` y `en_tienda()` | Farol en Oakhaven, Moneda en Sunken City |
| Atributos y combate | `grupo.gd` `estadisticas()` suma el `bonus` de cualquier objeto puesto; `combate.gd` copia `efectos_de()` en cada héroe | Los efectos solo suman y tienen tope |

**Crecimiento por nivel (para comparar):** 3 puntos de atributo por nivel; además +6 PV y +2 PM. Un punto vale
8 PV (Vitalidad), 3 PM (Espíritu), +1 de daño (Fuerza), +2,5 % de daño mágico (Magia) o −0,5 de daño recibido
(Defensa). Las tiendas cobran unos **60-70 monedas por punto** (anillo de fuerza: 3 puntos, 180). Un Grimfang da 18
monedas y un jefe 120-150.

## 2. Principios

1. **Sin ranuras nuevas.** Anillos → ranura Anillo; amuletos, colgantes y talismanes → Amuleto; brazaletes, broches,
   reliquias, mágicos y los de cada personaje → Accesorio. Una novena ranura obligaría a desplazar la ficha del
   menú Grupo en el móvil (`menus.gd` ya apretó la separación a 3 px para que quepa la octava) y doblaría el poder
   de los accesorios de golpe. Si algún día se quiere, la propuesta es una **segunda ranura Accesorio que se gana**
   (misión de la tallista del Collado), apagada y con su propia prueba de la ficha.
2. **Táctica antes que números.** Cada accesorio nuevo pide una forma de jugar: cubrir, defender para actuar antes,
   rematar, arriesgar con poca vida, curar más a quien tanquea. Los números son pequeños y con tope.
3. **Sin romper la dificultad.** Ningún efecto pasa del 70 % de su tope del catálogo; ningún atributo pasa de un
   nivel (3 puntos); ningún accesorio da ataque ni daño mágico plano; los que dan un efecto fuerte no dan
   atributos. La prueba lo comprueba (`prueba_accesorios_v12`, apartado 1).
4. **Neutros sin el objeto.** Cada gancho devuelve lo mismo y no tira ningún dado si nadie lleva el accesorio: la
   huella del combate no cambia (apartado 4 de la prueba).
5. **Sin Orbes Cristalinos** (economía pendiente) y sin canon nuevo: textos cortos, lugares que ya existen.

## 3. Rarezas

| Rareza | Color | Precio orientativo | Dónde aparecería |
|---|---|---|---|
| Común | `#D9D3C3` (marfil) | 100-180 | Tiendas de siempre |
| Poco común | `#7FD69E` (verde) | 240-320 | Tiendas de ciudades más lejanas, cofres |
| Raro | `#78AEFF` (azul) | 380-450 | Cofres escondidos, encargos, recetas de taller, botín raro |
| Excepcional | `#FFB45A` (ámbar) | sin precio | Solo misiones importantes (una en todo el juego) |

Los objetos de antes de la V12 **no tienen rareza** y se ven como siempre (decidir si se les asigna es del usuario;
propuesta en §8).

## 4. Primera tanda (implementada, APAGADA): 11 objetos

Todos en `equipo_extra.gd` `ACCESORIOS` con `"tanda": "v12"`. Los cuatro ejemplos del usuario están; la Reliquia del
Confino queda en propuesta (§6).

| Objeto | Ranura · categoría | Rareza | Efecto (texto del menú) | Precio | Dónde (PROPUESTA) |
|---|---|---|---|---|---|
| Anillo de cuarzo | Anillo · anillo | Común | +2 Defensa, +1 Velocidad | 150 | Tallista del Collado; mientras no exista, tienda de Oakhaven |
| **Anillo del Alba** | Anillo · anillo | Raro | +2 Espíritu; «-20 % de daño mágico.» | 380 | Cofre del Templo Sumergido de Atlantis |
| **Colgante del Eco** | Amuleto · colgante | Poco común | «+10 % a Agua y a Rayo.» | 300 | Cofre del Valle de los Ecos |
| **Talismán de Ceniza** | Amuleto · talismán | Poco común | +1 Vitalidad; «Corrupción y quema: mitad.» | 240 | Abismo de Ceniza, en las ruinas |
| Colgante de savia | Amuleto · colgante | Poco común | «+15 % a las curas que recibe.» | 280 | Doña Encina (Oakhaven), tras purificar al Guardián del Bosque |
| **Broche del Guardián** | Accesorio · broche | Raro | «Cubriendo, -20 % de daño.» | 420 | Encargo del gremio de Oakhaven con Garon en el grupo |
| Brazalete del centinela | Accesorio · brazalete | Poco común | «Tras Defender, +25 de barra.» | 320 | Tallista del Collado (accesorios de ámbar) |
| Velo de bruma | Accesorio · mágico | Poco común | «Esquiva el primer golpe físico.» | 300 | Tienda de Sunken City |
| Brazal del último muro | Accesorio · brazalete | Raro | «+20 % de daño con poca vida.» | 450 | Botín raro de Gorthor, o premio del gremio |
| Fiador de empuñadura (solo Kael) | Accesorio · personal | Raro | «+20 % a enemigos casi vencidos.» | 400 | Receta de la Forja de Kael |
| Rosario del Loto (solo Lya) | Accesorio · personal | Raro | «+15 % a las Curas que lanza.» | 400 | Receta de la Alquimia de Lya |

Textos de ambiente (≤ 95 letras), en `equipo_extra.gd`. Ejemplos: Anillo del Alba, «Oro pálido con una piedra que
clarea al amanecer. La magia ajena llega más tibia.»; Broche del Guardián, «Un escudo diminuto de la Guardia de la
Muralla. Pesa poco y obliga mucho.» (la Guardia de la Muralla es propuesta de la biblia, como en las Gemelas).

### 4.1 Qué hace cada uno exactamente (y por qué no rompe nada)

- **Anillo de cuarzo** — atributos, sin efecto: −1 de daño por golpe y algo de velocidad. Es la referencia «común»:
  3 puntos por 150, más barato por punto que el anillo de fuerza porque sus atributos son defensivos.
- **Anillo del Alba** — `res_magica` 0,20 (tope 0,40) más +2 Espíritu (6 PM). Reduce los ataques enemigos que el
  juego trata como mágicos. **Ojo:** hoy casi todo el daño enemigo es físico; solo son mágicas las **esporas del
  Guardián del Bosque** (unos 9 por héroe) y el **Aliento de la Putrefacción de Humbaba** (unos 13). Por eso lleva
  también Espíritu: sirve fuera de esos combates. Cuando haya enemigos que lancen magia (§6), se marcan con la misma
  variable y el anillo vale más sin tocarlo.
- **Colgante del Eco** — +10 % al daño de Agua y Rayo (las de siempre, no las artes): lo mismo que el anillo de
  rubí (+4 Magia = +10 %), pero solo dos familias y en otra ranura. Para Lya o un Kael que use Rayo.
- **Talismán de Ceniza** — `res_quemadura` 0,5: la **corrupción** de Humbaba (6 % de los PV máximos durante 3
  turnos) quita la mitad. Los héroes **no se queman** hoy (solo los enemigos): cuando algún enemigo queme, el gancho
  es el mismo (`dano_continuo`). Lleva +1 Vitalidad para no ser un objeto de un solo combate.
- **Colgante de savia** — +15 % a lo que cura la Cura, la Poción (60 → 69) y el Bálsamo de Mirta a quien lo lleva.
  Pensado para el tanque: Garon recibe más de cada curación de Lya.
- **Broche del Guardián** — mientras Garon cubre a un aliado con su Guardia (ya está en guardia: mitad de daño),
  recibe otro 20 % menos. Ejemplo: descarga de Gorthor en furia (72) → Garon 66 − mitad 33 → con broche 26. Gasta
  la ranura Accesorio de Garon (compite con la Brasa, la Lágrima o la Corteza). Solo Garon tiene Guardia: en otro
  héroe no hace nada (su texto empieza por «Cubriendo»).
- **Brazalete del centinela** — tras la orden Defender, la barra empieza en 25 en vez de 0 (con velocidad 22, un
  turno llega 1,1 s antes). Defender deja de «perder el turno». El Farol da 35, pero solo al empezar.
- **Velo de bruma** — el primer golpe físico que va a por él en cada combate no le alcanza («¡Esquiva!», el mismo
  aviso y sonido de la Pluma), sin dado. Frente a la Pluma (12 % cada golpe), es seguro pero una vez: vale contra
  el golpe de apertura de un jefe. No para los ataques a todo el grupo.
- **Brazal del último muro** — +20 % de daño físico con un tercio de sus PV o menos (como Embuir, pero solo en
  apuros). Recompensa arriesgar; no se suma a la defensa.
- **Fiador de empuñadura (Kael)** — +20 % de daño físico a un enemigo por debajo del 30 % de su vida: rematar antes
  de la furia (los enemigos entran en furia por debajo del 30 %).
- **Rosario del Loto (Lya)** — +15 % a sus Curas (Cura I con la Magia inicial: 68 → 78).

Topes del catálogo (`EFECTOS`): `res_magica` 0,40 · `res_quemadura` 0,75 · `guardia_def` 0,40 · `atb_defender` 50 ·
`furia_baja` 0,40 · `remate` 0,40 · `pot_agua`/`pot_rayo`/`pot_cura` 0,30 · `cura_recibida` 0,40 · `velo` sí/no.

## 5. Ganchos en el combate (pequeños y localizados)

| Gancho | Archivo y función | Línea añadida |
|---|---|---|
| Alba y Broche | `combate.gd` `_quitar_pv` (al principio, solo héroes) | `d = Extra.dano_al_heroe(f, d, heroes, dano_magico_entrante)` |
| Ataque mágico enemigo | `combate.gd` variable `dano_magico_entrante` (junto a `golpe_magico`); a `true` mientras se resuelven las esporas del Guardián (`_turno_guardian`) y el Aliento de Humbaba (`combate_humbaba.gd` `_aliento`) | 2 + 2 líneas |
| Talismán | `combate_humbaba.gd` `tic_heroe` (corrupción) | `d = …dano_continuo(h, d)` |
| Brazal y Fiador | `combate.gd` `_animar_golpe`, golpes físicos de héroe, antes del crítico | `dano = Extra.dano_fisico_heroe(origen, objetivo, dano)` |
| Velo | `combate.gd` `_animar_golpe`, la línea de la esquiva | `Extra.velo(objetivo) or Extra.esquiva(…)` |
| Eco | `combate.gd` `_dano_magia` (busca la familia en `NIVELES_MAGIA`) | `Extra.potencia_magia(quien, fam, …)` |
| Rosario | `combate.gd` `_aplicar_cura` | `cantidad = Extra.potencia_magia(quien, "Cura", cantidad)` |
| Savia | `combate.gd` `_lanzar_cura`, `_usar_objeto` (Poción y Bálsamo) | `Extra.cura_recibida(…)` |
| Centinela | `combate.gd` `_defender`, tras `_terminar_turno()` | `quien["atb"] = Extra.atb_al_defender(…)` |

Ninguno reorganiza nada ni toca la cámara, las animaciones o el precalentado. Las funciones están en
`equipo_extra.gd` (al final, «V12, accesorios nuevos»). **No** se han tocado `efectos_de()` ni
`grupo.estadisticas()` (otro especialista añade allí sus bloques).

## 6. Propuestas para después (NO implementadas)

### 6.1 Reliquia del Confino — PROPUESTA sujeta a aprobación narrativa
- **Rareza:** Excepcional. **Ranura:** Accesorio. **Una en todo el juego**, sin precio (no se vende).
- **Idea:** un fragmento de la luz que se negó a ser olvidada (propuesta A de `docs/biblia/rebelum_propuesta.md`),
  ligado a la misión principal del Confino (Acto III). Si el usuario no aprueba la propuesta A, cambia el texto pero
  no el efecto.
- **Efecto propuesto:** inmune a los estados que quitan el control (raíces, agarre, tambaleo) y −10 % de daño mágico.
  Tope de diseño: no da daño ni vida; protege de lo que hace perder turnos, que es lo que más frustra en los jefes.
- **Texto propuesto:** «Un trozo de luz que pesa como un recuerdo. Quien la lleva no se deja atar.»
- **Obtención:** no se implementa; depende de la misión y de la aprobación narrativa.

### 6.2 Tanda 2 (necesita ganchos nuevos, «A2»)
| Idea | Lo que falta en el combate | Tamaño |
|---|---|---|
| Resistencias elementales (Fuego, Agua, Rayo, Hielo) | Los enemigos no lanzan elementos a los héroes: habría que dar elemento a algunos ataques enemigos (`combate_afinidades.gd` ya lo hace al revés) | Medio: decisión de diseño de enemigos |
| Quemaduras en héroes | Ningún enemigo quema; el Talismán ya tiene el gancho (`dano_continuo`) | Pequeño cuando haya un enemigo de fuego |
| Resistencia a estados (raíces, agarre de Humbaba, tambaleo de Bramavidrio) | Un `if` en cada sitio donde se ponen (`combate_humbaba.gd`, `combate_bramavidrio.gd _a_todos`) | Pequeño, pero en archivos de otros especialistas |
| Ahorro de PM (−10 % del coste) | `_gastar_pm` y los menús que enseñan el coste | Medio (menús) |
| Garon: «Placa de la Muralla» (Guardia cuesta 2 PM menos) | `GUARDIA["coste"]` por héroe | Pequeño |
| Naira (PROVISIONAL): «Lente del Eclipse» (+1 turno a sus estados) | `magia_negra.gd` | Pequeño, cuando Naira se apruebe |
| Detalle visual en el personaje (brillo del anillo, broche en el pecho) | Un hueso o punto de anclaje por héroe v2 | Medio; mejor cuando los héroes v2 sean los de siempre |

## 7. Interfaz

- **Tienda:** con el interruptor, encima de los nuevos sale «Prueba V12: accesorios nuevos (apagados en la partida
  normal)». Cada fila lleva un **icono dibujado por código** (`icono_equipo.gd`: aro, colgante, hexágono, banda,
  escudo, orbe o estrella, según la categoría) en el color de su rareza, el nombre en ese color y la nota «Raro ·
  Todos» / «Raro · Solo Kael». El resumen («+2 Espíritu  -20 % de daño mágico.») cabe en la columna de 300 px a
  18 px: la prueba lo mide con la fuente del juego.
- **Menú Grupo:** en la ficha, el icono y el color delante del nombre del objeto puesto (la columna sigue midiendo
  220 px); en Objetos, lo mismo en la lista de equipo.
- Sin texturas nuevas ni modelos: nada que pese en el móvil.

## 8. Decisiones pendientes del usuario
1. Encender la tanda en la partida normal y **dónde se consigue** cada objeto (la columna «Dónde» es propuesta).
2. Si los accesorios de antes reciben rareza (propuesta: Farol, Moneda, Cinta, Gota → poco común; Diente, Pluma,
   Aguja, Amuleto del claro → raro; Brote, Corteza, Lágrima, Fragmento, Brasa → raro; ninguno excepcional).
3. La Reliquia del Confino (§6.1): texto, efecto y misión.
4. Si se quiere que algunos enemigos lancen magia o quemen (da sentido pleno al Anillo del Alba y al Talismán).
5. Una segunda ranura Accesorio ganada (§2.1): no recomendada por ahora.

## 9. Cómo se prueba
- `pruebas/prueba_accesorios_v12.gd` (lista de pruebas, al final): datos, interruptor, equipar y quitar, ganchos
  neutros, dos combates de verdad (grupo 9) con los once objetos, guardar y cargar (también con el interruptor
  apagado), partida antigua, id desconocido y menús.
- Encender a mano: `Engine.set_meta("accesorios_v12", true)` o el argumento `-- accesorios_v12`; cualquier tienda
  vende entonces la tanda.
