
-- Execute UM BLOCO POR VEZ (erros nos testes negativos sao esperados).
-- Se o Workbench parar no erro, execute o ROLLBACK separadamente.
-- Nenhuma alteracao deve ser confirmada; AUTO_INCREMENT pode avancar.
USE manutencao_industrial;

-- T01: conferir as 12 FKs e suas regras de exclusao/atualizacao.
SELECT TABLE_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME, UPDATE_RULE, DELETE_RULE
FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = DATABASE() ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- T02: DELETE RESTRICT. Esperado: erro 1451 (equipamento com dependencias).
START TRANSACTION;
DELETE FROM EQUIPAMENTO WHERE tag_equipamento = 1001;
ROLLBACK;

-- T03: DELETE RESTRICT em OS com historico. Esperado: erro 1451.
START TRANSACTION;
SET @os = (SELECT MIN(id_os) FROM LANCAMENTO_HORAS);
DELETE FROM ORDEM_SERVICO WHERE id_os = @os;
ROLLBACK;

-- T04: UPDATE CASCADE. Esperado: referencias passam de 1001 para 900001.
START TRANSACTION;
UPDATE EQUIPAMENTO SET tag_equipamento = 900001 WHERE tag_equipamento = 1001;
SELECT 'EQUIPAMENTO' AS tabela, COUNT(*) AS referencias FROM EQUIPAMENTO WHERE tag_equipamento = 900001
UNION ALL SELECT 'NOTIFICACAO', COUNT(*) FROM NOTIFICACAO WHERE id_equipamento = 900001
UNION ALL SELECT 'PLANO_MANUTENCAO', COUNT(*) FROM PLANO_MANUTENCAO WHERE id_equipamento = 900001
UNION ALL SELECT 'ORDEM_SERVICO', COUNT(*) FROM ORDEM_SERVICO WHERE id_equipamento = 900001;
ROLLBACK;
SELECT tag_equipamento, descricao FROM EQUIPAMENTO WHERE tag_equipamento = 1001;

-- T05: desativacao logica preserva historico. Esperado: ativo=0 e OS preservadas.
START TRANSACTION;
UPDATE EQUIPAMENTO SET ativo = FALSE WHERE tag_equipamento = 1001;
SELECT e.tag_equipamento,e.ativo,COUNT(o.id_os) AS ordens_preservadas
FROM EQUIPAMENTO e LEFT JOIN ORDEM_SERVICO o ON o.id_equipamento=e.tag_equipamento
WHERE e.tag_equipamento=1001 GROUP BY e.tag_equipamento,e.ativo;
ROLLBACK;

-- T06: FK impede equipamento inexistente. Esperado: erro 1452.
START TRANSACTION;
UPDATE NOTIFICACAO SET id_equipamento=999999 WHERE id_notificacao=1;
ROLLBACK;

-- T07: PK duplicada. Esperado: erro 1062.
START TRANSACTION;
UPDATE FUNCIONARIO SET id_funcionario=1 WHERE id_funcionario=2;
ROLLBACK;

-- T08: UNIQUE impede e-mail duplicado. Esperado: erro 1062.
START TRANSACTION;
SET @email = (SELECT email FROM FUNCIONARIO WHERE id_funcionario=1);
UPDATE FUNCIONARIO SET email=@email WHERE id_funcionario=2;
ROLLBACK;

-- T09: NOT NULL impede descricao ausente. Esperado: erro 1048.
START TRANSACTION;
UPDATE EQUIPAMENTO SET descricao=NULL WHERE tag_equipamento=1001;
ROLLBACK;

-- T10: CHECK impede recorrencia invalida. Esperado: erro 3819.
START TRANSACTION;
UPDATE PLANO_MANUTENCAO SET recorrencia_dias=0 WHERE id_plano=1;
ROLLBACK;

