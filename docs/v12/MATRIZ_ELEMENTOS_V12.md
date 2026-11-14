# Matriz por elemento — encargo coordinador (estado del 14/11, 03:45)

**Estados:**
- **V** = verificado (con evidencia en el PC salvo que la columna diga Android);
- **P** = parcial;
- **—** = pendiente o no aplica;
- **B** = bloqueado.

| Elemento | Diseño | Modelo | Rig | Animación | Integración | Combate / equipo | Guardado | PC | Android |
|---|---|---|---|---|---|---|---|---|---|
| Orbe experimental de Érebo | V | — | — | V (evento «orbe_fuera») | V (APAGADO, Auditoría) | V (mismo resultado) | — | V (7 casos ×2, batería) | — (APK `e318629`) |
| Solo Lya invoca | V | — | — | — | V (por defecto) | V | — (las partidas no guardan la invocación por héroe) | V | — |
| Magia Agua v12 | V | — | — | V | V (APAGADA, Auditoría) | V (mismo daño, golpe y azar) | — | V | — |
| Nix: cuerpo desde el FBX | V (canon fijado) | V (11.968 tri.) | V (48 huesos, mechones) | P (23 clips; proporciones por reajustar) | V (APAGADO, `nix_fbx`) | P (combate con `nix_fbx`: 2 comprobaciones del modelo antiguo) | — | V (`prueba_nix_fbx` 35/35) | — |
| Nix: vestuario canónico | V (canon) | P (especialista activo) | — | — | — | — | — | — | — |
| Capa de Garon articulada | V | V (misma imagen) | V (21 huesos) | V (procedural) | V (APAGADA, Auditoría) | V (anclaje, colisiones con armas) | — | V (`prueba_capa_garon` 77/77) | — |
| Garon v2/v3: pasos dobles | — | — | — | V (usa su clip de correr) | V (por defecto, `80ac41a`) | V | — | V | — |
| Kael: Ataque rúnico (24) | **B** (falta el catálogo y el PDF de Kael) | — | — | — | — | — | — | — | — |
| Garon: Esgrima (18) y Compás | P (existe tras `esgrima`, apagado; el catálogo falta) | — | — | — | P | — | — | — | — |
| Lya: Magia blanca (18) e invocaciones (6) | P (existe tras su interruptor, apagado; el catálogo falta) | — | — | — | P | — | — | — | — |
| Nix: Magia negra (24) y Eclipse | P (escuelas existentes, apagadas; la lista completa del PDF está en `RESUMEN_PDFS_NIX_ENEMIGOS.md`) | — | — | — | P | — | — | — | — |
| `meshy_e01` Custodio de Porcelana | V (paquete) | P | P | P | — (especialista activo) | — | — | — | — |
| `meshy_e02`…`e04` | V (paquete) | — (FBX sin rig) | — | — | — | — | — | — | — |
| `common_e01`…`e10` | V (bestiario V12) | P (Peón y Velador del bestiario v12) | P | P | P (`enemigos_v12`, apagado) | P | — | P | — |
| 32 conjuntos equipables | **B** (falta el PDF del arsenal y el catálogo) | — | — | — | — | — | — | — | — |
| Oakhaven jugable (gremio, Diario, caravana, cerradura) | P | — | — | — | — (especialista activo) | — | — | — | — |
| Protagonistas v2/v3 de pie | — | — | — | V | V | — | — | V | V (v694; repetir mañana) |
| NPC de Oakhaven sin bloquear | — | — | — | — | V | — | — | V | — (cortada; mañana) |
| Gran Bosque: mipmaps y matas | — | — | — | — | V (apagados) | — | — | V | V (v694: ninguno llega a 30) |

**Documentos de cada elemento:**
- `EREBO_ORBE_V12.md`, `MAGIA_AGUA_V12.md`, `NIX_PILOTO_FBX.md` y `CAPA_GARON_V12.md`;
- `encargos/FASES_ENCARGO_COORDINADOR.md`;
- `GUION_REDMI_14_11.md`.

Las celdas «Android» se rellenan solo con pruebas en el Redmi. Una medida del PC nunca se cuenta como Android.
