#!/usr/bin/env node
// Valida o modelo e exporta para gUFO (Turtle), sem abrir o VS Code.
// Usa o servidor MCP que vem na extensão Tonto (nemo-ufes.tonto-vscode) instalada.
//
// Uso:  node scripts/exportar_gufo.mjs [arquivo.tonto]
//       padrão: ontologia-tonto/src/ontologia-nova.tonto
// Saída: ontologia-tonto/generated/<nome da ontologia>.ttl
import { spawn } from "node:child_process";
import { readdirSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join, dirname, resolve, relative } from "node:path";
import { createInterface } from "node:readline";
import { fileURLToPath } from "node:url";

const aqui = dirname(fileURLToPath(import.meta.url));
const raiz = resolve(aqui, "..");
const workspace = join(raiz, "ontologia-tonto");
const modelo = relative(workspace, resolve(process.argv[2] ?? join(workspace, "src/ontologia-nova.tonto")));

// Acha a versão mais nova da extensão Tonto
const pastas = [join(homedir(), ".vscode/extensions"), join(homedir(), ".vscode-server/extensions")];
const servidor = pastas.filter(existsSync)
  .flatMap((p) => readdirSync(p).filter((n) => n.startsWith("nemo-ufes.tonto-vscode-")).map((n) => join(p, n)))
  .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }))
  .map((p) => join(p, "out/tonto-mcp.mjs")).filter(existsSync).pop();
if (!servidor) { console.error("Extensão Tonto não encontrada em ~/.vscode/extensions."); process.exit(1); }
console.log(`Tonto: ${servidor}`);

const proc = spawn(process.execPath, ["-r", join(aqui, "polyfill.cjs"), servidor, workspace], { stdio: ["pipe", "pipe", "inherit"] });
const espera = new Map();
createInterface({ input: proc.stdout }).on("line", (l) => {
  const m = JSON.parse(l);
  if (espera.has(m.id)) { espera.get(m.id)(m); espera.delete(m.id); }
});
let id = 0;
const chama = (method, params) => new Promise((ok) => {
  const n = ++id; espera.set(n, ok);
  proc.stdin.write(JSON.stringify({ jsonrpc: "2.0", id: n, method, params }) + "\n");
});
const texto = (r) => (r.result?.content ?? []).map((c) => c.text).join("\n") || JSON.stringify(r.error);

await chama("initialize", { protocolVersion: "2024-11-05", capabilities: {}, clientInfo: { name: "exportar_gufo", version: "1" } });
proc.stdin.write(JSON.stringify({ jsonrpc: "2.0", method: "notifications/initialized" }) + "\n");

console.log(`\n== Validação de ${modelo} ==`);
const v = await chama("tools/call", { name: "tonto_validate", arguments: { paths: [modelo] } });
console.log(texto(v));
const erro = /\berror\b/.test(texto(v));

let falhou = erro;
if (!erro) {
  console.log("== Export gUFO ==");
  const g = await chama("tools/call", { name: "tonto_gufo", arguments: { paths: [modelo], outDir: "generated" } });
  console.log(texto(g));
  falhou = g.result?.isError ?? false;
} else {
  console.log("Há erros: o export não foi feito.");
}
proc.kill();
process.exit(falhou ? 1 : 0);
