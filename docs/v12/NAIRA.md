# Naira, la Astrónoma del Eclipse: cuarto protagonista (PROPUESTA, NO CANON)

> **NO ES CANON.** Todo este documento es una propuesta hasta que el usuario lo apruebe. No cambia el juego: ni código,
> ni diálogos, ni hitos, ni recompensas, ni magias. Narrativa, 11-12/11/2026, rama LOCAL
> `claude/v12-fase2-naira-historia` (`D:\Aethelgard_v12_naira_historia`), desde `claude/rebelum-v12` @ `1b8f720`.
> Encargo: «Segunda gran fase», punto F (`docs/v12/RETOMAR.md`). «Naira» y «la Astrónoma del Eclipse» son nombres
> provisionales del usuario.
>
> **Aviso de destripes:** las secciones 1.5, 2.3 y 3 citan secretos de los actos II a IV para el equipo. Nada de eso
> puede salir en pantalla antes de su hito.

**Leyenda** (la misma de la biblia): **[C]** canon (juego o documento aprobado, con su fuente) · **[DIR]** decidido
por el usuario · **[P]** propuesta (de la biblia v2/v3, de la V11/V12 o de este documento) · **[D]** decisión pendiente
del usuario · **[U]** lo pide el encargo del usuario.

## 0. En una página

- **Quién:** Naira, 21 años, la última aprendiz del **Viejo Observatorio de Calid**, medio enterrado en el borde norte
  del Mar de Cristal. Cartografía el cielo, no la tierra: en sus cartas antiguas cada pueblo tenía su estrella, y tiene
  **cuarenta y una estrellas sin nombre**. Sabe dónde estaban esos lugares; no cómo se llamaban. «Las estrellas no se
  pueden raspar. Por eso las miro.»
- **Su magia:** la **astromancia del eclipse**: toma prestado lo que hay *entre* las luces del cielo (umbra, peso y
  frío de los astros). Donde Lya toma la luz, Naira toma la falta de luz. **Un eclipse tapa; nunca borra.** Esa es la
  frontera con la antagonista: la ceniza borra para siempre.
- **Su herida:** se ha organizado la vida para que nadie la eche de menos: «Si nadie me espera, la niebla no le quita
  nada a nadie». Su arco va de ahí a dejar que la recuerden. Es la regla del mundo hecha persona: nadie puede recordar
  por ti, pero alguien puede recordártelo (v2 §3.6, [P]).
- **Cuándo entra:** al empezar el acto II, en el Mar de Cristal (región ya aprobada y jugable en pruebas), tras «La
  caravana perdida». Misión de incorporación: **«La única noche que cabe en un día»** (hitos `nr_*`), con un combate
  en el que hay que protegerla mientras prepara su Eclipse. Después: **tres activos y una reserva**.
- **Lo que no puede saber ni decir:** que Érebo guarda corazones o recuerdos (acto III), qué es la niebla (acto III),
  que Kael es el niño del anillo (final del acto II), el secreto de Lya y el de Garon. Su teoría de Érebo es la
  **lectura falsa** («un eclipse con patas: un hueco que se come la luz»), y en el acto III reconoce que se equivocó.
- **Técnicas combinadas:** **Contrapeso** (Kael), **Equinoccio** (Lya), **Vigilia** (Garon) y **Doble Fondo**
  (Kael, tardía).
- **Riesgo principal:** confundirse con la antagonista de magia negra. Ninguna está aprobada; las candidatas son **Nyx**
  (el «Mago negro» de los datos, propuesto como rival del Cónclave) y **Madre Ceniza**. Si Naira ocupa el puesto de
  cuarto héroe, recomiendo que Nyx quede como rival y cambie de nombre (§1.6).

---

## 1. Contraste con la biblia

### 1.1 Fuentes leídas (11/11/2026, `1b8f720`)
- `D:\Aethelgard\CLAUDE.md`; `docs/v12/RETOMAR.md`; `docs/v12/NARRATIVA_DESIERTO.md` y `docs/v12/DISENO_V12.md`;
  `docs/v11/HISTORIA.md`; `docs/narrativa/voces_heroes.md`; `docs/biblia/rebelum_propuesta.md`.
