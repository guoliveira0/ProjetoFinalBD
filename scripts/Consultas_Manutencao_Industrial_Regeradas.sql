
USE manutencao_industrial;

-- Q01 | SIMPLES | Supervisor: quais OS corretivas prioritarias ainda exigem acao?
-- Recursos: SELECT, WHERE, IN, ORDER BY, LIMIT.
SELECT id_os, id_equipamento, descricao, status, prioridade, data_abertura
FROM ORDEM_SERVICO
WHERE tipo='M1' AND status IN ('PLANEJADA','EM_EXECUCAO') AND prioridade='P1'
ORDER BY data_abertura ASC LIMIT 10;

-- Q02 | SIMPLES | PCM: quais planos preventivos vencem entre 10 e 30/11/2026?
-- Recursos: BETWEEN, WHERE, ORDER BY.
SELECT id_plano, id_equipamento, descricao, proxima_execucao, recorrencia_dias
FROM PLANO_MANUTENCAO
WHERE ativo=TRUE AND proxima_execucao BETWEEN '2026-11-10' AND '2026-11-30'
ORDER BY proxima_execucao, id_equipamento;

-- Q03 | SIMPLES | Operador: quais notificacoes citam vibracao?
-- Recursos: LIKE, ORDER BY.
SELECT id_notificacao, id_equipamento, descricao, data_criacao, prioridade
FROM NOTIFICACAO
WHERE descricao LIKE '%Vibração%'
ORDER BY data_criacao DESC;

-- Q04 | SIMPLES | Coordenacao: quais locais funcionais possuem equipamentos ativos?
-- Recursos: DISTINCT, WHERE, ORDER BY.
SELECT DISTINCT functional_location
FROM EQUIPAMENTO
WHERE ativo=TRUE ORDER BY functional_location;

-- Q05 | SIMPLES | PCM: quais servicos terceirizados ativos tem maior valor-base?
-- Recursos: WHERE, ORDER BY, LIMIT.
SELECT id_servico, nome, descricao, valor_base
FROM SERVICO
WHERE ativo=TRUE ORDER BY valor_base DESC LIMIT 8;

-- Q06 | JOIN 2 tabelas | PCM: quais OS corretivas estao abertas e em quais ativos?
-- INNER JOIN (2 tabelas).
SELECT o.id_os, e.tag_equipamento, e.descricao AS equipamento,
       o.prioridade, o.status, o.data_abertura
FROM ORDEM_SERVICO o
INNER JOIN EQUIPAMENTO e ON e.tag_equipamento=o.id_equipamento
WHERE o.tipo='M1' AND o.status <> 'CONCLUIDA'
ORDER BY o.prioridade, o.data_abertura;

-- Q07 | JOIN 2 tabelas | Supervisor: quantas OS por equipamento e quais os mais demandados?
-- INNER JOIN, GROUP BY, HAVING, COUNT, MAX.
SELECT e.tag_equipamento, e.descricao AS equipamento,
       COUNT(o.id_os) AS total_os, MAX(o.data_abertura) AS ultima_abertura
FROM EQUIPAMENTO e
INNER JOIN ORDEM_SERVICO o ON o.id_equipamento=e.tag_equipamento
GROUP BY e.tag_equipamento, e.descricao
HAVING COUNT(o.id_os)>=2
ORDER BY total_os DESC, e.tag_equipamento;

-- Q08 | JOIN 2 tabelas | Lider tecnico: quais tecnicos registraram mais horas-pessoa?
-- INNER JOIN, GROUP BY, SUM, COUNT.
-- Horas-pessoa NAO sao a duracao do reparo quando ha trabalho paralelo.
SELECT t.id_tecnico, t.nome, t.especialidade,
       COUNT(l.id_os_tecnico) AS apontamentos,
       ROUND(SUM(TIME_TO_SEC(l.tempo_trabalhado))/3600,2) AS horas_pessoa
FROM TECNICO t
INNER JOIN LANCAMENTO_HORAS l ON l.id_tecnico=t.id_tecnico
GROUP BY t.id_tecnico, t.nome, t.especialidade
ORDER BY horas_pessoa DESC, t.nome;

-- Q09 | JOIN 3 tabelas | Financeiro: quanto foi contratado de cada empresa?
-- INNER JOIN (OS_SERVICO, SERVICO, EMPRESA_TERCEIRIZADA), SUM, AVG, COUNT.
SELECT emp.id_empresa, emp.razao_social,
       COUNT(os.id_os_servico) AS contratacoes,
       ROUND(SUM(os.valor_cobrado),2) AS custo_total,
       ROUND(AVG(os.valor_cobrado),2) AS ticket_medio
