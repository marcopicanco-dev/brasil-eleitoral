# Brasil Eleitoral

![Dashboard do Brasil Eleitoral com indicadores e linha do tempo dos governos](docs/images/brasil-eleitoral-dashboard.png)

Dashboard dos presidentes que exerceram o governo desde a redemocratização em 1985. Interface construída com views Rails e Tailwind CSS.

O tema tem fundo branco, verde nas ações, azul nos títulos e amarelo nos destaques. A paleta está centralizada nas variáveis de `app/assets/tailwind/application.css`.

## Stack

- Ruby 4.0.5 e Rails 8.1.4.
- PostgreSQL; desenvolvimento validado com PostgreSQL 18.
- Tailwind CSS 4 pelo `tailwindcss-rails`, com compilação local.
- Hotwire: Turbo, Stimulus e Importmap. Não exige Node ou React.
- Minitest e testes de navegador com Selenium/Chrome.

## Executar com Docker (macOS)

Instale e abra o Docker Desktop. Ruby, Rails, Bundler, PostgreSQL e Tailwind serão executados nos containers; não é necessário instalá-los no Mac. Este projeto não utiliza MongoDB nem Redis.

### 1. Abra o projeto

Se ainda não tiver o repositório:

```sh
git clone https://github.com/marcopicanco-dev/brasil-eleitoral.git
cd brasil-eleitoral
```

Se já clonou, abra o terminal na pasta existente. Opcionalmente, abra o editor com `code .`.

Confirme que `Dockerfile.dev` e `compose.yaml` estão na raiz e verifique o Docker:

```sh
docker --version
docker compose version
docker info
docker compose config --quiet
```

Se `docker info` não conectar ao servidor, aguarde o Docker Desktop terminar de iniciar.

### 2. Construa a imagem de desenvolvimento

```sh
docker compose build
```

O `Dockerfile.dev` instala as dependências do sistema, Bundler e Foreman. O `Dockerfile` original é voltado à produção.

### 3. Prepare as dependências e o banco

Adicione ao lockfile a plataforma Linux usada pelo container (inclusive em Macs Apple Silicon):

```sh
docker compose run --rm --no-deps app ruby -e 'exec "bundle", "lock", "--add-platform", Gem::Platform.local.to_s'
```

Esse comando pode atualizar o `Gemfile.lock` local. Em seguida:

```sh
docker compose run --rm app bin/setup --skip-server
```

O Compose inicia o PostgreSQL e aguarda sua disponibilidade. O setup instala as gems, prepara o banco, importa os dados e compila o Tailwind. A primeira execução pode demorar por causa dos downloads.

### 4. Inicie o projeto

```sh
docker compose up -d
docker compose ps
docker compose logs -f app
```

Acesse **http://localhost:3000**. Use `Ctrl+C` para sair dos logs; os containers continuam funcionando.

O Rails e o observador do Tailwind são iniciados pelo `bin/dev`. Os arquivos da pasta local são compartilhados com o container, permitindo editar no VS Code e acompanhar as alterações.

### 5. Confira os dados

```sh
docker compose exec app bin/rails runner 'puts [President.count, Administration.count, EconomicObservation.count].inspect'
```

Com o catálogo atual, o resultado esperado é `[8, 9, 30]`.

### Comandos do dia a dia

Execute na raiz do projeto:

| Objetivo | Comando |
| --- | --- |
| Iniciar | `docker compose up -d` |
| Parar | `docker compose stop` |
| Acompanhar logs | `docker compose logs -f app` |
| Console Rails | `docker compose exec app bin/rails console` |
| Terminal no container | `docker compose exec app bash` |
| Aplicar migrations | `docker compose exec app bin/rails db:migrate` |
| Recarregar catálogo | `docker compose exec app bin/rails db:seed` |
| Instalar gems após alterar o Gemfile | `docker compose run --rm app bundle install` |
| Reconstruir após alterar o Dockerfile.dev | `docker compose build` |
| Remover containers preservando volumes | `docker compose down` |

Após instalar gems ou reconstruir a imagem, execute `docker compose up -d` (ou `docker compose restart app` se apenas instalou gems).

