# Barrio experimental de Oakhaven: fase 0 (contrato y blockout jugable)

> 16/11/2026. Rama `area-barrio-fase0` (desde `2d7745d`). Plan completo: `docs/v12/BARRIO_OAKHAVEN_PLAN.md`.
> **Fase A (agente A, rama `area-barrio-a`): los seis tramos horneados con el acabado de la muestra → §6.**
> Todo el barrio es **PROPUESTA [P]**: solo existe en el banco de pruebas de Auditoría y está **apagado fuera de él**.
> Siguen abiertas las decisiones del usuario del plan §1: (a) arrabal extramuros, (b) el nombre, (c) la tarde dorada
> frente a la hora azul del canon.

## 1. Qué hay

- **Región jugable** `aethelgard/zonas3d/barrio/barrio.tscn` + `barrio.gd` (extiende `prototipos/vista3d.gd`).
  - Se entra solo desde el banco: «Barrio de Oakhaven (en pruebas)», con Kael, Lya y Garon.
  - El **blockout** sale entero del trazado:
    - suelo con sus cotas (rampas y escalones del §2: el barrio sube de 0 a 1,4 m);
    - fachadas como cajas con su altura aproximada, tejados de otro color y puertas marcadas en naranja con su rótulo («Horno / Taller / Vivienda (en obras)»);
    - una malla por sector (colores en los vértices, un material);
    - **un StaticBody3D por caja**: 57 cuerpos (45 bloques sólidos, 11 losas de suelo y el fondo).
  - **Kael anda el bucle completo**: caravanas → comercial → plaza → talleres → casas → atajo → caravanas. El grupo le sigue (`grupo_3d`).
  - **Cámara por zonas sin girar.** Es la misma de la muestra de la calle: 10,8 m arriba, 14,2 m al sur, 25° y 38° de campo.
  - La API de región del contrato, el reparto de `_accion` y la guardia del prólogo.
  - «Volver al banco» funciona (lo pone `Recursos`). Hay un botón de prueba «Guardar y recargar» (plan §7).
  - **Fuera del banco** `_ready` no construye nada y vuelve a la carga.
- **Luz provisional en tiempo real.** Es una tarde dorada con el sol de la muestra, sin hornear. `sonda()` devuelve el valor provisional (sol 1, cielo 0,7).
- **Stubs** con las firmas exactas del §11, para B y C:
  - `zonas3d/barrio/interiores.gd`;
  - `ciudades/oakhaven_barrio.gd`;
  - `zonas3d/barrio/barrio_vivo.gd`.
  - No hacen nada y no rompen nada. Por eso las tres puertas dicen «Aún no se puede entrar (en obras).».
- **Banco** (`banco_pruebas.gd`):
  - el caso `EXPLORAR["barrio"]`;
  - `barrio_v12`, `barrio_interior` y `barrio_reloj` en `METAS_SESION`;
  - en `salir()`, `soltar_caches()` de `barrio.gd`, `interiores.gd` y `barrio_vivo.gd` si están cargados (el mismo patrón que la muestra).
  - Ahora son 12 casos (`prueba_banco_pruebas`).

## 2. El contrato real (lo que reciben A, B y C)

### 2.1 `zonas3d/barrio/trazado.gd` (estático, dueño A)

| Nombre | Qué es |
|---|---|
| `SECTORES` | sector → `Rect2`. Son los 6 del §2 con dos ajustes (ver §3). |
| `COTAS` | sector → `Vector2(mín, máx)`. |
| `ORDEN` | El orden de los 6 sectores. |
| `TRAMOS_EO` | Los tramos de este a oeste. |
| `SUELOS` | `[sector, Rect2, eje "", "x" o "z", cota al principio, cota al final]`. Es **lo único** de lo que salen `andable()` y `altura()`. El blockout construye las losas con estos mismos números. |
| `BLOQUES` | `[id, sector, Rect2, base, alto, tipo, sólido]`. Fachadas, muros, puestos, carros… Lo sólido que cae en un suelo deja de ser andable. También servirá de guía para el kit de Blender. |
| `ANCLAS` | Las 30 del contrato (`ANCLAS_CONTRATO`). Su «y» es la del suelo y la prueba lo comprueba. |
| `INICIO` | (−38,5; 0; 1), en el patio de caravanas. |
| `PASOS` | Los umbrales `paso_horno`, `paso_taller`, `paso_vivienda` y `paso_atajo`, como `Rect2` en x y z. |
| `PUERTAS` | `{horno, taller, vivienda}` → `{fuera, mira, radio 1.6, texto}`, más `ancla` y `paso` (campos añadidos). |
| `GRAFO` | Simétrico, con 15 nodos `n_*`. Cada arista es un tramo recto que se anda entero. |
| `BUCLE` | El recorrido de la prueba. |
| `CAMARA_ZONAS` | Lista de `{sector, rect, modo: "x"\|"eje"\|"libre", x, z_riel \| eje, z}`. |
| `OFFSET_CAMARA`, `INCLINACION`, `CAMPO`, `MARGEN_CAMARA` | La cámara (los tres primeros, los de la muestra) y el fundido de 2,5 m. |

Funciones:
- `andable(x, z)`, `altura(x, z)`, `sector_de(x, z)` y `ancla(id)` (las del contrato);
- además: `suelo_en`, `bloque_en`, `en_paso`, `peso_zona`, `peso_total`, `foco_camara(k)` y `poner_camara(cam, foco)`.

Convenciones:
- **«mira»** es la `rotation.y` de Godot: 0 = norte, PI = sur, −PI/2 = este.
- **`ancla(id)`** devuelve el punto con la y de `altura()`. Si el nombre no existe, avisa y devuelve el inicio.
- **`sector_de`** devuelve el sector del suelo que se pisa. Fuera de lo que se pisa, el primer `SECTORES` que lo contiene.
- **La cámara**:
  - el foco es la media pesada (smoothstep de la distancia al borde de cada zona) de lo que dice cada zona;
  - modo «x»: `x = clamp(Kael.x)`, `z = z_riel + min(0, Kael.z − z_riel)·0,55` (como la muestra);
  - modo «eje»: x fija y z sigue a Kael;
  - modo «libre»: x y z con límites;
  - en altura, `k.y·0,6`.

### 2.2 La región `zonas3d/barrio/barrio.gd` (dueño A)

```gdscript
var kael; var cam; var perfil: Dictionary; var interior := ""      # "" = fuera
var interiores; var vivo; var exterior: Node3D; var sectores := {}   # sector → Node3D (visibilidad por sector)
signal interior_cambiado(id: String)                               # también con "" al salir
func avisar(texto, efecto := "", seg := 2.8) -> void
func guardar() -> void          # solo en el banco: guardar_posicion() + Progreso.guardar (user://banco_pruebas.save)
func guardar_posicion() -> void # pos_3d_lugar 102; dentro de un interior, SIEMPRE PUERTAS[id].fuera
func ocupado() -> bool          # fundido de una puerta o diálogo de Dialogic
func sonda(p) -> Vector2        # fuera: (1, 0.7) provisional; dentro: interiores.sonda(p)
func iniciar_dialogo(ruta) -> bool   # señales "bar:" → Barrio.aplicar (aviso al acabar); al acabar, guardar() y vivo.reanudar_todos()
func ancla(id) -> Vector3       # "int_*" → interiores.ancla(id); si no, T.ancla(id)
static func puede_pasar() -> bool    # la guardia del prólogo (= Barrio.puede_pasar())
static func soltar_caches() -> void  # (vacío en la fase 0)
```

**`_accion`** (botón o `ui_accept`) reparte así:
- `entrar_<id>`:
  - sin la guardia del prólogo, «Todavía no: termina el prólogo.»;
  - si no, `Barrio.puerta(id)` (si devuelve un aviso, se enseña);
  - si no, con `id` fuera de `Interiores.ORIGEN`, «Aún no se puede entrar (en obras).»;
  - si no, el fundido de 0,35 + 0,15 + 0,35 s con `_pasar_dentro(id)`: `interiores.mostrar(id)`, el exterior oculto, Kael en `entrada(id)` mirando a `mira_entrada(id)`, `vivo.al_interior(id)` y la señal.
- `salir_<id>`: el mismo fundido. Kael aparece en `PUERTAS[id].fuera` mirando a «mira». Llama a `mostrar("")` y a `vivo.al_interior("")`.
- Un id de `vivo.piezas()`: `vivo.hablar(id)`.
- Cualquier otro: `Barrio.accion(pid)`, que devuelve `{texto, efecto, dialogo, guardar}`. Con `dialogo` se llama a `iniciar_dialogo`; si no, se enseña `texto`. Con `guardar`, se guarda.

