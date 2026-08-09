# ADR-004 — Regla de decisión con incertidumbre
- **Estado:** aceptada
- **Fecha:** 2026-08-08
- **Contexto:** declarar conformidad solo con `|E|≤MPE` ignora la incertidumbre cerca del límite.
- **Decisión:** banda de guarda: APRUEBA si `|E|+U≤MPE`; RECHAZA si `|E|-U>MPE`; en otro caso NO CONCLUYENTE y debe repetirse la muestra. Repetibilidad para n≥3: `s≤MPE/3`.
- **Consecuencias:** se reduce el riesgo de falsos aprobados. El reporte siempre muestra E, U, MPE y regla aplicada. Cambiar esta regla requiere nueva ADR y tests.
