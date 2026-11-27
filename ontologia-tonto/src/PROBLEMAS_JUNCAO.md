# Problemas de modelagem e implementação — `ontologia-nova.tonto`

Revisado em 2026-11-26, com os dados reais (números na seção 4).

As duas categorias de problema:
- **Modelagem**: limitações do modelo, que devem ser declaradas no texto do trabalho.
- **Implementação**: regras que o script de instanciação precisa seguir.

Documentos dos módulos:
- `modulos/biologia/src/FONTES_FORA_DA_PROPOSTA.md`: GAF, HPA e ECO;
- `modulos/pesquisa/src/PROBLEMAS.md`: estudos, populações e fontes.

---

## 1. Decisões já aplicadas no modelo

**Critério para opcionais:** `[0..1]`/`[0..*]` só quando o domínio permite a falta
(variante intergênica, anotação IEA sem estudo, haplótipo sem rsID, contexto celular).
Falta de dado de uma base é resolvida no script: normalizar, derivar ou descartar (com
log). Por isso saíram `Gene.entrezId`, `Estudo.idNaFonte` e os dois `SemInformacao`.

| Decisão | Motivo |
|---|---|
| `Gene` e `Variante` são kinds; `category ElementoGenomico` acima deles | Identidades diferentes. A category só serve para o relator apontar para "gene ou variante" |
| `AssociacaoLongevidade avaliaElemento [1..*] ElementoGenomico` | Nem todo registro tem gene (2) ou variante (116), e a `@mediation` não aceita mínimo 0 |
| `Gene.hgncId [1]`, sem `entrezId` | Todo gene passa pela HGNC antes de entrar; o Entrez só serve para achar o HGNC (3.1) |
| Sem `SemInformacao` nos enums | Ausência não vira relator: os 2 registros sem significância saem (log); gene fora da GenAge não tem `EvidenciaEnvelhecimento` |
| `ProcessoBiologico subprocessoDe ProcessoBiologico` | Hierarquia da GO. Sem ela, "DNA repair" acha 217 genes em vez de 475 |
| `AnotacaoFuncional ocorreEm Celula` + `ExpressaoGenica` (HPA) | QC4 por dois caminhos: curado (GO + CL) e por expressão (HPA) |
| `AnotacaoFuncional.referencia [1]` e `baseadaEm [0..1] Estudo` | O GAF tem uma referência por linha |
| `baseadaEm` é `@historicalDependence` (Estudo `const`, anotação `addOnly`) | A anotação veio de um estudo já feito; não pode ser `@mediation` porque é opcional |
| `category RecursoInformacional`, kinds `ConjuntoDeDados` e `Ontologia` | Subkind mediado por relator o Tonto lê como role; ser base de dados é rígido |
| `ExpressaoGenica.nCPM` | A unidade do HPA é nCPM (não TPM) |
| `Variante.rsId [0..1]`: haplótipo sem rsId | `E2/E3/E4` = rs429358 + rs7412. Fica como Variante só com `descricao` |
| `Celula.tipoCelular_idCL [1]`: tipo HPA → termo CL mais geral | 155 tipos no HPA, alguns sem termo exato |
| `Populacao` é `kind` | Sem `Pessoa`, um collective ficaria sem membros |
| GWAS entra **filtrado** para traços de longevidade | 708 associações, 49 estudos, 28 PMIDs; não precisa de `Fenotipo` |
| `observadaEm [1..*] Populacao` | 4 estudos do GWAS são multiancestrais; rótulos compostos da LongevityMap podem ser separados |
| `Estudo` = artigo, `pubmedId [1]` | PMID em 550/550 registros da LongevityMap e 708/708 do GWAS. Os GCST do mesmo artigo (9 dos 28 PMIDs têm vários) viram um Estudo; o GCST vai no `idNaFonte` da associação |
| `AssociacaoLongevidade.trait [1]` | 442 das 708 associações do GWAS são longevidade **dos pais** (EFO_0007796); a LongevityMap recebe OBA_VT0005372 (*life span*) |
| `AssociacaoLongevidade.pValor [0..1]` | O GWAS traz o p-valor (todas ≤ 1e-5); a LongevityMap não |

---

## 2. Problemas de modelagem (declarar no texto)

Só o que é escolha de modelo. O resto aparece na implementação (seção 3).

| # | Problema | Onde |
|---|---|---|
| M1 | **Termos GO e CL são instâncias**, não classes. Na UFO, processo é evento e tipo celular é tipo, mas aqui viram indivíduos para os relatores apontarem para eles | `ProcessoBiologico`, `Celula` |
| M2 | **"Gene participa do processo" abrevia "o produto do gene participa"**. O GAF anota proteínas e RNAs, não genes | `AnotacaoFuncional` |
| M3 | **"Longevidade" reúne traços diferentes**: longevidade própria (LongevityMap, *life span*), dos pais (*parental longevity*, 62% do GWAS), *healthspan* e idade ao morrer. O atributo `trait` (termo EFO/OBA) distingue; declarar no texto quais traços contam | `AssociacaoLongevidade` |
| M4 | **Em aberto: `ocorreEm` opcional ou `@mediation`?** Biologicamente, o processo ocorre em alguma célula. Hoje é relação comum `[0..*]`, porque o relator é o **registro** do GAF, que existe sem célula (só cerca de 3% das linhas de processo têm `occurs_in`), e porque há processos de organismo (GO:0007568 *aging*, GO:0008340 *determination of adult lifespan*). **Decidir depois do recorte** (3.4b) | `AnotacaoFuncional ocorreEm Celula` |