**Piezas al alcance:**
- fuera, las tres puertas; dentro, `["salir_<id>", interiores.salida(id), 1.3, "Salir"]`;
- además, `vivo.piezas()` y `Barrio.PIEZAS` filtradas por zona: un ancla `int_<id>_…` solo dentro de ese interior; las demás, solo fuera.

**Kael:**
- `_prohibido`: fuera, `not T.andable(...) or vivo.ocupa(p)`; dentro, `not interiores.andable(p)`.
- Al entrar en la región, la posición guardada solo vale si el lugar es 102, `Interiores.interior_de(p) == ""` y es andable. Si no, `inicio`.
- `preparar(id)`: cuando Kael está a menos de 8 m de la puerta, una vez por puerta y solo si el `id` está en `ORIGEN`.
- **CAL**:
  - guarda la posición;
  - si está dentro, pone la meta de sesión `barrio_interior = {id, pos}`;
  - al recargar, vuelve a meter a Kael dentro (sin fundido) y borra la meta.

### 2.3 Lo que la región espera de B y de C (los stubs lo documentan arriba de cada archivo)

**B, `interiores.gd`:**
- `ORIGEN` **vacío = ningún interior construido**: la región dice «en obras». Al poner `"horno": Vector3(-300,0,200)`, la puerta del horno empieza a funcionar.
- `mostrar("")` = todos ocultos.
- `salida(id)` = dónde está el botón «Salir» **dentro**. El sitio de fuera lo pone `T.PUERTAS`.
- `camara(id, k)` devuelve `[posición, rotación en grados, campo]`. `[]` = la del exterior.
- Firmas: `construir(region)` y `preparar(id)`, más `interior_de`, `entrada`, `mira_entrada`, `andable`, `altura`, `abrir_paso`, `ancla`, `sonda` y `soltar_caches`, como en el §11.

**C, `ciudades/oakhaven_barrio.gd`:**
- `activado()`:
  - FALSO si no es Auditoría ni el editor;
  - dentro, `Engine "banco_pruebas"` y `"barrio_v12"`. La región pone la segunda en su `_ready` y el banco la quita al salir.
- Añadido al contrato: `puede_pasar()` y `TEXTO_PROLOGO`. El stub de `puerta(id)` ya devuelve la guardia del prólogo.
- `NOMBRE "oak_barrio"`; `NOMBRE_LUGAR`; y `NPCS`, `PIEZAS`, `MISIONES`, `AFIRMACIONES` y `SABER` vacíos.

**C, `barrio_vivo.gd`:** `montar`, `piezas`, `hablar`, `reanudar_todos`, `ocupa`, `al_interior`, la señal `vio` y `soltar_caches`.

## 3. Cambios respecto al plan (decididos aquí, reversibles)

1. **Patio de talleres de 10×22** (z −30..−8) en vez de 10×18. Con 18 m no llegaba a la calle T5 (z −30..−26).
2. **El taller del carretero, en z −22..−12** (plan: −24..−14) **y bajo** (3,4 m sobre su suelo de 1,4).
   - Con el plan quedaba a 2 m al sur de la calle T5 y, con la cámara mirando al norte, tapaba a Kael.
   - El portón sigue donde dice el contrato: `puerta_taller` en (−4,6; 1,4; −19,5).
3. **La casa del este del atajo empieza en z −18** por la misma regla. Entre z −26 y −18 el atajo se abre a los huertos, con una valla baja.
4. **Calle comercial**:
   - rampa lineal de x −32 (0) a −10 (0,4);
   - `puerta_horno` queda a 0,18 de altura (plan: 0,2) y `n_horno` a 0,136;
   - la «y» de cada ancla es la del suelo.
5. **SECTORES**: «talleres» llega hasta z −8 (el pie de la rampa) y «residencial» va de x −44 a −5 (toda su calle). Para lo que se pisa manda el sector de su `SUELO`.
6. **Escalones del atajo**: son rampa continua de 0,7 m en 3 m (13°), en z −22..−19 y −13..−10, con un rellano a 0,7. El arco de paso va en z −17..−16 (`paso_atajo`).
7. **La vivienda** está a 1,4, la cota de la calle. La alcoba a +0,35 y los 2 escalones a 1,75 quedan **dentro** (para B).
8. **`PUERTAS`** lleva además `ancla` y `paso`. `mira` es `rotation.y`.
9. **`GRAFO`**: `n_res_o` está en (−41; 1,4; −28), en la esquina con el atajo, para que la arista hacia `n_atajo_n` sea recta y andable. `n_carav` también enlaza con `n_atajo_s`.
10. **La regla del lado sur** se comprueba desde `BLOQUES`. `barrio.json` todavía no existe (lo escribe A con el kit).

## 4. Cómo se prueba

- `pruebas/prueba_barrio_trazado.gd` (auto, sin ventana, en `lista_pruebas.txt`).
- Batería del encargo: `powershell -ExecutionPolicy Bypass -File aethelgard/pruebas/ejecutar_pruebas.ps1 -Solo prueba_barrio_trazado,prueba_banco_pruebas,prueba_banco_pruebas_3d,prueba_muestra_calle` → **4 superadas, 0 fallidas**. Datos reales y proyecto sin cambios.
- Qué comprueba la prueba del barrio:
  - el contrato (30 anclas, umbrales, puertas, sectores, el grafo simétrico con aristas rectas andables);
  - **el BFS en rejilla de 0,25 m desde el inicio llega a las 16 886 casillas andables**;
  - **mayor salto de altura entre vecinas: 0,058 m**, con desniveles de 0 a 1,4;
  - toda casilla tiene una zona de cámara con peso;
  - **mayor paso del foco: 0,287 m por cada 0,1 m de Kael** (en el atajo);
  - la cámara es idéntica a la de la muestra y no gira;
  - el lado sur es bajo;
  - la región en el banco (activación, 6 sectores, 57 choques, la API, las tres puertas «en obras» y con la guardia del prólogo, guardar en el lugar 102);
  - **Kael llega a los 15 puntos del bucle** (a menos de 0,15 m), pisando la cota exacta y sin que la cámara gire;
  - no entra en el horno ni baja a los huertos;
  - fuera del banco no se construye ni se activa, y al salir del banco no quedan sus metas.
