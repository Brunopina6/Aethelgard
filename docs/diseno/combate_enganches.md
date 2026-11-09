# Enganches de las ampliaciones de combate (fase 1: C0, M1, M2 y C1)

> **Estado (09/11, fase 2): aplicado** en `area-combate`, salvo E-1 (`diario.gd`, de narrativa). Las diferencias con lo
> que se escribió aquí y lo que se añadió, en el §7. El resto del documento se deja como estaba (fase 1).
> **Base de las líneas:** `area-combate` @ `2386761` (con la tanda 2 de sonido). Si un archivo ha cambiado, cada fila
> lleva su **ancla** (el texto exacto de la línea) para encontrarla.
> **Módulos que se enganchan:** `artes.gd` (M1 y M2) y `equipo_extra.gd` (C1), con sus pruebas `prueba_artes` y
> `prueba_equipo`. Diseño: [combate_ampliaciones.md](combate_ampliaciones.md).
> **Fecha:** 2026-11-09 (fase 1 de T-091 a T-093).

**Índice:** 0. Resumen · 1. C0 · 2. M1 y M2 · 3. C1 · 4. Después (M3, C2 y M4) · 5. Peticiones a otros ·
6. Pruebas al enganchar · 7. Aplicado (fase 2)

---

## 0. Resumen

| Archivo | C0 | M1 y M2 | C1 | Notas |
|---|---|---|---|---|
| `combate.gd` | 3 líneas | 2 constantes, 5 cambios y 5 funciones nuevas | 5 cambios | Las 12 magias no cambian: las artes van por su ruta |
| `menu_combate.gd` | — | 1 constante y 3 cambios | — | Pestañas de 64 px con icono; iconos de estado |
| `menus.gd` | — | 1 (Habilidades) | 2 (tolerancia y «solo») | La fila Accesorio sale sola (recorre `Inv.RANURAS`) |
| `tienda.gd` | — | libros de artes | equipo por lugar | |
| `inventario.gd` | — | — | 7 | La ranura «accesorio», al final |
| `diario.gd` | — | 1 (fichas) | — | |
| `grupo.gd` y `progreso.gd` | — | **ninguno** | **ninguno** | Las artes se calculan con `grupo.datos()`; nada nuevo en la partida |

- **Orden:** C0 → M1 y M2 juntos (son la misma infraestructura) → C1.
- **La huella no debe cambiar** con ningún enganche de este documento: ningún combate de la referencia usa artes ni
  equipo nuevo, y ningún escenario cruza un umbral de las artes al subir de nivel (E1 a E3, E6 y E7 suben del 1 al 2;
  E4 y E5, del 10 al 11; E8, del 7 al 8). La única excepción es C0.2, que cambia Infierno y Cólera del Cielo, que
  hoy están fuera de la huella.
- `MAGIAS` y `NIVELES_MAGIA` **no se tocan**: `prueba_artes` comprueba que siguen con sus 4 familias y sus 12 niveles.

---

## 1. C0: determinismo (`combate.gd`)

| # | Función | Línea | Ancla | Cambio |
|---|---|---|---|---|
| C0.1 | `_ready` | 322 | `	randomize()` | Con `-- semilla=N`, `seed(N)`; sin ella, como hoy |
| C0.2 | `_lluvia_meteoros` | 3349 | `	var rng := RandomNumberGenerator.new()` | Añadir debajo `	rng.seed = randi()` |
| C0.3 | `_tormenta` | 3527 | `	rng.randomize()` | Cambiar por `	rng.seed = randi()` |

```gdscript
# C0.1, en lugar de «randomize()» (primera línea de _ready)
	var semilla := -1                              # pruebas: -- semilla=N (C0); en el juego, al azar como siempre
	for a in OS.get_cmdline_user_args():
		if a.begins_with("semilla="):
			semilla = int(a.substr(8))
	if semilla >= 0:
		seed(semilla)
	else:
		randomize()
```

- **Por qué C0.2 y C0.3** (comprobado ejecutando, aislado, el 09/11): en Godot 4.7 un `RandomNumberGenerator.new()`
  empieza al azar (dos procesos dieron 1189864965 y 2393320160). Los meteoros y rayos de adorno caen entonces en
  momentos al azar, y sus partículas y el rayo 3D tiran del generador global. Con Infierno, 6 pasadas del mismo
  combate dieron 3 huellas distintas; sin él, 6 iguales.
- **Con `rng.seed = randi()`** los adornos salen de la semilla del combate: en el juego siguen variando, y en las
  pruebas son fijos. Cuesta una tirada global más por lanzamiento, solo de esas dos magias.
