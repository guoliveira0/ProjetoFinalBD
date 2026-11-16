# SISTEMA DE GESTÃO DE MANUTENÇÃO INDUSTRIAL

## 1. Capa e identificação

**CENTRO UNIVERSITÁRIO FIPMOC**  
**Curso:** Engenharia de Computação  
**Disciplina:** Modelagem Relacional de Banco de Dados  
**Semestre letivo:** 6º semestre de 2026  
**Título:** Projeto Final — Modelo Relacional de Banco de Dados: Sistema de Gestão de Manutenção Industrial  
**Integrantes:** Luiz Gustavo Oliveira Santos e Gabriel Soares Fonseca  
**Local:** Montes Claros — MG  
**Ano:** 2026

---

## 2. Resumo executivo

Este trabalho apresenta a modelagem de um banco de dados relacional para um sistema de gestão de manutenção industrial, com foco no cadastro de equipamentos, registro de notificações de falhas, programação de manutenções preventivas e acompanhamento de ordens de serviço. As ordens são classificadas como **M1 (corretivas)**, vinculadas a notificações, ou **M2 (preventivas)**, vinculadas a planos de manutenção.

O modelo final, elaborado em UML/DER, contém **10 tabelas** e contempla o registro das horas trabalhadas por técnicos e a contratação de serviços de empresas terceirizadas. O projeto foi concebido para implementação no MySQL, com relacionamentos 1:N e dois relacionamentos N:N resolvidos por tabelas associativas.

## 3. Domínio e regras de negócio

### 3.1. Cenário de aplicação

Em um ambiente industrial, equipamentos exigem inspeções periódicas e intervenções corretivas. O sistema centraliza as informações necessárias para acompanhar essas atividades. O funcionário cadastra equipamentos e registra notificações; os planos definem recorrências preventivas; as ordens de serviço formalizam as manutenções; os técnicos registram suas atividades e horas; e serviços externos podem ser contratados de empresas terceirizadas.

### 3.2. Entidades do domínio

- **FUNCIONARIO:** dados cadastrais e credenciais dos funcionários.
- **EQUIPAMENTO:** identificação, descrição, localização funcional e data de instalação.
- **PLANO_MANUTENCAO:** periodicidade, última execução e próxima execução prevista.
- **NOTIFICACAO:** comunicação de falha ou necessidade de manutenção.
- **ORDEM_SERVICO:** acompanhamento das intervenções M1 e M2.
- **TECNICO:** dados dos profissionais que executam atividades.
- **APONTAMENTO_HORAS:** horas e atividades realizadas por técnico em cada OS.
- **EMPRESA_TERCEIRIZADA:** cadastro de prestadores externos.
- **SERVICO:** catálogo de serviços externos oferecidos.
- **OS_SERVICO:** contratação de serviços para determinada OS.

### 3.3. Regras de negócio

**RN01.** Um funcionário pode cadastrar vários equipamentos; cada equipamento registra um funcionário responsável pelo cadastro.

**RN02.** Cada notificação refere-se a um equipamento e ao funcionário que a registrou.

**RN03.** Um equipamento pode possuir vários planos de manutenção, notificações e ordens de serviço.

**RN04.** Uma OS do tipo **M1** deve ter `id_notificacao` preenchido e `id_plano` nulo.

**RN05.** Uma OS do tipo **M2** deve ter `id_plano` preenchido e `id_notificacao` nulo. A emissão automática de ordens quando chegar `proxima_execucao` depende de rotina de aplicação ou agendamento, não apenas do esquema relacional.

**RN06.** O equipamento indicado na OS deve ser o mesmo da notificação ou do plano que a originou.

**RN07.** Um técnico pode realizar vários apontamentos em uma mesma OS. Cada apontamento registra início, fim, duração e descrição da atividade. A duração deve corresponder ao intervalo entre início e fim.

**RN08.** Uma OS pode conter apontamentos de vários técnicos; assim, `APONTAMENTO_HORAS` materializa o relacionamento N:N entre técnico e OS. Ela registra execução, não designação antecipada de técnicos.

**RN09.** Os registros em `SERVICO` representam serviços terceirizados. Uma empresa pode oferecer vários serviços; cada serviço deve estar vinculado a uma empresa.

**RN10.** Uma OS pode contratar vários serviços e um serviço pode ser contratado em várias ordens. `OS_SERVICO` registra o valor efetivamente cobrado, distinto do valor-base do catálogo.

**RN11.** Os campos `senha_hash` devem guardar hashes de senha produzidos por algoritmo adequado, nunca senhas em texto puro.

## 4. Diagrama de classes / DER

