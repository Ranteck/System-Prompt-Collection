---
description: Resumen diario de commits para Jira (no técnico)
---

## Contexto

- Fecha actual: !`date +"%d/%m/%Y"`
- Rama actual: !`git branch --show-current`
- Commits de hoy (todas las ramas): !`git log --since="midnight" --format="--- %h por %an ---%n%s%n%b" --all`
- Estadísticas de cambios: !`git log --since="midnight" --stat --format="--- %h ---" --all`

## Tu tarea

Con los commits del día listados arriba, genera un resumen para poner en Jira.

### Formato de salida

```
[fecha en formato d/mm]

- [descripción clara y no técnica de cada cambio o grupo de cambios]
- [otro cambio...]
```

### Reglas

- Agrupa commits relacionados en un solo bullet point
- Usa lenguaje claro y NO técnico, orientado a lo que se logró
- Enfócate en el "qué se mejoró/arregló/agregó", no en el "cómo"
- No menciones nombres de archivos, variables, funciones ni parámetros técnicos
- No uses jerga de programación (refactor, merge, fix typo, etc.)
- Sé conciso pero descriptivo, como si le explicaras a un project manager
- Si un commit es trivial (typo, formato), omítelo o agrúpalo
- Si no hay commits del día, indica que no hubo actividad registrada

### Ejemplo de salida

```
9/02

- Ajuste de velocidades y tolerancias de navegación para que el robot se mueva de forma
  más estable y llegue a los waypoints sin oscilaciones
- Ampliación del área de detección de obstáculos local para mejorar la evasión
- Simplificación de la configuración: se eliminaron archivos duplicados y se centralizó
  todo en un único lugar
```

No uses ninguna herramienta. Solo genera el resumen como texto.
