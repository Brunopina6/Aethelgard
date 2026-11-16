# Entrega de la noche del 15 al 16/11 (REBELUM V12)

Encargo del usuario (15/11, 23:50, y «continuidad autónoma»): cerrar las optimizaciones de la muestra, ampliar la calle
aprobada a un barrio jugable de Oakhaven (interiores, habitantes trabajando, misión), mejorar Sunken City y la Arboleda
Mítica con el mismo cuidado, todo EXPERIMENTAL (solo desde el banco de Auditoría, apagado por defecto). Rama
`claude/rebelum-v12`, commits SOLO locales (sin push, PR ni fusiones). El Redmi estuvo DESCONECTADO: **nada de lo de
esta noche está medido en el móvil**.

Leyenda: **D** diseñado · **C** construido · **I** integrado (en la rama, apagado fuera del banco) · **PC** probado en el
PC · **M** pendiente de móvil.

## 1. Muestra de la calle: optimizaciones cerradas (D C I PC; M pendiente)
Detalle: `docs/v12/MUESTRA_CALLE_OAKHAVEN.md` §7.d. Precalentado de sus programas en la carga (verificado que DIBUJA la
misma variante: 1.ª entrada con caché vacía, dibujo 134 → 57 ms; carga total igual), materiales y luz reutilizados entre
entradas (15-16 → 0,1 ms y 1,1 → 0 ms), un solo cuerpo de choques DESCARTADO (no mejoraba: se vuelve a uno por caja).

## 2. Oakhaven: el barrio «Arrabal de las Carretas» [P] (D C I PC; M pendiente)
Detalle: `docs/v12/BARRIO_OAKHAVEN.md` (§2 contrato, §6 B interiores, §7 C vida y misión, §8 A exterior, §9 pulido) y
el plan `BARRIO_OAKHAVEN_PLAN.md`. Entrada: banco → «Barrio de Oakhaven (en pruebas)». Oakhaven 3D no se toca.
- **Recorrido** (6 tramos horneados con el acabado aprobado de la muestra, ≈ 128 m de bucle, con desniveles reales):
  patio de caravanas con establo → calle comercial con el horno → plaza de mercado con lonja → patio de talleres en
  rampa → sector residencial → atajo con escalones → caravanas. Cámara por zonas, sin girar.
- **Interiores visitables** (3, horneados, distintos): horno de Maela en L (obrador + zona doméstica tras la cortina),
  taller de Damián (nave + trastienda que se abre en la misión), vivienda de Odila y Nela (cocina con la galga en la
  repisa + alcoba dos escalones arriba). Puerta con destino, condición y retorno seguro; guardar dentro guarda la puerta
  de fuera; lo examinable, lo ofrecido y lo privado distinguidos (lo privado no se coge: el dueño reacciona).
- **Habitantes que trabajan** con objetos sujetos de una sola ubicación: Maela (amasar → hornear → bandeja → puesto),
  Tobías (caja del carro de caravanas → pila del patio; saco al horno), Brena (cepillo → Avena → cubo → pozo →
  abrevadero → heno). Avena [prototipo] atada, bebe y come. Hablar interrumpe y se reanuda sin perder objetos; los
  vecinos ceden el paso. Coste de la vida: ≈ 0,3 ms por fotograma en el PC.
- **Misión «Antes de que se enfríe» [P]**: carro parado por el pasador → taller → la galga en la vivienda (pista con
  función) → medir → pasador en la trastienda → reparar → cesta a Odila → Maela. Sin cuenta atrás, fuera de orden,
  guardar/cargar en cualquier paso, premio único **Éter ×2**. Sin el prólogo no empieza.
- **Conocimiento** sabe / ha oído / cree como datos; Brena cree que fue Avena hasta que se examinan sus cascos; los
  rumores solo de caravanas, caminos, precios y guardia.
- **Probado en PC**: pruebas del barrio (trazado, interiores, datos, vivo) y la **misión entera jugada con clics**
  (orden normal y con la galga primero, con «Guardar y recargar»): **0 fallos a 1600×720 y a 1280×720**.
- **Medidas PC** (1600×720, perfil bajo, 30 FPS en todos los tramos): 40-66 llamadas, 109-153 mil primitivas,
  3,4-3,8 ms sin límite; entrada 1,33 s. Interiores: 11-13 llamadas, < 7 mil primitivas.
- **Vídeos**: recorrido FINAL del barrio pulido `D:\REBELUM_diagnosticoarrio_oakhaveninalarrio_final_bajo.mp4`
  (1 min 13 s, 1280×720, perfil bajo; en el residencial el tejado de primer plano roza a Kael, que sigue visible);
  misión con interiores `D:\REBELUM_diagnostico\barrio_oakhaven\pulido_datos\video\mision_interiores.mp4`
  (4 min 51 s), rutinas `...\c\video\rutinas.mp4`, recorrido exterior (antes del pulido) `...\a\barrio_recorrido_bajo.mp4`.
  Comparaciones con la misma cámara: `...\a\comparar_*` (blockout → horneado) y `...\pulido_region\comparar_s*`.