**Figura 1 — Diagrama de classes/DER final.** As caixas representam as tabelas, seus atributos e as indicações de PK/FK. As linhas com `1` e `N` representam os relacionamentos um-para-muitos. As tabelas `APONTAMENTO_HORAS` e `OS_SERVICO` resolvem os relacionamentos muitos-para-muitos.

## 5. Dicionário de dados

As tabelas a seguir reproduzem os nomes e tipos da imagem. **PK** = chave primária; **FK** = chave estrangeira; **NULL** = valor opcional.

### 5.1. FUNCIONARIO

| Atributo | Tipo | Restrições no DER | Descrição |
|---|---|---|---|
| `id_funcionario` | INT | PK | Identificador do funcionário. |
| `nome` | VARCHAR(120) | — | Nome completo. |
| `cargo` | VARCHAR(50) | — | Cargo exercido. |
| `email` | VARCHAR(120) | — | E-mail de contato e acesso. |
| `telefone` | VARCHAR(20) | — | Telefone de contato. |
| `ativo` | BOOLEAN | — | Situação do cadastro. |
| `senha_hash` | VARCHAR(255) | — | Hash da senha de acesso. |

### 5.2. EQUIPAMENTO

| Atributo | Tipo | Restrições no DER | Descrição |
|---|---|---|---|
| `tag_equipamento` | INT | PK | Identificador do equipamento. |
| `id_funcionario` | INT | FK → `FUNCIONARIO.id_funcionario` | Funcionário que cadastrou o equipamento. |
| `descricao` | VARCHAR(200) | — | Descrição do equipamento. |
| `functional_location` | VARCHAR(100) | — | Localização funcional na planta. |
| `data_instalacao` | DATE | — | Data de instalação. |
| `ativo` | BOOLEAN | — | Situação do equipamento. |

### 5.3. PLANO_MANUTENCAO

| Atributo | Tipo | Restrições no DER | Descrição |
|---|---|---|---|
| `id_plano` | INT | PK | Identificador do plano. |
| `id_equipamento` | INT | FK → `EQUIPAMENTO.tag_equipamento` | Equipamento abrangido. |
| `descricao` | VARCHAR(200) | — | Descrição da manutenção planejada. |
| `recorrencia_dias` | INT | — | Intervalo entre execuções, em dias. |
| `ultima_execucao` | DATE | — | Data da última execução. |
| `proxima_execucao` | DATE | — | Data programada para a próxima execução. |
| `ativo` | BOOLEAN | — | Situação do plano. |

### 5.4. NOTIFICACAO

| Atributo | Tipo | Restrições no DER | Descrição |
|---|---|---|---|
| `id_notificacao` | INT | PK | Identificador da notificação. |
| `id_equipamento` | INT | FK → `EQUIPAMENTO.tag_equipamento` | Equipamento afetado. |
| `id_funcionario` | INT | FK → `FUNCIONARIO.id_funcionario` | Funcionário que abriu a notificação. |
| `descricao` | VARCHAR(200) | — | Relato da ocorrência. |
| `data_criacao` | DATETIME | — | Data e hora de criação. |
| `status` | VARCHAR(20) | — | Situação da notificação. |
| `prioridade` | VARCHAR(10) | — | Prioridade do atendimento. |

### 5.5. ORDEM_SERVICO

| Atributo | Tipo | Restrições no DER | Descrição |
|---|---|---|---|
| `id_os` | INT | PK | Identificador da OS. |
| `id_equipamento` | INT | FK → `EQUIPAMENTO.tag_equipamento` | Equipamento que receberá a manutenção. |
| `id_notificacao` | INT | FK, NULL → `NOTIFICACAO.id_notificacao` | Origem da OS M1. |
| `id_plano` | INT | FK, NULL → `PLANO_MANUTENCAO.id_plano` | Origem da OS M2. |
| `tipo` | VARCHAR(2) | M1/M2 | Tipo de manutenção. |
| `descricao` | VARCHAR(200) | — | Descrição da intervenção. |
| `data_abertura` | DATETIME | — | Data e hora de abertura. |
| `data_fechamento` | DATETIME | — | Data e hora de encerramento. |
| `status` | VARCHAR(20) | — | Situação da OS. |
| `prioridade` | VARCHAR(10) | — | Prioridade da OS. |

### 5.6. TECNICO

| Atributo | Tipo | Restrições no DER | Descrição |
|---|---|---|---|
| `id_tecnico` | INT | PK | Identificador do técnico. |
| `nome` | VARCHAR(120) | — | Nome completo. |
| `especialidade` | VARCHAR(100) | — | Área de atuação técnica. |
| `telefone` | VARCHAR(20) | — | Telefone de contato. |
| `email` | VARCHAR(120) | — | E-mail de contato e acesso. |
| `ativo` | BOOLEAN | — | Situação do cadastro. |
| `senha_hash` | VARCHAR(255) | — | Hash da senha de acesso. |