As simplificações do módulo de pesquisa (população e estudo como kind)
estão em `modulos/pesquisa/src/PROBLEMAS.md`.

---

## 3. Notas de implementação (script e consultas)

Não mudam o modelo. São regras para o script de instanciação e para as consultas, e
algumas viram uma frase de limitação no texto (marcadas com *texto*).

### 3.1 Identidade de gene (todas as fontes)

- **Normalizar todo gene para o `hgncId`** antes de cruzar. A ordem é:
  1. Entrez;
  2. símbolo atual;
  3. símbolo anterior ou alias da HGNC, só quando for único.
- Símbolos antigos encontrados:
  - na GenAge, 4 (ARNTL→BMAL1, H2AFX→H2AX, CTGF→CCN2, ATP5O→ATP5PO);
  - na LongevityMap, 90 dos 884 não são atuais, e só 28 se resolvem pela HGNC.
- Os nomes sem solução vão para um log:
  - `LOC...`;
  - `LINC...`;
  - mitocondriais sem `MT-`, como `ATP8`;
  - símbolos retirados.
- Hoje a interseção da QC2 dá 125 **por coincidência**: as duas bases usam os mesmos
  símbolos antigos. A normalização evita que ela quebre.

### 3.2 LongevityMap

- Separar os campos com vários genes (66 registros) e vários rsIDs (154 registros).
- **Variante = nome do gene** (100 registros) conta como "só gene".
- **Identidade da variante:** usar o rsID quando houver. Os 434 nomes que não são rsID
  (`E2/E3/E4`, `I/D`, `677C/T`, `HLA-B40`) ficam só com `descricao`.
  - Cuidado: o mesmo nome em registros diferentes deve virar a **mesma** Variante.
- **Significância:** normalizar a grafia (`significant`, `non-significant`,
  `Non-significant`). Os 2 registros vazios não entram (log).
- **`trait`:** sempre OBA_VT0005372 (*life span*).
- A população do registro tem de estar entre as que o `Estudo` observa.
- *texto*: o CSV não diz qual variante é de qual gene (154 registros com várias
  variantes, 66 com vários genes). O par se recupera só pela posição (`localizadaEm`).
- *texto*: o G481 tem 8 rsIDs, sem dizer se é um haplótipo ou se são 8 testes.
- *texto*: a significância é só sim/não, sem p-valor nem direção do efeito.

### 3.2b GWAS Catalog

- **Filtro:** `MAPPED_TRAIT_URI` contém EFO_0007796 (*parental longevity*),
  OBA_VT0005372 (*life span*), EFO_0009762 (*healthspan*), EFO_0005056 (*age at
  death*) ou EFO_0022597 (*aging*), e **não** contém traços de outra natureza
  (cognição EFO_0008354, menarca e menopausa EFO_0004703/4, tabagismo EFO_0006527).
  Os traços de *survival* do GWAS são sobrevida a câncer e ficam fora.
- **Associação:** uma por linha. `avaliaElemento` = a **variante** (rsID; 693 de 708
  têm). O gene **não** entra na associação:
  - o `MAPPED_GENE` é posicional (243 linhas "A - B", variante entre dois genes);
  - o `REPORTED GENE(S)` é "NR" em 405 linhas;
  - o gene vem por `Variante localizadaEm Gene`.
- **`significancia`:** sempre `Significativa`. **`pValor`:** coluna `P-VALUE`.
  **`trait`:** URI de `MAPPED_TRAIT_URI`.
- **`tipoSO`:** coluna `CONTEXT` (intron_variant, missense_variant...), sem precisar
  do VEP. O VEP só é necessário para as variantes da LongevityMap.
- **Estudo:** um por `PUBMEDID` (28), com `nome` = título do artigo. O `STUDY
  ACCESSION` (GCST) entra no `idNaFonte` da associação (`GCST...:rs...`).
- **População:** do `gwas-catalog-ancestry.tsv`, estágio `initial`: `BROAD ANCESTRAL
  CATEGORY` + `COUNTRY OF RECRUITMENT`. 4 estudos têm mais de uma.
- **Efeito:** `OR or BETA` está vazio em 180 linhas. Ainda não está no modelo.
- *texto*: 62% das associações do GWAS são longevidade **dos pais**, medida no genoma
  dos filhos (UK Biobank).

