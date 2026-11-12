# Combate V12 · Enemigos y combate: el Centinela del Anillo (Guardián de piedra)

## 12/11/2026, 21:30 · rama LOCAL `claude/v12-enemigos` (`D:\Aethelgard_v12_enemigos`, desde `6c8ad51`)

Sin push ni merge. Nota de partida: la copia `D:\Aethelgard_v12_enemigos` estaba en la rama vieja
`claude/v12-fase2-enemigos` (limpia, ya integrada por copia en `cc3557d`); la cambié a `claude/v12-enemigos`, que es la
que pide el encargo (no se perdió nada: la rama vieja sigue igual).

### 1. Revisión: papel de cada uno y qué les faltaba (observado en el código y en `docs/`, 12/11)

| Enemigo | Dónde sale (combate.gd) | Papel | Clips que había (v1) | Lo que faltaba para estar completo |
|---|---|---|---|---|
| Guardián de piedra, «Centinela del Anillo» | GRUPOS[4] (con Grimfang): **encuentros al azar de Pastos Verdes con el grupo de tres** (`grupo_al_azar(3)` = `randi() % 5`) | **Élite común de la región** (lento, duro, no huye); el que más veces ve el jugador de los tres | reposo, caminar, correr, entrada, ataque, carga, carga_espera, golpe_fuerte, recibir_golpe, victoria, derrota | un segundo ataque diferenciado (todos sus golpes eran el tajo o el golpe devastador «jefe» a todos), aturdido, herida fuerte, algo que contrarrestar con magia; sonido propio (no tenía ninguno: solo la voz «piedra») |
| Gólem de ámbar, «Guardián del Nido» | GRUPOS[6] (con Grimfang): combate fijo del nido de la Garganta (`garganta_nido`, premio fijo Lágrima de ámbar) | **Élite de mazmorra** (minijefe del nido); inmune al Rayo, débil al Hielo (`combate_afinidades.gd`) | los de arriba + aturdido; golpe_fuerte = Pisotón | herida fuerte; un segundo ataque propio (ahora solo tajo y Pisotón «bruto» de PATRONES); identidad sonora (claves «golem_ambar_*» por la señal impacto/evento) |
| Gorthor el Devorador | GRUPOS[5]: jefe de la Garganta (fases, Devorar, último aliento y perdón) | **Jefe** | completos para lo que ya hace: devorar, fase2, rendirse, rendido, arrastrarse, derrota_rendido | herida fuerte; un ataque de fase 2 propio a todos; sonido propio por evento (rugido, trago, rodillas) |

**Elegido: el Guardián de piedra.** Es el único de los tres que sale en encuentros al azar (los otros dos son combates
fijos de una mazmorra y ya tienen mecánicas propias de la V11: Pisotón interrumpible, fases, Devorar, perdón), y era el
que tenía menos identidad: un «jefe» genérico. Sin giros narrativos nuevos: «Centinela del Anillo» es el nombre que ya
le dio animaciones; aquí solo se le da forma de luchar (estatua de templo que despierta, `docs/diseno/ciudades_y_lugares.md`).

**Hallazgo (observado en el código, no lo he cambiado):** en el golpe devastador de los «jefe» (`_turno_enemigo`,
rama `cargando`: el Guardián de siempre y Gorthor) y en el Pisotón del Gólem (`_turno_patron`, `plan["a"] == "todos"`),
el daño a los demás héroes se aplica **después** de que `_animar_golpe` termina (tras la vuelta corriendo, ~0,6-1 s
después del impacto), con un `Sonido.golpe(true)` aparte. El golpe y el número del principal caen en el impacto; los de
los demás, tarde. Arreglo propuesto (cambia la huella C0, por eso no lo toco): pasar los demás al instante del impacto,
como hace `combate_centinela.gd` (`_golpear_resto` dentro del callable del impacto).

### 2. Lo hecho (comprobado ejecutando, aislado, 12/11; commits `ed7c88f`, `f1367e7`, `f766ec6`, `df1e244` y el de este informe)

