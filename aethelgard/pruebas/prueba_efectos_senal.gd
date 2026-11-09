extends SceneTree
# Lo que sale DE VERDAD por el altavoz con los efectos (T-083), como prueba_musica_senal: con ventana y el driver de
# audio real se graba el bus Master (AudioEffectRecord) mientras suena cada efecto del catálogo SOLO (variante 1, sin
# variación de tono ni de volumen, con su volumen del catálogo) y se mide: pico, RMS de la parte con señal y duración.
# También el río y la cascada como sonido 3D (a 1, 2 y 4 veces su distancia de referencia) y tres escenas seguidas
# para escuchar la mezcla: pasos sobre hierba, un combate (golpes y victoria, que baja lo demás) y abrir un cofre.
# Deja un WAV por grabación en <carpeta> y, con «muestras=<carpeta>», los copia allí con un índice (indice.md) para que
# una persona los escuche. Esto mide que HAY señal y a qué nivel; cómo suena no lo dice ninguna prueba.
#   Godot --path aethelgard --script res://pruebas/prueba_efectos_senal.gd --fixed-fps 30 -- <carpeta> [muestras[=<carpeta>]]
#        [efectos=<prefijo>,<prefijo>…]   (solo esos efectos sueltos y las mezclas de la tanda 2: para no rehacerlo todo)
# («muestras» sin carpeta: D:/REBELUM_diagnostico/sonido_muestras/<fecha de hoy>)
# FALLO si un efecto no da señal (RMS < -60 dBFS) o satura a la salida (pico ≥ -0,3 dBFS).
# Tanda 2: voces de los enemigos (cada una sola y cuatro combates seguidos), la palanca de la Garganta con su puerta, y
# el río de las zonas 2D a 0, 3 y 6 casillas de la orilla (solo y con el ambiente de la pradera debajo).

