extends Node3D
# DUEÑO: agente B — stub de la fase 0. Firmas EXACTAS del contrato (docs/v12/BARRIO_OAKHAVEN_PLAN.md §11) con valores
# neutros: no hace nada, pero la región (zonas3d/barrio/barrio.gd) ya lo crea, lo llama y no se rompe.
#
# Los tres interiores (horno, taller, vivienda) van en la MISMA escena del barrio, cada uno en su ORIGEN lejano y oculto
# cuando no se usa (plan §3 y §8). Lo que la región espera de este archivo (docs/v12/BARRIO_OAKHAVEN.md, «Contrato»):
#   - ORIGEN: id → Vector3. Un id que NO está en ORIGEN es un interior sin construir: la región dice «Aún no se puede
#     entrar (en obras)» y no hace el fundido. En este stub está vacío (ningún interior hecho).
#   - construir(region): se llama una vez en el _ready de la región (ya hay Kael y cámara). Aquí se cuelgan los
#     sub-árboles de cada interior (ocultos y con PROCESS_MODE_DISABLED).
#   - preparar(id): la región lo llama cuando Kael está a menos de 8 m de la puerta (una vez por id): carga en diferido.
#   - mostrar(id): enseña ese interior y oculta los demás; mostrar("") los oculta todos (al salir).
#   - entrada(id) / mira_entrada(id): dónde aparece Kael al entrar y hacia dónde mira (rotation.y de Godot).
#   - salida(id): dónde está el botón «Salir» dentro (el sitio de fuera lo da trazado.gd, PUERTAS[id]["fuera"]).
#   - andable(p) / altura(p): lo que se pisa dentro (la región lo usa en _prohibido mientras interior != "").
#   - camara(id, k): [posición Vector3, rotación en grados Vector3, campo float] de la cámara propia con Kael en k;
#     [] = la región usa la del exterior.
#   - sonda(p): Vector2(sol, cielo) dentro.
#   - ancla(nombre): las anclas «int_<id>_<nombre>» (plan §11) en coordenadas del mundo.

const IDS := ["horno", "taller", "vivienda"]
const ORIGEN := {}                       # (stub) B: {"horno": Vector3(-300, 0, 200), "taller": …, "vivienda": …}
const SONDA_NEUTRA := Vector2(1.0, 0.7)

var region = null


# El interior en el que cae p ("" = fuera). Lo usa la región para no restaurar a Kael dentro de un ORIGEN.
static func interior_de(_p: Vector3) -> String:
	return ""


func construir(r) -> void:
	region = r


func preparar(_id: String) -> void:
	pass


func mostrar(_id: String) -> void:
	pass


func entrada(_id: String) -> Vector3:
	return Vector3.ZERO


func mira_entrada(_id: String) -> float:
	return 0.0


func salida(_id: String) -> Vector3:
	return Vector3.ZERO


func andable(_p: Vector3) -> bool:
	return false


func altura(_p: Vector3) -> float:
	return 0.0


func abrir_paso(_nombre: String, _abierto: bool) -> void:
	pass


func ancla(_nombre: String) -> Vector3:
	return Vector3.ZERO


func camara(_id: String, _k: Vector3) -> Array:
	return []


func sonda(_p: Vector3) -> Vector2:
	return SONDA_NEUTRA


# Cachés estáticas (materiales, mapas de luz…): las suelta banco_pruebas.salir() y la región al salir del árbol.
static func soltar_caches() -> void:
	pass
