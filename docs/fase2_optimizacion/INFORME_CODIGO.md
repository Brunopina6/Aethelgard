# B. INFORME DE CÓDIGO — Fase 2 (10/11/2026)

## Antes de la fase: integración de los especialistas (ya en GitHub)

En `integracion-experimental`, subida sin forzar (`59c3a67..0d06bd1`):
- **Ramas integradas:**
  - sonido (`f891b0c`): mezcla del combate y memoria del audio;
  - narrativa (`04d33a2`): rutinas de los vecinos de Oakhaven;
  - Oakhaven 3D (`384f789`): modelos ligeros, jardines, botica y posadera;
  - rendimiento (`4cb20cc`): calidad adaptable.
- **Sin nada nuevo que integrar:** las ramas de animaciones, combate y Garganta 3D solo tenían commits de puesta al
  día. Su trabajo sin confirmar se ha dejado intacto en sus copias.
- **Conflictos:** dos archivos de pruebas, resueltos conservando lo de las dos ramas.
- **Fallo corregido** (`c75806b`): `prueba_boton_prologo` se cerraba 2 de cada 3 veces.
  - Causa: el renderizador falso de Godot sin ventana no aguanta crear mallas desde varios hilos, y con los modelos
    nuevos de Oakhaven había más.
  - Arreglo: sin ventana, la pantalla de carga carga de uno en uno. En el móvil y en el PC con ventana no cambia nada.
  - Resultado: 4 de 4, y la batería completa, 82 superadas y 0 fallidas.
- **Respaldo:** rama local `respaldo-integracion-antes-especialistas-20261110`.

## Fase 2: rama `claude/rebelum-optimizacion-fase2` (local, sin subir)

| Commit | Qué |
|---|---|
| `a7cf707` | Combate modular: `combate_recompensas.gd` |
| `ae5627a` | Datos ampliables: `datos/catalogo.gd`, tipos y la Corteza espinosa migrada |
| `6051936` | Base de investigaciones y talleres |
| `8381d75` | Carga inicial más ligera |

### Archivos nuevos
- `combate_recompensas.gd`: experiencia y monedas del combate, en funciones sin estado.
- `datos/catalogo.gd`, `datos/tipos/{material,receta,investigacion}.gd`, `datos/materiales/corteza_espinosa.tres`.
- `investigacion.gd` y `talleres.gd`.
- **Pruebas:** `prueba_recompensas`, `prueba_datos`, `prueba_investigacion` y `prueba_precarga`, con sus datos de
  ejemplo en `pruebas/datos_prueba/`. **Herramienta:** `pruebas/medir_texturas_modelos.gd`.

### Archivos cambiados
- `combate.gd`: `_repartir_exp` usa `combate_recompensas.gd`. Textos, sonidos y esperas, igual que antes.
- `equipo_extra.gd`:
  - `MATERIALES` y `BOTIN` dejan de ser constantes y pasan a ser `materiales()` y `botin()`, que leen el catálogo;
  - `botin_de` da lo mismo que antes.
- `tienda.gd`: vende los materiales con `materiales()`.
- `progreso.gd`: la clave `investigaciones` en lo que se guarda. Las partidas antiguas no la tienen y cargan igual.
- `recursos.gd`: la lista de la precarga no incluye texturas sin uso, la versión de Oakhaven de otro perfil ni
  `vegetacion_prueba/` y `pruebas/`.
- `pruebas/medir_precarga.gd`: medida por región y con `perfil=`.
- `pruebas/lista_pruebas.txt`: cinco pruebas nuevas.

## Sistemas modularizados

- **Combate:** van dos piezas fuera de `combate.gd`: las fórmulas de daño (fase 1) y las recompensas (fase 2). La huella
  de los nueve combates es idéntica (`725aef4a…`).
  - **Siguiente pieza propuesta:** la IA de los enemigos normales (`_turno_enemigo`).
  - **Por qué no se hizo ahora:** elige objetivo con el azar del combate, y hay que mover las llamadas al azar en el
    mismo orden para que la huella no cambie. Antes conviene integrar el trabajo sin confirmar de `area-combate`, que
    toca `combate.gd`.
- **Datos:** un recurso por cosa, validado. Se migró un tipo completo (materiales) para demostrar el camino sin dos
  fuentes de verdad.
  - **Siguientes candidatos:** accesorios y armas especiales (`equipo_extra.gd`), y después enemigos (`combate.gd`
    ENEMIGOS).
  - **Cómo migrarlos:** uno cada vez, con una prueba que compare campo a campo con la tabla antigua.

## Mejoras eficaces

- Precarga: −92 archivos, −95 MB importados en el PC, −0,9 s de arranque y −280 MB de memoria máxima (ver informe A).
- Pruebas: cinco nuevas, todas con comprobaciones reales (ninguna «pasa sin comprobar»).

## Intentos descartados y por qué

- **Carga diferida de lo del combate:** riesgo de tirones sin poder medirlo en el Redmi (informe A).
- **Cambios en el 3D** (sombras, vegetación, LOD): sin el teléfono no se puede demostrar que no empeoran la imagen.
- **Recetas e investigaciones reales:** serían mecánica y economía nuevas; esperan al diseño aprobado
  (`FASE3_TALLERES.md`).