FROM OS_SERVICO os
INNER JOIN SERVICO s ON s.id_servico=os.id_servico
INNER JOIN EMPRESA_TERCEIRIZADA emp ON emp.id_empresa=s.id_empresa
GROUP BY emp.id_empresa, emp.razao_social
ORDER BY custo_total DESC;

-- Q10 | JOIN 3 tabelas | Gestor: quais OS contrataram mais de um servico externo?
-- INNER JOIN (OS, OS_SERVICO, SERVICO), GROUP BY, HAVING, COUNT, SUM.
SELECT o.id_os, o.tipo, o.descricao,
       COUNT(DISTINCT s.id_servico) AS servicos_distintos,
       ROUND(SUM(os.valor_cobrado),2) AS custo_total
FROM ORDEM_SERVICO o
INNER JOIN OS_SERVICO os ON os.id_os=o.id_os
INNER JOIN SERVICO s ON s.id_servico=os.id_servico
GROUP BY o.id_os, o.tipo, o.descricao
HAVING COUNT(DISTINCT s.id_servico)>1
ORDER BY custo_total DESC;

-- Q11 | LEFT JOIN | PCM: quais equipamentos nao possuem OS em execucao?
-- LEFT JOIN inclui ativos sem correspondencia; bom para detectar lacunas.
SELECT e.tag_equipamento, e.descricao, COUNT(o.id_os) AS os_em_execucao
FROM EQUIPAMENTO e
LEFT JOIN ORDEM_SERVICO o ON o.id_equipamento=e.tag_equipamento
 AND o.status='EM_EXECUCAO'
WHERE e.ativo=TRUE
GROUP BY e.tag_equipamento,e.descricao
HAVING COUNT(o.id_os)=0
ORDER BY e.tag_equipamento;

-- Q12 | SUBQUERY | Gestor: quais OS terceirizadas custaram acima da media?
SELECT o.id_os, o.tipo, ROUND(SUM(os.valor_cobrado),2) AS custo_externo
FROM ORDEM_SERVICO o
INNER JOIN OS_SERVICO os ON os.id_os=o.id_os
GROUP BY o.id_os, o.tipo
HAVING SUM(os.valor_cobrado) > (
 SELECT AVG(t.custo) FROM (
  SELECT SUM(valor_cobrado) AS custo FROM OS_SERVICO GROUP BY id_os
 ) t
)
ORDER BY custo_externo DESC;

-- Q13 | MTTR DE REPARO (horas) | Eng. confiabilidade:
-- Qual o tempo medio de reparo por equipamento, usando OS M1 concluida?
-- Primeiro inicio ate ultimo fim por OS, NAO soma de horas-pessoa.
-- Premissa: lancamentos cobrem inicio/fim real do reparo e nao incluem
-- deslocamentos/esperas externos. A duracao pode incluir lacunas entre turnos.
WITH reparos AS (
 SELECT o.id_os,o.id_equipamento,
        MIN(l.inicio) AS inicio_reparo, MAX(l.fim) AS fim_reparo,
        COUNT(*) AS registros, COUNT(l.fim) AS registros_fechados
 FROM ORDEM_SERVICO o
 INNER JOIN LANCAMENTO_HORAS l ON l.id_os=o.id_os
 WHERE o.tipo='M1' AND o.status='CONCLUIDA' AND o.retorno_operacao IS NOT NULL
 GROUP BY o.id_os,o.id_equipamento
 HAVING registros=registros_fechados
)
SELECT e.tag_equipamento, e.descricao AS equipamento,
       COUNT(*) AS reparos,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE,r.inicio_reparo,r.fim_reparo))/60,2) AS mttr_horas,
       ROUND(MIN(TIMESTAMPDIFF(MINUTE,r.inicio_reparo,r.fim_reparo))/60,2) AS menor_reparo_h,
       ROUND(MAX(TIMESTAMPDIFF(MINUTE,r.inicio_reparo,r.fim_reparo))/60,2) AS maior_reparo_h
FROM reparos r INNER JOIN EQUIPAMENTO e ON e.tag_equipamento=r.id_equipamento
GROUP BY e.tag_equipamento,e.descricao
ORDER BY mttr_horas DESC;

