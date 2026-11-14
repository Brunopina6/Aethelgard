import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np, wavio, dsp
O = sys.argv[sys.argv.index("--") + 1]
for n in ("completa", "abreviada"):
    y, _ = wavio.leer(os.path.join(O, "erebo_cine_%s.wav" % n))
    s = sum(wavio.leer(os.path.join(O, "stems", "%s_%s.wav" % (n, k)))[0] for k in ("latidos", "zumbido_motivo", "efectos", "ambiente"))
    d = y - s
    print(n, "suma de stems vs mezcla: diferencia RMS %.1f dBFS, pico %.1f dBFS (mezcla RMS %.1f)" % (dsp.rms_db(d), 20*np.log10(np.abs(d).max()), dsp.rms_db(y)))