### 5.7. APONTAMENTO_HORAS

| Atributo | Tipo | Restrições no DER | Descrição |
|---|---|---|---|
| `id_os_tecnico` | INT | PK | Identificador do apontamento, conforme nome usado no DER. |
| `id_os` | INT | FK → `ORDEM_SERVICO.id_os` | OS na qual ocorreu a atividade. |
| `id_tecnico` | INT | FK → `TECNICO.id_tecnico` | Técnico executor. |
| `inicio` | DATETIME | — | Data e hora de início. |
| `fim` | DATETIME | — | Data e hora de término. |
| `tempo_trabalhado` | TIME | — | Duração registrada, no formato HH:MM:SS. |
| `descricao_atividade` | VARCHAR(200) | — | Descrição do trabalho realizado. |

### 5.8. EMPRESA_TERCEIRIZADA

| Atributo | Tipo | Restrições no DER | Descrição |
|---|---|---|---|
| `id_empresa` | INT | PK | Identificador da prestadora. |
| `razao_social` | VARCHAR(100) | — | Razão social da empresa. |
| `cnpj` | VARCHAR(14) | — | CNPJ sem pontuação. |
| `email` | VARCHAR(100) | — | E-mail de contato da empresa. |

### 5.9. SERVICO

| Atributo | Tipo | Restrições no DER | Descrição |
|---|---|---|---|
| `id_servico` | INT | PK | Identificador do serviço terceirizado. |
| `nome` | VARCHAR(100) | — | Nome do serviço. |
| `descricao` | TEXT | — | Descrição detalhada. |
| `valor_base` | DECIMAL | — | Preço de referência. |
| `ativo` | BOOLEAN | — | Situação do serviço no catálogo. |
| `id_empresa` | INT | FK | Empresa que oferece o serviço; deve referenciar `EMPRESA_TERCEIRIZADA.id_empresa`. |

### 5.10. OS_SERVICO

| Atributo | Tipo | Restrições no DER | Descrição |
|---|---|---|---|
| `id_os_servico` | INT | PK | Identificador da contratação. |
| `id_os` | INT | FK → `ORDEM_SERVICO.id_os` | OS que contratou o serviço. |
| `id_servico` | INT | FK → `SERVICO.id_servico` | Serviço contratado. |
| `valor_cobrado` | DECIMAL | — | Valor efetivamente cobrado na OS. |

### 5.11. Resumo dos relacionamentos

| Entidade de origem | Entidade de destino | Cardinalidade |
|---|---|---|
| FUNCIONARIO | EQUIPAMENTO | 1:N |
| FUNCIONARIO | NOTIFICACAO | 1:N |
| EQUIPAMENTO | PLANO_MANUTENCAO | 1:N |
| EQUIPAMENTO | NOTIFICACAO | 1:N |
| EQUIPAMENTO | ORDEM_SERVICO | 1:N |
| PLANO_MANUTENCAO | ORDEM_SERVICO | 1:N, FK opcional na OS |
| NOTIFICACAO | ORDEM_SERVICO | 1:N, FK opcional na OS |
| TECNICO | APONTAMENTO_HORAS | 1:N |
| ORDEM_SERVICO | APONTAMENTO_HORAS | 1:N |
| EMPRESA_TERCEIRIZADA | SERVICO | 1:N |
| SERVICO | OS_SERVICO | 1:N |
| ORDEM_SERVICO | OS_SERVICO | 1:N |

## 6. Justificativa da normalização

### Primeira Forma Normal (1FN)

Os campos representam valores atômicos e cada tabela possui identificador primário. Em vez de armazenar uma lista de técnicos ou serviços em uma única célula de `ORDEM_SERVICO`, cada participação ou contratação é registrada em linha própria.

### Segunda Forma Normal (2FN)

As tabelas utilizam chaves primárias simples, e seus atributos descritivos dependem da identificação do registro. As associações N:N não são representadas por colunas repetidas, mas pelas tabelas `APONTAMENTO_HORAS` e `OS_SERVICO`.

### Terceira Forma Normal (3FN)

Os dados cadastrais de empresas ficam em `EMPRESA_TERCEIRIZADA`, e não são repetidos em cada contratação. O catálogo `SERVICO` referencia a empresa por FK; `OS_SERVICO` registra a relação contratual e o valor cobrado.

