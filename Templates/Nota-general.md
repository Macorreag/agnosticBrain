<%*
const titulo = await tp.system.prompt("Título de la nota");
const tipo = await tp.system.suggester(
  ["idea","doc","reunion","tarea","analisis","guia","referencia","arquitectura","proyecto","indice"],
  ["idea","doc","reunion","tarea","analisis","guia","referencia","arquitectura","proyecto","indice"],
  false, "Tipo (tag)");
const area = await tp.system.suggester(
  ["trabajo","personal","ia"],
  ["trabajo","personal","ia"],
  false, "Área");
const estado = await tp.system.suggester(
  ["activo","wip","pendiente","completado","archivado"],
  ["activo","wip","pendiente","completado","archivado"],
  false, "Estado");
await tp.file.rename(titulo);
-%>
---
title: "<% titulo %>"
tags: [<% tipo %>, <% area %>, <% estado %>]
date: <% tp.date.now("YYYY-MM-DD") %>
---

# <% titulo %>

## 

## Referencias

- 
