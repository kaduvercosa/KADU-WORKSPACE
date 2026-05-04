# POKÉDEX DO KADU

## Pokédex ao Vivo
Confira a Pokédex ao vivo aqui:

[https://kaduvercosa.github.io/pokedexdokadu/Pokedex/](https://kaduvercosa.github.io/pokedexdokadu/Pokedex/)

## Recursos
* **Visualização Detalhada:** Veja Pokémon individuais com atributos, estatísticas, movimentos, habilidades, itens e evoluções.

* **Visualização em Lista:** Visualização completa da Pokédex em grade para facilitar a navegação.

* **Busca e Autocompletar:** Encontre qualquer Pokémon por nome ou ID.

* **Filtros:** Filtre Pokémon por Geração, Tipo e Raridade (Lendário, Mítico, Bebê).

* **Randomizador:** Descubra novos Pokémon com o recurso de rolagem aleatória.

* **Estilo Dinâmico:** As cores se adaptam dinamicamente com base no tipo principal do Pokémon selecionado.
* **Localização:** Tradução automática usando a API do Google Translate.
* **Modo Escuro:** Suporta a preferência de modo escuro do sistema operacional.

## Organização de Arquivos (index.html)
O arquivo `Pokedex/index.html` é um aplicativo de arquivo único que contém todo o HTML, CSS e JavaScript. Aqui está um guia para ajudá-lo a encontrar e modificar seções específicas:

### 1. Estilos CSS (tag `<style>`)
* **Linhas ~15 a ~30:** Variáveis ​​raiz (Cores, Gradientes, temas Liquid Glass).

* **Linhas ~30 a ~120:** Redefinições básicas, tipografia, animações globais (`float`, `fadeIn`) e a definição da classe `liquid-glass`.

* **Linhas ~120 a ~190:** Estilo do cabeçalho e da barra de navegação (`#search-container`, `#autocomplete-list`, botões).

* **Linhas ~190 a ~250:** Estilo principal do Card de Pokémon (`#main-card`, `#poke-image`, tipografia, barras de status, emblemas de movimento).
* **Linhas ~250 a ~280:** Estilo da Visualização em Grade (`#full-pokedex`, `.pokedex-card`, `.mini-type`).

* **Linhas ~280 a ~320:** Estilo geral de Modais e Sobreposições (botões de fechar com efeito Liquid Glass, fundos de modais).

* **Linhas ~320 a ~350:** Regras específicas para Modais (`#compare-modal-content`, `.details-content`, `#settings-modal`).

### 2. Estrutura HTML (tag `<body>`)
* **Linhas ~350 a ~390:** Barra de Navegação Superior (Campo de busca, Selecionar filtros, Botões: Favoritos, Aleatório, Configurações). **Linhas ~390 a ~460:** Conteúdo principal do aplicativo.

* `#main-card`: O Pokémon atualmente selecionado (Imagem, Tipos, Estatísticas, Movimentos, Informações adicionais).

* `#evolutions` e `#varieties`: A árvore evolutiva e formas alternativas.

* `#list-view`: O contêiner em grade para a lista completa da Pokédex.

* **Linhas ~460 a ~630:** Estrutura dos modais.

* `#compare-modal`: O comparador de Pokémon lado a lado.

* `#info-modal`: Modal pequeno para detalhes de Movimentos e Habilidades.

* `#image-viewer-modal`: Visualizador de imagens em tela cheia para sprites.

* `#details-modal`: Detalhes expandidos do Pokémon (Galeria de Sprites, Criação, Treinamento).

* `#settings-modal`: Preferências do usuário (Tema, Tamanho da fonte, Ativar/Desativar efeitos).

* **Linhas ~630 a ~640:** Rodapé.

### 3. Lógica JavaScript (tag `<script>`)
* **Linhas ~640 a ~670:** Variáveis ​​iniciais, dicionários de mapeamento (tipos, cores, nomes de gerações) e carregamento inicial de dados (`loadAllPokemon`).

* **Linhas ~670 a ~760:** Lógica de autocompletar (para busca principal e busca comparativa) e lógica de ocultar o cabeçalho ao rolar a página.

* **Linhas ~760 a ~860:** Lógica da visualização em grade (`loadPokedex`, `handleFilter`). Busca e renderiza a grade de cartas.

* **Linhas ~860 a ~1100:** Busca principal de Pokémon (`fetchPokemon`). A função principal! Carrega detalhes, atualiza o DOM, traduz o texto descritivo e calcula os atributos.
* **Linhas ~1100 a ~1150:** Lógica de Compatibilidade de Tipos (`calculateTypeMatchups`).
* **Linhas ~1150 a ~1210:** Busca da Cadeia Evolutiva (`fetchEvolutions`).

* **Linhas ~1210 a ~1320:** Utilitários (Busca, Aleatório, Manipulação de parâmetros de URL).

* **Linhas ~1320 a ~1410:** Lógica de Configurações e Armazenamento Local (`saveSettings`, `applySettings`, `updatePokemonUI`).

* **Linhas ~1410 a ~1480:** Lógica de Favoritos (`toggleFavorite`, `updateFavoriteButton`).
* **Linhas ~1480 a ~1550:** Lógica de abertura/fechamento de modais (`openDetailsModal`, `openImageViewer`, etc.). Inclui a lógica para renderizar a galeria de sprites.
* **Linhas ~1550 a ~1650:** Lógica do modal de comparação (`searchCompare`). Calcula as barras de estatísticas lado a lado.

* **Linhas ~1650 a ~1730:** Lógica dos modais de informação (`fetchAbilityInfo`, `fetchMoveInfo`).

## Tecnologias Utilizadas
* HTML5
* CSS3
* JavaScript (Vanilla)
* [PokeAPI](https://pokeapi.co/)

## Como executar localmente
1. Clone o repositório:

``bash

git clone https://github.com/kaduvercosa/KADU-WORKSPACE.git

```
2. Navegue até o diretório raiz do repositório:

``bash

cd KADU-WORKSPACE

```
3. Inicie um servidor local. Por exemplo, usando Python 3:

``bash

python3 -m http.server --directory Pokedex/

```
4. Abra seu navegador e acesse:

``bash

http://localhost:8000
```
