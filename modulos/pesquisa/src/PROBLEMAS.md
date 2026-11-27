# Problemas de modelagem e implementação — módulo de pesquisa

Modelo: `pesquisa.tonto`, também presente nas seções 4 e 5 de
`ontologia-tonto/src/ontologia-nova.tonto`. Revisado em 2026-11-26.

As duas categorias de problema:
- **Modelagem**: limitações do modelo, que devem ser declaradas no texto.
- **Implementação**: regras que o script precisa seguir.

## Decisões já aplicadas

| Decisão | Motivo |
|---|---|
| Sem `Publicacao`: `Estudo` tem `nome` e `pubmedId` | Na LongevityMap, estudo e artigo são 1 para 1 (270 PMIDs) |
| `RecursoInformacional` = `ConjuntoDeDados` + `Ontologia` | Só bases e ontologias são "mantidas" por organizações |
| LongevityMap, GenAge etc. são **instâncias** de `ConjuntoDeDados` | Sem subkinds por tipo de base. O que cada base fornece aparece pelo relator que a usa |
| GenAge sem `Estudo` | O CSV não tem referência por gene, então a fonte citada é a própria GenAge (Tacutu et al. 2018, NAR 46(D1):D1083) |
| `Estudo observa [0..*] Populacao` | Estudos de laboratório (do GAF) não têm população |
| `Estudo` = artigo, `pubmedId [1]` | Todo registro da LongevityMap e do GWAS tem PMID. No GWAS, os vários GCST do mesmo artigo viram um Estudo; o GCST fica no `idNaFonte` da associação |
| `Populacao` é `kind`, não `collective` | Sem `Pessoa` no escopo, um collective ficaria sem membros. A população é identificada pelo rótulo do estudo |

## Problemas de modelagem (declarar no texto)

| # | Problema |
|---|---|
| P1 | **População como `kind`**. Conceitualmente é um grupo de pessoas (collective), mas sem `Pessoa` no escopo virou um kind identificado pelo rótulo do estudo |
| P2 | **Estudo como `kind`**. Na UFO, um estudo é evento (perdurant). É a mesma simplificação usada nos processos GO |

## Notas de implementação (script e consultas)

- **Instâncias fora do diagrama** (LongevityMap, HAGR, GO...): o Tonto não desenha
  instâncias. Mostrar no Protégé ou numa tabela no texto.
- **`relata` repete os relatores**: derivar `ConjuntoDeDados relata Estudo` dos
  relatores (`obtidaEm`, `baseadaEm`), sem preencher à parte.
- **Versões**: ficam em `VERSOES.txt`. Só entram no modelo (`versao`) se cobrarem.

### Populações (LongevityMap: 81 rótulos de texto livre)

| Tipo de problema | Exemplo | Regra |
|---|---|---|
| Erro de digitação | `Italian (Nothern and Central)` | normalizar por tabela |
| Rótulo composto | `Spanish and Italian` | **separar** em populações. `observadaEm` agora é `[1..*]` |
| Granularidade variável | `Italian`, `Italian (Sicily)` | sem hierarquia por ora; tratar como populações diferentes |
| Espaço sobrando | `German ` | `strip()` |

**Opcional:** alinhar os rótulos à **HANCESTRO** (ontologia de ancestralidade usada pelo
GWAS Catalog). Ela não está na proposta e é baixada com `--opcionais`.

### Populações do GWAS

Vêm de `gwas-catalog-ancestry.tsv` (estágio `initial`): ancestralidade ampla
(European, East Asian...) + país de recrutamento. Não são rótulos livres como na
LongevityMap. Comparar as populações das duas bases exige uma tabela de equivalência
(ou a HANCESTRO, opcional).

### Estudos

- `nome` = título via NCBI E-utilities `esummary`, em lotes, até 3 requisições/s sem
  chave. Se a busca falhar, usar `"PMID:<id>"`.
- Só referências `PMID:` do GAF viram `Estudo`. As outras (`GO_REF`, `Reactome`, `DOI`)
  ficam no atributo `AnotacaoFuncional.referencia`.

### Fontes e vocabulários

- `usaVocabulario`: instanciar só os usos reais.
  - **Sim:** GAF → GO; GWAS → EFO, se o GWAS entrar.
  - **Não:** HPA → CL. O mapeamento é nosso.
- `mantidoPor`:
  - HAGR → LongevityMap, GenAge;
  - GO Consortium → GO, GAF;
  - HGNC → HGNC;
  - OBO Foundry → CL, SO;
  - Human Protein Atlas → HPA.
