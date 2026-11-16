# Barrio experimental de Oakhaven: fase 0 (contrato y blockout jugable)

> 16/11/2026. Rama `area-barrio-fase0` (desde `2d7745d`). Plan completo: `docs/v12/BARRIO_OAKHAVEN_PLAN.md`.
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
- `fuente/kit_barrio.py`: la COPIA refactorizada del kit de `crear_calle.py`, que no se toca, con `Sector{nombre, semilla, rnd}`. Y `fuente/crear_barrio.py` (`--solo`, `--fase blockout|completa`, `--muestras`).
- `barrio.json`, escrito desde `trazado.gd`: lo leen Blender (recorte y sondas) y la prueba del lado sur.
- Hornear primero `comercial` + `plaza` y medir en el Redmi; después, el resto:
  - escala de luz común;
  - sondas PNG por sector;
  - materiales de la muestra sin cambios.
  - Hay que sustituir el blockout de cada `Sector_<s>` por su GLB, conservando los nombres de `T.BLOQUES` como guía y un `choque_*` por caja.
- `sonda()` real por sector y la luz de Kael (sol y cielo), como la muestra.
- La visibilidad manual por sector con `sectores`. `soltar_caches()` de verdad cuando haya cachés.
- `pruebas/medir_barrio.gd`.
- Ampliar la prueba con «examinables a ≥ 2,5 m» cuando C tenga `PIEZAS`.
- **Integración**: el precalentado en `carga.gd` (y `barrio_npc.gdshader`).

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
