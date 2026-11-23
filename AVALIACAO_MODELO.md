# Avaliação do modelo — o que falta para ficar bom

Modelo avaliado: `ontologia-tonto/src/ontologia.tonto` (versão de 2026-11-23).
Referência das regras: `REFERENCIA_ONTOUML.md`.

**Resumo.** A espinha dorsal está boa: kinds/subkinds coerentes, três relatores bem
justificados e todas as QCs têm caminho no diagrama. O que impede o modelo de "ficar
bom" são três coisas, nesta ordem:

1. **10 relações sem estereótipo** — o OntoUML não sabe o que elas significam, e o gUFO
   gerado vai sair pobre ou com erro.
2. **Termos de GO/CL/SO tratados de três jeitos diferentes** — é a maior fonte de
   confusão conceitual do modelo.
3. **Nenhum atributo ativo** — sem identificadores (símbolo, rsID, PubMed, ID GO) as
   instâncias não se ligam aos dados, e a QC1 não filtra significância.

---

## 1. O que já está bom (não mexer)

| Elemento | Por que está certo |
|---|---|
| `Gene`, `Variante` subkinds de `RegiaoGenomica` | um único provedor de identidade; genset disjoint incompleto (há outras regiões) |
| `FonteDeDados` + 4 subkinds, disjoint complete | classifica o *tipo* de base; LongevityMap etc. ficam como instâncias |
| `AssociacaoLongevidade` (relator) | tem significância, população, estudo; o mesmo gene aparece em vários estudos → passa no teste do relator |
| `EvidenciaEnvelhecimento` (relator) | tem motivo (`why`), é curadoria; media 2 entidades |
| `AnotacaoFuncional` (relator) | tem código de evidência; o mesmo par gene–processo tem várias anotações |
| `@mediation` com mínimo 1 e `(const)` | cumpre dependência existencial |
| `PopulacaoEstudada` role de `Populacao` (collective) | role com dependência relacional via mediation |
| `TipoCelular` subkind de `Celula` | tipo celular é rígido (hepatócito não deixa de ser) |

## 2. Cobertura das questões de competência

| QC | Caminho no modelo | Situação |
|---|---|---|
| QC1 genes/variantes associados | `AssociacaoLongevidade → avaliaGene / avaliaVariante` | ⚠ precisa do atributo `significancia` para separar associados de não associados |
| QC2 LongevityMap ∩ GenAge | Gene com `AssociacaoLongevidade` **e** `EvidenciaEnvelhecimento` | ✔ |
| QC3 processos GO | Gene ← `AnotacaoFuncional` → `ProcessoBiologico` | ✔ (filtrar aspecto P do GAF) |
| QC4 tipos celulares CL | `ProcessoBiologico ← realiza ← TipoCelular` | ✔ estrutura; ⚠ verificar nos dados quantos termos CL têm `capable_of` |
| QC5 resultados entre fontes | `registradaEm`, `curadaPor`, `anotadaEm` | ⚠ ligações à fonte inconsistentes (ver 3.2) |

---

## 3. Problemas e o que fazer

### 3.1 Relações sem estereótipo (bloqueia o OWL)

| Relação | Natureza real | Proposta |
|---|---|---|
| `Variante localizadaEm Gene` | decorre só das coordenadas dos dois | `@formal` (comparativa, baseada em atributos) |
| `AssociacaoLongevidade avaliaVariante Variante` | participante opcional do relator | criar `relator`-subkind `AssociacaoDeVariante specializes AssociacaoLongevidade` com `@mediation [1..*] (const) Variante` — resolve o "0..* não pode ser mediation" |
| `AssociacaoLongevidade registradaEm BaseDeAssociacoes` | proveniência | `@mediation` dentro do relator (igual a `curadaPor`) — ver 3.2 |
| `AnotacaoFuncional anotadaEm OntologiaDeReferencia` | proveniência | `@mediation` dentro do relator — ver 3.2 |
| `FonteDeDados mantidaPor Organizacao` | não serve a nenhuma QC | **remover** `Organizacao` e a relação (simplifica) |
| `ProcessoBiologico processoDefinidoEm OntologiaDeReferencia` | o termo pertence à ontologia | some com a decisão 3.3 (vira IRI/namespace da GO) |
| `TipoDeVariante tipoVarianteDefinidoEm …` | idem | some com 3.3 |
| `TipoCelular tipoCelularDefinidoEm …` | idem | some com 3.3 |
| `Variante classificadaComo TipoDeVariante` | classificação | some com 3.3 (termos SO viram subclasses de `Variante`) |
| `TipoCelular realiza ProcessoBiologico` | capacidade do tipo celular (CL `capable_of`) | manter, estereótipo a definir com 3.3 (`@participation` se Processo virar `event`; senão documentar como relação de domínio) |

### 3.2 Ligação com a fonte: escolher UM jeito

