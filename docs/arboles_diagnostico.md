# Árboles de Pastos Verdes — diagnóstico y candidatos (Fase 2.1)

Capturas: `docs/capturas/arboles/` (misma escena, luz y terreno; cámara de juego a 12, 20 y 34 m; perfiles
bajo, medio y alto). Escena de comparación: `aethelgard/prototipos/arboles_prueba.tscn` (no cambia el mapa).

## 1. Diagnóstico del árbol actual (arce de Meshy «3D»)

| Problema | ¿Modelo o render? | Detalle |
|---|---|---|
| Copa como una bola uniforme | **Modelo** | 36–44 planos grandes en una sola esfera: sin lóbulos, la silueta no tiene forma de árbol. |
| Textura «ruidosa» y sin forma de hoja | **Modelo** | Las matas se recortaron de un render fotográfico: a 20 m las hojas se mezclan en manchas. |
| Mitad naranja / mitad verde | **Modelo** | El arce de Meshy es otoñal; el corte entre colores es brusco y no encaja con la pradera luminosa. |
| Interior plano, sin profundidad | **Render** (Compatibility no tiene oclusión ambiental) | Se arregla pintando la sombra interior en el color de vértice. |
| Bordes de hojas dentados | **Render** | Alfa recortado sin MSAA en bajo y medio. Las hojas pintadas con bordes más limpios lo disimulan. |
| A 34 m | **Ambos** | La mancha naranja domina; las hojas no se leen. |
| Tronco | Correcto | Tronco real del arce (1 592 triángulos), proporcionado. |

**Conclusión:** el problema principal es el **diseño de la copa** (modelo), no el renderizador.

## 2. Alternativas estudiadas
| Alternativa | Calidad | Coste móvil | Control artístico | Esfuerzo | Licencia |
|---|---|---|---|---|---|
| 1. Árboles hechos a medida (tronco + copa de lóbulos con matas pintadas) | Buena y luminosa | Muy bajo (~600 triángulos) | **Total** (colores, forma, viento) | Bajo, ya hecho | Propio |
| 2. Árboles de alta calidad en Blender + versiones optimizadas | La mejor posible | Bajo, si se hacen bien | Total | Alto (requiere Blender y tiempo de arte) | Propio |
| 3. Bibliotecas (Quaternius, EmacE Art...) | Buena, estilo genérico | Bajo | Limitado | Bajo | Quaternius es CC0. **EmacE Art: comprobar la licencia del paquete concreto.** Hay que descargarlos (pendiente de tu permiso). |

No se usan modelos de Meshy con millones de triángulos: su reducción automática destruye la silueta (medido:
el abedul no baja de 375 000 triángulos).

## 3. Candidatos (generador `prototipos/arbol_estilizado.gd`, textura `modelos/hojas/matas.png`)
| Candidato | Descripción | Triángulos |
|---|---|---|
| **Pradera** (frondoso) | Tronco robusto con raíz, 4 ramas, copa ancha de 6 lóbulos con 96 matas pintadas y verde-amarillo luminoso | ~600 |
| **Abedul** (copa ligera) | Tronco blanco esbelto con marcas, copa alta y aireada de 70 matas con hojas pequeñas | ~500 |
| **Mágico** (ornamental) | Tronco lila que se retuerce, copa de flores lila y rosa y motas de luz (14 partículas) | ~650 |

Técnica: doble cara, alfa recortado, normales de volumen, sombreado interior pintado, luz que atraviesa las hojas
y viento en el sombreador.

## 4. Coste medido (PC, tope de 30 FPS, bosque completo del mapa con cada opción)
| Bosque | Dibujos | Triángulos | Mediana | Tirones |
|---|---|---|---|---|
| Arce actual (medio) | 150 | 345k | 33,3 ms | 0 % |
| Pradera (medio) | 153 | 330k | 33,3 ms | 0 % |
| Mezcla de los 3 (medio, 20 m / 34 m) | 152 / 140 | 329k / 304k | 33,3 ms | 0 % |
| Mezcla de los 3 (bajo / alto) | 78 / 164 | 145k / 352k | 33,3 / 16,7 ms | 0 / 0,2 % |

**Redmi: pendiente de medir** (botón «ARB» del APK de prueba).

## 5. Pendiente
- Que elijas los candidatos. No se reparten por el mapa hasta entonces.
- Afinar el que elijas: variedad de formas, segunda textura de hojas, versión simplificada para lejos.
- Opcional: probar árboles de Quaternius, solo con tu permiso para descargarlos.
