-- ================================================================
-- Migration: 订单号原子序列
--
-- 解决并发创建订单时 order_no 可能重复的竞态问题。
-- 用 PostgreSQL INSERT ... ON CONFLICT DO UPDATE 在数据库层
-- 原子递增每日序列号，彻底杜绝重复。
--
-- 用法:
--   SELECT next_order_seq('2026-6-24');  → 返回下一个序号 (integer)
--
-- 执行方式: 在 Supabase SQL Editor 中运行本文件全部内容
-- ================================================================

-- 1. 序列表 —— 存储每天的最新序号
CREATE TABLE IF NOT EXISTS order_sequences (
    date_key TEXT PRIMARY KEY,
    last_seq INTEGER NOT NULL DEFAULT 0
);

-- 2. 开启 RLS（但允许 anon 调用 RPC）
ALTER TABLE order_sequences ENABLE ROW LEVEL SECURITY;

-- 3. 原子自增函数
--    使用 INSERT ... ON CONFLICT DO UPDATE 保证原子性:
--    - 当天第一条记录: INSERT 写入 1
--    - 后续: UPDATE last_seq = last_seq + 1 RETURNING
--    PostgreSQL 保证单个语句的原子性 —— 多个并发调用永远不会返回相同值
CREATE OR REPLACE FUNCTION next_order_seq(p_date_key TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_seq INTEGER;
BEGIN
    INSERT INTO order_sequences (date_key, last_seq)
    VALUES (p_date_key, 1)
    ON CONFLICT (date_key)
    DO UPDATE SET last_seq = order_sequences.last_seq + 1
    RETURNING last_seq INTO v_seq;

    RETURN v_seq;
END;
$$;

-- 4. 授予 anon 角色执行权限
GRANT EXECUTE ON FUNCTION next_order_seq(TEXT) TO anon, authenticated, service_role;