- Biblia v2 y v3 en `D:\Aethelgard\docs\biblia\` (solo lectura; no están en esta rama).
- `D:\Aethelgard\DECISIONS.md` (D-030, D-032, D-033, D-037, D-038, D-048, D-060, D-062, D-071 a D-073).
- `docs/diseno/combate_ampliaciones.md` (familias Alba, Escarcha y Lumbre; P2 «Eclipse») y
  `docs/diseno/ciudades_y_lugares.md` §4 (compañeros: Nyx, Brea y Nerea); `docs/marca_rebelum.md`.
- Código (observado, no ejecutado): `grupo.gd` (`HEROES`, `EN_EL_GRUPO`, `SE_UNE_EN`, `activos()`), `combate.gd`
  (`MAGIAS`, dúos de la V11: Filo Arcano, Quiebra y Barrera Rúnica; `golpe_ruptura`), `artes.gd`, `menu_combate.gd`
  (`COLOR_HEROE`), `progreso.gd` (`hito()`, `poner_hito()`).

### 1.2 Dónde encaja sin romper nada

| Misterio del mundo | Cómo lo toca Naira | Qué no hace | Fuente |
|---|---|---|---|
| **La noche estrellada es lo olvidado** | Su oficio es mirar justo ahí | — | [C] `marca_rebelum.md`: «Noche estrellada y profunda […]: el misterio, lo olvidado» |
| **Nombres raspados** | En las cartas viejas del observatorio también rasparon los nombres de las estrellas. Ella los copia a mano | No sabe quién lo hizo ni por qué | [C] sello raspado (`progreso.gd`); [P] el Cónclave raspa (v3 §3.7, se sabe en el acto I) |
| **La niebla se traga lugares** | Desde la noche de la niebla, seis estrellas más se han quedado sin nombre en sus copias impresas; las suyas a mano resisten mejor | No explica qué es la niebla | [C] «La niebla ha vuelto a tragarse otra aldea» (`prologo.dtl`); [P] «lo escrito a mano resiste» (v2 §3.6) |
| **Fenómenos que la magia no explica** | Mide con plomadas de bronce que «el aire pesa» cerca de la niebla. No sabe qué pesa | Nunca dice «está llena de gente» antes del acto III | [P] este documento; pago con la Gran Verdad A (v3, [DIR]) |
| **Calid y sus sabios** | El Viejo Observatorio es una ruina del «Reino de los Sabios» | No nombra el Lente del Sol ni la máquina enterrada | [C] Calid (`mapa.gd`); [P] v3 §10.2.2 (pendiente) |
| **El brazalete que brilla** | Durante el eclipse es lo único que no se apaga: por eso los acompaña | No deduce que Kael es el niño del anillo | [C] `zona.gd`: «brilla un instante…» |
| **Érebo** | Lo estudia con fascinación y se equivoca: cree que devora la luz | Nunca habla de guardar ni de recuerdos antes de `hitos.verdad_erebo` | [DIR] D-033; v3 §5.3 y §5.5 |
| **Los peregrinos y el anillo partido** | En sus cartas hay una constelación de manos abiertas que guiaba a los peregrinos | No la relaciona con el Anillo de Rebelum | [C] pilar «gastado por miles de manos» (`progreso.gd`); [P] v2 §3.2 |

### 1.3 El origen que propone el usuario: qué encaja y qué choca

| Idea del usuario [U] | Veredicto | Por qué |
|---|---|---|
| Joven hechicera que estudia fenómenos oscuros y constelaciones olvidadas | **Encaja** | La marca ya hace de la noche estrellada «lo olvidado» [C] |
| Conserva registros de lugares cuyos nombres han desaparecido de los mapas | **Choca a medias** | Es exactamente **Nerea, la cartógrafa de nombres** (v2 §4.7 y `ciudades_y_lugares.md` §4.3, [P]); en el mismo desierto ya está **Ismena**, cartógrafa aprobada (`RETOMAR.md`); y el **Atlas de los Nombres** (v3 §10.2.1, [P]) ya es «el libro de nombres y caminos». Tres personajes con el mismo oficio se pisan. **Solución:** que registre el **cielo** (estrellas emparejadas con lugares), no los mapas de tierra |
| Fenómenos de la niebla que la magia tradicional no explica | **Encaja con límite** | Una investigadora seria se acercaría a la Gran Verdad (la niebla es Rebelum, acto III). Debe medir sin explicar, y equivocarse de forma creíble |
| Relación entre los recuerdos y las formas antiguas de magia | **Choca con D-033** | Una estudiosa de «recuerdos y magia» junto a una sombra que «roba corazones» haría la pregunta prohibida. **Solución:** estudia **nombres, pesos y luz**; nunca «recuerdos». La palabra queda fuera de su boca hasta el acto III |
| Su investigación la cruza con Kael, Lya y Garon; al principio los ve como una distracción | **Encaja** | La misión la hace literal: le han pisado la medición |
| Colaborar es la única forma de proteger lo que teme perder | **Encaja** | Es su arco (§2.3) |

### 1.4 Tres orígenes que sí encajan

| | A. La astrónoma del Viejo Observatorio (**recomendada**) | B. La desertora del Cónclave | C. La cronista de la Arboleda |
|---|---|---|---|
| **Quién** | Huérfana criada por Héspera, la última sabia del observatorio de Calid. Copia a mano las cartas del cielo. Tiene 41 estrellas sin nombre | Novicia del archivo del crematorio que se negó a quemar un libro de estrellas y huyó con él | Joven de la ciudad flotante que baja a estudiar la niebla desde abajo |
| **Encaja con** | Calid (acto II), la noche estrellada de la marca, el Mar de Cristal (aprobado), «lo escrito a mano resiste» | El Cónclave y Madre Ceniza; da un enemigo personal | La ciudad flotante, a la que la niebla no llega [C] |
| **Choca con** | Nada del canon. Añade un lugar nuevo [P] | **Nyx** (v2: aprendiz del Cónclave): dos magos negros salidos del mismo sitio; además, sabría demasiado del Cónclave antes de tiempo | Lumi «nunca ha bajado» y nadie baja [C, `isla.gd`]; la isla es del acto III y del Cristal del Cielo |
| **Riesgo** | Bajo: hay que construir el observatorio | Alto: confusión con la antagonista | Medio: pisa el misterio de la isla |

**Recomendación: A.** Cumple todo lo que pide el usuario (registros de lugares desaparecidos, constelaciones
olvidadas, fenómenos de la niebla) sin duplicar a Nerea ni a Ismena: **Ismena cartografía la tierra que cambia; Naira,
el cielo que no cambia.** Y la deja lejos del Cónclave, que es lo que más la separa de la antagonista.

### 1.5 Lo que Naira no puede revelar, ni deducir en voz alta

| Secreto | Desde cuándo puede hablar de ello | Antes de eso, cómo habla | Hito |
|---|---|---|---|
| Érebo guarda corazones o recuerdos (S2) | Acto III | Lectura falsa: «Es un eclipse con patas. Donde está, la luz falta.» Puede contar latidos de la gema como «hambre». Nunca «guardar», «conservar» ni «recuerdo» | `hitos.verdad_erebo` |
| La niebla es Rebelum; los Hollines, sus olvidados (S3) | Acto III | «La niebla no es humo: pesa. No sé qué pesa.» | `hitos.verdad_niebla` |
| Kael es el niño del anillo (S4) | Final del acto II | «Tu inmunidad es una anomalía. Me gustan las anomalías.» Nada de bebés, tapices ni el mural | `hitos.tapiz_encaja` |
| La profecía y el encargo de Lya (S6) | Final del acto II | No ha leído los libros prohibidos del templo. Nota que Lya calla algo; no pregunta (L1) | `hitos.secreto_lya` |
| Garon estuvo en el encargo del Águila y salvó al bebé (S7, S8) | Acto II (S7) y acto III (S8) | Nada. Su escena G3 exige `hitos.garon_recuerda` | `hitos.garon_recuerda` |
| Morgath es el caballero de brazo dorado (S9) | Final del acto III | **Ninguna constelación del cuervo** en sus cartas (el cuervo es el blasón de Morgath, v3 §3.5) | `hitos.morgath_revelado` |
| La máquina de Calid quemaba nombres (A2-01) y el Lente del Sol | Cuando lo vea el grupo | Sabe de «tubos bajo la arena» (`vid_tubos`, V11) y no sabe más | `hitos.calid_recuerdo` |
| Los dioses (Auralis, Neria, Kardun) y Elaria | Pendientes de aprobación (v3 §10.2) | Sus estrellas tienen nombres propios y modestos; ninguna lleva nombre de dios | — |

**Regla para quien escriba sus diálogos:** antes de cada frase sobre Érebo, la niebla o Kael, pasar la comprobación de
v3 §5.5 (la regla de oro) y fijar el hito en su timeline.

### 1.6 La antagonista de magia negra: quién puede ser y cómo diferenciarlas

No hay ninguna antagonista de magia negra aprobada. Estas son las tres figuras con las que Naira podría confundirse:

| Figura | Qué hay | Riesgo de confusión |
|---|---|---|
| **Nyx** | [C] datos de «Mago negro» en `grupo.gd`, color violeta `#8E5BD8` y un dibujo 2D de maga con falda (`combate.gd`). [P] Aprendiz del Cónclave y rival de Lya (v2 §4.5); propuesta como cuarto héroe en el acto III (D-073, pendiente) | **Muy alto**: mismo oficio, mismo puesto en el grupo y otro nombre corto en N |
| **Madre Ceniza** | [P] Archivera del Cónclave que raspa y quema nombres (v3 §3.7) | Medio: anciana, con hábito gris y oficio de archivo |
| **La Reina de los Espejismos** | [P] Jefa del fondo del Mar de Cristal (V11 §1.4; el mural aprobado deja leer «…de los Espejismos») | Bajo, aunque comparten región |

**Principio de diferenciación** (vale para texto, arte y combate):

| | Naira | La antagonista (Nyx o el Cónclave) |
|---|---|---|
| Qué hace su magia | **Tapa y pesa.** Un eclipse oculta la luz un rato; la luz sigue ahí | **Borra y quema.** La ceniza no vuelve |
| Con los nombres | Los copia a mano: «Lo apunto» | Los raspa |
| De dónde toma el poder | Del cielo, de lo que hay entre las luces | Del fuego del crematorio y del olvido como «piedad» |
| Cara | Siempre visible; gafas ahumadas sobre la frente | Capucha, hábito o sombra que tapa la cara |
| Color | Azul medianoche, bronce y verdín (§6) | Gris ceniza y violeta |
| Relación con la verdad | «Si me equivoco, lo apunto» | Certeza: «Olvidar es perdonar» |
| Con los espejismos | Los deshace: un eclipse enseña las estrellas que el sol tapa | — |

**Recomendación sobre Nyx [D]:** si Naira es el cuarto héroe, Nyx deja de serlo. Hay dos opciones:
- **A (recomendada):** Nyx queda como la rival del Cónclave, la «maga de ceniza», y es la antagonista de magia negra.
  Que cambie de nombre para que no haya dos «N» de cuatro letras con magia oscura (por ejemplo, **Cendra**, de «ceniza»)
  y que sus datos de `grupo.gd` sigan sin usarse.
- **B:** se retira Nyx; la antagonista será Madre Ceniza o su aprendiz.

En los dos casos, el hueco del modelo de Lya en el combate, que se llama `nyx3d`, sigue confundiendo: conviene
renombrarlo cuando se toque `combate.gd`.