- `_rayo_2d` (línea 3475) **no se toca**: su generador solo dibuja la forma del rayo y no cambia ningún tiempo.
- **Después de C0:** añadir a la huella Infierno (E4, Kael) y Cólera del Cielo (un E9), comprobar dos pasadas y sacar
  otra referencia explicando el cambio.
- C0.1 no cambia la huella: la prueba siembra el generador después de `_ready` de todas formas.

---

## 2. M1 y M2: las artes (Alba I-II y Lumbre I-II)

`artes.gd` limita lo que sale en el juego con `ACTIVOS` (`{"Alba": 2, "Escarcha": 0, "Lumbre": 2}`). Escarcha y los
niveles III ya tienen datos, lógica y pruebas, pero no salen hasta M3 y M4.

### 2.1 `combate.gd`

| # | Función | Línea | Ancla | Cambio |
|---|---|---|---|---|
| A1 | (constantes) | 64 | `# Magias: cambia aquí el coste, el daño y los colores.` | Encima, las dos constantes de abajo |
| A2 | `_siguiente_turno` | 1191 | `		_mostrar_menu()` (rama del héroe) | Encima: `		_tic_estados_heroe(f)` |
| A3 | `_hechizos` | 1741 | `	return r` | `	return r + Artes.hechizos(f["nombre"])` |
| A4 | `_menu_magia` | 1750-1775 | `func _menu_magia(nivel := 0) -> void:` | Sustituir la función (abajo) |
| A5 | `_elegir_hechizo` | 1794 | `	nivel_sel = nivel` | Encima, el desvío (abajo) |
| A6 | (funciones nuevas) | 1818 | `# Elegir a qué aliado curar: se toca al héroe.` | Encima, las cinco funciones de abajo |
| A7 | `_carga_magia` | 3104 | `	var color: Color = MAGIAS[magia]["color"]` | `	var color: Color = MAGIAS[magia]["color"] if MAGIAS.has(magia) else Artes.COLOR[magia]` |
| A8 | `_repartir_exp` | 3813 | `					registro.text = "%s aprende %s" % [h["nombre"], NIVELES_MAGIA[k][nm - 1]["nombre"]]` | Debajo, fuera del `for k`, el aviso de las artes (abajo) |

```gdscript
# A1
const Artes := preload("res://artes.gd")             # familias nuevas de T-091 (Alba, Escarcha y Lumbre)
const Extra := preload("res://equipo_extra.gd")       # accesorios y armas especiales de T-092 (C1)
```

```gdscript
# A4: la misma función, con una pestaña con icono por familia nueva detrás de I · II · III (§3.6 del diseño).
# Sin artes, las pestañas, las filas y su orden son exactamente las de hoy.
func _menu_magia(nivel := 0) -> void:
	estado = "magia"
	var por_nivel := [[], [], []]
	var familias: Array = []                      # artes (artes.gd), en el orden de sus pestañas
	var sabe := {}                                # familia → nivel que puede usar
	for h in _hechizos(actor):
		if Artes.es_arte(h[0]):
			if not h[0] in familias:
				familias.append(h[0])
			sabe[h[0]] = h[1]
		else:
			por_nivel[h[1] - 1].append(h)
	if nivel == 0:
		nivel = magia_nivel_menu.get(actor["nombre"], 1)
	var p: Dictionary = Artes.pestanas_magia(por_nivel.map(func(x): return not x.is_empty()), familias, nivel)
	nivel = p["valor"]
	magia_nivel_menu[actor["nombre"]] = nivel     # 1-3: nivel; 4 y 5: primera y segunda familia
	var pestanas: Array = []
	for t in p["pestanas"]:
		var tab: Dictionary = t.duplicate()
		tab["accion"] = _menu_magia.bind(t["valor"])
		pestanas.append(tab)
	var items: Array = []
	if nivel >= 4:
		var fam: String = familias[nivel - 4]
		for it in Artes.filas_familia(fam, sabe[fam], actor, heroes, enemigos, cola, MODO_PRUEBAS, ATB_MAX):
			it["accion"] = _elegir_hechizo.bind(fam, it["nivel"])
			items.append(it)
	else:
		for h in por_nivel[nivel - 1]:
			var d: Dictionary = h[2]
			items.append({"texto": d["nombre"], "accion": _elegir_hechizo.bind(h[0], h[1]), "icono": h[0],
				"derecha": "PM ∞" if MODO_PRUEBAS else "%d PM" % d["coste"], "apagado": not _puede_pagar(d["coste"]),
				"desc": _desc_magia(h[0], d)})
	menu.submenu(items, pestanas, p["activa"])
```