const PROCEDENCIA := "docs/audio/efectos_procedencia.csv"
const EVENTOS := {
	"paso_hierba": "Paso de Kael en la hierba (Pastos Verdes 3D, llanuras 2D)",
	"paso_piedra": "Paso en las losas del camino, el puente de piedra, la ciudad flotante y las calles",
	"paso_hojas": "Paso en el suelo del bosque (zonas 2D de bosque)",
	"paso_nieve": "Paso en la nieve (zonas 2D de nieve)",
	"paso_grava": "Paso en la tierra y la grava de caminos y montañas (zonas 2D)",
	"paso_arena": "Paso en la arena y la ceniza (desierto y ceniza)",
	"paso_madera": "Paso en los puentes de tablas (zonas 2D)",
	"golpe": "Golpe físico resuelto (cualquier atacante, también Embuir y el Giro de Esgrima)",
	"golpe_critico": "Golpe crítico, Juicio de Esgrima, golpe cargado del jefe y «Acabar»",
	"golpe_defendido": "Golpe contra un héroe que se defiende",
	"defensa": "Orden DEFENDER: el héroe se pone en guardia",
	"salto": "Kael 3D salta con el sable (antes del tajo)",
	"huida": "El grupo huye (y, más bajo, un enemigo que huye)",
	"emboscada": "Empieza un encuentro (mapa, zonas, Pastos Verdes y Garganta); sigue al entrar al combate",
	"jefe": "Presentación de un jefe (su nombre en grande)",
	"fase2": "Segunda fase del jefe («¡Furia del abismo!»)",
	"carga_jefe": "El jefe carga su golpe devastador (aviso)",
	"embuir": "Garon imbuye sus espadas (Embuir)",
	"victoria": "Victoria",
	"derrota": "Derrota",
	"nivel": "Un héroe sube de nivel",
	"monedas": "Monedas ganadas al vencer y compras en la tienda",
	"pocion": "Poción o Éter (combate y menú; el Éter, un poco más agudo)",
	"cofre": "Se abre un cofre (Pastos Verdes 3D, zonas 2D, Garganta)",
	"tesoro": "El premio del cofre (0,3 s después) y la mecha de Tilo (PV-14)",
	"union": "Lya (PV-03) o Garon (PV-05) se unen al grupo",
	"examinar": "Examinar un detalle (la estela, los detalles de lore)",
	"pagina": "Nueva página en el Diario; abrir el Diario",
	"misterio": "Nueva página en el Diario (con la página, 0,2 s después)",
	"palanca": "Tirar de la palanca de la Garganta",
	"atascado": "El ascensor de la Garganta sin fuerza",
	"puente_baja": "El puente que baja a lo lejos (Garganta, tras la palanca)",
	"ascensor": "Viajar en el ascensor de la Garganta",
	"cerrada": "La puerta sellada de la Garganta no cede",
	"guardado": "Guardar en el punto de guardado de la Garganta",
	"posada": "Descansar en la posada",
	"portal": "Cruzar el portal a la ciudad flotante y bajar de ella",
	"entrar": "Entrar en un lugar desde el mapa del mundo",
	"ui_tic": "Mover el cursor o cambiar de pestaña (hecho por código, el de siempre)",
	"ui_confirmar": "Confirmar (hecho por código, el de siempre)",
	"ui_clac": "Girar ATACAR ⇄ DEFENDER (hecho por código, el de siempre)",
	"ui_mejora": "Subir un atributo en el menú del grupo",
	"ui_abrir": "Abrir el menú del grupo o la tienda",
	"ui_cerrar": "Cerrar el menú del grupo o la tienda",
	"ui_atras": "Atrás en la tienda (al elegir quién aprende una magia)",
	"ui_error": "Opción apagada, compra o posada sin dinero",
	"ui_equipar": "Cambiar escudo, armadura o accesorio",
	"ui_equipar_arma": "Cambiar de arma",
	"rafaga_hierba": "Ráfaga de viento en la hierba (pradera, ciudad flotante…, de vez en cuando)",
	"rafaga_arbol": "Ráfaga entre los árboles (bosque, de vez en cuando)",
	"pajaro": "Un pájaro (pradera y ciudades, de vez en cuando)",
	"hojas": "Hojas que se mueven (bosque, de vez en cuando)",
	"gota": "Una gota (mazmorra, de vez en cuando)",
	"rio": "El río de Pastos Verdes 3D (sonido 3D a lo largo del barranco)",
	"cascada": "La cascada de Pastos Verdes 3D (sonido 3D)",
	# tanda 2
	"congelar": "Un enemigo se congela (Frostfang o Embuir de hielo)",
	"limo_ataque": "El limo (slime) se lanza al ataque",
	"limo_herido": "El limo recibe un golpe físico",
	"limo_caida": "El limo cae (golpe físico)",
	"goblin_ataque": "Grimfang se lanza al ataque (más fuerte y grave con furia)",
	"goblin_herido": "Grimfang recibe un golpe físico",
	"goblin_caida": "Grimfang cae (golpe físico)",
	"gorthor_ataque": "Gorthor se lanza al ataque",
	"gorthor_herido": "Gorthor recibe un golpe físico",
	"gorthor_caida": "Gorthor cae de rodillas (último aliento)",
	"gorthor_muerte": "«Acabar» con Gorthor",
	"gorthor_devorar": "El mordisco de Gorthor (Devorar, segunda fase)",
	"piedra_ataque": "El Guardián de piedra se lanza al ataque",
	"piedra_herido": "El Guardián de piedra recibe un golpe físico",
	"piedra_caida": "El Guardián de piedra se derrumba",
	"ambar_ataque": "El Gólem de ámbar se lanza (la piedra, más aguda)",
	"ambar_herido": "El Gólem de ámbar recibe un golpe físico",
	"ambar_caida": "El Gólem de ámbar se derrumba",
	"puerta_abre": "La puerta sellada de la Garganta se abre a lo lejos (1,3 s tras la palanca)",
	"brazalete": "El brazalete de Kael brilla junto a un detalle sin ver (zonas 2D)",
	"libro_hoja": "Cambiar de pestaña en el Diario",
	"libro_cerrar": "Cerrar el Diario",
	"rio_2d": "El río de las zonas 2D (por cercanía)",
}
const DOS_D_CASILLA := 64.0                                # zona.gd, T

var Son
var Mus
var rec: AudioEffectRecord
var salida := ""
var muestras := ""
var fallos: Array = []
var filas: Array = []                                      # [archivo, efecto, evento, juego, fuente, licencia, pico, rms, dur]
var procedencia := {}                                      # derivado → [fuente, capas]
var solo := PackedStringArray()                            # «efectos=…»: solo los que empiezan así (y la tanda 2)


