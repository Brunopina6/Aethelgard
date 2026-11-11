# Combate, V12: Bramavidrio y sus tres ataques

## 11/11/2026, 16:40 · rama `claude/v12-bramavidrio-combate` (LOCAL, nace de `claude/v12-bramavidrio` @ `b4157a6`)

Encargo del usuario (11/11): tres ataques de Bramavidrio completamente diferenciados (animación, anticipación y
sensación de peligro propias), con el modelo 3D de animaciones enganchado al combate. Copia
`D:\Aethelgard_v12_bramavidrio_combate`. **Estado: jugable y probado en el PC (aislado, sin ventana y con ventana para
las capturas). Nada probado en el Redmi. Los efectos son un prototipo funcional, no un acabado final.**

### Commits

| Commit | Qué |
|---|---|
| `f8de591` | el modelo de la pasada 2 de animaciones (`claude/v12-bramavidrio` @ `4c5b759`), copiando sus archivos sin fusionar (orden del coordinador) |
| `c10814a` | `combate_bramavidrio.gd` (nuevo) y los ganchos de `combate.gd` |
| `79b3cf1` | `pruebas/prueba_bramavidrio_combate.gd` y sus líneas en `lista_pruebas.txt` (también la de `fotos_bramavidrio_combate`, de animaciones) |
| `3d4f5a1` | efectos revisados con las capturas, vida con dos héroes, la prueba mira `gusano.gd` `vencido()` y cuenta partículas |
| este | este informe |

Sin confirmar a propósito (los genera Godot y no son míos): `enemigos/bramavidrio/bramavidrio_v1.png.import` y
`pruebas/fotos_bramavidrio_combate.gd.uid` (el `.gd` es de animaciones; su rama no lleva el `.uid`).

## 1. Los tres ataques (observado en el código y comprobado ejecutando, 11/11, `3d4f5a1`)

El daño parte de su ataque (34) y de la furia de siempre (×1,5 por debajo del 30 %). Todos pasan por `_quitar_pv`:
la defensa del héroe, Defender, la Guardia de Garon (`_cubre`), las corazas (Escarcha, Barrera Rúnica) y la Brasa
funcionan como con cualquier enemigo.

| | Embestida del Abismo | Fractura del Mar de Cristal | Aliento del Desierto Eterno |
|---|---|---|---|
| Tipo | básico, a uno, ×1,35 | sísmico, a todos, ×1,2 | gran ataque, a todos, ×1,9 |
| Aviso | ninguno de turno: la anticipación va en el clip (se retrae y fija, 0,55 s; muerde a 1,0 s). Anillo rojo y «⚠» sobre el héroe fijado; el cartel lo nombra | un turno: se alza (20 m) y ruge; cartel grande «⚠ Fractura del Mar de Cristal / Defendeos: a la mitad y sin tambalearos», «⚠ Fractura: defendeos» sobre su vida, la señal de aviso, grietas rojas que laten bajo los héroes y el fondo que se apaga | un turno largo: abre las fauces y aspira; arena que gira hacia su boca, la garganta se enciende, cartel «⚠ Aliento del Desierto Eterno / Defendeos, o quitadle N PV más para cortarlo» (N baja con cada golpe) y «⚠ Aliento: córtalo n/m» sobre su vida. Mientras aspira, su barra de tiempo va al 70 % |
| Golpe | arena oscura y clara que salta a los pies, polvo, onda, sacudida 8, empujón del alcanzado | cae a lo largo: grietas que brillan y se apagan, placas de piedra con filo de vidrio que se alzan y se hunden (7; 4 en el móvil), polvo, esquirlas de vidrio, dos ondas, sacudida 12 | chorro de arena con bordes suaves de la boca al pecho del grupo y más allá, arena que vuela dentro, nube de polvo y empujón de cada héroe, velo de arena en pantalla, sacudida 9 |
| Sonido (una vez, en el impacto) | el golpe de siempre + `gusano_temblor` | aviso: `carga_jefe` + `gusano_rugido` en el pico del rugido; golpe: `Sonido.golpe(true)` + `gusano_temblor` | aviso: `carga_jefe` + `gusano_temblor` al empezar a aspirar; golpe: `gusano_rugido` + `Sonido.golpe(true)` |
| Respuesta | Defender (½), Guardia de Garon, curar | Defender (½ y sin tambalearse) o Barrera Rúnica. Quien no defiende **se tambalea**: pierde 25 de su barra de tiempo (nunca por debajo de 0; quien ya espera turno, nada). No se corta | Defender (½), Barrera Rúnica o **cortarlo**: quitarle mientras aspira el 20 % de su vida (15 % con dos héroes en pie, 10 % con uno) o Quiebra. Cortado: se atraganta, pierde su turno siguiente («Aturdido») y no suelta nada. Soltado: jadea un turno |

