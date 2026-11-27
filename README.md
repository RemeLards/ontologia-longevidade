# Ontologia de Referência para a Longevidade Humana

Rafael Fracalossi Freitas e Breno Uliana De Angelo. Modelo em OntoUML (Tonto), fundamentado
na UFO, exportado para gUFO/OWL.

## Requisitos

Feito no **Linux (Ubuntu 22.04)**; versões exatas na tabela seguinte.

| Ferramenta | Para quê | Como instalar |
|---|---|---|
| VS Code + extensão **Tonto** (NEMO/UFES) | editar e validar o modelo; **necessária também para o script de export** | `code --install-extension nemo-ufes.tonto-vscode` |
| Extensão **Tonto Visualizer** (opcional) | diagrama OntoUML do modelo | `code --install-extension nemo-ufes.tonto-visualizer` |
| Node.js ≥ 20 | `scripts/exportar_gufo.mjs` | https://nodejs.org |
| Protégé 5.6 (opcional) | abrir o OWL e rodar o raciocinador | https://protege.stanford.edu |
| bash, curl, unzip | `baixar_dados.sh` | já vêm no Linux |

### Ambiente em que foi feito e testado

| | Versão |
|---|---|
| Sistema | Ubuntu 22.04.5 LTS (Linux 6.8) |
| VS Code | 1.124.2 |
| Tonto (extensão) | 0.9.4 |
| Tonto Visualizer | 0.3.6 |
| Node.js | 20.14.0 |
| Java (para o Protégé) | OpenJDK 11 |
| Protégé | 5.6.9 (com os plugins OntoGraf e OWLViz) |

Os scripts são para Linux (bash). No Windows, usar o WSL.

## Uso

```bash
bash baixar_dados.sh               # baixa as bases e ontologias (~1,2 GB); ver FONTES.md
node scripts/exportar_gufo.mjs     # valida e gera ontologia-tonto/generated/longevidadehumana.ttl
```

O export também pode ser feito no VS Code: abra `ontologia-tonto/src/ontologia-nova.tonto` e
rode **Tonto: Export to gUFO...** (Ctrl+Shift+P). O script dá o mesmo resultado, porque usa o
servidor da própria extensão; por isso ela precisa estar instalada, mesmo sem abrir o VS Code.

## Onde está cada coisa

| Caminho | Conteúdo |
|---|---|
| `ontologia-tonto/src/ontologia-nova.tonto` | o modelo atual |
| `ontologia-tonto/generated/` | o OWL exportado (não editar; gerar de novo) |
| `modulos/biologia`, `modulos/pesquisa` | os dois módulos avaliados separadamente |
| `AVALIACAO_MODELO.md` | estado do modelo, cobertura das QCs e o que falta |
| `ontologia-tonto/src/PROBLEMAS_JUNCAO.md` | problemas de modelagem e regras de implementação |
| `FONTES.md` | fontes de dados, downloads e referências |
| `Longevidade___Ontologia.pdf` | a proposta |

## Abrir no Protégé

1. *File → Open* → `ontologia-tonto/generated/longevidadehumana.ttl` (com internet: ele
   baixa o gUFO, que o arquivo importa).
2. A aba **Active ontology** só mostra o cabeçalho (título, autores, licença).
3. Classes: aba **Entities → Classes**, ou *Window → Tabs → Classes*. As nossas ficam
   abaixo das classes do gUFO (ex.: `Gene` em `owl:Thing → … → gufo:Object → … → ElementoGenomico`).
4. Grafo: *Window → Tabs → OntoGraf*; clicar numa classe para expandir.
5. Raciocínio: *Reasoner → HermiT → Start reasoner*.

O arquivo hoje só tem o modelo (classes e propriedades). **Ainda não há dados**
(genes, variantes...): isso vem com o script de instanciação. Em *Individuals* aparecem só
os valores dos enums (`Significativa`, `Functional`...) e as próprias classes como
instâncias de `gufo:Kind`, `gufo:Category` etc. (é assim que o gUFO marca o estereótipo).