func _initialize() -> void:
	_grabar_todo.call_deferred()


func _real(segundos: float) -> void:
	var fin := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < fin:
		await process_frame


func _grabar_todo() -> void:
	var args := OS.get_cmdline_user_args()
	salida = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://")
	for a in args:
		if a.begins_with("muestras="):
			muestras = a.substr(9)
		elif a == "muestras":                              # la carpeta de hoy, fuera del proyecto
			muestras = "D:/REBELUM_diagnostico/sonido_muestras/" + Time.get_date_string_from_system()
		elif a.begins_with("efectos="):
			solo = a.substr(8).split(",", false)
	Son = root.get_node("Sonido")
	Mus = root.get_node("Musica")
	_leer_procedencia()
	Mus.pedir("silencio")                                  # sin ambientes de fondo
	await _real(2.5)
	rec = AudioEffectRecord.new()
	AudioServer.add_bus_effect(0, rec)
	# cada efecto, solo
	for nombre in Son.EFECTOS:
		if Son.EFECTOS[nombre].has("tres_d") or Son.EFECTOS[nombre].has("dos_d"):
			continue
		if not solo.is_empty() and not Array(solo).any(func(s): return String(nombre).begins_with(s)):
			continue
		Son.reiniciar_contadores()
		rec.set_recording_active(true)
		await _real(0.15)
		var p = Son.efecto(nombre, {"variante": 0})
		if p == null:
			rec.set_recording_active(false)
			fallos.append("%s no suena (%s)" % [nombre, str(Son.descartes)])
			continue
		await _real(p.stream.get_length() / maxf(p.pitch_scale, 0.1) + 0.45)
		rec.set_recording_active(false)
		_medir(rec.get_recording(), nombre, nombre, _juego(nombre))
	if not solo.is_empty():                                # solo la tanda 2: sus mezclas y el río 2D
		await _tanda2()
		AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
		_indice()
		for f in fallos:
			print("FALLO: ", f)
		print("FALLOS: %d" % fallos.size())
		quit(1 if fallos.size() > 0 else 0)
		return
	# el río y la cascada, en 3D: a 1, 2 y 4 veces su distancia de referencia
	var mundo := Node3D.new()
	root.add_child(mundo)
	var cam := Camera3D.new()
	mundo.add_child(cam)
	cam.make_current()
	await _real(0.2)
	for nombre in ["rio", "cascada"]:
		var unidad: float = Son.EFECTOS[nombre]["tres_d"]["unidad"]
		var e: AudioStreamPlayer3D = Son.fuente_3d(mundo, nombre, Vector3(0, 0, -unidad))
		for k in [1.0, 2.0, 4.0]:
			e.position = Vector3(0, 0, -unidad * k)
			await _real(0.5)
			rec.set_recording_active(true)
			await _real(4.0)
			rec.set_recording_active(false)
			_medir(rec.get_recording(), "%s_a_%dm" % [nombre, int(unidad * k)], nombre,
				"%s · a %.0f m" % [_juego(nombre), unidad * k])
		e.queue_free()
		await _real(0.3)
	mundo.queue_free()
	await _real(0.3)
	# escenas seguidas, para escuchar la mezcla
	await _escena("mezcla_pasos_hierba", [[0.0, "paso_hierba"], [0.33, "paso_hierba"], [0.66, "paso_hierba"],
		[0.99, "paso_hierba"], [1.32, "paso_hierba"], [1.65, "paso_hierba"], [1.98, "paso_hierba"], [2.31, "paso_hierba"]],
		"Ocho pasos seguidos en la hierba, con sus variantes y su tono al azar (¿se nota que se repiten?)")
	await _escena("mezcla_combate", [[0.0, "salto"], [0.45, "golpe"], [1.2, "golpe_critico"], [1.9, "victoria"],
		[2.3, "golpe"], [3.6, "monedas"], [5.0, "nivel"]],
		"Salto, golpe, crítico y victoria; el golpe que llega durante la victoria va más bajo; monedas y nivel")
	await _escena("mezcla_cofre", [[0.0, "cofre"], [0.3, "tesoro"]], "Abrir un cofre: la tapa y el premio")
	await _tanda2()
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	_indice()
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _escena(nombre: String, golpes: Array, texto: String) -> void:
	Son.reiniciar_contadores()
	rec.set_recording_active(true)
	await _real(0.15)
	var t0 := Time.get_ticks_msec()
	for g in golpes:
		while Time.get_ticks_msec() - t0 < int(g[0] * 1000.0):
			await process_frame
		Son._ultimo.erase(g[1])
		Son.efecto(g[1], g[2] if g.size() > 2 else {})
	await _real(2.0)
	rec.set_recording_active(false)
	_medir(rec.get_recording(), nombre, "", texto)


