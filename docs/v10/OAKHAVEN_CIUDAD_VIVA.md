# Oakhaven, ciudad viva (V10)

Rama LOCAL `claude/rebelum-v10` (`D:\Aethelgard_v10`).
- Comprobado ejecutando, aislado, el 10/11/2026, salvo donde se indica.
- Sin validar en el Redmi.

## Oakhaven 2D (la que se juega por defecto)

**Distrito de los oficios:** tres vecinos nuevos con oficio. Son propuesta de narrativa, **pendientes de canon**.

| Vecino | Dónde | Servicio al acabar su diálogo |
|---|---|---|
| Maese Ferro | herrería, junto al yunque (70.5, 26) | forja de Kael |
| Hilda la Armera | puesto de armaduras, entrada de la Calle del Mercado (47, 25.6) | taller de armaduras de Garon |
| Mirta la Boticaria | plazuela de la Botica (33.5, 41.5) | «¿Qué necesitáis?»: ingredientes o alquimia de Lya |

**Rutinas** (`ciudades/oakhaven_vida.gd`, las tres franjas del día):
- **Ferro** trabaja en la fragua mañana, tarde y anochecer.
- **Hilda** monta el puesto por la mañana y, al anochecer, lleva piezas a su taller (paseo hasta la casilla 57, 25.6).
- **Mirta** revisa la botica y, al anochecer, busca algo por la plazuela («¿Dónde dejé las gafas? …Ah. Puestas.»).
- Las rutinas de los ocho vecinos de antes no cambian.

**Frases al pasar.** Reaccionan al mundo:
- cómo acabó el bosque (purificado o Guardián derrotado);
- si Garon va en el grupo;
- el encargo del herrero y su decisión;
- la fórmula de Mirta.

**Consecuencias que se ven:**
- la tienda de Ferro vende Hierro de la Falla si se lo entregaron;
- la botica vende el Bálsamo tras el encargo B;
- Ferro comenta las rejas nuevas de la muralla o la espada de Kael;
- Mirta da las gracias a Lya.

**Secreto:** en 2D, las tres páginas del cuaderno de Mirta.

## Oakhaven 3D (Ajustes → «en pruebas»): el distrito de los oficios

Lo hizo el especialista de gráficos (rama `claude/v10-distrito`, fusionada en `b53d091`). Su informe completo está en
`docs/memory/agents/graficos_v10_distrito.md`.

**Calle de los Oficios**, al sureste de la plaza. Es un kit de Blender, obra propia: `crear_distrito.py` da el mismo
SHA-256 en dos pasadas. Hay modelo alto y modelo ligero.
- **Herrería de Maese Ferro:** fragua con brasas, llamas, humo y chimenea; fuelle, yunque y tina. Ferro golpea el
  yunque y saltan chispas.
- **Taller de Hilda:** escudos, mostrador y maniquí con armadura.
- Dos puestos con toldos a rayas y dos casas con patio. Delante de las casas del sur, jardines cerrados.
- **Tenderete de Mirta**, delante de la botica.
- **Rincón secreto del pozo viejo:** al examinarlo sube una ráfaga de luciérnagas. Sus tres textos son de gráficos,
  **sin canon**.
- Carteles con yunque, escudo y mortero.

**Botones.** «Hablar con Maese Ferro», «Hablar con Hilda» y «Hablar con Mirta» abren el mismo diálogo que en 2D. Al
acabar, el diálogo pide el mismo servicio (`servicios.gd`). Las señales de los encargos se aplican igual que en la 2D.

**Cámara.** En la calle nueva la cámara sube de 52° a 60°.
- A 52°, las cuatro casas del sur (tejados de 7,4 a 8,3 m) tapan a Kael.
- Se probó hacerlas transparentes y volver a 52°, y quedaba peor: medio plano de tejado translúcido sobre Kael.
  Capturas en `D:\REBELUM_diagnostico\v10\distrito\camara52_descartada`. **Se quedan los 60°.**

**Presupuesto** (montaje en el PC, sin ventana; **no son medidas del Redmi**):

| Perfil | Triángulos (tope) | Mallas | Choques |
|---|---|---|---|
| alto | 15 184 (20 000) | 23 | 40 |
| bajo (kit ligero) | 8 799 (10 000) | 22 | 39 |

Orientación en el PC, no es una medida: la vista general pasa de 323 a 353 llamadas de dibujo.

**Antes y después:** `D:\REBELUM_diagnostico\v10\distrito\comparacion_antes_despues_alto.png` y `…_bajo.png`.

## Estado

| Parte | Estado |
|---|---|
| Vecinos, servicios, rutinas y frases en 2D | implementado y probado (`prueba_oakhaven_v10`, `prueba_oakhaven_rutinas`, `prueba_oakhaven_vida`, `prueba_oakhaven`) |
| Distrito 3D: montaje, choques, botones, diálogo → servicio, pozo | implementado y probado (`prueba_distrito_oakhaven`, alto y bajo) |
| Rutinas de los vecinos en 3D | **parcial**: Ferro trabaja (golpea el yunque); Hilda y Mirta están quietas en su puesto |
| Sonido del martillo, la fragua y el pozo | **pendiente** (sonido; el momento del golpe está marcado en `distrito.gd`, `_martillo`) |
| Pasos en la calle nueva | suenan a «hierba»: pendiente |
| Lya y Garon respetan los jardines al seguir a Kael | sin comprobar |
| FPS en el Redmi | **pendiente de validación manual** (perfil bajo) |
