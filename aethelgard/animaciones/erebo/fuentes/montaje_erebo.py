# Montaje de la invocación cinematográfica de Érebo: fotogramas PNG + mezcla WAV → vídeo (docs/v12/EREBO_CINEMATICA_V12.md)
#   blender -b --factory-startup -P montaje_erebo.py -- <carpeta de fotogramas> <mezcla.wav> <salida> [formato=ogv|mp4]
#           [res=960x540] [kbps=2500] [fin_s=20.0]
# · ogv: Ogg Theora + Vorbis, el formato que Godot 4 reproduce sin complementos (VideoStreamTheora).
# · mp4: H.264 + AAC, solo para revisar en el PC o en el móvil (Godot no lo reproduce).
import sys, os
sys.dont_write_bytecode = True
import bpy

a = sys.argv[sys.argv.index("--") + 1:]
FOTOS, WAV, SALIDA = a[0], a[1], a[2]
OPC = {k: v for k, v in (x.split("=", 1) for x in a[3:] if "=" in x)}
FORMATO = OPC.get("formato", "ogv")
RES = tuple(int(x) for x in OPC.get("res", "960x540").split("x"))
FPS = 30

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.fps = FPS
sc.render.resolution_x, sc.render.resolution_y = RES
sc.render.resolution_percentage = 100
sc.view_settings.view_transform = 'Standard'          # los PNG ya llevan su transformación (AgX): no se aplica otra
ed = sc.sequence_editor_create()
tiras = ed.strips if hasattr(ed, "strips") else ed.sequences
nombres = sorted(f for f in os.listdir(FOTOS) if f.lower().endswith(".png"))
if not nombres:
    raise SystemExit("sin fotogramas en " + FOTOS)
img = tiras.new_image("fotogramas", os.path.join(FOTOS, nombres[0]), 2, 1)
for n in nombres[1:]:
    img.elements.append(n)
try:
    img.transform.filter = 'BILINEAR'
except Exception:
    pass
img.use_proxy = False
n_fot = len(nombres)
fin = int(round(float(OPC.get("fin_s", str(n_fot / FPS))) * FPS))
snd = tiras.new_sound("mezcla", WAV, 1, 1)
sc.frame_start = 1
sc.frame_end = min(n_fot, fin)
r = sc.render
r.image_settings.media_type = 'VIDEO' if hasattr(r.image_settings, "media_type") else r.image_settings.media_type
r.image_settings.file_format = 'FFMPEG'
ff = r.ffmpeg
if FORMATO == "ogv":
    ff.format = 'OGG'
    ff.codec = 'THEORA'
    ff.constant_rate_factor = 'NONE'
    ff.video_bitrate = int(OPC.get("kbps", "2500"))
    ff.maxrate = int(ff.video_bitrate * 1.6)
    ff.gopsize = FPS
    ff.audio_codec = 'VORBIS'
    ff.audio_bitrate = 160
else:
    ff.format = 'MPEG4'
    ff.codec = 'H264'
    ff.constant_rate_factor = 'HIGH'
    ff.gopsize = FPS
    ff.audio_codec = 'AAC'
    ff.audio_bitrate = 192
ff.audio_channels = 'STEREO'
ff.audio_mixrate = 44100
r.use_sequencer = True
r.use_compositing = False
r.filepath = SALIDA
os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
bpy.ops.render.render(animation=True)
print("MONTAJE", SALIDA, sc.frame_end, "fotogramas", RES, FORMATO)