-- Q14 | MTBF ENTRE FALHAS (horas operacionais) | Eng. confiabilidade:
-- Quanto tempo, em media, cada ativo opera entre falhas sucessivas?
-- Para cada falha concluida: retorno_operacao -> inicio da PROXIMA falha.
-- Premissa: ativo funciona continuamente entre eventos; sem paradas
-- planejadas/nao registradas. Conta intervalos completos, nao numero
-- de notificacoes. CTE LEAD exige MySQL 8.0+.
WITH eventos AS (
 SELECT o.id_equipamento, o.id_os, n.inicio_indisponibilidade,
        o.retorno_operacao,
        LEAD(n.inicio_indisponibilidade) OVER (
          PARTITION BY o.id_equipamento
          ORDER BY n.inicio_indisponibilidade,o.id_os
        ) AS proxima_falha
 FROM ORDEM_SERVICO o
 INNER JOIN NOTIFICACAO n ON n.id_notificacao=o.id_notificacao
 WHERE o.tipo='M1' AND n.inicio_indisponibilidade IS NOT NULL
), intervalos AS (
 SELECT id_equipamento,id_os,
        TIMESTAMPDIFF(MINUTE,retorno_operacao,proxima_falha) AS minutos_operacao
 FROM eventos
 WHERE retorno_operacao IS NOT NULL AND proxima_falha IS NOT NULL
       AND proxima_falha > retorno_operacao
)
SELECT e.tag_equipamento,e.descricao AS equipamento,
       COUNT(*) AS intervalos_completos,
       ROUND(SUM(i.minutos_operacao)/60,2) AS horas_operacionais_observadas,
       ROUND(AVG(i.minutos_operacao)/60,2) AS mtbf_horas
FROM intervalos i
INNER JOIN EQUIPAMENTO e ON e.tag_equipamento=i.id_equipamento
GROUP BY e.tag_equipamento,e.descricao
HAVING COUNT(*)>=2
ORDER BY mtbf_horas DESC;

-- Q15 | DISPONIBILIDADE (periodos de falha registrados) | Gestor:
-- Quanto tempo os ativos ficaram indisponiveis por falhas ja reparadas?
-- Nao e disponibilidade global: faltam calendario e paradas planejadas.
SELECT e.tag_equipamento,e.descricao,
       COUNT(*) AS falhas_reparadas,
       ROUND(SUM(TIMESTAMPDIFF(MINUTE,n.inicio_indisponibilidade,o.retorno_operacao))/60,2)
          AS horas_indisponiveis,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE,n.inicio_indisponibilidade,o.retorno_operacao))/60,2)
          AS tempo_medio_restauracao_h
FROM ORDEM_SERVICO o
INNER JOIN NOTIFICACAO n ON n.id_notificacao=o.id_notificacao
INNER JOIN EQUIPAMENTO e ON e.tag_equipamento=o.id_equipamento
WHERE o.tipo='M1' AND o.status='CONCLUIDA'
 AND n.inicio_indisponibilidade IS NOT NULL
 AND o.retorno_operacao >= n.inicio_indisponibilidade
GROUP BY e.tag_equipamento,e.descricao
ORDER BY horas_indisponiveis DESC;

-- Q16 | CUSTO + MAO DE OBRA | Gestor: quais OS exigiram mais recursos?
-- Pre-agregacao evita multiplicar custos e horas ao cruzar duas tabelas N:N.
WITH horas AS (
 SELECT id_os, ROUND(SUM(TIME_TO_SEC(tempo_trabalhado))/3600,2) horas_pessoa
 FROM LANCAMENTO_HORAS GROUP BY id_os
), custos AS (
 SELECT id_os,ROUND(SUM(valor_cobrado),2) custo_externo
 FROM OS_SERVICO GROUP BY id_os
)
SELECT o.id_os,o.tipo,o.status,e.descricao AS equipamento,
       COALESCE(h.horas_pessoa,0) AS horas_pessoa,
       COALESCE(c.custo_externo,0) AS custo_externo
FROM ORDEM_SERVICO o
INNER JOIN EQUIPAMENTO e ON e.tag_equipamento=o.id_equipamento
LEFT JOIN horas h ON h.id_os=o.id_os
LEFT JOIN custos c ON c.id_os=o.id_os
WHERE h.id_os IS NOT NULL OR c.id_os IS NOT NULL
ORDER BY custo_externo DESC, horas_pessoa DESC LIMIT 20;
