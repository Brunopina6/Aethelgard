# CONVERSACIONES_19_11 — Conversaciones que recuerdan decisiones y rumores de Oakhaven (AM-8)

Encargo del 13/11 §12 (AM-8), hecho el 19/11 en `claude/rebelum-v12`. **Todos los textos de este documento son
PROPUESTA [P], sin canon**: están en el juego para poder probarlos, marcados con `"p": true`, y esperan la aprobación del
usuario (aprobar, cambiar o quitar cada uno). Ninguno nombra la niebla, el Sello, Érebo, el tapiz, corazones, recuerdos
ni niños, ni inventa hechos históricos (D-033).

## 1. Qué decisiones guarda de verdad la partida

Comprobado en el código (19/11) y vigilado por `prueba_conversaciones` (si el código deja de escribirlas, falla):

| Clave en `decisiones` | Valores | Dónde se escribe |
|---|---|---|
| `gorthor` | `perdonado` / `muerto` | `combate.gd`, `_perdonar` / `_acabar` → `_apuntar_decision` (Kael decide ante Gorthor de rodillas) |
| `guardian_bosque` | `purificado` / `derrotado` | `combate.gd` → `combate_bosque.gd`, `apuntar` (Elixir en la 2.ª fase o derrota) |
| `hierro_ferro` | `entregado` / `kael` | `ciudades/oakhaven.gd`, señales `oak:hierro_entregar` / `oak:hierro_kael` |
| `pip_oak` | `pagado` | `ciudades/oakhaven.gd`, señal `oak:pip_pagar` (una moneda por el secreto) |

No hay más decisiones guardadas hoy (las de `dialogos/oakhaven/propuesta/` no están en el juego).

## 2. Comentarios de los héroes que dependen de una decisión (9)

**Dónde:** `aethelgard/dialogos/comentarios.gd`, constante `DECISIONES` (mismo formato que los comentarios de siempre).
**Cuándo salen:** en los momentos tranquilos `quieto`, `llegar:oakhaven` y `llegar:lugar_nuevo` (`DECISIONES_EN`), antes
que las frases de siempre; nunca en el cofre ni en la cascada. Con eso salen en la Oakhaven 3D por defecto (al entrar y
quietos 14 s; nuevo enganche en `zonas3d/oakhaven_3d.gd`), en la Oakhaven 2D, en Pastos Verdes 3D (quietos), y al llegar
por primera vez a Ciclópea, al Gran Bosque 3D y a las zonas 2D.
**Una sola vez en la partida:** al decirse se apunta su id como bool en `mazmorras["comentarios_decisiones"]` (sin clave
nueva de partida; una partida antigua vale «sin decir»). No sale otra vez ni en otra sesión ni tras guardar y cargar.
**Quién:** solo si quien habla está en el grupo activo; si no, espera a otra ocasión. La respuesta, solo si está quien
responde. Las llegadas «únicas» no se gastan: si sale un comentario de decisión, la llegada de siempre sale la próxima vez.

| id | Condición | Habla | Texto [P] | Respuesta [P] |
|---|---|---|---|---|
| dec_gorthor_perdonado_kael | `decision:gorthor=perdonado` | Kael | Dejé ir a Gorthor. Supongo que hoy tocaba ser blando. | Garon: Blando, no. Bajar la espada cuesta más. |
| dec_gorthor_perdonado_lya | `decision:gorthor=perdonado` | Lya | Kael… dejaste ir a Gorthor. No era fácil. Lo he apuntado. | — |
| dec_gorthor_muerto_kael | `decision:gorthor=muerto` | Kael | Lo de Gorthor… No me sale ninguna broma. Vamos. | Lya: Kael… no hace falta que la busques. |
| dec_gorthor_muerto_garon | `decision:gorthor=muerto` | Garon | Lo de Gorthor pesa. Se carga. Juntos. | — |
| dec_bosque_purificado_kael | `decision:guardian_bosque=purificado` | Kael | Un árbol me dio las gracias. Sigo sin saber qué contestar. | Lya: «De nada», Kael. Se dice «de nada». |
| dec_bosque_derrotado_lya | `decision:guardian_bosque=derrotado` | Lya | Esos árboles grises… Volveremos con semillas, ¿vale? | Garon: Volveremos. Yo cavo. |
| dec_hierro_kael | `decision:hierro_ferro=kael` | Kael | Desde que Ferro la templó, la espada canta. Yo sigo desafinando. | Garon: A practicar, entonces. Mañana, temprano. |
| dec_hierro_entregado_garon | `decision:hierro_ferro=entregado` | Garon | Rejas nuevas en la muralla. Con vuestro hierro. Bien. | — |
| dec_pip_pagado_kael | `decision:pip_oak=pagado` | Kael | Una moneda a Pip por un secreto. Mi mejor inversión. | Lya: Tu única inversión, Kael. |