**Interruptor:** el mismo que ya ponía los modelos propios, `enemigos_v12` (`Engine.set_meta("enemigos_v12", true)` o
`-- enemigos_v12`), APAGADO por defecto y fuera de la partida guardada. Encendido, el Guardián de los encuentros al azar
de Pastos Verdes con tres héroes (GRUPOS[4], con Grimfang: donde ya salía, con la misma probabilidad) usa el modelo v2 y
la personalidad «centinela». Combates de prueba: `-- grupo=18 enemigos_v12` (solo) y `-- grupo=19 enemigos_v12` (con un
Slime), que no salen al azar. **Apagado, el juego queda igual:** `prueba_combate_huella` SUPERADA (las 2 pasadas = la
referencia) y la prueba nueva lo mira en escena (el Guardián de GRUPOS[4] sigue siendo el dibujo 2D con «jefe»).

**Módulo `aethelgard/combate_centinela.gd` (nuevo).** Élite lento y duro; vida, ataque, premios y escalado los de
`ENEMIGOS["guardian"]` (sin tocar fórmulas). Cuatro acciones, cada una con preparación → ejecución → impacto →
recuperación y con su respuesta en lo que ya existe:

| Acción | Aviso / preparación | Efecto | Cómo se contrarresta |
|---|---|---|---|
| Tajo | corre, alza el mandoble sobre el hombro (clip `ataque`, impacto 0,8 s) | a uno ×1,0 (la curandera si ha curado) | Defender |
| Barrido del Anillo | «¡Barrido!» y cartel; tensa el mandoble a su derecha (0-0,6 s, sonido de tensión y chispas del anillo) | a todos ×0,9 en el impacto (0,85 s), con un arco de luz | Defender (a la mitad); nunca dos seguidos |
| Juicio del Anillo | un turno entero de aviso: mandoble y anillo en alto (`carga` → `carga_espera`), «⚠ ¡Juicio!», la señal de aviso de siempre sobre él, marca verde agua sobre el héroe elegido y «⚠ Juicio: Lya» en su estado | turno siguiente: ×2,2 al marcado + lascas ×0,6 a los demás, todo en el impacto (`golpe_fuerte` 0,92 s, onda y lascas) | Defender (mitad), Guardia de Garon (se lo lleva él), **cortarlo**: un cuarto de su vida mientras carga (UMBRAL_INTERRUPCION de la V11) o Quiebra → aturdido, pierde el turno |
| Escudo del Anillo | con < 60 % de vida (como mucho cada 4 turnos suyos): el anillo baja delante del pecho y crece | hasta su turno siguiente, golpes a la mitad (el `defendiendo` de siempre) | **la magia lo rompe** → aturdido, pierde el turno; si nadie lo rompe, su turno siguiente suelta el anillo con un Barrido |

Golpes grandes (≥ 12 % de su vida) ponen la herida fuerte; los demás, la de siempre. Todo el daño a varios héroes cae
en el MISMO instante del impacto (no después de la animación). Nada nuevo se guarda; las marcas se quitan al acabar.

**Ganchos en `combate.gd` (todos «V12, Centinela», 1-4 líneas cada uno):** `const Centinela`; `Centinela.preparar(e)`
dentro del `if` del interruptor de `_elegir_enemigos`; `al_entrar` en `_ready` (sonidos de los instantes de sus clips);
el turno en `_turno_enemigo`; `vigilar` en `_vigilar_carga`; `animar_golpe` en `_animar_golpe`; `al_acabar` en
`_comprobar_fin`; `estados`/`repasar` en `_actualizar`; `info` en `_info_objetivo`; `MODELOS["guardian3d"]["rutas"]`
con el v2 delante del v1; GRUPOS[18] y [19] al final. **Posible choque al integrar:** si otro especialista también añade
grupos tras el 17, hay que renumerar `GRUPO_SOLO`/`GRUPO_CON_SLIME` del módulo.