### 1.7 Referencias externas: qué evitar
- **Nada de Final Fantasy X** (D-033).
- **FFIX:** nada del mago negro clásico (sombrero picudo, cara en sombra, ojos que brillan). Ni un ser creado para la
  guerra.
- **Expedition 33:** solo la elegancia melancólica. Naira no es una maga erudita que encadena cargas elementales que ella
  misma consume: sus marcas las gastan **los otros** héroes.
- Las técnicas, nombres y escenas de este documento son propios.

---

## 2. Ficha de personaje

### 2.1 Datos

| Rasgo | Propuesta [P] |
|---|---|
| Edad | 21 años: mayor que Kael, cerca de Lya. En la familia sería **la prima que vino de lejos** y se queda sin decir que se queda |
| Origen | La dejaron de bebé en la puerta del Viejo Observatorio de Calid. La crió **Héspera**, la última sabia, que murió de vieja hace dos inviernos («Me enseñó a mirar arriba. No me enseñó a mirar a los lados»). Desde entonces vive sola en la torre medio enterrada |
| Oficio | Astrónoma. Copia a mano el **Almanaque de las Estrellas sin Nombre**, las cartas en que cada pueblo tenía su estrella. Cuando una aldea se olvida, su nombre se borra de las copias impresas; la estrella sigue en el cielo |
| Lo que ha descubierto | Desde la noche de la niebla, seis estrellas más se han quedado sin nombre. Cerca de la niebla, sus plomadas de bronce caen más deprisa: «el aire pesa» |
| Motivación declarada | Medir el fenómeno antes de que se lleve su Almanaque |
| Motivación real | Que lo que ella copia no se pierda… y que no se pierda ella sin que nadie lo note |
| Herida | Nadie fue nunca a buscarla. Lo convirtió en método: no dejar a nadie que pueda echarla de menos |
| Deseo | Saber |
| Miedo | Que la niebla la encuentre y no quede ni el papel. Y, más hondo, que alguien la eche de menos y no pueda evitarlo |
| Conflicto interno | Para estudiar el olvido se ha aislado; y lo único que frena el olvido es que alguien te recuerde. **Su método es su problema** |
| Secreto | Ninguno de la historia principal. Su secreto pequeño: en la primera página de cada cuaderno escribe «Si lees esto y no me conoces, me llamo Naira. Apúntalo» |

### 2.2 Tabla de conocimiento (con los momentos de la v3 §3)

| Momento | Sabe | Cree o sospecha | Todavía no sabe |
|---|---|---|---|
| Al unirse (`nr_union`, inicio del acto II) | Que las aldeas tragadas se borran de las copias impresas; que el aire pesa cerca de la niebla; que el brazalete no se apaga en un eclipse; que alguien raspó las cartas viejas | Que Érebo devora la luz; que la niebla es una fuerza de la naturaleza que se podrá medir | Todo lo de §1.5 |
| M4 (final del acto II) | Lo que el grupo: Kael es el niño del anillo, el secreto de Lya, que Garon estuvo allí | Que la niebla «se come» lugares | Qué es la niebla; qué hace Érebo |
| M6 (final del acto III) | La niebla es Rebelum; Érebo guarda; Morgath. Entiende sus plomadas: «Pesaba porque estaba llena» | — | Cómo devolver los nombres a sus estrellas |
| M7 (final) | Los nombres de sus estrellas | — | — |

### 2.3 Arco por actos (sin destripes en pantalla)

| Acto | Arco |
|---|---|
| **II · Las Reliquias** (entra en Calid) | Distancia y datos: dice que viaja con el brazalete, no con ellos. Su teoría falsa de Érebo se refuerza con la pista 2 de Calid («se come las chispas»). Choca con Garon (G1) y con Lya (L1); las bromas de Kael la sacan de quicio (K1). A mitad del acto, primeras grietas: K2, L2 y G2. Al final, cuando el grupo se rompe (el secreto de Lya, Kael se va una noche), sus datos ya están y podría irse. Se queda: «La medición no ha terminado». Se le escapa un «nosotros»; Kael lo oye: «¿Nosotros?». Ella: «Errata» |
| **III · Los Ecos** | Sus certezas caen una a una: la niebla pesaba porque estaba llena; Érebo no se comía la luz (L3). Enseña a Garon que «no sé» no es una derrota (G3). Deja que Kael la vea con miedo y acepta su broma como escudo (K3). En el Confino reconoce lugares de su Almanaque y no puede nombrarlos: su peor momento |
| **IV · Los Nombres** | Pone la mano en el anillo, ella, que nunca quiso que la sostuvieran. Con la lluvia, sus estrellas recuperan el nombre y ella lo escribe. En la primera página del Almanaque, debajo de «me llamo Naira», tres letras distintas han escrito: «Te conocemos» |

### 2.4 Voz

**En una frase:** precisión fría aplicada a cosas calientes.

| Rasgo | Cómo suena |
|---|---|
| Ritmo | Frases medias y exactas. Corrige palabras: «No es oscuridad. Es luz que no ha llegado.» |
| Humor | Seco, por quedarse corta: «Es estadística. Pero sí.» No exagera (eso es de Kael) ni se ríe de sí misma en voz alta |
| Marcas | «Lo apunto.» · **«Interesante.»** cuando tiene miedo: lo dice despacio y escribe más deprisa (Kael lo descubre en K2) · usa «vosotros» para excluirse; su primer «nosotros» es un hito del arco |
| Con quien la cuida | Se incomoda y corta: «No me cuides. Me desconcentra.» |
| Cuando de verdad importa | Deja de corregir y dice algo sin medir: «Con.» |
| Diferencia con Lya | Ver la tabla siguiente |

**Diez frases de muestra** (todas caben en dos líneas de la caja):
1. «Un eclipse es la única noche que cabe en un día.»
2. «No es oscuridad. Es luz que todavía no ha llegado.»
3. «Interesante.» (con miedo)
4. «Las estrellas no se pueden raspar. Por eso las miro.»
5. «No me cuides. Me desconcentra.»
6. «Tengo una teoría. Os va a gustar menos que a mí.»
7. «Si me equivoco, lo apunto. Por eso me equivoco menos.»
8. «Un eclipse no apaga el sol. Lo tapa un rato.»
9. «Nadie ha venido nunca a buscarme. No empecéis ahora.»
10. «Lo escribo. Si se me olvida, que se acuerde el papel.»

En combate: «Tres turnos. Dadme tres turnos.» · «Prepárate. Esto va a pesar.»

**Distinta de Lya** [U]:

| | Lya | Naira |
|---|---|---|
| Ante lo desconocido | Le preocupa por los demás | Le fascina, sobre todo lo prohibido |
| Ante el riesgo | Lo evita para proteger: «No bromees.» | Lo mide y lo asume: «Por eso funciona.» |
| Cariño | Riñe porque quiere: «Kael…» | Le incomoda que la quieran; cuida sin decirlo (apunta lo que necesita cada uno) |
| Humor | Suave y tierno | Seco y exacto |
| Precisión | Precisión cálida: un dato y el siguiente paso | Precisión fría: un dato y una corrección |
| Magia | La luz y la cura | La falta de luz, el peso, el frío de los astros |

### 2.5 Gestos (propuesta para animaciones; las etiquetas se acuerdan con el coordinador)
- **Retrato** (`extra_data` del `.dch`): `naira_seria`, `naira_ironica` (media sonrisa torcida), `naira_apunta`
  (escribe en el Almanaque), `naira_mira` (mira arriba o mide con la mano extendida), `naira_incomoda` (se sube el
  cuello), `naira_interesante` (ojos abiertos y lápiz rápido: es miedo), `naira_sonrisa` (la casi sonrisa, escasa).
- **Esperas 3D:** `espera_astrolabio` (gira un aro de la esfera armilar), `espera_cuaderno` (apunta algo),
  `espera_mano_cielo` (mide grados con la mano a la altura del ojo), `espera_gafas` (se baja las gafas ahumadas y mira
  al sol).

