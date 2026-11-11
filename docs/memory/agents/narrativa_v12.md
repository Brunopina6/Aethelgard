# Narrativa · V12, el Mar de Cristal (primer sector)

## 11/11/2026 · «La caravana perdida»: diálogos, personajes, textos y enemigos (PROPUESTA)

Rama LOCAL `claude/v12-desierto-narrativa` (`D:\Aethelgard_v12_narrativa`), desde `claude/rebelum-v12` @ `e9eebf1`.
Commit del trabajo: `aceb5da`. Detalle completo en `docs/v12/NARRATIVA_DESIERTO.md`.

### Qué se entrega
- **Personajes** (sin retrato, como Maese Ferro): `aethelgard/dialogos/personajes/mar_cristal/ismena.dch` (la
  cartógrafa) y `oren.dch` (su hermano, el superviviente).
- **19 timelines** en `aethelgard/dialogos/mar_cristal/`, con los nombres pedidos como base y variantes:
  - `mc_cartografa_inicio` → `mc:buscador`; `mc_cartografa_espera` (genérica) y `_restos`, `_sello`, `_ruinas`,
    `_llave` (pista según hito); `mc_cartografa_fin` → `mc:fin`.
  - `mc_caravana_restos` → `mc:caravana`; `mc_tormenta`; `mc_ruinas_mural`; `mc_superviviente` →
    `mc:superviviente`. Cada una en trío (base), `_lya` y `_solo`.
- **Textos de la región** (9 ids, uno extra opcional, `mc_tormenta_fin`) y **3 enemigos** (Vidracrán, Tolvanera y
  Tragaluz), en `docs/v12/NARRATIVA_DESIERTO.md` §3 y §4.
- **Tabla de intenciones y gestos** para animaciones: §5 del mismo documento.

### Comprobaciones
- **Observado en el código** (11/11, `e9eebf1`): el formato de `.dtl` y `.dch` de `dialogos/oakhaven/`,
  `dialogos/garganta/gg_veta.dtl` y `ciudades/oakhaven.gd`. Dialogic no usa condiciones ni variables en este proyecto:
  la timeline la elige el código (como `oak_posada_grupo`/`_lya`/`_solo` y `gg_veta`). Por eso las variantes.
- Solo se usan gestos que ya existen en `kael.dch` y `lya.dch`; Garon, Ismena y Oren hablan sin `join`.
- Longitud: 94 intervenciones, la más larga de 84 caracteres (medido con PowerShell).
- «Ismena» y «Oren» no aparecen en el repositorio ni en la biblia v2/v3.
- **Pendiente de verificar:** no se ha ejecutado Godot ni la batería (lo pidió el coordinador). Falta comprobar que
  las timelines se analizan bien, que los personajes se resuelven y que los textos caben en el Redmi.

### Canon
Nada de Érebo ni de lo que guarda; el Lente del Sol y la máquina enterrada no se nombran; la Reina de los Espejismos
solo aparece como «…de los Espejismos» (nombre raspado) en el mural, sin decir quién es; nada de Final Fantasy X.
Ningún hito, recompensa ni magia cambia. La paga y la reliquia se nombran sin cifra ni nombre, para no pisar los datos
del coordinador.

### Lo que necesito en archivos de otros (coordinador)
1. Registrar `ismena` y `oren` (`dch_directory` o un `PERSONAJES` con `registrar_dialogic()`), y las 19 timelines en
   `dtl_directory` (o lanzarlas por ruta).
2. Elegir la variante por grupo (función de ejemplo en §2.1) y la espera por hito (§2.2).
3. Llevar la llave «con ojo de bronce» al diseño, para que el buscador la oiga.

### Preguntas para el usuario
Nombres (Ismena, Oren; si sustituye a Marga de la V11), el nombre del gusano (Tragaluz, el Sordo o Bramavidrio), si el
mural puede dejar leer «…de los Espejismos» y qué reliquia es la recompensa.
