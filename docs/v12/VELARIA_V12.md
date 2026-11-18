# Velaria en la V12 (19/11/2026)

**Estado: implementada y APAGADA, pendiente de decisión del usuario y de verla en el Redmi.** No es definitiva: las
cifras de combate y el encuadre son propuestas.

Velaria es la polilla de alas como postigos de farol, una hostigadora de ruinas húmedas. Es la tercera bestia del
bestiario aprobado (T-097 y D-075 en `D:\Aethelgard\TASKS.md` y `DECISIONS.md`).

> **Licencia.** El modelo es de Meshy, de la cuenta del usuario, y la licencia **no está confirmada**. Solo puede ir
> en APK de prueba privadas. No se puede publicar mientras no se confirmen los derechos (ficha, apartado
> «Procedencia»: tarea Meshy `01a1bd67-327d-753e-8da8-0ad8a4d3e49d`).

## 1. Rescate

La única copia estaba **sin commit** en `D:\Aethelgard_animaciones`, rama `area-animaciones` (último commit `625abfb`).
Se **copió**, sin mover ni borrar nada del origen: allí siguen los tres elementos sin seguimiento, y el SHA-1 del GLB
es el mismo en las dos copias (`b5a673a5…`).

| Origen (animaciones) | Destino (V12) |
|---|---|
| `aethelgard/enemigos/velaria/` (GLB 9,2 MB, 3 texturas JPG 2K, `velaria_3d.gd`, `.tscn`, `fuentes_blender/crear_clips.py` con `.gdignore`) | igual |
| `aethelgard/pruebas/prueba_velaria_modelo.gd`, `prueba_velaria_fotos.gd` | igual |

Al importar en la V12, las texturas pasaron a VRAM comprimida (s3tc/etc2), como las del Zarzalín y del Cencerrante. Los
UID que venían de animaciones (`.uid` y `.import`) no chocan con ninguno de la V12.

**Corrección de una prueba.** La comprobación «tras la entrada, en su sitio» de `prueba_velaria_modelo` venía copiada de
la del Cencerrante, que exige la raíz en el suelo (< 0,03 m). Velaria vuela: en el reposo su raíz flota a 0,24 m. Ahora
se pide que no haya desplazamiento horizontal y que esté a altura de vuelo (entre 0,12 y 0,34 m). Esta comprobación
fallaba al rescatarla, con «FALLO y en su sitio (raíz a 0.240 m)»; ahora pasa.

## 2. Integración, comparada con el Zarzalín y el Cencerrante

- **Zarzalín:** está enganchado y encendido (GRUPOS[10], personalidad «embiste», `_anim_zarzalin`).
- **Cencerrante:** en la V12 solo existe como prototipo. No está en `combate.gd` y su carpeta queda fuera de la precarga.
- **Velaria:** sigue el patrón del Zarzalín, pero **apagada** detrás de un interruptor propio, igual que el Custodio
  (`meshy_e01`).

| Pieza | Qué hay |
|---|---|
| `combate_velaria.gd` (nuevo) | IA (`turno`) y animación (`animar_golpe`). El interruptor es `velaria_v12` (`Engine.set_meta` o `-- velaria_v12`) y está apagado por defecto; tampoco va en la partida. Grupo de prueba: `GRUPOS[30]`. |
| `combate.gd` | `MODELOS["velaria"]`: `vp` 900×700, `alto_vista` 2,0, `centro_y` 0,8, `centro_3d` 0,75, respaldo «slime», 350 px por metro como el Zarzalín. `ENEMIGOS["velaria"]`: 70 PV, ataque 11, velocidad 16, experiencia 22, oro 14, personalidad «agresivo». También `GRUPOS[30]` (Velaria sola, nunca al azar), `ANIM` y los ganchos «V12, Velaria» (`preparar`, turno y animación). |
| `combate_afinidades.gd` | Fila **neutra**: la ficha no trae afinidades y no se inventan. |
| `recursos.gd` | `enemigos/velaria/` va a `APAGADOS` con `velaria_v12`: unos 18 MB que no se precargan mientras siga apagada. |
| `banco_pruebas.gd` | Caso «velaria», «Velaria: destello de velo y corte de ala (prueba)»: grupo 30, Kael, Lya y Garon, vida ×1. Enciende `velaria_v12` solo para su sesión (`METAS_SESION`) y lo quita al salir. |
| `sonido.gd` | No cambia: los siete sonidos de Velaria (`velaria_*`) ya estaban en el catálogo de la tanda 4, con sus WAV en `audio/efectos/bestias/`. |

### Ataques (ficha `Fichas_e_integracion.txt`)

