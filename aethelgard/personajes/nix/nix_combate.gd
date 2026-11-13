extends RefCounted
# Nix (V12, PROTOTIPO APAGADO tras «nix_v12», grupo.gd): las reglas propias de su magia negra en el combate ATB.
# Los datos de sus tres hechizos piloto están en magia_negra.gd (HECHIZOS «nix_ascuas», «nix_aguja», «nix_colapso»)
# y van por la ruta de siempre de la magia negra (combate.gd _lanzar_negra, _resolver_negra, _golpe_negra): este
# módulo solo añade lo que la especificación pide y el juego no tenía (docs/v12/NIX_V12.md):
#   - ECLIPSE: hasta 3 sellos (f["nx_sellos"]). Un hechizo de rango I-IV que resuelva y afecte al menos a un blanco
#     válido da 1 sello (uno por acción, aunque alcance a varios). Los de rango V gastan 2 y los de VI, 3; los que
#     gastan sellos no dan. Se pierden al acabar el combate (viven en el diccionario del luchador, como los estados).
#   - Tiempo de espera (CD) en TURNOS PROPIOS: «cd 4» impide sus cuatro oportunidades siguientes (f["nx_cd"]).
#   - Probabilidad base de los estados («prob»): la tira el generador del combate, solo cuando Nix lanza el hechizo.
#   - Reparto en área (magia_negra.gd dano_base, «reparto_area»): con 4 o más blancos, cada uno recibe ×3/n.
# Con Nix fuera del combate nada de aquí se ejecuta: la huella del combate (C0) no cambia.

const SELLOS_MAX := 3
const COLOR_SELLO := Color("E8D9A0")


static func es_suyo(d: Dictionary) -> bool:
	return d.has("nix")


static func sellos(f: Dictionary) -> int:
	return int(f.get("nx_sellos", 0))


static func cd(f: Dictionary, fam: String) -> int:
	return int(f.get("nx_cd_turno", {}).get(fam, 0))


# Por qué no se puede lanzar ahora ("" si se puede). Se valida antes de confirmar: nada se cobra si no se puede.
static func motivo(f: Dictionary, fam: String, d: Dictionary) -> String:
	if not es_suyo(d):
		return ""
	var faltan := int(d.get("sellos", 0)) - sellos(f)
	if faltan > 0:
		return "Necesita %d sellos de Eclipse: tiene %d." % [int(d["sellos"]), sellos(f)]
	var espera := cd(f, fam)
	if espera > 0:
		return "Aún no: %d turno%s de espera." % [espera, "" if espera == 1 else "s"]
	return ""


# Lo que se lee a la derecha de la fila del menú (antes del coste): «◈3 · » si gasta sellos.
static func prefijo(d: Dictionary) -> String:
	if es_suyo(d) and int(d.get("sellos", 0)) > 0:
		return "◈%d · " % int(d["sellos"])
	return ""


# Al confirmar el hechizo: gasta los sellos y empieza la espera (los PM los cobra combate.gd, como siempre).
static func al_confirmar(f: Dictionary, fam: String, d: Dictionary) -> void:
	if not es_suyo(d):
		return
	f["nx_sellos"] = maxi(0, sellos(f) - int(d.get("sellos", 0)))
	if int(d.get("cd", 0)) > 0:
		if not f.has("nx_cd"):
			f["nx_cd"] = {}
		f["nx_cd"][fam] = int(d["cd"])
		if not f.has("nx_cd_turno"):
			f["nx_cd_turno"] = {}
		f["nx_cd_turno"][fam] = int(d["cd"])
	f["nx_afecto"] = false


# Al empezar cada turno propio: lo que queda de espera ESTE turno y lo que quedará en el siguiente.
static func al_empezar_turno(f: Dictionary) -> void:
	if not f.has("nx_cd"):
		return
	var t := {}
	for fam in f["nx_cd"]:
		var n := int(f["nx_cd"][fam])
		t[fam] = n
		f["nx_cd"][fam] = maxi(0, n - 1)
	f["nx_cd_turno"] = t


# ¿Entra el estado? (probabilidad base de la especificación; sin «prob», como siempre: entra).
static func estado_entra(d: Dictionary) -> bool:
	if not es_suyo(d) or not d.has("prob"):
		return true
	return randf() < float(d["prob"])


# Un golpe o un estado que llegó a un blanco válido (para el sello).
static func marcar_afecto(f: Dictionary, d: Dictionary) -> void:
	if es_suyo(d):
		f["nx_afecto"] = true


# Tras resolver: da un sello si toca. Devuelve true si lo dio (combate.gd lo enseña).
static func tras_resolver(f: Dictionary, d: Dictionary) -> bool:
	if not es_suyo(d):
		return false
	var dio := false
	if bool(d.get("genera_sello", false)) and bool(f.get("nx_afecto", false)) and sellos(f) < SELLOS_MAX \
			and f["hp"] > 0:
		f["nx_sellos"] = sellos(f) + 1
		dio = true
	f["nx_afecto"] = false
	return dio


static func texto_sellos(f: Dictionary) -> String:
	return "Eclipse %s" % "".join(range(SELLOS_MAX).map(func(i): return "◆" if i < sellos(f) else "◇"))
