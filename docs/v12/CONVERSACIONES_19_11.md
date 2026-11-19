# CONVERSACIONES_19_11 — Conversaciones que recuerdan decisiones y rumores de Oakhaven (AM-8)

Encargo del 13/11 §12 (AM-8), hecho el 19/11 en `claude/rebelum-v12`. **Todos los textos de este documento son
PROPUESTA [P], sin canon**: están en el juego para poder probarlos, marcados con `"p": true`, y esperan la aprobación del
usuario (aprobar, cambiar o quitar cada uno): **26 textos [P]**, 9 comentarios, sus 6 respuestas y 11 rumores
(sección 6: lo que cambió en la revisión del 19/11). Ninguno nombra la niebla, el Sello, Érebo, el tapiz, corazones, recuerdos
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
quietos 14 s; nuevo enganche en `zonas3d/oakhaven_3d.gd`; la llegada, solo en la calle y tras `pv_02`), en la Oakhaven 2D, en Pastos Verdes 3D (quietos), y al llegar
por primera vez a Ciclópea, al Gran Bosque 3D y a las zonas 2D.
**Una sola vez en la partida:** al decirse se apunta su id como bool en `mazmorras["comentarios_decisiones"]` (sin clave
nueva de partida; una partida antigua vale «sin decir»). No sale otra vez ni en otra sesión ni tras guardar y cargar.
Si su caja se quita antes de haberse leído entera (se abre un diálogo o un panel, cambia la escena), el «ya dicho» se
deshace (`desapuntar`) y vuelve a salir en otro momento tranquilo (revisión 19/11).
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
| dec_hierro_kael | `decision:hierro_ferro=kael` | Kael | Ferro me enseñó a templar. El hierro canta; yo sigo desafinando. | Garon: A practicar, entonces. Mañana, temprano. |
| dec_hierro_entregado_garon | `decision:hierro_ferro=entregado` | Garon | Hierro para la muralla. Bien elegido. | — |
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
| dec_hierro_entregado_garon | Garon | Soldado de Oakhaven: orgullo por su ciudad en dos golpes; aprueba sin adornos | — | espera_hombros |
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
precios y guardia, nada reservado, ≤ 48 letras. **Ojo:** solo se reutilizan los textos y las reglas. Los campos `af`
(afirmación) y `de` (fuente) de cada rumor son metadatos de procedencia que solo lee `prueba_conversaciones`: en el
juego no tienen efecto (oír el rumor no apunta `j_oido_<af>` ni lo que se sabe, oye o cree del barrio, no va al Diario
con su fuente) y la voz no tiene entrada en `RUTINAS`: solo filtra por franja. Integrarlo de verdad queda pendiente
(sección 5).
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
  apuntados, el corrillo lo cuenta junto al Pórtico y en una sesión nueva sale la llegada de siempre. Desde la
  revisión: si un diálogo quita el comentario a los pocos fotogramas, no consta como dicho y vuelve a salir; y la
  llegada no sale con Kael sin haber salido (sin `pv_02`) ni dentro de la posada, y sí en la calle.