- **destello_de_velo (0,70 s), proyectil anunciado.**
  - **Turno del aviso.** Velaria repliega las alas con `avisar()` y se queda con la luz concentrada (`aviso_espera`).
    Su señal «aviso» pide `velaria_aviso_destello` **una vez**, por `combate.gd _sonidos_bestia`. Sobre su vida sale
    «⚠ Cargando» con la marca de aviso, y no hay daño.
  - **Turno siguiente.** Lo suelta contra el héroe elegido; Garon puede cubrirle. Al abrir las alas, la señal
    «impacto» pide `velaria_destello` una vez. La luz sale de su pecho (`luz()`) y vuela durante 0,3 s. Al llegar,
    el daño se resuelve **una sola vez**: ataque ×1,5. Defender lo deja a la mitad, como cualquier golpe.
  - **Turno después.** Se recompone sin atacar; es el «centro visible» de la ficha.
- **corte_de_ala (0,50 s).** Vuela hasta el héroe y se coloca usando el alcance medido del clip (0,57 m) más la
  posición de su cabeza en el reposo. Al empezar el clip suena `velaria_aviso_corte`. El impacto (daño y
  `velaria_corte`) llega una vez, en el ancla del clip, y después vuelve volando a su sitio.
- **Apagada.** Solo se ve si alguien pide `grupo=30` sin el interruptor: sin personalidad propia, ataca como un
  enemigo «agresivo» y su golpe es el corte de ala. Ni avisa ni hace el destello.

**Cifras propuestas, sin equilibrar:** `PROB_AVISO` 0,4 (la del Zarzalín), `MULT_DESTELLO` 1,5 y su fila de `ENEMIGOS`.

## 3. Pruebas (`ejecutar_pruebas.ps1 -Solo`, datos aislados)

Salidas literales de los resúmenes:

```
prueba_velaria_modelo FALLIDA      1,8 s  código de salida 1      (antes de corregir la comprobación de la raíz)
prueba_velaria_combate SUPERADA     3,9 s
  OK: U: apagada; A (semilla 20261119); B: apagada, 2 turnos con el corte { "entrada": true, "aviso": 1, "destello": 1, "corte": 1, "recupera": 1, "defendida": 1 }
  FALLOS: 0
prueba_zarzalin_modelo SUPERADA     1,9 s
prueba_cencerrante_modelo SUPERADA     1,9 s
prueba_zarzalin_combate SUPERADA       4 s
prueba_velaria_modelo SUPERADA     1,9 s      («ok    y en su sitio, flotando (raíz en 0.000, 0.240, 0.000 m)»; FALLOS: 0)
prueba_enemigos_v12  SUPERADA     9,8 s
prueba_banco_pruebas SUPERADA      21 s     («OK: A: archivo propio, grupo de partida, 7 selectores y 17 casos»)
prueba_escalado      SUPERADA     6,5 s
prueba_magia_negra   SUPERADA       8 s     (cada clave de ENEMIGOS, en la tabla de afinidades)
prueba_meshy_e01     SUPERADA    10,7 s     (ahora comprueba 31 grupos y que GRUPOS[30] es Velaria)
prueba_integridad    SUPERADA     8,6 s
prueba_cargas        SUPERADA     9,3 s
partida.save real: sin cambios · carpeta real de datos: sin cambios · proyecto: sin cambios · otros Godot: 0
```

`prueba_velaria_combate` (nueva) comprueba lo siguiente:

- **Apagada:** no cambia nada, solo `GRUPOS[30]` la trae, no sale al azar, su carpeta no se precarga y su fila de
  afinidades existe.
- **Encendida, con Kael solo:**
  - entra con su clip y avisa un turno antes (una señal, «⚠ Cargando», sin daño);
  - el destello da un solo impacto y un solo cambio de PV, y el daño llega después de soltar la luz; luego se recompone;
  - el corte da un solo impacto;
  - Defender deja el destello en la mitad o menos;
  - Kael gana y Velaria cae con su clip de derrota;
  - cada aviso y cada impacto piden su sonido una vez y en el fotograma de su señal; el aviso del corte suena antes
    de su impacto; la entrada suena una vez.
- **Apagada en su grupo:** solo hace el corte.

Además, en `prueba_banco_pruebas` el caso de Velaria la trae con su personalidad y su modelo 3D, su interruptor no pasa
al caso siguiente y al salir se quita. `prueba_meshy_e01` pasaba de 30 a 31 grupos y se ajustó.

## 4. Lo que queda

- **Licencia de Meshy:** confirmarla antes de cualquier publicación. Hasta entonces, solo APK de prueba privadas.
- **Redmi:** ver en el teléfono el caso «Velaria» del banco de Auditoría. Hay que revisar:
  - el encuadre: si las alas se cortan en la ventana 900×700, la barra de vida y el sitio del corte;
  - que el destello se lea bien con el perfil gráfico bajo;
  - el rendimiento: GLB de 9,2 MB y 10,7 MB de texturas en la GPU.
- **Decisiones del usuario:**
  - las cifras (PV, multiplicador del destello y probabilidad del aviso);
  - sus afinidades, hoy neutras;
  - el botín (la ficha propone «Escama de farol»; no está puesto);
  - si algún día sale en encuentros al azar, y dónde.
- **Capturas sin hacer:** `prueba_velaria_fotos` (modo ventana, con `-Manual`). No se ejecutó en esta sesión.
