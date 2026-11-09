# Hornea piezas de Oakhaven (T-089): monta cada pieza (piezas.py), la ilumina a la hora azul y la renderiza en 3/4
# con la proyección del juego (kit.py), por capas:
#   <id>_<capa>.webp   cada capa (cuerpo, letrero…), recortada a lo que tiene (RGBA, alfa normal)
#   <id>_suelo.png     calcomanía del suelo en alfa PREMULTIPLICADO: rgb = luz cálida que se suma al empedrado,
#                      alfa = sombra (lo que oscurece). Se dibuja con mezcla «premult» y sin luz del juego.
#   fuente/datos/<id>.json  dónde va cada imagen (píxeles del mundo 2D con la huella de diseño), orden, anclas, efectos
# Uso: blender -b --factory-startup -P hornear.py -- <ids separados por comas> <carpeta oakhaven_arte> <carpeta crudos>
#      [muestras=256] [solo_cuerpo]
import sys, os, json, math
sys.dont_write_bytecode = True          # sin __pycache__ en la carpeta del proyecto
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import importlib
import bpy
import numpy as np
import kit as K
import util_img as U
import piezas as P
import generar_datos

args = sys.argv[sys.argv.index("--") + 1:]
IDS = args[0].split(",")
SALIDA = os.path.abspath(args[1])
CRUDOS = os.path.abspath(args[2])
MUESTRAS = 256
SOLO_CUERPO = False
for a in args[3:]:
    if a.startswith("muestras="):
        MUESTRAS = int(a[9:])
    elif a == "solo_cuerpo":
        SOLO_CUERPO = True
os.makedirs(SALIDA, exist_ok=True)
os.makedirs(CRUDOS, exist_ok=True)
DATOS = os.path.join(AQUI, "datos")
os.makedirs(DATOS, exist_ok=True)

GANANCIA_LUZ = 0.85        # luz práctica medida sobre gris 0,5 → lo que se suma al suelo del juego
RADIO_SOMBRA = 2           # desenfoque de la sombra del atrapasombras (quita el grano)
FUERZA_SOMBRA = 0.62       # la sombra del cielo de la hora azul es suave: no más que esto
ESCALA_SUELO = 4           # las calcomanías del suelo se guardan a 1/4 (todo en ellas es suave); en el juego, ×4