```gdscript
# A5, primeras líneas de _elegir_hechizo
	if Artes.es_arte(magia):                        # familias nuevas (artes.gd): su ruta; las 12 de siempre, igual
		_elegir_arte(magia, nivel, sola)
		return
```

```gdscript
# A6: funciones nuevas (encima de «# Elegir a qué aliado curar»)

# Artes (artes.gd): las de uno piden objetivo como las de siempre; las de todos, no. Con «sola» (pruebas:
# -- magia=Alba:1), al primero. Si no hay a quién o faltan PM, nada: el menú ya la enseña apagada con su motivo.
func _elegir_arte(fam: String, nv: int, sola := false) -> void:
	var d: Dictionary = Artes.datos(fam, nv)
	var objs: Array = Artes.objetivos(fam, nv, actor, heroes, enemigos, cola, ATB_MAX)
	if objs.is_empty() or not _puede_pagar(d["coste"]):
		return
	if d["todos"]:
		_lanzar_arte(fam, nv, objs)
	elif sola:
		_lanzar_arte(fam, nv, [objs[0]])
	else:
		_pedir_objetivo(objs, func(f): _lanzar_arte(fam, nv, [f]), _menu_magia.bind(0),
			"TOCA UN ENEMIGO" if d["a"] == "enemigos" else "TOCA A UN ALIADO")


# Lanza un arte: gasta los PM, anima a quien lanza (el círculo de siempre con el color de su familia), aplica el
# efecto (artes.gd), suena una vez y acaba el turno (la Armonía +0,15, como cualquier acción).
func _lanzar_arte(fam: String, nv: int, objs: Array) -> void:
	_ocultar_menu()
	estado = "accion"
	var quien = actor
	var d: Dictionary = Artes.datos(fam, nv)
	_gastar_pm(quien, d["coste"])
	_actualizar()
	registro.text = "%s lanza %s" % [quien["nombre"], d["nombre"]]
	quien["animando"] = true
	var circulo := _carga_magia(quien, fam, 1.0 + 0.3 * (nv - 1))
	var p = _p3d(quien)
	if p != null:
		await p.lanzar_magia()
	else:
		await get_tree().create_timer(0.5).timeout
	var extra := int(quien.get("efectos", {}).get("apoyo_turnos", 0.0))   # Báculo del Peregrino (C2)
	var hechos: Array = Artes.aplicar(fam, nv, objs, cola, ATB_MAX, extra)
	_sonar(Artes.sonido(fam, nv))
	var col: Color = Artes.COLOR[fam]
	if fam == "Alba" and nv == 2:
		_fogonazo(Color(0.55, 0.35, 0.8), 0.25, 1.2)   # Peso del Ocaso: la pantalla se tiñe de violeta
	for x in hechos:
		var f: Dictionary = x["f"]
		_onda(_suelo_de(f), Color(col, 0.9), 20.0, 160.0, 0.7, 8.0)
		_particulas(_centro(f) + Vector2(0, 60), Color(col, 1.0), Color(col, 0.0), 26, 1.0, Vector2(40, 120), 60.0,
			Vector2(0, -1), 30.0, Vector2(0, -60), 0.07)
		if x.has("atb"):
			_numero_flotante(f, "Retraso" if x["atb"] < 0.0 else "¡Antes!", col, 32)
		elif x.has("pv"):
			_revivir_visual(f)
			_numero_flotante(f, "+%d" % x["pv"], C_CURA)
		elif x.has("aliento"):
			_numero_flotante(f, "Aliento", col, 30)
		elif x.has("barrera"):
			_numero_flotante(f, "❄ %d" % x["barrera"], col, 30)
		elif x.has("brasa"):
			_numero_flotante(f, "Brasa", col, 30)
	_actualizar()
	_quitar_carga(circulo)
	await get_tree().create_timer(0.9).timeout
	if p != null:
		p.fin_magia()
	await get_tree().create_timer(0.3).timeout
	quien["animando"] = false
	_terminar_turno()


# Lumbre de Retorno: el 3D se levanta (revivir(), que ya tienen los tres modelos); el 2D deshace la pose de caído
# de _restablecer_color (giro de 25° y 30 px abajo).
func _revivir_visual(f: Dictionary) -> void:
	var p = _p3d(f)
	if p != null and p.has_method("revivir"):
		p.revivir()
	elif f.has("cuerpo"):
		f["cuerpo"].rotation_degrees = 0.0
		f["rig"].position = f["rig_base"]
	_restablecer_color(f)


# Al empezar el turno de un héroe, antes de su menú: su Aliento (Segundo Aliento) y la regeneración de su equipo
# (Cinta de Lumi, C1). Sin ninguno de los dos, no hace nada.
func _tic_estados_heroe(f: Dictionary) -> void:
	var con_aliento := int(f.get("aliento", 0)) > 0
	var cura: int = Artes.curar_al_empezar_turno(f, Extra.regen(f.get("efectos", {})))
	if cura > 0:
		_numero_flotante(f, "+%d" % cura, C_CURA)
		if con_aliento:
			_sonar(Artes.SONIDO_ESTADO["aliento"])
		_actualizar()


# Sonidos nuevos: solo si ya están en el catálogo de sonido.gd (si no, Sonido.efecto avisa con un push_warning).
func _sonar(nombre: String) -> void:
	if Sonido.EFECTOS.has(nombre):
		Sonido.efecto(nombre)
```

