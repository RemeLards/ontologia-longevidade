# Avaliação do modelo

Modelo avaliado: `ontologia-tonto/src/ontologia-nova.tonto` (ontologia
`longevidadehumana`), em 2026-11-26.

Documentos relacionados:

| Documento | Conteúdo |
|---|---|
| `Longevidade___Ontologia.pdf` | Proposta: escopo, fontes e QCs |
| `FONTES.md` | Fontes, downloads e **referências do trabalho** |
| `ontologia-tonto/src/PROBLEMAS_JUNCAO.md` | Problemas de modelagem (M1–M3) e notas de implementação |
| `modulos/pesquisa/src/PROBLEMAS.md` | Populações, estudos e vocabulários |
| `modulos/biologia/src/FONTES_FORA_DA_PROPOSTA.md` | GAF, HPA e ECO |
| `REFERENCIA_ONTOUML.md` | Regras do OntoUML |

A avaliação anterior, do `ontologia.tonto` antigo e da `proposta-ontouml/`, está no
histórico do git (commit `f8469b4`).

---

## 1. Resumo

O modelo cobre tudo o que a proposta promete: genes, variantes, associações com
longevidade, processos biológicos, tipos celulares e a **fonte de cada registro**.
Todas as QCs têm caminho no modelo, e as decisões foram conferidas contra os dados
reais.

**O que falta:** o modelo já valida no Tonto e exporta para gUFO (seção 6). Ainda não
existem o script de instanciação e as consultas SPARQL (seção 5).

## 2. Estrutura

| Parte | Elementos |
|---|---|
| Biologia | `category ElementoGenomico` → kinds `Gene`, `Variante`; kinds `ProcessoBiologico`, `Celula` |
| Proveniência | `Organizacao`; `category RecursoInformacional` → kinds `ConjuntoDeDados`, `Ontologia`; `Estudo`; `Populacao` |
| Fatos (relatores) | `AssociacaoLongevidade` (LongevityMap + GWAS), `EvidenciaEnvelhecimento` (GenAge), `AnotacaoFuncional` (GAF), `ExpressaoGenica` (HPA) |
| Enums | `Significancia`, `MotivoGenAge` |
| Relações comuns | `localizadaEm`, `subprocessoDe`, `ocorreEm`, `mantidoPor`, `usaVocabulario`, `observa`, `relata` |
| Dependência histórica | `baseadaEm` (anotação → estudo) |

**Regras seguidas em todo o modelo:**
- todo relator media a base que afirma o fato;
- não há `@material`;
- termos GO e CL entram como instância ou atributo, não como classe.

## 3. O que está bom

| Ponto | Por quê |
|---|---|
| Fonte de cada registro | Todo relator tem `@mediation [1]` para o `ConjuntoDeDados`. Cumpre o escopo da proposta e dá a base da QC5 |
| `Gene` e `Variante` como kinds + category | Identidades diferentes, e o relator aponta para "gene ou variante" sem subkinds artificiais |
| Relatores justificados | Cada um tem atributos próprios (significância, motivo, evidência, nCPM) e pode se repetir para o mesmo par de entidades |
| Hierarquia da GO (`subprocessoDe`) | Sem ela a QC3 perde metade dos genes (217 contra 475 em "DNA repair") |
| Opcional só quando o domínio permite | Falta de dado de uma base é tratada no script (normaliza, deriva ou descarta), não no modelo. Sobram como opcionais só `rsId`, `tipoSO`, `pValor`, `localizadaEm`, `ocorreEm` e `baseadaEm` |
| QC4 com dois caminhos | O curado (GO + CL, dentro da proposta) e o por expressão (HPA) |
| Cardinalidades | Conferidas contra os dados: `referencia [1]`, `baseadaEm [0..1]`, `avaliaElemento [1..*]`... |

## 4. Cobertura das questões de competência

