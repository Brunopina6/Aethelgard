# Escribe oakhaven_arte/arte_datos.gd a partir de las fichas fuente/datos/<id>.json que deja hornear.py.
# Uso: blender -b --factory-startup -P generar_datos.py -- <carpeta oakhaven_arte>   (o desde hornear.py)
import os, sys, json, glob
sys.dont_write_bytecode = True

AQUI = os.path.dirname(os.path.abspath(__file__))


def _v(p):
    return "Vector2(%s, %s)" % (_n(p[0]), _n(p[1]))


def _n(x):
    x = float(x)
    return ("%d.0" % x) if x == int(x) else ("%.2f" % x).rstrip("0")


def _valor(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return _n(v)
    if isinstance(v, str):
        return '"%s"' % v.replace('"', '\\"')
    if isinstance(v, (list, tuple)) and len(v) == 2 and all(isinstance(a, (int, float)) for a in v):
        return _v(v)
    if isinstance(v, (list, tuple)):
        return "[" + ", ".join(_valor(a) for a in v) + "]"
    if isinstance(v, dict):
        return "{" + ", ".join('"%s": %s' % (k, _valor(x)) for k, x in v.items()) + "}"
    return str(v)


def generar(carpeta_arte):
    fichas = []
    for ruta in sorted(glob.glob(os.path.join(AQUI, "datos", "*.json"))):
        with open(ruta, encoding="utf-8") as f:
            fichas.append(json.load(f))
    L = ["extends RefCounted",
         "# GENERADO por ciudades/oakhaven_arte/fuente/hornear.py (generar_datos.py): no se edita a mano.",
         "# Por pieza: «rect», la huella de diseño (casillas); «sprites», cada imagen con su esquina («pos», píxeles del",
         "# mundo 2D a 64 por casilla), su tamaño, la «y» con la que se ordena frente a Kael («orden») y su tipo;",
         "# «suelo», la calcomanía de sombra y luz; «anclas», puntos con nombre; «efectos», humo, halos y luciérnagas;",
         "# «choques», cajas que no se pueden atravesar (centro y tamaño en casillas).",
         "",
         "const PIEZAS := {"]
    for f in fichas:
        r = f["rect"]
        L.append('\t"%s": {' % f["id"])
        L.append('\t\t"rect": Rect2i(%d, %d, %d, %d),' % tuple(r))
        L.append('\t\t"sprites": [')
        for s in f["sprites"]:
            d = {"capa": s["capa"], "tex": s["archivo"], "pos": s["pos"], "tam": s["tam"], "orden": float(s["orden"]),
                 "tipo": s["tipo"]}
            for k in ("pivote", "estado", "estado_no", "viento", "escala"):
                if k in s:
                    d[k] = s[k]
            L.append("\t\t\t%s," % _valor(d))
        L.append("\t\t],")
        if "suelo" in f:
            s = f["suelo"]
            L.append('\t\t"suelo": %s,' % _valor({"tex": s["archivo"], "pos": s["pos"], "tam": s["tam"], "escala": s.get("escala", 1)}))
        L.append('\t\t"anclas": %s,' % _valor(f.get("anclas", {})))
        L.append('\t\t"efectos": %s,' % _valor(f.get("efectos", [])))
        L.append('\t\t"choques": %s,' % _valor(f.get("choques", [])))
        L.append("\t},")
    L.append("}")
    ruta = os.path.join(carpeta_arte, "arte_datos.gd")
    with open(ruta, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(L) + "\n")
    print("DATOS escritos: %s (%d piezas)" % (ruta, len(fichas)))


if __name__ == "__main__" and "--" in sys.argv:
    generar(os.path.abspath(sys.argv[sys.argv.index("--") + 1]))