# Tanda 2: combates seguidos con las voces (con los tiempos de verdad de sus animaciones), la palanca de la Garganta y
# el río de las zonas 2D.
func _tanda2() -> void:
	await _escena("mezcla_limo", [[0.0, "limo_ataque"], [0.45, "golpe"], [1.6, "salto"], [2.05, "golpe"],
		[2.05, "limo_herido"], [3.4, "golpe"], [3.4, "limo_caida"], [4.6, "victoria"]],
		"El limo se lanza y golpea; Kael le da (herido) y lo tumba (caída); victoria")
	await _escena("mezcla_grimfang", [[0.0, "goblin_ataque"], [0.78, "golpe"], [1.40, "golpe", {"db": -6.0}],
		[2.6, "golpe"], [2.6, "goblin_herido"], [3.9, "golpe_critico"], [3.9, "goblin_caida"], [5.1, "victoria"]],
		"Grimfang: su voz, el doble tajo (el segundo 6 dB más bajo); Kael le da y lo tumba con un crítico; victoria")
	await _escena("mezcla_piedra_ambar", [[0.0, "piedra_ataque"], [0.6, "golpe"], [1.8, "golpe"], [1.8, "piedra_herido"],
		[3.0, "golpe"], [3.0, "piedra_caida"], [5.0, "ambar_ataque"], [5.6, "golpe"], [6.8, "golpe"], [6.8, "ambar_herido"],
		[8.0, "golpe"], [8.0, "ambar_caida"]],
		"El Guardián de piedra (ataque, herido, derrumbe) y después el Gólem de ámbar (lo mismo, con cristal)")
	await _escena("mezcla_gorthor", [[0.0, "jefe"], [2.2, "gorthor_ataque"], [3.0, "golpe"], [3.0, "gorthor_devorar"],
		[3.62, "golpe", {"db": -6.0}], [5.0, "golpe"], [5.0, "gorthor_herido"], [6.6, "gorthor_caida"],
		[9.0, "golpe_critico"], [9.0, "gorthor_muerte"]],
		"Gorthor: presentación, su voz y su mordisco (Devorar), herido, de rodillas y «Acabar»")
	await _escena("mezcla_garganta_palanca", [[0.0, "palanca"], [0.5, "puente_baja"], [1.3, "puerta_abre"]],
		"La palanca de la Garganta: el puente que baja y la puerta sellada que se abre, a lo lejos")
	await _rio_2d()


# El río de las zonas 2D (sonido.gd, Agua2D) con una zona de mentira: el río es una franja de agua de lado a lado y quien
# escucha (la cámara) está con «Kael» a 0, 3 y 6 casillas de la orilla. Después, a 3 casillas con el ambiente de la
# pradera debajo, como en una llanura.
func _rio_2d() -> void:
	var z := ZonaRio.new()
	root.add_child(z)
	var cam := Camera2D.new()
	z.jugador.add_child(cam)
	cam.make_current()
	var e = Son.agua_zona(z)
	if e == null:
		fallos.append("rio_2d: no se crea el emisor del río 2D")
		z.queue_free()
		return
	for casillas in [0.3, 3.0, 6.0]:
		z.jugador.position = Vector2(40.0, z.FILA - 0.5 - casillas) * DOS_D_CASILLA
		await _real(1.8)                                   # fundido y búsqueda
		rec.set_recording_active(true)
		await _real(4.0)
		rec.set_recording_active(false)
		_medir(rec.get_recording(), "rio_2d_a_%d_casillas" % int(round(casillas)), "rio_2d",
			"%s · a %.0f casillas de la orilla (%.1f dB)" % [EVENTOS["rio_2d"], casillas, e.volume_db])
	z.jugador.position = Vector2(40.0, z.FILA - 3.5) * DOS_D_CASILLA
	Mus.pedir("pradera")
	await _real(3.0)
	rec.set_recording_active(true)
	await _real(6.0)
	rec.set_recording_active(false)
	_medir(rec.get_recording(), "mezcla_rio_2d_y_pradera", "",
		"El río 2D a 3 casillas con el ambiente de la pradera (−6 dB) debajo, como en una llanura (¿tapa algo?)")
	Mus.pedir("silencio")
	z.queue_free()
	await _real(1.0)