Las posiciones de los héroes no cambian nunca: los empujones mueven solo su dibujo (`cuerpo`) y vuelven.

## 2. Patrón de IA (determinista, sin azar)

- Más de la mitad de vida: E, E, ⚠F, F, E, E, ⚠F, F…
- Con la mitad o menos («¡La arena se enfurece!»): E, ⚠A, A (o cortado), jadea, E, ⚠F, F, E, ⚠A…
- **Nada encadenado:** tras soltar un especial, su turno siguiente es una embestida (o jadea); cada especial se avisa un
  turno antes; y si desde el aviso no ha empezado ningún turno de héroe (`combate.gd`, `turnos_heroe`), sigue
  preparándolo («sigue preparando su…»). Comprobado en cada combate de la prueba (`_patron`).
- No huye nunca (ni en «zona limpia») y HUIR sigue apagado con «Bramavidrio cierra el paso».

## 3. Equilibrio medido (comprobado ejecutando, aislado, 11/11, `3d4f5a1`; registro en `D:\REBELUM_diagnostico\combate\2026-11-11_bramavidrio\medir_equilibrio.log`)

**Valores:** 1150 PV, ataque 34, velocidad 11 (antes: 380, 20 y 9). Con uno o dos héroes en el grupo, 50 % o 70 % de
la vida. Escalado de jefe de siempre (como mucho +2 niveles sobre el 10 del desierto).

Cinco semillas por fila. «Jugador» = estrategia sencilla de la prueba: defender la Fractura, cargar contra el Aliento
(Lya Fuego, Garon Juicio, Kael ataca), Lya cura por debajo del 55 %. «Automático» = solo ataques al gusano. **Ganar con
ataques automáticos o con una estrategia de prueba no demuestra cómo lo vive un jugador.**

| Grupo | Jugador | Automático | Notas (jugador) |
|---|---|---|---|
| Kael, Lya, Garon a nivel 10 | 5/5, ~120 s, vida mínima 35-48 % | 2/5 (caen héroes) | corta el Aliento en las 5 |
| los tres a nivel 9 | 5/5 | 0/5 | vida mínima 15-34 % |
| los tres a nivel 12 | 5/5, ~160 s | 0/5 | el escalado de jefe sube al gusano y los héroes de la prueba no reparten atributos |
| Kael y Lya a nivel 10 | 5/5, ~150 s | 0/5 | a veces cae uno; vida mínima 0-20 % |

Daños típicos (nivel 10): Embestida 40-50 (crítico o furia hasta ~90), Fractura 33-42 sin defender y 17-19 defendida,
Aliento ~60 sin defender (~90 con furia) y la mitad defendido. Duración: 6-10 turnos del gusano.

## 4. Archivos y ganchos

- **`aethelgard/combate_bramavidrio.gd`** (nuevo): nodo hijo del combate (sus esperas y efectos mueren con la escena).
  IA, ataques, avisos (cartel arriba a la derecha, en el cielo: no tapa al gusano ni el menú), efectos 2D temporales
  (nada del terreno ni de las colisiones cambia), premio y textos. Constantes de equilibrio al principio.