### Persistência e configuração

O volume `postgres_data` preserva o banco e o volume `gems` preserva as gems. Não use `docker compose down -v` para uma parada comum: ele apaga esses volumes, incluindo o banco local.

A configuração de desenvolvimento utiliza PostgreSQL 18, host `postgres`, usuário `brasil` e senha `senha_local`, definidos no Compose. Essas credenciais são apenas para desenvolvimento. O banco não publica uma porta no Mac; a aplicação fica disponível em `127.0.0.1:3000`.

### Problemas comuns

- **Porta 3000 ocupada:** pare o processo que a utiliza ou altere o mapeamento no Compose para `127.0.0.1:3001:3000` e acesse `http://localhost:3001`.
- **Erro no build ou setup:** consulte a mensagem completa; não avance enquanto o comando falhar. Para o banco, consulte `docker compose logs postgres`.
- **Mudança em gems:** execute `bundle install` pelo container conforme a tabela e reinicie o serviço `app`.

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

## Coleta de dados

O dashboard não consulta APIs nem sites externos durante a navegação. Os dados são coletados e conferidos manualmente nas fontes, gravados em arquivos versionados no repositório e importados para o PostgreSQL. Assim, cada número exibido pode ser rastreado até um arquivo, e a aplicação funciona sem depender da disponibilidade de terceiros.

O fluxo tem quatro etapas:

1. **Coleta:** o dado é obtido na fonte (arquivo de dados abertos, API pública ou página oficial). Registramos a URL, o arquivo usado e, quando existir, a data de geração ou da consulta.
2. **Tratamento:** quando a fonte traz dados desagregados, eles são somados e os percentuais são recalculados com uma regra única, documentada em [db/data/README.md](db/data/README.md).
3. **Registro:** o resultado vai para `db/data/` (YAML ou JSON) ou para `config/candidate_portraits.json`, com a fonte ao lado de cada registro.
4. **Carga:** `bin/rails db:seed` lê os arquivos e grava tudo em uma única transação. A carga é idempotente: localiza registros por slug ou ano, atualiza o que mudou e não apaga o que não está nos arquivos.

| Arquivo | Conteúdo | Fonte | Como foi coletado |
| --- | --- | --- | --- |
| [administrations.yml](db/data/administrations.yml) | 8 presidentes e 9 períodos, com datas, partido, posição, economia, políticas e marcos | Legislação no Planalto, Banco Central, Senado | Curadoria editorial; cada governo lista as leis e páginas que sustentam seus destaques |
| [elections.yml](db/data/elections.yml) | 10 eleições (1985–2022): chapas, candidatos por turno, votos, percentuais e coligações | Portal de Dados Abertos do TSE; TREs para coligações e para 1998; TSE e STF para o Colégio Eleitoral de 1985 | Soma da votação presidencial (`CD_CARGO = 1`) por turno e candidatura nos arquivos por UF ou município/zona; em 1998, lista nacional do TRE-SC |
| [accessions.yml](db/data/accessions.yml) | Como cada presidente chegou ao poder (eleição direta, indireta ou sucessão) | Presidência, Arquivo Nacional, Senado, TRE-RJ | Texto editorial que referencia as eleições por ano; o seed resolve essas referências no JSONB `accession` |
| [ipca.json](db/data/ipca.json) | IPCA acumulado no ano, Brasil, 1995–2024 | API do SIDRA/IBGE, tabela 1737, variável 69 | Consulta ao mês de dezembro de cada ano, feita em 28/10/2026 |
| [candidate_portraits.json](config/candidate_portraits.json) | 59 retratos de candidatos e presidentes | TSE (38), Câmara dos Deputados (19), Senado (1), Biblioteca da Presidência (1) | Cópia local em `app/assets/images/portraits/`, com URL de origem, arquivo do pacote e crédito |

O gráfico **Esquerda versus Direita** não tem arquivo próprio: é calculado em `DashboardHelper#political_tenure_series` a partir das datas e posições de `administrations.yml`.

A exportação CSV reúne governos, resultados, alianças e fontes, e acompanha os filtros selecionados.

## Escolha das fontes

As fontes seguem esta ordem de preferência:

