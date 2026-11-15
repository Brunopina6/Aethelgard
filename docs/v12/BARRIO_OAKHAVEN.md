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