### 2.6 Lo que no haría nunca
- Raspar o quemar un nombre, ni para salvarse.
- Usar o pedir prestada la sombra de alguien: la de Lya es de Érebo y no se toca.
- Mentir por escrito. De palabra, sobre lo que siente, sí: fatal.
- Fingir certeza sin datos, o reírse del miedo de otro.
- Dejar un cuaderno sin la primera página escrita.
- Invocar, ni hablar de «recuerdos» guardados antes del acto III.
- Romance con nadie del grupo (la familia de D-032 se mantiene) [D].

---

## 3. Relaciones: tres escenas por compañero

Cada escena es una timeline corta. La forma de lanzarla (posada, campamento o tras un combate) la decide el coordinador.
El hito `nr_*` se pone al terminar.

### 3.1 Kael: de no soportar sus bromas a leerle el miedo

**K1 · «Cuarenta pasos»** (acto II, primera acampada tras `nr_union`; hito `nr_k1`). Ella apunta; él busca su risa.
*Intención:* fricción. Ella no soporta sus bromas y él no soporta que lo ignoren.
> **Kael:** ¿Qué apuntas?
> **Naira:** Que haces un chiste cada cuarenta pasos.
> **Kael:** ¿Solo? Hoy estoy flojo.
> **Naira:** Y que nadie se ríe desde el paso veinte.
> **Kael:** Lya se ha reído.
> **Naira:** Lya es amable. Es un dato distinto.

**K2 · «Tres es miedo»** (acto II, mitad, tras un combate duro; hito `nr_k2`). Kael encadena bromas.
*Intención:* ella ve el miedo de él; él ve el suyo. Empate.
> **Kael:** ¿Has visto qué cara ha puesto? Casi le pido perdón.
> **Naira:** Tercer chiste. Antes de entrar hiciste uno.
> **Kael:** ¿Ahora me cuentas los chistes?
> **Naira:** Te mido. Uno es costumbre. Tres es miedo.
> **Kael:** …¿Y cuánto es «interesante»?
> **Naira:** ¿Qué?
> **Kael:** Lo dices cuando te tiemblan las manos.
> **Naira:** …Interesante.

**K3 · «Yo no te quito ojo»** (acto III, antes de un jefe; hito `nr_k3`; desbloquea **Doble Fondo**). Kael se ofrece de
cebo para que ella lance sin preparar.
*Intención:* ella acepta su broma como escudo, sabiendo que tiene miedo.
> **Kael:** Yo los entretengo. Tú lanza eso tan gordo.
> **Naira:** Te tiembla la mano.
> **Kael:** Es el frío.
> **Naira:** Hace calor.
> **Kael:** Es un frío muy mío.
> **Naira:** …Vale. Haz el payaso. Yo no te quito ojo.
> **Kael:** ¿Eso es cariño?
> **Naira:** Es astronomía. Se parece.

### 3.2 Lya: respeto intelectual y desacuerdo sobre la magia oscura

**L1 · «Todo se paga»** (acto II, tras su primer combate juntas; hito `nr_l1`).
*Intención:* dos inteligencias que se miden; Lya avisa, Naira devuelve la pregunta.
> **Lya:** Lo que lanzaste no salía de ti. ¿De dónde lo tomas?
> **Naira:** Del cielo. De la parte que no brilla.
> **Lya:** Lo que se toma, se paga. Siempre.
> **Naira:** Lo sé. Lo apunto todo. ¿Tú apuntas lo que pagas?
> **Lya:** …Más de lo que crees.
> **Naira:** Entonces estamos de acuerdo. Qué incómodo.

(«Más de lo que crees» es subtexto del secreto de Lya y no revela nada.)

**L2 · «Con, no por»** (acto II, tras la pista 2 de Érebo en Calid; hito `nr_l2`; desbloquea **Equinoccio**).
*Intención:* Naira quiere estudiar la sombra; Lya se cierra; pactan sin rendirse ninguna.
> **Naira:** Tu sombra se ha movido antes que tú. Dos veces.
> **Lya:** No es asunto tuyo.
> **Naira:** Todo lo que no entiendo es asunto mío. Es un defecto.
> **Lya:** Pues apúntalo como defecto. Y déjala en paz.
> **Naira:** Sin apuntes, entonces. Pero si un día quieres mirarla…
> **Naira:** …miro contigo. No por ti.
> **Lya:** Con.
> **Naira:** Con.

**L3 · «Me equivoqué»** (acto III, **solo con `hitos.verdad_erebo`**; hito `nr_l3`).
*Intención:* las dos se equivocaron con Érebo; se perdonan riéndose.
> **Naira:** Lo llamé «eclipse con patas». Un hueco que se come la luz.
> **Lya:** Yo lo llamé maldición. Toda la vida.
> **Naira:** Tú ganas. Te has equivocado durante más tiempo.
> **Lya:** ¿Eso es consolarme?
> **Naira:** Es estadística. Pero sí.
> **Naira:** Apunto: «Lya tenía razón en preocuparse. No en el motivo».
> **Lya:** Apunta que tú tampoco lo viste.
> **Naira:** …Ya está. Con letra pequeña.

### 3.3 Garon: desconfianza, certezas puestas en duda y respeto

**G1 · «Pesa»** (acto II, primer día; hito `nr_g1`).
*Intención:* Garon ve peligro; ella le discute las certezas.
> **Garon:** Ese hechizo. Lejos de ellos.
> **Naira:** ¿Por qué?
> **Garon:** Pesa.
> **Naira:** Exacto. Por eso funciona.
> **Garon:** Por eso no.
> **Naira:** Tus certezas también pesan. Nadie te pide que las sueltes.
> **Garon:** …Lejos de ellos.

**G2 · «Más peligrosa sin nadie delante»** (acto II, tras un combate en que Garon la cubrió sin que se lo pidiera;
hito `nr_g2`; desbloquea **Vigilia**).
*Intención:* él sigue desconfiando de la magia, pero no deja sola a quien la lanza.
> **Naira:** No te he pedido que te pongas delante.
> **Garon:** No.
> **Naira:** Sigues pensando que mi magia es peligrosa.
> **Garon:** Sí.
> **Naira:** ¿Entonces?
> **Garon:** Más peligrosa sin nadie delante.
> **Naira:** …Lo apunto.
> **Garon:** Bien.

**G3 · «Primera lección»** (acto III, **solo con `hitos.garon_recuerda`**; hito `nr_g3`).
*Intención:* se cambian los papeles: el hombre de las certezas aprende a no saber.
> **Garon:** Toda la vida seguro de lo que hice. Y no lo sabía.
> **Naira:** Bienvenido. Aquí nadie sabe nada y seguimos andando.
> **Garon:** ¿Cómo?
> **Naira:** Se apunta. Y mañana se mira otra vez.
> **Garon:** …Enséñame.
> **Naira:** Primera lección: «no sé» no es una derrota.
> **Garon:** Segunda.
> **Naira:** El que se pone delante también puede pedir ayuda.

---

## 4. Misión de incorporación: «La única noche que cabe en un día»

### 4.1 Dónde y por qué
- **Región:** el **Mar de Cristal** (Calid), ya aprobado y jugable en pruebas (`modo3d.gd`, `REGIONES[4]`). Es el primer
  lugar del acto II [C: orden de `progreso.gd`], así que llegan Kael, Lya y Garon (Garon desde PV-05): la continuidad
  no se toca.
- **Lugar nuevo [P]:** el **Viejo Observatorio de Calid**, una torre medio enterrada **al norte de las ruinas**
  (45, 18) del sector «La Orilla de Vidrio». Dos opciones de coste:
  - **barata (recomendada):** una mini-zona de unos 40 × 40 m, con el exterior de la torre y **una sola sala
    interior** (como la Gruta del Velo de la v2);
  - completa: un segundo sector, «La Cresta del Observatorio».
