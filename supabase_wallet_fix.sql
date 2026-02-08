-- =====================================================
-- FIX: Add DELETE policy for wallet_transactions
-- =====================================================
-- Bu SQL'i Supabase SQL Editor'da çalıştırın

-- Drop existing policy if any
DROP POLICY IF EXISTS "Admins can delete transactions" ON wallet_transactions;

-- Add DELETE policy for admins
CREATE POLICY "Admins can delete transactions" ON wallet_transactions
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Also add UPDATE policy for completeness
DROP POLICY IF EXISTS "Admins can update transactions" ON wallet_transactions;

CREATE POLICY "Admins can update transactions" ON wallet_transactions
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