- `prueba_comentarios`: ahora también mira que ENGANCHES nombre la Oakhaven 3D (17 llamadas).
- Pasadas (19/11, aisladas): prueba_conversaciones, prueba_comentarios, prueba_integridad, prueba_ciudad_datos,
  prueba_oakhaven_vida, prueba_oakhaven_posada, prueba_oakhaven_rutinas, prueba_oakhaven3d, prueba_comentarios_3d,
  prueba_barrio_datos y prueba_oakhaven3d_completo: todas SUPERADAS. Resúmenes en `D:\REBELUM_diagnostico\conversaciones_19_11\`.
- Revisión (19/11, aisladas): con la prueba nueva y el código de antes, `prueba_conversaciones` FALLA con 4 fallos
  (`D:\REBELUM_diagnostico\conversaciones_19_11_revisionntes6-11-19_202223\`); con el arreglo, esa y otras 12
  (comentarios, comentarios_3d, integridad, oakhaven3d, oakhaven3d_completo, barrio_datos, ciudad_datos, oakhaven_vida,
  oakhaven_posada, oakhaven_rutinas, rincones_pastos y garganta3d_tramo) salen SUPERADAS 13 · FALLIDAS 0
  (`D:\REBELUM_diagnostico\conversaciones_19_11_revision\despues6-11-19_202400\`).
- Capturas con ventana (perfil alto, 1280 × 720): `D:\REBELUM_diagnostico\conversaciones_19_11\capturas\` (el comentario
  de Kael al llegar, la respuesta de Garon y el rumor del corrillo). Se leen bien; la caja va abajo a la derecha, dentro
  de la pantalla (en las capturas no había botón de acción a la vista; la prueba lo comprueba cuando lo hay).

## 5. Límites y lo que queda

- **Aprobación del usuario** de los 26 textos [P] (secciones 2 y 3). Hasta entonces no son canon.
- El corrillo es una voz sin figuras (como las demás voces): en el Pórtico no se ve a nadie. Si se enciende el mundo
  vivo (`mundo_vivo_v12`, PD-16), se podrían poner allí dos o tres vecinos chibi; no se ha hecho.
- Pendiente, si se quiere integrar el corrillo en el barrio: que oír un rumor de afirmación apunte `j_oido_<af>` como
  hacen los diálogos del barrio (`oakhaven_barrio.gd`), y darle a la voz una entrada en `RUTINAS`.
- En la Oakhaven 3D el comentario y los avisos comparten altura: el comentario espera a que no haya aviso y las voces
  callan mientras se ve; otro aviso (una acción) sí puede salir encima unos segundos.
- Nada de esto se ha visto en el Redmi.

## 6. Revisión del 19/11 (CONVERSACIONES_19_11_REVISION)

**Arreglado y probado** (`prueba_conversaciones`, falla antes y pasa después):
- **El comentario que se pierde:** antes, un comentario de decisión quedaba dicho al enseñarse; si un diálogo lo quitaba
  enseguida, no volvía nunca. Ahora la caja apunta «leído» al acabar su tiempo de lectura; si sale de la escena antes,
  `desapuntar` deshace el «ya dicho» (en la sesión y en la partida). Vale para todas las escenas que usan `mostrar`
  (la Oakhaven 2D y 3D, las zonas 2D, Pastos Verdes, Ciclópea y el Gran Bosque 3D). Prueba: Kael empieza «Dejé ir a
  Gorthor…», se abre `npc_aldric` a los 10 fotogramas, no consta como dicho y, quietos, salen los dos de Gorthor.
- **La llegada a la Oakhaven 3D:** ahora se pide solo fuera de la posada y con `cond:kael_salio` (hito `pv_02`). Antes
  salía al empezar a jugar con Kael solo («Oakhaven. Huele a pan…», pensada como alivio de volver) y dentro de la
  posada. **Es un cambio del juego por defecto:** desde AM-8, la Oakhaven 3D enseña también los comentarios de siempre
  (la llegada, ya con estas condiciones, y los de quedarse quieto 14 s en la calle); antes no tenía ninguno.

**Textos cambiados** (siguen siendo [P]):

| id | Antes | Después | Por qué |
|---|---|---|---|
| dec_hierro_kael | Desde que Ferro la templó, la espada canta. Yo sigo desafinando. | Ferro me enseñó a templar. El hierro canta; yo sigo desafinando. | Podía salir 14 s después de elegir, sin tiempo para templar nada; Ferro le enseña en ese mismo diálogo (`oak_ferro_veta`, «Ven, te enseño a templarlo») |
| dec_hierro_entregado_garon | Rejas nuevas en la muralla. Con vuestro hierro. Bien. | Hierro para la muralla. Bien elegido. | Casi repetía la frase de Ferro («Rejas nuevas en la muralla. Con tu hierro.», `oakhaven_vida.gd`) |

**Para que el usuario decida** (no se ha cambiado):
- **Garon responde a Kael dos veces** («Blando, no. Bajar la espada cuesta más.» y «A practicar, entonces. Mañana,
  temprano.»). `voces_heroes.md` dice que Garon «nunca contesta a la broma, la deja caer». La segunda es una orden, como
  pide esa regla. La primera no contesta a una broma, sino a una duda de Kael disfrazada de broma, igual que «No era para
  ti.» en el cofre. Si se quiere la regla estricta, se puede quitar la respuesta o dejar solo «Andando.».
- **«Un árbol me dio las gracias»:** la revisión decía que inventaba un agradecimiento. No es así: en el juego, el
  Guardián purificado les da un brote («Tomad este brote. Que crezca con vosotros.») y Kael dice «Primera vez que un
  árbol me da las gracias.» (`dialogos/bosque/bq_purificado.dtl`, l. 6 y 8). El comentario es un eco de esa frase y se
  conserva. Si el eco parece repetitivo, otra opción [P]: «El Guardián nos dejó un brote. Sigo sin saber qué decirle.»,
  con la respuesta de Lya «“Gracias”, Kael. Se empieza por “gracias”.».
- **La cifra:** el informe de AM-8 decía 20 textos [P]; son 26 (9 + 6 + 11).