Hoje: GenAge liga a fonte por `@mediation` (`curadaPor`); LongevityMap e GO por relação
solta (`registradaEm`, `anotadaEm`). **Proposta: todos os relatores com `@mediation` para
a fonte.** Regra do modelo: *todo fato é afirmado por uma fonte e depende dela*. Fica
uniforme, a QC5 vira sempre o mesmo padrão de consulta, e cada relator passa a mediar ≥ 2
entidades naturalmente.

### 3.3 Termos de GO, CL e SO — decisão principal

Hoje há três tratamentos diferentes:
- CL → subclasses de `TipoCelular` (decidido);
- SO → instâncias de `TipoDeVariante` + relação `classificadaComo`;
- GO → instâncias de `kind ProcessoBiologico`.

O problema de fundo é de **nível**: "DNA repair", "hepatocyte", "missense_variant" são
**tipos**, não coisas individuais. A proposta usa a regra "o termo vira subclasse quando
dá; vira instância só quando um relator precisa apontar para ele":

| Ontologia | Proposta | Justificativa |
|---|---|---|
| **CL** | subclasse de `TipoCelular` (já decidido) | taxonomia da CL se encaixa direto embaixo de `Celula` |
| **SO** | subclasse de `Variante`; **remover** `TipoDeVariante` e `classificadaComo` | mesmo raciocínio da CL; `rs7412 a so:missense_variant` |
| **GO** | **instância** (simplificação documentada) | `AnotacaoFuncional` precisa mediar um indivíduo; se GO virasse classe, o relator apontaria para uma classe — não é OntoUML válido |

Consequência: `ProcessoBiologico` continua `kind` cujas instâncias são termos GO — isso
fere a UFO (processo é perdurant) e **deve ser dito no texto** como simplificação
consciente, ou o nome muda para algo honesto (ex.: `TermoGO`). As três relações
`*DefinidoEm` deixam de ser necessárias: a origem do termo está no próprio IRI
(`obo:GO_…`, `obo:CL_…`, `obo:SO_…`).

### 3.4 Célula contém região genômica — conflito de nível

`@componentOf Celula [1..*] <>-- RegiaoGenomica` diz que **o mesmo** indivíduo APOE é parte
de muitas células. Mas cada célula tem **sua cópia física**; o APOE da HGNC é a região
de referência (informação). É o mesmo problema de nível de 3.3.
- **Nenhuma QC usa essa relação.**
- Proposta: **remover**, ou manter com nota explícita de que `RegiaoGenomica` é a região
  de referência e a relação é uma simplificação. Recomendo remover até uma QC precisar.

### 3.5 Atributos mínimos para religar

Antes de gerar o OWL, descomentar só os identificadores e o que as QCs filtram:

| Classe | Atributo | Usado em |
|---|---|---|
| Gene | `simbolo`, `hgncId` | cruzamento entre bases (QC2) |
| Variante | `rsId`, `descricao` | QC1 |
| AssociacaoLongevidade | `significancia` (+ enum) | QC1 |
| Publicacao | `pubmedId` | QC5 |
| EvidenciaEnvelhecimento | `motivo` (+ enum) | QC2 detalhada |
| AnotacaoFuncional | `codigoEvidencia` (novo) | QC3: separar experimental (IDA/IMP) de automática (IEA) |
| Populacao | `nome` | QC1 |

Coordenadas (`montagem`, `cromossomo`, `inicio`, `fim`) e `entrezId` podem continuar comentados.

### 3.6 Pontos menores

- **Fenótipo implícito:** a associação é "com longevidade" por definição. Se o GWAS
  entrar (vários traços), será preciso `kind Fenotipo` (EFO) mediado pelo relator.
- **`significancia` é só da LongevityMap** (GWAS usa p-valor). Enquanto só a
  LongevityMap for instanciada, deixar no relator; quando o GWAS entrar, mover para um
  subkind `AssociacaoLongevityMap`.
- **`Populacao` sem membros:** collective normalmente tem `@memberOf`. Sem `Pessoa` no
  escopo, documentar que a população é tratada como rótulo do estudo.

---

## 4. Plano em ordem

| # | Tarefa | Tipo |
|---|---|---|
| 1 | Decidir 3.3 (termos) e 3.4 (célula contém região) | decisão |
| 2 | Aplicar 3.1 + 3.2: estereótipos, relator de variante, fonte via mediation, remover `Organizacao`, `TipoDeVariante`, `*DefinidoEm` | modelo |
| 3 | Descomentar atributos de 3.5 | modelo |
| 4 | Validar na extensão até zerar erros | ferramenta |
| 5 | Exportar gUFO (`.ttl`) e abrir no Protégé | ferramenta |
| 6 | Script de instanciação: LongevityMap + GenAge + recorte do GAF/CL | dados |
| 7 | Uma consulta SPARQL por QC | resultado |

## 5. Organização do repositório

- `dados/`, `ontologias-geneticas/` e o PDF da proposta não vieram para
  `ontologia-longevidade/`. Os dados se recriam com `bash baixar_dados.sh`.
- Adicionar `.gitignore` com `dados/` e `ontologias-geneticas/` (~320 MB) antes de commitar.