```gdscript
# A8: después del bucle «for k in NIVELES_MAGIA» del aviso de magias nuevas, con la misma sangría que ese «for»
			for x in Artes.nuevas_al_subir(h["nombre"], gr.datos()[h["nombre"]], nivel - subidos, nivel):   # artes
				await get_tree().create_timer(1.0).timeout
				registro.text = "%s aprende %s" % [h["nombre"], Artes.datos(x[0], x[1])["nombre"]]
```

- **Por qué no se añaden a `MAGIAS`:** `_golpe_visual`, `_lanzar`, `_magia_grupal`, `_desc_magia` y `_elegir_hechizo`
  deciden por el nombre de la familia; las artes no pasan por ninguna de ellas (A5 las desvía antes).
- **Cola del ATB:** `Artes.sumar_atb` nunca pone 100 a mano y `Artes.revivir` saca al caído de la cola (los dos
  riesgos de la fase 0).
- **Acciones normales:** `_lanzar_arte` acaba con `_terminar_turno()`: barra a 0, Armonía +0,15 y fin de combate, como
  cualquier acción.
- **Efectos visuales:** de momento, las piezas 2D de siempre (`_onda`, `_particulas`, `_fogonazo`, `_numero_flotante`)
  y el círculo de carga con el color de la familia. Las escenas `vfx/AlbaVFX.tscn` y `vfx/LumbreVFX.tscn` del diseño
  llegan después, con su precalentado en `carga.gd` y en `_precalentar_efectos` (línea 3090).

### 2.2 `menu_combate.gd`

| # | Función | Línea | Ancla | Cambio |
|---|---|---|---|---|
| B1 | (constantes) | 15 | `const SOMBRA := Color("0B1220")` | Encima: `const Artes := preload("res://artes.gd")` |
| B2 | `_construir` | 358-378 | `	if not pestanas.is_empty():                     # pestañas I · II · III de las magias` | Ancho e icono de cada pestaña (abajo) |
| B3 | `_dibujar_icono` | 518 | `		return` (tras `draw_texture_rect`) | Debajo: `	if Artes.dibujar_icono(c, str(icono), c.size):` / `		return` |
| B4 | `preparar` y `actualizar_grupo` | 234 y 257; 275 | `		n.position = Vector2(X_TEXTO, y - 4)`; `grupo.append(...)`; `		g["brillo"].visible = lleno` | Iconos de estado (abajo) |

```gdscript
# B2: dentro de «if not pestanas.is_empty():», antes del «for i in pestanas.size():»
		var x := X_TEXTO - 12.0                     # I · II · III miden 96 px; las de familia (artes.gd), 64
# y en el bucle:
			var ancho := float(p.get("ancho", 96.0))
			nodo.position = Vector2(x, y)            # (antes: X_TEXTO - 12 + i * 100.0; sin artes, lo mismo)
			nodo.size = Vector2(ancho, FILA_SUB)
			x += ancho + 4.0
			# ... la etiqueta de siempre (con texto "" en las de familia) ...
			if p.has("icono"):                      # pestaña de una familia nueva: su icono
				var ic := Control.new()
				ic.position = (nodo.size - Vector2(34, 34)) * 0.5
				ic.size = Vector2(34, 34)
				ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
				ic.modulate = Color(1, 1, 1, 1.0 if i == pestana else 0.55)
				ic.draw.connect(_dibujar_icono.bind(ic, p["icono"]))
				nodo.add_child(ic)
# y la raya de la elegida (línea 374), centrada en cualquier ancho (con 96 px, la misma x = 30):
				raya.position = Vector2((nodo.size.x - 36.0) * 0.5, FILA_SUB - 10)
```

