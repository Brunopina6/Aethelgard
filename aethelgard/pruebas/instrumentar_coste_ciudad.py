# MEDIDA (18/11), NO prueba: instrumentación TEMPORAL para medir en el PC el coste en el hilo principal de los arreglos de
# la ciudad tras el Redmi (docs/v12/ciudad_sectores/MEDIDAS_PC.md §7). Envuelve unas funciones de ciudad.gd y grupo_3d.gd
# con un reloj (Time.get_ticks_usec) que suma en «_coste_x» = {clave: [µs, llamadas]}; medir_ciudad.gd y
# medir_coste_grupo.gd lo recogen y lo vacían en cada fotograma. Sirve igual con el código de antes (70b5f82) y con el de
# después: la función original pasa a llamarse <nombre>__x y la envoltura conserva el nombre, así que las llamadas del
# juego (y las de vista3d.gd a los métodos de la escena) pasan por ella. Coste de la envoltura: ~1 µs por llamada, igual en
# las dos versiones (por eso los ms por fotograma «limpios» se toman de pasadas SIN instrumentar).
#
# NUNCA se hace commit del código instrumentado. Uso (desde la raíz del repositorio):
#   py -3.10 aethelgard/pruebas/instrumentar_coste_ciudad.py            -> instrumenta (en la copia de trabajo)
#   git checkout -- aethelgard/zonas3d/ciudad/ciudad.gd aethelgard/zonas3d/grupo_3d.gd   -> lo quita
import re
import subprocess
import sys

# (revisión, 18/11) el commit 16ffb9c se llevó código cambiado por una medida: no instrumentar con nada preparado para commit
if subprocess.run(["git", "diff", "--cached", "--quiet"]).returncode != 0:
    sys.exit("hay cambios preparados para commit (git diff --cached): no se instrumenta")

FUNCIONES = {
    "aethelgard/zonas3d/ciudad/ciudad.gd": [("_oclusion", "oclusion"), ("_altura_suelo", "altura_suelo"),
                                            ("_ajustar_destino", "ajustar_destino"), ("_bordear", "bordear")],
    "aethelgard/zonas3d/grupo_3d.gd": [("_despejado", "despejado"), ("_process", "grupo_proceso")],
}

AYUDA = """

# ---- instrumentación temporal (pruebas/instrumentar_coste_ciudad.py): NO hacer commit ----
var _coste_x := {}


func _cx(k: String, t0: int) -> void:
	var e = _coste_x.get(k)
	if e == null:
		_coste_x[k] = [Time.get_ticks_usec() - t0, 1]
	else:
		e[0] += Time.get_ticks_usec() - t0
		e[1] += 1
"""


def instrumentar(ruta: str, funciones) -> None:
    s = open(ruta, encoding="utf-8").read()
    if "_coste_x" in s:
        print("ya instrumentado:", ruta)
        return
    extra = AYUDA
    for nombre, clave in funciones:
        m = re.search(r"^func " + re.escape(nombre) + r"\((.*)\)(\s*->\s*(\w+))?:\s*$", s, re.M)
        if m is None:
            print("  (no está: %s en %s)" % (nombre, ruta))
            continue
        params = m.group(1)
        tipo = m.group(3)
        nombres = [p.split(":")[0].split("=")[0].strip() for p in params.split(",") if p.strip()]
        s = s[:m.start()] + "func " + nombre + "__x(" + params + ")" + (m.group(2) or "") + ":" + s[m.end():]
        cab = "func " + nombre + "(" + params + ")" + (m.group(2) or "") + ":\n"
        cab += "\tvar t0 := Time.get_ticks_usec()\n"
        llamada = nombre + "__x(" + ", ".join(nombres) + ")"
        if tipo is None or tipo == "void":
            if tipo is None:
                cab += "\tvar r = " + llamada + "\n\t_cx(\"" + clave + "\", t0)\n\treturn r\n"
            else:
                cab += "\t" + llamada + "\n\t_cx(\"" + clave + "\", t0)\n"
        else:
            cab += "\tvar r: " + tipo + " = " + llamada + "\n\t_cx(\"" + clave + "\", t0)\n\treturn r\n"
        extra += "\n\n" + cab
        print("  envuelta %s (%s) en %s" % (nombre, clave, ruta))
    open(ruta, "w", encoding="utf-8", newline="\n").write(s.rstrip("\n") + "\n" + extra)


if __name__ == "__main__":
    for ruta, funciones in FUNCIONES.items():
        instrumentar(ruta, funciones)
    sys.exit(0)
