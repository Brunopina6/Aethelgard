# V12, fase 7: primera experiencia jugable de Oakhaven

Encargo del coordinador del 13/11, §10 («Primera experiencia jugable completa») y §11 (cerraduras rúnicas, primer
minijuego). Texto literal en `docs/v12/encargos/ENCARGO_COORDINADOR_13_11.md`.

- **Rama local:** `claude/v12-oakhaven-jugable`, desde `claude/rebelum-v12` @ `b451518`. Worktree:
  `D:\Aethelgard_v12_oakhaven_jugable`. Sin subir.
- **Probado:** solo en el PC, sin ventana y con datos aislados (`ejecutar_pruebas.ps1`). Nada en el Redmi.
- **Regla seguida:** se reutilizan el registro de encargos (`encargos.gd`), el Diario (`diario.gd`), el gremio
  (`gremio.gd`), las piezas, cofres y estados de Oakhaven (`ciudades/oakhaven.gd`) y el guardado de siempre. **Ninguna
  clave de partida nueva**: todo va en `hitos`, `mazmorras["oakhaven"]`, `decisiones`, `inventario` y `gremio`.

## 1. Gremio: el bloqueo de Oro (13 frente a 15)

**Qué estaba (comprobado en el código, `b451518`).**
- La reputación solo sube en `gremio.gd` → `cobrar()`. No hay otra fuente en el juego (búsqueda de `gremio` en
  todos los `.gd`).
- Antes de Oro hay estos contratos:
  - Bronce: `gr_limos`, `gr_musgo` y `gr_formula`, con +2 cada uno.
  - Plata: `gr_hachas` (+3) y `gr_garganta` (+4).
  - En total, **13**. Oro pedía **15**, así que «El encargo del maestro» (`gr_ambar`, rango Oro) no se podía abrir nunca.
- Los cinco contratos son cumplibles en el juego actual:
  - las claves `slime` y `grimfang` existen;
  - el Musgo de piedra está en el bosque y en la botica;
  - el hito `enc_formula_fin` existe;
  - el combate fijo `garganta_nido` existe;
  - el Mineral rúnico sale del buscador y del Coloso.

**Qué cambia.** Ajuste mínimo, un número: **Oro pasa a 13** (justo los cinco contratos de Bronce y Plata). No cambian
los contratos, los premios ni los textos.

**Partidas antiguas.**
- Una partida atascada con 13 de reputación carga directamente en Oro, sin perder nada.
- Una partida sin gremio empieza en Bronce, como antes.

**Pruebas.**
- Nueva, `prueba_gremio_progresion`:
  - invariante por rango (si un rango vuelve a pedir más de lo accesible, falla);
  - Bronce → Plata → Oro jugando cada contrato con su condición real;
  - el encargo del maestro y una reputación final de 18;
  - guardar y cargar;
  - la partida de antes del ajuste y la partida sin gremio;
  - el tablón en Oro.
- **Contraprueba:** con Oro a 15, la prueba falla con 14 fallos.
- `prueba_gremio` sigue pasando.

## 2. Misiones de Oakhaven en el Diario y la caravana

**Qué estaba.**
- El Diario (pestaña Encargos) ya listaba las misiones de Oakhaven (`ciudades/oakhaven.gd` MISIONES,
  `datos/encargos_oakhaven.gd`) y las de Pastos Verdes, pero solo con el paso actual. No recordaba:
  - los objetivos cumplidos;
  - lo leído;
  - las decisiones tomadas.
- Los contratos del gremio no salían en el Diario.
- **La caravana:** «La caravana perdida» se juega entera en el Mar de Cristal 3D (`zonas3d/mar_cristal/mision.gd`,
  hitos `mc_*`). Faltaba `datos/encargos_desierto.gd`, que `DISENO_V12.md` §2 preveía, así que el Diario no la
  recordaba. La región sigue «en pruebas» (`modo3d.gd`).

**Qué cambia.**
- `encargos.gd`, campos opcionales (sin ellos, todo sigue igual):
  - `tipo`: principal, secundaria (por defecto), personal, secreta, cadena o contrato;
  - `pistas`: [{texto, si}];
  - `pasos_conocidos()`: los pasos hechos y el actual, **nunca los siguientes**;
  - `pistas_conocidas()` y `tipo()`.
- `diario.gd`:
  - ✔ en los objetivos cumplidos, «Ahora:» en el actual y «·» en las pistas y decisiones conocidas;
  - un rótulo con el tipo (por ejemplo, «Secreto»);
  - arriba, los contratos del gremio **aceptados**, con su progreso o «listo» (`gremio.gd` → `para_diario()`).
