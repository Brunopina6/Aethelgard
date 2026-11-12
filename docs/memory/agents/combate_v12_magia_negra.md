# Combate, V12, fase E: escuela de magia negra con profundidad

## 12/11/2026 · rama `claude/v12-fase2-magia` (LOCAL, nace de `claude/rebelum-v12` @ `c703625`)

Encargo del usuario (fase E): escuelas de magia negra (Fuego, Hielo, Rayo, Sombras, Gravedad y Debilitamiento) con
coste, potencia, preparación, efecto, sonido, desbloqueo y afinidades; tabla de debilidades, resistencias e
inmunidades por enemigo (jefes incluidos) con señales en pantalla; estados nuevos; menú legible; desbloqueo por
investigación; sin cambiar lo que tiene hoy cada héroe. Copia `D:\Aethelgard_v12_magia`.

**Estado:** hecho y probado en el PC (aislado, sin ventana; capturas con ventana). **Nadie lo ha jugado a mano, no se
ha probado en el Redmi y hoy no lo tiene ningún héroe**: solo se ve con el interruptor de desarrollo, apagado.

### Commits

| Commit | Qué |
|---|---|
| `d2937f9` | `aethelgard/magia_negra.gd` y `aethelgard/combate_afinidades.gd` (nuevos, con sus `.uid`) |
| `72e38ca` | ganchos «V12, magia negra» de `aethelgard/combate.gd` y el estado «conjuro» de `aethelgard/artes.gd` |
| `e41d53f` | `aethelgard/investigacion.gd`, `aethelgard/datos/catalogo.gd` y seis `datos/investigaciones/arcano_*.tres` |
| `a5f223e` | `combate.gd`: menú en páginas de 4 filas y jaula de la Prisión |
| `454b04b` | `pruebas/prueba_magia_negra.gd`, `pruebas/fotos_magia_negra.gd` y `pruebas/lista_pruebas.txt` |
| el último | este informe |

**Fuera de mi lista de archivos:** `aethelgard/datos/catalogo.gd` (2 cambios): el taller `arcano` en `TALLERES` y que
`validar()` acepte en `desbloquea` los ids `magia:<escuela>:<nivel>` (los comprueba `magia_negra.gd`). Sin ese cambio,
las seis investigaciones nuevas darían error en `prueba_datos`. Lo dejo confirmado para que el coordinador lo revise.

## 1. Lo que no cambia (comprobado en `prueba_magia_negra`, parte U, y en la batería)

- Las 12 magias (`MAGIAS`, `NIVELES_MAGIA`), Esgrima, Embuir, Érebo, la Armonía, el ATB y los dúos: la magia negra va
  por su propia ruta (`_elegir_negra`, `_lanzar_negra`, `_resolver_negra`, `_vfx_negra`).
- Nadie la tiene: `DE_HEROE := {}`. Lya conserva su magia (Cura, Agua, Fuego, Rayo y Lumbre), Garon ninguna (D-037).
- Los ganchos del combate («V12, magia negra») solo actúan si un luchador tiene `f["mn"]` (estados nuevos) o
  `f["conjuro"]`. Sin usarla, las cuentas son las de siempre y la huella C0 (`prueba_combate_huella`) no cambia.
- Ningún archivo nuevo tira del generador aleatorio global (los efectos usan uno local con semilla fija).
- Las afinidades **solo** se aplican a las escuelas nuevas (`APLICAR_A_LAS_DE_SIEMPRE := false`): aplicarlas a las de
  siempre cambiaría el equilibrio y la huella. Es una decisión del usuario.
- Robustez: el color de magia ya no se lee sin protección. `_color_magia()` (MAGIAS → artes → magia negra → blanco)
  sustituye a las cuatro lecturas de la auditoría (`_anim_magia_3d`, `_anim_magia`, `_proyectil`, `_magia_grupal`) y a
  la de `_carga_magia`.

## 2. Hechizos (24)

`prep` = preparación en barras ATB: 0 al momento; 0,35 la barra empieza en 65; 0,7 empieza en 30. Daño como las de
siempre (`combate_formulas.gd`: × la magia del héroe). Umbral = nivel del héroe con el que lo aprende. «Inv.» = además
hace falta completar esa investigación. Color propio por escuela, distinto de los de siempre.