Todos ≤ 70 letras y en dos líneas de su caja como mucho (medido con la fuente del juego: 1 o 2 líneas).

### Intención, gesto y espera (para animaciones)

| id | Quién | Intención | Gesto (retrato) | Espera 3D |
|---|---|---|---|---|
| dec_gorthor_perdonado_kael | Kael | Le pesa la duda y la tapa con una broma contra sí mismo | duda | espera_empunadura |
| ↳ respuesta | Garon | Le da la razón sin adornos; es su forma de decir «bien hecho» | — | espera_hombros |
| dec_gorthor_perdonado_lya | Lya | Se lo reconoce a su manera: con un dato y apuntándolo | decidida | espera_cetro |
| dec_gorthor_muerto_kael | Kael | Por una vez deja la broma: tres palabras y a andar | duda | espera_brazalete |
| ↳ respuesta | Lya | Le cuida sin pedirle que lo explique | preocupada | espera_pelo |
| dec_gorthor_muerto_garon | Garon | Un parte militar; el corazón, en la última palabra | — | espera_espalda |
| dec_bosque_purificado_kael | Kael | Asombro que despacha con humor (eco de su frase en `bq_purificado`) | ligero | espera_vigilar |
| ↳ respuesta | Lya | Le corrige la versión con cariño | — | espera_flor |
| dec_bosque_derrotado_lya | Lya | Le duele y propone el siguiente paso (eco de `bq_derrotado`) | decidida | espera_flor |
| ↳ respuesta | Garon | Literal y seco; se pone el primero sin decirlo | — | espera_apoyarse |
| dec_hierro_kael | Kael | Orgullo que se ríe de sí mismo (eco de «Ese filo canta», Ferro) | ligero | espera_empunadura |
| ↳ respuesta | Garon | Una orden que es cariño: le entrenará | — | espera_hombros |
| dec_hierro_entregado_garon | Garon | Soldado de Oakhaven: orgullo por su ciudad, en tres golpes | — | espera_hombros |
| dec_pip_pagado_kael | Kael | Presume en broma de un negocio diminuto | ligero | espera_vigilar |
| ↳ respuesta | Lya | Le pincha la vanidad, con humor suave | — | espera_pelo |

Voces según `docs/narrativa/voces_heroes.md`: Kael, dato y remate («Supongo que…») y, cuando importa, deja la broma;
Lya, «Kael…» cuando se preocupa, «¿vale?», apunta; Garon, telegráfico, plural, el corazón en la última palabra.

## 3. Rumores de Oakhaven con sus rutinas (11)

**Dónde:** `aethelgard/ciudades/oakhaven_vida.gd`, `VOCES`, nueva voz `voz_corrillo` («Unos vecinos»), en el Pórtico del
Concejo (casilla 48, 22). Es una voz sin modelo, como las demás voces sin nombre (la taberna, el vendedor, los niños, el
guardia): **no usa ningún NPC del usuario** ni el mundo vivo apagado. Sale en la Oakhaven 3D por defecto (y en la 2D) con
el sistema de voces que ya había: a menos de 7 m de Kael, una frase cada pocos segundos, sin repetirse en la visita.
**Reutiliza el barrio:** los rumores de siempre son las afirmaciones de `ciudades/oakhaven_barrio.gd` (`AFIRMACIONES`,
todas verdad) con su fuente («de»: caravaneros o guardia, como en `SABER`), y siguen sus reglas: solo caravanas, caminos,
precios y guardia, nada reservado, ≤ 48 letras.
**Rutina:** a la mañana, lo de las caravanas; a la tarde, los peajes; al anochecer, la ronda; el precio del hilo, mañana
y tarde; y lo que se cuenta del grupo, de tarde y al anochecer (después del trabajo), primero que lo demás.

