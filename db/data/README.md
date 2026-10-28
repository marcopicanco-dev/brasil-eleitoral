# Base inicial

- `administrations.yml`: 8 presidentes e 9 períodos. Contém resumos editoriais, políticas selecionadas e links por governo.
- `ipca.json`: 30 valores oficiais do IPCA acumulado no ano, 1995–2024, Brasil, em percentual.
- `elections.yml`: 10 eleições presidenciais, de 1985 a 2022, com chapas, turnos, votos, percentuais, coligações e fontes.
- `accessions.yml`: forma de chegada ao poder em cada governo, com referências aos anos eleitorais. A carga resolve as referências antes de gravar o JSONB `accession`.

O IPCA foi obtido em 28/10/2026 na API do SIDRA/IBGE, tabela 1737, variável **69**, nível territorial **n1/all**, meses de dezembro (`AAAAMM`). Consulta de exemplo: <https://apisidra.ibge.gov.br/values/t/1737/n1/all/v/69/p/202412>. Não confundir com a variável 2266, que representa o número-índice.

Os dados ficam no PostgreSQL após `rtk bin/rails db:seed`. A carga usa slugs e anos únicos, dentro de uma transação, e pode ser executada novamente. Ela atualiza os registros do catálogo, sem apagar registros que não estejam nos arquivos.

O recorte das políticas do governo iniciado em 2023 vai até 2024. As classificações ideológicas são qualitativas, editoriais e discutíveis; não são dados oficiais nem resultados automáticos do artigo citado. Os critérios aparecem na página /metodologia.

Os limites diários usam o último dia completo antes da sucessão para manter períodos consecutivos sem sobreposição. As datas formais de posse, afastamento e titularidade são explicadas nos perfis.

## Resultados e alianças eleitorais

Os resultados mostram todos os candidatos de cada turno, em ordem de votação, com as situações especiais identificadas. O segundo turno contém somente os dois finalistas. Em 1985, os votos são do Colégio Eleitoral, sem percentual popular.

Para 1989, foi usado o recurso “Votação nominal por UF” de <https://dadosabertos.tse.jus.br/dataset/resultados-1989>: `votacao_candidato_uf_1989.zip`, sistema SISTOT, geração indicada no arquivo: 05/11/2012. Foram somados os votos por turno/candidato de todas as UFs, incluindo ZZ (exterior), sem duplicar uma linha nacional. Os totais nominais são 67.625.886 no primeiro turno e 66.166.009 no segundo. Os percentuais foram calculados sobre esses totais e arredondados a duas casas. Esta versão pode diferir de resumos históricos publicados anteriormente.

Nos anos de 1994, 2002, 2006, 2010, 2014, 2018 e 2022, são usados os arquivos de votação nominal por município/zona do Portal de Dados Abertos do TSE. Foi lido somente o arquivo `votacao_candidato_munzona_ANO_BR.csv`, filtrando `CD_CARGO = 1` e agrupando por turno/candidatura. O arquivo `_BRASIL.csv`, que agrega os arquivos de todas as unidades, não foi somado novamente. Os votos no exterior são incluídos quando presentes na fonte.

Para 1998, a lista nacional com os 12 candidatos e 67.722.475 votos foi obtida na série histórica do TRE-SC. Em 1994, os arquivos do TSE consultados abrangem as 27 UFs, sem ZZ (exterior), e somam 63.285.633 votos; o perfil informa esse recorte. Os totais coincidem com a lista completa do TRE-SC. Esta edição substitui a mistura anterior de resumos históricos e evita somar candidatos de consolidações diferentes.

Todos os percentuais são calculados a partir dos votos e do total válido da mesma fonte, com arredondamento a duas casas. Onde o CSV informa `QT_VOTOS_NOMINAIS_VALIDOS`, esse campo é utilizado; nas séries antigas, usa-se a votação nominal. Votos nulos e brancos ficam fora do denominador. Diferenças de centésimos em relação a notícias antigas podem decorrer do arredondamento ou da edição consultada.

O campo `results_source` registra a página da fonte, o arquivo usado e sua data de geração. Edições consultadas:

| Eleição | Geração do arquivo / publicação | Candidaturas no 1º turno |
| --- | --- | --- |
| 1989 | 05/11/2012 | 22 |
| 1994 | 13/02/2026 | 8 |
| 1998 | 07/08/2001 | 12 |
| 2002 | 18/03/2022 | 6 |
| 2006 | 13/05/2022 | 8 |
| 2010 | 19/07/2021 | 9 |
| 2014 | 28/07/2021 | 11 |
| 2018 | 13/11/2024 | 13 |
| 2022 | 28/10/2026 | 11 |

A base de 1989 inclui Armando Corrêa como `INAPTO`, com zero votos, e o identifica dessa forma na interface. Em 2006, a votação nominal tem sete candidatos; o cadastro oficial de candidaturas, arquivo `consulta_cand_2006_BR.csv`, também registra Rui Costa Pimenta (PCO, nº 29), inserido na urna e com registro `INDEFERIDO`. Ele é incluído na lista com `votes: null`, sem percentual e com a indicação de votos não computados. Não se confunde essa ausência de votação contabilizada com zero pessoas que votaram nele. Apenas nome, partido, número e situação são extraídos do cadastro; documentos pessoais não integram a aplicação.

As listas de partidos descrevem a coligação eleitoral, não a composição ministerial ou a base parlamentar posterior. Apoios individuais e informais no segundo turno não alteram retroativamente a lista de integrantes da coligação registrada. As siglas históricas são mantidas, com notas para a Frente Liberal de 1985, o PSD de 1998 e as federações de 2022.
