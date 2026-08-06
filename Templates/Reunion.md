<%*
const tema = await tp.system.prompt("Tema de la reunión");
const asistentes = await tp.system.prompt("Asistentes (separados por coma)", "");
await tp.file.rename(`${tp.date.now("YYYY-MM-DD")} - Reunión - ${tema}`);
-%>
---
title: "Reunión — <% tema %>"
tags: [reunion, activo]
date: <% tp.date.now("YYYY-MM-DD") %>
---

# Reunión — <% tema %>

| Campo | Valor |
|---|---|
| Fecha | <% tp.date.now("YYYY-MM-DD HH:mm") %> |
| Asistentes | <% asistentes %> |
| Tema | <% tema %> |

## Agenda

## Notas / Discusión

## Decisiones

## Accionables

- [ ] 

## Referencias

- 
