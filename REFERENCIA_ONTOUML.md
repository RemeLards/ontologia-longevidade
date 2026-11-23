# Referência OntoUML — o que liga com o quê

Resumo para consulta rápida durante a modelagem. Fontes conferidas em 2026-11-23.

## Onde ler

| O quê | Link |
|---|---|
| **Especificação OntoUML** (principal) | https://ontouml.readthedocs.io/en/latest/ |
| Classes — sortais (kind, subkind, phase, role, collective, quantity, relator) | https://ontouml.readthedocs.io/en/latest/classes/sortals/kind/index.html (troque `kind` pelo nome) |
| Classes — não sortais (category, mixin, roleMixin, phaseMixin) | https://ontouml.readthedocs.io/en/latest/classes/nonsortals/category/index.html |
| Classes — aspectos (mode, quality) | https://ontouml.readthedocs.io/en/latest/classes/aspects/mode/index.html |
| Relações — visão geral | https://ontouml.readthedocs.io/en/latest/relationships/intro.html |
| Relações — material, mediation, characterization, derivation, formal | https://ontouml.readthedocs.io/en/latest/relationships/mediation/index.html (troque o nome) |
| Parte-todo — componentOf, memberOf, subCollectionOf, subQuantityOf | https://ontouml.readthedocs.io/en/latest/relationships/aggregations/intro.html |
| **Anti-padrões** (erros comuns: RelOver, FreeRole, UndefPhase...) | https://ontouml.readthedocs.io/en/latest/anti-patterns/index.html |
| **Padrões** (relator, partição de phases, roleMixin) | https://ontouml.readthedocs.io/en/latest/patterns/index.html |
| Portal da comunidade e publicações | https://ontouml.org/ · https://ontouml.org/publications/ |
| gUFO (o OWL gerado pelo Tonto) | https://nemo-ufes.github.io/gufo/ |
| Tonto (linguagem textual) | https://matheuslenke.github.io/tonto-docs/docs/intro |

> A extensão Tonto 0.9.3 instalada aqui é mais nova que a doc do Tonto: a sintaxe
> (`ontology` minúsculo, `use`, `(const)`) e as regras que ela valida estão no próprio
> `~/.vscode/extensions/nemo-ufes.tonto-vscode-0.9.3/out/language-server.cjs`
> (busque por `SIGNATURES`). O painel *Problems* + lâmpada (quick fix) explica cada regra.

---

## 1. Especialização (`specializes`) — quem pode ser filho de quem

Regra-mãe: **todo sortal tem exatamente um provedor de identidade** (kind, collective,
quantity, relator, mode, quality) acima dele. Por isso:

| Estereótipo | Pode especializar | Observações |
|---|---|---|
| **kind** | category, mixin | **Kind NÃO especializa kind** (seriam duas identidades) |
| collective, quantity, relator | category, mixin | também são provedores de identidade |
| **subkind** | kind, subkind, collective, quantity, relator, mode, quality, category, mixin | rígido; nada anti-rígido acima |
| **phase** | qualquer sortal, phase, phaseMixin, mixin, category | anti-rígido; **obrigatório genset disjoint complete** com as phases irmãs; não especializa role |
| **role** | qualquer sortal, role, roleMixin, mixin, category, phaseMixin | anti-rígido; **precisa de dependência relacional** (mediation, material, componentOf, memberOf...) com mínimo ≥ 1 |
| category | category, mixin | rígido, abstrato, agrupa kinds diferentes |
| mixin | mixin, category | semi-rígido |
| roleMixin / phaseMixin | mixin, category, (roleMixin / phaseMixin) | anti-rígidos, abstratos; agrupam roles/phases de kinds diferentes |
| mode, quality | category, mixin | precisam de characterization com o portador (multiplicidade 1) |

Rigidez em uma linha: **rígido** (kind, subkind, category) = é sempre; **anti-rígido**
(phase, role) = pode deixar de ser; um anti-rígido nunca fica acima de um rígido.

---

## 2. Relações — "kind pode se ligar com kind?"

**Sim, por relação; não por especialização.** Duas classes de kinds diferentes se ligam
por uma relação estereotipada. Qual estereótipo depende da natureza dos dois lados:

| Relação | De → Para | Regras principais |
|---|---|---|
| **@mediation** | relator → qualquer endurant (kind, subkind, role, collective...) | mínimo **≥ 1** no lado mediado; o relator media **≥ 2** indivíduos no total; extremidade `(const)` |
| **@material** | endurant ↔ endurant (ex.: kind ↔ kind) | deve ser **derivada de um relator** (relação "derivation") |
| @derivation | relator → relação material | liga o relator à material que ele justifica |
| **@characterization** | mode/quality → portador | portador com multiplicidade exatamente 1 |
| @externalDependence | extrinsicMode → endurant | |
| **@componentOf** | functional complex → functional complex | parte-todo funcional (kind/subkind comuns são functional complexes) |
| **@memberOf** | membro → **collective** | o todo é collective |
| @subCollectionOf | collective → collective | |
| @subQuantityOf | quantity → quantity | |
| @formal / @comparative | qualquer ↔ qualquer | baseada em qualidades (ex.: "mais velho que"); 0..* livre |
| @participation | objeto → evento | para eventos/processos |
| @instantiation | qualquer → `type` | multinível (powertypes) |

Resumo prático:
- **kind ↔ kind "mundo real"** (pessoa trabalha em empresa): crie um **relator** (Emprego) e use **@mediation**; se quiser a linha direta, ela é **@material** derivada do relator.
- **kind é parte de kind** (motor de carro): **@componentOf**.
- **coisa é membro de grupo**: **@memberOf** com um **collective**.
- **relação sem estereótipo**: o OntoUML não define o significado dela; evite no modelo final.

---

## 3. Como isso se aplica ao nosso modelo (`ontologia-tonto/src/ontologia.tonto`)

| Elemento | Situação |
|---|---|
| `Gene`, `Variante` subkind de `RegiaoGenomica` (kind) | ✔ correto |
| `TipoCelular` subkind de `Celula` (kind) | ✔ correto |
| `FonteDeDados` kind + 4 subkinds em genset disjoint complete | ✔ correto |
| Relatores com `@mediation` mínimo 1 e `(const)` | ✔ correto |
| `EvidenciaEnvelhecimento` media Gene + CatalogoDeGenes (2 entidades) | ✔ cumpre "≥ 2" |
| `PopulacaoEstudada` role de `Populacao` (collective), mediada pelo relator | ✔ dependência relacional ok |
| `@componentOf Celula <>-- RegiaoGenomica` | ✔ ambos functional complexes |
| **Relações sem estereótipo** (`localizadaEm`, `mantidaPor`, `registradaEm`, `anotadaEm`, `realiza`, `classificadaComo`, `*DefinidoEm`, `avaliaVariante`) | ⚠ **pendente**: decidir estereótipo — candidatas a `@material` (com relator) ou relações de domínio documentadas como simplificação |
