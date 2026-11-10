# Combate · V9, hito 7: escalado de los enemigos (10/11/2026)

Rama `claude/v9-escalado` (copia `D:\Aethelgard_v9_escalado`), sobre `82bb3af`. Encargo: directiva V9, punto 8
«Enemigos con escalado de nivel» y 3.6 «Escalado de jefes». Que los enemigos mejoren de forma controlada cuando el
grupo progresa, sin igualar nunca su nivel.

## 2026-11-10 17:05 · Escalado por región y de los jefes

### Qué había (observado en el código, 10/11, `82bb3af`)
- `progreso.gd`: `NIVEL_ZONA` (nivel recomendado de cada región), `nivel_grupo()` (la media de los activos),
  `zona_limpia()` (grupo 5 niveles o más por encima: menos encuentros y los enemigos débiles huyen solos) y `mult_exp()`
  (experiencia por héroe: hasta x2 si va por debajo, x0,1 con 5 o más por encima, jefes x10). Nada tocaba los PV ni el
  ataque de los enemigos: salían siempre con los números de `ENEMIGOS`.
- `combate.gd _elegir_enemigos`: copia `ENEMIGOS[clave]` y fija `hp_max = hp`. Las recompensas las suma
  `combate_recompensas.gd de_enemigos` con el `exp` y el `oro` de cada enemigo.
- **Los 404 PV del Guardián del Bosque (420 en `ENEMIGOS`)** no son un escalado: es la **Congelación de Frostfang**.
  Kael empieza con Frostfang; su primer golpe congela y quita `VITALIDAD_CONGELACION × 8 = 16` PV máximos durante dos
  rondas (`_congelar`), y luego los devuelve. Comprobado ejecutando, aislado (sonda temporal fuera del proyecto): al
  empezar 420/420; en el fotograma 221, tras el primer golpe, 399/404 con «congelado 2, quitado 16».

### Qué se ha hecho
- **`aethelgard/combate_escalado.gd`** (nuevo; funciones estáticas, sin estado, como `combate_formulas.gd`):
  - nivel del encuentro = nivel del grupo acotado a `[base, base + SUBIDA[región]]`; la base es `NIVEL_ZONA` (una sola
    tabla de niveles para el ritmo, la experiencia y el escalado);
  - por cada nivel sobre la base: PV +8 %, ataque +5 %, experiencia +8 %, oro +5 %, con techo (PV y exp x1,40; ataque
    y oro x1,25). La velocidad (ATB), la personalidad, los patrones y las fases no cambian;
  - **jefes** (personalidad `jefe` o `bosque`, `fases`, `ultimo_aliento`, o cualquier enemigo de un combate fijo):
    como mucho base + 2 (`SUBIDA_JEFE`), y nunca por debajo de sus valores de diseño;
  - en la base o por debajo **no cambia ningún número**; solo se apunta `nivel_encuentro` en el enemigo.
- **`combate.gd`**: un `preload` y tres líneas en `_elegir_enemigos`. El nivel del grupo se lee una vez, al crear los
  enemigos: el nivel del encuentro queda fijo todo el combate.
- Lo que ya existía sigue encima: `mult_exp` se aplica después, sobre la experiencia ya escalada (con 5 o más niveles
  por encima, x0,1), y en zona limpia los enemigos débiles siguen huyendo.

### Tabla de escalado (de `prueba_escalado`, comprobado ejecutando)

| Región | Base | Tope normal | Tope jefe | Grupo: por debajo · igual · +3 · +10 · +30 → nivel del encuentro (PV ×, ataque ×) |
|---|---|---|---|---|
| llanura (Pastos Verdes) | 2 | 5 | 4 | 1→2 (1,00) · 2→2 (1,00) · 5→5 (1,24 / 1,15) · 12→5 · 32→5 (1,24 / 1,15) |
| bosque | 4 | 8 | 6 | 1→4 · 4→4 · 7→7 (1,24 / 1,15) · 14→8 · 34→8 (1,32 / 1,20) |
| montana | 7 | 11 | 9 | 4→7 · 7→7 · 10→10 (1,24 / 1,15) · 17→11 · 37→11 (1,32 / 1,20) |
| garganta | 7 | 11 | 9 | igual que montana |
| desierto | 10 | 14 | 12 | 7→10 · 10→10 · 13→13 (1,24 / 1,15) · 20→14 · 40→14 (1,32 / 1,20) |
| nieve | 15 | 20 | 17 | 12→15 · 15→15 · 18→18 (1,24 / 1,15) · 25→20 · 45→20 (1,40 / 1,25) |
| yermo | 18 | 23 | 20 | 15→18 · 18→18 · 21→21 (1,24 / 1,15) · 28→23 · 48→23 (1,40 / 1,25) |
| ceniza | 34 | 38 | 36 | 31→34 · 34→34 · 37→37 (1,24 / 1,15) · 44→38 · 64→38 (1,32 / 1,20) |
| ciudad | 0 | 0 | 0 | sin escalado |
| otra región | 1 | 5 | 3 | (por defecto: subida 4) |

