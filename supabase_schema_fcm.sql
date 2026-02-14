-- ============================================
-- Talay FCM Device Tokens Schema
-- ============================================

-- Device tokens table for push notifications
CREATE TABLE IF NOT EXISTS public.device_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    platform TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index for fast lookups by user
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON public.device_tokens(user_id);

-- Enable RLS
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

-- Users can insert their own tokens
CREATE POLICY "Users can insert their own device tokens"
    ON public.device_tokens FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own tokens
CREATE POLICY "Users can update their own device tokens"
    ON public.device_tokens FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own tokens
CREATE POLICY "Users can delete their own device tokens"
    ON public.device_tokens FOR DELETE
    USING (auth.uid() = user_id);

-- Users can read their own tokens
CREATE POLICY "Users can read their own device tokens"
    ON public.device_tokens FOR SELECT
    USING (auth.uid() = user_id);

-- Admin can read all tokens (for sending push notifications)
CREATE POLICY "Admin can read all device tokens"
    ON public.device_tokens FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );
