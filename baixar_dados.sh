#!/usr/bin/env bash
# Baixa as fontes da Ontologia de Longevidade (ontologia-tonto/src/ontologia-nova.tonto).
#   ./dados/                 bases com instâncias (HAGR, GO annotations, HGNC, HPA, GWAS)
#   ./ontologias-geneticas/  ontologias reutilizadas (GO, CL, SO; ECO e HANCESTRO opcionais)
#
# Uso:
#   bash baixar_dados.sh               # só o que o modelo usa (~260 MB descompactado)
#   bash baixar_dados.sh --gwas        # + GWAS Catalog (~170 MB; na proposta, ainda fora do modelo)
#   bash baixar_dados.sh --opcionais   # + ECO, mapeamento GAF->ECO, HANCESTRO (~3 MB)
#   bash baixar_dados.sh --tudo        # tudo acima
#   -f                                 # baixa de novo mesmo se o arquivo já existir
#
# Reexecutar é seguro: arquivos já baixados são pulados. Cada download é registrado em
# VERSOES.txt (data, URL, tamanho, sha256) para citar as versões no trabalho.
#
# Não são downloads (consultados pelo script de instanciação, sob demanda):
#   NCBI E-utilities (títulos dos artigos PubMed -> Estudo.nome)
#   Ensembl VEP REST (tipo SO das variantes -> Variante.tipoSO)
set -euo pipefail

cd "$(dirname "$0")"
GWAS=0; OPCIONAIS=0; FORCAR=0
for a in "$@"; do
  case "$a" in
    --gwas) GWAS=1 ;;
    --opcionais) OPCIONAIS=1 ;;
    --tudo) GWAS=1; OPCIONAIS=1 ;;
    -f) FORCAR=1 ;;
    *) echo "opção desconhecida: $a" >&2; exit 1 ;;
  esac
done

D=dados
O=ontologias-geneticas
mkdir -p "$D"/{hagr,go,hgnc,hpa} "$O"
LOG="VERSOES.txt"
echo "# Download em $(date -u +%Y-%m-%dT%H:%MZ)" >> "$LOG"

baixar() {  # baixar <pasta> <url> [nome do arquivo]
  local pasta=$1 url=$2 nome=${3:-$(basename "$url")}
  local arq="$pasta/$nome"
  if [[ -s $arq && $FORCAR == 0 ]]; then echo "-- já existe: $arq"; return; fi
  echo ">> $url"
  curl -fL --retry 3 --progress-bar -o "$arq.part" "$url" && mv "$arq.part" "$arq"
  echo "$arq  $url  $(stat -c %s "$arq") bytes  sha256=$(sha256sum "$arq" | cut -c1-16)" >> "$LOG"
}

# --- Bases de dados usadas pelo modelo --------------------------------------
baixar $D/hagr https://genomics.senescence.info/longevity/longevity_genes.zip   # LongevityMap  (QC1, QC2, QC5)
baixar $D/hagr https://genomics.senescence.info/genes/human_genes.zip           # GenAge-Human  (QC2)
baixar $D/go   https://current.geneontology.org/annotations/goa_human.gaf.gz    # GAF           (QC3, QC4)
baixar $D/hgnc https://storage.googleapis.com/public-download-files/hgnc/tsv/tsv/hgnc_complete_set.txt  # HGNC (normalização de genes)
baixar $D/hpa  https://www.proteinatlas.org/download/tsv/rna_single_cell_type.tsv.zip   # HPA (QC4, por expressão)

# --- Ontologias usadas pelo modelo ------------------------------------------
baixar $O https://purl.obolibrary.org/obo/go/go-basic.obo    # GO  (processos + hierarquia subprocessoDe)
baixar $O https://purl.obolibrary.org/obo/cl/cl-basic.obo    # CL  (IDs e nomes dos tipos celulares)
baixar $O https://purl.obolibrary.org/obo/so.obo             # SO  (Variante.tipoSO)

# --- GWAS Catalog (na proposta; ainda não modelado) -------------------------
if [[ $GWAS == 1 ]]; then
  mkdir -p $D/gwas
  GW=https://ftp.ebi.ac.uk/pub/databases/gwas/releases/latest
  baixar $D/gwas $GW/gwas-catalog-associations_ontology-annotated-full.zip
  baixar $D/gwas $GW/gwas-catalog-studies.tsv
  baixar $D/gwas $GW/gwas-efo-trait-mappings.tsv
fi

# --- Opcionais (fora da proposta; ver documentação dos módulos) -------------
if [[ $OPCIONAIS == 1 ]]; then
  baixar $O https://purl.obolibrary.org/obo/eco.obo                     # ECO (agrupar códigos de evidência)
  baixar $O https://purl.obolibrary.org/obo/eco/gaf-eco-mapping.txt     # código GO -> termo ECO
  baixar $O https://raw.githubusercontent.com/EBISPOT/hancestro/main/hancestro.obo  # HANCESTRO (populações)
fi

# --- Descompacta --------------------------------------------------------------
for z in "$D"/hagr/*.zip; do
  [[ -f $z ]] && unzip -oq "$z" -d "${z%.zip}"
done
[[ -f $D/hpa/rna_single_cell_type.tsv.zip ]] && unzip -oq "$D/hpa/rna_single_cell_type.tsv.zip" -d "$D/hpa"

echo; echo "Pronto. Versões registradas em $LOG"; du -sh "$D"/* "$O"
