# Base inicial

- `administrations.yml`: 8 presidentes e 9 períodos. Contém resumos editoriais, políticas selecionadas e links por governo.
- `ipca.json`: 30 valores oficiais do IPCA acumulado no ano, 1995–2024, Brasil, em percentual.

O IPCA foi obtido em 28/10/2026 na API do SIDRA/IBGE, tabela 1737, variável **69**, nível territorial **n1/all**, meses de dezembro (`AAAAMM`). Consulta de exemplo: <https://apisidra.ibge.gov.br/values/t/1737/n1/all/v/69/p/202412>. Não confundir com a variável 2266, que representa o número-índice.

Os dados ficam no PostgreSQL após `rtk bin/rails db:seed`. A carga usa slugs e anos únicos, dentro de uma transação, e pode ser executada novamente. Ela atualiza os registros do catálogo, sem apagar registros que não estejam nos arquivos.

O recorte das políticas do governo iniciado em 2023 vai até 2024. As classificações ideológicas são qualitativas, editoriais e discutíveis; não são dados oficiais nem resultados automáticos do artigo citado. Os critérios aparecem na página /metodologia.

Os limites diários usam o último dia completo antes da sucessão para manter períodos consecutivos sem sobreposição. As datas formais de posse, afastamento e titularidade são explicadas nos perfis.