| Escuela (color) | Hechizo | PM | Daño | A quién | Prep | Efecto | Umbral | Inv. | Forma del efecto | Sonido (respaldo hoy) |
|---|---|---|---|---|---|---|---|---|---|---|
| Fuego (`E8572A`) | Ascua | 5 | 40 | uno | 0 | quema 2 | 1 | | brasa con arco | `negra_fuego` (`brasa`) |
| | Llama Voraz | 14 | 95 | uno | 0,35 | quema 2 | 6 | | el fuego se encoge y estalla | `negra_fuego` (`brasa`) |
| | Lluvia de Brasas | 20 | 60 | todos | 0,35 | quema 2 | 10 | | brasas que caen del cielo | `negra_fuego` (`brasa`) |
| | **Sol de Ceniza** | 38 | 150 | todos | 0,7 | quema 3 | 16 | `arcano_sol_ceniza` | un sol nace, cae y deja ceniza | `negra_sol_ceniza` (`brasa`) |
| Hielo (`7FD8FF`) | Aguja Glacial | 5 | 38 | uno | 0 | conserva 20 de barra | 1 | | aguja recta y rápida | `negra_hielo` (`congelar`) |
| | Escarcha Profunda | 12 | 55 | uno | 0 | Lento 2 | 5 | | el suelo se escarcha | `negra_hielo` (`congelar`) |
| | Prisión de Hielo | 16 | 20 | uno | 0,35 | Prisión 1 (pierde su turno) | 9 | | barras de hielo; la jaula se queda | `negra_prision` (`arte_escarcha`) |
| | **Invierno Eterno** | 40 | 135 | todos | 0,7 | Lento 2 | 17 | `arcano_invierno_eterno` | cielo blanco y nevada | `negra_invierno` (`arte_escarcha`) |
| Rayo (`B49CFF`) | Chispa | 4 | 32 | uno | 0 | corta golpes como toda magia | 1 | | arco corto | `negra_rayo` (`golpe_critico`) |
| | Rayo Encadenado | 13 | 60 | uno + 2 saltos (70 % y 50 %) | 0 | salta al más cercano | 6 | | un trazo por salto | `negra_rayo` (`golpe_critico`) |
| | Tormenta del Cielo Roto | 22 | 70 | todos | 0,35 | | 11 | | el cielo se agrieta y caen rayos | `negra_rayo` (`golpe_critico`) |
| | **Juicio del Relámpago** | 36 | 210 | uno | 0,7 | corta siempre un golpe preparado | 15 | `arcano_juicio_relampago` | sello en el cielo y columna de luz | `negra_juicio` (`golpe_critico`) |
| Sombras (`8A63E0`) | Aguja Umbría | 6 | 42 | uno | 0 | atraviesa la guardia | 2 | | aguja oscura (no suma luz) | `negra_sombras` (`arte_ocaso`) |
| | Manto del Eclipse | 15 | 0 | todos | 0,35 | Ataque ↓ 3 (×0,75) | 7 | | un eclipse tapa la luz | `negra_sombras` (`arte_ocaso`) |
| | Marca del Vacío | 12 | 0 | uno | 0 | Marca 3: guarda el 30 % del daño; al acabar pesa; si cae, pesa sobre los demás | 10 | | sello que gira encima | `negra_sombras` (`arte_ocaso`) |
| | **Noche Absoluta** | 42 | 120 | todos | 0,7 | Res. mágica ↓ 2 | 18 | `arcano_noche_absoluta` | se hace de noche: estrellas y coronas | `negra_noche` (`arte_ocaso`) |
| Gravedad (`C8924A`) | Peso del Abismo | 9 | 30 | uno | 0 | Lento 3 | 3 | | anillos que bajan y se cierran | `negra_gravedad` (`arte_ocaso`) |
| | Pozo Gravitatorio | 18 | 50 (+20 % por cada otro enemigo) | todos | 0,35 | | 8 | | remolino hacia un punto | `negra_gravedad` (`arte_ocaso`) |
| | **Colapso Astral** | 40 | 25 % de la vida actual (mín. 40; jefes, tope 10 % de la máxima) | todos | 0,7 | | 15 | `arcano_colapso_astral` | estrellas de los bordes que colapsan | `negra_colapso` (`golpe_critico`) |
| Debilitamiento (`B9C96A`) | Quebranto | 5 | 0 | uno | 0 | Defensa ↓ 3 (golpes ×1,25) | 2 | | sello que baja | `negra_maldicion` (`arte_ocaso`) |
| | Velo Roto | 7 | 0 | uno | 0 | Res. mágica ↓ 3 (magia ×1,25) | 4 | | sello | ídem |
| | Paso Torcido | 10 | 0 | todos | 0 | Lento 2 | 7 | | sello | ídem |
| | Maldición Menguante | 9 | 0 | uno | 0 | Maldición 3 (pierde el 6 % al actuar) | 9 | | sello | ídem |
| | **Herida Elemental** | 14 | 0 | uno | 0,35 | Vulnerable 3 (resiste → normal; normal → débil) | 12 | `arcano_herida_elemental` | sello | ídem |

