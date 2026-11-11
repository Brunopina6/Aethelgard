# RETOMAR la V12 (El Mar de Cristal)

Punto seguro del 11/11 a mediodía, con la ventana de contexto casi llena. Antes de seguir, lee
`D:\Aethelgard\CLAUDE.md` (protocolo) y `CONTINUAR_V12_NUEVA_SESION.md`, en la raíz de esta copia.

## Git

- **Trabajo:** `claude/rebelum-v12` en `D:\Aethelgard_v12`, LOCAL.
  - Nace de `claude/rebelum-v11` @ `33c69c2` (la V11 cerrada: batería 108 · 0 · 43 · 0 en `6c6dc27`).
  - Último commit: `9531bd4`. Ver con `git -C D:\Aethelgard_v12 log --oneline -5`.
- **Sin push ni merge.** La orden del usuario lo prohíbe, también para la memoria.
- **Especialistas** (lanzados el 11/11; integrar solo lo terminado y revisado):

| Especialista | Rama | Copia | Tarea |
|---|---|---|---|
| Gráficos | `claude/v12-desierto-arte` | `D:\Aethelgard_v12_arte` | modelos del desierto, shaders de arena, viento y tela, `materiales_arte.gd`, capturas, informe `docs/memory/agents/graficos_v12_desierto.md` |
| Narrativa | `claude/v12-desierto-narrativa` | `D:\Aethelgard_v12_narrativa` | personajes y timelines `mc_*` de Dialogic, textos de la región y enemigos, `docs/v12/NARRATIVA_DESIERTO.md` |
| Sonido | `claude/v12-desierto-sonido` | `D:\Aethelgard_v12_sonido` | `audio/desierto/*`, claves nuevas en `sonido.gd`, `prueba_audio_desierto` |

  Si su informe no está, mirar `git -C <copia> log` para ver hasta dónde llegaron.

## Estado del código (`9531bd4`, EN OBRAS)

- **Hecho y confirmado, sin probar todavía:**
  - `zonas3d/mar_cristal/trazado.gd`: sitios, altura de las dunas, zonas prohibidas, ritmo de encuentros;
  - `zonas3d/mar_cristal/terreno.gd`: arena con relieve y choque, oasis, rocas, cobijo, sitios, y los modelos de
    gráficos cuando existan;
  - `zonas3d/mar_cristal/clima.gd`: brisa, arena en movimiento y tormenta (narrativa y sistémica);
  - `zonas3d/mar_cristal/buscador_hud.gd`: indicador, pitidos, EXCAVAR y el bloqueo con tormenta;
  - `zonas3d/mar_cristal_3d.gd`: la región (encuentros, salida, guardado, Dialogic, cartógrafa provisional).
- **Falta para que cargue** (siguiente paso, en este orden):
  1. `zonas3d/mar_cristal/mision.gd`, la misión «La caravana perdida» con los hitos `mc_*` de `DISENO_V12.md` §2.
     Interfaz que usa la región:
     - `piezas() -> Array` de `[id, Vector3, radio, texto]`;
     - `accion(region, id)`, `senal(region, arg)`, `dialogo_terminado(region, nombre)`;
     - `hallazgo(region, r)`, `vigilar(region, pos)`, `ruinas_reveladas() -> bool`.
  2. `zonas3d/mar_cristal/gusano.gd`: `_init(region)` y `actualizar(delta, pos)`. Son las vibraciones en la arena que
     tiembla, el surco, el rugido y la aparición, que lleva al encuentro especial.
  3. `buscador.gd`:
     - `tiene()` y `dar()`;
     - cambiar `REGIONES["mar_de_cristal_1"]` a este mapa: área `Rect2(18, 26, 62, 58)`, Sello de la caravana en
       (55,5; 57,0), que pide `mc_caravana`, y Llave de vidrio en (49; 21), que pide `mc_ruinas`;
     - filtrar los únicos por su hito en `pendientes`;
     - ajustar `prueba_buscador`.
  4. `zonas3d/mar_cristal_3d.tscn`, como `oakhaven_3d.tscn`.
  5. `modo3d.gd`: `REGIONES[4]` y `EN_PRUEBAS[4] = "mardecristal"`. En `menus.gd`, la opción de Ajustes «en
     pruebas», como la de Oakhaven 3D.
  6. **Pruebas** nuevas:
     - `prueba_mar_cristal`: carga, colisiones, salida, guardado, misión de principio a fin, tormenta y cobijo,
       buscador sin duplicados al recargar;
     - capturas con ventana.
  7. **Enemigos del desierto:** escorpión de vidrio que se entierra, espíritu de polvo con tormenta, y el gusano
     (original, con señales). Usar los nombres que proponga narrativa.
  8. **Investigación de Kael** para subir el buscador: nivel 2 con 2 Fragmentos de espada y 1 Mineral rúnico; nivel 3
     con 2 Reliquias de vidrio y 5 Monedas antiguas.
- **Ninguna prueba Android de la V12:** no se ha compilado ninguna APK de la V12.

## Narrativa, integrada (`b13bb11`)

- **Personajes:** `ismena.dch` (la cartógrafa) y `oren.dch` (su hermano), en `aethelgard/dialogos/personajes/mar_cristal/`.
- **Diálogos:** 19 timelines `mc_*` en `aethelgard/dialogos/mar_cristal/`, con variantes según el grupo (`_lya`,
  `_solo`) y según el hito (`mc_cartografa_espera_*`).
- **Señales:** `mc:buscador`, `mc:caravana`, `mc:superviviente` y `mc:fin`.
- **Cuál lanzar en cada momento:** `docs/v12/NARRATIVA_DESIERTO.md`, §2.1 y §2.2, con los textos de la región y los
  enemigos.
- **Falta, por parte del coordinador:**
  - registrar `ismena` y `oren` en Dialogic, como `registrar_dialogic()` de Oakhaven, o lanzar las timelines por su
    ruta;
  - comprobar que cargan.
  `mar_cristal_3d.gd` (`dialogo()`) ya las lanza por su ruta completa.
- **Nombres propuestos, sin canon:** Ismena, que sustituye a Marga de la V11; Oren; Vidracrán, el escorpión de vidrio;
  Tolvanera, el espíritu de polvo; y Tragaluz, el gusano, con las alternativas «el Sordo» y «Bramavidrio».
- **Preguntas para el usuario:** si valen Ismena y Oren, el nombre del gusano, si el mural puede leer «…de los
  Espejismos», y qué reliquia es la recompensa.
