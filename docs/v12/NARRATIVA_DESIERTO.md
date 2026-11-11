# V12 · Narrativa del Mar de Cristal (primer sector): PROPUESTA

> **Todo es PROPUESTA** (nombres, textos y enemigos): nada es canon hasta que el usuario lo apruebe. Narrativa,
> 11/11/2026, rama LOCAL `claude/v12-desierto-narrativa` (`D:\Aethelgard_v12_narrativa`), desde `claude/rebelum-v12`
> @ `e9eebf1`. Contrato: `docs/v12/DISENO_V12.md`. Canon de partida: `docs/v11/HISTORIA.md` §1 y §3.
> **Sin ejecutar Godot** (lo pidió el coordinador): todo lo de aquí está **observado en el código** o **pendiente de
> verificar**.

Reglas respetadas: nada de Érebo ni de lo que guarda; el Lente del Sol y la máquina enterrada de Calid no se nombran;
nada de Final Fantasy X; la Reina de los Espejismos no se nombra entera ni se revela qué es; ningún hito, recompensa ni
magia cambia. Cada intervención mide 84 caracteres como mucho (dos líneas de la caja del móvil).

## 1. Nombres (propuesta)

| Quién | Nombre | Identidad en una frase | Voz |
|---|---|---|---|
| La cartógrafa (NPC del campamento, 37, 96) | **Ismena** | Dibuja mapas de un mar que el viento cambia cada noche; espera en el campamento porque, si su hermano vuelve y no la encuentra, se perderá buscándola | Ironía cansada, frases de dirección y medida, el cariño escondido en una regaña. No es Hilda: Hilda cuenta remaches; Ismena orienta |
| Su hermano, el superviviente | **Oren** | Lleva un carro de mercancías por el Mar de Cristal y se pierde siempre; bromea incluso con dos días de sed | Charlatán, optimista, se ríe de sí mismo |

- **La caravana** es pequeña a propósito: **un carro, dos mulas y un toldo rojo**. Así nadie más corre peligro (no hay
  muertos que explicar) y el carro volcado del centro se reconoce por el toldo.
- **El sello de la caravana** es una regla de la familia: «quien se pierde deja el sello mirando adonde va». Por eso
  «marca el norte» (paso 3) y por eso cierra la misión con emoción.
- **Ismena sustituye a «Marga la Cristalera»** (`docs/v11/HISTORIA.md` §3.2) como NPC del campamento. Marga puede
  quedarse para más adelante como vendedora de vidrio.
- Comprobado con búsqueda en el repositorio y en la biblia v2 y v3 (11/11, `e9eebf1`): «Ismena» y «Oren» no aparecen.

## 2. Diálogos de Dialogic

**Formato** (observado en `dialogos/oakhaven/oak_ferro*.dtl`, `dialogos/garganta/gg_veta.dtl` y `ciudades/oakhaven.gd`):
- Ismena y Oren no tienen retrato (como Maese Ferro): hablan sin `join`. Kael y Lya entran con `join … (vivo_pv)`,
  como en la Garganta y el bosque, y cambian de gesto con `update … [extra_data="…"]`, solo con los gestos que ya
  tienen sus `.dch` (Kael: `ligero`, `sorpresa`, `decidido`, `brazalete`; Lya: `preocupada`, `decidida`, `duda`).
  Garon habla sin `join` (no tiene retrato).
- **Dialogic no lleva condiciones en este proyecto** (no hay `if` en ningún `.dtl` ni variables de Dialogic): quién
  habla lo decide el código, que elige la timeline. Igual que `oak_posada_grupo` / `_lya` / `_solo` y que `gg_veta`
  (`garganta_3d.gd:993`, solo con Lya y Garon).

### 2.1 Las timelines y cuándo lanzarlas

Carpeta: `res://dialogos/mar_cristal/`. **Nombre base = con Kael, Lya y Garon** (lo normal en el acto II: Garon se une
en PV-05). Variantes `_lya` (Kael y Lya) y `_solo` (Kael). Kael siempre está.