Comparación con las de siempre: Infierno (34 PM, 140 a todos, al momento) frente a Sol de Ceniza (38 PM, 150 a todos
y quema, pero casi otra barra de preparación que se puede romper). Los grandes cuestan más y se preparan: no las
superan sin riesgo. Las «mejoras posibles» de cada hechizo están en el campo `mejora` de `magia_negra.gd` (sin
implementar). Las descripciones del menú están en `DESCRIPCION`; ninguna dice «borrar» (Naira: «tapa y pesa»).

### Preparación e interrupción

Con `prep`, el héroe paga, queda «conjurando» (círculo en el suelo y reloj de arena junto a su nombre en el HUD) y su
barra empieza más arriba. Al llenarse, el hechizo sale solo, sin menú, a quien siga en pie (si el elegido cayó, al
primero que quede). Si recibe de una vez o en varias el 25 % de sus PV máximos (`UMBRAL_ROTURA`, como
`UMBRAL_INTERRUPCION` de los enemigos) o cae, el conjuro se rompe: pierde los PM, suena la rotura una vez y la barra
sigue. La Armonía sube una vez, al soltarlo. El Alba (Compás, Hora Dorada) lo adelanta, y la Guardia de Garon lo
protege: encaja con «protegerla mientras prepara» de `docs/v12/NAIRA.md`.

### Sonido

Una vez por hechizo, en el primer impacto real (también con varios objetivos y con la cadena); otra al empezar a
preparar y otra si se rompe. Claves que **faltan** en `sonido.gd` (pedir al especialista de sonido): `negra_fuego`,
`negra_hielo`, `negra_rayo`, `negra_sombras`, `negra_gravedad`, `negra_maldicion`, `negra_prision`, `negra_invierno`,
`negra_sol_ceniza`, `negra_juicio`, `negra_colapso`, `negra_noche`, `negra_preparar` y `negra_conjuro_roto`. Hasta
entonces se usan las que existen (`brasa`, `congelar`, `arte_escarcha`, `golpe_critico`, `arte_ocaso`, `embuir`,
`barrera_rota`); `combate.gd` elige sola la nueva en cuanto exista.

## 3. Estados nuevos

En `f["mn"] = {tipo: turnos}` del enemigo; acaban con el combate y **no se guardan**. Se cuentan al empezar su turno.
Volver a ponerlos renueva al mayor, no suma. Se leen sobre su barra de vida («Lento 2», «Def ↓ 3», «Prisión 1»,
«Marca 3»…) y en el panel de objetivos; al aplicarse sale su nombre flotando, con «(resiste)» o «Inmune: …».

| Estado | Efecto | Dónde se lee |
|---|---|---|
| Lento | barra ×0,6 | `_process` |
| Prisión | pierde su próximo turno; corta un golpe preparado de Grimfang, Slime o Gólem | `_turno_enemigo` |
| Defensa ↓ | golpes ×1,25 | `_animar_golpe` |
| Res. mágica ↓ | toda magia ×1,25 (también las de siempre, sobre quien lo lleve) | `_animar_golpe`, `_magia_grupal`, magia negra |
| Ataque ↓ | su golpe ×0,75 (todas las IA, jefes incluidos, por `mult`) | `_turno_enemigo` |
| Marca | guarda el 30 % del daño; al acabar, le pesa; si cae, se reparte entre los demás | `_quitar_pv`, `_turno_enemigo` |
| Maldición | pierde el 6 % de su vida máxima al empezar cada turno | `_turno_enemigo` |
| Vulnerable | resiste → normal; normal → débil (inmune sigue inmune) | `combate_afinidades.gd` |
| (héroe) conjuro | prepara un hechizo | HUD (`artes.gd`), `_siguiente_turno`, `_quitar_pv` |

