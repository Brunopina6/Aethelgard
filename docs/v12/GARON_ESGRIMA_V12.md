# Garon · Esgrima de dos filos (V12, piloto del 13/11/2026)

Especificación del usuario: `D:\REBELUM_diagnostico\v12\expansion\encargos_13_11\Aethelgard_Garon_Esgrima.pdf`
(12/11/2026, «diseño propuesto»). Este documento dice cómo se adapta al juego real y qué hay hecho.

Código: `aethelgard/combate_acciones_v12.gd` (nuevo) con enganches de una línea en `combate.gd`; opción en Ajustes,
bloque «Combate» (`menus.gd`). Clips: `aethelgard/fuente/clips_combate_v12.py` → `personajes/heroes_v2/garon/garon_v2_combate_v12.glb`.
Prueba: `aethelgard/pruebas/prueba_acciones_v12.gd`.

**Interruptor:** `esgrima_v12` (APAGADO). Se enciende con `Engine.set_meta("esgrima_v12", true)`, con el argumento
`-- esgrima_v12` o en Ajustes › Combate › «Esgrima v12 de Garon: sí» (`[combate] esgrima` en `user://ajustes.cfg`).
Apagado, `combate.gd` hace exactamente lo de siempre: Garon no tiene Compás, ESGRIMA muestra Juicio, Giro, Guardia (y
Leer runas) y la huella del combate es la misma.

## 1. Conversión de turnos (el documento pide decidirla antes de integrar)

El combate es **ATB por turnos**, no de acción: cada luchador llena su barra, entra en la cola y actúa cuando sale de
ella (`_siguiente_turno`). Por eso **no hace falta** la equivalencia «1 turno = 5 s» que el documento propone para
juegos de acción, y no se crea ningún contador ficticio:

| Documento | Juego (lo que hace el piloto) |
|---|---|
| Turno propio | Cada vez que a ese héroe le toca (sale de la cola y se abre su menú). `al_turno_heroe` lo cuenta en `c12_turnos` al empezar el turno, junto a la Guardia de Garon y el Segundo Aliento de siempre. |
| CD N «impide las siguientes N oportunidades propias» | Al usarla en el turno T se guarda `T + N`; está apagada mientras `turnos ≤ T + N` y vuelve en el turno T + N + 1, con el motivo «Lista dentro de X turnos de Garon». |
| Estado «hasta el siguiente turno propio» (Guardia en Cruz, el Compás de Defender) | Se quita al empezar su siguiente turno, igual que Defender (`defendiendo`). |
| «Durante la pausa no avanzan eventos ni CD» | Los CD solo cuentan turnos; con la animación v12 y «ATB quieto al actuar», las barras esperan mientras actúa (`AnimV12._accion`, presupuesto de Juicio). |
| Contactos al 50 % / 65 % y 50-74 % del clip | Eventos `contacto`, `contacto_2`… del JSON del clip; el daño entra en ese instante. Sin el clip (Garon de siempre), los contactos van seguidos dentro del Juicio de siempre. |

## 2. Reglas del piloto

* **Daño:** con la fórmula de siempre (`_dano_fisico(Garon, coeficiente)`, la del Juicio: ataque, Embuir +20 %,
  variación). Se tira **una vez** por acción y se reparte entre los contactos: la suma es exactamente esa tirada
  (Punta Gemela 2 contactos de 1,10 A en total; Cadencia 7 de 3,80 A en total). Las defensas de los jefes (Coloso,
  Vidracrán, Humbaba) se aplican a cada contacto, como al Juicio. Sin crítico: el documento dice «críticos usan el
  sistema real» y en el juego las técnicas de esgrima (Juicio, Giro) no hacen crítico. Las fórmulas no se cambian.