1. **Dado primário oficial e reprodutível.** Para votos, usamos os arquivos do Portal de Dados Abertos do TSE; para inflação, o SIDRA/IBGE; para leis, o texto no portal do Planalto. Com eles, qualquer pessoa pode refazer a conta e chegar ao mesmo número.
2. **Publicação oficial de outro órgão público**, quando o dado primário não existe ou está incompleto. Um exemplo é 1998, cuja lista nacional com os 12 candidatos vem da série histórica do TRE-SC. Também entram aqui Senado, Câmara, Presidência, Arquivo Nacional e Banco Central, para datas, sucessões e contexto.
3. **Referência acadêmica**, apenas como contexto. Bolognesi, Ribeiro e Codato (*Dados*, 2023), CEBRAP/NECI e FGV/CPDOC embasam a discussão sobre posições políticas. Os rótulos desses trabalhos não são aplicados automaticamente aos governos.

Alguns critérios valem para todas as fontes:

- **Uma base por eleição.** Os candidatos de uma eleição vêm todos da mesma totalização, sem misturar consolidações diferentes. Os percentuais são recalculados sobre os votos válidos da própria base.
- **Edição registrada.** O campo `results_source` guarda a URL, o arquivo e a data de geração. Os arquivos do TSE são reeditados com o tempo, então os números podem diferir de reportagens antigas.
- **Recortes declarados.** Quando a fonte tem lacunas, como a ausência dos votos do exterior em 1994, a lacuna aparece no perfil em vez de ser preenchida com outra fonte.
- **Só dados públicos necessários.** Do cadastro de candidaturas extraímos apenas nome, partido, número e situação. Retratos vêm de acervos oficiais identificados; quando não há foto confiável, a interface mostra as iniciais.
- **Julgamento editorial explícito.** Posições políticas, seleção de políticas e o agrupamento do centro no bloco azul do gráfico são escolhas editoriais e estão identificadas como tal.

Os detalhes por eleição, como arquivos, totais e casos especiais, estão em [db/data/README.md](db/data/README.md). A página **/metodologia** explica esses critérios para quem usa o dashboard.

### Atualizar ou acrescentar dados

1. Obtenha o dado na fonte de maior preferência disponível e anote a URL, o arquivo e a data de geração ou consulta.
2. Edite o arquivo correspondente em `db/data/`, preenchendo o campo de fonte do registro.
3. Se o tratamento for novo ou fugir da regra, documente-o em [db/data/README.md](db/data/README.md).
4. Recarregue com `docker compose exec app bin/rails db:seed` e rode os testes.

Como o seed não remove registros, apagar uma entrada do arquivo não a tira do banco. Nesse caso, remova o registro manualmente.

## Critérios de apresentação

FHC e os mandatos consecutivos de Lula e Dilma são agrupados por período contínuo. Lula a partir de 2023 tem registro próprio. As datas usam o último dia completo anterior à sucessão; as notas distinguem exercício e titularidade. Tancredo não entra na contagem, pois não exerceu o cargo.

As posições políticas são sínteses editoriais qualitativas. As políticas são uma seleção inicial, com cobertura até 2024 no período aberto em 2023. O gráfico econômico não atribui causalidade aos presidentes.

## Verificação

Com os serviços em execução:

```sh
docker compose exec app bin/rails test
docker compose exec app bin/rails zeitwerk:check
docker compose exec app bin/rails tailwindcss:build
```

Os testes de sistema (`bin/rails test:system`) precisam de um navegador Chrome acessível ao Selenium. A imagem de desenvolvimento fornecida não inclui Chrome; esses testes exigem configuração adicional de navegador no ambiente Docker.

## Estrutura principal

- `app/controllers/dashboard_controller.rb`: páginas, filtros e exportação.
- `app/models/`: presidentes, períodos e observações econômicas.
- `app/views/dashboard/`: dashboard, perfis, comparação e metodologia.
- `app/assets/tailwind/application.css`: tema e componentes.
- `app/javascript/controllers/navigation_controller.js`: menu móvel.
- `db/seeds.rb`: importação transacional dos arquivos locais.

O projeto está preparado para desenvolvimento local.