| Timeline (base) | Variantes | Cuándo (hitos `mc_*`) | Señal al final |
|---|---|---|---|
| `mc_cartografa_inicio` | — (solo Kael e Ismena) | hablar con Ismena sin `mc_inicio` | `mc:buscador` |
| `mc_cartografa_espera` | `_restos`, `_sello`, `_ruinas`, `_llave` (solo Ismena; ver 2.2) | hablar con ella con `mc_inicio` y sin `mc_superviviente` | — |
| `mc_caravana_restos` | `_lya`, `_solo` | examinar los restos (50, 60) sin `mc_caravana` | `mc:caravana` |
| `mc_tormenta` | `_lya`, `_solo` | al levantarse la tormenta narrativa (paso 4) | — |
| `mc_ruinas_mural` | `_lya`, `_solo` | examinar el mural (bajo la trampilla, según el contrato; el texto vale también en el arco) | — |
| `mc_superviviente` | `_lya`, `_solo` | abrir la trampilla con la Llave de vidrio | `mc:superviviente` |
| `mc_cartografa_fin` | — (Kael, Ismena y Oren) | hablar con Ismena con `mc_superviviente` y sin `mc_fin` | `mc:fin` |

**Elección por grupo** (sugerencia para el coordinador; `grupo.gd` une a Lya en PV-03 y a Garon en PV-05, así que
«Garon sin Lya» solo pasa en pruebas y va a `_solo`):

```gdscript
static func dialogo_mc(base: String) -> String:
	var g: Array = load("res://grupo.gd").activos()
	if g.has("Lya") and g.has("Garon"):
		return base
	return base + ("_lya" if g.has("Lya") else "_solo")
```

### 2.2 La espera de Ismena, según el hito

| Condición | Timeline | Pista |
|---|---|---|
| `mc_inicio`, sin `mc_caravana` | `mc_cartografa_espera` | escucha al buscador; si el cielo se pone pardo, roca (vale también como genérica) |
| `mc_caravana`, sin `mc_sello` | `mc_cartografa_espera_restos` | el sello de la familia, junto al carro |
| `mc_sello`, sin `mc_ruinas` | `mc_cartografa_espera_sello` | al norte, a las ruinas; con viento, al cañón del oeste |
| `mc_ruinas`, sin `mc_llave` | `mc_cartografa_espera_ruinas` | si hay puerta, hay llave: buscar entre las columnas |
| `mc_llave`, sin `mc_superviviente` | `mc_cartografa_espera_llave` | ve y ábrelo |

### 2.3 Registro (archivos del coordinador)

- **Personajes**, en `project.godot` (`dialogic/directories/dch_directory`) o en un `PERSONAJES` como el de
  `ciudades/oakhaven.gd` con `registrar_dialogic()`:
  `"ismena": "res://dialogos/personajes/mar_cristal/ismena.dch"`, `"oren": "res://dialogos/personajes/mar_cristal/oren.dch"`.
- **Timelines**, en `dialogic/directories/dtl_directory`: las 19 de `res://dialogos/mar_cristal/` con su nombre de
  archivo como clave (o lanzarlas por ruta completa).
- Los `.uid` los crea el editor al importar (no se ha ejecutado Godot).

## 3. Textos de la región (avisos y examinar)