* **Compás:** tope 3, empieza en 0 cada combate (vive en el diccionario del combate, no se guarda). +1 si acierta el
  ataque básico; +1 si Defender para de verdad un golpe (una vez por Defender); +1 como mucho si acierta una técnica
  I-IV que lo diga (Punta Gemela, Guardia en Cruz); las que lo gastan no dan. Nunca por contacto. Indicador: tres
  rombos junto al nombre de Garon en el HUD.
* **Costes:** los del documento. Su «PM de referencia 100 al final de la progresión» coincide con el juego
  (`grupo.gd`: 4 + 3 × espíritu + 2 por nivel ⇒ unos 100-120 PM a nivel 50; Garon empieza con 10). En el piloto no
  hay desbloqueo por nivel: las tres salen en el menú y, sin PM o sin Compás, apagadas con su motivo. Se cobra al
  confirmar el objetivo, una vez; elegir sin poder pagar no cobra ni pide objetivo.
* **Menú:** con el interruptor, ESGRIMA abre en páginas de 3 (el menú enseña 4 filas): Punta Gemela, Guardia en Cruz y
  Cadencia, y «Más ›» a Juicio, Giro, Guardia (y Leer runas). ESGRIMA ya no se apaga por PM (Punta Gemela cuesta 0).

## 3. Las tres acciones del piloto

| ID | Nombre | Coste | Efecto en el juego | Clip (perfil) | Efecto visual y sonido |
|---|---|---|---|---|---|
| garon_01 | Punta Gemela (básica) | 0 PM | 1,10 A en una tirada, 2 contactos (50 % y 65 %). +1 Compás si acierta. | `c12_punta_gemela` 1,2 s (P01): estocada corta con cada hoja | 2 trazos finos de acero; golpe seco por contacto |
| garon_02 | Guardia en Cruz (estado) | 3 PM | 0,80 A, 1 contacto; el próximo golpe directo que reciba Garon hace −20 % (una vez), hasta su siguiente turno. +1 Compás. | `c12_guardia_cruz` 1,45 s (P02): corte bajo y cruza las hojas | cruz de dos trazos sobre Garon y rótulo «Guardia en Cruz»; «Cruz» al parar el golpe |
| garon_16 | Cadencia de las Siete Puntas (culminante) | 32 PM + 3 Compás | 3,80 A en una tirada, 7 contactos (50-74 %). CD 4. No da Compás. | `c12_tecnica_carga` (anuncio) + `c12_cadencia` 3,1 s (P07): quietud, siete puntas en tres frases | 7 marcas pequeñas, 3 golpes de audio (1.º, 4.º y 7.º), acercamiento de cámara ≤ 9 % fuera de jefes, pausa corta por contacto |

La «Guardia en Cruz» solo cuenta golpes que pasan por `_animar_golpe` (los directos); los golpes a todos de los
jefes no la gastan (el documento dice «daño directo»).

## 4. Las 18 técnicas: hecho / pendiente y adaptación

Estados: **D** diseñado (PDF) · **G** generado (clip) · **I** integrado (en `combate.gd` tras su interruptor) ·
**P** probado en PC (prueba automática) · **A** validado en Android. Nada está validado en Android.