```gdscript
# B4: en preparar(), dentro del bucle, después de crear la etiqueta del nombre
		var est := Control.new()                    # iconos de estado (artes.gd): coraza, Aliento y Brasa
		est.position = Vector2(935, y + 6)          # entre el nombre y los PV (§3.5 del diseño)
		est.size = Vector2(66, 18)
		est.mouse_filter = Control.MOUSE_FILTER_IGNORE
		est.draw.connect(func():
			var k := 0
			for e in Artes.estados_de(h):
				est.draw_set_transform(Vector2(k * 22.0, 0))
				Artes.dibujar_estado(est, e, Vector2(18, 18))
				k += 1
			est.draw_set_transform(Vector2.ZERO))
		add_child(est)
# y en el grupo.append(...) de la línea 257, la clave «"estados": est».
# En actualizar_grupo(), después de «g["brillo"].visible = lleno»:
		var firma := str(Artes.estados_de(h))
		if g.get("firma", "") != firma:
			g["firma"] = firma
			g["estados"].queue_redraw()
```

- Teclado y mando: Q / E (L1 / R1) ya recorren cualquier número de pestañas (`_unhandled_input`, línea 632).
- Comprobar con capturas que los iconos de estado no tapan PV largos («600/600»): solo se ve en pantalla.

### 2.3 `menus.gd` (Habilidades)

| # | Función | Línea | Ancla | Cambio |
|---|---|---|---|---|
| C-1 | `_pintar_habilidades` | 347 | `					cuerpo.add_child(_texto(texto + "   (se aprende al nivel %d)" % Grupo.NIVEL_MAGIA[i], 18, COLOR_SUAVE))` | Debajo, fuera del `for m`, las artes (abajo) |

```gdscript
		var Artes = load("res://artes.gd")          # artes (artes.gd): solo las que ya están en el juego
		for fam in Artes.familias_de(n):
			var sabe: int = Artes.nivel(n, fam)
			for i in int(Artes.ACTIVOS.get(fam, 0)):
				var d: Dictionary = Artes.datos(fam, i + 1)
				var texto := "   %s %s — %s, %d PM, %s" % [fam, romano[i], d["nombre"], d["coste"], "a todos" if d["todos"] else "a uno"]
				if i < sabe:
					cuerpo.add_child(_texto(texto + "   ✔", 18, COLOR_BIEN))
				else:
					cuerpo.add_child(_texto(texto + "   (se aprende al nivel %d)" % Artes.UMBRALES[fam][i], 18, COLOR_SUAVE))
```

### 2.4 `tienda.gd` (libros de las artes)

| # | Función | Línea | Ancla | Cambio |
|---|---|---|---|---|
| D1 | `_ready` | 42 | `	Grupo = load("res://grupo.gd")` | Debajo: `	Artes = load("res://artes.gd")` (y `var Artes` junto a `var Grupo`, línea 31) |
| D2 | `_pintar`, «Magias» | 162-169 | `			for l in LIBROS:` | `for l in LIBROS + Artes.libros_en_venta():` y las cuatro funciones de abajo en lugar de `NIVELES_MAGIA[...]`, `Grupo.HEROES[h]["magias"]` y `Grupo.nivel_magia` |
| D3 | `_comprar_libro` | 225 | `		if l[0] in Grupo.HEROES[h]["magias"] and Grupo.nivel_magia(h, l[0]) < l[1]:` | `		if _usa(h, l[0]) and _sabe(h, l[0]) < l[1]:` |
| D4 | `_dar_libro` | 248 y 250 | `		Grupo.aprender(heroe, l[0], l[1])` | `_aprender(heroe, l[0], l[1])` y `_nombre_libro(l[0], l[1])` |

```gdscript
# Libros: de las magias de siempre (grupo.gd) o de las artes (artes.gd).
func _usa(h: String, magia: String) -> bool:
	return magia in (Artes.familias_de(h) if Artes.es_arte(magia) else Grupo.HEROES[h]["magias"])


func _sabe(h: String, magia: String) -> int:
	return Artes.nivel(h, magia) if Artes.es_arte(magia) else Grupo.nivel_magia(h, magia)


func _nombre_libro(magia: String, n: int) -> String:
	if Artes.es_arte(magia):
		return Artes.datos(magia, n)["nombre"]
	return load("res://combate.gd").NIVELES_MAGIA[magia][n - 1]["nombre"]


func _aprender(h: String, magia: String, n: int) -> void:
	if Artes.es_arte(magia):
		Artes.aprender(h, magia, n)                 # grupo.gd aprender() no las conoce: lo comprueba prueba_artes
	else:
		Grupo.aprender(h, magia, n)
```

### 2.5 `diario.gd`

