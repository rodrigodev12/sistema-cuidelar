-- ============================================================
-- CuideLar — Schema PostgreSQL (Supabase)
-- ============================================================
-- Execute este arquivo no SQL Editor do Supabase
-- ============================================================

-- Habilitar extensões
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. USUÁRIOS
-- ============================================================
CREATE TABLE IF NOT EXISTS usuarios (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  nome        TEXT NOT NULL,
  email       TEXT UNIQUE NOT NULL,
  tipo        TEXT CHECK (tipo IN ('administrador', 'cuidador', 'cliente')) NOT NULL,
  avatar_url  TEXT,
  ativo       BOOLEAN DEFAULT TRUE,
  criado_em   TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. CLIENTES / FAMÍLIA
-- ============================================================
CREATE TABLE IF NOT EXISTS clientes_familia (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario  UUID REFERENCES usuarios(id) ON DELETE CASCADE,
  telefone    TEXT,
  celular     TEXT,
  cpf         TEXT UNIQUE,
  cep         TEXT,
  logradouro  TEXT,
  numero      TEXT,
  complemento TEXT,
  bairro      TEXT,
  cidade      TEXT,
  estado      CHAR(2),
  criado_em   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 3. IDOSOS
-- ============================================================
CREATE TABLE IF NOT EXISTS idosos (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_cliente        UUID REFERENCES clientes_familia(id) ON DELETE CASCADE,
  nome              TEXT NOT NULL,
  data_nascimento   DATE,
  genero            TEXT CHECK (genero IN ('masculino', 'feminino', 'outro')),
  tipo_sanguineo    TEXT CHECK (tipo_sanguineo IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
  restricoes_medicas TEXT,
  alergias          TEXT,
  medicamentos      TEXT,  -- lista de medicamentos contínuos
  foto_url          TEXT,
  observacoes       TEXT,
  plano_saude       TEXT,
  numero_plano      TEXT,
  medico_responsavel TEXT,
  contato_emergencia TEXT,
  telefone_emergencia TEXT,
  perfil            TEXT CHECK (perfil IN ('idoso', 'crianca_autista')) DEFAULT 'idoso' NOT NULL,
  ativo             BOOLEAN DEFAULT TRUE,
  criado_em         TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em     TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. CUIDADORES
-- ============================================================
CREATE TABLE IF NOT EXISTS cuidadores (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario      UUID REFERENCES usuarios(id) ON DELETE CASCADE,
  cpf             TEXT UNIQUE,
  rg              TEXT,
  data_nascimento DATE,
  telefone        TEXT,
  formacao        TEXT,
  certificados    TEXT,
  especialidades  TEXT[],  -- array de especialidades
  publico_atendido TEXT[] DEFAULT ARRAY['idoso']::TEXT[] NOT NULL,  -- array de públicos atendidos
  disponibilidade JSONB DEFAULT '{}',  -- {"seg": ["08:00","18:00"], "ter": [...], ...}
  valor_hora      NUMERIC(10,2) DEFAULT 0,
  status          TEXT CHECK (status IN ('ativo', 'inativo', 'ferias')) DEFAULT 'ativo',
  avaliacao_media NUMERIC(3,2) DEFAULT 0,
  total_avaliacoes INT DEFAULT 0,
  bio             TEXT,
  foto_url        TEXT,
  cep             TEXT,
  logradouro      TEXT,
  numero          TEXT,
  cidade          TEXT,
  estado          CHAR(2),
  criado_em       TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 5. ESCALAS DE SERVIÇO
-- ============================================================
CREATE TABLE IF NOT EXISTS escalas_servicos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_idoso        UUID REFERENCES idosos(id),
  id_cuidador     UUID REFERENCES cuidadores(id),
  data_inicio     TIMESTAMPTZ NOT NULL,
  data_termino    TIMESTAMPTZ NOT NULL,
  valor_hora      NUMERIC(10,2),
  valor_total     NUMERIC(10,2),
  status          TEXT CHECK (status IN ('agendado','em_andamento','concluido','cancelado')) DEFAULT 'agendado',
  -- Check-in / Check-out
  checkin_hora    TIMESTAMPTZ,
  checkin_lat     NUMERIC(10,7),
  checkin_lng     NUMERIC(10,7),
  checkout_hora   TIMESTAMPTZ,
  checkout_lat    NUMERIC(10,7),
  checkout_lng    NUMERIC(10,7),
  -- Financeiro
  pago            BOOLEAN DEFAULT FALSE,
  data_pagamento  DATE,
  observacoes     TEXT,
  criado_em       TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 6. ATIVIDADES DO CHECKLIST (por escala)
-- ============================================================
CREATE TABLE IF NOT EXISTS atividades_escala (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_escala        UUID REFERENCES escalas_servicos(id) ON DELETE CASCADE,
  descricao        TEXT NOT NULL,
  horario_previsto TIME,
  concluida        BOOLEAN DEFAULT FALSE,
  hora_conclusao   TIMESTAMPTZ,
  ordem            INT DEFAULT 0
);

-- ============================================================
-- 7. DIÁRIO DE CUIDADOS
-- ============================================================
CREATE TABLE IF NOT EXISTS diario_cuidados (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_escala               UUID REFERENCES escalas_servicos(id) ON DELETE CASCADE,
  horario                 TIMESTAMPTZ DEFAULT NOW(),
  -- Sinais vitais
  batimento_cardiaco      INT,       -- bpm
  pressao_arterial        TEXT,      -- ex: "120/80"
  temperatura             NUMERIC(4,1),  -- ºC
  saturacao_oxigenio      INT,       -- %
  glicemia                NUMERIC(5,1),  -- mg/dL
  -- Cuidados
  alimentacao             TEXT CHECK (alimentacao IN ('aceitou','recusou','parcial')),
  hidratacao              TEXT CHECK (hidratacao IN ('boa','regular','insuficiente')),
  medicamento_ministrado  BOOLEAN DEFAULT FALSE,
  medicamentos_lista      TEXT,      -- quais medicamentos foram dados
  banho_realizado         BOOLEAN DEFAULT FALSE,
  humor                   TEXT CHECK (humor IN ('otimo','bom','regular','agitado','sonolento','triste')),
  -- Mídia e notas
  foto_url                TEXT,
  observacoes             TEXT,
  visivel_familia         BOOLEAN DEFAULT TRUE,
  criado_em               TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 8. AVALIAÇÕES
-- ============================================================
CREATE TABLE IF NOT EXISTS avaliacoes (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_escala    UUID REFERENCES escalas_servicos(id),
  id_cuidador  UUID REFERENCES cuidadores(id),
  id_cliente   UUID REFERENCES clientes_familia(id),
  nota         INT CHECK (nota BETWEEN 1 AND 5),
  comentario   TEXT,
  criado_em    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ÍNDICES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_escalas_cuidador   ON escalas_servicos(id_cuidador);
CREATE INDEX IF NOT EXISTS idx_escalas_idoso      ON escalas_servicos(id_idoso);
CREATE INDEX IF NOT EXISTS idx_escalas_status     ON escalas_servicos(status);
CREATE INDEX IF NOT EXISTS idx_escalas_data       ON escalas_servicos(data_inicio, data_termino);
CREATE INDEX IF NOT EXISTS idx_diario_escala      ON diario_cuidados(id_escala);
CREATE INDEX IF NOT EXISTS idx_idosos_cliente     ON idosos(id_cliente);
CREATE INDEX IF NOT EXISTS idx_usuarios_tipo      ON usuarios(tipo);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE usuarios           ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes_familia   ENABLE ROW LEVEL SECURITY;
ALTER TABLE idosos             ENABLE ROW LEVEL SECURITY;
ALTER TABLE cuidadores         ENABLE ROW LEVEL SECURITY;
ALTER TABLE escalas_servicos   ENABLE ROW LEVEL SECURITY;
ALTER TABLE atividades_escala  ENABLE ROW LEVEL SECURITY;
ALTER TABLE diario_cuidados    ENABLE ROW LEVEL SECURITY;
ALTER TABLE avaliacoes         ENABLE ROW LEVEL SECURITY;

-- Políticas básicas (ajuste conforme necessidade de segurança)
-- Admins têm acesso total
CREATE POLICY "admin_all" ON usuarios
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.auth_id = auth.uid() AND u.tipo = 'administrador'
    )
  );

-- Usuário pode ler/editar seus próprios dados
CREATE POLICY "proprio_usuario" ON usuarios
  FOR SELECT USING (auth_id = auth.uid());

-- ============================================================
-- TRIGGER: atualizar campo atualizado_em automaticamente
-- ============================================================
CREATE OR REPLACE FUNCTION update_atualizado_em()
RETURNS TRIGGER AS $$
BEGIN
  NEW.atualizado_em = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_usuarios_atualizado
  BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION update_atualizado_em();

CREATE TRIGGER trg_idosos_atualizado
  BEFORE UPDATE ON idosos
  FOR EACH ROW EXECUTE FUNCTION update_atualizado_em();

CREATE TRIGGER trg_cuidadores_atualizado
  BEFORE UPDATE ON cuidadores
  FOR EACH ROW EXECUTE FUNCTION update_atualizado_em();

CREATE TRIGGER trg_escalas_atualizado
  BEFORE UPDATE ON escalas_servicos
  FOR EACH ROW EXECUTE FUNCTION update_atualizado_em();

-- ============================================================
-- DADOS DE EXEMPLO (comentar em produção)
-- ============================================================
/*
INSERT INTO usuarios (nome, email, tipo) VALUES
  ('Admin CuideLar', 'admin@cuideLar.com.br', 'administrador'),
  ('Maria Souza', 'maria@cuideLar.com.br', 'cuidador'),
  ('João Família', 'joao@email.com', 'cliente');
*/

-- ============================================================
-- MIGRATION NOTES (Para bancos de dados já existentes)
-- ============================================================
-- Executar caso o banco já esteja criado para adicionar as colunas do novo público:
-- ALTER TABLE idosos ADD COLUMN IF NOT EXISTS perfil TEXT CHECK (perfil IN ('idoso', 'crianca_autista')) DEFAULT 'idoso' NOT NULL;
-- ALTER TABLE cuidadores ADD COLUMN IF NOT EXISTS publico_atendido TEXT[] DEFAULT ARRAY['idoso']::TEXT[] NOT NULL;

