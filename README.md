<<<<<<< HEAD
# brasil-eleitoral
Dashboad com todos os Presidentes do Brasil desde a redemocratização até os dias atuais
=======
# Brasil Eleitoral

Dashboard dos presidentes que exerceram o governo desde a redemocratização em 1985. Interface em português, inspirada no [Light Blue React Template](https://github.com/flatlogic/light-blue-react-template), adaptada para views Rails e Tailwind.

O tema tem fundo branco, verde nas ações, azul nos títulos e amarelo nos destaques. A paleta está centralizada nas variáveis de `app/assets/tailwind/application.css`.

## Stack

- Ruby 4.0.5 e Rails 8.1.4.
- PostgreSQL; desenvolvimento validado com PostgreSQL 18.
- Tailwind CSS 4 pelo `tailwindcss-rails`, com compilação local.
- Hotwire: Turbo, Stimulus e Importmap. Não exige Node ou React.
- Minitest e testes de navegador com Selenium/Chrome.

## Executar

É necessário ter Ruby/Bundler e PostgreSQL instalados. O usuário local do PostgreSQL precisa conseguir criar os bancos `brasil_eleitoral_development` e `brasil_eleitoral_test`. A configuração padrão usa o usuário do sistema por socket; para outra instalação, use as variáveis padrão do PostgreSQL `PGHOST`, `PGPORT`, `PGUSER` e `PGPASSWORD`.

```sh
rtk bundle install
rtk bin/setup --skip-server
rtk bin/dev
```

Abra **http://localhost:3000**. O `bin/dev` inicia o Rails e recompila o Tailwind ao editar o CSS. O `bin/setup` prepara o banco, carrega o catálogo e compila o CSS.

Para recarregar o conteúdo após editar os arquivos de dados:

```sh
rtk bin/rails db:seed
```

## O que já funciona

- Dashboard com 8 presidentes e 9 períodos de governo.
- Linha do tempo com acesso aos perfis.
- Busca por nome, partido ou agenda e filtros por posição e década.
- Perfis com contexto político, economia, políticas, marcos e fontes.
- Seção “Como chegou ao poder?” com sucessões, chapas, todos os candidatos por turno e coligações eleitorais de 1985 a 2022.
- Comparação de duas gestões lado a lado.
- Gráfico do IPCA com 30 observações oficiais do IBGE, de 1995 a 2024.
- Exportação CSV em UTF-8, com os filtros selecionados.
- Layout responsivo e navegação móvel.
- Página de fontes e metodologia.

## Dados e critérios

O catálogo está em [db/data/administrations.yml](db/data/administrations.yml); a série econômica está em [db/data/ipca.json](db/data/ipca.json). A carga é idempotente.

A origem dos mandatos está em [db/data/accessions.yml](db/data/accessions.yml), que referencia por ano as eleições em [db/data/elections.yml](db/data/elections.yml). A carga resolve essas referências no campo JSONB `accession` de cada governo. Resultados, alianças e fontes também são incluídos na exportação CSV.

FHC e os mandatos consecutivos de Lula e Dilma são agrupados por período contínuo. Lula a partir de 2023 tem registro próprio. As datas usam o último dia completo anterior à sucessão; as notas distinguem exercício e titularidade. Tancredo não entra na contagem, pois não exerceu o cargo.

As posições políticas são sínteses editoriais qualitativas. As políticas são uma seleção inicial, com cobertura até 2024 no período aberto em 2023. A página **/metodologia** explica critérios, limites e fontes; o gráfico econômico não atribui causalidade aos presidentes. Veja a [proveniência dos dados](db/data/README.md).

## Verificação

```sh
rtk bin/rails test
rtk bin/rails test:system
rtk bin/rails zeitwerk:check
rtk bin/rails tailwindcss:build
```

Os testes de sistema precisam de Google Chrome. O Selenium Manager resolve o driver compatível, podendo precisar de rede na primeira execução.

## Estrutura principal

- `app/controllers/dashboard_controller.rb`: páginas, filtros e exportação.
- `app/models/`: presidentes, períodos e observações econômicas.
- `app/views/dashboard/`: dashboard, perfis, comparação e metodologia.
- `app/assets/tailwind/application.css`: tema e componentes.
- `app/javascript/controllers/navigation_controller.js`: menu móvel.
- `db/seeds.rb`: importação transacional dos arquivos locais.

O projeto está preparado para desenvolvimento local. Não foi publicado e nenhum commit foi criado. A licença MIT do template original está preservada em [docs/licenses/light-blue-react-template.txt](docs/licenses/light-blue-react-template.txt).
>>>>>>> a1ec455 (dashboard com os presidentes do pais desde a redemocratização)
