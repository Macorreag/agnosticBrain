<%*
const ref = await tp.system.prompt("Referencia (ticket, caso, o dejar vacío)", "");
const titulo = await tp.system.prompt("Título corto");
const prioridad = await tp.system.suggester(["alta","media","baja"], ["alta","media","baja"], false, "Prioridad / severidad");
const nombreArchivo = ref ? `${ref} - ${titulo}` : titulo;
await tp.file.rename(nombreArchivo);
-%>
---
title: "<% ref ? `${ref} — ${titulo}` : titulo %>"
tags: [analisis, wip]
date: <% tp.date.now("YYYY-MM-DD") %>
---

# <% ref ? `${ref} — ${titulo}` : titulo %>

> [!abstract] Resumen
> _(una línea: qué pasó o qué se encontró)_

| Campo | Valor |
|---|---|
| Referencia | <% ref %> |
| Prioridad / severidad | <% prioridad %> |
| Fecha | <% tp.date.now("YYYY-MM-DD HH:mm") %> |
| Elemento(s) afectado(s) o involucrado(s) |  |

## Qué pasó / qué se encontró

## Análisis

## Detalle técnico (queries, cálculos, comandos — si aplica)

```

```

## Conclusión / solución

## Accionables

- [ ] 

## Referencias

- 