- **Pistas con texto que el jugador ya vio:**
  - las tres páginas de Mirta, una a una;
  - el pilar del herrero, con y sin Garon (el aviso de `garganta_3d.gd`);
  - **la decisión del hierro** (se recuerda solo la que se tomó);
  - lo que dijo Rosa sobre la lavanda;
  - de la caravana: el sello, la llave y el mural («…de los Espejismos», aprobado el 11/11).
- «Un secreto por una moneda» se marca como `secreta`. Sigue sin salir hasta pagar a Pip.
- `datos/encargos_desierto.gd`: «La caravana perdida».
  - Sus siete pasos siguen los hitos `mc_*`, con los avisos de la región.
  - `recompensa` va vacía, porque el premio lo da `mision.gd`.
  - Sin `mc_inicio`, no sale.

**Pruebas.**
- Nueva, `prueba_diario_misiones`:
  - registro y condiciones;
  - en **todos** los encargos y paso a paso, nada se adelanta;
  - las pistas, con señales de verdad;
  - el secreto oculto;
  - los contratos;
  - guardar y cargar, y la partida antigua.
- **Contraprueba:** si el Diario enseñara todos los pasos, la prueba falla con 62 fallos.

## 3. La cerradura rúnica (primer minijuego de cerraduras)

**Qué es.**
- `cerradura_runica.gd` es una ventana reutilizable. Quien la abre le da su configuración y lo que pasa al resolverla.
- **El puzle:**
  - tres anillos concéntricos con los seis símbolos del reino (los de las parejas);
  - una marca arriba;
  - la combinación (de fuera adentro) se **deduce** de la inscripción de la tapa;
  - los anillos están **engranados**: girar uno arrastra un paso al de dentro, así que importa el orden.
- Siempre tiene solución: se resuelve en 9 giros o menos desde cualquiera de las 216 posiciones, y en 6 desde la
  inicial.
- No hay intentos, ni tiempo, ni castigo.
- **Controles:**
  - con el dedo o el ratón, tocar un anillo lo gira hacia ese lado; también hay botones ◀ ▶ de 110 × 80 px;
  - con el teclado o el mando, ↑ ↓ eligen el anillo, ← → lo giran e Intro lo gira;
  - Esc, B, Atrás de Android o «Salir» cierran sin perder nada.

**Dónde (PROPUESTA de sitio y textos).**
- **El arcón del Concejo**, bajo el pórtico de la Casa del Concejo (casilla 50,5; 22), en la 2D y en la 3D.
- En 3D se reutiliza el cofre de los barrios, con un aro de runas dorado.
- Inscripción: «De fuera adentro: lo que arde, lo que sana y lo que vela de noche.» (Fuego, Cura y Luna.)
- **Premio, una sola vez:** 60 monedas, 1 Éter y 1 Mineral rúnico. El mineral sirve para el contrato de Oro del gremio.
- Estado en `mazmorras["oakhaven"]`: `cerradura_vista` y `cerradura_abierta`.
- **Diario:** encargo «El arcón del Concejo».
  - Sale al mirar la cerradura.
  - Su pista es la inscripción, nunca la combinación.
- `taberna_parejas.gd`: el dibujo de los símbolos pasa a la función estática `dibujar_simbolo` (a escala 1, el mismo
  dibujo). Lo usan las dos ventanas.

**Pruebas.**
- `prueba_cerradura_runica`:
  - el puzle, las 216 posiciones y el engranaje;
  - los botones, el ratón, la pantalla táctil, el teclado y el mando;
  - abandonar de tres formas sin premio;
  - 300 giros sin que nada se cierre;
  - el premio una vez y el Diario;
  - guardar y cargar, y la partida antigua;
  - la ciudad 2D.
- `prueba_cerradura_runica_3d`, en Oakhaven 3D:
  - el aro;
  - «Girar los anillos»;
  - ocupado mientras está abierta;
  - salir;
  - la tapa que se abre;
  - que se guarda;
  - «Examinar» cuando ya está abierto.

## 4. Misión secundaria y secreto ambiental (PROPUESTA, APAGADA)

**Pendiente de aprobación del usuario.** Va tras el interruptor `oakhaven_propuestas_v12`, **apagado por defecto**,
en `ciudades/oakhaven_propuestas.gd`. Con él apagado, Oakhaven queda exactamente igual; la prueba lo comprueba. Se
enciende de tres formas:
- `Engine.set_meta("oakhaven_propuestas_v12", true)`;
- el argumento `oakhaven_propuestas_v12`;
- `user://ajustes.cfg`, en `[mundo] propuestas_v12 = true`.

**«Las tres marcas del cantero»** (misión secundaria) y **la losa del cantero** (secreto ambiental con deducción e
interacción):
1. Al abrir el arcón del Concejo hay, además, una nota: «Dejé tres marcas donde la ciudad siempre mira. Léelas por sus
   muescas.» Empieza la misión. Se conecta así con la cerradura.
