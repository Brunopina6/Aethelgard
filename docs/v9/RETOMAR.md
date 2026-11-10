# RETOMAR — REBELUM: fase 3 («El bosque que no recuerda») y directiva V9 (10/11/2026, 19:20)

Escrito para leerlo sin saber programar. **Rama actual:** `claude/rebelum-v9`. Contiene todo el trabajo de la fase 3 y
de la V9.

## 1. Estado exacto de Git (comprobado el 10/11, ~19:20)

| Rama | Copia | Commit | En GitHub | Notas |
|---|---|---|---|---|
| **`claude/rebelum-v9`** | `D:\Aethelgard_v9` | `efa1225` + el commit de este traspaso | **NO** (local) | **La buena.** Nace de la v293 (`dca4c1c`) y contiene todo lo de abajo |
| `claude/rebelum-bosque-fase3` | `D:\Aethelgard_fase3` | `dda5473` | NO | Fase 3; ya dentro de la V9 |
| `integracion-experimental` | `D:\Aethelgard_alpha` | `b4e26e2` | sí (`b4e26e2`) | Fase 2 fusionada y subida, con autorización |
| ramas de especialistas: `claude/v9-escalado`, `claude/v9-sector`, `claude/v9-coloso-modelo`, `claude/v9-coloso-combate`, `claude/v9-sonido-guardian`, `claude/f3-guardian-modelo`, `claude/f3-dialogos` | `D:\Aethelgard_v9_*`, `D:\Aethelgard_f3_*` | — | NO | **Todas fusionadas en `claude/rebelum-v9`** (comprobado con `git merge-base --is-ancestor`) |
| `main` / `desarollo` | — | `d4b2d16` / `2d1adc4` | sí | Sin tocar |

**Cambios sin confirmar:** ninguno en `D:\Aethelgard_v9`. En algunas copias de especialistas quedan `.uid` sueltos que
generó la importación; ya están confirmados en la V9, así que no hay que hacer nada.

**Respaldos:** ramas y etiquetas `respaldo-integracion-*` en local; no se borran.

## 2. Qué hay hecho (probado en el PC; **nada de esto se ha probado en el Redmi**)

**«El bosque que no recuerda»**, en Pastos Verdes 3D tras la misión de Tilo (`zonas3d/bosque_pastos.gd`; diseño en
`docs/fase3_bosque/AVENTURA_JUGABLE.md`):
- Tilo abre la aventura y el árbol de su puesto amanece marcado.
- Tres pistas en sitios distintos: los lirios, los surcos y la inscripción.
- La senda que abre Garon lleva a las ruinas, con el manantial, el ciervo de niebla y el cofre.
- Nueve puntos de materiales.
- **El orbe del altar:** dos futuros del bosque; verlos adelanta la investigación de Lya.
- **El Guardián del Bosque Olvidado:** jefe de dos fases con modelo de Blender; se purifica con el Elixir o se
  derrota.
- El claro del noreste cambia según el desenlace.
- Oakhaven reacciona: Doña Encina y su tienda.

**Talleres** (`alquimia_menu.gd`, `talleres.gd`, `investigacion.gd`, `datos/`):
- Lya: 3 recetas con efecto real y 2 investigaciones.
- Kael: mejora de ataque y técnica de crítico.
- Garon: mejora de defensa y runa.
- Taller conjunto: Amuleto del claro.
- Se abren desde Pastos Verdes y desde el menú del juego (pestaña Objetos).

**Combate:**
- Escalado de enemigos por región: `combate_escalado.gd`.
- **Coloso de la Falla**, jefe opcional de la Garganta 3D: `combate_coloso.gd`, `enemigos/coloso_falla/` y
  `zonas3d/garganta/coloso.gd`.

**Encargos:**
- `encargos.gd`: registro con el formato de las misiones de Oakhaven.
- Pestaña Encargos del Diario.
- «Canela se ha perdido», con Pip.

**Sonido:** identidad del Guardián y del orbe (`sonido.gd`, `audio/efectos/guardian/`).

**El detalle, en:**
- `docs/v9/ESTADO_V9.md` (por hitos);
- `docs/fase3_bosque/INFORME_DESARROLLO.md`;
- los informes de los especialistas en `docs/memory/agents/` (`*_fase3_*`, `*_v9_*`).

## 3. Pruebas

- **Última batería completa:** **100 superadas, 0 fallidas**, 43 manuales y 0 no seguras, sobre `56dfb9c`
  (`D:\REBELUM_diagnostico\pruebas\2026-11-10_185955\resumen.md`). La partida real, sin cambios.
- **Cómo ejecutarlas.** Desde **PowerShell** (nunca desde Bash), en `D:\Aethelgard_v9`:
  `powershell -ExecutionPolicy Bypass -File .\ci_local.ps1`. Importa con datos aislados, deshace lo que la importación
  cambia en `project.godot` y lanza la batería. Debe terminar con «CI LOCAL: todo superado».
  - **Una sola prueba:** `aethelgard\pruebas\ejecutar_pruebas.ps1 -Solo <prueba>`.
  - **Las de capturas con ventana:** `-Manual -Solo <prueba>`.