- **Capturas** (herramienta manual `pruebas/fotos_barrio.gd`, con APPDATA y LOCALAPPDATA aislados):
  - están en `D:\REBELUM_diagnostico\barrio_oakhaven\fase0\`, a 1600×720 y en perfil bajo;
  - `barrio_0_plano` (desde arriba) y `barrio_1_caravanas` a `barrio_6_atajo`;
  - en el PC, en bajo: 24-33 llamadas y unas 62 000 primitivas con Kael y el grupo. Es un blockout: no sirve de medida para el Redmi.
- Nota para quien pruebe en otra copia de trabajo: sin la carpeta `.godot` (no está en Git) fallan las clases de Dialogic y las fuentes. Hay que importar primero (`--headless --import`, con APPDATA aislado).

## 5. Pendiente

### A (exterior, kit de Blender y región)
Hecho en la fase A (ver §6). Queda:
- **Medir en el Redmi** (perfil bajo, APK del banco copiada por USB): FPS, PSS, tirones de entrada y por tramo. Todo lo de §6 es PC.
- Lo que se ve mal o flojo (§6.5): losas en sombra muy oscuras y destellos blancos en sus juntas; el atajo y los talleres
  con tejados grandes en primer plano (la cámara de la fase 0).
- Ampliar la prueba con «examinables a ≥ 2,5 m» cuando C tenga `PIEZAS`.
- **Integración** (orquestador): el precalentado en `carga.gd` (y `barrio_npc.gdshader` de C); y en `export_presets.cfg`,
  excluir `zonas3d/barrio/*` donde ya se excluye `zonas3d/muestra_calle/*` (el barrio precarga sombreados de la muestra).

### B (interiores)
- Rellenar `ORIGEN` y construir los tres interiores en `construir()`:
  - ocultos y con `PROCESS_MODE_DISABLED`;
  - carga en diferido en `preparar()`;
  - las anclas `int_<id>_…`, la cámara propia, `andable`/`altura` con bloqueos y los pasos internos (`cortina_horno`, `trastienda`, `alcoba`).
- `utensilios.glb` con sus pivotes.
- `pruebas/prueba_barrio_interiores.gd`:
  - entrar y salir de los tres;
  - `guardar_posicion` dentro guarda la puerta de fuera (ya lo hace la región);
  - restaurar nunca deja a Kael en un ORIGEN;
  - CAL vuelve a dentro;
  - la trastienda, cerrada y abierta;
  - doble pulsación y «Volver al banco» a mitad de un fundido.
- **Nada que pedir a A para empezar**: la región ya llama a todo. Solo pasa de «en obras» a entrar cuando el id está en `ORIGEN`.

### C (rutinas, misión y conocimiento)
- `oakhaven_barrio.gd`:
  - NPCS, PIEZAS (con «ancla» del contrato), MISIONES y el modelo sabe / ha oído / cree;
  - `accion`, `aplicar` con «bar:», `registrar_dialogic`;
  - la guardia del prólogo debe seguir en `puerta(id)`.
- `barrio_vivo.gd`: los NPC por el `GRAFO` con sus anclas, `ocupa(p)` y `piezas()` de la zona actual. Además, `npc_barrio.gd`, `utensilios.gd`, los `.dtl` y `.dch`, los oficios nuevos en `crear_npc_chibi.py` (solo añadiendo) y el prototipo del caballo.
- Una línea en `encargos.gd` FUENTES y la nota de `hallazgos.gd` l.53.
- `pruebas/prueba_barrio_datos.gd`, `prueba_barrio_vivo.gd` y `fotos_barrio_recorrido.gd`.
- La recompensa está **sin decidir** (Farol del Peregrino o Éter ×2): decide el usuario.

## 6. B: los interiores (agente B, rama `area-barrio-b` desde `a4cbbe8`)

> 16/11/2026. Todo sigue siendo **PROPUESTA [P]** y **solo existe en el banco** (los interiores los construye la región, y
> fuera del banco la región no se construye). Archivos de B: `zonas3d/barrio/interiores.gd`, `interiores/*.json`,
> `fuente/crear_interiores.py`, `fuente/crear_utensilios_barrio.py`, `modelos/int_*`, `modelos/utensilios*`,
> `pruebas/prueba_barrio_interiores.gd` y `pruebas/fotos_barrio_interiores.gd`. No toca `barrio.gd`, `trazado.gd` ni nada de C.

### 6.1 Los tres interiores (distintos en planta, muebles y actividad)

Cada uno es una «casa de muñecas» en su `ORIGEN` (horno −300,0,200; taller −300,0,240; vivienda −300,0,280): sin techo
ni muro sur a la vista, con un murete bajo al sur (su cara de fuera, oscura, se lee como el corte) y su puerta.

| Interior | Planta | Qué hay | Actividad (anclas para C) |
|---|---|---|---|
| **Horno de Maela** (10 × 7 × 3,4) | **En L**: el obrador (oeste) y la tienda (sur). Tras la **cortina** (tabique con paso, `cortina_horno`, siempre abierto), la zona de Maela (noreste). Baldosa de barro (con harina junto a la artesa y ceniza ante la boca); tablas en la zona de Maela | La **bóveda de ladrillo con la boca hundida y las brasas** (luz de fuego horneada), campana tiznada, pala, hurgón y leña; **la artesa** con la masa y un saco abierto; **dos estantes de enfriar** llenos de hogazas y barras; sacos de harina (dos abiertos); **el mostrador** a la calle con tres cestas de pan y la balanza. En la zona de Maela: hogar pequeño con su olla, **alacena** azul, mesa con tazón, pan empezado y vela, dos taburetes, la escalera a la alcoba (decorado) y hierbas colgadas | `int_horno_maela` (amasa en la artesa, de cara a la cámara), `_boca`, `_artesa`, `_estante`, `_mostrador`, `_mesa`, `_alacena`, `_cortina` |
| **Taller de Damián** (nave 9 × 7 × 4,6 + trastienda 4 × 7 × 3,2) | **Nave alta** con el **portón doble** al este (abierto, hojas contra el muro) y ventanas altas al oeste por encima del tejado de la trastienda (el sol de la tarde cruza la nave). La **trastienda** al oeste, tras un tabique con puerta. Tierra apisonada con virutas; tablas en la trastienda | **El potro** con la rueda a medio hacer (8 de 12 radios, 3 pinas); **el torno de pértiga**; **el banco de las gubias** y **la pared de las herramientas con sus siluetas pintadas de almagre: la de la GALGA está vacía, con su clavo** (la pista). Tres ruedas acabadas apoyadas y una colgada, pinas colgadas, haz de radios, barreño de remojar, piedra de afilar, estante con cajas y tarros, cuerda, candil; banco con **cántaro y vaso** junto al portón. **Trastienda**: fresno apilado con separadores, banco de cortar con **pasadores en bruto** y sierra, tajo con hacha, cesto de retales | `int_taller_damian` (al norte del potro, de cara a la cámara), `_potro`, `_clavo`, `_torno`, `_cantaro`, `_paso_trastienda`, `_banco_corte` |
| **Vivienda de Odila y Nela** (8 × 8 × 3,2) | **En profundidad**: la cocina delante (losas) y, **dos escalones arriba (+0,35, paso `alcoba`)**, la alcoba al fondo (tablas), tras una baranda baja que deja verla | **El hogar con la repisa y la GALGA encima** (copia de `utensilios.glb`, `sitio("galga")`), vela, tarros y la caja de los hilos; olla y fuego; **la mesa de la familia** con bancos, platos, jarra y pan; el **cántaro grande** en su pie; el vasar con platos; **la silla de Odila** junto a la ventana con su cesto de costura. En la alcoba: **la cama grande** (con el sol de la ventana oeste encima), **el arcón** con herrajes, la percha con ropa, candil, **la cama de Nela** con su colcha de retales y **su rincón**: alfombra de tiras, **la rueda de juguete tallada** (eco del taller), muñeca y tacos | `int_vivienda_odila` (en su silla), `_nela` (en la alfombra), `_repisa`, `_mesa`, `_cantaro`, `_arcon`, `_rincon`, `_alcoba` |

**Pista vivienda↔taller:** en el taller, la silueta pintada vacía con su clavo (una galga de 0,36 m con los escalones de
medir); en la vivienda, esa misma galga tumbada en la repisa (la misma silueta: `galga_2d()` del generador). La rueda de
juguete une los dos sitios.

### 6.2 Puertas, pasos internos y retorno seguro

- **Destino y retorno**: los hace la región (§2.2). B da `entrada(id)` (dentro), `mira_entrada(id)` (norte en el horno y
  la vivienda; **oeste** en el taller, en el que se entra por el portón del este) y `salida(id)` (el botón «Salir» de
  dentro, a 1,4 m de la entrada para que no salga al entrar). Al salir, Kael aparece en `T.PUERTAS[id].fuera`.
  `guardar_posicion()` dentro guarda esa puerta; CAL vuelve dentro (`barrio_interior`); una posición guardada en un
  `ORIGEN` no se restaura (`interior_de()`).
- **Condición**: las tres puertas de fuera están abiertas, con la guardia del prólogo y `Barrio.puerta(id)` de C (por
  ejemplo, «Llamar a la puerta» la primera vez en la vivienda). Dentro:
  - `cortina_horno` y `alcoba`: siempre abiertos.
  - **`trastienda`: cerrada** hasta `Barrio.paso_interno("trastienda")` **o** `estado:enf_taller` (la regla del plan, por
    si C aún no la tiene). Cerrada, no se pisa (todo x < 4,4 local) y **la hoja de su puerta se ve cerrada, con su
    tranca**. Al acercarse a la puerta sale el aviso **«Damián guarda ahí la madera buena.»** (una vez por acercamiento).
    Al abrirse, la hoja gira 90° (0,6 s, sonido `puerta_abre`). `abrir_paso(nombre, abierto)` fuerza cualquier paso (para
    C o las pruebas).
- **Estado**: entrar y salir no toca `mazmorras`, `lore_visto` ni nada de C (comprobado); los interiores siguen vivos en la
  misma escena.

### 6.3 Objetos: examinable, ofrecido, privado (los textos son de C)

`interiores/<id>.json` → `objetos`, y `interiores.objetos(id)` (con la posición): cada ancla lleva su **clase**.
- **examinable** (se mira; examinar no es coger): `horno_boca`, `horno_artesa`, `horno_estante`, `taller_potro`,
  `taller_clavo`, `taller_torno`, `vivienda_repisa`, `vivienda_mesa`, `vivienda_rincon`.
- **ofrecido** (lo da su dueño en el diálogo; no se toma): `horno_mostrador` (el pan, Maela), `taller_cantaro` (el agua,
  Damián), `vivienda_cantaro` (el agua, Odila).
- **privado** (tocarlo provoca una reacción o un aviso): `horno_alacena`, `horno_mesa`, `taller_banco_corte`,
  `taller_paso_trastienda`, `vivienda_arcon`.
- Todas a ≥ 2,5 m entre sí dentro de cada interior (las más cercanas: 2,57, 2,55 y 2,65 m).

### 6.4 Utensilios (`modelos/utensilios.glb`, `fuente/crear_utensilios_barrio.py`)

- Triángulos: `bandeja` 220, `cesta_pan` 250, `caja` 60, `saco_harina` 113, `cepillo` 36, `cubo` 138, `galga` 52,
  `pasador` 52, `pasador_roto` 90.
- Un material opaco (`utensilio`: color del vértice + `utensilios_atlas.png` de 256²: madera, tela, mimbre y metal).
- **Pivote = punto de agarre**; +Y arriba, −Z hacia delante.
  - Al pecho (dos manos): `bandeja`, `caja` y `saco_harina`, con el agarre en el borde que toca el cuerpo.
  - Una mano: `cesta_pan` y `cubo` por el asa (cuelgan debajo); `cepillo` por la correa; `galga` por el agujero de colgar
    (de canto, los escalones hacia −Z); `pasador` y `pasador_roto` por el medio.
- `utensilios.json` da los triángulos y la caja de cada uno. Sin luz horneada (se mueven): en la repisa, `calle_vertice`
  con una luz fija; en la mano, la de C (`barrio_npc.gdshader`).

### 6.5 Cámara, luz y materiales

- **Cámara de interior**: 6,2 m arriba, 7,2 m al sur, 40,73° hacia abajo y 44° de campo (a 9,5 m de Kael, frente a
  17,8 m fuera). **Nunca gira**; sigue a Kael dentro de los límites de cada sala (json `camara`), suavizada.
- **Luz horneada** (Cycles, 768 muestras, mapa de **1024**):
  - el sol de la tarde de la muestra entra **solo por las ventanas y la puerta** (el techo y el muro sur están en el
    horneado);
  - el cielo, por los huecos; los fuegos (horno, hogares, candiles, velas); un relleno tenue del techo;
  - una compresión suave de las luces altas: el fuego y las manchas de sol quedan a ≈ 5 veces el percentil 70 (no se
    queman);
  - exposición por sala (`escala`); `BRILLO` en `interiores.gd` para el ajuste fino sin volver a hornear.
- **Materiales**: los de la muestra **sin cambios** (`calle_estatico` con el mapa de luz, `calle_vertice` para las piezas,
  `calle_brillo` con su temblor para las brasas y las velas) y sus texturas: **ningún programa nuevo**. Se cargan con
  `load()`, no con `preload`. La sombra de contacto de Kael funciona dentro (`kael_pos` cada fotograma; sin sombra larga).
- **Kael dentro**: el sol de la región más débil y cálido y un ambiente cálido (`LUZ_KAEL`), fondo oscuro y sin niebla;
  todo se devuelve al salir. `sonda(p)`: rejilla de 0,5 m del json (sol por las ventanas; cielo y fuegos como relleno).

### 6.6 Presupuesto (PC, ventana 1600×720, pase 3D sin Kael ni el grupo; igual en bajo, medio y alto)

| Interior | Llamadas 3D | Primitivas | Superficies | Triángulos a la vista |
|---|---|---|---|---|
| Horno | 11 | ≈ 6 850 | 11 | 7 022 (+ 5 425 solo para el horneado) |
| Taller | 13 | ≈ 3 740 | 13 (con la hoja de la trastienda) | 3 749 |
| Vivienda | 12 | ≈ 2 760 | 11 + la galga | 2 818 |

Límite del plan §9: ≤ 14 llamadas, ≤ 35 000 triángulos y luz de 1024 → **cumple**. Con Kael y el grupo dentro, ≈ 32
llamadas y ≈ 65 000 primitivas (casi todo, los personajes). **Medido en el PC: el Redmi está sin medir.**

### 6.7 Cómo se rehace y cómo se prueba

- **Interiores**, con el turno de `D:\REBELUM_coordinacion\horneado.lock` (≈ 50 s los tres con la GPU):
  `blender -b --factory-startup -P zonas3d/barrio/fuente/crear_interiores.py -- <aethelgard/zonas3d/barrio> [--solo horno|taller|vivienda] [--sin-horneado] [--muestras N]`.
- **Utensilios**: `blender -b --factory-startup -P zonas3d/barrio/fuente/crear_utensilios_barrio.py -- <aethelgard/zonas3d/barrio>`.
- Después, `--headless --import`. Los `.import` van como los de la muestra: sin tangentes, sin niveles de detalle ni mallas
  de sombra; los mapas de luz, en VRAM con mipmaps.
- **`pruebas/prueba_barrio_interiores.gd`** (auto, en `lista_pruebas.txt`): **299 comprobaciones, 0 fallos**.
  - Datos: anclas del contrato andables y a la altura del suelo, objetos con clase a ≥ 2,5 m, BFS de 0,1 m desde la
    entrada, pasos, presupuesto, `interior_de` y tres plantas distintas. Utensilios.
  - En el banco: entrar y salir de los tres, preparar al acercarse, el exterior oculto y solo ese interior activo, la
    cámara propia sin girar, la puerta de fuera al guardar y al salir, lo examinado sin cambios, la doble pulsación.
  - La trastienda cerrada (aviso, hoja, no se pisa) y abierta; la alcoba y la cortina, andando.
  - CAL dentro; un ORIGEN no se restaura; «Guardar y recargar» dentro; el fundido cortado no deja metas y
    `banco_pruebas.salir()` suelta las cachés.
- **Capturas** (`pruebas/fotos_barrio_interiores.gd`, manual, APPDATA aislado): en `D:\REBELUM_diagnostico\barrio_oakhaven\b\`,
  17 por perfil (bajo, medio y alto): cada puerta por fuera, cada interior con su cámara y Kael en varios sitios, y los
  detalles (la boca del horno, el clavo vacío, la galga en la repisa, el rincón de Nela).
- `prueba_banco_pruebas`: 0 fallos.

### 6.8 Cambios que pide B (no los hace: no son sus archivos)

- **A, `pruebas/prueba_barrio_trazado.gd`** (en esta rama falla, como se esperaba al llenar `ORIGEN`):
  - la l.283 espera `v.ancla("int_horno_boca") == Vector3.ZERO` y la l.296, «en obras»; ahora la puerta ENTRA;
  - propuesta: comprobar «en obras» solo para los id que no estén en `Interiores.ORIGEN` y, para los demás, que la puerta
    entra (esperar al fundido y `_pasar_fuera()` antes de la siguiente);
  - el fallo «7: Kael llega a n_com_o» es consecuencia (Kael se queda dentro tras el bloque 6).
- **A, `barrio.gd`**:
  - el rótulo de las puertas dice «(en obras)» siempre: quitarlo cuando el id esté en `ORIGEN`;
  - dentro, `_prohibido` no mira `vivo.ocupa(p)`: Kael atravesaría a Maela, Damián, Odila y Nela;
  - cuando A haga la luz de Kael con `sonda()`, que dentro use la de los interiores sin pisar lo que pone
    `interiores.mostrar()` (o que A lo haga todo y B quite `_luz_dentro`).
- **C**:
  - las `PIEZAS` de los interiores con las anclas y la clase de §6.3 (texto de examinar; reacción o aviso en lo privado;
    lo ofrecido, solo por diálogo);
  - `paso_interno("trastienda")` = `estado:enf_taller` (B ya mira también ese estado);
  - `puerta("vivienda")` con «Llamar a la puerta»;
  - si un utensilio de sitio cambia de lugar (la galga al cogerla), ocultar la copia con `interiores.poner_sitio("galga", false)`;
  - las NPC, en sus anclas (`int_*_maela`, `_damian`, `_odila`, `_nela`).
- **Integración**:
  - `prueba_muestra_calle` (bloque 2) exige que nadie fuera de la muestra nombre `muestra_calle`, pero el plan §8 manda
    reutilizar sus sombreados y texturas (B ya lo hace; A lo hará). Hay que admitir `res://zonas3d/barrio/` en esa lista y
    **excluir `zonas3d/barrio/*` de las APK sin banco** en `export_presets.cfg` (como `zonas3d/muestra_calle/*`);
  - precalentado: nada nuevo para los interiores (son los programas de la muestra).

### 6.9 Estado

- **Diseñado**: los tres interiores, sus pasos, los objetos con clase, los utensilios, la cámara y la luz (§6.1-6.5).
- **Construido**: los generadores de Blender, los tres GLB horneados con su mapa de 1024 y su json, `utensilios.glb`,
  `interiores.gd` con todo el contrato, la prueba y la herramienta de fotos.
- **Integrado**: en la región del barrio de esta rama (la región ya llamaba a todo: no hizo falta tocar `barrio.gd`).
  Sin integrar con A (exterior horneado, luz de Kael) ni con C (NPC, piezas, misión).
- **Probado en PC**: `prueba_barrio_interiores` (299 · 0), `prueba_banco_pruebas` (0 fallos), capturas en bajo, medio y
  alto, y la medida de llamadas y primitivas. A la espera de los cambios de §6.8: `prueba_barrio_trazado` y
  `prueba_muestra_calle`.
- **Pendiente de móvil**: FPS, PSS y tirones en el Redmi (perfil bajo) al entrar en cada interior. La primera entrada
  carga el GLB en un hilo al acercarse (a menos de 8 m) y usa los mismos programas que la muestra (ya precalentados).

## 7. Sección C: vida, misión y conocimiento (agente C, rama `area-barrio-c` desde `a4cbbe8`)

> 16/11/2026. Todo sigue siendo **PROPUESTA [P]**, solo en el banco de Auditoría y **apagado fuera de él** (`Barrio.activado()`
> exige `banco_pruebas` y `barrio_v12`; fuera, las señales no hacen nada y la misión queda oculta aunque la partida traiga
> sus claves). La guardia del prólogo sigue en `puerta(id)` y, además, ninguna señal ni pieza cambia nada sin
> `prologo_visto` y `pv_02`.

### 7.1 Qué hay

**Archivos (dueño C):**
- `ciudades/oakhaven_barrio.gd`; `zonas3d/barrio/{barrio_vivo.gd, npc_barrio.gd, utensilios.gd}`;
- `dialogos/oakhaven/barrio/*.dtl` (24) y `dialogos/personajes/oakhaven/barrio/*.dch` (6);
- `fuente/crear_caballo.py` y las adiciones de `fuente/crear_npc_chibi.py` (125 líneas añadidas, ninguna cambiada);
- los modelos `personajes/npc_v12/{panadera,porteador,encargada_establo,caballo}/` y los atlas `herrero/damian.png`,
  `campesina/odila.png` y `nina/nela.png`;
- las pruebas `pruebas/{prueba_barrio_datos,prueba_barrio_vivo,fotos_barrio_recorrido}.gd` (en `lista_pruebas.txt`).

**Fuera de la carpeta, lo mínimo:** una línea en `encargos.gd` (FUENTES) y la nota del farol en `hallazgos.gd` («el barrio
de prueba da Éter ×2, no el farol»). `project.godot` **no se toca**: los `.dch` se registran en tiempo de juego
(`registrar_dialogic`); el import de Godot lo reescribe con los personajes nuevos y se deshace antes de cada commit.

#### Rutinas (plan §4) — `barrio_vivo.gd`
- **Programas compilados** (pasos `ir`, `tarea`, `coger`, `dejar`, `entrar`/`salir` de un interior y `evento`): el paso que
  toca es `(reloj − retraso) mod ciclo`, O(1). Sin navegación ni física: posición, clip y **dónde está cada objeto** salen
  del instante. Fuera de la vista o lejos no se dibuja, no se anima y no tiene choques (Kael no los pisa por `ocupa()`).
  Animación cada fotograma a < 12 m, a 15 Hz hasta 28 m, quieta más lejos; no se dibuja a > 34 m.
- **Ciclos medidos** (con los interiores sin hacer, cada tramo de dentro dura 3 s):

  | Vecino | normal | carro_parado (misión empezada) | reparto (carro arreglado) |
  |---|---|---|---|
  | Maela, la panadera | 125,5 s (22 tramos) | 87,6 s | 161,5 s |
  | Tobías, el porteador | 303,7 s (la pila del patio está a ~72 m del carro) | 119,9 s (sentado junto al carro) | 173,0 s |
  | Brena, la encargada del establo | 110,7 s (24 tramos) | — | — |

  - **Maela**: amasa y hornea **dentro** del horno, coge la **bandeja**, sale, la deja en el mostrador, llena la **cesta** y
    la lleva al puesto del pan de la plaza; vuelve, recoge y mete la bandeja. Con la misión empezada espera junto al
    carro mirando la rueda; con él arreglado, la bandeja va al carro.
  - **Tobías**: del carro de caravanas, una **caja** a la pila del patio de talleres y un **saco de harina** a la pila junto
    a la puerta del horno (fuera de su eje). Con el carro parado, sentado junto a él; con él arreglado, carga cajas en el
    carro del horno.
  - **Brena**: **cepillo** del gancho → cepilla a Avena (25 s) → lo cuelga → **cubo** → pozo (llenar) → abrevadero (verter:
    se ve el agua y Avena bebe 14 s) → deja el cubo → echa heno (Avena come 20 s) → devuelve el cubo.
  - **Damián** (carretero), **Odila** (costurera) y **Nela** (su hija), en su puesto con su tarea. Con su interior hecho por
    B (`Interiores.ORIGEN`), dentro (`int_taller_potro`, `int_vivienda_odila`, `int_vivienda_nela`). Mientras no, junto a
    su puerta, fuera de umbrales y caminos (`Barrio.PUESTOS[*].fuera`).
- **Objetos sujetos:** una ubicación lógica por objeto (`sitio:<nombre>` o `mano`); una copia por sitio y otra en la mano
  (BoneAttachment3D en `pecho` o `mano.R` del chibi, colocada con la pose de reposo; en la cápsula, un punto fijo). El
  cambio va a mitad de coger o dejar, por el reloj, nunca por la pose del clip. Al compilar se comprueba que **nada se
  coge donde no está ni se deja sin llevarlo** y que cada programa acaba donde empieza (`errores` vacío). La caja y el saco
  que Tobías deja en las pilas vuelven al carro al empezar su ciclo siguiente (se ve un instante, una vez cada 5 min).
- **Hablar interrumpe:** si cruza un umbral, primero cruza; si coge o deja, termina; se para con su reloj congelado, se
  gira hacia Kael y usa `llevar_quieto` si lleva algo (no `hablar`). Al acabar el diálogo (o la frase suelta, 3,2 s) sigue
  donde estaba sin perder objetos (`retraso += pausa`). Si Kael se le pone delante, espera (nunca en un umbral). Kael
  nunca queda atrapado: si ya está dentro del círculo de un vecino, puede salir.
- **La misión cambia el programa** (`Barrio.programa`), no la hora: al empezar el ciclo siguiente, o al momento si no se le
  ve. El reloj, los retrasos y los programas viven en la meta de sesión `barrio_reloj` (CAL y «Guardar y recargar» no los
  reinician; `banco_pruebas.salir()` la quita).
- **Avena** (yegua) atada ante el establo, mirando al abrevadero: no anda; `reposo`, `beber`, `comer` y `sacudir` según la
  rutina de Brena. Nada de montura ni carreras. Kael no la atraviesa.

#### Misión «Antes de que se enfríe» (plan §5) — `oakhaven_barrio.gd`
- **Pasos:** carro → taller → galga → medir → pasador → reparar → entrega (la cesta) → volver.
- **Estados** (bool en `mazmorras["oak_barrio"]`): `enf_carro_visto`, `enf_taller`, `enf_galga`, `enf_medida`, `enf_pasador`,
  `enf_reparado`, `enf_cesta`, `enf_entrega`, `enf_fin`, `viv_llamado` y los `j_*` del conocimiento.
- `empieza = cond:enf_empieza` (activado, prólogo y pv_02, y carro visto, taller, medida o pasador).
  `fin = cond:enf_terminada` (activado y `enf_fin`: apagado nunca sale «hecha»). **Sin cuenta atrás.**
- **Fuera de orden** (probado):
  - la galga suelta se guarda y NO empieza (su pista sale al empezar);
  - el taller primero (Damián lo ha oído por la rampa) empieza la misión;
  - medir antes del taller vale con la galga (y pone el carro visto);
  - el pasador solo con la medida; la cesta solo con el carro arreglado; el premio solo tras la entrega;
  - todas las señales son idempotentes (salir a mitad o repetir un diálogo no rompe nada).
- **La galga es un ESTADO** (`enf_galga`), no inventario. Dentro de la vivienda, la pieza «Coger la galga» de la repisa
  (`int_vivienda_repisa`). Mientras B no tenga la vivienda, **Odila la trae a la puerta** (`bar_odila_galga_puerta`, con
  `cond:vivienda_cerrada`). Pista del taller: el clavo vacío con la silueta (`int_taller_clavo`).
- **El carro** (`carro_horno`) hace lo que toca según el estado: examinar (empieza), medir con la galga o poner el pasador.
  El botón es fijo («Examinar el carro»): ver la petición de contrato 6.3.
- **Premio único: «Éter» ×2** (decisión del coordinador; catálogo real), una sola vez: `enf_fin` se pone ANTES de darlo.
- La trastienda del taller se abre con `enf_taller` (`paso_interno("trastienda")`); la cortina del horno y la alcoba,
  siempre. La primera vez se «llama» a la vivienda (Odila abre, `viv_llamado`) **solo cuando B la tenga hecha** (así la
  prueba de A, que espera «en obras», sigue igual).

#### Conocimiento sabe / ha oído / cree (plan §6)
- `AFIRMACIONES` (verdad o no) y `SABER` (vecino, afirmación, modo, «de» y «si»; gana la última regla que se cumple):
  - Maela **sabe** que se partió el pasador; Tobías lo **ha oído** a Maela (y lo sabe con el carro arreglado);
  - Brena **cree** (falso) que Avena le dio una coz al carro, hasta que Kael examina a Avena (`j_sabe_no_culpa_caballo`)
    y Brena cambia de frase;
  - Damián lo ha oído por la rampa (o a Kael) y lo sabe con la medida; Damián, Odila y Nela saben que la galga está en casa.
- Cada diálogo declara `dice` y sus señales `bar:<modo>:<af>:<npc>` guardan bools DEL JUGADOR (`j_<modo>_<af>` y
  `j_<modo>_<af>_<npc>`). **Solo lo sabido de primera mano avanza** (Maela o el propio carro); lo oído y lo creído va al
  Diario con su fuente («Tobías (se lo oyó a Maela): …», «Brena cree que…»). Opciones «¿Quién te lo dijo?» y «¿Lo viste tú?».
- **Rumores:** solo caravanas (el retraso de la del sur), caminos (barro, la ronda doble de la guardia) y precios (portes,
  peajes, hilo). Ningún texto nombra niebla, Sello, Érebo, tapiz, corona, niño ni aldeas; «se quedó en casa», nunca «se le
  olvidó». Frases al pasar ≤ 48, globos y avisos ≤ 110, pistas ≤ 15 palabras.

#### Modelos (Blender 5.2.3 por guion, respetando el turno de `horneado.lock`)
- Oficios nuevos **sin herramienta horneada** (las manos libres para los objetos): `panadera` (Maela, 5804 triángulos),
  `porteador` (Tobías, 5360) y `encargada_establo` (Brena, 5768), con el esqueleto común de 22 huesos. Clips nuevos solo
  para ellos: `caminar_llevar`, `llevar_quieto`, `coger`, `dejar`, `hornear`, `amasar`, `cepillar` y `verter`.
- Personas nuevas de oficios que ya existían, **solo su atlas** (sacado a otra carpeta con el 4.º argumento y copiado):
  Damián (`herrero`), Odila (`campesina`) y Nela (`nina`). Ningún GLB existente cambia.
- **Avena es un PROTOTIPO** (`fuente/crear_caballo.py`: 2612 triángulos, 17 huesos, atlas propio, sin Hunyuan3D), para
  enseñarlo al usuario, no el definitivo. Láminas en `D:\REBELUM_diagnostico\barrio_oakhaven\c\modelos\caballo_*.png`.
  Sin el GLB, una reserva de cajas.
- Utensilios: **cajas de reserva** opacas de su color y tamaño (`utensilios.gd`) hasta que B entregue
  `zonas3d/barrio/modelos/utensilios.glb` (un nodo por utensilio con su nombre y el pivote en el punto de agarre; se usa
  solo, sin tocar código).

### 7.2 Cómo se prueba

- **`pruebas/prueba_barrio_datos.gd`** (auto, sin ventana): controles de los comprobadores; apagado no cambia nada (la
  misión oculta aunque la partida traiga sus claves); condiciones (`error_condicion`), anclas del contrato, piezas y
  puestos de fuera (andables, fuera de umbrales, a ≥ 3 m de las puertas, a ≥ 2,5 m entre sí); textos; SABER coherente y
  cada diálogo con lo que su vecino sabe, ha oído o cree; la misión en orden normal, galga primero, taller primero y medir
  antes del taller, **guardando y cargando en cada paso**; Éter ×2 una vez; sin pv_02 o sin el prólogo no empieza;
  partida antigua; Dialogic: los 6 personajes y **29 recorridos** de diálogos y opciones (habla solo su vecino, cada
  frase con su `.dch`, llegan todas las señales).
- **`pruebas/prueba_barrio_vivo.gd`** (auto, sin ventana, con la región de verdad en el banco): programas sin errores;
  ciclos completos muestreados cada 0,1 s (una ubicación por objeto, coger y dejar junto a su sitio, nada en umbrales ni
  delante de puertas, nadie pisa a Avena, lo que se ve es lo que dice su ubicación); **hablar en cada paso** (13 de Maela,
  11 de Tobías, 20 de Brena: el resto, dentro del horno) y en el umbral (primero cruza); Dialogic desde el botón de la
  región (Brena con el cepillo, `llevar_quieto`, reloj congelado, sigue al acabar); salto fuera de la vista igual a lo
  simulado; la misión cambia los programas; Kael no pisa ni queda atrapado; quien anda espera; Avena bebe y se ve el
  agua. **`us_proceso` de la vida: 170-320 µs en el PC** (límite de la prueba 1,5 ms).
- **`pruebas/fotos_barrio_recorrido.gd`** (ventana, controles normales): la misión entera dos veces (orden normal con
  «Guardar y recargar» a mitad, y la galga primero), con clics, Intro y el botón de recargar; capturas y `recorrido.txt`.
  `modo=rutinas` visita cada rutina (vídeo). Resultado: ver 6.4.
- Batería (`ejecutar_pruebas.ps1 -Solo prueba_barrio_trazado,prueba_barrio_datos,prueba_barrio_vivo,prueba_banco_pruebas,
  prueba_banco_pruebas_3d,prueba_muestra_calle,prueba_encargos,prueba_diario_misiones,prueba_hallazgos,prueba_ciudad_datos,
  prueba_oakhaven_propuestas,prueba_mundo_vivo`): **12 superadas, 0 fallidas**; partida real, carpeta real de datos y
  proyecto sin cambios. (La del trazado de A sigue igual: por eso la vivienda solo se «llama» con el interior hecho.)

### 7.3 Peticiones de contrato (C no toca archivos de A ni de B)

**A A (región `barrio.gd`):**
1. **Botón según el estado:** en `piezas_al_alcance()`, usar `Barrio.boton(pid)` (ya existe) en vez de
   `PIEZAS[pid]["boton"]`. El carro diría «Medir el eje con la galga» y «Poner el pasador» en su momento (hoy dice
   siempre «Examinar el carro» y el aviso cuenta lo que se ha hecho).
2. **Aviso y diálogo:** al empezar un diálogo (`iniciar_dialogo`), ocultar el aviso que esté a la vista (el del carro se
   superpone al globo de Maela un instante; se ve en la captura `A02_maela`).
3. **`ocupa()` y el toque:** `_ajustar_destino` para en la primera muestra prohibida; si la recta roza el círculo de un
   vecino (0,42 m), Kael no se mueve y hay que tocar otro sitio. `ocupa()` ya deja SALIR a Kael si está dentro del círculo;
   sugerencia: que la región deje pasar rozando (o rodee) cuando el destino está más allá del vecino.
4. **Prueba del trazado:** ya se puede añadir «examinables a ≥ 2,5 m» con `Barrio.PIEZAS` (la de datos de C ya lo mira
   para los de fuera).
5. **Integración:** precalentar en `carga.gd` los GLB nuevos (`panadera`, `porteador`, `encargada_establo`, `caballo`) y,
   cuando exista, `barrio_npc.gdshader` (la luz de los vecinos por sonda: hoy usan el material de la familia chibi con la
   luz en tiempo real de la fase 0, sin parpadeo porque no hay `_luz_kael` horneada).
6. **Sombras:** la región no pasa el perfil a los vecinos después del `_ready`; la vida lee `region.perfil.sombras` al
   montar (CAL recarga la escena, así que vale).

**A B (interiores):**
1. Las anclas que usa C (todas del contrato): `int_horno_{artesa,boca,salida,estante}`, `int_taller_{potro,clavo,salida}` y
   `int_vivienda_{repisa,rincon,odila,nela,salida}`. `int_<id>_salida` es el punto de la puerta por dentro por donde
   entran y salen los vecinos (Maela entra y sale del horno por ahí).
2. Lo andable de dentro: Maela anda en **rectas** entre `salida`, `boca` y `artesa`: que no crucen muebles.
3. `abrir_paso("trastienda", …)` debe preguntar a `Barrio.paso_interno("trastienda")` (cerrada hasta `enf_taller`).
4. `utensilios.glb`: un nodo por utensilio con su nombre del contrato y el pivote en el punto de agarre (base apoyada en
   y = 0); `utensilios.gd` lo usa solo. Sin él, cajas de reserva.
5. Al hacer la vivienda, la primera vez se «llama» (`Barrio.puerta("vivienda")` devuelve el aviso de Odila y pone
   `viv_llamado`); la prueba del trazado de A, que hoy espera «en obras», tendrá que aceptarlo.
6. Con el interior hecho, Damián, Odila y Nela pasan dentro solos (`Barrio.interior_hecho`), y la galga se coge de la
   repisa (pieza `galga`) en vez de traerla Odila a la puerta.

### 7.4 Capturas y vídeos (`D:\REBELUM_diagnostico\barrio_oakhaven\c\`)

- `recorrido\`: el recorrido jugado (los 6 tramos, cada paso de la misión en orden normal y con la galga primero, el Diario
  al empezar y al acabar, Avena) y `recorrido.txt`. En `recorrido7\` la misión entera, **dos veces, completa con los
  controles normales** (A: orden normal con «Guardar y recargar» a mitad, Éter ×2 una vez y nada al repetir; B: la galga
  primero, que no empieza la misión, y medir, que sí). Sus 2 fallos eran de la prueba (al examinar a Avena el botón
  ofrecía «Hablar con Brena», que estaba al lado): se corrigió el acercamiento y la grabación lo confirma
  (`video_mision
ecorrido.txt`; su único aviso es un punto detrás de Avena, también corregido).
- `modelos\`: láminas del prototipo de Avena (`caballo_tres_cuartos/perfil/frente/beber/comer/sacudir.png`).
- `video\`: `mision.mp4` (3 min 38 s: la misión A entera jugada, con la recarga a mitad) y `rutinas.mp4` (1 min 04 s:
  Brena cepilla y vierte, Tobías coge y lleva la caja, Maela deja la bandeja y coge la cesta), del Movie Maker a 30 fps y
  1280×720 pasados a MP4 H.264 con ffmpeg (los `.avi` originales, al lado). Capturas de cada rutina en `rutinas2\`.
- Las carpetas `recorrido`, `recorrido2` a `recorrido6` y `rutinas` son intentos anteriores (con fallos de la prueba ya
  corregidos); no valen como resultado.

### 7.5 Estado (separado)

- **Diseñado:** las 3 rutinas, los 3 puestos y Avena; la misión con sus 8 pasos y el fuera de orden; el modelo sabe / ha
  oído / cree; los textos y las 6 voces; el contrato con A y B (6.3).
- **Construido:** todo lo de 6.1 (datos, vida, diálogos, modelos por guion, prototipo de Avena y pruebas).
- **Integrado:** en la región de A tal como está (fase 0): la vida monta, las piezas y los vecinos salen en el botón, los
  diálogos y sus señales pasan por `iniciar_dialogo` y `Barrio.aplicar`, guardar y «Guardar y recargar» conservan la
  misión y el reloj. **Sin integrar** (esperan a B): los interiores (Maela dentro del horno, Damián en el taller, Odila y
  Nela en casa, la galga en la repisa, el clavo, la trastienda); hoy esa parte está preparada y documentada, y lo de dentro
  se juega fuera (Odila trae la galga a la puerta).
- **Probado en el PC:** `prueba_barrio_datos` y `prueba_barrio_vivo` superadas; el recorrido jugado (6.4); la batería
  del encargo (6.2).
- **Pendiente de móvil (Redmi):** nada medido aún. La vida cuesta 0,17-0,32 ms en el PC; hay que medir en el Redmi el
  coste de 6 chibis animados + Avena (llamadas, primitivas, us_proceso) con el perfil bajo, y ver la luz de los vecinos
  cuando A hornee (riesgo 1 del plan: `barrio_npc.gdshader`).

### 7.6 Decisiones para el usuario (propuestas, sin canon)

- Los nombres y oficios (Maela, Tobías, Brena, Damián, Odila, Nela, Avena) y sus textos son PROPUESTA.
- Avena es un prototipo de guion: si gusta la idea, falta su versión buena (o un caballo hecho a mano).
- El ciclo de Tobías es largo (≈ 5 min) porque la pila del patio de talleres está lejos del carro: se puede acortar
  llevando la caja a la plaza.

## 8. Fase A: los seis tramos horneados (16/11, noche, agente A)

> Rama `area-barrio-a` (desde `a4cbbe8`). Sigue siendo **PROPUESTA [P]**, solo en el banco y apagado fuera de él.
> Capturas, comparaciones, medidas y vídeo: `D:\REBELUM_diagnostico\barrio_oakhaven\a\`.

### 8.1 Qué está hecho (diseñado → construido → integrado → probado en PC)

| Tramo | Identidad | Horneado | En la región | Probado en PC |
|---|---|---|---|---|
| T1 caravanas | Puerta de caravanas con dos torres almenadas y el rastrillo bajado; establo de tablas con dos cuadras a medio portón, pajar, polea, gancho del cepillo y herradura; abrevadero de piedra con agua; carro de caravana cargado; pozo bajo; fardos; cerca de varas; rodadas y paja | Sí (256 muestras, 2048/1024) | Sí | Sí |
| T2 comercial | Tienda de telas (escaparate, toldo a rayas, letrero); **el horno de Maela** (planta de sillería, puerta en arco ABIERTA con la luz del obrador en el umbral, mostrador a la calle bajo un arco rebajado con la tapa levantada y pan, chimenea ancha, letrero de la hogaza, sacos de harina); ultramarinos de hastial con balcón y toneles en la boca; lado sur bajo con puestos de verdura y cacharros, cajones y el **carro de reparto parado con la rueda torcida** | Sí | Sí | Sí |
| T3 plaza | Losas rectangulares a matajunta con un anillo oscuro; **lonja** con soportal de dos arcos y columnas; la **muralla de Oakhaven** con talud, contrafuertes, matacanes, almenas y el **postigo cerrado** (farol y poyo); tejados de la ciudad asomando; puestos del pan (toldo bajo), fruta y flores; árbol del mercado al noroeste; pretil con macetas | Sí | Sí | Sí |
| T4 talleres | **Taller del carretero** (nave baja de tablas sobre zócalo que baja a la rampa, portón doble abierto, letrero de la rueda, aperos); ruedas apoyadas; potro con rueda a medio hacer; muela; tablones; **tonelería** larga con portones, aros y toneles; la casa del fondo con galería | Sí | Sí | Sí |
| T5 residencial | Cinco casas distintas (alero, hastial, buhardillas); **la vivienda** con puerta verde en arco, rosal, macetas y banco; **tendederos** con ropa bajo los vuelos; canaleta; **huertos** con bancales, coles, judías en tutores, caseta y frutales; muro del arrabal; campos al fondo | Sí | Sí | Sí |
| T6 atajo | Dos tramos de **escalones** de sillería, el **arco** rebajado entre las casas, la **hornacina** con velas encendidas y figurilla, faroles, macetas, hiedra, cerca de varas a los huertos | Sí | Sí | Sí |

Todos con el acabado aprobado de la muestra: su arquitectura (casas de alero y de hastial **generalizadas** de `casa_a` y
`casa_b`), sus colores, sus 8 texturas (las mismas PNG) y sus 4 sombreados **sin cambios ni programas nuevos**; la misma
tarde dorada (sol 252°/24°, cielo frío) y la **misma escala de luz (2,229)** en todos los sectores. Probado en el
**Redmi: NO** (pendiente).

### 8.2 Cómo está hecho

- `fuente/exportar_trazado.gd` escribe `modelos/barrio.json` **desde** `trazado.gd` (suelos, cotas, bloques, anclas, grafo,
  zonas de cámara). Blender no repite ningún número a mano.
- `fuente/kit_barrio.py`: COPIA refactorizada del kit de `crear_calle.py` (que no se toca; cada bloque dice de qué líneas
  sale). Cambios: `Sector{nombre, semilla, rnd, anclas, choques}` (rehacer un tramo no mueve los demás), `marco(origen,
  giro)` para fachadas que miran al este u oeste, recorte con las cámaras del barrio, sondas en PNG, escala común,
  `FUSION` hierro→piedra y barro→revoque (comparten textura: dos superficies menos por objeto), y la luz de vértices sin
  luciérnagas (una esquina se baja a 2 × la mediana de su cara).
- `fuente/crear_barrio.py` (`--solo s1,s2`, `--fase arquitectura|completa`, `--muestras`, `--res`, `--sin-horneado`,
  `--sin-recorte`):
  - construye **todo** el barrio en una sesión y hornea cada sector con los demás como tapadores (sin costuras);
  - un `choque_<id>` por bloque sólido del trazado, **con las mismas medidas que el blockout**: el recuento de choques no
    cambia (57) y Kael anda igual; las piezas sueltas en lo andable llevan `choque_<s>_p<n>` (17) solo si están a más de
    0,8 m de toda arista del grafo, del bucle, de las anclas, de las puertas y de los umbrales;
  - recorte con **318 cámaras posibles** (Kael en cada metro de lo andable → su foco → la cámara de la zona);
  - **cobertura de pantalla** de cada sector (lo fijo y las piezas por separado) desde cada cámara, con una rejilla de
    64 × 36 rayos (16:9, 38°): la visibilidad por sector de la región;
  - lo lejano (campos y árboles) va en `barrio_fondo.glb` aparte (si no, las cajas envolventes de los sectores medían
    100 m y Godot no descartaba nada).
  - Tiempo en el PC (RTX 3050, OptiX): **≈ 4,8 min** todo (construir 4 s, cobertura y recorte ≈ 70 s, horneado ≈ 20 s por
    sector a 256 muestras, exportar); un sector suelto con `--solo`, ≈ 1-1,7 min.
- Salidas (`zonas3d/barrio/modelos/`): `barrio_<s>.glb` (fijo con mapa de luz, piezas y vegetación con luz en los
  vértices, choques y anclas), `barrio_<s>_luz_{2048,1024}.png`, `barrio_<s>_sondas.png` (R = sol, G = cielo, rejilla de
  0,25 m sobre el sector + 1 m; se importa como `Image`), `barrio_fondo.glb` y `barrio_luz.json` (escala, sol y cielo
  medidos, rejillas, triángulos, cámaras y cobertura). 54 MB en total (los GLB, 0,5-5,8 MB).
- Regenerar: `blender -b --factory-startup -P aethelgard/zonas3d/barrio/fuente/crear_barrio.py -- aethelgard/zonas3d/barrio`
  y reimportar (`godot --headless --path aethelgard --import`, con datos aislados). Antes, el turno de horneado
  (`D:\REBELUM_coordinacion\horneado.lock`).

### 8.3 La región (`barrio.gd`; el contrato de B y C no cambia)

- Un sector con su GLB y su entrada en `barrio_luz.json` se dibuja horneado; si no, en blockout (como la fase 0). Engine
  `barrio_solo_blockout` lo pone todo en cajas (las capturas del antes).
- Ambiente, sol y cielo **de la muestra** (con algún tramo horneado); materiales de la muestra, el estático con el mapa
  de luz de su sector (1024 en bajo, 2048 en medio y alto).
- `sonda(p)` real: la rejilla PNG del sector (interpolada); un sector en blockout, la provisional (1; 0,7); dentro, la de
  B. La **luz de Kael** y su **sombra de contacto** son las de la muestra, con el tono en sombra ya corregido (la luz de
  Kael va de 0 a 2,07 de sol en caravanas, prueba 9).
- **Visibilidad por sector**: con las 3 cámaras medidas más cercanas a la de ahora, lo fijo de un sector se dibuja si
  ocupa ≥ 2,5 % de la pantalla, y sus piezas y vegetación si sus piezas ocupan ≥ 1,5 % (`UMBRAL_VISTA`,
  `UMBRAL_DETALLE`); el sector de Kael, siempre entero. La sombra de Kael solo se manda a los materiales que se dibujan.
- `soltar_caches()` suelta materiales, luz y sondas (lo llama `banco.salir()`).
- Rótulos «(en obras)» solo para las puertas cuyo interior no está en `Interiores.ORIGEN`.
- Cambio fuera de mi carpeta, documentado: `pruebas/prueba_muestra_calle.gd` admite `zonas3d/barrio/barrio.gd` como único
  uso nuevo de la muestra (reutiliza sus sombreados y texturas, plan §8).

### 8.4 Medidas en el PC (VERIFICADO; NO certifica el Redmi)

RTX 3050 Laptop + Ryzen 7 4800H, Compatibility, ventana 1600×720, `pruebas/medir_barrio.gd`, con Kael, Lya y Garon;
«sin límite» = sin tope de FPS ni sincronía vertical; textos en `a\medidas\medida_barrio_{bajo,medio}.txt`.

| Tramo (sitio de las capturas) | Sectores que se dibujan | Llamadas | Primitivas | ms sin límite (mediana / p95) | CPU / GPU dibujo |
|---|---|---|---|---|---|
| caravanas | caravanas, comercial (fijo), atajo | 57 | 120 313 | 4,2 / 6,0 | 1,51 / 0,81 |
| comercial | comercial | 41 | 107 549 | 3,6 / 5,4 | 1,19 / 0,66 |
| plaza | comercial (fijo), plaza, talleres | 63 | 153 335 | 3,5 / 4,7 | 1,25 / 0,63 |
| talleres | plaza (fijo), talleres, residencial (fijo) | 57 | 133 389 | 3,9 / 5,5 | 1,38 / 0,71 |
| residencial | residencial | 42 | 132 229 | 4,2 / 6,0 | 1,45 / 0,80 |
| atajo | caravanas (fijo), residencial (fijo), atajo | 53 | 105 136 | 3,5 / 5,0 | 1,20 / 0,63 |

(perfil bajo; el medio da las mismas llamadas y primitivas y 3,1-3,4 ms de mediana.) Con el límite, 33,3 ms (30 FPS)
en todos, máximo 33,7.
- **Presupuesto §9**: ≤ 18 llamadas por sector → **11-14** (caravanas 11, comercial 13, plaza 14, talleres 13,
  residencial 14, atajo 12); ≤ 65 en pantalla → **41-63**; ≤ 160 k primitivas → **105-153 k**. Triángulos por sector
  (lo dibujable tras el recorte): 20-65 k (residencial 64,5 k, algo por encima de los 60 k del plan; el resto, debajo).
  Sin la visibilidad por sector eran 70-117 llamadas y 230-330 k primitivas.
- Entrada (Recursos.cambiar_escena, primera del proceso): **1,15 s** hasta el control en bajo (1,17 en medio; la muestra,
  0,77 s); memoria al entrar: vídeo 73,9 MB y texturas 47,0 MB en bajo (86,5 / 59,5 en medio).
- Sin medir: Redmi (FPS, PSS, tirones), malioc (los sombreados son los de la muestra: 4,8-5,15 ciclos).

### 8.5 Valoración honesta y lo provisional

**Conseguido:** los seis tramos se leen como el mismo barrio que la muestra (mismo entramado, tejas, revoques, luz) y cada
uno con su identidad y su historia (el horno abierto con su luz, el carro parado, el establo, la lonja y la muralla, el
carretero, los tendederos y los huertos, la hornacina). Kael anda el bucle entero con el grupo y la cámara de la fase 0.

**Lo que no está a la altura todavía:**
- **Suelo en sombra**: las losas (luz en los vértices, el método de la muestra) salen bastante más oscuras que la tierra
  horneada en el mapa de luz justo al lado, y en sus juntas aparecen trazos blancos. Se nota en la rampa de los talleres,
  en el atajo y en la sombra del muro de caravanas (sombras largas: el sol está a 24°). Comprobado que el color de los
  vértices llega igual a Godot que sale de Blender y que la irradiancia horneada de las losas no es menor que la del suelo;
  la causa no está aislada. Siguientes pasos posibles: hornear las losas al mapa de luz en las zonas de sombra, o un mapa
  aparte para el suelo.
- **La cámara de la fase 0** en el atajo y en los talleres: los tejados de las casas de la boca ocupan mucho cuadro (Kael
  se ve, pero en un pasillo estrecho). Es del trazado, no del acabado: se puede bajar el alero de esas casas o mover la
  zona de cámara.
- Los vecinos que asoman poco se dibujan solo con lo fijo o no se dibujan: al andar puede haber algún cambio pequeño en el
  borde de la pantalla (umbrales ajustables en `barrio.gd`).
- Las ventanas encendidas son planas (como en la muestra); la paja del patio es sencilla; el fondo lejano es plano.
- Rótulos «(en obras)» encima de las puertas mientras B no tenga los interiores.

**Capturas** (`D:\REBELUM_diagnostico\barrio_oakhaven\a\`, 1600×720, perfil bajo, la MISMA cámara de juego y el mismo
sitio de Kael): `antes_barrio_<n>_*` (todo en blockout), `despues_barrio_<n>_*` y `comparar_<n>_antes_arriba_despues_abajo.png`
para 0 plano, 1 caravanas, 2 comercial, 3 plaza, 4 talleres, 5 residencial, 6 atajo. **Vídeo**:
`barrio_recorrido_bajo.mp4` (73 s, 1280×720, 30 FPS, perfil bajo; Movie Maker + ffmpeg; `pruebas/grabar_barrio.gd`):
Kael anda el bucle entero a 2,2 m/s con el grupo.

**Pruebas**: `ejecutar_pruebas.ps1 -Solo prueba_barrio_trazado,prueba_banco_pruebas,prueba_banco_pruebas_3d,prueba_muestra_calle`
→ **4 superadas, 0 fallidas** (partida y datos reales sin cambios). `prueba_barrio_trazado` añade la parte 9 (tramos
horneados, choques, mapa de 1024 en bajo, solo los 4 sombreados, sondas con sol y sombra, luz de Kael, visibilidad).
