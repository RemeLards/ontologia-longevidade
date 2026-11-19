# Fontes de dados — Ontologia de Longevidade

Links verificados em 2026-11-16 (HTTP 200). Para baixar tudo: `bash baixar_dados.sh`
(ou `bash baixar_dados.sh --sem-grandes` para pular os arquivos > 50 MB).
Estrutura: `dados/` (bases com instâncias) e `ontologias-geneticas/` (GO, CL, SO), criadas pelo script; o modelo Tonto fica em `ontologia-tonto/`.

## Bases de dados (instâncias)

| Fonte | Página | Arquivo baixado | Tamanho | Uso |
|---|---|---|---|---|
| LongevityMap (HAGR) | https://genomics.senescence.info/longevity/ · downloads: https://genomics.senescence.info/download.html | `longevity_genes.zip` | 25 KB | Associações variante/gene ↔ longevidade (QC1, QC2, QC5) |
| GenAge–Human (HAGR) | https://genomics.senescence.info/genes/ | `human_genes.zip` | 9 KB | Genes ligados ao envelhecimento (QC2) |
| GWAS Catalog (NHGRI-EBI) | https://www.ebi.ac.uk/gwas/docs/file-downloads · FTP: https://ftp.ebi.ac.uk/pub/databases/gwas/releases/latest/ | `gwas-catalog-associations_ontology-annotated-full.zip` | 73 MB | Associações GWAS com traços EFO (QC1, QC5) |
| | | `gwas-catalog-studies.tsv` | 77 MB | Metadados dos estudos (opcional) |
| | | `gwas-efo-trait-mappings.tsv` | 19 MB | Mapeamento traço → EFO (filtrar "longevity") |
| GO Annotations (humano) | https://current.geneontology.org/products/pages/downloads.html | `goa_human.gaf.gz` | 15 MB | Ligação gene → processo biológico (QC3) |
| HGNC | https://www.genenames.org/download/archive/ | `hgnc_complete_set.txt` | 17 MB | IDs/símbolos padronizados de genes (cruzar as bases) |

## Ontologias reutilizadas (esquema)

| Ontologia | Página | Arquivo | Tamanho | Uso |
|---|---|---|---|---|
| Gene Ontology (GO) | https://geneontology.org/docs/download-ontology/ | `go-basic.obo` | 32 MB | Processos biológicos |
| Cell Ontology (CL) | https://obofoundry.org/ontology/cl.html | `cl-basic.obo` | 3 MB | Tipos celulares |
| | | `cl.owl` (completa, inclui relações CL↔GO) | 66 MB | Ponte tipo celular ↔ processo (QC4) |
| Sequence Ontology (SO) | http://www.sequenceontology.org/ · https://obofoundry.org/ontology/so.html | `so.obo` | 1 MB | Tipos de variante |

## Opcionais (ponte para QC4)

| Fonte | Página | Arquivo | Tamanho | Uso |
|---|---|---|---|---|
| Human Protein Atlas — single cell | https://www.proteinatlas.org/about/download | `rna_single_cell_type.tsv.zip` | 16 MB | Expressão gene × tipo celular (alternativa à ponte via CL↔GO) |
| CellAge (HAGR) | https://genomics.senescence.info/cells/ | `cellAge.zip` | 22 KB | Genes de senescência celular |

## Observações

- A LongevityMap informa o rsID mas não o tipo de variante. Para classificar com a SO
  será preciso anotar via Ensembl VEP (https://rest.ensembl.org/ — endpoint `vep/human/id/{rsID}`),
  feito depois, sob demanda, só para os rsIDs da LongevityMap.
- Licenças: HAGR e GO são CC-BY; GWAS Catalog é aberto (EMBL-EBI terms); HPA é CC-BY-SA.
  Citar as versões/datas registradas em `VERSOES.txt`.
