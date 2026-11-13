# Bestiario de producción V12 (e01-e10): matriz honesta y conversión al ATB

Encargo del usuario del 13/11: `D:\REBELUM_diagnostico\v12\expansion\encargos_13_11\Aethelgard_Bestiario_Produccion.pdf`
(29 págs., fechado el 12/11). Es una **especificación propuesta** escrita para combate de acción en tiempo real; REBELUM
es **ATB por turnos**. Aquí se documenta cómo se adapta cada cifra al sistema real, el estado de cada enemigo por puertas
y dónde encaja en el mundo (`docs/v12/INVENTARIO_MUNDO.md`). Especialista: «bestiario», rama `claude/v12-bestiario`.
Informe: `docs/memory/agents/combate_v12_bestiario.md`.

Estados: **pendiente** (no empezado) · **parcial** (hecho en parte o sin revisar) · **verificado** (comprobado con
pruebas o capturas, con su evidencia) · **bloqueado** (no se puede hacer ahora y por qué). Nada está validado en
Android: el Redmi no está conectado (todas las puertas ANDROID quedan **bloqueadas** hasta medirlo allí).

## 1. Matriz e01-e10

| ID | Enemigo | Familia (pág. 23) | Región de REBELUM (nivel base) | DISEÑO | ARTE | INTEGRACIÓN | COMBATE | ANDROID |
|---|---|---|---|---|---|---|---|---|
| e01 | Peón de Linde | ágil | **Pastos Verdes** y caminos (llanura, 2) | verificado | verificado (PC) | verificado | verificado (PC) | bloqueado |
| e02 | Velador de Corteza | pesada | **Gran Bosque Verde** (bosque, 4) | verificado | verificado (PC) | verificado | verificado (PC) | bloqueado |
| e03 | Cestero de Turba | estándar | Gran Bosque Verde: charcas y cauce hundido (bosque, 4); después Valle de los Ecos | parcial | pendiente | pendiente | pendiente | bloqueado |
| e04 | Cantero de Sal | pesada | Mar de Arena de Calid / Mar de Cristal (desierto, 10) | parcial | pendiente | pendiente | pendiente | bloqueado |
| e05 | Farolero de Escarcha | estándar | Cumbres de Ciclópea (nieve, 15; región aún 2D) | parcial | pendiente | pendiente | pendiente | bloqueado (la región no es 3D) |
| e06 | Remachador de Brasa | estándar | Abismo de Ceniza (ceniza, 34; 2D, isla) o las forjas de la Garganta (7) | parcial | pendiente | pendiente | pendiente | bloqueado |
| e07 | Campanero de Umbral | estándar | Valle de los Ecos (yermo, 18; 2D) | parcial | pendiente | pendiente | pendiente | bloqueado |
| e08 | Cartógrafo de Duna | ágil | Mar de Arena de Calid, dunas y caravanas (desierto, 10) | parcial | pendiente | pendiente | pendiente | bloqueado |
| e09 | Custodio de Nácar | pesada | Sunken City / Templo Sumergido de Atlantis (2D) | parcial | pendiente | pendiente | pendiente | bloqueado |
| e10 | Recolector de Vidrio | ágil | Calid: ruinas sepultadas y máquina enterrada (sector futuro del desierto, 10-14) | parcial | pendiente | pendiente | pendiente | bloqueado |

«DISEÑO parcial» en e03-e10: la ficha del documento está leída entera y su conversión al ATB está propuesta en el
apartado 4, pero sin cifras probadas en combate. Un enemigo solo pasa a «terminado» con todas sus puertas verificadas;
importar un modelo no lo completa.

### Evidencia de e01 (13/11, rama `claude/v12-bestiario`)
- **Diseño**: ficha adaptada (apartado 3). Lámina de revisión frente / perfil / espalda junto a Kael:
  `D:\REBELUM_diagnostico\v12\expansion\bestiario\laminas\peon_linde_lamina.png`; hoja de 28 poses: `..\peon_linde_poses.png`.
- **Arte**: guion `aethelgard/enemigos/peon_linde/fuente/crear_peon_linde.py` (Blender 5.2.3; rig base
  `aethelgard/enemigos/bestiario_comun/fuente/bestiario_rig.py`); `.blend` en `..\laminas\peon_linde.blend` (fuera de Git).
  GLB `aethelgard/enemigos/peon_linde/peon_linde.glb` (3 536 triángulos, 24 huesos deformantes, 4 influencias), atlas
  `peon_linde.webp` (1024) y `peon_linde_bajo.webp` (512), `peon_linde_clips.json` (20 clips con duración e instantes).