## 4. Debilidades, resistencias e inmunidades (`combate_afinidades.gd`)

Débil ×1,5 («Débil», dorado) · Resiste ×0,5 («Resiste», gris azulado) · Inmune: 0 y sin estado («Inmune», gris).
Un estado resistido dura la mitad (hacia arriba). Un jefe nuevo sin fila: resiste la lentitud e inmune a la prisión.

| Enemigo | Débil | Resiste | Inmune | Estados que resiste | Estados inmunes |
|---|---|---|---|---|---|
| Slime | Hielo, Rayo | Gravedad | | | |
| Grimfang | Fuego | Sombras | | | |
| Zarzalín | Fuego | Rayo | | | |
| Guardián de piedra | Gravedad | Fuego, Hielo | | Lento | Prisión |
| Gólem de ámbar | Hielo | Fuego | **Rayo** | | |
| Gorthor | Hielo | Fuego | | Lento, Ataque ↓ | Prisión |
| Guardián del Bosque | Fuego | Hielo, Sombras | | Defensa ↓ | Prisión, Lento |
| Coloso de la Falla | Rayo | Fuego, Hielo | **Gravedad** | Lento, Defensa ↓ | Prisión |
| Bramavidrio | Hielo | Fuego, Rayo | | Lento, Ataque ↓ | Prisión |

Los ganchos de cada jefe siguen siendo suyos y se suman: la coraza rúnica del Coloso y la Esencia de enfoque se
aplican también a la magia negra (se les pasa «Negra»); la debilidad al fuego del Guardián del Bosque en su fase 2 la
pone su archivo a las de siempre, y aquí la tiene en las dos fases para las escuelas nuevas. Al elegir objetivo, el
panel dice «Débil: Rayo», «Resiste: Hielo» o «Inmune: Prisión» antes de lanzar. La IA de los jefes respeta las
inmunidades porque el estado no llega a ponerse; la de Bramavidrio, el Coloso y el Guardián no cambia.

## 5. Menú

Seis escuelas no caben como pestañas junto a I · II · III, las artes y el DÚO (432 px). Solución:
- **una sola pestaña «Magia negra»** (icono del eclipse, 64 px), detrás de las de siempre y antes del DÚO;
- dentro, la **lista de escuelas** (una fila por escuela, con su icono, cuántos hechizos sabe «4/4» y una línea);
- cada escuela abre **su página**: sus hechizos en filas (coste a la derecha; «◷» si prepara) y arriba **seis
  pestañas de icono** (6 × 64 + 5 × 4 = 404 px) para pasar de una escuela a otra con el dedo, Q / E o L1 / R1;
  «‹» (Esc, B o atrás) vuelve a la lista;
- **páginas de 4 filas**: la primera captura enseñó que con las pestañas arriba solo caben 4 filas de 64 px y la
  línea de explicación; con 6 escuelas o 5 hechizos, las filas pisaban el bloque del grupo (PV · PM · ATB). Ahora, si
  hay más de 4, salen 3 y una fila «Más ›» (su explicación dice cuáles faltan) o «‹ Antes» en la última. La lista de
  escuelas va en 2 páginas (Fuego, Hielo, Rayo | Sombras, Gravedad, Debilitamiento) y Debilitamiento en 2 (3 + 2);
- si las pestañas de arriba no caben (héroe con I · II · III, dos artes, magia negra y DÚO = 7), se estrechan todas por
  igual (58 px; nunca menos de 56) — **solo** para quien sabe magia negra; los demás, exactamente como hoy;
- quien solo sabe magia negra (Naira) abre directamente la lista de escuelas y, si hay dúo, dos pestañas: «Magia negra»
  y «DÚO».

