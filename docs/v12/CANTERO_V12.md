# «Las tres marcas del cantero»: aventura secundaria cerrada (14/11, noche)

Encargo del usuario del 14/11 por la noche, prioridad 1: cerrar una aventura secundaria aprovechando lo hecho, sin
crear otra misión paralela. Parte de la PROPUESTA de la fase 7 (`OAKHAVEN_JUGABLE_V12.md` §4) y la completa.

**Sigue siendo PROPUESTA, sin canon.** Va tras su interruptor (`oakhaven_propuestas_v12`), APAGADO fuera de Auditoría.
- En Auditoría se enciende en Ajustes («Oakhaven: misión del cantero (propuesta)») o en el banco de pruebas (selector
  «Misión del cantero»).
- Apagada, Oakhaven queda igual: no salen ni el vecino, ni las marcas, ni la losa, ni la investigación del taller.
- Personaje nuevo sin nombre propio (el aprendiz del cantero). No toca Érebo, los corazones, la posadera, el
  crematorio ni nada de D-073.

## Cómo se juega

1. **Inicio:** en la plaza, entre la fuente y el pórtico del Concejo, el aprendiz del cantero labra un sillar.
   - Su maestro, el cantero del Concejo, se marchó hace dos inviernos.
   - Le dejó su última pieza bajo una losa, y la clave en el arcón del Concejo, que nadie sabe abrir.
   - Da la primera pista: «la ciudad siempre mira al agua, a la campana y al Árbol».
   - Si se abre antes el arcón, la misión empieza igual, por la nota del cantero, y el aprendiz la reconoce
     (otro diálogo).
2. **El arcón del Concejo** (la cerradura rúnica que ya existía): dentro, la nota «Léelas por sus muescas».
3. **Las tres marcas:** placas de piedra con la runa y sus muescas.
   - La fuente: Agua, dos muescas, en la cara sureste del pilón.
   - La Torre de la Campana: Rayo, una muesca, en una estela al pie.
   - El Árbol: Luna, tres muescas, en la raíz que baja a la calle.
   - El brazalete brilla cerca de las que faltan, y el Diario apunta cada una.
4. **La losa del cantero**, entre las raíces, al oeste del tronco: otra cerradura rúnica.
   - La combinación se deduce ordenando las marcas por sus muescas, de fuera adentro (Rayo, Agua, Luna). Ningún texto
     la da hecha.
   - Se puede abandonar con Esc, Atrás o «Salir» sin perder nada.
   - Al abrirla, la piedra se aparta y deja un hueco. Premio UNA vez: 80 monedas, 1 Incienso de Ceniza, 1 Éter, y el
     cincel del maestro con una carta.
5. **Resolución:** se le llevan al aprendiz.
   - Lee la carta («El oficio ya es tuyo. Firma con tus propias muescas.»).
   - Da UNA vez 3 puñados de Polvo de cantera, para la Alquimia de Lya.
   - Desde entonces dice otra cosa: ya talla su primera marca.

**Diario:** cuatro pasos (arcón, marcas, losa, volver), que se enseñan a medida que se llega a ellos, y pistas con lo
leído y oído; nunca la combinación.

**Taller de Lya (prioridad 2):** con el polvo aparece la investigación «La piedra que asienta» (se estudia con tenerlo;
no se gasta). Desbloquea «Éter asentado»: 1 Hierba lunar y 1 Polvo de cantera dan 1 Éter.
- El polvo no se compra ni lo suelta nadie: hay tres, así que no hay fabricación infinita ni dinero infinito.
- Ese mismo lote dejó los talleres más claros: dicen todo lo que falta, ponen pistas en vez de «Aún no es el momento»,
  avisan de que el material «no se gasta» y enseñan primero lo que se puede hacer.

## Estado y guardado

Todo va en `mazmorras["oakhaven"]`, sin claves nuevas de partida:
- `cantero_pedido`;
- `cantero_marca_1` a `cantero_marca_3` y `cantero_marcas`;
- `cerradura_vista` y `cerradura_abierta` (el arcón);
- `cerradura_cantero_vista` y `cerradura_cantero_abierta` (la losa);
- `cantero_fin`.

Una partida antigua no los tiene: todo por descubrir.

## Archivos

- **Datos y lógica:**
  - `ciudades/oakhaven_propuestas.gd` (vecino, misión, señales `oak:cantero_pedido` y `oak:cantero_fin`);
  - `ciudades/oakhaven.gd` (`npcs_activos()`, el personaje de Dialogic y el texto de la losa);
  - `ciudad_oakhaven.gd` (la 2D pone al vecino; arreglado el error de la sombra de un vecino sin rutina).
