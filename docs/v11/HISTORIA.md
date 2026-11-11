# Historia de la V11: PROPUESTA de narrativa (no es canon)

> **Todo este documento es una PROPUESTA.** Nada es canon hasta que el usuario lo apruebe. No cambia el juego:
> ni diálogos, ni hitos, ni recompensas, ni magias. Narrativa, 11/11/2026, rama LOCAL `claude/v11-narrativa`
> (`D:\Aethelgard_v11_narrativa`), desde `claude/rebelum-v11` @ `4e1f734`.

**Fuentes revisadas** (observado en los documentos y en el código de esta rama):
- biblia v2 y v3 (`D:\Aethelgard\docs\biblia\`), la propuesta v1 y `docs/narrativa/voces_heroes.md`;
- `docs/v9/`, `docs/v10/`, los informes de narrativa (`docs/memory/agents/narrativa*.md`) y `DECISIONS.md`
  (D-030, D-032, D-037, D-038, D-071);
- código: `mapa.gd` (lugares), `encargos.gd` y `datos/encargos_*.gd`, `artes.gd`, `combate.gd` (`INVOCACION`),
  `grupo.gd` y `ciudades/oakhaven.gd` (nombres de vecinos y lugares).

**Reglas que se han respetado:** nada de que Érebo guarda corazones o recuerdos (eso es del acto III); los secretos de
Érebo no se tocan; nada de Final Fantasy X; FFIX, FFVII y Expedition 33 solo como principios; el futuro personaje de
magia negra **no** recibe identidad aquí.

## 0. Qué construir primero (orden recomendado)

1. **El Brumín Rizo y su encargo en Pastos Verdes** (§2). Usa una zona que ya existe, el sistema de encargos y un
   modelo pequeño. Es lo más barato y lo que antes se ve.
2. **Los nombres** (§1): fijarlos antes de modelar o programar nada que los use.
3. **El encargo arqueológico del Mar de Cristal** (§3), cuando exista el primer sector del desierto.
4. **Los ganchos personales** (§4), para escribirlos más adelante.

## 1. Los nombres propuestos por el usuario, contra el canon

Leyenda: **[C]** canon (texto del juego o decisión aprobada) · **[P]** propuesta de la biblia, no canon.

### 1.1 Lugares, pueblos y deporte

| Nombre | Con qué choca o se parece | Veredicto | Propuesta |
|---|---|---|---|
| **Brumines** | «Bruma» ya está en el **Océano de Bruma** [C: `mapa.gd`], en la **coneja Bruma** [P: biblia v2 y v3, PV-15] y en la bruma gris del barranco [P: PV-11]. El final «-ín / -ines» recuerda a **Hollín / Hollines** [C], las sombras de los borrados | **Encaja, con cuidado** | Singular **Brumín** (con tilde), plural **Brumines**. Que nazcan de la **bruma blanca de las cascadas**, nunca de la niebla gris: colores claros, ojos con brillo y silueta redonda, para no confundirlos con los Hollines. Si se aprueban, la coneja Bruma [P] podría cambiar de nombre (por ejemplo «Pelusa») para no repetir |
| **Mar de Cristal** (gran desierto) | El canon ya tiene **un** desierto: el **Mar de Arena de Calid** [C: `mapa.gd`], con el Lente del Sol y la máquina enterrada [C: `progreso.gd`]. «Cristal» también es el **Cristal del Cielo** [C: `isla.gd`] | **Cambiar el encaje, no el nombre** | No crear un segundo desierto. **El Mar de Cristal es el corazón del Mar de Arena de Calid:** llanuras donde la arena se fundió en vidrio por un calor antiguo. Calid sigue siendo la región del mapa; el Mar de Cristal, su parte más honda. Así no se toca `mapa.gd` y el nombre cuenta algo (§3) |
| **ESPIRAL** (deporte) | Nada en el canon. «Espiral» solo aparece en el remolino del Portal del Vacío [C], sin nombre | **Encaja** | En los textos, «**la Espiral**» (en español es femenino); «ESPIRAL», en el logo o el menú. Diseño propio y sencillo: se juega en la calle y los niños no saben de dónde viene. Narrativa revisará las reglas para que no se parezca a deportes de otras sagas |

### 1.2 Invocaciones

Hoy solo hay una invocación: **Érebo**, de Lya, con la Armonía [C: D-038; `combate.gd`, `INVOCACION`]. Garon no
invoca [C: D-037]. Propuesta común: las nuevas **no nacen de la sombra de Lya** (eso es solo de Érebo y no se toca);
responden a una llamada en su región. Quién las invoca queda para el usuario (§5).

| Nombre | Con qué choca o se parece | Veredicto | Propuesta |
|---|---|---|---|
| **Auralis** (Ciervo del Alba) | **Auralis** es el dios de la luz y el amanecer en la biblia v3 [P: §10.2.3, idea del propio director], con el Lente del Sol por corazón. «Alba» es también una familia de artes de Kael [C: `artes.gd`] | **Dudoso** | Si se aprueban los dioses de la v3, el invocado sería **el Ciervo del Alba, el heraldo de Auralis**, y el dios conserva su nombre. Si el usuario prefiere que Auralis sea el ciervo, la v3 tendría que renombrar a su dios. Encaja bien con Pastos Verdes o con Calid (el Lente del Sol) |
| **Varkhûn** (Serpiente de Ceniza) | «Ceniza» está muy cargada: Guerra de las Cenizas, Cónclave de las Cenizas, Madre Ceniza, Abismo de Ceniza, Incienso de Ceniza [C y P]. En la v2, la ceniza es «el residuo de los nombres quemados» [P]. Suena algo parecido a **Kardun** (dios de la v3) [P] | **Encaja, con cuidado** | Bonito y con peso, pero su texto **no** debe decir qué es la ceniza (eso es historia de los actos II a IV). La «û» está en las fuentes del juego (Roboto, Saira y Cormorant cubren el latín extendido): **pendiente de verificar en pantalla** |
| **Nimara** (Señora de las Mareas) | Se parece a **Neria**, diosa de la memoria en la v3 [P]. Lugar natural: el Templo Sumergido y el Océano de Bruma [C] | **Encaja** | Mantener. Si se aprueba Neria, conviene que nunca salgan juntas en el mismo texto, para no confundirlas |
| **Zerath** (Vigía de Cristal) | «Vigía» recuerda a los **centinelas de ámbar** [P] y al Guardián de piedra [C]. «Cristal», al Cristal del Cielo [C] | **Encaja** | Hacerlo **el guardián del Mar de Cristal** (§3): un vigía de vidrio que mira el desierto. Encaja con el sitio y no pisa a los centinelas si su forma es claramente distinta (vidrio, no piedra ni ámbar) |

### 1.3 Magias oscuras

El personaje de magia negra **no tiene identidad aquí**. En `grupo.gd` sigue un «Mago negro» (Nyx) antiguo [C, sin
usar como héroe]: el usuario decidirá qué hacer con él. Las magias nuevas se añaden sin cambiar las de siempre
[C: D-071]. Ninguno de estos nombres habla de corazones ni de recuerdos, y así debe seguir su descripción.

| Nombre | Con qué choca o se parece | Veredicto | Propuesta (y función que sugiere el nombre, para combate) |
|---|---|---|---|
| **Umbral** | En español, «umbral» es sobre todo «la entrada de una puerta». Doble sentido (umbra + umbral) | **Encaja** | Mantener. Función: el primer hechizo oscuro, a un enemigo |
| **Noche Hendida** | Nada | **Encaja** | Mantener. Función: golpe que parte la defensa (baja defensa) |
| **Marca del Vacío** | **El Vacío** ya es del enemigo: hachas del Vacío y Portal del Vacío [C]; en la v2, «la ausencia» que venera el Cónclave [P]. Ligaría el poder del héroe al del enemigo, y eso fijaría su identidad | **Cambiar** | **Marca de Penumbra.** Función: marca a un enemigo y el siguiente golpe oscuro hace más daño |
| **Lanza Sombría** | Nada | **Encaja** | Mantener. Función: daño fuerte a uno |
| **Eclipse** | Nada (contrasta bien con el Lente del Sol y con Auralis) | **Encaja** | Mantener. Función: a todos los enemigos |
| **Prisión de Sombras** | El Guardián tiene «Raíces que aprisionan» [C: `combate.gd`]; no choca | **Encaja** | Mantener. Función: retrasa el turno (ATB) de un enemigo. Es el nombre más largo (18 letras): **pendiente de verificar** que cabe en el botón del menú del móvil |
| **Drenaje Arcano** | Nada en el canon. «Drenaje» suena algo a tubería | **Encaja** | Mantener (se entiende en un juego). Alternativa si se quiere más poesía: «Sorbo Arcano». Función: quita PM al enemigo y los da a quien lo lanza |
| **Lamento Abisal** | «Abismo» ya está en el **Abismo de Ceniza** (fortaleza final) [C], en «¡FURIA DEL ABISMO!» de Gorthor [C] y en el Emperador Slime del Abismo | **Encaja, con cuidado** | Mantener solo si el Slime pierde «del Abismo» (§1.4), para no repetir. Función: la más fuerte, a todos |

### 1.4 Jefes

| Nombre | Con qué choca o se parece | Veredicto | Propuesta |
|---|---|---|---|
| **El Campanero del Porvenir** | Oakhaven tiene la **Torre de la Campana** [C: `ciudades/oakhaven.gd`]; la v3 pone una campana junto al puente de Pastos Verdes [P: PV-11]. «Porvenir» recuerda al orbe que enseña futuros [experimental, `bq_futuros`] | **Encaja** | Mantener. Las campanas ya son una semilla del mundo: que su campana «toque lo que va a pasar» y avise de su próximo ataque (aviso de un turno, como los jefes de ahora). Dónde: **por decidir**; no en la Torre de Oakhaven en el acto I |
| **La Reina de los Espejismos** | El **Valle de los Ecos** tiene espejos de agua y «Kael se enfrenta a sí mismo» [C]; la v3 tiene una ciudad reflejada en el río [P]. Un espejismo no es un espejo | **Encaja** | Hacerla **la jefa del fondo del Mar de Cristal** (no del primer sector). Sus espejismos enseñan oasis y caminos falsos, nunca a los héroes duplicados, para no pisar el Valle de los Ecos |
| **Emperador Slime del Abismo** | «del Abismo» lo ata al **Abismo de Ceniza**, la fortaleza final [C], y lo vuelve un jefe del final. Los slimes de la biblia son algo pequeño y vivo, «una gota de lluvia sobre una hoja al sol» [P]. El «rey de los slimes» ya existe en otras sagas (no Final Fantasy) | **Cambiar** | **Emperador Slime**, como ya se llamaba en la V9 (`docs/v9/RETOMAR.md`). Jefe opcional y con humor, en charcas o en una gruta húmeda. Diseño propio: que no sea una pila de slimes que se juntan |

## 2. El primer Brumín: Rizo

### 2.1 Quién es
- **Los Brumines** [propuesta mínima]: gente menuda que vive en la bruma blanca de las cascadas. Recogen lo que se
  cae al río y lo guardan en montones ordenados. Casi nadie los ve. No se dice más de ellos: no tienen secreto que
  revelar todavía.
- **Rizo** vive bajo la cascada de Pastos Verdes, junto al río. Lleva la cuenta de todo lo que guarda.

### 2.2 Aspecto (para gráficos)
- **Tamaño:** por la rodilla de Kael, unos 0,55 m (Kael mide 1,7 m).
- **Forma:** cuerpo redondo como una pera, sin cuello; brazos cortos y pies redondos. Camina dando saltitos.
- **Lo que le da nombre:** un **rizo de bruma** en la cabeza, una espiral sólida y estilizada (no partículas).
- **Cara:** ojos grandes y oscuros con un punto de luz blanco; boca pequeña, solo se ve al hablar o al estornudar.
- **Ropa:** bufanda de musgo verde y una bandolera de junco trenzado de la que asoman cosas (un botón, una pluma).
- **Colores:** blanco hueso y azul bruma pálido en el cuerpo; verde musgo; ocre en el junco.
- **Para el móvil:** cuerpo opaco con un borde claro (luz de contorno) en vez de transparencia; un solo material;
  unos 2 000 triángulos; textura de 512 px.
- **Gestos que pide** (para animaciones): saludar con los dos brazos; **estornudar soltando una nubecilla de bruma**
  (su gesto propio, cuando se pone nervioso); esconderse detrás de una piedra; contar con los dedos; ofrecer algo con
  las dos manos.
- **Que no se parezca a:** ningún ser con alas, pompón o pelo; no reparte cartas ni guarda la partida; no tiene
  muletilla inventada al final de cada frase. Tampoco a un Hollín: nada oscuro ni sin cara.

### 2.3 Personalidad
- Curioso y miedoso a la vez: se acerca a todo y luego se esconde.
- **Cuenta las cosas** (es su forma de hablar): números exactos, incluso de sus miedos.
- Tierno sin ser bobo: cree que todo lo perdido tiene a alguien que vuelve a buscarlo.
- Le da miedo Garon (es grande y suena a metal); a Lya le habla de igual a igual; con Kael se pica.

### 2.4 Diálogo (frases cortas para el móvil; todas caben en dos líneas de la caja)

| # | Quién | Frase | Intención | Gesto o retrato |
|---|---|---|---|---|
| 1 | Rizo | ¡Quietos! Ahí no. Ahí hay un botón. Bueno, había. | Presentarse con un susto | `brumin_alto` (brazos arriba) [nuevo] |
| 2 | Rizo | Soy Rizo. Guardo lo que se cae al río. Me faltan tres cosas. | El encargo, en una frase | `brumin_contar` [nuevo] |
| 3 | Kael | ¿Tres? ¿Y cuántas tienes? | Pincharle | `ligero` |
| 4 | Rizo | Cuatrocientas doce. Pero esas tres eran las bonitas. | Humor y cariño | `brumin_contar` |
| 5 | Rizo | (a Garon, escondido) El grande no me pisa, ¿verdad? | Miedo | `brumin_esconderse` [nuevo] |
| 6 | Garon | No. | Seco, protector | (sin retrato) |
| 7 | Lya | ¿Y para qué guardas todo eso? | Curiosidad de Lya | `duda` |
| 8 | Rizo | Para esperar. Siempre vuelve alguien a buscar algo. | El corazón del personaje, de lado | `brumin_ofrecer` [nuevo] |
| 9 | Rizo | (al devolverle las tres) Un botón, una llave, una canica. Ya estoy entero. | Alivio | `brumin_alto` |
| 10 | Rizo | (si Kael rechaza la canica) Entonces la guardo yo. Por si vuelves a buscarla. | Cierre tierno | `brumin_ofrecer` |

Frase de estornudo (comentario al explorar, si Kael se acerca mucho): «¡Achís! Perdón. Me pasa cuando hay gente.»
Gesto: `brumin_estornudo` [nuevo]. Las etiquetas `brumin_*` son **propuestas**: se acuerdan con el coordinador y con
animaciones; las de los héroes ya existen (`docs/narrativa/voces_heroes.md`).

### 2.5 Encargo: «Las tres cosas bonitas» (Pastos Verdes)
- **Cuándo aparece:** con Garon en el grupo (`hito:pv_05`), para que estén los tres héroes y no se rompa la
  continuidad (Kael solo hasta PV-03, Lya desde PV-03, Garon desde PV-05).
- **Dónde:** junto al río, al pie de la cascada. El punto exacto lo fija exploración, a 2,5 m o más de lo que ya se
  examina.
- **Pasos:**
  1. Hablar con Rizo. → `hito:brm_inicio`
  2. **El botón de latón**, entre las piedras junto al puente. → `hito:brm_boton`
  3. **La llave pequeña**, en las ruinas, bajo una piedra que Garon aparta (como las ramas de «Canela se ha
     perdido»). → `hito:brm_llave`
  4. **La canica de vidrio**: un Slime dormido en la pradera se la ha tragado. Kael lo pincha y el Slime la escupe
     (escena corta, sin combate nuevo). → `hito:brm_canica`
  5. Volver con Rizo. → `hito:brm_fin`
- **Pequeña decisión** (`decisiones.rizo_canica`): Rizo ofrece la canica.
  - `kael`: Kael se la queda (objeto de recuerdo, sin efecto en combate, para no tocar el equilibrio);
  - `rizo`: Kael le dice que se la quede; Rizo da una Poción más y, si se vuelve, dice: «Cuatrocientas quince.
    Ninguna se ha ido.»
- **Recompensa propuesta:** 2 Pociones (las mismas que «Canela se ha perdido»); sin oro, porque un Brumín no tiene.
- **Datos** (formato de `encargos.gd`; para `datos/encargos_pastos.gd`, **no añadido**: lo decide el coordinador):

```gdscript
{"id": "enc_brumin", "nombre": "Las tres cosas bonitas", "quien": "rizo",
	"resumen": "Rizo, un Brumín de la cascada, ha perdido las tres cosas más bonitas de su montón.",
	"empieza": "hito:brm_inicio", "fin": "hito:brm_fin",
	"pasos": [
		{"id": "boton", "texto": "Busca un botón de latón entre las piedras del puente.", "hecho": "hito:brm_boton"},
		{"id": "llave", "texto": "Busca una llave pequeña en las ruinas (Garon puede apartar la piedra).",
			"hecho": "hito:brm_llave"},
		{"id": "canica", "texto": "Un Slime dormido se ha tragado una canica. Despiértalo.", "hecho": "hito:brm_canica"},
		{"id": "volver", "texto": "Devuélvele sus cosas a Rizo, junto a la cascada.", "hecho": "hito:brm_fin"}],
	"recompensa": {"objetos": {"Poción": 2}}, "pago": "Rizo vuelve a estar entero. Y os ha contado."},
```

No cambia ningún hito, recompensa ni misión existentes: todo lleva el prefijo nuevo `brm_`.

## 3. Encargo arqueológico: «Lo que guarda el vidrio» (primer sector del Mar de Cristal)

**Idea:** el viento ha destapado el vidrio del borde del desierto. Debajo hay cosas atrapadas desde hace tres mil años.
Es una **semilla** del pasado del reino, no una revelación: cada hallazgo deja una pregunta y ninguno la contesta.
No adelanta la máquina enterrada de Calid, que es de la historia principal del acto II [P: A2-01]; solo apunta hacia
ella.

### 3.1 El buscador de metales de Kael
- **De dónde sale:** Maese Ferro [P, V10] le regala a Kael un **diapasón de Hierro de la Falla**, el hierro «que
  canta» de su encargo. Aparece después de `enc_herrero_fin`, decida lo que decida el jugador, así que no cambia ese
  encargo ni su recompensa. Kael lo ata a un asta: **el Buscador de Kael** (objeto clave).
- **Si el jugador no hizo el encargo de Ferro:** la jefa del campamento le presta una varilla de cobre vieja. Encuentra
  los tres hallazgos principales, pero no los dos pequeños. Así nunca bloquea.
- **Cómo se juega en el móvil:** botón **«Escuchar»**. Un aro alrededor de Kael y un sonido dicen cuánto falta, en tres
  estados: **silencio**, **zumbido** y **canto**. En «canto», aparece **«Cavar»**. Vibración opcional, en Ajustes.
- **El brazalete** no hace de buscador. Solo brilla una vez, junto a la placa, como ya hace con los detalles nuevos
  [C: «brilla un instante… Nadie dice nada»].

### 3.2 Pasos
1. **El campamento de los cristaleros**, en el borde del vidrio. **Marga la Cristalera** [nombre nuevo], que recoge
   vidrio para venderlo, pide ayuda: el buscador suena donde ella no ve nada. → `hito:vid_inicio`
2. **Escuchar y cavar en cinco puntos** del primer sector (tres principales y dos pequeños). → `hito:vid_hallazgos`
   al tener los tres principales.
3. **Seguir los tubos**: el último canto lleva a unos tubos de metal que bajan hacia el sur, bajo la arena. No se puede
   seguir todavía. → `hito:vid_tubos`
4. **Volver con Marga.** → `hito:vid_fin`

### 3.3 Hallazgos (cada uno, un detalle de lore de 15 palabras o menos, como pide `progreso.gd`)

| Hallazgo | Detalle (texto al examinar) | Qué cuenta del pasado | Quién comenta |
|---|---|---|---|
| Farol de peregrino | «Un farol de peregrino, atrapado en el vidrio. Aún tiene la mecha.» | Por aquí pasaban los peregrinos del anillo [C: los peregrinos existen; su camino es P] | Lya: «Alguien lo llevaba encendido cuando pasó.» |
| Remache de máquina | «Un remache de hierro con el sello de la corona.» | Las máquinas de la corona estuvieron aquí [C: el sello de la corona y la máquina de Calid] | Garon: «Sello de la corona.» (y no dice más) |
| Placa de bronce | «Una placa de bronce. Alguien raspó el nombre antes de que se fundiera.» | La misma mano que raspó los nombres del sello de Oakhaven [C] | Kael: «Otro nombre raspado. Alguien tenía prisa por olvidar.» Garon: «O miedo.» |
| Monedas (pequeño) | «Monedas con un anillo entero grabado. Ninguna lleva rey.» | El anillo antes de partirse [C: el anillo partido]. Un pueblo sin rey | — |
| Cuenco (pequeño) | «Un cuenco de barro con huellas de dedos pequeños.» | Aquí vivía gente, también niños | Lya: «Esto no era una ruina. Era una casa.» |

**Conexión con el pasado del reino:** el jugador entiende, sin que nadie lo diga, que aquí hubo gente, que pasaron
peregrinos, que llegaron las máquinas de la corona y que después alguien raspó un nombre. Encaja con la dirección
aprobada (Rebelum es el reino olvidado, D-030) y deja la explicación para la historia principal. **Nada de Érebo ni de
sombras que roban:** esa pista ya tiene su sitio (acto II, A2-01 [P]) y aquí no se toca.

### 3.4 Recompensa propuesta
- 150 monedas y **Vidrio del Mar** ×3 (material nuevo, venta 25), para un oficio futuro. Las cifras las ajusta
  combate con el escalado del desierto.
- Los tres detalles de lore se apuntan en el Diario, como los demás.
- Marga vende vidrio después; si Kael le enseña las monedas, se ríe: «Eso no se compra. Eso se cuenta.»

## 4. Ganchos de misiones personales (uno por héroe)

Ninguno revela el pasado propuesto de los héroes (biblia v2 y v3): solo abren la pregunta.

**Kael · «Lo que la niebla no toca».** En Oakhaven, una niña le pide lo que nadie más puede hacer: entrar en el borde de
la niebla y sacar el colgante de su abuela de una casa tragada. Kael acepta con una broma («Por una vez, ser raro
sirve»). Dentro, todo está quieto y gris, y en la puerta de la casa hay un anillo partido que no estaba en el pueblo.

**Lya · «La página que no era de Mirta».** Entre las páginas que se llevó el viento (encargo de Mirta [P, V10]) había
una que no era suya: el sello de las sacerdotisas, un dibujo de flores y media frase quemada. Lya se la guarda sin
decir nada. Quiere encontrar el resto del libro antes de que lo encuentre otro.

**Garon · «Nadie se pierde en mi guardia».** En el libro de guardia de Oakhaven [C: el libro existe] falta una línea:
el turno de un recluta, Anselmo [nombre nuevo], la noche de la niebla. Nadie lo recuerda bien. Garon sí: lo entrenó
él. «Fuera de la muralla no os puedo proteger.» Esta vez, Garon sale a buscarlo.

## 5. Preguntas para el usuario

1. **Mar de Cristal:** ¿el corazón del Mar de Arena de Calid (recomendado) o un desierto nuevo y aparte?
2. **Auralis:** ¿dios de la luz (v3) con el Ciervo del Alba como su heraldo (recomendado), o el propio ciervo?
3. **Invocaciones nuevas:** ¿quién las invoca? ¿Lya con la Armonía, como Érebo, el futuro personaje de magia negra, o
   cada una con su condición?
4. **Marca del Vacío → Marca de Penumbra** y **Emperador Slime del Abismo → Emperador Slime**: ¿de acuerdo?
5. **Brumines:** ¿te vale «gente menuda de la bruma de las cascadas que guarda lo que se pierde»? ¿Renombramos a la
   coneja Bruma [P] para no repetir?
6. **Campanero del Porvenir:** ¿en qué región va?
7. **Nyx, el «Mago negro» antiguo de `grupo.gd`:** ¿se descarta, o es la base del futuro personaje de magia negra?