class ZonaRio extends Node2D:
	const T := 64
	const ANCHO := 80
	const ALTO := 56
	const FILA := 30                                       # el río: las filas de vértices 30 a 33, de lado a lado
	var estilo := {"agua": "agua"}
	var agua_v := PackedByteArray()
	var jugador := Node2D.new()
	var saliendo := false

	func _init() -> void:
		agua_v.resize((ANCHO + 1) * (ALTO + 1))
		for y in range(FILA, FILA + 4):
			for x in ANCHO + 1:
				agua_v[y * (ANCHO + 1) + x] = 1
		add_child(jugador)


func _juego(nombre: String) -> String:
	var d: Dictionary = Son.EFECTOS.get(nombre, {})
	if d.has("codigo"):
		return "(hecho por código: menu_combate.gd)"
	var a: String = d.get("a", "")
	return "audio/efectos/" + a + ("1.wav (de %d)" % int(d["n"]) if d.has("n") else ".wav")


func _medir(w: AudioStreamWAV, archivo: String, efecto: String, evento: String) -> void:
	if w == null:
		fallos.append("%s: no hay grabación (¿driver de audio?)" % archivo)
		return
	var b: PackedByteArray = w.data
	var n := b.size() / 2
	var ventana := int(w.mix_rate * 0.01) * 2              # 10 ms, estéreo
	var env: Array = []
	var pico := 0.0
	var i := 0
	while i < n:
		var s := 0.0
		var k := 0
		while k < ventana and i + k < n:
			var v := b.decode_s16((i + k) * 2) / 32768.0
			s += v * v
			pico = maxf(pico, absf(v))
			k += 1
		env.append(sqrt(s / maxf(1.0, k)))
		i += ventana
	var pico_db := linear_to_db(maxf(pico, 1e-6))
	var umbral := db_to_linear(pico_db - 40.0)
	var a := -1
	var z := -1
	var suma := 0.0
	var cuenta := 0
	for j in env.size():
		if env[j] > umbral:
			if a < 0:
				a = j
			z = j
	if a >= 0:
		for j in range(a, z + 1):
			suma += env[j] * env[j]
			cuenta += 1
	var rms_db := linear_to_db(maxf(sqrt(suma / maxf(1.0, cuenta)), 1e-6))
	var dur := 0.0 if a < 0 else (z - a + 1) * 0.01
	var ruta := "%s/%s.wav" % [salida, archivo]
	w.save_to_wav(ruta)
	print("SEÑAL %-26s pico %6.1f dBFS · RMS %6.1f dBFS · %.2f s con señal" % [archivo, pico_db, rms_db, dur])
	if rms_db < -60.0 or a < 0:
		fallos.append("%s no da señal (RMS %.1f dBFS)" % [archivo, rms_db])
	elif pico_db >= -0.3:
		fallos.append("%s satura a la salida (pico %.1f dBFS)" % [archivo, pico_db])
	var fuente := ""
	var licencia := ""
	if efecto != "":
		var d: Dictionary = Son.EFECTOS[efecto]
		if d.has("codigo"):
			fuente = "Propio (hecho por código)"
			licencia = "Propia"
		else:
			var der: String = d["a"] + ("1" if d.has("n") else "") + ".wav"
			var pr: Array = procedencia.get(der, ["", ""])
			fuente = pr[0].get_file() + (" + " + pr[1] if pr[1] != "" else "")
			licencia = _licencia(pr[0])
	filas.append([archivo + ".wav", efecto, EVENTOS.get(efecto, evento) if efecto != "" else evento,
		_juego(efecto) if efecto != "" else "", fuente, licencia, pico_db, rms_db, dur])