- **Integración**: `aethelgard/enemigos/peon_linde/peon_linde_3d.gd`, `aethelgard/combate_peon.gd`, ganchos «V12, Peón»
  en `combate.gd`, sonidos `aethelgard/audio/efectos/peon/` (claves en `sonido.gd`).
- **Combate**: `pruebas/prueba_peon_v12.gd` (y `fotos_peon_v12.gd`); vídeos en `..\bestiario\videos\`.
- **Android**: sin medir (Redmi desconectado). Lo medido en el PC está en el informe; no son FPS del teléfono.

### Evidencia de e02 (13/11, misma rama)
- **Diseño**: apartado 3 bis. Lámina `..\laminas\velador_corteza_lamina.png`; hoja de 21 poses `velador_corteza_poses.png`.
- **Arte**: guion `aethelgard/enemigos/velador_corteza/fuente/crear_velador_corteza.py` (mismo rig base a 1,95 m);
  `.blend` en `..\laminas\velador_corteza.blend` (fuera de Git). GLB `velador_corteza.glb` (2 872 triángulos, 24
  deformantes), atlas 1024 / 512, `velador_corteza_clips.json`.
- **Integración**: `velador_corteza_3d.gd`, `aethelgard/combate_velador.gd`, ganchos «V12, Velador» en `combate.gd`,
  sonidos `aethelgard/audio/efectos/velador/`.
- **Combate**: `pruebas/prueba_velador_v12.gd` (y `fotos_velador_v12.gd`); vídeos en `..\bestiario\videos_velador\`.
- **Android**: sin medir.

## 2. Conversión general del documento al ATB de REBELUM (vale para los diez)

| Documento (tiempo real) | REBELUM (ATB por turnos) | Por qué |
|---|---|---|
| Referencia: héroe de 100 PV y golpe de 20 | Los números de `ENEMIGOS` de la región (`combate.gd`) y su escalado (`combate_escalado.gd`: base de la región en `progreso.gd NIVEL_ZONA`, +8 % de PV y +5 % de ataque por nivel del grupo sobre la base) | Las fórmulas de daño no se tocan; se escalan los PV y el ataque a la región real |
| Daño «9-12» de un ataque | Multiplicador del ataque del enemigo (`atk × mult`, con el ±2 de siempre); el héroe resta su defensa / 2 y Defender lo deja a la mitad (lo de siempre de `_animar_golpe`) | Proporción del documento: daño del ataque ÷ el mayor del golpe básico |
| Aviso (anticipación) ≤ 0,9 s | Anticipación DENTRO del clip (la pose, el cartel y el sonido) antes del instante del impacto | Menos de un turno: no merece un turno entero |
| Aviso largo o ataque fuerte | Un **turno de preparación**: «⚠» sobre él (la señal de siempre), marca sobre el héroe elegido y su estado; golpea en su turno siguiente. Se corta como en la V11 (un cuarto de su vida mientras prepara o Quiebra → aturdido, pierde el turno) | El jugador tiene al menos un turno de héroe para responder (Defender, Guardia, cortar) |
| Ventana activa y recuperación | El instante del impacto (`impacto` del JSON) resuelve el daño UNA vez; la recuperación es el resto del clip | El combate decide; el clip lo representa |
| CD en segundos | Turnos: un turno de enemigo dura 100 / velocidad s (Peón, 15 → 6,7 s). CD < 1 turno → 0 turnos; «no repetir» → 1 turno; «medio CD» tras cortarlo → no se prepara en su turno siguiente | Con ATB, los segundos de CD caben dentro de un turno |
| Área «arco», «cono», «rectángulo», «disco» | **a uno** (cuerpo a cuerpo de frente), **en fila** (el elegido y el de detrás en la formación, el segundo al ×0,5), **a todos** (discos y anillos grandes) | Las posiciones del combate son lógicas, no metros |
| Proyectil (velocidad, alcance, vida) | **A distancia**: desde su sitio; el proyectil vuela en 2D ~0,3 s y el daño cae **al llegar**; la Guardia de Garon y Defender valen | La emisión no daña (regla del documento) |
| Lento X % por N s | **Retroceso** (como el empuje): el tiempo que el documento quita con la lentitud, quitado de una vez de la barra ATB. Los estados por turnos (veneno, quemadura) usan los que ya existen | No crear sistemas paralelos |
| Empuje (m) | **Retroceso**: quita una fracción de la barra ATB a quien lo recibe sin defender; nunca a quien ya tiene su turno en la cola | El único «espacio» del ATB es el tiempo |
| Navegación, detección, retorno | El encuentro del mapa (`grupo_al_azar`, su región y el tamaño del grupo); en el combate, ir corriendo al héroe y volver | El combate no tiene navegación |
| Pesos de selección 50/30/20 | Igual, entre los ataques posibles en ese turno | — |
| «Máximo dos ataques seguidos» | Tras dos ataques, el turno siguiente se repliega (sin daño: la ventana para castigarle) | El descanso de 1,2 s no llega a un turno; un turno de repliegue es la pausa legible |
| 18 clips con prefijo `e01__clip` | Los nombres del juego (`reposo`, `entrada`, `ataque`…: `enemigo_v12_3d.gd` los busca así) con la equivalencia en el JSON (`mapa_pdf`) y, si el ATB lo pide, `carga` y `carga_espera` | El documento lo permite: «si el proyecto exige otra jerarquía, adaptar el piloto y documentarlo» |
| Rig base (root, pelvis, spine_01…) | `raiz`, `cadera`, `columna_01`, `columna_02`, `pecho`, `cuello`, `cabeza`, `clavicula`, `brazo`, `antebrazo`, `mano`, `muslo`, `pierna`, `pie`, `dedos` (.L/.R): 22 deformantes; sockets `arma.R`/`arma.L` (llevan el arma rígida: deforman), `pecho_fx` y `luz` (no deforman) | Los nombres que ya usan el Rig de Blender y el juego |
| Escala animada de huesos prohibida | Solo `luz` (sin malla, no deforma: es el canal del brillo de los ojos que lee `enemigo_v12_3d.gd`) | — |
| Estructura `art/enemies/e01/…`, `EnemyDefinition` | La del proyecto: `enemigos/<nombre>/` (GLB, texturas, JSON, guion de Godot), `enemigos/<nombre>/fuente/` (guion de Blender, con `.gdignore`), `combate_<nombre>.gd` (la definición de ataques y su ejecución) y `ENEMIGOS`/`MODELOS`/`GRUPOS` de `combate.gd` | Sin arquitectura paralela |
| Interruptor | Lo nuevo va APAGADO tras `enemigos_v12` (el de los modelos propios); apagado, el azar y la huella del combate no cambian | Regla del proyecto |

## 3. e01 · Peón de Linde (piloto, hecho)

**Dónde sale.** Pastos Verdes (región «llanura», nivel base 2: Kael solo hasta PV-03, con Lya hasta PV-05, con Garon
después; los tres llegan a nivel 1 al unirse). Con `enemigos_v12` encendido, uno de cada cuatro encuentros al azar de la
llanura es de Peones, del tamaño del grupo: 1 héroe → `GRUPOS[22]` (uno), 2 → `[23]` (dos), 3 → `[24]` (tres). El
documento propone 1-3 enemigos y empezar con uno solo: el grupo de Kael solo es de uno. Apagado, nunca sale.

**Números (ENEMIGOS["peon_linde"]).** PV 72, ataque 11, velocidad 15, experiencia 22, monedas 14; entre el Zarzalín
(80 / 11 / 14) y Grimfang (110 / 15 / 13). El documento pide 60-85 PV con un golpe de 20 (3-4 golpes); en la llanura
Kael de nivel 1-3 quita unos 18-25, así que cae en 3-4 golpes como pide.

| Ataque (documento) | Clip (impacto) | En el ATB | Daño | Contra |
|---|---|---|---|---|
| A1 Piquete cruzado (aviso 0,55, arco 80°, 9-12) | `ataque` 1,27 s (0,62) | A uno, cuerpo a cuerpo; corre en zigzag, golpea y retrocede a saltitos (el `retroceso`) | ×1,0 | Defender |
| A2 Estaca de aviso (aviso 0,85, proyectil 7 m/s, 4,5 m, 7-10; la réplica reaparece) | `lanzar` 1,7 s (suelta 0,85; `recoge` 1,25: saca otra del haz de la espalda) | A distancia, desde su sitio, a la retaguardia (la curandera si ha curado; si no, quien menos vida tenga); el daño AL LLEGAR (vuelo 0,3 s); nunca dos seguidas | ×0,85 | Defender, Guardia de Garon |
| A3 Zancada de lindero (aviso 0,90, avance 2 m con barrido, 12-15, empuje 0,4 m) | `carga` + `carga_espera` (el turno de aviso) y `zancada` 1,9 s (desde la carga 0,9; impacto 1,0) | Turno de aviso con marca; **en fila**: el marcado y el de detrás en el mismo impacto; **Retroceso** −15 % de la barra ATB a quien la recibe sin defender; nunca dos seguidas; cortada → aturdido y sin prepararla el turno siguiente | ×1,3 y ×0,5 al de detrás | Defender (mitad y sin retroceso), Guardia, cortarla |
| Comportamiento: «zigzaguea, busca flanco, retrocede 2 m; máx. dos ataques seguidos» | `retroceso` 0,67 s | Tras dos ataques, se repliega un turno (sin daño) y su ataque siguiente va a la retaguardia | — | Castigarle en ese turno |

CD 2-3 s → 0 turnos (cabe en un turno de 6,7 s), salvo las reglas de «no repetir». Furia de siempre con < 30 % de
vida (×1,5) y huida de siempre en «zona limpia». Heridas: un golpe ≥ 12 % de su vida alarga la sacudida.

**Clips (20).** Los 18 del documento por su equivalencia (spawn → `entrada`, idle → `reposo`, alert → `alerta`, walk_fwd
→ `caminar`, run_fwd → `correr`, strafe_l/r → `lateral_izq/der`, turn_l/r → `girar_izq/der`, hit_front → `recibir_golpe`,
hit_back → `recibir_golpe_espalda`, stagger → `aturdido` (en bucle: es el estado de aturdido hasta su turno), death →
`derrota`, despawn → `desaparecer`, attack_01-03 → `ataque`, `lanzar`, `zancada`, retreat_step → `retroceso`), con las
duraciones del documento (±1/30 s, las de 0,35 y 0,65 s caen en 0,333 y 0,667 por los 30 fps), más `carga` y
`carga_espera` del ATB. Locomoción en el sitio. Los que el combate no usa todavía (`lateral_*`, `girar_*`,
`recibir_golpe_espalda`, `desaparecer`) están para el mapa.

## 3 bis. e02 · Velador de Corteza (hecho)

**Dónde sale.** Gran Bosque Verde (región «bosque», nivel base 4). Con `enemigos_v12`, uno de cada cuatro encuentros al
azar del bosque: 1 héroe → `GRUPOS[25]` (él solo), 2 → `[26]` (con un Slime), 3 → `[27]` (con Grimfang y un Slime). Apagado,
nunca sale. **Números:** PV 115, ataque 13, velocidad 11, experiencia 34, monedas 22 (el documento: 100-130 PV, un 50 %
más que el Peón; lento).

| Documento | Clip (impacto) | En el ATB | Daño | Contra |
|---|---|---|---|---|
| Rasgo: «protege con el escudo frontal (35-45 %); tras bloquear dos golpes abre la guardia 1 s; no bloquea atacando» | `guardia_espera` (su reposo en el combate) | **Guardia de anillos**: fuera de sus ataques, la defensa de siempre de los enemigos (golpes a la mitad); al segundo golpe parado se ABRE hasta el final de su turno siguiente (golpes enteros, «¡Guardia abierta!»); atacando y preparando la Raíz no está en guardia | — | Dos golpes flojos y luego el fuerte; o golpearle mientras prepara la Raíz |
| A1 Mazazo de poda (aviso 0,9, arco 65°, 13-17) | `ataque` 1,8 s (0,95) | A uno, cuerpo a cuerpo, andando pesado | ×1,35 | Defender |
| A2 Empuje de anillos (aviso 0,65, 6-9, empuje 0,8 m) | `empuje` 1,5 s (0,70) | A uno + **Retroceso −20 %** de la barra ATB | ×0,65 | Defender (mitad y sin retroceso) |
| A3 Raíz de umbral (aviso 1,1, disco a 3 m, 9-12, lento 20 % 2 s) | `carga` + `carga_espera` (turno de aviso) y `raiz` 2,2 s (desde la carga 1,1; impacto 1,15) | Turno de aviso con marca; desde su sitio brotan tres raíces bajo el marcado; **Retroceso −15 %** (la lentitud); cortada → aturdido y sin prepararla el turno siguiente; nunca dos seguidas | ×0,9 | Defender, Guardia de Garon, cortarla |

Lo no adaptado: «no bloquea por detrás» (el combate no tiene espaldas).

## 4. e03-e10: conversión propuesta (sin hacer; para revisar antes de producir)

Mismas reglas del apartado 2. Las cifras son puntos de partida a medir como se midió el Peón (prueba Q de equilibrio).

| ID | A1 | A2 | A3 (avisado un turno salvo que se diga) | Rasgo propio en el ATB |
|---|---|---|---|---|
| e02 Velador de Corteza | **hecho**: apartado 3 bis | | | |
| e03 Cestero de Turba | Bolsa de cieno: a distancia, marca el sitio un turno, ×0,7 al caer | Palma de turba: a uno ×0,85 + Retroceso | Vaho del cesto: en fila ×0,45 + veneno 2 turnos (la Quemadura de siempre como modelo de daño por turno; por aprobar) | Charco: máximo dos activos; mantiene la distancia (ataca desde su sitio) |
| e04 Cantero de Sal | Cuña de sal: a uno ×1,6 (aviso en el clip de 1,15 s, el más largo) | Barrido de cantera: a todos ×0,9 + Retroceso | Fisura cristalina: en fila ×1,3, primer golpe solo anuncia (dos golpes en el clip, daño en el segundo) | Lento y duro; nunca tres veces el mismo ataque |
| e05 Farolero de Escarcha | Aguja de farol: a distancia ×0,8 | Arco de vara: a uno ×0,6 (si le golpean cuerpo a cuerpo) | Sello de escarcha: a uno (disco) ×1,0 + lento; débil al Fuego, resiste el Hielo (`combate_afinidades.gd`) | Artillero: se queda atrás |
| e06 Remachador de Brasa | Mordida de tenaza: a uno ×0,95 | Remache incandescente: a distancia ×0,75 + Quemadura (la de siempre) | Purga de horno: a todos salvo el «centro seguro» (quien defiende) ×1,2 | Resiste el Fuego |
| e07 Campanero de Umbral | Badajo penitente: a uno ×0,75 | Toque de duelo: en fila ×0,8 (arcano: la defensa física no resta) | Repique de custodia: aliados +10-15 % de ataque 2 turnos, no acumulable, no a sí mismo | Apoyo: detrás de los aliados |
| e08 Cartógrafo de Duna | Disco de rumbo: a distancia ×0,75 | Tajo de compás: a uno ×0,9 | Punto ciego: en fila ×0,5 + lento | Esquiva un golpe físico cada 3 turnos (con su animación; sin invulnerabilidad) |
| e09 Custodio de Nácar | Estocada de rompeolas: en fila ×1,1 | Gancho de bajamar: a todos ×0,7 + lento | Marea seca: en fila ×1,2 + Retroceso | Guardia frontal fuera de sus ataques (golpes ×0,7) |
| e10 Recolector de Vidrio | Corte de faceta: a uno ×1,0 | Salto de esquirla: a uno ×1,2 (aviso en el clip) | Descarga de mosaico (con < 30 % de vida, como mucho cada 3 turnos): a todos ×0,6, un impacto por héroe | Frágil (PV bajos); ataca tras un fallo de un héroe |

Orden propuesto por familias (reutilizando rig y locomoción del Peón): **ágil** (e08 Cartógrafo, e10 Recolector: el
mismo ciclo de pasos y retroceso), **pesada** (e04 Cantero y e09 Custodio, sobre lo ya hecho para el e02 Velador: el ciclo lento y su
guardia frontal) y **estándar** (e03, e05, e06, e07). Los que dependen de un estado nuevo (lento, veneno) esperan a que
el usuario decida si se usa uno existente.

## 5. Segunda pasada de arte (v2, 13/11 de madrugada)

El Peón y el Velador tienen una **v2** (proporciones compactas al lado de los héroes chibi, formas de torno y cajas muy
redondeadas, atlas de 3×3 celdas más detallado y mapa de normales) con los mismos huesos, clips e instantes. La v1 se
conserva y se puede elegir (`bestiario_v1`). Láminas v1 / v2 junto a Kael, Lya y Garon a su altura del combate:
`D:\REBELUM_diagnostico\v12\expansion\bestiario\laminas\peon_linde_v1_v2_heroes.jpg` y
`velador_corteza_v1_v2_heroes.jpg`; poses `peon_linde_v2_poses.png` y `velador_corteza_v2_poses.png`. Detalle, medidas y
pruebas en el informe (`docs/memory/agents/combate_v12_bestiario.md`). La puerta ARTE de e01 y e02 sigue «verificado
(PC)» con la v2; la de ANDROID, bloqueada.