-- T11: CHECK impede tipo de OS invalido. Esperado: erro 3819.
START TRANSACTION;
UPDATE ORDEM_SERVICO SET tipo='M3' WHERE id_os=1;
ROLLBACK;

-- T12: M1 precisa de notificacao e nao pode ter plano. Esperado: erro 3819.
START TRANSACTION;
SET @m1=(SELECT MIN(id_os) FROM ORDEM_SERVICO WHERE tipo='M1');
UPDATE ORDEM_SERVICO SET id_notificacao=NULL WHERE id_os=@m1;
ROLLBACK;

-- T13: M2 precisa de plano e nao pode ter notificacao. Esperado: erro 3819.
START TRANSACTION;
SET @m2=(SELECT MIN(id_os) FROM ORDEM_SERVICO WHERE tipo='M2');
UPDATE ORDEM_SERVICO SET id_plano=NULL WHERE id_os=@m2;
ROLLBACK;

-- T14: retorno anterior a abertura. Esperado: erro 3819.
START TRANSACTION;
UPDATE ORDEM_SERVICO SET retorno_operacao=DATE_SUB(data_abertura,INTERVAL 1 HOUR) WHERE id_os=1;
ROLLBACK;

-- T15: fim do trabalho anterior ao inicio. Esperado: erro 3819.
START TRANSACTION;
UPDATE LANCAMENTO_HORAS SET fim=DATE_SUB(inicio,INTERVAL 1 HOUR) WHERE id_os_tecnico=1;
ROLLBACK;

-- T16: duracao divergente do apontamento. Esperado: erro 3819.
START TRANSACTION;
UPDATE LANCAMENTO_HORAS SET tempo_trabalhado='00:00:00' WHERE id_os_tecnico=1;
ROLLBACK;

-- T17: custo negativo. Esperado: erro 3819.
START TRANSACTION;
UPDATE OS_SERVICO SET valor_cobrado=-100 WHERE id_os_servico=1;
ROLLBACK;

-- T18: DEFAULT na notificacao. Esperado: ABERTO, P2, NULL.
START TRANSACTION;
INSERT INTO NOTIFICACAO(id_equipamento,id_funcionario,descricao)
VALUES (1001,1,'Inspecao de vibracao solicitada pela operacao');
SELECT id_notificacao,status,prioridade,inicio_indisponibilidade,data_criacao
FROM NOTIFICACAO WHERE id_notificacao=LAST_INSERT_ID();
ROLLBACK;

-- T19: exclusao de registro sem dependencias e permitida.
START TRANSACTION;
INSERT INTO NOTIFICACAO(id_equipamento,id_funcionario,descricao)
VALUES (1001,1,'Solicitacao de inspecao cancelada antes da abertura da OS');
SET @nova=LAST_INSERT_ID();
DELETE FROM NOTIFICACAO WHERE id_notificacao=@nova;
SELECT COUNT(*) AS registros_restantes FROM NOTIFICACAO WHERE id_notificacao=@nova;
ROLLBACK;

-- T20: auditoria de regra de negocio NAO garantida pelas FKs simples:
-- equipamento da OS precisa coincidir com o equipamento da origem.
-- Esperado na massa consistente: nenhuma linha. Nao prova bloqueio de escrita.
SELECT o.id_os,o.id_equipamento,n.id_equipamento AS equipamento_notificacao,
       p.id_equipamento AS equipamento_plano
FROM ORDEM_SERVICO o LEFT JOIN NOTIFICACAO n ON n.id_notificacao=o.id_notificacao
LEFT JOIN PLANO_MANUTENCAO p ON p.id_plano=o.id_plano
WHERE (o.tipo='M1' AND o.id_equipamento<>n.id_equipamento)
   OR (o.tipo='M2' AND o.id_equipamento<>p.id_equipamento);
-- Para impedir divergencias, seriam necessarias FKs compostas, triggers
-- ou validacao da aplicacao. A desativacao tambem nao bloqueia novas OS por si so.
