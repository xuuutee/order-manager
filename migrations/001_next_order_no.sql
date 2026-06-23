-- ============================================================
-- 迁移 001: 原子自增订单编号生成器
-- 用途: 彻底杜绝 order_no 并发生成重复
-- 执行方式: 在 Supabase Dashboard → SQL Editor 中运行此脚本
-- 创建日期: 2026-06-24
-- ============================================================

-- 1. 创建序列表（每天一行，last_seq 自增）
CREATE TABLE IF NOT EXISTS order_sequences (
  date_key TEXT PRIMARY KEY,       -- 格式: "2026-6-24"
  last_seq INTEGER NOT NULL DEFAULT 0
);

-- 2. 开启 RLS 但允许所有认证用户操作（序列表不暴露给客户端直接 CRUD）
ALTER TABLE order_sequences ENABLE ROW LEVEL SECURITY;

-- 3. 创建原子自增函数
--    INSERT .. ON CONFLICT .. DO UPDATE 是单条原子 SQL，
--    PostgreSQL 的行级锁保证并发调用拿到的 last_seq 永不重复。
CREATE OR REPLACE FUNCTION next_order_no()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER        -- 以创建者权限运行，绕过 RLS
AS $$
DECLARE
  today_key TEXT;
  seq INTEGER;
BEGIN
  -- 组装当天日期键 (与旧格式兼容: 2026-6-24)
  today_key := EXTRACT(YEAR FROM NOW()) || '-'
            || EXTRACT(MONTH FROM NOW()) || '-'
            || EXTRACT(DAY FROM NOW());

  -- 原子 UPSERT: 不存在则插入 last_seq=1，存在则 last_seq+1
  INSERT INTO order_sequences (date_key, last_seq)
  VALUES (today_key, 1)
  ON CONFLICT (date_key)
  DO UPDATE SET last_seq = order_sequences.last_seq + 1
  RETURNING last_seq INTO seq;

  -- 返回完整编号
  RETURN today_key || '-' || seq;
END;
$$;

-- 4. 验证
-- SELECT next_order_no();  -- 预期: "2026-6-24-1"
-- SELECT next_order_no();  -- 预期: "2026-6-24-2"
