-- =====================================================
-- TALAY APP - RSS FEED SYSTEM SCHEMA
-- =====================================================
-- Bu SQL dosyasını Supabase SQL Editor'da çalıştırın
-- =====================================================

-- =====================================================
-- 1. RSS_SOURCES TABLE (RSS Kaynakları)
-- =====================================================
CREATE TABLE IF NOT EXISTS rss_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    url TEXT NOT NULL,
    category TEXT DEFAULT 'genel',
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE rss_sources ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Everyone can view active rss sources" ON rss_sources;
DROP POLICY IF EXISTS "Admins can manage rss sources" ON rss_sources;
DROP POLICY IF EXISTS "View rss sources" ON rss_sources;

-- FIXED POLICY: Herkes aktif kaynakları görebilir, adminler tümünü görebilir
CREATE POLICY "View rss sources" ON rss_sources
    FOR SELECT USING (
        is_active = true 
        OR 
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can manage rss sources" ON rss_sources
    FOR ALL USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Enable realtime
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE rss_sources;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;

-- =====================================================
-- 2. RSS_ITEMS TABLE (Cache'lenmiş RSS İçerikleri)
-- =====================================================
CREATE TABLE IF NOT EXISTS rss_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_id UUID REFERENCES rss_sources(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    link TEXT NOT NULL,
    image_url TEXT,
    pub_date TIMESTAMPTZ,
    guid TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_guid_per_source UNIQUE (source_id, guid)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_rss_items_source_id ON rss_items(source_id);
CREATE INDEX IF NOT EXISTS idx_rss_items_pub_date ON rss_items(pub_date DESC);

-- Enable RLS
ALTER TABLE rss_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Everyone can view rss items" ON rss_items;
DROP POLICY IF EXISTS "Admins can manage rss items" ON rss_items;

-- Policies
CREATE POLICY "Everyone can view rss items" ON rss_items
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage rss items" ON rss_items
    FOR ALL USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Enable realtime
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE rss_items;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;

-- =====================================================
-- DONE! RSS tables are ready.
-- =====================================================
