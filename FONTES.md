# Fontes de dados — Ontologia de Longevidade

Revisado em 2026-11-26. Links conferidos (HTTP 200).

Para baixar, use `bash baixar_dados.sh`, com estas opções:
- `--gwas`: inclui o GWAS Catalog;
- `--opcionais`: inclui ECO e HANCESTRO;
- `--tudo`: inclui tudo;
- `-f`: baixa de novo.

As versões baixadas ficam registradas em `VERSOES.txt`. O modelo é
`ontologia-tonto/src/ontologia-nova.tonto`.

## Usadas pelo modelo (download padrão)

| Fonte | Página | Arquivo | Tamanho | Na proposta? | Elemento do modelo | QC |
|---|---|---|---|---|---|---|
| LongevityMap (HAGR) | https://genomics.senescence.info/longevity/ | `longevity_genes.zip` | 25 KB | sim | `AssociacaoLongevidade`, `Estudo`, `Populacao` | QC1, QC2, QC5 |
| GenAge-Human (HAGR) | https://genomics.senescence.info/genes/ | `human_genes.zip` | 9 KB | sim | `EvidenciaEnvelhecimento` | QC2 |
| GO Annotations (GAF) | https://current.geneontology.org/products/pages/downloads.html | `goa_human.gaf.gz` | 15 MB | como parte da GO | `AnotacaoFuncional`, `ocorreEm` | QC3, QC4 |
| HGNC | https://www.genenames.org/download/ | `hgnc_complete_set.txt` | 17 MB | sim | `Gene.simbolo/hgncId/entrezId` (normalização) | todas |
| Human Protein Atlas (single cell) | https://www.proteinatlas.org/about/download | `rna_single_cell_type.tsv.zip` | 16 MB (150 MB descompactado) | **não** | `ExpressaoGenica` | QC4 |
| Gene Ontology | https://geneontology.org/docs/download-ontology/ | `go-basic.obo` | 32 MB | sim | `ProcessoBiologico`, `subprocessoDe` | QC3, QC4 |
| Cell Ontology | https://obofoundry.org/ontology/cl.html | `cl-basic.obo` | 4 MB | sim | `Celula.tipoCelular_idCL` | QC4 |
| Sequence Ontology | https://obofoundry.org/ontology/so.html | `so.obo` | 1 MB | sim | `Variante.tipoSO` | QC1 |

## Na proposta, ainda fora do modelo (`--gwas`)

| Fonte | Página | Arquivos | Tamanho | O que falta no modelo |
|---|---|---|---|---|
| GWAS Catalog (NHGRI-EBI) | https://www.ebi.ac.uk/gwas/docs/file-downloads | `gwas-catalog-associations_ontology-annotated-full.zip`, `gwas-catalog-studies.tsv`, `gwas-efo-trait-mappings.tsv` | ~170 MB | filtro por traços de longevidade (EFO); opcional `pValor` (PROBLEMAS_JUNCAO.md, M3) |

## Opcionais, fora da proposta (`--opcionais`)

| Fonte | Página | Arquivo | Tamanho | Para quê |
|---|---|---|---|---|
| ECO | https://obofoundry.org/ontology/eco.html | `eco.obo` | 1,4 MB | agrupar códigos de evidência da GO |
| Mapeamento GAF → ECO | https://github.com/evidenceontology/evidenceontology | `gaf-eco-mapping.txt` | 2 KB | código GO (IDA...) → termo ECO |
| HANCESTRO | https://github.com/EBISPOT/hancestro | `hancestro.obo` | 1 MB | padronizar rótulos de população |

## Consultadas pelo script de instanciação (APIs, sem download)

| Serviço | Endpoint | Para quê | Limite |
|---|---|---|---|
| NCBI E-utilities | `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id=...` | título do artigo → `Estudo.nome` | 3 requisições/s sem chave |
| Ensembl VEP REST | `https://rest.ensembl.org/vep/human/id/{rsID}` | tipo SO da variante → `Variante.tipoSO` | 15 requisições/s; existe POST em lote |

## Removidas

- **`cl.owl`** (CL completa, 75 MB): só servia para o `capable_of` CL → GO, que saiu do
  modelo (cobre 342 de 3.893 tipos). A QC4 usa o GAF e o HPA.
- **CellAge**: fora da proposta (versão "sem cellage").

## Licenças

| Fonte | Licença |
|---|---|
| HAGR, GO/GAF, CL, SO, ECO, HANCESTRO | CC-BY 4.0 |
| HPA | CC-BY-SA 4.0 |
| HGNC | livre, com citação |
| GWAS Catalog | EMBL-EBI terms of use |

Citar as versões e datas registradas em `VERSOES.txt`.

## Referências para o trabalho

A proposta está em `Longevidade___Ontologia.pdf`. As referências [1] a [7] são as dela.
As referências [8] a [11] entraram depois e foram aceitas.

| # | Referência | Status | Usada em |
|---|---|---|---|
| [1] | HAGR. *LongevityMap*. Artigo: Budovsky et al. 2013, *Aging Cell* 12(2):320 | proposta | QC1, QC2, QC5 |
| [2] | HAGR. *GenAge–Human*. Artigo: Tacutu et al. 2018, *NAR* 46(D1):D1083 | proposta | QC2 |
| [3] | NHGRI–EBI. *GWAS Catalog* | proposta ("poderá"); **ainda não modelado** | — |
| [4] | Gene Ontology Consortium. *Gene Ontology (GO)* | proposta | QC3, QC4 |
| [5] | OBO Foundry. *Cell Ontology (CL)* | proposta | QC4 |
| [6] | Sequence Ontology. *Sequence Ontology (SO)* | proposta | QC1 (`tipoSO`) |
| [7] | HUGO Gene Nomenclature Committee. *HGNC Database* | proposta | todas (normalização de genes) |
| [8] | GO Consortium / UniProt-GOA. *GO Annotations (goa_human.gaf)* | **nova**, aceita; produto da [4] | QC3, QC4 |
| [9] | *Human Protein Atlas*, single cell type. Artigo: Karlsson et al. 2021, *Science Advances* 7(31):eabh2169 | **nova**, aceita | QC4 (por expressão) |
| [10] | Ensembl. *Variant Effect Predictor (VEP)*. Artigo: McLaren et al. 2016, *Genome Biology* 17:122 | **nova**, necessária para a [6]: a LongevityMap não traz o tipo SO | QC1 (`tipoSO`) |
| [11] | NCBI. *PubMed / E-utilities* | **nova**, só para o título do estudo | `Estudo.nome` |

As opcionais (ECO, HANCESTRO) **não entram** nas referências enquanto não forem usadas.