2. Hay tres runas talladas con muescas. Se examinan («Examinar la marca») y el Diario las apunta como pistas:
   - en la fuente de la plaza, Agua (2);
   - en la puerta de la Torre de la Campana, Rayo (1);
   - en una raíz del Árbol, Luna (3).
3. **Deducción:** ordenadas por sus muescas y de fuera adentro, dan la combinación de la losa (Rayo, Agua y Luna).
   Ningún texto la da hecha; la prueba lo comprueba.
4. La losa está entre las raíces, al oeste del tronco. Es otra cerradura rúnica con otra configuración.
   - Se puede intentar en cualquier momento.
   - Al abrirla da, una sola vez, 80 monedas, 1 Incienso de Ceniza y 1 Éter. La misión acaba.

**Lo que no inventa.** No toca:
- el crematorio, la posadera, Pip ni los requisados;
- ningún nombre de la versión neutra (D-073);
- Érebo, los corazones o los recuerdos.

El «cantero» es anónimo.

**Pruebas.**
- `prueba_oakhaven_propuestas`:
  - apagada, nada cambia;
  - encendida: los sitios (pisables y a 2,5 casillas o más), los textos, la deducción y la solución;
  - la misión entera, el guardado y la partida antigua;
  - la ciudad 2D.
- `prueba_oakhaven_propuestas_3d`:
  - apagada, nada nuevo;
  - encendida, cuatro piezas alcanzables, la losa en el suelo, una marca apuntada y la losa abierta.

## Archivos

- **Nuevos:**
  - `cerradura_runica.gd`;
  - `ciudades/oakhaven_propuestas.gd`;
  - `datos/encargos_desierto.gd`;
  - las pruebas `prueba_gremio_progresion`, `prueba_diario_misiones`, `prueba_cerradura_runica` (y `_3d`) y
    `prueba_oakhaven_propuestas` (y `_3d`).
- **Tocados:**
  - `gremio.gd`: el umbral de Oro y `para_diario`;
  - `encargos.gd`;
  - `diario.gd`;
  - `ciudades/oakhaven.gd`: la pieza y la configuración del arcón, las cerraduras genéricas, `piezas_activas()`, las
    señales `oak:cantero_*` y el `tipo` y las `pistas` de dos misiones;
  - `datos/encargos_oakhaven.gd`: pistas y el encargo del arcón;
  - `ciudad_oakhaven.gd` y `zonas3d/oakhaven/vida3d.gd`: abrir las cerraduras, dibujar el arcón y la losa, e iterar
    `piezas_activas()`. En la 3D, el cofre se extrae a `_nodo_cofre`;
  - `taberna_parejas.gd`;
  - `pruebas/lista_pruebas.txt`;
  - `docs/v11/GREMIO.md`: el rango Oro.

## Propuestas pendientes de aprobación

1. **Sitio y textos del arcón del Concejo:** la inscripción y el premio. Están activos por defecto porque son juego y no
   historia. Si el usuario no los quiere, basta con quitar la pieza.
2. **«Las tres marcas del cantero» y la losa:** narrativa nueva, apagada. Para activarla por defecto:
   `ACTIVO_POR_DEFECTO = true` en `ciudades/oakhaven_propuestas.gd` y una línea en Ajustes (`menus.gd`, como
   «Oakhaven: mundo vivo»).
3. **Gremio:** Oro a 13 obliga a hacer todos los contratos anteriores. Si se prefiere margen, hay dos alternativas: un
   contrato de Plata más, o Oro a 12.

## Pendientes

- **En el Redmi:**
  - girar los anillos con el dedo (botones y rueda);
  - leer la inscripción a 28 px;
  - el Diario con pistas largas (con salto de línea).
- Capturas con ventana del arcón (2D y 3D) y de la ventana de la cerradura: no se han hecho en esta fase.
- La opción de Ajustes de la propuesta: queda pendiente de aprobación. Para no tocar `menus.gd` no se añadió.
- Los minijuegos siguientes (§11: alquimia experimental, forja, cartas y pesca): sin empezar, como pide el encargo.

## Batería completa (14/11, con los cuatro puntos)

**Resultado:** 166 superadas, 1 fallida, 73 manuales y 0 no seguras. La partida real no cambió.

- **Dónde:** `D:\REBELUM_diagnostico\pruebas\2026-11-14_031907`.
- **La fallida:** `prueba_velador_v12`, de equilibrio de combate, en un archivo que esta fase no toca.
  - Falló con 63 Godot de otras sesiones abiertos.
  - Repetida sola, en `2026-11-14_035929` y sin otros Godot, se supera.
  - Es intermitente por carga.
- **«Proyecto cambiado»:** son este documento y el informe de agente, escritos mientras corría la pasada.