### 3.3 GenAge

- Uma `EvidenciaEnvelhecimento` por gene, com `motivo` separado por vírgula (64 genes
  têm mais de um).
- Genes da LongevityMap ausentes da GenAge (cerca de 759) **não** recebem evidência.
  Na QC2, "tem evidência" é `FILTER EXISTS { ?e :sobreGene ?g }`.
- *texto*: a GenAge é curadoria seletiva (307 genes). A QC2 mede concordância entre
  curadorias; ausência na GenAge não significa que o gene não tem relação.
- QC2 filtrada: oferecer uma versão sem `Putative` (80 genes de evidência fraca).

### 3.4 GAF (anotações GO)

- **Filtrar:**
  - aspecto `P`;
  - sem `NOT` (621 linhas);
  - qualificador `involved_in` (fica fora o "atua a montante de", cerca de 2%);
  - sem `ND` (102 linhas);
  - sem ComplexPortal (4.507 linhas de complexos, que não são genes).
- **Produto → gene:** o símbolo da coluna 3 passa pela normalização da HGNC (3.1).
  Isoformas se juntam no mesmo gene (44 símbolos têm mais de um UniProt).
- **`subprocessoDe`:** carregar o `is_a` e o `part_of` do `go-basic.obo`, para todos os
  termos usados e seus ancestrais.
- **`ocorreEm`:** extrair `occurs_in(CL:...)` da coluna 16.
- **`baseadaEm`:** só quando a referência é `PMID:`. As referências `GO_REF`,
  `Reactome` e `DOI` ficam só no atributo.
- **Volume:** recortar para os genes da LongevityMap e da GenAge (1.066). As linhas
  repetidas do mesmo par gene–termo continuam separadas se a evidência for diferente.
- **QC3, versão padrão:** evidência experimental + IBA. A versão "tudo" inclui IEA.

### 3.4b Medir para decidir o M4

Depois de filtrar o GAF (3.4) e recortar para os genes do projeto, medir:
1. quantas anotações têm `occurs_in(CL:...)`, no total e por gene da QC2;
2. quantas são de processos de organismo ou multicelulares, sem célula possível
   (descendentes de GO:0032501 *multicellular organismal process*, GO:0007568 *aging*);
3. quantos genes a QC3 perderia se só entrassem anotações com célula.

Se quase todas tiverem célula e a perda for pequena, `ocorreEm` vira `@mediation [1..*]`.
Senão, continua relação comum, e o texto explica que a célula é contexto opcional do
registro.

### 3.5 HPA (expressão)

- Tabela manual **HPA → CL** para os 155 tipos. Quando não houver termo exato, usar o
  mais geral e marcar como "aproximado". Casos conhecidos:
  - `other brain neurons`;
  - `pituicytes/fscs`;
  - `pancreatic islet cells`;
  - `myonuclei`.
- **Recorte:** genes da LongevityMap e da GenAge, com nCPM ≥ 1. O HPA tem 3,1 milhões
  de linhas, 800 mil delas com zero.
- **Não instanciar** `HPA usaVocabulario CL`, porque o HPA não usa a CL; o
  mapeamento é nosso.
- O relator aceita qualquer `ConjuntoDeDados` como fonte. O script garante a base
  certa em cada relator.

### 3.6 Estudos (PubMed)

- `Estudo.nome` = título do artigo, via NCBI E-utilities `esummary` (270 PMIDs da
  LongevityMap, mais os PMIDs do GAF dentro do recorte). Usar chamadas em lote e
  respeitar o limite de 3 requisições/s sem chave de API.

### 3.7 Versões

- Todo download fica registrado em `VERSOES.txt`, com data e hash. O GAF e a GO saem
  todo mês.

---

## 4. Números de referência (dados de 2026-11-26)

| Fonte | Números |
|---|---|
| LongevityMap | 550 registros: 432 gene + variante, 116 só gene, 2 só variante; 884 nomes de gene; 3.457 nomes de variante (3.023 rsIDs); 270 PMIDs; 81 rótulos de população |
| GenAge | 307 genes (Build 21, 2023); 9 motivos; interseção com a LongevityMap: 125 |
| GAF | 906.445 linhas; 204.919 de processo; 11.190 termos; cobertura: LongevityMap 716/884, GenAge 302/307, QC2 122/125 (120 com evidência experimental); 6.705 extensões `occurs_in(CL)`, 46/125 genes da QC2 |
| GWAS | 1.206.717 associações no total; 708 de longevidade (442 parental), 49 estudos, 28 PMIDs; em comum com a LongevityMap: 29 rsIDs, 61 genes, 7 PMIDs |
| GO | todos os termos usados no GAF existem no go-basic; "DNA repair": 217 genes direto, 475 com descendentes |
| HPA | 3.107.242 linhas; 20.162 genes; 155 tipos celulares; unidade nCPM |
| CL | 3.893 termos; só 342 com `capable_of` → GO (por isso a QC4 não usa isso) |