- **`aethelgard/combate.gd`**, ganchos comentados «V12, Bramavidrio»:
  - `const Brama`, `var brama`, `var turnos_heroe` (+1 al empezar cada turno de héroe en `_siguiente_turno`);
  - `MODELOS["bramavidrio"]`: el 3D con el encuadre de animaciones (pasada 2: `esc` 1,07, `vp` 1920×1000,
    `alto_vista` 5,1, `centro_y` 1,45, `pies_como` 0) más `centro_3d_v` (el cuello: números, efectos y la vida
    encima) y `pos_golpe` (adónde van los héroes cuerpo a cuerpo); `MODELOS["bramavidrio2d"]`, la foto de antes con
    `pos_grupo` (su sitio de antes); `GRUPOS[13]` en (288, 600); `ANIM["bramavidrio2d"]`;
  - `ENEMIGOS["bramavidrio"]`: personalidad «bramavidrio», 1150 PV, ataque 34, velocidad 11;
  - `_ready`: crea su nodo y su emersión (arena, temblor y rugido); `_elegir_enemigos`: `pos_grupo`;
  - `_turno_enemigo`, `_animar_golpe`, `_vigilar_carga`, `_info_objetivo`, `_actualizar` (estados), `_fin_combate`
    (premio una vez), `_restablecer_color` (su derrota se ve 2,8 s antes de desvanecerse);
  - `_sonar`: también los efectos de `EFECTOS_DESIERTO` (`gusano_rugido`, `gusano_temblor`);
  - `_crear_rig_3d`: `centro_3d_v` opcional; `_crear_rig`: `pos_golpe`; `_pos_ataque(obj)` sustituye a `obj["pos"]` en
    los acercamientos (con cualquier otro enemigo devuelve `obj["pos"]`: la huella del combate sale igual).
- **`barra_y`** = 498: la vida y los estados se leen sobre el cuello (pantalla ≈ (304, 316); estados ≈ y 288), dentro de
  la pantalla y sin cortar (capturas). La flecha del objetivo, sobre la cabeza.
- **Premio** (propuesta): 2 Reliquias de vidrio la primera vez (sirven para el buscador de nivel 3). En la región,
  `gusano.gd` `vencido()` da verdadero después (comprobado en la prueba).
- **Huella del combate:** `prueba_combate_huella` sigue saliendo igual (ningún otro enemigo cambia).

## 5. Pruebas (aisladas, `--fixed-fps 30`)

- **`prueba_bramavidrio_combate`** (nueva, en la lista): A (tres héroes a nivel 10 con estrategia: cada turno del
  gusano comprobado, patrón, victoria, premio una vez, `vencido()`), A2 (otra vez: sin premio), B (Aliento cortado,
  pierde su turno, sin impacto, suena el corte), C (Aliento defendido a la mitad), D (dos héroes ganan en alguna de 4
  semillas), E (derrota a nivel 1: sin premio, sin avisos colgados, no se bloquea), F (automático: termina), G
  (tambaleo y textos). Con `medir`: la tabla de arriba. Con `fotos=<carpeta>` y ventana: capturas.
- **Pasada final** (`D:\REBELUM_diagnostico\pruebas\2026-11-11_162413\resumen.md`): **17 SUPERADAS, 0 FALLIDAS**:
  `prueba_bramavidrio_combate`, `prueba_bramavidrio_modelo`, `prueba_mar_cristal`, `prueba_huir`, `prueba_garon`,
  `prueba_grupos_combate`, `prueba_combate_seguro`, `prueba_coloso`, `prueba_coloso_garganta`,
  `prueba_equipo_combate`, `prueba_zarzalin_combate`, `prueba_combate_huella`, `prueba_v11_combate`,
  `prueba_patrones_enemigos`, `prueba_hud_combate`, `prueba_integridad` y `prueba_audio_desierto`. Partida y carpeta
  real de datos sin cambios. No he pasado la batería entera.

## 6. Capturas (con ventana, datos aislados): `D:\REBELUM_diagnostico\combate\2026-11-11_bramavidrio\`