| ID | Técnica | Rango | Coste | Estado | Adaptación propuesta al juego real |
|---|---|---|---|---|---|
| garon_01 | Punta Gemela | I | 0 | D G I P | Hecha (arriba). |
| garon_02 | Guardia en Cruz | I | 3 | D G I P | Hecha (arriba). |
| garon_03 | Paso de Aguja | I | 3 | D | El juego no tiene evasión de enemigos: queda 1,20 A a uno. Muy cerca de Juicio: diferenciar por coste o quitarla. |
| garon_04 | Finta del Espejo | II | 6 | D | «Guardia física −10»: el estado más cercano es «Defensa ↓» de la magia negra (es de Nix: reusarlo solo con acuerdo). Probabilidad base 75 % con `randf` (gasta azar: solo encendido). |
| garon_05 | Tijera de Bronce | II | 6 | D | Barreras enemigas: solo la coraza rúnica del Coloso. +15 % contra ella, sin bonus a PV. |
| garon_06 | Círculo del Duelista | II | 7 | D | Área sin desplazarse: se parece al Giro (área). Reusar `atacar_giro` con pies anclados; regla 3/n con 4+ blancos. |
| garon_07 | Ligadura de Filo | III | 10 | D | «Debilidad física»: estado nuevo de 2 turnos del enemigo (sube el daño físico que recibe) o «Defensa ↓» compartido. |
| garon_08 | Réplica Medida | III | 9 | D | Postura propia: un contraataque de 1,50 A al primer golpe físico directo. Enganche en el mismo sitio que la Guardia en Cruz (`reducir`); no responde a áreas, venenos ni a otro contraataque. Da 1 Compás al resolverlo. |
| garon_09 | Roseta de Acero | III | 11 | D | 1,80 A en 3 contactos: la misma tirada repartida que ya usa el piloto. |
| garon_10 | Desarme del Alba | IV | 15 | D | −15 % al daño físico del enemigo 2 turnos suyos (enganche en `_animar_golpe` cuando él golpea). 70 % base. |
| garon_11 | Doble Horizonte | IV | 16 | D | Área 1,55 A; con un blanco, sin daño extra. Clip de dos barridos. |
| garon_12 | Compás de Asalto | IV | 14 | D | «Ruptura»: el juego no tiene barra de postura ⇒ se omite (lo dice el documento) y no consume Compás; queda 2,15 A. |
| garon_13 | Apertura del Maestro | V | 22 | D | «Ignora 20 % de defensa física»: necesita que la fórmula acepte esa opción; no se toca la fórmula sin decisión. |
| garon_14 | Ronda de las Dos Lunas | V | 24 | D | Área 2,00 A, 2 Compás, CD 2. |
| garon_15 | Promesa del Acero | V | 20 | D | Barrera 0,50 A a Garon 2 turnos con la «barrera» de las artes (la de la Custodia de Lya, que ya caduca por turnos). |
| garon_16 | Cadencia de las Siete Puntas | VI | 32 | D G I P | Hecha (arriba). |
| garon_17 | Juramento de Dos Filos | VI | 34 | D | Área 2,85 A, 3 Compás, CD 4; perfil P08 (remate gemelo, por hacer). |
| garon_18 | Silencio del Duelo | VI | 30 | D | 4,10 A, 3 Compás, CD 4; ruptura omitida (no hay postura). Perfil P07 con otra pose (quietud y doble estocada). |

Para ampliar: las 18 no caben en una página; propuesta: pestañas por rango (I-II, III-IV, V-VI) como las de MAGIA, y
desbloqueo por nivel (1/8/16/26/38/50) con su motivo, sin tocar `grupo.gd` hasta que el coordinador lo apruebe.

## 5. Límites honrados

* **Probado en PC** con `prueba_acciones_v12` (sin ventana): PM y Compás insuficientes, objetivo, una sola aplicación,
  suma de contactos = una tirada, Compás +1 como mucho, tope 3, CD, Guardia en Cruz −20 % una vez, Defender una vez,
  con los protagonistas de siempre y con los v2 (por sus clips). Capturas y vídeo en
  `D:\REBELUM_diagnostico\v12\expansion\combate2\acciones\`.
* **No** validado en el Redmi (sin ADB en este encargo). Coste de los efectos: trazos y sprites del combate, sin
  partículas nuevas, luces ni texturas.
* Interrupción a mitad (muerte del actor, objetivo muerto antes del contacto): el contacto no hace nada si el objetivo
  ya cayó; si el combate se cierra, el motor es un nodo hijo y no reanuda. No hay prueba específica de «muerte del actor».
* Los clips son poses por guion (biblioteca de Blender) sobre el rig v2: legibles en combate, no animación de autor.