- **Pruebas de esta tanda:**
  - **Aventura:** `prueba_bosque_pastos` (el recorrido entero en la región).
  - **Jefes:** `prueba_guardian_bosque`, `prueba_guardian_modelo`, `prueba_coloso`, `prueba_coloso_garganta` y
    `prueba_coloso_modelo`.
  - **Talleres y datos:** `prueba_datos`, `prueba_investigacion`, `prueba_oficios` y `prueba_tienda_bosque`.
  - **Encargos y diálogos:** `prueba_encargos` y `prueba_dialogos_bosque`.
  - **Combate y región:** `prueba_escalado` y `prueba_claro_guardian`.
  - **Sonido:** `prueba_audio_guardian`.
  - **Capturas:** `fotos_bosque.gd`, `fotos_guardian_combate.gd` y `fotos_coloso`.
- **Cuidado:**
  - si la importación borra el registro de Dialogic de `project.godot`, `git restore aethelgard/project.godot` (lo
    hace `ci_local.ps1`);
  - sin ventana, la pantalla de carga carga de uno en uno: es a propósito.

## 4. APK

- **La última es la v499:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261110-56dfb9c.apk`.
  - «REBELUM Auditoría», paquete aparte `com.aethelgard.auditoria`;
  - 281,1 MB; SHA-256 `52d7a120…`.
  - **Está compilada en local y SIN VALIDAR EN EL REDMI.**
- **Las anteriores, sin validar:** v449 (fase 3) y v471.
- **La última validada en el Redmi es la v420** (fase 2).
- **Para instalar:** copiarla a Descargas e instalarla tocándola. MIUI cancela las instalaciones por USB si nadie
  pulsa «Instalar».
- **Qué probar:** `docs/fase3_bosque/PENDIENTES_REDMI.md`, más el orbe, los talleres de Kael y Garon, el Coloso y
  «Canela».

## 5. Prohibido sin autorización expresa del usuario

- **No fusionar ni subir** `claude/rebelum-v9` ni `claude/rebelum-bosque-fase3`.
- No publicar APK y no tocar `main` ni `desarollo`.
- Nada de `push --force`, `reset --hard` ni borrar ramas o respaldos.
- La memoria (`memoria-desarrollo`) sí se publica en cada hito.

## 6. Errores conocidos y dudas

- **Combate:** Juicio y Giro de Garon (con su modelo 3D) no pasan por `combate_bosque.dano_recibido`, así que la coraza
  de raíces del Guardián no reduce su daño.
- **Respaldo 2D:** si faltara el modelo, el respaldo 2D del Guardián podría dejar su vida fuera de pantalla.
- **Sonido:**
  - nadie ha escuchado el del Guardián;
  - el Coloso no tiene efectos propios: «Leer runas» usa «misterio».
- **Claro del Guardián:** un árbol de la región, en (14, -14), tapa parte del claro, y hay dos arbustos dentro del
  anillo.
- **Equilibrio:** no se ha jugado a mano, sobre todo Kael solo en Pastos Verdes con el escalado.
- **Canon por revisar con el usuario:**
  - los nombres «El corazón del bosque» y «Corazón de roble»;
  - que el Guardián hable;
  - el orbe (propuesta experimental);
  - los textos del Coloso.

## 7. Pendiente, por orden

1. Validar la v499 en el Redmi y corregir lo que salga.
2. Con autorización: fusionar `claude/rebelum-v9` en `integracion-experimental` y subirla.
3. **Hitos de la V9 sin hacer:**
   - el Campanero del Porvenir;
   - el Emperador Slime;
   - el cuarto protagonista (magia negra; antes, revisar el «Mago negro» Nyx antiguo de `grupo.gd`);
   - la ampliación de Oakhaven;
   - más encargos;
   - los efectos del Coloso.

## 8. Cómo seguir con «El bosque que no recuerda»

- **Diseño e identificadores:** `docs/fase3_bosque/AVENTURA_JUGABLE.md`.
  - **Hitos:** `bq_*`, `enc_perro_*`.
  - **Desenlace:** `decisiones.guardian_bosque`.
  - **Combates fijos:** `pastos_guardian` (grupo 11) y `garganta_coloso` (grupo 12).
- **Lógica de la región:** `zonas3d/bosque_pastos.gd`. Para añadir una cosa que se examina:
  - `_punto(id, nodo, texto_del_botón)`;
  - su caso en `accion()`;
  - su diálogo en `tras_dialogo()`.
- **Diálogos:**
  - en `dialogos/bosque/` y `dialogos/oakhaven/`;
  - se registran en `project.godot` (`dtl_directory`, en orden alfabético) y en `pruebas/prueba_dialogos_bosque.gd`;
  - sin «Érebo», «recuerdo», «memoria» ni «corazón».
- **Datos nuevos** (materiales, recetas e investigaciones): un `.tres` en `datos/`, que `prueba_datos` valida sola.
- **Encargos nuevos:** una entrada en `datos/encargos_pastos.gd`, o en el módulo de su región, añadido a
  `encargos.gd` FUENTES.