def reducir(px, f, premultiplicado):
    """Reduce por f (media de bloques f×f). Con alfa normal, la media se hace premultiplicada (sin halos)."""
    h = ((px.shape[0] + f - 1) // f) * f
    w = ((px.shape[1] + f - 1) // f) * f
    full = np.zeros((h, w, 4), dtype=np.float32)
    full[:px.shape[0], :px.shape[1]] = px
    if not premultiplicado:
        full[:, :, :3] *= full[:, :, 3:4]
    r = full.reshape(h // f, f, w // f, f, 4).mean(axis=(1, 3))
    if not premultiplicado:
        a = r[:, :, 3:4]
        r[:, :, :3] = np.where(a > 1e-6, r[:, :, :3] / np.maximum(a, 1e-6), 0.0)
    return r


def render(ruta, muestras):
    sc = bpy.context.scene
    sc.cycles.samples = muestras
    sc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)


def visibles(objetos_camara, todos):
    s = set(o.name for o in objetos_camara)
    for o in objetos_camara:                   # lo que instancian sus partículas (las hojas de la copa) va con ellos
        for ps in getattr(o, "particle_systems", []):
            if ps.settings.instance_object is not None:
                s.add(ps.settings.instance_object.name)
    for o in todos:
        o.visible_camera = o.name in s


def hornear(pid):
    K.escena_nueva()
    K.LUCES_CIELO.clear()
    K.LUCES_PRACTICAS.clear()
    K._MATS.clear()
    ficha = P.PIEZAS[pid]()
    r = ficha["rect"]
    cielo = dict(ficha.get("cielo", {}))
    cielo.setdefault("centro", (r[0] + r[2] * 0.5, r[1] + r[3] * 0.5))
    K.cielo_hora_azul(**cielo)
    todos = [o for o in bpy.context.scene.objects if o.type == 'MESH' and not o.hide_render]
    objs = [o for c in ficha["capas"] for o in c["objetos"] if o.type == 'MESH' and not o.hide_render]
    m = K.marco_pantalla(objs, 4)
    ext = ficha.get("margen_suelo", (140, 24, 160, 150))   # izquierda, arriba, derecha, abajo (px)
    marco = (m[0] - ext[0], m[1] - ext[1], m[2] + ext[2], m[3] + ext[3])
    if "recorte_arriba" in ficha:          # lo que queda por encima del borde del mapa nunca se ve
        marco = (marco[0], max(marco[1], int(ficha["recorte_arriba"] * K.PX)), marco[2], marco[3])
    K.poner_camara(marco)
    suelo = K.suelo_bajo(marco)
    gris = K.m_liso((0.5, 0.5, 0.5, 1.0), 0.95, nombre="suelo_gris")
    suelo_mat = K.m_liso(K.hexlin("#5C5852"), 0.92, nombre="suelo_empedrado")
    suelo.data.materials.append(suelo_mat)
    rx0, ry0, rx1, ry1 = marco
    print("PIEZA %s marco %s (%d×%d px)" % (pid, marco, rx1 - rx0, ry1 - ry0))
    ficha_json = {"id": pid, "rect": list(ficha["rect"]), "sprites": [], "anclas": {}, "efectos": ficha.get("efectos", []),
                  "choques": ficha.get("choques", []), "marco": list(marco)}
    tapa = None                 # alfa del cuerpo: debajo de lo opaco, la calcomanía no hace falta
    # ---- capas
    for capa in ficha["capas"]:
        nombre = capa["nombre"]
        visibles(capa["objetos"], todos + [suelo])
        suelo.visible_camera = False
        crudo = os.path.join(CRUDOS, "%s_%s.png" % (pid, nombre))
        render(crudo, MUESTRAS)
        px = U.cargar(crudo)
        caja = U.bbox(px[:, :, 3], 1.5 / 255.0)
        if caja is None:
            print("AVISO: la capa %s/%s sale vacía" % (pid, nombre))
            continue
        bx0, by0, bx1, by1 = caja
        recorte = px[by0:by1, bx0:bx1]
        esc = int(capa.get("escala", 1))
        if esc > 1:                            # capas suaves y grandes (las raíces): a menor resolución
            bx1 = bx0 + ((bx1 - bx0 + esc - 1) // esc) * esc
            by1 = by0 + ((by1 - by0 + esc - 1) // esc) * esc
            recorte = reducir(px[by0:by1, bx0:bx1], esc, False)
        archivo = "%s_%s.webp" % (pid, nombre)
        U.guardar(recorte, os.path.join(SALIDA, archivo), 'WEBP', 94)
        U.guardar(recorte, os.path.join(CRUDOS, "%s_%s_recorte.png" % (pid, nombre)))
        orden = capa.get("orden")
        # sin «orden» (alfombras: raíces, escalones): ordena con su borde de arriba, debajo de quien la pisa
        orden_px = (ry0 + by0) if orden is None else orden * K.PX
        s = {"capa": nombre, "archivo": archivo, "pos": [rx0 + bx0, ry0 + by0], "tam": [bx1 - bx0, by1 - by0],
             "orden": orden_px, "tipo": capa.get("tipo", "edificio")}
        if "pivote" in capa:
            pv = K.V(*capa["pivote"])
            s["pivote"] = list(K.a_pantalla(pv))
        for k in ("estado", "estado_no", "viento", "escala"):
            if k in capa:
                s[k] = capa[k]
        if nombre == "cuerpo":
            tapa = px[:, :, 3].copy()
        ficha_json["sprites"].append(s)
        print("  capa %s: %d×%d en %s" % (nombre, bx1 - bx0, by1 - by0, s["pos"]))
    # ---- suelo: sombra (atrapasombras) y luz práctica
    if ficha.get("suelo", False) and not SOLO_CUERPO:
        visibles([suelo], todos + [suelo])
        suelo.is_shadow_catcher = True
        crudo_s = os.path.join(CRUDOS, "%s_suelo_sombra.png" % pid)
        render(crudo_s, max(MUESTRAS, 384))
        suelo.is_shadow_catcher = False
        suelo.data.materials[0] = gris
        K.apagar_cielo(True)
        crudo_l = os.path.join(CRUDOS, "%s_suelo_luz.png" % pid)
        render(crudo_l, max(MUESTRAS, 256))
        K.apagar_cielo(False)
        suelo.data.materials[0] = suelo_mat
        S = U.cargar(crudo_s)
        L = U.cargar(crudo_l)
        a = U.desenfocar(np.clip(S[:, :, 3], 0, 1), RADIO_SOMBRA) * FUERZA_SOMBRA
        luz = np.clip(L[:, :, :3] * GANANCIA_LUZ, 0, 1) * L[:, :, 3:4]
        # se desvanece hacia el borde del marco (nada de cortes rectos en el empedrado)
        hh, ww = a.shape
        yy = np.minimum(np.arange(hh), np.arange(hh)[::-1])[:, None]
        xx = np.minimum(np.arange(ww), np.arange(ww)[::-1])[None, :]
        borde = np.clip(np.minimum(yy, xx) / 90.0, 0.0, 1.0)
        borde = borde * borde * (3.0 - 2.0 * borde)
        a = a * borde
        luz = luz * borde[:, :, None]
        if tapa is not None:
            fuera = (U.desenfocar((tapa > 0.995).astype(np.float32), 1) < 0.999)[:, :, None]
            luz = luz * fuera
            a = a * fuera[:, :, 0]
        dec = np.zeros_like(S)
        dec[:, :, :3] = luz
        dec[:, :, 3] = a
        hay = (dec[:, :, 3] > 2.0 / 255.0) | (dec[:, :, :3].max(axis=2) > 2.0 / 255.0)
        ys, xs = np.nonzero(hay)
        if len(xs):
            bx0, by0, bx1, by1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
            # a 1/ESCALA_SUELO de resolución (todo es suave: sombra de cielo y charcos de luz); en el juego, escalada
            f = ESCALA_SUELO
            bx1 = bx0 + ((bx1 - bx0 + f - 1) // f) * f
            by1 = by0 + ((by1 - by0 + f - 1) // f) * f
            parte = np.zeros((by1 - by0, bx1 - bx0, 4), dtype=np.float32)
            trozo = dec[by0:by1, bx0:bx1]
            parte[:trozo.shape[0], :trozo.shape[1]] = trozo
            rec = reducir(parte, f, True)
            # el WebP/PNG sin pérdida puede cambiar el color bajo alfa 0: nunca 0 donde hay luz
            conluz = rec[:, :, :3].max(axis=2) > 0.5 / 255.0
            rec[:, :, 3] = np.where(conluz, np.maximum(rec[:, :, 3], 1.0 / 255.0), rec[:, :, 3])
            archivo = "%s_suelo.png" % pid
            U.guardar(rec, os.path.join(SALIDA, archivo))
            ficha_json["suelo"] = {"archivo": archivo, "pos": [rx0 + int(bx0), ry0 + int(by0)], "tam": [int(bx1 - bx0), int(by1 - by0)],
                                   "escala": ESCALA_SUELO}
            print("  suelo: %d×%d" % (bx1 - bx0, by1 - by0))
    # ---- anclas en píxeles del mundo 2D
    for nombre, p in ficha.get("anclas", {}).items():
        ficha_json["anclas"][nombre] = list(K.a_pantalla(K.V(*p)))
    with open(os.path.join(DATOS, "%s.json" % pid), "w", encoding="utf-8") as f:
        json.dump(ficha_json, f, ensure_ascii=False, indent=1)
    print("HECHA %s" % pid)


import traceback
fallos = []
for pid in IDS:
    try:
        hornear(pid)
    except Exception:
        traceback.print_exc()
        fallos.append(pid)
        print("FALLO al hornear %s" % pid)
generar_datos.generar(SALIDA)
print("FALLOS: %s" % (", ".join(fallos) if fallos else "ninguno"))