Experiencia: el mismo multiplicador que los PV. Oro: el del ataque. Ejemplos (comprobados):

| Enemigo | Caso | PV | Ataque | Exp | Oro | Nivel |
|---|---|---|---|---|---|---|
| Grimfang (110/15/28/18) | bosque, grupo 7 (+3) | 136 | 17 | 35 | 21 | 7 |
| Grimfang | bosque, grupo 34 (tope) | 145 | 18 | 37 | 22 | 8 |
| Guardián del Bosque (420/17/90/0) | llanura, combate fijo, grupo 34 | 487 | 19 | 104 | 0 | 4 |
| Gorthor (460/22/60/150) | garganta, grupo 7 (base) | 460 | 22 | 60 | 150 | 7 |
| Zarzalín (80/11/20/12) | llanura, Kael a nivel 1 | 80 | 11 | 20 | 12 | 2 |

Por qué así de moderado: un héroe gana por nivel +6 PV y 3 puntos de atributo (en Fuerza, ~+15 % de golpe); el
enemigo, +8 % de PV y +5 % de ataque, y deja de subir en el tope.

### Pruebas (comprobado ejecutando, aislado, 10/11, sobre `ef23c42`/`be8e63e`)
- Importación aislada como `ci_local.ps1` (`D:\REBELUM_diagnostico\importaciones\v9escalado_2026-11-10_165817`);
  `project.godot` deshecho tras importar.
- `ejecutar_pruebas.ps1 -Solo prueba_escalado,prueba_combate_huella,prueba_combate_seguro,prueba_guardian_bosque,prueba_equilibrio,prueba_ia,prueba_recompensas`:
  **7 SUPERADAS, 0 FALLIDAS** (`D:\REBELUM_diagnostico\pruebas\2026-11-10_170339\resumen.md`). La huella: «9 de 9
  combates iguales», SHA `725aef4aad0d90bdd6289d5ce865754de59491574b8467ef88a29ab8f73b54cc` (la de la referencia, sin
  regenerarla). partida.save real sin cambios.
- `prueba_escalado` (nueva, en `lista_pruebas.txt`, «-- auto»): la tabla de arriba con todos los enemigos de
  `ENEMIGOS`, normales y en combate fijo; y cuatro combates de verdad: base (los números de `ENEMIGOS`), +3 en el
  bosque (victoria, reparto 70 exp y 42 monedas), +30 en el bosque (nivel 8 fijo aunque el grupo pase a 50 a mitad;
  los Grimfang huyen por la zona limpia) y el Guardián del Bosque con el grupo a 34 (487 PV, 19 de ataque, fase 2 y
  victoria). Son combates con ataques automáticos (y el Guardián empujado como en `prueba_guardian_bosque`): prueban que
  el escalado funciona y no rompe nada, **no** la estrategia de un jugador.
- Batería completa con `ci_local.ps1`: ver la sección siguiente si se añade.

### Límites y pendiente
- No se ha jugado a mano ni en el Redmi: el equilibrio real con el escalado (sobre todo Kael solo en Pastos Verdes con
  nivel 3-5) está **pendiente de verificar** por una persona.
- No se muestra el nivel del enemigo en la interfaz (queda en `nivel_encuentro` del enemigo por si se quiere).
- La subida por región (`SUBIDA`) y los porcentajes son una propuesta conservadora: si el usuario quiere más o menos
  presión, se cambian en la tabla de `combate_escalado.gd` sin tocar `combate.gd`.
