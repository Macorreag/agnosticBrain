<%*
// Toma la fecha del archivo si existe; si no, usa hoy.
const isoMatch = tp.file.title.match(/^(\d{4}-\d{2}-\d{2})/);
const dmyMatch = tp.file.title.match(/^(\d{2})-(\d{2})-(\d{4})/);
const ref = isoMatch ? isoMatch[1] : dmyMatch ? `${dmyMatch[3]}-${dmyMatch[2]}-${dmyMatch[1]}` : tp.date.now("YYYY-MM-DD");
const fechaTitulo = tp.date.now("DD-MM-YYYY", 0, ref, "YYYY-MM-DD");
const carpetaDaily = "raw/Daily Notes/";
const sinMd = (file) => file.path.replace(/\.md$/, "");
const dailyFiles = () => app.vault.getMarkdownFiles()
  .filter((file) => file.path.startsWith(carpetaDaily) && !file.basename.toLowerCase().includes("template"));
const fechaDeDaily = (file) => {
  const match = file.basename.match(/^(\d{2})-(\d{2})-(\d{4})(?:\b| - )/);
  if (!match) return null;
  const key = `${match[3]}-${match[2]}-${match[1]}`;
  return {
    dmy: `${match[1]}-${match[2]}-${match[3]}`,
    key,
    time: window.moment(key, "YYYY-MM-DD", true).valueOf()
  };
};
const buscarDaily = (fecha) => {
  return dailyFiles()
    .find((file) => file.basename === fecha || file.basename.startsWith(`${fecha} - `));
};
const buscarUltimaDailyAntes = (refKey) => {
  const refTime = window.moment(refKey, "YYYY-MM-DD", true).valueOf();
  return dailyFiles()
    .map((file) => ({ file, fecha: fechaDeDaily(file) }))
    .filter(({ fecha }) => fecha && fecha.time < refTime)
    .sort((a, b) => b.fecha.time - a.fecha.time)[0] || null;
};
const currentFile = app.workspace.getActiveFile();
const dailyExistente = dailyFiles()
  .find((file) => file.path !== currentFile?.path && (file.basename === fechaTitulo || file.basename.startsWith(`${fechaTitulo} - `)));

if (dailyExistente && currentFile) {
  new Notice(`Ya existe una nota diaria para ${fechaTitulo}. Abriendo la existente.`);
  await app.workspace.getLeaf(false).openFile(dailyExistente);
  await app.vault.trash(currentFile, true);
  return;
}

const tituloActual = tp.file.title.replace(/^(\d{4}-\d{2}-\d{2}|\d{2}-\d{2}-\d{4})( - )?/, "").trim();
const titulo = await tp.system.prompt("Título", tituloActual || "");
if (currentFile?.basename !== fechaTitulo) await tp.file.rename(fechaTitulo);

const ayerDmy = tp.date.now("DD-MM-YYYY", -1, ref, "YYYY-MM-DD");
const mananaDmy = tp.date.now("DD-MM-YYYY", 1, ref, "YYYY-MM-DD");
const dailyAyer = buscarDaily(ayerDmy);
const dailyManana = buscarDaily(mananaDmy);
const linkAyer = dailyAyer ? `[[${sinMd(dailyAyer)}|${ayerDmy}]]` : `[[${carpetaDaily}${ayerDmy}|${ayerDmy}]]`;
const linkManana = dailyManana ? `[[${sinMd(dailyManana)}|${mananaDmy}]]` : `[[${carpetaDaily}${mananaDmy}|${mananaDmy}]]`;
const ultimaDaily = buscarUltimaDailyAntes(ref);
const tituloUltimaDaily = ultimaDaily ? `## Ultima nota - ${ultimaDaily.fecha.dmy}` : "## Ultima nota";
const embedUltimaDaily = ultimaDaily ? `![[${sinMd(ultimaDaily.file)}#HOY]]` : "";
setTimeout(() => {
  const editor = app.workspace.activeLeaf?.view?.editor;
  if (!editor) return;

  const lineas = editor.getValue().split("\n");
  const hoy = lineas.findIndex((linea) => linea.trim() === "## HOY");
  const tarea = lineas.findIndex((linea, index) => index > hoy && linea.trim().startsWith("- [ ]"));
  if (tarea < 0) return;

  editor.focus();
  editor.setCursor({ line: tarea, ch: lineas[tarea].length });
}, 300);
-%>
# <% titulo || fechaTitulo %>

<< <% linkAyer %> | <% linkManana %> >>

<% tituloUltimaDaily %>

<% embedUltimaDaily %>

## HOY

- [ ] 

### Blockers

### Notes