## 3. Sunken City: la Quilla horneada (D C I PC; M pendiente; fase B sin empezar)
Detalle: `docs/v12/SUNKEN_QUILLA.md`. Interruptor del banco «Sunken: Quilla horneada». Con él apagado, Sunken queda
exactamente como antes. Cuadernas dobles, casas hechas con restos del barco, empalme de la costilla 32, la 38 sigue a
oscuras; cuadrilla de 4 obreros (estopa, tablones, fardos con la cabria) que se para al hablar. PC, bajo: 72 → 44
llamadas en la Quilla (con la cuadrilla, un poco por encima del objetivo de 45 en dos vistas: decisión del usuario).
Vídeo `D:\REBELUM_diagnostico\sunken_quilla\video\quilla_cuadrilla_bajo.mp4`; láminas en `...\sunken_quilla\laminas\`.
Fase B (paso de babor y El Ancla Seca) NO empezada: el plan la condiciona a medir antes en el Redmi.

## 4. Arboleda Mítica: la escalera de la Hospedería (D C I PC; M pendiente)
Detalle: `docs/v12/ARBOLEDA_HOSPEDERIA.md`. Sigue siendo 2D pintada. La escalera conecta con la terraza, la Hospedería
del Peregrino [P] es visitable (dormir 20, guardar dentro → terraza), «Una flor para Lumi» [P] (el dibujo de Lumi en la
pared). PC: GPU +0,14 ms en el peor sitio, texturas +5,8 MB. Vídeo `D:\REBELUM_diagnostico\arboleda_hospederia\video\tramo_hospederia.mp4`.

## 5. Diseño: actividades futuras
`docs/v12/ACTIVIDADES_FUTURAS.md`: Rastreadores, Piezas Huérfanas y Feria de los Oficios sobre el Gremio y las misiones
con pasos (inicio, lugares, personajes, conocimiento, consecuencia, recompensa). Ninguna implementada.

## 6. Revisiones y calidad
Revisiones independientes con escépticos en cada paso; la última, sobre todo lo integrado (5 enfoques): 13 hallazgos
confirmados y ARREGLADOS (aislamiento de la precarga y de las APK, misión, región, Quilla, Arboleda), cada uno con su
prueba (comprobada también al revés). **Batería completa final: 194 · 0 · 114 · 0** (`2026-11-16_052721`, partida y
datos reales sin cambios); validado `e8ed88f` (`validado/v12/20261116-055910`). `prueba_arboleda_tramo` (ventana): 0 fallos.

## 6.b APK de Auditoría (NO instalada: el Redmi está desconectado)
- `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261116-e8ed88f-local.apk`, 472,4 MB, «TODO CORRECTO»,
  versionCode **931**, commit `e8ed88f`.
- SHA-256: `6709004b8afe905719d585524e4d18560014d47f930b5f914d3b9dafd39d89df`.
- Guion para el teléfono: `docs/v12/GUION_REDMI_15_11.md`, sección «PARA EL 16/11, APK e8ed88f».

## 6.c Puntos de recuperación (etiquetas locales)
`recuperacion/v12/20261116-antes-barrio` (antes de todo esto), `-antes-fase0-barrio`, `-antes-barrio-b`, `-antes-barrio-a`,
`-antes-sunken-quilla`, `-barrio-integrado`, `-antes-pulido-barrio`, `-antes-arboleda`, `-antes-arreglos-revision`.

## 7. Decisiones para el usuario [D]
- Barrio: nombre de trabajo «Arrabal de las Carretas»; arrabal extramuros al oeste; tarde dorada (el canon de Oakhaven es
  la hora azul); premio Éter ×2; nombres y textos de Maela, Tobías, Brena, Damián, Odila, Nela y Avena; el prototipo de
  Avena; las losas al sol 2,2 veces más oscuras que la tierra (como en la muestra aprobada); la boca norte del atajo y
  de los talleres aún con mucho tejado (más arreglo exige otro horneado o tocar arquitectura).
- Sunken: si la cuadrilla se queda en el perfil bajo; nombres [P].
- Arboleda: precio 20, qué flor, la Cinta de Lumi, Yedra y Nívea [P] (estilo 3D junto a sprites anime), Dialogic.
- Pendientes de antes: Nix y el grupo de cuatro, la cinemática de Érebo, el canon del cantero y de Sunken.

## 8. Fallos abiertos (no se declaran resueltos)
- Cierre 0xC0000005 al apagar Godot tras `prueba_banco_pruebas` (diagnóstico en `MUESTRA_CALLE_OAKHAVEN.md` §8:
  recursos de render y texto retenidos por cachés estáticas; sin demostrar que sea la causa).
- Transparencias que no oscurecen en bajo/medio (sin investigar; lo nuevo no usa transparencias).
- `prueba_audio` intermitente (peor fotograma cerca del umbral de 100 ms; sin regresión medida).
