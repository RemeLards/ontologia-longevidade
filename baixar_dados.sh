#!/usr/bin/env bash
# Baixa as fontes da Ontologia de Longevidade, separadas em:
#   ./dados/       bases com instâncias (HAGR, GWAS, GO annotations, HGNC, opcionais)
#   ./ontologias-geneticas/  ontologias reutilizadas (GO, CL, SO)
# Uso: bash baixar_dados.sh            # tudo
#      bash baixar_dados.sh --sem-grandes  # pula arquivos > 50 MB (GWAS estudos/associações, cl.owl)
# Reexecutar é seguro: arquivos já baixados são pulados (use -f para forçar).
set -euo pipefail

cd "$(dirname "$0")"
SEM_GRANDES=0; FORCAR=0
for a in "$@"; do
  case "$a" in
    --sem-grandes) SEM_GRANDES=1 ;;
    -f) FORCAR=1 ;;
  esac
done

D=dados
O=ontologias-geneticas
mkdir -p "$D"/{hagr,gwas,go,hgnc,opcionais} "$O"
LOG="VERSOES.txt"
echo "# Download em $(date -u +%Y-%m-%dT%H:%MZ)" >> "$LOG"

baixar() {  # baixar <pasta relativa à raiz> <url> [grande]
  local pasta=$1 url=$2 grande=${3:-}
  local arq="$pasta/$(basename "$url")"
  if [[ -n $grande && $SEM_GRANDES == 1 ]]; then echo "-- pulado (grande): $url"; return; fi
  if [[ -s $arq && $FORCAR == 0 ]]; then echo "-- já existe: $arq"; return; fi
  echo ">> $url"
  curl -fL --retry 3 --progress-bar -o "$arq.part" "$url" && mv "$arq.part" "$arq"
  echo "$arq  $url  $(stat -c %s "$arq") bytes  sha256=$(sha256sum "$arq" | cut -c1-16)" >> "$LOG"
}

# --- Bases de dados ---
baixar $D/hagr https://genomics.senescence.info/longevity/longevity_genes.zip     # LongevityMap
baixar $D/hagr https://genomics.senescence.info/genes/human_genes.zip             # GenAge-Human
GW=https://ftp.ebi.ac.uk/pub/databases/gwas/releases/latest
baixar $D/gwas $GW/gwas-catalog-associations_ontology-annotated-full.zip grande
baixar $D/gwas $GW/gwas-catalog-studies.tsv grande
baixar $D/gwas $GW/gwas-efo-trait-mappings.tsv
baixar $D/go   https://current.geneontology.org/annotations/goa_human.gaf.gz
baixar $D/hgnc https://storage.googleapis.com/public-download-files/hgnc/tsv/tsv/hgnc_complete_set.txt

# --- Ontologias ---
baixar $O https://purl.obolibrary.org/obo/go/go-basic.obo
baixar $O https://purl.obolibrary.org/obo/cl/cl-basic.obo
baixar $O https://purl.obolibrary.org/obo/cl.owl grande
baixar $O https://purl.obolibrary.org/obo/so.obo

# --- Opcionais (ponte gene ↔ tipo celular) ---
baixar $D/opcionais https://www.proteinatlas.org/download/tsv/rna_single_cell_type.tsv.zip
baixar $D/opcionais https://genomics.senescence.info/cells/cellAge.zip

# Descompacta os zips pequenos do HAGR
for z in "$D"/hagr/*.zip "$D"/opcionais/cellAge.zip; do
  [[ -f $z ]] && unzip -oq "$z" -d "${z%.zip}"
done

echo; echo "Pronto. Versões registradas em $LOG"; du -sh "$D"/* "$O"
