
DROP DATABASE IF EXISTS manutencao_industrial;
CREATE DATABASE manutencao_industrial
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE manutencao_industrial;

-- ORDEM DE CRIACAO: primeiro entidades independentes; depois entidades
-- dependentes; por ultimo tabelas associativas. Todas as FKs incluem
-- explicitamente ON DELETE e ON UPDATE.

CREATE TABLE FUNCIONARIO (
  id_funcionario INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(120) NOT NULL,
  cargo VARCHAR(50) NOT NULL,
  email VARCHAR(120) NOT NULL UNIQUE,
  telefone VARCHAR(20) UNIQUE,
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  senha_hash VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE TECNICO (
  id_tecnico INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(120) NOT NULL,
  especialidade VARCHAR(100) NOT NULL,
  telefone VARCHAR(20) NOT NULL UNIQUE,
  email VARCHAR(120) NOT NULL UNIQUE,
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  senha_hash VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE EMPRESA_TERCEIRIZADA (
  id_empresa INT AUTO_INCREMENT PRIMARY KEY,
  razao_social VARCHAR(100) NOT NULL,
  cnpj VARCHAR(14) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE EQUIPAMENTO (
  tag_equipamento INT AUTO_INCREMENT PRIMARY KEY,
  id_funcionario INT NOT NULL,
  descricao VARCHAR(200) NOT NULL,
  functional_location VARCHAR(100) NOT NULL,
  data_instalacao DATE NOT NULL,
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_equipamento_funcionario FOREIGN KEY (id_funcionario)
    REFERENCES FUNCIONARIO(id_funcionario)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE PLANO_MANUTENCAO (
  id_plano INT AUTO_INCREMENT PRIMARY KEY,
  id_equipamento INT NOT NULL,
  descricao VARCHAR(200) NOT NULL,
  recorrencia_dias INT NOT NULL,
  ultima_execucao DATE NULL,
  proxima_execucao DATE NOT NULL,
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT chk_plano_recorrencia CHECK (recorrencia_dias > 0),
  CONSTRAINT fk_plano_equipamento FOREIGN KEY (id_equipamento)
    REFERENCES EQUIPAMENTO(tag_equipamento)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE NOTIFICACAO (
  id_notificacao INT AUTO_INCREMENT PRIMARY KEY,
  id_equipamento INT NOT NULL,
  id_funcionario INT NOT NULL,
  descricao VARCHAR(200) NOT NULL,
  data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(20) NOT NULL DEFAULT 'ABERTO',
  prioridade VARCHAR(2) NOT NULL DEFAULT 'P2',
  inicio_indisponibilidade DATETIME NULL,
  CONSTRAINT chk_notificacao_parada CHECK (inicio_indisponibilidade IS NULL OR inicio_indisponibilidade <= data_criacao),
  CONSTRAINT chk_notificacao_prioridade CHECK (prioridade IN ('P1', 'P2')),
  CONSTRAINT chk_notificacao_status CHECK (status IN ('ABERTO','EM_ANALISE','FECHADA')),
  CONSTRAINT fk_notificacao_equipamento FOREIGN KEY (id_equipamento)
    REFERENCES EQUIPAMENTO(tag_equipamento)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_notificacao_funcionario FOREIGN KEY (id_funcionario)
    REFERENCES FUNCIONARIO(id_funcionario)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE SERVICO (
  id_servico INT AUTO_INCREMENT PRIMARY KEY,
  id_empresa INT NOT NULL,
  nome VARCHAR(100) NOT NULL,
  descricao VARCHAR(200) NOT NULL,
  valor_base DECIMAL(10,2) NOT NULL,
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT chk_servico_valor_base CHECK (valor_base > 0),
  CONSTRAINT fk_servico_empresa FOREIGN KEY (id_empresa)
    REFERENCES EMPRESA_TERCEIRIZADA(id_empresa)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE ORDEM_SERVICO (
  id_os INT AUTO_INCREMENT PRIMARY KEY,
  id_equipamento INT NOT NULL,
  id_notificacao INT NULL,
  id_plano INT NULL,
  tipo VARCHAR(2) NOT NULL,
  descricao VARCHAR(200) NOT NULL,
  data_abertura DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  data_fechamento DATETIME NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PLANEJADA',
  prioridade VARCHAR(10) NOT NULL DEFAULT 'P2',
  retorno_operacao DATETIME NULL,
  CONSTRAINT chk_os_retorno CHECK (retorno_operacao IS NULL OR retorno_operacao >= data_abertura),
  CONSTRAINT chk_os_tipo CHECK (tipo IN ('M1','M2')),
  CONSTRAINT chk_os_origem CHECK (
    (tipo = 'M1' AND id_notificacao IS NOT NULL AND id_plano IS NULL)
    OR
    (tipo = 'M2' AND id_plano IS NOT NULL AND id_notificacao IS NULL)
  ),
  CONSTRAINT chk_os_datas CHECK (data_fechamento IS NULL OR data_fechamento >= data_abertura),
  CONSTRAINT chk_os_status CHECK (status IN ('PLANEJADA','EM_EXECUCAO','CONCLUIDA')),
  CONSTRAINT chk_os_prioridade CHECK (prioridade IN ('P1','P2')),
  CONSTRAINT fk_os_equipamento FOREIGN KEY (id_equipamento)
    REFERENCES EQUIPAMENTO(tag_equipamento)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_os_notificacao FOREIGN KEY (id_notificacao)
    REFERENCES NOTIFICACAO(id_notificacao)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_os_plano FOREIGN KEY (id_plano)
    REFERENCES PLANO_MANUTENCAO(id_plano)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE LANCAMENTO_HORAS (
  id_os_tecnico INT AUTO_INCREMENT PRIMARY KEY,
  id_os INT NOT NULL,
  id_tecnico INT NOT NULL,
  inicio DATETIME NOT NULL,
  fim DATETIME NOT NULL,
  tempo_trabalhado TIME NOT NULL,
  descricao_atividade VARCHAR(200) NOT NULL,
  CONSTRAINT chk_lancamento_horario CHECK (fim > inicio),
  CONSTRAINT chk_lancamento_tempo CHECK (
    TIME_TO_SEC(tempo_trabalhado) = TIMESTAMPDIFF(SECOND, inicio, fim)
  ),
  CONSTRAINT fk_lancamento_os FOREIGN KEY (id_os)
    REFERENCES ORDEM_SERVICO(id_os)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_lancamento_tecnico FOREIGN KEY (id_tecnico)
    REFERENCES TECNICO(id_tecnico)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE OS_SERVICO (
  id_os_servico INT AUTO_INCREMENT PRIMARY KEY,
  id_os INT NOT NULL,
  id_servico INT NOT NULL,
  valor_cobrado DECIMAL(10,2) NOT NULL,
  CONSTRAINT chk_os_servico_valor CHECK (valor_cobrado > 0),
  CONSTRAINT fk_os_servico_os FOREIGN KEY (id_os)
    REFERENCES ORDEM_SERVICO(id_os)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_os_servico_servico FOREIGN KEY (id_servico)
    REFERENCES SERVICO(id_servico)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

START TRANSACTION;

INSERT INTO FUNCIONARIO (id_funcionario, nome, cargo, email, telefone, ativo, senha_hash) VALUES
  (1, 'Ana Paula Martins', 'Engenheira de Manutenção', 'ana.martins@fabricaexemplo.com.br', '31988010001', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (2, 'Bruno Henrique Lopes', 'Supervisor de Produção', 'bruno.lopes@fabricaexemplo.com.br', '31988010002', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (3, 'Carla Mendes Ribeiro', 'Planejadora de Manutenção', 'carla.ribeiro@fabricaexemplo.com.br', '31988010003', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (4, 'Diego Alves Rocha', 'Operador de Produção', 'diego.rocha@fabricaexemplo.com.br', '31988010004', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (5, 'Eduarda Costa Lima', 'Engenheira de Processos', 'eduarda.lima@fabricaexemplo.com.br', '31988010005', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (6, 'Felipe Augusto Nunes', 'Supervisor de Utilidades', 'felipe.nunes@fabricaexemplo.com.br', '31988010006', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (7, 'Gabriela Souza Pinto', 'Analista de PCM', 'gabriela.pinto@fabricaexemplo.com.br', '31988010007', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (8, 'Henrique Barbosa Reis', 'Operador de Caldeira', 'henrique.reis@fabricaexemplo.com.br', '31988010008', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (9, 'Isabela Ferreira Dias', 'Coordenadora Industrial', 'isabela.dias@fabricaexemplo.com.br', '31988010009', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (10, 'João Pedro Cardoso', 'Operador de Envase', 'joao.cardoso@fabricaexemplo.com.br', '31988010010', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (11, 'Larissa Oliveira Freitas', 'Técnica de Qualidade', 'larissa.freitas@fabricaexemplo.com.br', '31988010011', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (12, 'Marcos Vinícius Teixeira', 'Líder de Turno', 'marcos.teixeira@fabricaexemplo.com.br', '31988010012', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (13, 'Natália Gomes Azevedo', 'Engenheira de Automação', 'natalia.azevedo@fabricaexemplo.com.br', '31988010013', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (14, 'Otávio Rodrigues Melo', 'Operador de Tratamento', 'otavio.melo@fabricaexemplo.com.br', '31988010014', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (15, 'Patrícia Almeida Castro', 'Analista de Produção', 'patricia.castro@fabricaexemplo.com.br', '31988010015', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.');

INSERT INTO TECNICO (id_tecnico, nome, especialidade, telefone, email, ativo, senha_hash) VALUES
  (1, 'Rafael Monteiro', 'Mecânica industrial', '31987020001', 'tecnico01@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (2, 'Camila Duarte', 'Elétrica industrial', '31987020002', 'tecnico02@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (3, 'Lucas Ferreira', 'Instrumentação', '31987020003', 'tecnico03@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (4, 'Mariana Azevedo', 'Automação industrial', '31987020004', 'tecnico04@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (5, 'André Ribeiro', 'Mecânica de bombas', '31987020005', 'tecnico05@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (6, 'Beatriz Carvalho', 'Manutenção de utilidades', '31987020006', 'tecnico06@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (7, 'Pedro Henrique Lima', 'Mecânica de transportadores', '31987020007', 'tecnico07@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (8, 'Juliana Martins', 'Calibração de instrumentos', '31987020008', 'tecnico08@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (9, 'Gustavo Rocha', 'Eletrotécnica', '31987020009', 'tecnico09@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (10, 'Fernanda Alves', 'Manutenção de compressores', '31987020010', 'tecnico10@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (11, 'Ricardo Santos', 'Manutenção de caldeiras', '31987020011', 'tecnico11@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (12, 'Aline Costa', 'Mecânica de máquinas', '31987020012', 'tecnico12@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (13, 'Vinícius Oliveira', 'Diagnóstico de inversores', '31987020013', 'tecnico13@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (14, 'Sofia Almeida', 'Manutenção de processos', '31987020014', 'tecnico14@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.'),
  (15, 'Daniel Barbosa', 'Manutenção de geradores', '31987020015', 'tecnico15@fabricaexemplo.com.br', TRUE, '$2y$12$2MWVidUIxhRgEqyLLSpqceHQCO.uw8NX1HCEhM/IrgJhSSBlZTNS.');

INSERT INTO EMPRESA_TERCEIRIZADA (id_empresa, razao_social, cnpj, email) VALUES
  (1, 'EletroMaq Serviços Industriais Ltda', '12345678000190', 'contato@eletromaq.example.com'),
  (2, 'Mecânica Horizonte Industrial Ltda', '23456789000101', 'comercial@mecanica-horizonte.example.com'),
  (3, 'CalibraMinas Instrumentação Ltda', '34567890000112', 'atendimento@calibraminas.example.com'),
  (4, 'TermoVapor Engenharia Ltda', '45678901000123', 'servicos@termovapor.example.com'),
  (5, 'ArComprimido Soluções Ltda', '56789012000134', 'suporte@arcomprimido.example.com'),
  (6, 'Bombas Gerais Manutenção Ltda', '67890123000145', 'orcamentos@bombasgerais.example.com'),
  (7, 'Automatec Controles Ltda', '78901234000156', 'contato@automatec.example.com'),
  (8, 'Correias e Transportes Técnicos Ltda', '89012345000167', 'comercial@correiastecnicas.example.com'),
  (9, 'Energia Segura Engenharia Ltda', '90123456000178', 'suporte@energiasegura.example.com'),
  (10, 'Filtros Industriais do Cerrado Ltda', '11223344000189', 'atendimento@filtroscerrado.example.com'),
  (11, 'VibraTech Diagnósticos Ltda', '22334455000190', 'contato@vibratech.example.com'),
  (12, 'Processo Limpo Soluções Ltda', '33445566000101', 'comercial@processolimpo.example.com'),
  (13, 'MetalSolda Engenharia Ltda', '44556677000112', 'orcamentos@metalsolda.example.com'),
  (14, 'Refrigeração Técnica Minas Ltda', '55667788000123', 'suporte@refrigeracaominas.example.com'),
  (15, 'Geradores Brasil Assistência Ltda', '66778899000134', 'atendimento@geradoresbrasil.example.com');

INSERT INTO EQUIPAMENTO (tag_equipamento, id_funcionario, descricao, functional_location, data_instalacao, ativo) VALUES
  (1001, 1, 'Motor elétrico do transportador de caixas', 'Linha de Embalagem / Transportador 01', '2022-03-14', TRUE),
  (1002, 2, 'Bomba centrífuga de água de processo', 'Utilidades / Casa de Bombas 02', '2021-07-20', TRUE),
  (1003, 3, 'Compressor de ar de parafuso', 'Utilidades / Sala de Compressores', '2020-11-09', TRUE),
  (1004, 4, 'Esteira transportadora de produto acabado', 'Expedição / Esteira 03', '2023-01-18', TRUE),
  (1005, 5, 'Trocador de calor de placas', 'Processo / Resfriamento', '2019-05-23', TRUE),
  (1006, 6, 'Caldeira industrial a vapor', 'Utilidades / Caldeiraria', '2018-09-11', TRUE),
  (1007, 7, 'Misturador industrial de matérias-primas', 'Produção / Mistura 01', '2022-08-05', TRUE),
  (1008, 8, 'Válvula de controle pneumática', 'Processo / Linha de Vapor', '2021-12-07', TRUE),
  (1009, 9, 'Painel elétrico de baixa tensão', 'Subestação / QGBT 01', '2020-02-28', TRUE),
  (1010, 10, 'Envasadora automática de frascos', 'Envase / Linha 02', '2023-06-12', TRUE),
  (1011, 11, 'Sistema de filtragem de água industrial', 'Tratamento de Água / Filtro 01', '2021-04-16', TRUE),
  (1012, 12, 'Ventilador de exaustão industrial', 'Produção / Exaustão 02', '2022-10-30', TRUE),
  (1013, 13, 'Inversor de frequência do motor principal', 'Embalagem / Painel de Acionamento', '2023-02-08', TRUE),
  (1014, 14, 'Dosadora volumétrica de aditivos', 'Processo / Dosagem 01', '2020-06-19', TRUE),
  (1015, 15, 'Gerador de energia de emergência', 'Utilidades / Casa de Geradores', '2019-12-02', TRUE);

-- PLANO_MANUTENCAO: 20 registros
INSERT INTO PLANO_MANUTENCAO (id_plano, id_equipamento, descricao, recorrencia_dias, ultima_execucao, proxima_execucao, ativo) VALUES
  (1, 1001, 'Inspeção preventiva e lubrificação', 7, '2026-11-06', '2026-11-13', TRUE),
  (2, 1002, 'Verificação elétrica e reaperto', 14, '2026-10-31', '2026-11-14', TRUE),
  (3, 1003, 'Calibração preventiva', 30, '2026-10-16', '2026-11-15', TRUE),
  (4, 1004, 'Revisão mecânica programada', 60, '2026-09-17', '2026-11-16', TRUE),
  (5, 1005, 'Teste funcional e segurança', 90, '2026-08-19', '2026-11-17', TRUE),
  (6, 1006, 'Inspeção preventiva e lubrificação', 7, '2026-11-11', '2026-11-18', TRUE),
  (7, 1007, 'Verificação elétrica e reaperto', 14, '2026-11-05', '2026-11-19', TRUE),
  (8, 1008, 'Calibração preventiva', 30, '2026-10-21', '2026-11-20', TRUE),
  (9, 1009, 'Revisão mecânica programada', 60, '2026-09-22', '2026-11-21', TRUE),
  (10, 1010, 'Teste funcional e segurança', 90, '2026-08-24', '2026-11-22', TRUE),
  (11, 1011, 'Inspeção preventiva e lubrificação', 7, '2026-11-16', '2026-11-23', TRUE),
  (12, 1012, 'Verificação elétrica e reaperto', 14, '2026-11-10', '2026-11-24', TRUE),
  (13, 1013, 'Calibração preventiva', 30, '2026-10-13', '2026-11-12', TRUE),
  (14, 1014, 'Revisão mecânica programada', 60, '2026-09-14', '2026-11-13', TRUE),
  (15, 1015, 'Teste funcional e segurança', 90, '2026-08-16', '2026-11-14', TRUE),
  (16, 1001, 'Inspeção preventiva e lubrificação', 7, '2026-11-08', '2026-11-15', TRUE),
  (17, 1002, 'Verificação elétrica e reaperto', 14, '2026-11-02', '2026-11-16', TRUE),
  (18, 1003, 'Calibração preventiva', 30, '2026-10-18', '2026-11-17', TRUE),
  (19, 1004, 'Revisão mecânica programada', 60, '2026-09-19', '2026-11-18', TRUE),
  (20, 1005, 'Teste funcional e segurança', 90, '2026-08-21', '2026-11-19', TRUE);

-- NOTIFICACAO: 42 registros
INSERT INTO NOTIFICACAO (id_notificacao, id_equipamento, id_funcionario, descricao, data_criacao, status, prioridade, inicio_indisponibilidade) VALUES
  (1, 1001, 2, 'Vibração excessiva e parada automática', '2026-09-04 07:15:00', 'FECHADA', 'P1', '2026-09-04 07:00:00'),
  (2, 1001, 3, 'Superaquecimento e desligamento de proteção', '2026-09-19 08:15:00', 'FECHADA', 'P2', '2026-09-19 08:00:00'),
  (3, 1001, 4, 'Perda de pressão durante operação', '2026-10-04 09:15:00', 'FECHADA', 'P2', '2026-10-04 09:00:00'),
  (4, 1001, 5, 'Alarme de falha no inversor', '2026-10-19 10:15:00', 'FECHADA', 'P1', '2026-10-19 10:00:00'),
  (5, 1001, 6, 'Travamento do conjunto de transmissão', '2026-11-03 11:15:00', 'FECHADA', 'P2', '2026-11-03 11:00:00'),
  (6, 1002, 3, 'Superaquecimento e desligamento de proteção', '2026-09-05 08:15:00', 'FECHADA', 'P1', '2026-09-05 08:00:00'),
  (7, 1002, 4, 'Perda de pressão durante operação', '2026-09-20 09:15:00', 'FECHADA', 'P2', '2026-09-20 09:00:00'),
  (8, 1002, 5, 'Alarme de falha no inversor', '2026-10-05 10:15:00', 'FECHADA', 'P2', '2026-10-05 10:00:00'),
  (9, 1002, 6, 'Travamento do conjunto de transmissão', '2026-10-20 11:15:00', 'FECHADA', 'P1', '2026-10-20 11:00:00'),
  (10, 1002, 7, 'Queda de rendimento com parada inesperada', '2026-11-04 06:15:00', 'FECHADA', 'P2', '2026-11-04 06:00:00'),
  (11, 1003, 4, 'Perda de pressão durante operação', '2026-09-06 09:15:00', 'FECHADA', 'P1', '2026-09-06 09:00:00'),
  (12, 1003, 5, 'Alarme de falha no inversor', '2026-09-21 10:15:00', 'FECHADA', 'P2', '2026-09-21 10:00:00'),
  (13, 1003, 6, 'Travamento do conjunto de transmissão', '2026-10-06 11:15:00', 'FECHADA', 'P2', '2026-10-06 11:00:00'),
  (14, 1003, 7, 'Queda de rendimento com parada inesperada', '2026-10-21 06:15:00', 'FECHADA', 'P1', '2026-10-21 06:00:00'),
  (15, 1003, 8, 'Falha intermitente no acionamento', '2026-11-05 07:15:00', 'FECHADA', 'P2', '2026-11-05 07:00:00'),
  (16, 1004, 5, 'Alarme de falha no inversor', '2026-09-07 10:15:00', 'FECHADA', 'P1', '2026-09-07 10:00:00'),
  (17, 1004, 6, 'Travamento do conjunto de transmissão', '2026-09-22 11:15:00', 'FECHADA', 'P2', '2026-09-22 11:00:00'),
  (18, 1004, 7, 'Queda de rendimento com parada inesperada', '2026-10-07 06:15:00', 'FECHADA', 'P2', '2026-10-07 06:00:00'),
  (19, 1004, 8, 'Falha intermitente no acionamento', '2026-10-22 07:15:00', 'FECHADA', 'P1', '2026-10-22 07:00:00'),
  (20, 1004, 9, 'Vibração excessiva e parada automática', '2026-11-06 08:15:00', 'FECHADA', 'P2', '2026-11-06 08:00:00'),
  (21, 1005, 6, 'Travamento do conjunto de transmissão', '2026-09-08 11:15:00', 'FECHADA', 'P1', '2026-09-08 11:00:00'),
  (22, 1005, 7, 'Queda de rendimento com parada inesperada', '2026-09-23 06:15:00', 'FECHADA', 'P2', '2026-09-23 06:00:00'),
  (23, 1005, 8, 'Falha intermitente no acionamento', '2026-10-08 07:15:00', 'FECHADA', 'P2', '2026-10-08 07:00:00'),
  (24, 1005, 9, 'Vibração excessiva e parada automática', '2026-10-23 08:15:00', 'FECHADA', 'P1', '2026-10-23 08:00:00'),
  (25, 1005, 10, 'Superaquecimento e desligamento de proteção', '2026-11-07 09:15:00', 'FECHADA', 'P2', '2026-11-07 09:00:00'),
  (26, 1006, 7, 'Queda de rendimento com parada inesperada', '2026-09-09 06:15:00', 'FECHADA', 'P1', '2026-09-09 06:00:00'),
  (27, 1006, 8, 'Falha intermitente no acionamento', '2026-09-24 07:15:00', 'FECHADA', 'P2', '2026-09-24 07:00:00'),
  (28, 1006, 9, 'Vibração excessiva e parada automática', '2026-10-09 08:15:00', 'FECHADA', 'P2', '2026-10-09 08:00:00'),
  (29, 1006, 10, 'Superaquecimento e desligamento de proteção', '2026-10-24 09:15:00', 'FECHADA', 'P1', '2026-10-24 09:00:00'),
  (30, 1006, 11, 'Perda de pressão durante operação', '2026-11-08 10:15:00', 'FECHADA', 'P2', '2026-11-08 10:00:00'),
  (31, 1007, 7, 'Falha intermitente no acionamento', '2026-10-23 07:10:00', 'FECHADA', 'P2', '2026-10-23 07:00:00'),
  (32, 1008, 8, 'Vibração excessiva e parada automática', '2026-10-25 07:10:00', 'FECHADA', 'P2', '2026-10-25 07:00:00'),
  (33, 1009, 9, 'Superaquecimento e desligamento de proteção', '2026-10-27 07:10:00', 'FECHADA', 'P2', '2026-10-27 07:00:00'),
  (34, 1010, 10, 'Perda de pressão durante operação', '2026-10-29 07:10:00', 'FECHADA', 'P2', '2026-10-29 07:00:00'),
  (35, 1011, 11, 'Alarme de falha no inversor', '2026-10-31 07:10:00', 'FECHADA', 'P2', '2026-10-31 07:00:00'),
  (36, 1012, 12, 'Travamento do conjunto de transmissão', '2026-11-02 07:10:00', 'FECHADA', 'P2', '2026-11-02 07:00:00'),
  (37, 1001, 4, 'Falha em análise, equipamento aguardando reparo', '2026-11-14 08:20:00', 'ABERTO', 'P1', '2026-11-14 08:00:00'),
  (38, 1002, 5, 'Falha em análise, equipamento aguardando reparo', '2026-11-14 12:20:00', 'ABERTO', 'P1', '2026-11-14 12:00:00'),
  (39, 1003, 6, 'Falha em análise, equipamento aguardando reparo', '2026-11-14 16:20:00', 'ABERTO', 'P1', '2026-11-14 16:00:00'),
  (40, 1004, 7, 'Falha em análise, equipamento aguardando reparo', '2026-11-14 20:20:00', 'ABERTO', 'P2', '2026-11-14 20:00:00'),
  (41, 1005, 8, 'Falha em análise, equipamento aguardando reparo', '2026-11-15 00:20:00', 'ABERTO', 'P2', '2026-11-15 00:00:00'),
  (42, 1006, 9, 'Falha em análise, equipamento aguardando reparo', '2026-11-15 04:20:00', 'ABERTO', 'P2', '2026-11-15 04:00:00');

INSERT INTO SERVICO (id_servico, id_empresa, nome, descricao, valor_base, ativo) VALUES
  (1, 1, 'Rebobinamento de motor elétrico', 'Rebobinamento e testes de isolamento do estator', 2450, TRUE),
  (2, 2, 'Alinhamento a laser de conjuntos rotativos', 'Medição e correção do alinhamento de eixos', 890, TRUE),
  (3, 3, 'Calibração de transmissor de pressão', 'Calibração com certificado e rastreabilidade', 620, TRUE),
  (4, 4, 'Inspeção técnica de caldeira', 'Inspeção de segurança e relatório técnico', 3100, TRUE),
  (5, 5, 'Revisão de compressor de parafuso', 'Inspeção do conjunto e substituição de filtros', 1950, TRUE),
  (6, 6, 'Recuperação de selo mecânico', 'Reparo e teste de vedação de bomba', 1280, TRUE),
  (7, 7, 'Parametrização de controlador industrial', 'Configuração e validação de parâmetros', 1100, TRUE),
  (8, 8, 'Emenda e alinhamento de correia', 'Reparo de correia e ajuste do transportador', 1450, TRUE),
  (9, 9, 'Ensaio de proteção elétrica', 'Testes funcionais de dispositivos de proteção', 1750, TRUE),
  (10, 10, 'Substituição de elementos filtrantes', 'Troca de elementos e teste de vazão', 980, TRUE),
  (11, 11, 'Análise de vibração em equipamentos', 'Coleta e diagnóstico de vibração mecânica', 780, TRUE),
  (12, 12, 'Limpeza química de trocador de calor', 'Desincrustação e lavagem controlada', 2100, TRUE),
  (13, 13, 'Soldagem de suporte estrutural', 'Reparo por soldagem e inspeção visual', 1350, TRUE),
  (14, 14, 'Revisão de circuito de refrigeração', 'Inspeção de vazamentos e testes de pressão', 1680, TRUE),
  (15, 15, 'Manutenção de gerador diesel', 'Revisão do sistema de partida e alimentação', 2850, TRUE);

-- ORDEM_SERVICO: 62 registros
INSERT INTO ORDEM_SERVICO (id_os, id_equipamento, id_notificacao, id_plano, tipo, descricao, data_abertura, data_fechamento, status, prioridade, retorno_operacao) VALUES
  (1, 1001, 1, NULL, 'M1', 'Reparo corretivo: vibração excessiva e parada automática', '2026-09-04 07:15:00', '2026-09-04 11:30:00', 'CONCLUIDA', 'P1', '2026-09-04 10:30:00'),
  (2, 1001, 2, NULL, 'M1', 'Reparo corretivo: superaquecimento e desligamento de proteção', '2026-09-19 08:15:00', '2026-09-19 13:30:00', 'CONCLUIDA', 'P2', '2026-09-19 12:30:00'),
  (3, 1001, 3, NULL, 'M1', 'Reparo corretivo: perda de pressão durante operação', '2026-10-04 09:15:00', '2026-10-04 15:30:00', 'CONCLUIDA', 'P2', '2026-10-04 14:30:00'),
  (4, 1001, 4, NULL, 'M1', 'Reparo corretivo: alarme de falha no inversor', '2026-10-19 10:15:00', '2026-10-19 14:30:00', 'CONCLUIDA', 'P1', '2026-10-19 13:30:00'),
  (5, 1001, 5, NULL, 'M1', 'Reparo corretivo: travamento do conjunto de transmissão', '2026-11-03 11:15:00', '2026-11-03 16:30:00', 'CONCLUIDA', 'P2', '2026-11-03 15:30:00'),
  (6, 1002, 6, NULL, 'M1', 'Reparo corretivo: superaquecimento e desligamento de proteção', '2026-09-05 08:15:00', '2026-09-05 12:30:00', 'CONCLUIDA', 'P1', '2026-09-05 11:30:00'),
  (7, 1002, 7, NULL, 'M1', 'Reparo corretivo: perda de pressão durante operação', '2026-09-20 09:15:00', '2026-09-20 14:30:00', 'CONCLUIDA', 'P2', '2026-09-20 13:30:00'),
  (8, 1002, 8, NULL, 'M1', 'Reparo corretivo: alarme de falha no inversor', '2026-10-05 10:15:00', '2026-10-05 16:30:00', 'CONCLUIDA', 'P2', '2026-10-05 15:30:00'),
  (9, 1002, 9, NULL, 'M1', 'Reparo corretivo: travamento do conjunto de transmissão', '2026-10-20 11:15:00', '2026-10-20 15:30:00', 'CONCLUIDA', 'P1', '2026-10-20 14:30:00'),
  (10, 1002, 10, NULL, 'M1', 'Reparo corretivo: queda de rendimento com parada inesperada', '2026-11-04 06:15:00', '2026-11-04 11:30:00', 'CONCLUIDA', 'P2', '2026-11-04 10:30:00'),
  (11, 1003, 11, NULL, 'M1', 'Reparo corretivo: perda de pressão durante operação', '2026-09-06 09:15:00', '2026-09-06 13:30:00', 'CONCLUIDA', 'P1', '2026-09-06 12:30:00'),
  (12, 1003, 12, NULL, 'M1', 'Reparo corretivo: alarme de falha no inversor', '2026-09-21 10:15:00', '2026-09-21 15:30:00', 'CONCLUIDA', 'P2', '2026-09-21 14:30:00'),
  (13, 1003, 13, NULL, 'M1', 'Reparo corretivo: travamento do conjunto de transmissão', '2026-10-06 11:15:00', '2026-10-06 17:30:00', 'CONCLUIDA', 'P2', '2026-10-06 16:30:00'),
  (14, 1003, 14, NULL, 'M1', 'Reparo corretivo: queda de rendimento com parada inesperada', '2026-10-21 06:15:00', '2026-10-21 10:30:00', 'CONCLUIDA', 'P1', '2026-10-21 09:30:00'),
  (15, 1003, 15, NULL, 'M1', 'Reparo corretivo: falha intermitente no acionamento', '2026-11-05 07:15:00', '2026-11-05 12:30:00', 'CONCLUIDA', 'P2', '2026-11-05 11:30:00'),
  (16, 1004, 16, NULL, 'M1', 'Reparo corretivo: alarme de falha no inversor', '2026-09-07 10:15:00', '2026-09-07 14:30:00', 'CONCLUIDA', 'P1', '2026-09-07 13:30:00'),
  (17, 1004, 17, NULL, 'M1', 'Reparo corretivo: travamento do conjunto de transmissão', '2026-09-22 11:15:00', '2026-09-22 16:30:00', 'CONCLUIDA', 'P2', '2026-09-22 15:30:00'),
  (18, 1004, 18, NULL, 'M1', 'Reparo corretivo: queda de rendimento com parada inesperada', '2026-10-07 06:15:00', '2026-10-07 12:30:00', 'CONCLUIDA', 'P2', '2026-10-07 11:30:00'),
  (19, 1004, 19, NULL, 'M1', 'Reparo corretivo: falha intermitente no acionamento', '2026-10-22 07:15:00', '2026-10-22 11:30:00', 'CONCLUIDA', 'P1', '2026-10-22 10:30:00'),
  (20, 1004, 20, NULL, 'M1', 'Reparo corretivo: vibração excessiva e parada automática', '2026-11-06 08:15:00', '2026-11-06 13:30:00', 'CONCLUIDA', 'P2', '2026-11-06 12:30:00'),
  (21, 1005, 21, NULL, 'M1', 'Reparo corretivo: travamento do conjunto de transmissão', '2026-09-08 11:15:00', '2026-09-08 15:30:00', 'CONCLUIDA', 'P1', '2026-09-08 14:30:00'),
  (22, 1005, 22, NULL, 'M1', 'Reparo corretivo: queda de rendimento com parada inesperada', '2026-09-23 06:15:00', '2026-09-23 11:30:00', 'CONCLUIDA', 'P2', '2026-09-23 10:30:00'),
  (23, 1005, 23, NULL, 'M1', 'Reparo corretivo: falha intermitente no acionamento', '2026-10-08 07:15:00', '2026-10-08 13:30:00', 'CONCLUIDA', 'P2', '2026-10-08 12:30:00'),
  (24, 1005, 24, NULL, 'M1', 'Reparo corretivo: vibração excessiva e parada automática', '2026-10-23 08:15:00', '2026-10-23 12:30:00', 'CONCLUIDA', 'P1', '2026-10-23 11:30:00'),
  (25, 1005, 25, NULL, 'M1', 'Reparo corretivo: superaquecimento e desligamento de proteção', '2026-11-07 09:15:00', '2026-11-07 14:30:00', 'CONCLUIDA', 'P2', '2026-11-07 13:30:00'),
  (26, 1006, 26, NULL, 'M1', 'Reparo corretivo: queda de rendimento com parada inesperada', '2026-09-09 06:15:00', '2026-09-09 10:30:00', 'CONCLUIDA', 'P1', '2026-09-09 09:30:00'),
  (27, 1006, 27, NULL, 'M1', 'Reparo corretivo: falha intermitente no acionamento', '2026-09-24 07:15:00', '2026-09-24 12:30:00', 'CONCLUIDA', 'P2', '2026-09-24 11:30:00'),
  (28, 1006, 28, NULL, 'M1', 'Reparo corretivo: vibração excessiva e parada automática', '2026-10-09 08:15:00', '2026-10-09 14:30:00', 'CONCLUIDA', 'P2', '2026-10-09 13:30:00'),
  (29, 1006, 29, NULL, 'M1', 'Reparo corretivo: superaquecimento e desligamento de proteção', '2026-10-24 09:15:00', '2026-10-24 13:30:00', 'CONCLUIDA', 'P1', '2026-10-24 12:30:00'),
  (30, 1006, 30, NULL, 'M1', 'Reparo corretivo: perda de pressão durante operação', '2026-11-08 10:15:00', '2026-11-08 15:30:00', 'CONCLUIDA', 'P2', '2026-11-08 14:30:00'),
  (31, 1007, 31, NULL, 'M1', 'Correção de falha detectada durante operação', '2026-10-23 07:10:00', '2026-10-23 13:35:00', 'CONCLUIDA', 'P2', '2026-10-23 12:45:00'),
  (32, 1008, 32, NULL, 'M1', 'Correção de falha detectada durante operação', '2026-10-25 07:10:00', '2026-10-25 10:35:00', 'CONCLUIDA', 'P2', '2026-10-25 09:45:00'),
  (33, 1009, 33, NULL, 'M1', 'Correção de falha detectada durante operação', '2026-10-27 07:10:00', '2026-10-27 11:35:00', 'CONCLUIDA', 'P2', '2026-10-27 10:45:00'),
  (34, 1010, 34, NULL, 'M1', 'Correção de falha detectada durante operação', '2026-10-29 07:10:00', '2026-10-29 12:35:00', 'CONCLUIDA', 'P2', '2026-10-29 11:45:00'),
  (35, 1011, 35, NULL, 'M1', 'Correção de falha detectada durante operação', '2026-10-31 07:10:00', '2026-10-31 13:35:00', 'CONCLUIDA', 'P2', '2026-10-31 12:45:00'),
  (36, 1012, 36, NULL, 'M1', 'Correção de falha detectada durante operação', '2026-11-02 07:10:00', '2026-11-02 10:35:00', 'CONCLUIDA', 'P2', '2026-11-02 09:45:00'),
  (37, 1001, 37, NULL, 'M1', 'Investigar causa e restabelecer equipamento', '2026-11-14 08:20:00', NULL, 'PLANEJADA', 'P1', NULL),
  (38, 1002, 38, NULL, 'M1', 'Investigar causa e restabelecer equipamento', '2026-11-14 12:20:00', NULL, 'EM_EXECUCAO', 'P1', NULL),
  (39, 1003, 39, NULL, 'M1', 'Investigar causa e restabelecer equipamento', '2026-11-14 16:20:00', NULL, 'PLANEJADA', 'P1', NULL),
  (40, 1004, 40, NULL, 'M1', 'Investigar causa e restabelecer equipamento', '2026-11-14 20:20:00', NULL, 'EM_EXECUCAO', 'P2', NULL),
  (41, 1005, 41, NULL, 'M1', 'Investigar causa e restabelecer equipamento', '2026-11-15 00:20:00', NULL, 'PLANEJADA', 'P2', NULL),
  (42, 1006, 42, NULL, 'M1', 'Investigar causa e restabelecer equipamento', '2026-11-15 04:20:00', NULL, 'EM_EXECUCAO', 'P2', NULL),
  (43, 1001, NULL, 1, 'M2', 'Inspeção preventiva e lubrificação', '2026-10-11 07:00:00', '2026-10-11 11:00:00', 'CONCLUIDA', 'P2', NULL),
  (44, 1002, NULL, 2, 'M2', 'Verificação elétrica e reaperto', '2026-10-12 07:00:00', '2026-10-12 12:00:00', 'CONCLUIDA', 'P2', NULL),
  (45, 1003, NULL, 3, 'M2', 'Calibração preventiva', '2026-10-13 07:00:00', '2026-10-13 10:00:00', 'CONCLUIDA', 'P2', NULL),
  (46, 1004, NULL, 4, 'M2', 'Revisão mecânica programada', '2026-10-14 07:00:00', '2026-10-14 11:00:00', 'CONCLUIDA', 'P2', NULL),
  (47, 1005, NULL, 5, 'M2', 'Teste funcional e segurança', '2026-10-15 07:00:00', '2026-10-15 12:00:00', 'CONCLUIDA', 'P2', NULL),
  (48, 1006, NULL, 6, 'M2', 'Inspeção preventiva e lubrificação', '2026-10-16 07:00:00', '2026-10-16 10:00:00', 'CONCLUIDA', 'P2', NULL),
  (49, 1007, NULL, 7, 'M2', 'Verificação elétrica e reaperto', '2026-10-17 07:00:00', '2026-10-17 11:00:00', 'CONCLUIDA', 'P2', NULL),
  (50, 1008, NULL, 8, 'M2', 'Calibração preventiva', '2026-10-18 07:00:00', '2026-10-18 12:00:00', 'CONCLUIDA', 'P2', NULL),
  (51, 1009, NULL, 9, 'M2', 'Revisão mecânica programada', '2026-10-19 07:00:00', '2026-10-19 10:00:00', 'CONCLUIDA', 'P2', NULL),
  (52, 1010, NULL, 10, 'M2', 'Teste funcional e segurança', '2026-10-20 07:00:00', '2026-10-20 11:00:00', 'CONCLUIDA', 'P2', NULL),
  (53, 1011, NULL, 11, 'M2', 'Inspeção preventiva e lubrificação', '2026-10-21 07:00:00', '2026-10-21 12:00:00', 'CONCLUIDA', 'P2', NULL),
  (54, 1012, NULL, 12, 'M2', 'Verificação elétrica e reaperto', '2026-10-22 07:00:00', '2026-10-22 10:00:00', 'CONCLUIDA', 'P2', NULL),
  (55, 1013, NULL, 13, 'M2', 'Calibração preventiva', '2026-10-23 07:00:00', '2026-10-23 11:00:00', 'CONCLUIDA', 'P2', NULL),
  (56, 1014, NULL, 14, 'M2', 'Revisão mecânica programada', '2026-10-24 07:00:00', '2026-10-24 12:00:00', 'CONCLUIDA', 'P2', NULL),
  (57, 1015, NULL, 15, 'M2', 'Teste funcional e segurança', '2026-10-25 07:00:00', '2026-10-25 10:00:00', 'CONCLUIDA', 'P2', NULL),
  (58, 1001, NULL, 16, 'M2', 'Inspeção preventiva e lubrificação', '2026-10-26 07:00:00', '2026-10-26 11:00:00', 'CONCLUIDA', 'P2', NULL),
  (59, 1002, NULL, 17, 'M2', 'Verificação elétrica e reaperto', '2026-11-16 07:00:00', NULL, 'PLANEJADA', 'P2', NULL),
  (60, 1003, NULL, 18, 'M2', 'Calibração preventiva', '2026-11-16 08:00:00', NULL, 'PLANEJADA', 'P2', NULL),
  (61, 1004, NULL, 19, 'M2', 'Revisão mecânica programada', '2026-11-16 09:00:00', NULL, 'PLANEJADA', 'P2', NULL),
  (62, 1005, NULL, 20, 'M2', 'Teste funcional e segurança', '2026-11-16 10:00:00', NULL, 'PLANEJADA', 'P2', NULL);

-- LANCAMENTO_HORAS: 82 registros
INSERT INTO LANCAMENTO_HORAS (id_os_tecnico, id_os, id_tecnico, inicio, fim, tempo_trabalhado, descricao_atividade) VALUES
  (1, 1, 1, '2026-09-04 07:30:00', '2026-09-04 09:30:00', '02:00:00', 'Diagnóstico e intervenção corretiva'),
  (2, 1, 7, '2026-09-04 08:15:00', '2026-09-04 10:00:00', '01:45:00', 'Substituição, ajuste e teste de componentes'),
  (3, 2, 1, '2026-09-19 08:30:00', '2026-09-19 11:30:00', '03:00:00', 'Diagnóstico e intervenção corretiva'),
  (4, 2, 8, '2026-09-19 09:15:00', '2026-09-19 12:00:00', '02:45:00', 'Substituição, ajuste e teste de componentes'),
  (5, 3, 1, '2026-10-04 09:30:00', '2026-10-04 13:30:00', '04:00:00', 'Diagnóstico e intervenção corretiva'),
  (6, 3, 9, '2026-10-04 10:15:00', '2026-10-04 14:00:00', '03:45:00', 'Substituição, ajuste e teste de componentes'),
  (7, 4, 1, '2026-10-19 10:30:00', '2026-10-19 12:30:00', '02:00:00', 'Diagnóstico e intervenção corretiva'),
  (8, 4, 10, '2026-10-19 11:15:00', '2026-10-19 13:00:00', '01:45:00', 'Substituição, ajuste e teste de componentes'),
  (9, 5, 1, '2026-11-03 11:30:00', '2026-11-03 14:30:00', '03:00:00', 'Diagnóstico e intervenção corretiva'),
  (10, 5, 11, '2026-11-03 12:15:00', '2026-11-03 15:00:00', '02:45:00', 'Substituição, ajuste e teste de componentes'),
  (11, 6, 2, '2026-09-05 08:30:00', '2026-09-05 10:30:00', '02:00:00', 'Diagnóstico e intervenção corretiva'),
  (12, 6, 8, '2026-09-05 09:15:00', '2026-09-05 11:00:00', '01:45:00', 'Substituição, ajuste e teste de componentes'),
  (13, 7, 2, '2026-09-20 09:30:00', '2026-09-20 12:30:00', '03:00:00', 'Diagnóstico e intervenção corretiva'),
  (14, 7, 9, '2026-09-20 10:15:00', '2026-09-20 13:00:00', '02:45:00', 'Substituição, ajuste e teste de componentes'),
  (15, 8, 2, '2026-10-05 10:30:00', '2026-10-05 14:30:00', '04:00:00', 'Diagnóstico e intervenção corretiva'),
  (16, 8, 10, '2026-10-05 11:15:00', '2026-10-05 15:00:00', '03:45:00', 'Substituição, ajuste e teste de componentes'),
  (17, 9, 2, '2026-10-20 11:30:00', '2026-10-20 13:30:00', '02:00:00', 'Diagnóstico e intervenção corretiva'),
  (18, 9, 11, '2026-10-20 12:15:00', '2026-10-20 14:00:00', '01:45:00', 'Substituição, ajuste e teste de componentes'),
  (19, 10, 2, '2026-11-04 06:30:00', '2026-11-04 09:30:00', '03:00:00', 'Diagnóstico e intervenção corretiva'),
  (20, 10, 12, '2026-11-04 07:15:00', '2026-11-04 10:00:00', '02:45:00', 'Substituição, ajuste e teste de componentes'),
  (21, 11, 3, '2026-09-06 09:30:00', '2026-09-06 11:30:00', '02:00:00', 'Diagnóstico e intervenção corretiva'),
  (22, 11, 9, '2026-09-06 10:15:00', '2026-09-06 12:00:00', '01:45:00', 'Substituição, ajuste e teste de componentes'),
  (23, 12, 3, '2026-09-21 10:30:00', '2026-09-21 13:30:00', '03:00:00', 'Diagnóstico e intervenção corretiva'),
  (24, 12, 10, '2026-09-21 11:15:00', '2026-09-21 14:00:00', '02:45:00', 'Substituição, ajuste e teste de componentes'),
  (25, 13, 3, '2026-10-06 11:30:00', '2026-10-06 15:30:00', '04:00:00', 'Diagnóstico e intervenção corretiva'),
  (26, 13, 11, '2026-10-06 12:15:00', '2026-10-06 16:00:00', '03:45:00', 'Substituição, ajuste e teste de componentes'),
  (27, 14, 3, '2026-10-21 06:30:00', '2026-10-21 08:30:00', '02:00:00', 'Diagnóstico e intervenção corretiva'),
  (28, 14, 12, '2026-10-21 07:15:00', '2026-10-21 09:00:00', '01:45:00', 'Substituição, ajuste e teste de componentes'),
  (29, 15, 3, '2026-11-05 07:30:00', '2026-11-05 10:30:00', '03:00:00', 'Diagnóstico e intervenção corretiva'),
  (30, 15, 13, '2026-11-05 08:15:00', '2026-11-05 11:00:00', '02:45:00', 'Substituição, ajuste e teste de componentes'),
  (31, 16, 4, '2026-09-07 10:30:00', '2026-09-07 12:30:00', '02:00:00', 'Diagnóstico e intervenção corretiva'),
  (32, 16, 10, '2026-09-07 11:15:00', '2026-09-07 13:00:00', '01:45:00', 'Substituição, ajuste e teste de componentes'),
  (33, 17, 4, '2026-09-22 11:30:00', '2026-09-22 14:30:00', '03:00:00', 'Diagnóstico e intervenção corretiva'),
  (34, 17, 11, '2026-09-22 12:15:00', '2026-09-22 15:00:00', '02:45:00', 'Substituição, ajuste e teste de componentes'),
  (35, 18, 4, '2026-10-07 06:30:00', '2026-10-07 10:30:00', '04:00:00', 'Diagnóstico e intervenção corretiva'),
  (36, 18, 12, '2026-10-07 07:15:00', '2026-10-07 11:00:00', '03:45:00', 'Substituição, ajuste e teste de componentes'),
  (37, 19, 4, '2026-10-22 07:30:00', '2026-10-22 09:30:00', '02:00:00', 'Diagnóstico e intervenção corretiva'),
  (38, 19, 13, '2026-10-22 08:15:00', '2026-10-22 10:00:00', '01:45:00', 'Substituição, ajuste e teste de componentes'),
  (39, 20, 4, '2026-11-06 08:30:00', '2026-11-06 11:30:00', '03:00:00', 'Diagnóstico e intervenção corretiva'),
  (40, 20, 14, '2026-11-06 09:15:00', '2026-11-06 12:00:00', '02:45:00', 'Substituição, ajuste e teste de componentes'),
  (41, 21, 5, '2026-09-08 11:30:00', '2026-09-08 13:30:00', '02:00:00', 'Diagnóstico e intervenção corretiva'),
  (42, 21, 11, '2026-09-08 12:15:00', '2026-09-08 14:00:00', '01:45:00', 'Substituição, ajuste e teste de componentes'),
  (43, 22, 5, '2026-09-23 06:30:00', '2026-09-23 09:30:00', '03:00:00', 'Diagnóstico e intervenção corretiva'),
  (44, 22, 12, '2026-09-23 07:15:00', '2026-09-23 10:00:00', '02:45:00', 'Substituição, ajuste e teste de componentes'),
  (45, 23, 5, '2026-10-08 07:30:00', '2026-10-08 11:30:00', '04:00:00', 'Diagnóstico e intervenção corretiva'),
  (46, 23, 13, '2026-10-08 08:15:00', '2026-10-08 12:00:00', '03:45:00', 'Substituição, ajuste e teste de componentes'),
  (47, 24, 5, '2026-10-23 08:30:00', '2026-10-23 10:30:00', '02:00:00', 'Diagnóstico e intervenção corretiva'),
  (48, 24, 14, '2026-10-23 09:15:00', '2026-10-23 11:00:00', '01:45:00', 'Substituição, ajuste e teste de componentes'),
  (49, 25, 5, '2026-11-07 09:30:00', '2026-11-07 12:30:00', '03:00:00', 'Diagnóstico e intervenção corretiva'),
  (50, 25, 15, '2026-11-07 10:15:00', '2026-11-07 13:00:00', '02:45:00', 'Substituição, ajuste e teste de componentes'),
  (51, 26, 6, '2026-09-09 06:30:00', '2026-09-09 08:30:00', '02:00:00', 'Diagnóstico e intervenção corretiva'),
  (52, 26, 12, '2026-09-09 07:15:00', '2026-09-09 09:00:00', '01:45:00', 'Substituição, ajuste e teste de componentes'),
  (53, 27, 6, '2026-09-24 07:30:00', '2026-09-24 10:30:00', '03:00:00', 'Diagnóstico e intervenção corretiva'),
  (54, 27, 13, '2026-09-24 08:15:00', '2026-09-24 11:00:00', '02:45:00', 'Substituição, ajuste e teste de componentes'),
  (55, 28, 6, '2026-10-09 08:30:00', '2026-10-09 12:30:00', '04:00:00', 'Diagnóstico e intervenção corretiva'),
  (56, 28, 14, '2026-10-09 09:15:00', '2026-10-09 13:00:00', '03:45:00', 'Substituição, ajuste e teste de componentes'),
  (57, 29, 6, '2026-10-24 09:30:00', '2026-10-24 11:30:00', '02:00:00', 'Diagnóstico e intervenção corretiva'),
  (58, 29, 15, '2026-10-24 10:15:00', '2026-10-24 12:00:00', '01:45:00', 'Substituição, ajuste e teste de componentes'),
  (59, 30, 6, '2026-11-08 10:30:00', '2026-11-08 13:30:00', '03:00:00', 'Diagnóstico e intervenção corretiva'),
  (60, 30, 1, '2026-11-08 11:15:00', '2026-11-08 14:00:00', '02:45:00', 'Substituição, ajuste e teste de componentes'),
  (61, 31, 7, '2026-10-23 07:25:00', '2026-10-23 12:25:00', '05:00:00', 'Correção e testes de funcionamento'),
  (62, 32, 8, '2026-10-25 07:25:00', '2026-10-25 09:25:00', '02:00:00', 'Correção e testes de funcionamento'),
  (63, 33, 9, '2026-10-27 07:25:00', '2026-10-27 10:25:00', '03:00:00', 'Correção e testes de funcionamento'),
  (64, 34, 10, '2026-10-29 07:25:00', '2026-10-29 11:25:00', '04:00:00', 'Correção e testes de funcionamento'),
  (65, 35, 11, '2026-10-31 07:25:00', '2026-10-31 12:25:00', '05:00:00', 'Correção e testes de funcionamento'),
  (66, 36, 12, '2026-11-02 07:25:00', '2026-11-02 09:25:00', '02:00:00', 'Correção e testes de funcionamento'),
  (67, 43, 5, '2026-10-11 08:00:00', '2026-10-11 10:00:00', '02:00:00', 'Inspeção preventiva e testes programados'),
  (68, 44, 6, '2026-10-12 08:00:00', '2026-10-12 11:00:00', '03:00:00', 'Inspeção preventiva e testes programados'),
  (69, 45, 7, '2026-10-13 08:00:00', '2026-10-13 09:00:00', '01:00:00', 'Inspeção preventiva e testes programados'),
  (70, 46, 8, '2026-10-14 08:00:00', '2026-10-14 10:00:00', '02:00:00', 'Inspeção preventiva e testes programados'),
  (71, 47, 9, '2026-10-15 08:00:00', '2026-10-15 11:00:00', '03:00:00', 'Inspeção preventiva e testes programados'),
  (72, 48, 10, '2026-10-16 08:00:00', '2026-10-16 09:00:00', '01:00:00', 'Inspeção preventiva e testes programados'),
  (73, 49, 11, '2026-10-17 08:00:00', '2026-10-17 10:00:00', '02:00:00', 'Inspeção preventiva e testes programados'),
  (74, 50, 12, '2026-10-18 08:00:00', '2026-10-18 11:00:00', '03:00:00', 'Inspeção preventiva e testes programados'),
  (75, 51, 13, '2026-10-19 08:00:00', '2026-10-19 09:00:00', '01:00:00', 'Inspeção preventiva e testes programados'),
  (76, 52, 14, '2026-10-20 08:00:00', '2026-10-20 10:00:00', '02:00:00', 'Inspeção preventiva e testes programados'),
  (77, 53, 15, '2026-10-21 08:00:00', '2026-10-21 11:00:00', '03:00:00', 'Inspeção preventiva e testes programados'),
  (78, 54, 1, '2026-10-22 08:00:00', '2026-10-22 09:00:00', '01:00:00', 'Inspeção preventiva e testes programados'),
  (79, 55, 2, '2026-10-23 08:00:00', '2026-10-23 10:00:00', '02:00:00', 'Inspeção preventiva e testes programados'),
  (80, 56, 3, '2026-10-24 08:00:00', '2026-10-24 11:00:00', '03:00:00', 'Inspeção preventiva e testes programados'),
  (81, 57, 4, '2026-10-25 08:00:00', '2026-10-25 09:00:00', '01:00:00', 'Inspeção preventiva e testes programados'),
  (82, 58, 5, '2026-10-26 08:00:00', '2026-10-26 10:00:00', '02:00:00', 'Inspeção preventiva e testes programados');

-- OS_SERVICO: 49 registros
INSERT INTO OS_SERVICO (id_os_servico, id_os, id_servico, valor_cobrado) VALUES
  (1, 1, 2, 555),
  (2, 3, 4, 795),
  (3, 5, 6, 1035),
  (4, 6, 3, 630),
  (5, 8, 5, 870),
  (6, 10, 7, 1110),
  (7, 11, 4, 705),
  (8, 13, 6, 945),
  (9, 15, 8, 1185),
  (10, 16, 5, 780),
  (11, 18, 7, 1020),
  (12, 20, 9, 1260),
  (13, 21, 6, 855),
  (14, 23, 8, 1095),
  (15, 25, 10, 1335),
  (16, 26, 7, 930),
  (17, 28, 9, 1170),
  (18, 30, 11, 1410),
  (19, 31, 7, 1085),
  (20, 33, 9, 1195),
  (21, 35, 11, 1305),
  (22, 44, 7, 364),
  (23, 46, 9, 428),
  (24, 48, 11, 492),
  (25, 50, 13, 556),
  (26, 52, 15, 620),
  (27, 54, 2, 684),
  (28, 56, 4, 748),
  (29, 58, 6, 812),
  (30, 60, 8, 876),
  (31, 62, 10, 940),
  (32, 1, 2, 359),
  (33, 2, 3, 378),
  (34, 3, 4, 397),
  (35, 4, 5, 416),
  (36, 5, 1, 435),
  (37, 6, 2, 454),
  (38, 8, 4, 492),
  (39, 10, 1, 530),
  (40, 12, 3, 568),
  (41, 16, 2, 644),
  (42, 20, 1, 720),
  (43, 23, 4, 777),
  (44, 27, 3, 853),
  (45, 32, 3, 948),
  (46, 38, 4, 1062),
  (47, 42, 3, 1138),
  (48, 48, 4, 1252),
  (49, 51, 2, 1309);

COMMIT;