- **Requisito:** `mc_fin` («La caravana perdida» terminada). Así el buscador de metales ya es de Kael, y la misión lo
  reutiliza.
- **Por qué un eclipse:** el juego no tiene ciclo de día y noche (riesgo 11 de la v3). Un eclipse es de día, dura unos
  minutos y se hace con la luz de la región (como la tormenta de `clima.gd`) y un plano guiado hacia el cielo.
- **Lo que no toca:** el Lente del Sol y la máquina enterrada no se nombran; los hitos `mc_*` no cambian.

### 4.2 Pasos e hitos (`progreso.gd`, hitos; prefijo nuevo `nr_`)

| # | Hito | Qué pasa | Sistema que reutiliza |
|---|---|---|---|
| 1 | `nr_rumor` | En el campamento, Oren e Ismena hablan de «la de la torre», que les tiró una piedra y anuncia «noche a mediodía» | NPC del campamento (timelines nuevas) |
| 2 | `nr_observatorio` | En la torre, Naira los echa: le han pisado una plomada. Faltan tres, el viento las movió y el eclipse es hoy | Zona nueva |
| 3 | `nr_plomada_1` · `_2` · `_3` → `nr_plomadas` | Con el **buscador**, las tres plomadas de bronce: una junto a la torre, otra en el cañón y otra en **la arena que tiembla** (riesgo de Bramavidrio). Solo suenan desde `nr_observatorio` | `buscador.gd` (hallazgos únicos que esperan su hito, como el sello y la llave) |
| 4 | `nr_medicion` | Con las plomadas en su sitio, los deja quedarse «para no estorbar». La luz empieza a bajar | `clima.gd` (luz) |
| 5 | `nr_eclipse` | Oscurece. De la niebla del norte (solo se ve en el plano guiado) salen Hollines hacia la torre. Garon guarda la puerta; dentro, **el combate** (§4.4) | Combate fijo nuevo |
| 6 | `nr_catalogo` | Después: el brazalete no se apagó. Naira les enseña el Almanaque y la primera página | Timeline + examinar |
| 7 | `nr_union` | Se une «al brazalete». Primera vez del menú de **Formación**: «¿Quién espera esta vez?» | `grupo.gd` (`SE_UNE_EN`) |

Opcional: `nr_eclipse_perfecto`, si nadie golpeó a Naira mientras preparaba.

**Ficha de encargo** (formato de `encargos.gd`; para `datos/encargos_desierto.gd`, **sin añadir**):
`{"id": "enc_naira", "nombre": "La única noche que cabe en un día", "empieza": "hito:nr_observatorio",
"fin": "hito:nr_union", …}`, con pasos `plomadas`, `eclipse` y `catalogo`.

### 4.3 Diálogos clave (esquema)

Carpeta `res://dialogos/mar_cristal/`, timelines `nr_*`. En el acto II el grupo siempre es el trío; las variantes
`_lya` y `_solo` solo hacen falta para pruebas (la función `dialogo_mc()` de `NARRATIVA_DESIERTO.md` §2.1 vale igual).
Naira lleva retrato (`dialogos/personajes/naira.dch`) desde el principio y entra con `join … (vivo_pv)`, como Kael y
Lya; Ismena, Oren y Garon hablan sin `join`.

| Timeline | Cuándo | Contenido |
|---|---|---|
| `nr_campamento_rumor` | Hablar con Oren tras `mc_fin` | La torre, la piedra, «noche a mediodía» → `nr_rumor` |
| `nr_torre_puerta` | Llegar a la torre | Primer encuentro (abajo) → `nr_observatorio` |
| `nr_plomadas_espera` (`_1`, `_2`) | Hablar con ella mientras faltan plomadas | Prisa e ironía; una pista por plomada |
| `nr_medicion` | Con `nr_plomadas` | Los deja quedarse; la luz baja |
| `nr_eclipse_antes` | Al empezar el eclipse | Abajo; acaba en el combate |
| `nr_eclipse_despues` | Al ganar | El brazalete; «No me cuides» |
| `nr_catalogo` | Examinar el Almanaque | Las 41 estrellas; la primera página → `nr_catalogo` |
| `nr_union` | Hablar con ella con `nr_catalogo` | Se une → `nr_union` |

**Muestras, con su intención y su gesto** (los gestos de Naira son los propuestos en §2.5; los de Kael y Lya existen):

`nr_campamento_rumor`

| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Oren | La de la torre del norte… La saludé y me tiró una piedra. | chiste, para no admitir que se asustó | — |
| 2 | Ismena | Le gritaste «¡eh, tú!» desde abajo. Yo también te la tiro. | la riña cariñosa de siempre | — |
| 3 | Oren | Y me dijo: «Me estás tapando el cielo». | sigue el chiste | — |
| 4 | Kael | ¿De día? | se le despierta la curiosidad | `sorpresa` |
| 5 | Ismena | Dice que hoy habrá noche a mediodía. Yo no pregunto. | dato seco | — |
| 6 | Lya | Habla de un eclipse. | lo sabe y lo dice exacto | `firme` |

`nr_torre_puerta`

| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Naira | Alto. Habéis pisado mi medición. | echarlos con autoridad | `naira_seria` |
| 2 | Kael | ¿Tu qué? | descolocado | `sorpresa` |
| 3 | Naira | Una plomada de bronce. Bajo tu bota izquierda. | precisión como arma | `naira_seria` |
| 4 | Kael | ¿Y la derecha? | broma para recuperar terreno | `ligero` |
| 5 | Naira | La derecha solo pisa arena. Enhorabuena. | le gana la broma, sin sonreír | `naira_ironica` |
| 6 | Lya | Perdona. Podemos ayudarte a colocarla. | arreglar el daño | `preocupada` |
| 7 | Naira | Faltan tres. El eclipse es hoy. Iros: tardo menos sola. | rechaza la ayuda que necesita | `naira_ironica` |
| 8 | Garon | No. | se quedan | — |

`nr_eclipse_antes`

| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Naira | Cuatro minutos. Si alguien habla, que sea después. | concentración | `naira_mira` |
| 2 | Kael | ¿Y si viene algo? | broma nerviosa | `ligero` |
| 3 | Naira | Entonces hablad. Poco. | seca | `naira_ironica` |
| 4 | Garon | La puerta es mía. | se queda fuera: explica la reserva | — |
| 5 | Naira | Necesito tres turnos. Que nadie me toque. | el reto del combate, en una frase | `naira_interesante` |
| 6 | Lya | ¿Nadie? | la pregunta cálida | `duda` |
| 7 | Naira | Ellos, sobre todo. Vosotros, poco. | primera concesión | `naira_ironica` |

`nr_eclipse_despues`

| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Naira | Tu brazalete no se ha apagado. Todo lo demás, sí. | el dato que lo cambia todo para ella | `naira_mira` |
| 2 | Kael | Es su único truco. No se lo digas. | quitar peso | `brazalete` |
| 3 | Naira | Es la única anomalía de hoy que no ha querido matarme. | lo apunta | `naira_apunta` |
| 4 | Lya | ¿Estás herida? | la cuida | `preocupada` |
| 5 | Naira | No me cuides. Me desconcentra. | incomodidad ante el cuidado | `naira_incomoda` |

`nr_catalogo`

| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Naira | Cuarenta y una estrellas sin nombre. Cada una era un pueblo. | enseña lo que más le importa | `naira_mira` |
| 2 | Lya | ¿Y sus nombres? | dolor por lo perdido | `preocupada` |
| 3 | Naira | Se borraron del papel. Las estrellas no se dejan. | orgullo terco | `naira_seria` |
| 4 | Kael | «Si lees esto y no me conoces, me llamo Naira. Apúntalo.» | lee la primera página en voz alta | `sorpresa` |
| 5 | Naira | Es método. No drama. | corta la emoción | `naira_incomoda` |
| 6 | Garon | ¿Para qué? | pregunta directa | — |
| 7 | Naira | Por si la niebla me encuentra antes que nadie. | lo de verdad, de lado | `naira_seria` |
| 8 | Kael | Ya te hemos encontrado nosotros. | deja la broma: pocas palabras | `decidido` |