- **3D:**
  - `zonas3d/oakhaven/cantero3d.gd` (las placas, con su textura pintada por código, y el sillar);
  - `zonas3d/oakhaven/vida3d.gd` (el aprendiz con su figura animada, las marcas, la losa que se aparta y el brillo del
    brazalete).
- **Diálogos:** `dialogos/oakhaven/prop_cantero_*.dtl` (pedido, nota, pendiente, fin y después) y
  `dialogos/personajes/oakhaven/cantero.dch` (sin retrato, como Ferro o Hilda).
- **Figura:** el cuerpo del herrero de la familia chibi V12, con su propio atlas,
  `personajes/npc_v12/herrero/cantero_aprendiz.png`.
  - Sale de `fuente/crear_npc_chibi.py`, que tiene ahora un 4.º argumento con otra carpeta de salida.
  - Se generó aparte y solo se copió el atlas: los demás archivos del herrero salen idénticos byte a byte.
- **Cerradura:** `cerradura_runica.gd` acepta `abre` y `grabado_en` (la losa: «Grabado en la losa», «la losa se
  aparta»).
- **Taller:** `datos/materiales/polvo_cantera.tres`, `datos/investigaciones/lya_cantera.tres` (con `si`) y
  `datos/recetas/eter_cantera.tres`.

## Pruebas (PC, datos aislados; nada en el Redmi)

- `prueba_oakhaven_propuestas`:
  - apagada, nada nuevo;
  - el vecino en un sitio pisable y separado, y sus diálogos sin la combinación;
  - la misión entera, por los dos caminos (el aprendiz primero o el arcón primero);
  - guardar y cargar antes de empezar, a mitad, con la losa vista y sin abrir, con la losa abierta y al final;
  - el premio y el polvo una sola vez;
  - la partida antigua;
  - el taller (la receta se acaba con el polvo).
- `prueba_oakhaven_propuestas_3d`: el aprendiz con su figura, las tres marcas visibles, hablar con él y la losa que se
  aparta.
- `prueba_ciudad_datos`: ahora revisa también al aprendiz (casilla, textos, frases y señales).
- **`fotos_cantero_recorrido` (ventana): la misión JUGADA con los controles normales**, sin poner hitos a mano.
  - Controles: clics en el suelo para andar, Intro para hablar y examinar, flechas en las cerraduras y Esc para
    abandonar.
  - Guardar y cargar con `Progreso.cargar` (como «Continuar») a mitad, con la losa vista y al final.
  - Resultado: **0 fallos** y 22 capturas en `D:\REBELUM_diagnostico\pruebas\<fecha>\fotos_cantero_recorrido\`.
  - Las rutas evitan obstáculos reales que encontró la propia prueba: el puesto de flores, Doña Encina y el farol de
    la losa.
- **Regresión de Oakhaven, talleres y banco:** 20 de 20 superadas.

## Revisión adversarial (14/11, 22:40)

Cuatro revisores de solo lectura (cantero, talleres, Custodio y pulido), y un escéptico por hallazgo que intentaba
refutarlo. El Custodio y el pulido salieron limpios. Se confirmaron dos defectos, ya corregidos:
- **El Diario mandaba al arcón aunque la losa ya estuviera abierta**, y no enseñaba «volver», si se abría la losa sin
  pasar por el arcón. Ahora el paso del arcón vale con cualquiera de las dos (`cond:cantero_arcon`), sin abrir el
  arcón por su cuenta.
- **El Polvo de cantera se podía vender antes de estudiar** «La piedra que asienta», y la dejaba bloqueada para
  siempre. Ahora queda reservado hasta que se estudia (`talleres.gd`, `reservado()`, como el Hierro de la Falla).

Contraprueba: sin los dos arreglos, `prueba_oakhaven_propuestas` da 3 fallos.

## Pendiente

- **Redmi:**
  - si las placas se leen a la distancia de juego (en el PC se ven como placas claras con la runa pequeña);
  - el aprendiz animado en el perfil bajo;
  - la losa con el dedo.
- **Decisión del usuario:** aprobar la misión como canon y encenderla por defecto (`ACTIVO_POR_DEFECTO` y la opción
  de Ajustes), o dejarla como propuesta.
- Sin búsqueda de caminos en la 3D: un toque lejano se para en el primer obstáculo. Es un comportamiento de siempre,
  no de esta misión.