| # | Función | Línea | Ancla | Cambio |
|---|---|---|---|---|
| E-1 | pestaña «Combate» | 119 | `		for f in FICHAS:` | `		for f in FICHAS + load("res://artes.gd").fichas_activas():` |

---

## 3. C1: la ranura Accesorio y 6 accesorios

`equipo_extra.gd` limita lo que se vende y se da con `HECHOS`: al enganchar C1, `const HECHOS: Array = ["C1"]`. Con
eso, se venden el Farol (Oakhaven, 220) y la Moneda del Águila (Sunken City, 450); la Lágrima (M3), la Brasa en frasco
(M4) y las armas especiales (C2) siguen fuera.

### 3.1 `inventario.gd`

| # | Función | Línea | Ancla | Cambio |
|---|---|---|---|---|
| F1 | `RANURAS` | 7 | `const RANURAS := [..., "anillo", "amuleto"]` | Añadir `"accesorio"` al final |
| F2 | `NOMBRES_RANURA` | 9 | `	"anillo": "Anillo", "amuleto": "Amuleto"}` | Añadir `"accesorio": "Accesorio"` |
| F3 | `objeto` | 118 | `	return PROTECCIONES.get(id, {})` | Ver abajo |
| F4 | `puede_llevar` | 128-133 | `	return o["para"] == "todos" or o["para"] == tipo` | Encima: `	if o.has("solo") and o["solo"] != heroe:` / `		return false` |
| F5 | `equipar` | 149 | `objeto(id)["ranura"] != ranura` | `objeto(id).get("ranura", "") != ranura` |
| F6 | `opciones` | 162 | `		if objeto(id)["ranura"] == ranura and puede_llevar(heroe, id):` | `objeto(id).get("ranura", "")` |
| F7 | `resumen` | 184 | `	return "  ".join(partes)` | Encima: `	if o.has("efecto"):` / `		partes.append(o["efecto"])` |

```gdscript
# F3: al final de objeto()
	if PROTECCIONES.has(id):
		return PROTECCIONES[id]
	return load("res://equipo_extra.gd").objeto(id)   # accesorios y armas especiales (T-092); {} si no existe
```

- F5 y F6 son la **tolerancia a ids desconocidos** de la fase 0: hoy un id que no existe rompe el menú. Con los ids
  de siempre, el mismo resultado.
- **Para C2** (no ahora): `arma_de` (línea 169) tendrá que buscar también en `equipo_extra.gd ARMAS`, para que los
  modelos 3D carguen la malla de las armas especiales.
- `estadisticas()` de `grupo.gd` no cambia: los accesorios no tienen `ataque`, `magia` ni `bonus` (lo comprueba
  `prueba_equipo`).

### 3.2 `combate.gd`

| # | Función | Línea | Ancla | Cambio |
|---|---|---|---|---|
| G1 | `_ready` | 367 | `			h["mult_magia"] = e["mult_magia"]` | Debajo, las dos líneas de abajo |
| G2 | `_animar_golpe` | 2480 | `	var critico: bool = magia == "" and randf() < PROB_CRITICO` | `randf() < Extra.prob_critico(PROB_CRITICO, origen.get("efectos", {}))` (la misma tirada) |
| G3 | `_animar_golpe` | 2487 | `	var congela: bool = magia == "" and origen["hero"] and _lleva_frostfang(origen) and randf() < PROB_CONGELAR` | Debajo, la esquiva (abajo); y al principio de `impacto`, su salida |
| G4 | `_terminar_turno` | 2051 | `	actor["atb"] = 0.0` | Debajo, los PM del accesorio (abajo) |
| G5 | `_repartir_exp` | 3777 | `	registro.text = "+%d EXP   +%d monedas" % [int(round(total * mult)), oro]` | Encima: `	oro = Extra.oro_con_extra(oro, heroes.map(func(h): return h.get("efectos", {})))   # Moneda del Águila, una vez` |

```gdscript
# G1
			h["efectos"] = Extra.efectos_de(h["nombre"])           # accesorios y armas especiales (T-092)
			h["atb"] = Extra.atb_inicial(h["efectos"], ATB_MAX)     # Farol de peregrino; sin él, 0 como siempre

# G3: debajo de «var congela»
	var esquiva: bool = magia == "" and objetivo["hero"] and Extra.esquiva(objetivo.get("efectos", {}))   # Pluma de arpía
# y la primera línea de «var impacto: Callable = func():»
		if esquiva:                                    # el golpe no llega (solo tira el dado con la pluma puesta)
			_numero_flotante(objetivo, "¡Esquiva!", Color(0.85, 0.95, 1.0), 34)
			return

# G4
	var pm_extra: int = Extra.pm_al_terminar(actor)            # Gota de la cascada alta
	if pm_extra > 0:
		_numero_flotante(actor, "+%d PM" % pm_extra, Color(0.55, 1.0, 0.85), 30)
```