(Si pasa de seis globos, se parte en `nr_catalogo` (1-3) y `nr_catalogo_pagina` (4-8), al examinar la página.)

`nr_union`

| # | Quién | Frase | Intención | Gesto |
|---|---|---|---|---|
| 1 | Naira | No os acompaño a vosotros. Acompaño a ese brazalete. | salvar la distancia | `naira_seria` |
| 2 | Kael | Venimos en el mismo paquete. | aceptar el juego | `ligero` |
| 3 | Naira | Ya me lo temía. | ironía | `naira_ironica` |
| 4 | Garon | Cuatro. En combate, tres. | la regla, en parte militar | — |
| 5 | Kael | Por turnos. Como la cama grande de la posada. | eco de `oak_posada_grupo` | `ligero` |
| 6 | Garon | Yo duermo en el suelo. | eco: su frase de siempre | — |
| 7 | Naira | Por fin alguien sensato. | su primera casi sonrisa, para Garon | `naira_sonrisa` |

Todas las intervenciones de §3 y §4.3 miden 60 caracteres como mucho (medido con un recuento automático del
documento, 12/11): caben en dos líneas de la caja.

### 4.4 El desafío: «La medición» (combate fijo `nr_eclipse`)
- **Grupo:** Kael, Lya y Naira. Garon guarda la puerta: la historia enseña la reserva antes que el menú.
- **Enemigos:** tres Hollines con hacha y, en el segundo turno de Naira, dos más. Se reutiliza el Hollín de combate
  (`hollin`, en `combate.gd` `MODELOS`). Fondo de combate más oscuro.
- **Objetivo:** Naira empieza **preparando el Eclipse** (tres turnos suyos, a la vista: anillo y contador). Los Hollines
  van a por quien prepara (la regla se anuncia: «¡Van a por Naira!»).
  - Si le dan dos golpes, el Eclipse sale con la mitad de fuerza (la regla P2 de `combate_ampliaciones.md` §3.8).
  - Se puede ayudar: la Coraza de Kael o la Barrera de Lya hacen que el golpe «no cuente»; el Compás del Alba de Kael
    le adelanta el turno. Así enseña sus sinergias sin un texto largo.
  - Al lanzarlo, el Eclipse da a todos y los Hollines se deshacen.
- **Derrota:** como cualquier derrota; se reintenta desde antes del combate.
- **Érebo:** la INVOCACIÓN está disponible, como siempre (Lya está). Si se usa, Naira no comenta nada en este
  combate: su teoría llega después (L2).
- **Medición perfecta** (`nr_eclipse_perfecto`): ningún golpe a Naira durante la preparación → la Lente ahumada.

### 4.5 Recompensa
- **Naira se une**, con la técnica **Contrapeso** con Kael.
- **El Almanaque de las Estrellas sin Nombre** (objeto clave): abre la página «Observaciones» del Diario (§5.5).
- **Astrolabio de Bronce**: su arma inicial, de tipo cetro, para reutilizar el sistema de equipo.
- **Lente ahumada** (accesorio; solo con la medición perfecta): el primer hechizo con preparación de cada combate se
  prepara un 25 % antes.
- **Sin monedas.** «Los astrónomos no cobramos. Por eso estamos así.» El observatorio pasa a ser punto de descanso [D].
- Ningún hito, recompensa ni misión existentes cambian: todo lleva el prefijo nuevo `nr_`.

### 4.6 El grupo después: tres activos y una reserva
- **Kael siempre activo** [D]: es el protagonista, lleva el brazalete y las escenas fijas lo necesitan.
- **Se eligen dos** entre Lya, Garon y Naira en el menú Grupo («Formación»), fuera de combate. Cambiar de héroe en
  mitad de un combate (un «Relevo») queda para más adelante [D].
- **La reserva:** gana la mitad de la experiencia [D], conserva sus datos (D-060) y descansa con los demás.
- **En la historia y la exploración viajan los cuatro.** Las escenas, a partir de `nr_union`, cuentan con los cuatro;
  así no se multiplican las variantes de cada timeline. En 3D se dibujan los tres activos y la reserva sale en las
  escenas con su retrato. Si se quiere ver a los cuatro en 3D, hay que medirlo antes en el Redmi [D].
- **Coherencias:** con Lya en la reserva no hay INVOCACIÓN ni Armonía (es su sombra). Sin Garon, no hay Quiebra ni
  Vigilia. Cada formación cambia el combate de verdad.
- **Al unirse,** Naira llega al nivel medio del grupo, con sus puntos ya repartidos según su plantilla (§5.2), para
  que funcione desde el primer combate. Es un caso distinto de D-062 (pendiente), pero conviene decidirlos juntos [D].

### 4.7 Sistemas que tocaría (sin implementar)

| Sistema | Archivos | Qué haría |
|---|---|---|
| Hitos y guardado | `progreso.gd` | Hitos `nr_*` (ya caben en `hitos`). Clave nueva `formacion` al final de `CLAVES`, con valor por defecto |
| Grupo | `grupo.gd` | `HEROES["Naira"]`; `SE_UNE_EN["Naira"] = "nr_union"`; `activos()` con tres como máximo y la reserva. **Ojo:** `datos()` crea a todos los de `EN_EL_GRUPO` en cualquier partida, también en las antiguas y en la versión estable. Naira no puede entrar ahí tal cual: hace falta una lista aparte o una condición |
| Combate | `combate.gd`, `menu_combate.gd` | Modelo `naira3d`; estado «preparando» para héroes (hoy solo lo tienen los enemigos); ruta propia para sus familias (como `artes.gd`, sin pasar por las 12 protegidas); filas de DÚO nuevas; `COLOR_HEROE["Naira"]`; grupo fijo `nr_eclipse` al final de `GRUPOS`; regla «a por quien prepara» para ese combate |
| Magias | `artes.gd` o un archivo nuevo, `astromancia.gd` | Las familias de Naira con sus umbrales (`DE_HEROE`, `UMBRALES`) |
| Menús | `menus.gd` | «Formación» en el menú Grupo; Habilidades de Naira |
| Equipo y tienda | `inventario.gd`, `equipo_extra.gd`, `tienda.gd` | Astrolabio de Bronce, Lente ahumada y libros de nivel II |
| Diario | `diario.gd` | Ficha de Naira y página «Observaciones» |
| Encargo | `encargos.gd`, `datos/encargos_desierto.gd` | `enc_naira` |
| Región | `zonas3d/mar_cristal/*`, `buscador.gd`, `clima.gd` | Observatorio, plomadas (hallazgos únicos), luz del eclipse y plano guiado al cielo |
| Diálogos | `dialogos/mar_cristal/nr_*.dtl`, `dialogos/personajes/naira.dch`, retratos, `project.godot` (registro) | Textos de §3 y §4.3 |
| Sonido y música | `sonido.gd`, `musica.gd` | Contexto «eclipse» (silencio que crece) y efectos de sus familias |
| Arte | flujo de Blender (GLB; las versiones anteriores se conservan) | Modelo, esqueleto, clips y retrato (§6) |
| Pruebas | nuevas: `prueba_naira_mision`, `prueba_formacion`, `prueba_duos_naira`; ampliar `prueba_guardado` | Que Naira no aparezca antes de `nr_union` ni en partidas antiguas; que con su ausencia el combate dé la misma huella que hoy; que sus frases sobre Érebo exijan su hito |

---

## 5. Mecánicas (propuesta para el especialista de combate; las cifras se ajustan probando)

### 5.1 Lo que no cambia
- Las 12 magias protegidas, Esgrima, Embuir, Érebo, la Armonía y el ATB (D-048, CLAUDE.md). **Naira no aprende
  ninguna de las 12:** su magia va por una ruta propia, como las artes.