- **`fotos\`** (las finales, `3d4f5a1` salvo el último ajuste de la Fractura): `01_entrada_rompe_arena`,
  `03_kael_ataca`, `04_garon_ataca` (los héroes se plantan ante su boca), `05_embestida_fija` (anillo y «⚠»),
  `06/07_impacto_embestida`, `10_aviso_sismico` (erguido fuera de pantalla, cartel, grietas), `11/12_impacto_sismico`,
  `15_aviso_aliento` (succión, cartel con lo que falta), `16_aliento_cortado`, `26/27_impacto_aliento`,
  `17_derrota_caida`.
- **`borrador1\` y `borrador2\`:** el antes de los arreglos (chorro duro y corto, Fractura escondida bajo el cuerpo y
  luego encima del menú, arena casi invisible).
- **`medir_equilibrio.log`:** la medida final.

## 7. Comprobado y NO comprobado

**Comprobado (PC, aislado):** lo de §5; que cada ataque golpea una vez y su sonido se pide una vez en el fotograma del
impacto (señal del modelo frente a `sonido_pedido`); que los efectos quedan bajo el menú y la vida; partículas en CPU a
la vez como mucho: ~180-350 en el PC y ~86-200 con `movil` (calidad 0,4; incluye las magias de los héroes).

**NO comprobado:**
- **Nada en el Redmi:** ni rendimiento (ventana 3D de 1920×1000 al 70 %, recorte con `discard`, partículas), ni la
  lectura del cartel y los estados en pantalla pequeña, ni el tacto.
- **Cómo suena:** las pruebas miran qué se pide, no lo que se oye. Nadie ha escuchado el combate.
- **El respaldo 2D** (`bramavidrio2d`) no se ha ejecutado: el código lo contempla (sin modelo, timers y la animación de
  imagen), pero no hay prueba que quite el GLB.
- **La vuelta a la región después de ganar** no se ha recorrido entera: solo `vencido()`; `prueba_mar_cristal` llega al
  combate pero no vuelve.
- **Controles:** el menú no cambia y el cartel no recibe toques (`MOUSE_FILTER_IGNORE`), pero no he simulado toque,
  teclado ni mando contra este combate.
- La Guardia de Garon, la Barrera Rúnica y Quiebra contra el gusano: el código pasa por los caminos de siempre, sin
  prueba propia.
- Estrategia de jugador real: la de la prueba es sencilla.

**Límites visibles (prototipo):**
- El chorro 3D del modelo (malla cian) sale hacia abajo y hacia la cámara, no hacia los héroes; el 2D sí va al grupo.
- En la Fractura y la derrota el cuerpo cae por delante de los héroes, pero ellos se dibujan encima (orden 2D).
- El sísmico y la emersión se salen por arriba a propósito; la cabeza en reposo queda junto a Kael y Garon.

## 8. Fallo mío de procedimiento

Al empezar (11/11, 15:41) lancé una vez Godot **sin datos aislados** para leer los atributos de los héroes
(solo lectura). No tocó `partida.save` (08/11 19:37, sin cambios), pero Godot rotó su registro en la carpeta real:
`%APPDATA%\Godot\app_userdata\Aethelgard\logs\godot.log` y `godot2026-11-11T15.41.20.log`. No he borrado nada. Todo lo
demás se lanzó con `APPDATA`, `LOCALAPPDATA`, `TEMP` y `TMP` redirigidos o con `ejecutar_pruebas.ps1`.

## 9. Siguiente paso y peticiones a otros

1. **Coordinador:** integrar en la V12 copiando (`combate.gd`, `combate_bramavidrio.gd` y su `.uid`, la prueba y su
   `.uid`, `lista_pruebas.txt`); probar en el Redmi el combate entero en los tres perfiles (FPS en la Fractura y el
   Aliento) y la lectura del cartel.
2. **Sonido** (`sonido.gd`, no es mío): una familia de voz para el gusano en `FAMILIAS` (hoy no tiene voz de herido ni
   de caída; por ejemplo `"bramavidrio": "piedra"` o una propia) y, si se quiere, sonidos propios para la succión y el
   chorro del Aliento y la caída de la Fractura (hoy se reutilizan `gusano_temblor`, `gusano_rugido`, `carga_jefe` y
   los golpes). Escuchar los volúmenes.
3. **Animaciones** (`bramavidrio_3d.gd`, no es mío): una opción para que en el combate el chorro 3D apunte a los
   héroes (hacia +X de la pantalla) o se pueda esconder (por ejemplo `chorro_combate := false` que deje la escala del
   hueso «chorro» a 0,01); hoy lo tapa en parte el chorro 2D.
4. **Narrativa:** revisar los textos del combate (cartel, «se retrae y clava sus ocelos en…», «se atraganta con su
   propia arena») y el premio propuesto (2 Reliquias de vidrio).
5. **Combate (yo, si se pide):** una prueba del respaldo 2D sin GLB y la vuelta a la región tras ganar.