| id | Texto | Cuándo |
|---|---|---|
| `mc_nota_esqueleto` | Un viajero de otro tiempo. Su nota dice: «Si la arena tiembla, roca. Si ves agua, no corras.» | examinar el esqueleto del nicho (8, 30) |
| `mc_espejismo_antes` | Una palmera junto al agua… Al acercarte, tiembla y se deshace en aire caliente. | acercarse al espejismo (82, 30) con calor |
| `mc_espejismo_cofre` | Con el aire en calma, el espejismo se apaga. Debajo había un cofre de verdad. | en calma, al revelarse el cofre |
| `mc_aviso_temblor` | La arena tiembla bajo tus pies. Algo enorme se mueve debajo. ¡Sal de la arena blanda! | aviso del gusano en la arena que tiembla |
| `mc_cobijo` | Bajo la roca, el viento ruge pero no entra. Toca esperar a que amaine. | llegar al cobijo (14, 48) con tormenta |
| `mc_tormenta_fin` | La tormenta amaina. Al norte, la arena ha dejado un arco al descubierto. | (extra, opcional) al acabar la tormenta narrativa: lleva a `mc_ruinas` |
| `mc_hallazgo_sello` | El sello de la caravana: un disco de bronce con una flecha. Alguien lo dejó mirando al norte. | excavar el sello junto a los restos |
| `mc_hallazgo_llave` | Una llave de vidrio con el ojo de bronce. Por eso cantaba el buscador. | excavar la llave en las ruinas |
| `mc_trampilla_cerrada` | Una trampilla de vidrio con cerradura. Desde abajo llega un golpe… ¿o es el viento? | examinar la trampilla sin la llave |

La llave lleva **bronce** a propósito: el buscador pita cerca del metal, y una llave solo de vidrio no sonaría.

## 4. Enemigos del desierto (nombre e identidad; propuesta)

| Enemigo | Nombre | Identidad en una frase | Idea de combate (para combate) |
|---|---|---|---|
| Escorpión de vidrio que se entierra | **Vidracrán** (vidrio + alacrán) | Duerme bajo la arena con la cola fuera, que brilla como un trozo de botella: quien se agacha a cogerla, lo despierta. | Se entierra un turno (no se le puede apuntar) y sale con el aguijón; avisa con un brillo |
| Espíritu de polvo que llega con la tormenta | **Tolvanera** («remolino de polvo» en castellano) | Un remolino con dos brasas por ojos: nace con la tormenta, busca a quien no se ha puesto a cubierto y se deshace cuando amaina. | Solo sale con tormenta; Agua lo asienta (más daño), viento le cura |
| Gusano colosal, con nombre propio | **Tragaluz** | Tan viejo que tiene surcos por arrugas: pasta el vidrio bajo la arena blanda y sube a ver quién le pisa la comida. | Encuentro especial de la arena que tiembla; en roca no sube |

**Tragaluz, sin parecerse a Dune:** no se monta, no es un dios ni guarda nada, no lo atrae un ritmo ni hay especia;
come vidrio (por eso el Mar de Cristal tiene surcos) y es territorial, no cazador. Para gráficos: corto y grueso, como
una larva enorme con placas de vidrio fundido en el lomo que brillan cuando come; boca pequeña de placas planas que
muelen, nunca un anillo de dientes. El nombre juega con «tragaluz» (la ventana del techo): se traga lo que brilla.
Alternativas si no convence: **el Sordo** (como lo llamarían los caravaneros) o **Bramavidrio**.

## 5. Intenciones y gestos (para animaciones)

Gestos: `extra_data` de las poses que ya existen. «—» = sin cambio de gesto (habla quien no tiene retrato, o sigue el
anterior). Las variantes `_lya` y `_solo` repiten estas intenciones; donde cambian, se indica.

**`mc_cartografa_inicio`**

| # | Quién | Intención | Gesto |
|---|---|---|---|
| 1 | Ismena | ruega sin querer que se note; lo dice como un dato | — |
| 2 | Kael | quita hierro, sin darse cuenta de que ella está mal | `sorpresa` |
| 3 | Ismena | lo dice seco para no romperse | — |
| 4 | Ismena | la ironía de siempre, con cariño | — |
| 5 | Kael | deja la broma: tres palabras | `decidido` |
| 6 | Ismena | da la dirección, práctica | — |
| 7 | Ismena | la razón de quedarse: humor que es miedo | — |
| 8 | Ismena | entrega el buscador; explica en una frase | — |
| 9 | Kael | encantado con el juguete | `ligero` |
| 10 | Ismena | lo de verdad, al final y de lado | — |