- Garon sigue sin magia (D-037), y Lya sigue siendo la única que cura, revive e invoca.

### 5.2 Estadísticas iniciales (plantilla de nivel 1, comparable a `grupo.gd` `HEROES`)

| Atributo | Kael | Lya | Garon | **Naira** | Lectura |
|---|---|---|---|---|---|
| Fuerza | 18 | 8 | 16 | **5** | Su golpe físico es el más flojo |
| Magia | 4 | 14 | 2 | **18** | La magia más alta, pero sus hechizos base hacen algo menos que los de Lya |
| Defensa | 6 | 4 | 12 | **3** | La más baja: su debilidad clara |
| Velocidad | 22 | 26 | 16 | **19** | Más lenta que Lya y que Kael: prepara, no corre |
| Vitalidad | 10 | 5 | 16 | **6** | Frágil |
| Espíritu | 4 | 12 | 2 | **12** | PM como Lya, con hechizos más caros |
| Suma | 64 | 69 | 64 | **63** | — |

`mult_fisico` 0,3 y `mult_magia` 1,0 (para sus familias). Datos de Nyx, como referencia sin usar: suma 70.

**Crecimiento** (3 puntos por nivel, como todos): se recomienda magia +1 y espíritu +1 cada nivel; velocidad +1 y
vitalidad +1 en niveles alternos; **defensa nunca**. Si se usa el reparto automático al unirse, sigue esta plantilla.

### 5.3 Su papel en el ATB: la que prepara
- **Estado nuevo «Preparando»** (los enemigos ya tienen «cargando»): algunos hechizos gastan su turno en prepararse, con
  un anillo y un contador visibles, y salen solos en su siguiente turno.
  - Si la golpean mientras prepara, el hechizo sale a la mitad. Un golpe que absorbe entero una barrera (Coraza de
    Escarcha, Barrera Rúnica) no cuenta.
  - Se puede cancelar.
- **Sinergias sin dúo:** el Compás del Alba de Kael le acorta la preparación; la Coraza de Kael y la Barrera Rúnica la
  protegen; Garon en guardia atrae golpes.
- **Su ritmo es más lento** (velocidad 19). Por eso carga la Armonía más despacio que Lya: llevarla tiene un coste real
  para Érebo.

### 5.4 Debilidades claras
1. **Defensa física baja:** los golpes físicos le duelen más que a nadie.
2. **PM:** sus hechizos de nivel III cuestan entre 28 y 40, y su espíritu no da para muchos. Tiene que alternar con
   Drenaje Arcano y objetos.
3. **Preparaciones:** un turno a la vista. Si la golpean, la mitad. Algunos enemigos del acto II (por ejemplo, la
   Tolvanera, sin aprobar) podrían ir «a por quien prepara», con aviso.
4. **Depende de la estrategia:** sin marcas ni estados, su daño directo es menor que el de Lya (Umbral 42 frente a
   Fuego 50).
5. **No corta golpes preparados por sí misma** (eso es de Quiebra y del daño de cualquiera). Prisión de Sombras
   retrasa, no corta.

### 5.5 Hechizos: cuatro familias, una firma y su progresión

Los nombres de la V11 (`docs/v11/HISTORIA.md` §1.3) y de la P2 (`combate_ampliaciones.md` §3.8) son del usuario y se
conservan todos. En su boca, «sombra» es siempre **la sombra de un astro** (umbra y penumbra son términos de los
eclipses), nunca la de una persona: así su magia no pisa a Érebo.

| Familia | Nivel | Nombre | PM | Objetivo | Efecto | Prep. | Se aprende |
|---|---|---|---|---|---|---|---|
| **Umbra** (daño) | I | Umbral | 7 | Uno | Daño 42 | — | Al unirse |
| | II | Lanza Sombría | 16 | Uno | Daño 95; atraviesa la guardia | — | Nivel 14 o libro |
| | III | Lamento Abisal | 40 | Todos | Daño 150 | 1 turno | Nivel 22 o tomo [nombre: ver V11 §1.4] |
| **Gravedad** (control) | I | Prisión de Sombras | 6 | Uno | Estado **Lastre**: su ATB carga un 30 % más despacio durante 3 turnos (jefes, 15 %); no se suma | — | Al unirse |
| | II | Caída del Firmamento | 24 | Todos | Tres pulsos de 30: ahora, tras la siguiente acción de un aliado y tras la otra; +50 % a quien tenga Lastre | — | Nivel 16 |
| | III | Cénit Quebrado | 36 | Uno | Daño 220; ×1,5 si tiene Marca o Hendido (y los gasta) | 1 turno | Nivel 24 u Observaciones |
| **Maldición** (debilitar) | I | Marca de Penumbra | 5 | Uno | El siguiente golpe de **otro** héroe le hace +50 % y gasta la marca (P2 proponía +60 %) | — | Al unirse |
| | II | Drenaje Arcano | 3 | Uno | Daño 30; Naira recupera en PM el 40 % del daño (15 como mucho) | — | Nivel 12 |
| | III | Noche Hendida | 22 | Todos | Estado **Hendido**: −25 % de defensa durante 3 turnos (jefes, −12 %) | — | Nivel 20 |
| **Astros** (elemental avanzado) | I | Estrella Roja | 9 | Uno | Fuego: daño 45 y una quemadura que dura el doble | — | Al unirse |
| | II | Estrella Helada | 20 | Todos | Hielo: daño 55; 25 % de congelar un turno (jefes, nunca) | — | Nivel 15 |
| | III | Estrella Azul | 34 | Todos | Rayo: daño 110; ×1,5 a quien tenga Lastre, Marca o Hendido | — | Nivel 26 o tomo |
| **Firma** | — | **Eclipse** | 30 | Todos | Daño 90 y estado **Penumbra** durante 2 turnos: los demás héroes les hacen +20 % | 1 turno | Al unirse (`nr_union`) |

- **Al unirse** tiene cinco: Umbral, Prisión de Sombras, Marca de Penumbra, Estrella Roja y Eclipse.
- **Menú:** como no tiene ninguna de las 12, sus cuatro familias ocupan las filas de I · II · III (cuatro filas, como
  Lya hoy). Eclipse y DÚO, en sus pestañas. Prisión de Sombras tiene 18 letras: comprobar que cabe en el botón (V11).
- **Comparación con Lya en el acto II** (nivel 10): Infierno hace 140 a todos por 34 PM, al momento. El Eclipse hace
  90 por 30 PM y un turno de preparación, pero sube un 20 % el daño de los otros dos. No la eclipsa: juegan distinto.
- **Investigación: «Observaciones».** Fenómenos del cielo que se examinan en el mundo, uno o dos por región. Son
  detalles nuevos, con una frase de 15 palabras como mucho, guardados en la lista aparte de `lore_visto`. Cada tres
  observaciones, adelanta un nivel III o mejora el Eclipse un 10 % (tres veces como mucho). Es la «progresión con
  investigación» que pide la escuela de magia negra (`RETOMAR.md`, punto E). La escuela completa la diseña ese
  encargo; aquí está lo que necesita Naira.

### 5.6 Técnicas combinadas

Siguen las reglas de los dúos de la V11 (`combate.gd`): el compañero, en pie y con la mitad de su ATB, presta su turno.