func _licencia(fuente: String) -> String:
	if fuente.begins_with("C/"):
		var s := fuente.get_file().get_basename().get_slice("_", fuente.get_file().get_basename().get_slice_count("_") - 1)
		return "CC0 (colección «500 GAME SOUND EFFECTS», fuente %s)" % s
	if fuente.begins_with("S"):
		return "Sonniss GDC 20%s (licencia del paquete: juegos, sin atribución)" % fuente.substr(1, 2)
	return "?"


func _leer_procedencia() -> void:
	var csv := ProjectSettings.globalize_path("res://").path_join("../" + PROCEDENCIA).simplify_path()
	var f := FileAccess.open(csv, FileAccess.READ)
	if f == null:
		return
	f.get_line()
	while not f.eof_reached():
		var c := f.get_line().split(";")
		if c.size() >= 5:
			procedencia[c[0]] = [c[1], c[4]]


func _indice() -> void:
	var dir := muestras if muestras != "" else salida
	if muestras != "":
		DirAccess.make_dir_recursive_absolute(muestras)
		for fila in filas:
			DirAccess.copy_absolute("%s/%s" % [salida, fila[0]], "%s/%s" % [muestras, fila[0]])
	var t := PackedStringArray()
	t.append("# Muestras de los efectos de sonido (T-083)")
	t.append("")
	t.append("Grabadas el %s del bus Master con el driver de audio real (prueba_efectos_senal.gd), cada efecto solo y" %
		Time.get_datetime_string_from_system(false, true))
	t.append("con su volumen del juego (variante 1, sin variación). **Nadie las ha escuchado todavía**: las pruebas")
	t.append("miden que hay señal y a qué nivel, no cómo suena. Volumen de referencia: Master a 0 dB y cada bus al 100 %.")
	t.append("")
	t.append("| Muestra | Efecto | Evento del juego | Archivo del juego | Fuente | Licencia | Pico (dBFS) | RMS (dBFS) | Duración (s) |")
	t.append("|---|---|---|---|---|---|---|---|---|")
	for f in filas:
		t.append("| %s | %s | %s | %s | %s | %s | %.1f | %.1f | %.2f |" % f)
	t.append("")
	t.append("Para escuchar: lo mejor, con auriculares y el volumen a mitad. Fíjate en: si algo suena «de otro juego»")
	t.append("(demasiado moderno o de dibujos), si los pasos se notan repetidos, si los golpes tapan la música, si la")
	t.append("victoria y la derrota encajan, y si el río y la cascada se oyen bien sin molestar.")
	var csv_magias := "%s/magias/magias_procedencia.csv" % dir
	if FileAccess.file_exists(csv_magias):                 # la propuesta de magias (prueba_efectos_preparar «magias=»)
		t.append("")
		t.append("## Magias: PROPUESTA, no integrada (D-048)")
		t.append("")
		t.append("Un candidato por magia y nivel, en `magias/`: el archivo tal cual quedaría (sin pasar por el juego ni por")
		t.append("sus buses). Ninguna magia suena en el juego; la tabla con la licencia y el enganche que tendría cada una")
		t.append("está en `docs/audio/inventario_sonidos.md`.")
		t.append("")
		t.append("| Muestra | Fuente | Tramo (s) | Capas y tono | Pico (dBFS) | RMS (dBFS) | Duración (s) |")
		t.append("|---|---|---|---|---|---|---|")
		var fm := FileAccess.open(csv_magias, FileAccess.READ)
		fm.get_line()
		while not fm.eof_reached():
			var c := fm.get_line().split(";")
			if c.size() >= 9:
				t.append("| magias/%s | %s | %s-%s | %s | %s | %s | %s |" % [c[0], c[1].get_file(), c[2], c[3], c[4], c[7], c[8], c[6]])
	var f := FileAccess.open("%s/indice.md" % dir, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(t) + "\n")
		f.close()
	print("INDICE %s/indice.md (%d muestras)" % [dir, filas.size()])
