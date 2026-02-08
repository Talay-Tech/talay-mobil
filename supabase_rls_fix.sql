-- =====================================================
-- RSS KAYNAKLARI RLS POLİTİKASI DÜZELTMESİ
-- =====================================================
-- Admin kullanıcıların tüm kaynaklara erişebilmesi için
-- SELECT politikası güncelleniyor.
-- =====================================================

-- Mevcut SELECT politikasını kaldır
DROP POLICY IF EXISTS "Everyone can view active rss sources" ON rss_sources;

-- Yeni SELECT politikası: Herkes aktif kaynakları görebilir, adminler tümünü görebilir
CREATE POLICY "View rss sources" ON rss_sources
    FOR SELECT USING (
        is_active = true 
        OR 
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- =====================================================
-- DONE! RLS policy has been fixed.
-- =====================================================