- La **regeneración** (Cinta de Lumi) va en `_tic_estados_heroe` (A6), que ya es de M2.
- **El orden de las tiradas** no cambia sin el equipo nuevo: el crítico es la misma tirada con otro umbral y la esquiva
  solo tira con la pluma (lo comprueba `prueba_equipo` con el generador global).

### 3.3 `menus.gd`

| # | Función | Línea | Ancla | Cambio |
|---|---|---|---|---|
| H1 | `_pintar_objetos`, «Equipo» | 290 | `			if o["ranura"] != r:` | `			if o.get("ranura", "") != r:` |
| H2 | `_pintar_objetos`, «Equipo» | 305 | `... else para[o["para"]], 18, COLOR_SUAVE))` | `... else (("Solo " + o["solo"]) if o.has("solo") else para.get(o["para"], "")), ...` |

- **La fila «Accesorio»** del menú Grupo sale sola, la octava, porque `menus.gd` recorre `Inv.RANURAS` (línea 206).
  Sus ◀ ▶ llevan las claves `ranura:accesorio:-1` y `ranura:accesorio:1`: el foco con teclado y mando ya funciona
  (D-063). «—» (sin accesorio) es una opción, como en las ranuras que no son arma.
- El texto del efecto sale en la línea de resumen (F7). La línea de lore al pie (mejora del diseño, §4.6) queda para
  después.

### 3.4 `tienda.gd`

| # | Función | Línea | Ancla | Cambio |
|---|---|---|---|---|
| I1 | `_pintar`, «Equipo» | 152 y 159 | `			for id in EQUIPO:` | `			for id in _precios_equipo():` y `_precios_equipo()[id]` en lugar de `EQUIPO[id]` |
| I2 | `_comprar_equipo` | 212 | `	if Inv.gastar_oro(EQUIPO[id]):` | `	if Inv.gastar_oro(_precios_equipo()[id]):` |
| I3 | `_pintar`, «Equipo» | 158 | `para[ob["para"]]` | `para.get(ob["para"], "")` |

```gdscript
# Equipo de la tienda: la lista común y, según el lugar (índice de mapa.gd), lo de equipo_extra.gd ya disponible.
func _precios_equipo() -> Dictionary:
	var r: Dictionary = EQUIPO.duplicate()
	r.merge(load("res://equipo_extra.gd").en_tienda(int(Engine.get_meta("lugar", {}).get("indice", -1))))
	return r
```

- **Cofres, secretos y botín** (Diente, Gota, Cinta y Pluma): el código del mundo (T-089, T-090) llamará a
  `load("res://equipo_extra.gd").conseguir(id)`, que lo apunta una vez y devuelve el aviso. `recompensas.gd` (§4.5 del
  diseño) puede quedarse en un reparto pequeño que llame a `conseguir` y a `Artes.aprender` (tomos).

---

## 4. Después (M3, C2 y M4), en resumen

- **M3, Escarcha y la coraza:** `ACTIVOS["Escarcha"] = 2`. En `_quitar_pv` (línea 2075), en un héroe:
  `var r := Artes.absorber(f, d)`, resta `r["resto"]` y devuelve el daño real; si `r["congela"]`, `_congelar` al
  atacante (`objetivo["golpeado_por"]`, que apunta `_animar_golpe` antes del impacto). El golpe devastador (líneas
  1290-1292) pasa a usar `_quitar_pv`. Sonidos `barrera_absorbe` y `barrera_rota`. `HECHOS` += `"M3"` (Lágrima).
- **C2, armas especiales:** `HECHOS` += `"C2"`; `arma_de` (F3 bis); `ataque_recuerdo` en `grupo.gd estadisticas()`;
  `Extra.robo_vida` en el impacto; `Extra.replica` tras el golpe en `_turno_enemigo`; `Extra.quien_cubre` en la línea
  1280 (`var objetivo = _elegir_objetivo(p, vivos)`); `aliento_inicio` en `_ready`; Fauces y Lágrima en `_fin_combate`
  según `combate_fijo`. Necesita `tinte` y `color_brillo` en `material_arma.gd`.
- **M4, los III:** `ACTIVOS` a 3; en `_quitar_pv`, `Artes.al_llegar_a_cero(f)` (Brasa) antes de dar a un héroe por
  caído; `HECHOS` += `"M4"` (Brasa en frasco); tomos.