**Exemplo de decomposição:** suponha uma tabela inicial `SERVICO_EXTERNO(id_servico, nome_servico, cnpj_empresa, razao_social, email_empresa)`. Quando uma empresa oferece diversos serviços, `razao_social` e `email_empresa` são repetidos. Além disso, a identificação da empresa determina seus dados cadastrais, caracterizando uma dependência transitiva em relação ao serviço. A decomposição proposta é:

```text
EMPRESA_TERCEIRIZADA(id_empresa PK, razao_social, cnpj, email)
SERVICO(id_servico PK, id_empresa FK, nome, descricao, valor_base, ativo)
```

Assim, os dados da empresa são mantidos em um único lugar.

## 8. Instruções de execução no MySQL

### 8.1. Pré-requisitos

1. Instalar o **MySQL Server 8.0 ou superior** e, opcionalmente, o MySQL Workbench.
2. Ter um usuário com permissão para criar banco de dados e tabelas.
3. Preparar um script de criação das tabelas (`schema.sql`) e, se necessário, um script de dados (`dados.sql`). **Esses scripts não fazem parte do diagrama nem estão incluídos neste relatório.**


### 8.2. Criar o banco de dados

No MySQL Workbench ou terminal SQL:

```sql
CREATE DATABASE IF NOT EXISTS manutencao_industrial
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE manutencao_industrial;
```

### 8.3. Importar os scripts quando estiverem disponíveis

No terminal do sistema operacional, executar:

```bash
mysql -u root -p manutencao_industrial < schema.sql
mysql -u root -p manutencao_industrial < dados.sql
```

Ou, no **MySQL Workbench**, abrir o arquivo `.sql`, selecionar o banco `manutencao_industrial` e executar o script. O arquivo `dados.sql` é opcional, mas necessário para produzir resultados com registros reais.

### 8.4. Ordem recomendada de criação das tabelas

1. `FUNCIONARIO`, `TECNICO`, `EMPRESA_TERCEIRIZADA`.
2. `EQUIPAMENTO` e `SERVICO` (com `id_empresa`).
3. `PLANO_MANUTENCAO` e `NOTIFICACAO`.
4. `ORDEM_SERVICO`.
5. `APONTAMENTO_HORAS` e `OS_SERVICO`.

Essa ordem respeita as dependências das chaves estrangeiras.

### 8.5. Conferência

```sql
USE manutencao_industrial;
SHOW TABLES;
DESCRIBE ORDEM_SERVICO;
DESCRIBE APONTAMENTO_HORAS;
SELECT COUNT(*) AS total_os FROM ORDEM_SERVICO;
```

Após a criação e a carga de dados, executar as consultas da seção 7.

## 9. Considerações finais

A modelagem consolidou dez entidades para atender ao cenário de manutenção industrial, diferenciando as ordens corretivas (M1) das preventivas (M2). Entre as principais decisões de projeto estão o uso de `APONTAMENTO_HORAS` como tabela associativa entre técnicos e ordens, a separação das empresas terceirizadas de seus serviços e a exclusão do controle de materiais, que não faz parte do escopo final.

Os principais desafios técnicos a observar na implementação são a integridade das FKs opcionais de `ORDEM_SERVICO`, a coerência entre o equipamento da OS e o equipamento da origem M1/M2, o cálculo confiável do tempo trabalhado e a inclusão da FK `id_empresa` em `SERVICO`, ausente na imagem final. Como evoluções futuras, podem ser implementadas geração automática de ordens preventivas, perfis de acesso, dashboards de indicadores, auditoria de alterações e relatórios de custos e produtividade.

## 10. Referências bibliográficas

ELMASRI, Ramez; NAVATHE, Shamkant B. **Sistemas de banco de dados**. 7. ed. São Paulo: Pearson, 2019.

SILBERSCHATZ, Abraham; KORTH, Henry F.; SUDARSHAN, S. **Database system concepts**. 7. ed. New York: McGraw-Hill, 2019.

ORACLE. **MySQL 8.4 Reference Manual**. Disponível em: https://dev.mysql.com/doc/refman/8.4/en/. Acesso em: 16 nov. 2026.

ORACLE. **MySQL 8.4 Reference Manual: CREATE TABLE Statement**. Disponível em: https://dev.mysql.com/doc/refman/8.4/en/create-table.html. Acesso em: 16 nov. 2026.

ORACLE. **MySQL 8.4 Reference Manual: FOREIGN KEY Constraints**. Disponível em: https://dev.mysql.com/doc/refman/8.4/en/create-table-foreign-keys.html. Acesso em: 16 nov. 2026.

ORACLE. **MySQL 8.4 Reference Manual: Date and Time Functions**. Disponível em: https://dev.mysql.com/doc/refman/8.4/en/date-and-time-functions.html. Acesso em: 16 nov. 2026.
