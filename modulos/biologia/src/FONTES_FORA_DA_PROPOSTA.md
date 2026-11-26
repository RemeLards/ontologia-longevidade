# Fontes do módulo de biologia que não estão na proposta (PDF)

A proposta (`proposta_longevidade_sem_cellage.pdf`, 06/11/2026) cita:
- as bases LongevityMap, GenAge-Human e GWAS Catalog;
- as ontologias GO, CL, SO e HGNC.

O modelo usa mais duas fontes, e uma terceira fica como opcional. Revisado em 2026-11-26.

| Fonte | Situação | Como citar no texto |
|---|---|---|
| **GAF** (anotações GO) | **usada**, necessária para a QC3 e a QC4 | "GO (ontologia e anotações)": é um produto da própria GO |
| **HPA** (Human Protein Atlas) | **usada**, um dos dois caminhos da QC4 | fonte nova, justificar |
| **ECO** (Evidence & Conclusion Ontology) | **opcional**, não usada | trabalho futuro |

## GAF — `goa_human.gaf.gz`

- **Para que serve:** diz qual gene participa de qual processo GO, com evidência e
  referência. A ontologia GO só define os processos.
- **Elementos do modelo:**
  - `AnotacaoFuncional`;
  - `ocorreEm` (coluna 16, `occurs_in(CL:...)`);
  - `baseadaEm`.
- **Problemas:** `ontologia-tonto/src/PROBLEMAS_JUNCAO.md` (M2; notas 3.4).

## HPA — `rna_single_cell_type.tsv.zip`

- **Para que serve:** a expressão de cada gene em 155 tipos celulares (nCPM). É o
  caminho "por expressão" da QC4:
  ```
  Celula <- ExpressaoGenica -> Gene <- AnotacaoFuncional -> ProcessoBiologico
  ```
- **Por que a CL sozinha não basta:** só 342 dos 3.893 termos da CL têm `capable_of`
  → GO, e são processos genéricos.
- **O outro caminho da QC4 (curado, só GO + CL):** `AnotacaoFuncional ocorreEm Celula`.
  Cobre 46 dos 125 genes da QC2.
- **Custos:**
  - uma fonte a mais;
  - tabela manual HPA → CL (155 tipos, alguns aproximados);
  - volume (3,1 milhões de linhas, é preciso recortar).
- **Problemas:** `PROBLEMAS_JUNCAO.md` (notas 3.5).

## ECO — `eco.obo` (opcional)

- **Para que serviria:** agrupar os códigos de evidência da GO (IDA, IMP... ficam abaixo
  de *experimental evidence*). O mapeamento oficial é `gaf-eco-mapping.txt`.
- **Sem ela:** `codigoEvidencia` fica como texto, e o filtro no SPARQL é uma lista de
  códigos:
  ```sparql
  FILTER(?codigo IN ("EXP","IDA","IPI","IMP","IGI","IEP","IBA"))
  ```
- **Download:** só com `bash baixar_dados.sh --opcionais`.