**`mc_cartografa_espera*`**: Ismena, frases cortas; se le nota la prisa (sin gestos).

**`mc_caravana_restos`** (trío)

| # | Quién | Intención | Gesto |
|---|---|---|---|
| 1 | Kael | reconoce el carro; se le corta la broma | `sorpresa` |
| 2 | Lya | lee el sitio como un libro: dato y conclusión | `preocupada` |
| 3 | Garon | parte militar | — |
| 4 | Kael | broma para bajar la tensión | `ligero` |
| 5 | Lya | propone el siguiente paso | `decidida` |
| 6 | Kael | cierra y se pone en marcha | `decidido` |

`_lya`: Lya dice también lo de Garon (2). `_solo`: Kael piensa en voz alta (sorpresa → decidido).

**`mc_tormenta`** (trío): Garon avisa (—) · Lya, el dato del buscador (`preocupada`) · Garon, la orden (—) · Kael,
la orden repetida con cariño (`decidido`). `_lya`: Kael lo ve el primero (`sorpresa`), Lya da la orden
(`preocupada` → `decidida`), Kael obedece con broma (`ligero`). `_solo`: `sorpresa` y se pone a correr.

**`mc_ruinas_mural`** (trío)

| # | Quién | Intención | Gesto |
|---|---|---|---|
| 1 | Kael | se burla para no sentir el frío de la pintura | `sorpresa` |
| 2 | Lya | observa; aún no entiende | `duda` |
| 3 | Lya | lo entiende, y no le gusta | `preocupada` |
| 4 | Garon | incómodo, lo dice como un parte | — |
| 5 | Kael | eco de «Las estatuas no miran» (`pv_07`), ahora con duda | `ligero` |
| 6 | Lya | el dato final, firme | `decidida` |

`_lya`: sin Garon; cierra Kael con una broma (`ligero`). `_solo`: Kael, de `sorpresa` a `ligero`.

**`mc_superviviente`** (trío)

| # | Quién | Intención | Gesto |
|---|---|---|---|
| 1 | Oren | deslumbrado y bromista a la vez | — |
| 2 | Kael | alivio escondido en broma | `sorpresa` |
| 3 | Oren | ternura por su hermana, en chiste | — |
| 4 | Lya | le cuida: orden suave | `preocupada` |
| 5 | Oren | lo cuenta deprisa, riéndose de sí mismo | — |
| 6 | Oren | sigue, sin aire | — |
| 7 | Garon | remata seco | — |
| 8 | Oren | el chiste del mural; debajo, dos días de miedo | — |
| 9 | Kael | lo saca de allí | `ligero` |

`_lya`: Kael dice el remate de Garon (`decidido`). `_solo`: Kael le da agua; sin remate.

**`mc_cartografa_fin`**

| # | Quién | Intención | Gesto |
|---|---|---|---|
| 1 | Ismena | estalla, riñendo | — |
| 2 | Oren | se hace el tonto | — |
| 3 | Ismena | una palabra: ahí está todo | — |
| 4 | Ismena | se ablanda | — |
| 5 | Oren | tierno, sin bromear | — |
| 6 | Ismena | lo de verdad | — |
| 7 | Ismena | a Kael: el buscador queda para él | — |
| 8 | Kael | encantado, para romper la emoción | `ligero` |
| 9 | Ismena | la recompensa; vuelve a la ironía | — |
| 10 | Oren | protesta; risa final | — |

## 6. Preguntas para el usuario

1. **Ismena y Oren**: ¿te valen los nombres? ¿Sustituye Ismena a Marga (V11) como NPC del campamento?
2. **Tragaluz**: ¿el nombre, o prefieres «el Sordo» o «Bramavidrio»?
3. **El mural** deja leer «…de los Espejismos»: ¿basta con eso, o prefieres que no se lea nada del nombre?
4. **La reliquia de la recompensa**: Ismena la da como «algo que trae suerte a quien vuelve», sin nombre, para no
   pisar lo que decida el coordinador. ¿Qué reliquia es?
