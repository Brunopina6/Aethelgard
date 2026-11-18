# meshy_e01 · comparar dos GLB canal a canal (18/11): mismos clips, mismas pistas (bytes de tiempos y valores por hueso y
# propiedad), misma malla y misma piel. Sin Blender ni Godot.
#   py -3.10 -I comparar_glb.py <glb anterior> <glb nuevo>
import sys, json, struct, hashlib


def leer(ruta):
    d = open(ruta, "rb").read()
    n = struct.unpack_from("<I", d, 12)[0]
    js = json.loads(d[20:20 + n])
    o = 20 + n
    bn = struct.unpack_from("<I", d, o)[0]
    return js, d[o + 8:o + 8 + bn]


def acc_bytes(js, b, i):
    a = js["accessors"][i]
    bv = js["bufferViews"][a["bufferView"]]
    comp = {5126: 4, 5123: 2, 5125: 4, 5121: 1, 5120: 1, 5122: 2}[a["componentType"]]
    num = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}[a["type"]]
    ini = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    paso = bv.get("byteStride", comp * num)
    if paso == comp * num:
        return b[ini:ini + a["count"] * comp * num]
    return b"".join(b[ini + k * paso:ini + k * paso + comp * num] for k in range(a["count"]))


def huella(ruta):
    js, b = leer(ruta)
    nodos = [n.get("name", "") for n in js["nodes"]]
    clips = {}
    for an in js.get("animations", []):
        pistas = {}
        dur = 0.0
        for ch in an["channels"]:
            s = an["samplers"][ch["sampler"]]
            t = js["accessors"][s["input"]]
            dur = max(dur, t["max"][0])
            clave = "%s/%s" % (nodos[ch["target"]["node"]], ch["target"]["path"])
            pistas[clave] = hashlib.md5(acc_bytes(js, b, s["input"]) + acc_bytes(js, b, s["output"])).hexdigest()
        clips[an["name"]] = (round(dur, 4), pistas)
    malla = hashlib.md5(b"".join(acc_bytes(js, b, i) for m in js["meshes"] for p in m["primitives"]
                                 for i in sorted(p["attributes"].values()) + [p["indices"]])).hexdigest()
    piel = hashlib.md5(b"".join(acc_bytes(js, b, s["inverseBindMatrices"]) for s in js["skins"])
                       + json.dumps([[nodos[j] for j in s["joints"]] for s in js["skins"]]).encode()).hexdigest()
    return clips, malla, piel


a_clips, a_malla, a_piel = huella(sys.argv[1])
b_clips, b_malla, b_piel = huella(sys.argv[2])
fallos = 0
for nm, (dur, pistas) in sorted(a_clips.items()):
    if nm not in b_clips:
        print("FALTA", nm); fallos += 1; continue
    dur2, pistas2 = b_clips[nm]
    dif = [k for k in pistas if pistas2.get(k) != pistas[k]] + [k for k in pistas2 if k not in pistas]
    print("%-22s %.4f s -> %.4f s  pistas %d/%d iguales %s" % (nm, dur, dur2, len(pistas) - len(dif), len(pistas),
                                                              "IGUAL" if not dif and dur == dur2 else "DISTINTO %s" % dif[:3]))
    fallos += 1 if (dif or dur != dur2) else 0
for nm in sorted(set(b_clips) - set(a_clips)):
    print("NUEVO  %-22s %.4f s  %d pistas" % (nm, b_clips[nm][0], len(b_clips[nm][1])))
print("MALLA", "IGUAL" if a_malla == b_malla else "DISTINTA", "· PIEL", "IGUAL" if a_piel == b_piel else "DISTINTA")
fallos += (a_malla != b_malla) + (a_piel != b_piel)
print("RESULTADO", "IGUALES (los clips anteriores, la malla y la piel)" if fallos == 0 else "%d DIFERENCIAS" % fallos)