**Modelo y clips (Blender 5.2.3 por guion):** `enemigos/guardian_piedra/fuente/crear_guardian_piedra.py` con `v2` en la
línea de órdenes escribe `guardian_piedra_v2.glb` + `guardian_piedra_v2_clips.json` al lado del v1 (que no se toca;
sin `v2` el guion hace lo de siempre). Misma malla (5 720 triángulos, 24 huesos, mismas texturas) y los 11 clips de
antes idénticos (la prueba compara los JSON), más: `barrido` 1,8 s (tensión 0,35, impacto 0,85), `guardia` 0,9 (escudo
0,55) + `guardia_espera` 2,0 (bucle), `aturdido` 1,6 (bucle) y `recibir_golpe_fuerte` 1,1. Los bucles del anillo cierran
(36° por vuelta). `guardian_piedra_3d.gd`: carga el v2 si está; `barrido()`, `guardia()`, `fin_guardia()`, `golpe_pesado`.
La derrota con peso es la de antes (rodilla 0,7 s, el anillo se desploma, vuelco a 2,2 s); ahora suena el derrumbe y
levanta polvo en su instante «suelo».

**Sonido (8 WAV mono 48 kHz, importados en QOA, `aethelgard/audio/efectos/centinela/`):** derivados propios de los
paquetes GDC 2018, 2019 y 2020 de Sonniss (#GameAudioGDC, `D:\qtorrent\sound effect`, solo lectura), con el guion
`preparar_centinela.py` (Python estándar + ffmpeg: mono, tono, recorte, capas, fundido, pico a −1 dBFS; copia en
`D:\REBELUM_diagnostico\v12\expansion\enemigos\sonido\`). Filas nuevas al final de `docs/audio/efectos_procedencia.csv`
(fuente, tramo, capas, SHA-256 de la fuente, duración, pico y RMS). **Medido, no escuchado.**

| Clave (sonido.gd, EFECTOS) | Archivo | Cuándo | dur. s · RMS dBFS · db |
|---|---|---|---|
| `guardian_entrada` | entrada | al empezar su entrada (ya lo pedía combate.gd por la clave) | 2,00 · −15,5 · −12 |
| `centinela_tension` | tension | instante «tension» del barrido (0,35 s) | 0,52 · −13,6 · −14 |
| `guardian_barrido` | barrido | impacto del barrido (señal `impacto`, `_sonidos_bestia`) | 0,64 · −15,6 · −10 |
| `centinela_carga` | carga | aviso del Juicio | 1,60 · −13,1 · −14 |
| `guardian_golpe` | juicio | impacto del Juicio (señal `impacto`) | 1,32 · −18,2 · −8 |
| `centinela_escudo` | escudo | instante «escudo» de la guardia (0,55 s) | 0,85 · −26,4 · −2 |
| `centinela_rota` | rota | Juicio cortado o escudo roto | 0,84 · −17,6 · −9 |
| `centinela_derrumbe` | derrumbe | instante «suelo» de la derrota (2,2 s) | 1,80 · −26,9 · −2 |

El golpe en sí sigue sonando con `Sonido.golpe` (una vez) y su voz es la familia «piedra» de siempre. El tajo no tiene
sonido propio (la clave `guardian_ataque` que pide `_sonidos_bestia` no existe a propósito: suena el golpe de siempre).

### 3. Pruebas (aisladas; partida real y carpeta real de datos sin cambios)
- `prueba_centinela_v12` (nueva, auto): **SUPERADA**, `D:\REBELUM_diagnostico\v12\expansion\enemigos\pruebas\2026-11-12_202931\resumen.md`
  (204 s). U: interruptor, grupos, 8 sonidos (QOA mono 48 kHz, con su fila de procedencia), modelo v2. S: apagado = el
  de siempre. A (Kael 3, Lya 2, Garon 1, estrategia de jugador; solo aquí se le triplica la vida para ver más turnos): en
  cada turno suyo, un impacto por golpe, todo el daño en el fotograma del impacto (±1), su sonido propio una vez y en
  ese fotograma (±1), `Sonido.golpe` una vez, el aviso sin daño con marca, señal y sonido, un turno de héroe entre aviso
  y Juicio, el escudo sin daño. B controlado: Juicio 45 / defendido 22 / con Guardia 24; cortado por daño y por Quiebra
  (aturdido, pierde el turno, la rotura suena una vez); escudo ×0,5 y roto por Fuego; tras un escudo sin romper, barrido;
  herida fuerte y ligera. C: Kael y Lya (nivel 5) contra él y un Slime, y Kael solo (nivel 6), automáticos: ganan. D:
  GRUPOS[4] con tres héroes (nivel 6), automático: gana. E: derrota (sin premio) y huida.
  **Q, equilibrio** frente al Guardián de siempre, GRUPOS[4], 6 semillas, solo ataques automáticos (caso pesimista):
  niveles 3/2/1: antes 6/6 victorias y 70 PV perdidos de media, ahora 6/6 y 70; niveles 6/6/6: antes 6/6 y 109, ahora
  6/6 y 89. (La primera versión, con barrido ×0,75 y lascas ×0,4, quitaba la mitad que antes; subí a ×0,9 y ×0,6.)
  Los combates ganados con ataques automáticos no prueban la estrategia de un jugador.
- En la misma pasada: `prueba_combate_huella` **SUPERADA** y `prueba_enemigos_v12` **SUPERADA** (los tres modelos, con el
  v2 cargado; su encuadre propone para el v2 vp 1300×1330 y alto_vista 4,8 porque la punta del barrido sale un poco más:
  no lo he cambiado, en las capturas no se ve cortado).
- `fotos_centinela_v12` (ventana): **MANUAL**, FALLOS 0, `D:\REBELUM_diagnostico\v12\expansion\enemigos\pruebas\2026-11-12_203722\`.
- Batería afectada: apartado 6.

### 4. Evidencias (`D:\REBELUM_diagnostico\v12\expansion\enemigos\`)
- Vídeos (15 fps, media resolución, montados con ffmpeg de los fotogramas del juego): `videos\B_tajo.mp4`, `B_barrido.mp4`,
  `B_juicio_sin.mp4`, `B_juicio_defiende.mp4`, `B_juicio_guardia.mp4`, `B_juicio_cortado.mp4` (por daño y por Quiebra),
  `B_escudo.mp4`, `B_escudo_roto.mp4`, `B_escudo_barrido.mp4`, `B_derrota.mp4` y el combate A entero, `A_inicio.mp4`.
- Hojas de fotogramas: `capturas\hoja_<ataque>.jpg`. Poses de Blender de los clips nuevos: `laminas\guardian_piedra_v2_poses.png`
  (y `laminas\poses\`), lámina `laminas\guardian_piedra_v2_lamina.png`, `.blend` en `laminas\` (fuera de Git).
- En las capturas del B el Guardián sale azulado y «Congelado»: en esa prueba Kael lleva un arma que congela (efecto de
  siempre del combate), no es del módulo.

### 5. Medida (PC, perfil medio, `medir_escenas.ps1 -Escenas combate3 -Ciclos 3`; NO son FPS del Redmi)
Con otros Godot y Blender de otros especialistas trabajando a la vez (apuntado en `medidas\*\procesos.txt`): comparar con
cuidado.

| Pasada | Fotograma media / p95 (ms) | Memoria de vídeo (MB) | Dibujos | Carga del combate (ms, 1.º / 2.º / 3.º) |
|---|---|---|---|---|
| combate de tres de siempre (`siempre`) | 6,15 / 10,42 | 114,7 | 102 | 2 734 / 845 / 773 |
| GRUPOS[4] con el Guardián de siempre (`guardian_antes`, `-Extra grupo=4`) | 5,93 / 8,40 | 116,8 | 100 | 2 100 / 679 / 854 |
| GRUPOS[4] con el Centinela (`centinela`, `-Extra grupo=4,enemigos_v12`) | 5,62 / 8,57 | 129,0 | 104 | 2 474 / 748 / 707 |

El coste está en la ventana 3D del Guardián (1280×1300): +12 MB de memoria de vídeo frente al dibujo 2D. A medir en el
Redmi antes de encenderlo para el usuario.

### 6. Batería afectada (aislada, con todo integrado en la rama)
- `prueba_efectos`, `prueba_grupos_combate`, `prueba_ia`, `prueba_equilibrio`, `prueba_huir`: **5 SUPERADAS**,
  `D:\REBELUM_diagnostico\v12\expansion\enemigos\pruebas\2026-11-12_204223\resumen.md`.
- `prueba_combate_huella`, `prueba_enemigos_v12`, `prueba_centinela_v12`: SUPERADAS (`2026-11-12_202931`).
- No ejecutadas: `prueba_incorporacion` (900 s; con el interruptor apagado sus combates no cambian, la huella lo cubre)
  y las de otras regiones.

### 7. Límites (honesto)
- **Sin Redmi** (desconectado): nada medido en Android; los efectos son 2D y cortos (CPUParticles2D con `calidad`, arcos
  dibujados de 0,3-0,7 s; ningún shader nuevo). La ventana 3D del Guardián (1280×1300) es lo que hay que medir allí.
- Sonido medido (pico y RMS), **no escuchado**. Los volúmenes («db») están puestos por el RMS medido.
- El escudo se lee como un anillo vertical delante de él, hacia los héroes (de canto desde la cámara del combate): se
  entiende con el cartel y el estado, pero conviene que el usuario lo mire en el vídeo `B_escudo.mp4`.
- El Gólem de ámbar y Gorthor no se han tocado (revisados en el apartado 1).
- `prueba_enemigos_v12` y la ventana muestran errores del motor `Parameter "material" is null` (material_storage de
  gles3) al liberar los modelos v12; no hacen fallar nada y salen también en `prueba_enemigos_v12`, que no he cambiado.
  Pendiente de mirar.

### 8. Para integrar (copiando archivos)
NUEVOS: `aethelgard/combate_centinela.gd` (+`.uid`), `aethelgard/enemigos/guardian_piedra/guardian_piedra_v2.glb`
(+`.import`), `aethelgard/enemigos/guardian_piedra/guardian_piedra_v2_clips.json`, `aethelgard/audio/efectos/centinela/`
(8 `.wav` + 8 `.import`), `aethelgard/pruebas/prueba_centinela_v12.gd` y `fotos_centinela_v12.gd` (+ sus `.uid`), este
informe.
COMPARTIDOS modificados: `aethelgard/combate.gd` (ganchos «V12, Centinela»), `aethelgard/sonido.gd` (8 claves nuevas al
final de EFECTOS), `aethelgard/pruebas/lista_pruebas.txt` (2 líneas al final), `docs/audio/efectos_procedencia.csv`
(8 filas al final). Míos modificados: `enemigos/guardian_piedra/guardian_piedra_3d.gd` y `fuente/crear_guardian_piedra.py`.
Pido además en `docs/recursos.md`: «Centinela del Anillo v2 (`enemigos/guardian_piedra/guardian_piedra_v2.glb`) | Obra
propia, Blender 5.2.3 por `fuente/crear_guardian_piedra.py -- <raíz> <láminas> v2` | Propia | Combate con `enemigos_v12` |
Sí» y «Sonidos del Centinela (`audio/efectos/centinela/`) | Derivados de Sonniss GDC 2018-2020 | #GameAudioGDC |
Combate con `enemigos_v12` | Sí (procedencia en efectos_procedencia.csv)».

### 9. Siguiente paso propuesto
1. Que el usuario mire los vídeos y decida si enciende `enemigos_v12`; medir en el Redmi un combate de GRUPOS[4].
2. El Gólem de ámbar con el mismo patrón (herida fuerte, segundo ataque propio, sonido por `evento`).
3. Coordinador: el arreglo del golpe a todos de los «jefe» (apartado 1), que cambia la huella C0.
