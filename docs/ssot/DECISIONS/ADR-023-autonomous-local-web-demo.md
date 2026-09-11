# ADR-023 — Demo Flutter Web autónoma para presentaciones

- **Estado:** aceptada
- **Fecha:** 2026-09-10

## Contexto

Se necesita presentar el flujo completo del verificador sin depender de un
usuario DDR001, red, API o base SQL y sin convertir el backend histórico en un
servidor operativo.

## Decisión

- Incorporar una entrada Flutter Web separada, `main_web_demo.dart`, que
  reutiliza branding, motor metrológico y generador de caudal, pero no el
  arranque productivo Android.
- Limitarla a SIMULACIÓN Q1/Q2: preflujo, inicio/final controlados por operador,
  captura manual, resultado y reporte.
- Persistir una representación JSON propia sólo en almacenamiento del navegador
  y ofrecer borrado total con confirmación. No abrir Drift ni consumir API/SQL.
- Mostrar indicadores verdes de ESP32 y control remoto como elementos
  demostrativos rotulados, sin fabricar una conexión BLE.
- Usar una carátula demo generada por IA como ayuda visual: recortes de
  totalizador/dial y vista completa ampliable. Los valores capturados, no la
  imagen, alimentan la metrología.

## Consecuencias

- La demo puede ejecutarse y distribuirse como archivos Web estáticos.
- El historial depende del perfil/origen del navegador y no se sincroniza.
- Android conserva Drift, auth, sync y todas sus fuentes productivas; la demo
  no sustituye LECTURA VISUAL ni habilita hardware.