Capturas: `D:\REBELUM_diagnostico\combate\2026-11-12_magia_negra\` (ver §8).

## 6. Investigación («estudiar hechizos»)

No hay sistema aparte: `investigacion.gd` acepta en el mismo campo `desbloquea` de cada `.tres` los ids
`magia:<escuela>:<nivel>` (`magia_desbloqueada`, `magias_de`, `recetas_que_desbloquea`). Taller nuevo `arcano`. Seis
investigaciones (`arcano_sol_ceniza`, `arcano_invierno_eterno`, `arcano_juicio_relampago`, `arcano_herida_elemental`,
`arcano_noche_absoluta` —pide la anterior— y `arcano_colapso_astral`) piden un material, avanzan un paso por combate
ganado (lo de siempre) y desbloquean el avanzado de su escuela. Están en **borrador**: no salen en ningún taller hasta
que exista el de Naira. Se guarda en la clave `investigaciones` de siempre; lo demás se deduce del nivel y de
`grupo[heroe]["libros"]` (con ids `negra_*`, que no pisan los de las 12). Una partida antigua no sabe nada nuevo y
carga sin errores (probado).

## 7. Cómo se asignará a Naira (no implementado)

1. `grupo.gd`: su entrada en `HEROES` (sin magias de siempre) y en `EN_EL_GRUPO` **detrás de su hito** (auditoría
   §4.4: `datos()` crea a los que faltan).
2. `magia_negra.gd`: `const DE_HEROE := {"Naira": PARA_NAIRA}` (las seis). Umbrales y libros ya funcionan.
3. `combate.gd`: su luchador en `heroes` y su sitio por puesto (auditoría §4.3).
4. Agrupar con los nombres de su propuesta: `GRUPO_NAIRA` ya dice Sombras → Umbra, Gravedad → Gravedad,
   Debilitamiento → Maldición, Fuego/Hielo/Rayo → Astros. Si se aprueba, basta con cambiar `NOMBRE_ESCUELA` o agrupar
   la lista de escuelas por ese campo.
5. Taller `arcano`: un botón en `menus.gd` (líneas 266-269) y su título en `alquimia_menu.gd`; quitar `borrador` de
   las seis investigaciones; que «Desbloquea:» use `MagiaNegra.nombre_desbloqueo()` (hoy enseñaría el id).

Falta además (no pedido esta noche): su «Eclipse» propio, las técnicas combinadas de su propuesta (Contrapeso,
Equinoccio, Vigilia, Doble Fondo), los sonidos `negra_*`, las fichas del Diario de estados y afinidades, libros en
tienda, que la IA de los enemigos prefiera golpear a quien prepara, y estados de magia negra sobre los héroes.

## 8. Pruebas y evidencias

Todo comprobado ejecutando, aislado (`ejecutar_pruebas.ps1`, o `APPDATA`/`LOCALAPPDATA` propios en mi carpeta
temporal), 12/11/2026. La importación aislada vació los directorios de Dialogic de `project.godot`: se restauró con
`git restore` y se reimportó (no se ha confirmado ningún cambio de `project.godot`).

**`prueba_magia_negra`** (nueva, auto, ~11 s): SUPERADA.
- U (sin escena): lo protegido igual; 24 hechizos con todos sus campos, descripción sin «borra» y sonido de respaldo
  que existe; formas propias de los avanzados; afinidades de Slime, Gólem, Coloso, Bramavidrio y Gorthor; prisión
  inmune en los cinco jefes y en uno nuevo; vulnerable; daño ×1,5 / ×0,5 / 0 / ×1,25; Colapso con mínimo y tope;
  Pozo; estados (entra, renueva al mayor, baja un turno por turno, acaba, resiste la mitad, inmune, prisión de un
  turno, maldición 6 %, marca 30 % y su reparto una vez); preparación (barra en 65, icono, rotura al 25 % sumando);
  cadena por cercanía; interruptor solo para Kael; umbrales; aviso al subir; investigación (bloqueada sin material,
  avanza con combates, completa → Sol de Ceniza); libros sin pisar los de siempre; catálogo sin errores; guardar,
  vaciar y cargar con lo mismo; partida antigua sin las claves.
- A (Kael con el interruptor y Lya contra 3 Slimes): 7 pestañas caben (58 px); lista de escuelas en 2 páginas;
  páginas de Rayo y de Debilitamiento (2 páginas); «‹» vuelve; Rayo Encadenado toca a los 3 con un sonido; Lluvia de
  Brasas prepara (estado, sin menú, se suelta sola, área, quema, Armonía +0,15 al soltarla, un sonido de preparar y
  uno de impacto); Sol de Ceniza roto (PM perdidos, sin daño, una rotura); Prisión: el Slime pierde su turno y acaba.
- B (Coloso): Gravedad inmune (ni daño ni Lento), Prisión no entra y el Hielo resiste, Chispa hace daño; panel con
  «Resiste: Hielo», «Inmune: Prisión» y «Débil: Rayo».
- C (Gorthor): Lento resistido (más corto), Manto baja su golpe (×0,75), panel «Inmune: Prisión», no entra.
- D (sin interruptor): ni pestaña ni hechizos.
- E (combate parado): los 24 hechizos uno tras otro llegan al final, golpean a los suyos (o no, si no hacen daño),
  ponen su estado y suenan una vez.

**Batería completa** (con `prueba_magia_negra` dentro), antes de las páginas del menú:
`D:\REBELUM_diagnostico\pruebas\2026-11-12_002227\resumen.md` → **SUPERADAS 121 · FALLIDAS 0 · MANUALES 51 · NO
SEGURAS 0**; partida real y carpeta real sin cambios. Incluye `prueba_combate_huella` (la huella C0 es la misma),
`prueba_combate_seguro`, `prueba_grupos_combate`, `prueba_incorporacion`, `prueba_bramavidrio_combate`,
`prueba_climax_jefe`, `prueba_coloso`, `prueba_artes`, `prueba_artes_combate`, `prueba_m4_c2`, `prueba_hud_combate`,
`prueba_controles_nuevos`, `prueba_datos`, `prueba_investigacion`, `prueba_oficios`…
Tras las páginas: 21 de combate, datos e investigación otra vez, `D:\REBELUM_diagnostico\pruebas\2026-11-12_004417\
resumen.md` → 21 · 0 · 0 · 0. **Batería final** (con todo confirmado, `454b04b`):
`D:\REBELUM_diagnostico\pruebas\2026-11-12_004840\resumen.md` → **SUPERADAS 121 · FALLIDAS 0 · MANUALES 51 · NO
SEGURAS 0**; partida real, carpeta real y proyecto sin cambios.

**Capturas** (`fotos_magia_negra`, con ventana): `D:\REBELUM_diagnostico\combate\2026-11-12_magia_negra\`
- `00_menu`, `01_pestanas_magia` (I · II · III, Alba, Escarcha, Magia negra y DÚO en 432 px), `02_lista_escuelas`,
  `02b_lista_escuelas_pagina2`, `03`-`08_escuela_*` (cada escuela), `08b_escuela_debilitamiento_pagina2`,
  `09_objetivo_debil_hielo` (panel con «Débil: Hielo»), `10_objetivo_resiste_gravedad`, `11_prepara_sol_de_ceniza`
  (círculo e icono), `12_estados_enemigos` («Lento 2 Def ↓ 3», «Marca 3» con su sello, «Prisión 1» con su jaula);
- `e_<escuela>_<n>_<forma>_1..3.jpg`: los 24 efectos en tres momentos.
- Ojo al revisarlas: el combate está parado para la foto, así que el cartel de arriba («¡Rompen el conjuro…!») y las
  vidas sobre los Slimes pueden ir atrasados respecto al efecto. Las capturas 00-12 son de antes del cambio de la
  jaula (aros como elipses); la jaula nueva no se ha vuelto a fotografiar.

## 9. Límites

- No jugado a mano ni en el Redmi: ni tacto real, ni rendimiento de los efectos en el Mali (los grandes usan
  fogonazos, ondas y hasta ~90 partículas, que en el móvil bajan con `calidad`). Los combates de la prueba los guía el
  guion, no la estrategia de un jugador.
- No probado en combate contra Bramavidrio, el Guardián del Bosque ni el Gólem (sí sus filas de la tabla).
- Los estados solo los ponen los héroes; los enemigos no lanzan magia negra.
- Sin sonidos propios (respaldo), sin taller visible, sin Diario y sin libros en tienda (§7).