| Técnica | Con | Pestaña DÚO de | Coste | Efecto | Por qué (la relación) | Se aprende |
|---|---|---|---|---|---|---|
| **Contrapeso** | Kael | Kael | 8 PM de Naira y su turno | Naira le quita el peso y se lo devuelve de golpe: el ataque de Kael más el 50 % del Umbral de Naira; rompe la guardia. Con Lastre, +30 % (y gasta el Lastre) | Ella pone peso a su ligereza; él le quita peso a ella | `nr_union` |
| **Equinoccio** | Lya | Lya | 10 PM de Lya y el turno de Naira | Naira golpea a uno (Umbral ×1,2); Lya convierte la mitad del daño en cura para el grupo en pie (el 20 % de la vida máxima de cada uno, como mucho) | Su desacuerdo, resuelto: lo que la oscuridad toma, la luz lo devuelve. Día y noche a partes iguales. No usa la sombra de Lya | `nr_l2` |
| **Vigilia** | Garon | Naira (al empezar una preparación) | 6 PM de Garon y su turno | Garon se pone delante: hasta que Naira lance, los golpes que iban a ella van a él (a la mitad, como Defender). Cada golpe que encaja suma +10 % al hechizo (+30 % como mucho) | Desconfía de su magia, pero no la deja sola; ella confía en su certeza. El soldado y la astrónoma: los dos velan | `nr_g2` |
| **Doble Fondo** | Kael | Naira | El coste del hechizo y el turno de Kael. Una vez por combate | Kael provoca: hasta su siguiente turno, los enemigos van a por él (con la defensa de Defender). Naira lanza **sin preparar** un hechizo que la necesita | Ella ha aprendido a leer su miedo y acepta su broma como escudo | `nr_k3` (acto III) |

Las cuatro tienen nombre propio, no salen de otros juegos y no tocan a Érebo ni la Armonía (cargan la Armonía como
una acción normal).

### 5.7 Equilibrio: criterios que se pueden comprobar
1. **Lya** sigue siendo la única que cura, revive e invoca. Naira no aprende las 12.
2. **Kael** sigue siendo el mejor daño físico a uno: Marca, Penumbra y Contrapeso lo hacen mejor, no innecesario.
3. **Garon** sigue siendo el único tanque y el de Quiebra; Vigilia le da más trabajo, no menos.
4. **Para combate (medible con la huella del combate):** en los encuentros del acto II, un trío con Naira tarda entre
   un 15 % más y un 15 % menos de turnos que el trío de siempre. El daño de Naira sin preparar no pasa del de Lya con
   sus elementales; con preparación completa, 1,3 veces como mucho.
5. **Ninguna formación queda bloqueada:** sin Lya, objetos; sin Garon, la Coraza de Escarcha de Kael y el Lastre.
6. **Sin Naira en el grupo, el combate da exactamente lo mismo que hoy** (huella C0).

---

## 6. Diferenciación visual (para el especialista de arte)

### 6.1 Paleta

| Uso | Color | Hex |
|---|---|---|
| Manto y prenda principal | Azul medianoche | `#1B2340` |
| Forro, botas y guantes | Negro tinta | `#0F1018` |
| Instrumentos y cierres | Bronce viejo | `#A27B45` |
| Pátina del bronce; **color de interfaz** (`COLOR_HEROE`) | Verdín | `#5FB49C` |
| Estrellas cosidas, marcas de tiza | Blanco hueso | `#E9E2CF` |
| Acento fino (solo el aro de la esfera) | Oro pálido de corona de eclipse | `#E8D9A0` |

El verdín es libre en la interfaz: Kael es celeste `8FD3FF`, Lya dorada `E8C46A`, Garon granate `9E2B2B` y Nyx violeta
`8E5BD8`.

**Colores prohibidos en ella:** violeta (Érebo, Nyx, la niebla de la marca), carmesí (Érebo, Garon), blanco
dominante (Lya), gris ceniza (el Cónclave).

### 6.2 Silueta y accesorios
- **El aro:** una esfera armilar de bronce de tres aros (unos 50 cm), a la espalda; pasa a la mano al lanzar. Es lo que
  se reconoce a 20 m de cámara.
- **Manto corto asimétrico,** a un hombro, con el forro bordado de un mapa del cielo que se ve al girar. Cuello alto.
- **Pantalón y botas de viaje** del desierto. Nada de vestido (Lya) ni de falda (el dibujo de Nyx).
- **El Almanaque:** un libro grueso de tapas azules con cierre de bronce, colgado de la cadera con una correa.
- **Gafas ahumadas redondas** subidas a la frente: su icono.
- **Pelo oscuro,** corto o recogido, con un lápiz clavado en el moño. Tiza en los dedos.
- **La cara, siempre visible:** sin capucha ni máscara (eso es de la antagonista y de Érebo).
- **Frente a Lya:** líneas rectas y compactas contra las curvas y el vuelo de Lya; bronce contra plata y flores.

### 6.3 Tres direcciones de concepto
1. **«La Vigía del Desierto».** Telas color arena sobre el azul medianoche, gafas en la frente, la esfera a la espalda
   como el armazón de una mochila, el Almanaque atado. Es la más práctica y la que mejor encaja en Calid. Riesgo: que se
   vea apagada y poco mágica.
2. **«La Erudita de la Torre».** Abrigo largo con el forro estrellado, cuello alto y aros de bronce que orbitan
   despacio alrededor de su mano al lanzar. Es la más mágica. Riesgos: cuesta más (la tela y los aros animados) y, si se
   oscurece demasiado, parece una hechicera villana; hay que dejarle la cara limpia y los acentos de verdín.
3. **«La Cazadora de Eclipses».** Más ligera y asimétrica: una manga negra con constelaciones dibujadas en tiza (las
   repinta cada mañana), un sextante en forma de media luna como foco y una capa corta. Es la mejor para la acción.
   Riesgo: la media luna lleva a «sacerdotisa lunar» y a figuras de otras sagas.

**Recomendación:** la 2 con lo práctico de la 1 (gafas, botas, correa del libro) y la esfera a la espalda, que pasa a
la mano al lanzar. Las tres deben respetar el presupuesto de los héroes y el flujo de Blender del proyecto (GLB,
versiones anteriores conservadas, nada se da por definitivo).

---

## 7. Decisiones pendientes del usuario
1. **¿Se aprueba Naira** como cuarto héroe, con el origen A (el Viejo Observatorio de Calid)?
2. **Nyx:** ¿rival y antagonista con otro nombre (recomendado; por ejemplo, Cendra), o se retira? ¿Se renombra el hueco
   `nyx3d`?
3. **¿Cuándo entra?** Al empezar el acto II, en el Mar de Cristal (recomendado), o más tarde.
4. **Formación:** ¿Kael siempre activo? ¿Cuánta experiencia gana la reserva? ¿Se ven los cuatro en 3D o solo los tres
   activos?
5. **Nivel al unirse:** ¿el medio del grupo con su plantilla, decidido junto con D-062?
6. **Observatorio:** ¿mini-zona con una sala (recomendado) o un segundo sector? ¿Punto de descanso?
7. **Nombres:** Naira, Héspera, el Almanaque, las técnicas (Contrapeso, Equinoccio, Vigilia, Doble Fondo), los estados
   (Lastre, Hendido, Penumbra) y los tres hechizos nuevos de Astros (Estrella Roja, Helada y Azul).
8. **Lamento Abisal:** la V11 lo dejaba solo si el Emperador Slime pierde «del Abismo». ¿Se confirma?
9. **¿Sin romance para Naira?** (Recomendado: la familia de D-032.)
10. **La Reina de los Espejismos:** ¿se siembra que «los espejismos no aguantan un eclipse», para que Naira cuente en ese
    jefe?

---

## 8. Registro
- 11-12/11/2026: documento nuevo. No se ha tocado código, diálogos, escenas, datos ni `project.godot`. No se ha
  ejecutado Godot: todo lo del juego es **observado en el código** (`1b8f720`) o **pendiente de verificar**.
- Comprobado por búsqueda en esta rama y en la biblia v2 y v3 (11/11, `1b8f720`): «Naira» solo aparece en `RETOMAR.md`,
  y Héspera, Lastre, Contrapeso, Equinoccio, Vigilia, Doble Fondo, plomada, Almanaque y Estrella Roja, Helada y Azul no
  aparecen. «Eclipse» solo aparece en la P2 de combate, en la lista de la V11 y en el nombre interno del hacha del
  Hollín (`goblin_3d.gd`, «Abyssal Eclipse Reaver», que no se ve en el juego).