| Condición | Franja | Texto [P] | Base |
|---|---|---|---|
| `decision:gorthor=perdonado` | tarde, anochecer | Al goblin de la Garganta lo dejaron ir, dicen. | decisión |
| `decision:gorthor=muerto` | tarde, anochecer | Ya no hay goblin en la Garganta. Eso dicen. | decisión |
| `decision:guardian_bosque=purificado` | tarde, anochecer | Del bosque de los Pastos traen brotes nuevos. | decisión |
| `decision:guardian_bosque=derrotado` | tarde, anochecer | Ha llegado madera gris de los Pastos. Dura. | decisión |
| `decision:hierro_ferro=entregado` | tarde, anochecer | Ferro vende hierro que canta. Y no es barato. | decisión (y tienda.gd, que ya lo vende) |
| `decision:hierro_ferro=kael` | tarde, anochecer | Dicen que Ferro templa la espada de un chico. | decisión |
| `decision:pip_oak=pagado` | tarde, anochecer | Pip va enseñando una moneda nueva a todos. | decisión |
| siempre | mañana | La caravana del sur llegó tres días tarde. | barrio `caravana_retraso` (caravaneros) |
| siempre | tarde | Han vuelto a subir los peajes del sur. | barrio `peaje_sube` (caravaneros) |
| siempre | mañana, tarde | Ya ni el hilo se puede pagar. Todo sube. | tema «precios» del barrio |
| siempre | anochecer | La guardia dobla la ronda del camino del este. | barrio `ronda_doble` (guardia) |

## 4. Pruebas

- `prueba_conversaciones` (nueva, auto, `3d sin_prologo`): datos (decisiones reales, largos, líneas, gestos, esperas,
  afirmaciones del barrio, vocabulario vetado del barrio más el de los comentarios); cada comentario solo con su
  decisión, nunca con el otro valor ni sin ella, una sola vez (misma sesión, sesión nueva, guardar y cargar), quién
  habla y quién responde, nunca en el cofre, y la llegada de siempre no se gasta; cada rumor solo con su decisión y en su
  franja; y en la Oakhaven 3D por defecto, con Gorthor perdonado: al llegar y quietos salen sus dos comentarios, quedan
  apuntados, el corrillo lo cuenta junto al Pórtico y en una sesión nueva sale la llegada de siempre.
- `prueba_comentarios`: ahora también mira que ENGANCHES nombre la Oakhaven 3D (17 llamadas).
- Pasadas (19/11, aisladas): prueba_conversaciones, prueba_comentarios, prueba_integridad, prueba_ciudad_datos,
  prueba_oakhaven_vida, prueba_oakhaven_posada, prueba_oakhaven_rutinas, prueba_oakhaven3d, prueba_comentarios_3d,
  prueba_barrio_datos y prueba_oakhaven3d_completo: todas SUPERADAS. Resúmenes en `D:\REBELUM_diagnostico\conversaciones_19_11\`.
- Capturas con ventana (perfil alto, 1280 × 720): `D:\REBELUM_diagnostico\conversaciones_19_11\capturas\` (el comentario
  de Kael al llegar, la respuesta de Garon y el rumor del corrillo). Se leen bien; la caja va abajo a la derecha, dentro
  de la pantalla (en las capturas no había botón de acción a la vista; la prueba lo comprueba cuando lo hay).

## 5. Límites y lo que queda

- **Aprobación del usuario** de cada texto [P] (secciones 2 y 3). Hasta entonces no son canon.
- El corrillo es una voz sin figuras (como las demás voces): en el Pórtico no se ve a nadie. Si se enciende el mundo
  vivo (`mundo_vivo_v12`, PD-16), se podrían poner allí dos o tres vecinos chibi; no se ha hecho.
- Un comentario se apunta como dicho al enseñarse: si justo después se abre un diálogo, se quita y no vuelve.
- En la Oakhaven 3D el comentario y los avisos comparten altura: el comentario espera a que no haya aviso y las voces
  callan mientras se ve; otro aviso (una acción) sí puede salir encima unos segundos.
- Nada de esto se ha visto en el Redmi.