---

## 5. Peticiones a otros especialistas (sin cambios desde la fase 0)

- **Sonido (`sonido.gd`):** `arte_alba`, `arte_ocaso`, `arte_hora_dorada`, `arte_escarcha`, `arte_lumbre`, `renacer`,
  `aliento` (prioridad baja, uno a la vez), `barrera_absorbe`, `barrera_rota`, `brasa` y uno nuevo, `esquiva` (un
  silbido, para la pluma). Mientras no estén, `_sonar` no los pide.
- **Gráficos (`material_arma.gd`):** `tinte` y `color_brillo` opcionales, en blanco por defecto (C2).
- **`carga.gd`:** precargar las escenas nuevas de `vfx/` cuando existan.

---

## 6. Pruebas al enganchar

- **Siempre:** la batería completa sin fallos nuevos; `prueba_combate_huella` **igual** (dos pasadas y referencia);
  `prueba_artes` y `prueba_equipo`.
- **M1 y M2:** `prueba_menu_magia` (Lya a nivel 1, como hoy), `prueba_mando` y `prueba_teclado` (pestañas),
  `prueba_grupos_combate`, `prueba_incorporacion`, `prueba_equilibrio` e `prueba_ia`. Prueba nueva propuesta con el
  combate enganchado: lanzar el Compás (Lya entra una vez en la cola, PM gastados, Armonía +0,15), el Ocaso, la
  Lumbre de Retorno (el 3D se levanta y vuelve a actuar) y el Segundo Aliento (cura en sus turnos, dura 3); capturas
  de las pestañas y los iconos.
- **C1:** `prueba_foco` y `prueba_mando` (◀ ▶ de la fila Accesorio y el foco que vuelve), `prueba_partida` y
  `prueba_guardado`; un combate con el Farol (empieza con un tercio de barra) y otro con la Moneda (+25 %).

---

## 7. Aplicado (fase 2, 09/11)

Sobre `area-combate` @ `555fc29`. Commits: C0 `30780e5`, M1 y M2 `653d7b6`, C1 `a3c4432`, menú y pruebas `5e3bf18`.
Las líneas de las tablas de arriba son de `2386761`; en `combate.gd` y `menu_combate.gd` no habían cambiado.

| Enganche | Aplicado | Diferencias con lo de arriba |
|---|---|---|
| C0.1 a C0.3 | Sí | Infierno y Cólera del Cielo entran en un **E9** nuevo y no en E4: así E1 a E8 siguen idénticos, línea a línea, a la primera referencia |
| A1 a A8 | Sí | — |
| B1 a B4 | Sí | Además, `_ajustar_nombre`: si un nombre de submenú no cabe junto a su coste, se juntan las letras y, si hace falta, baja el tamaño (no menos de 26) |
| C-1 | Sí | — |
| D1 a D4 | Sí | — |
| E-1 (`diario.gd`) | **No**: es de narrativa | El cambio exacto, en el informe |
| F1 a F7 | Sí | — |
| G1 a G5 | Sí | La esquiva tampoco hace sonar el golpe ni la voz; `ultimo_esquivado`: Gorthor no se cura si su mordisco se esquiva |
| H1 y H2 | Sí | Y `get("nombre", "—")` en la fila de cada ranura |
| I1 a I3 | Sí | Lo propio del lugar sale **primero** en la lista |
| `HECHOS = ["C1"]` | Sí | — |

**Cambios que no estaban en la lista** (vistos en las capturas o medidos en las pruebas):
- `artes.gd`, `filas_familia`: a la derecha, solo el coste («6 PM»). Con «I · 6 PM», el nombre pisaba el coste.
- `artes.gd`, `estados_de`: un héroe caído no tiene iconos.
- `menus.gd`, menú Grupo: con la octava ranura, el ▶ de Accesorio salía cortado (medido: ▶ de y = 611 a 652 y la
  lista acababa en 633). Ahora el panel mide 640 (40 px de margen arriba y abajo), la lista 560, la columna del equipo
  va con 3 px entre filas y «Arma: solo espadas.» va junto al título «Equipo».
- `pruebas/combate_con_artes.gd` y la pasada «con_enganches» de la huella, borrados: ya no hacen falta.

**Pruebas:** `prueba_combate_huella` (9 combates, referencia nueva con E9), `prueba_artes`, `prueba_artes_combate`
(con `combate.tscn` y el escenario D), `prueba_equipo`, `prueba_equipo_combate` y `prueba_controles_nuevos` (nuevas), y
`prueba_combate_fotos` (con ventana).