| QC | Caminho no modelo | Fontes | Situação |
|---|---|---|---|
| QC1 genes e variantes associados | `AssociacaoLongevidade —avaliaElemento→ Gene/Variante`, filtrando `significancia = Significativa` (e `trait`; `pValor` no GWAS) | LongevityMap, GWAS, SO (CONTEXT do GWAS; VEP na LongevityMap) | ✔ |
| QC2 LongevityMap ∩ GenAge | Gene com `AssociacaoLongevidade` **e** `EvidenciaEnvelhecimento` (gene fora da GenAge não tem evidência) | LongevityMap, GenAge, HGNC | ✔ 125 genes |
| QC3 processos GO | `Gene ← AnotacaoFuncional → ProcessoBiologico`, subindo por `subprocessoDe*` | GO, GAF | ✔ 122/125 genes anotados |
| QC4 tipos celulares | (a) `AnotacaoFuncional —ocorreEm→ Celula`; (b) `Gene ← ExpressaoGenica → Celula` | CL + GAF; HPA | ✔ (a) parcial: 46/125; (b) amplo |
| QC5 resultados compartilhados | Mesmo gene, variante ou estudo em relatores de bases diferentes (`registradaEm`, `curadaPor`, `anotadaEm`, `medidaEm`) | todas | ✔ LongevityMap × GWAS: 29 rsIDs, 61 genes, 7 PMIDs |

## 5. O que falta, em ordem

| # | Tarefa | Situação |
|---|---|---|
| 1 | **Validar na extensão** (painel *Problems*) até zerar os erros | **feito**: 0 erros, 0 warnings, 1 hint aceito (seção 6) |
| 2 | **GWAS**: entra filtrado para longevidade, com `trait`, `pValor` e `observadaEm [1..*]`; `Estudo` = artigo (PMID) | **feito** (em avaliação) |
| 3 | Rodar `bash baixar_dados.sh -f` para registrar as versões | **feito** (2026-11-26, 1,2 GB) |
| 4 | Tabelas manuais: HPA → CL (155 tipos) e normalização de populações (81 rótulos) | pendente |
| 5 | Exportar gUFO (`Tonto: Export to gUFO...`) e abrir no Protégé | pendente |
| 6 | Script de instanciação, seguindo as regras de `PROBLEMAS_JUNCAO.md` seção 3 | pendente |
| 6b | Decidir o M4 (`ocorreEm` como mediation?) com os números do recorte (`PROBLEMAS_JUNCAO.md` 3.4b) | pendente, depende do 6 |
| 7 | Uma consulta SPARQL por QC (`consultas/qc1.rq` … `qc5.rq`) | pendente |
| 8 | Texto: classes, relações, limitações (M1–M3, P1–P2 e as notas *texto*) e exemplos de instanciação | pendente |

## 6. Validação no Tonto (2026-11-27)

Validado com o servidor do Tonto 0.9.4 (o mesmo do painel *Problems*): **nenhum erro,
nenhum warning**. O export para gUFO funciona (642 linhas de Turtle). Fica 1 *hint*,
aceito:

| Hint | Onde | Por que fica |
|---|---|---|
| `implied-relation-stereotype` | `AnotacaoFuncional ocorreEm Celula` | Não é `@mediation` (mínimo 0, e mediation exige 1) nem dependência histórica: é só o contexto em que o processo ocorre. Uma relação comum é válida |

Resolvidos:
- `subkind-founded-on-relator` (`ConjuntoDeDados`): `RecursoInformacional` virou
  `category`, e `ConjuntoDeDados`/`Ontologia` viraram kinds.
- `implied-relation-stereotype` (`baseadaEm`): virou `@historicalDependence`, com
  `(const)` no Estudo e `(addOnly)` na anotação.

Para o Protégé: namespace provisório (`example.org`), `pValor` como `xsd:decimal`
(sem notação científica), `owl:imports` do gUFO pela internet.
