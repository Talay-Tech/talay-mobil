-- =====================================================
-- TALAY APP - MESSAGING SYSTEM SCHEMA
-- =====================================================
-- Bu SQL dosyasını Supabase SQL Editor'da çalıştırın
-- Sadece mesajlaşma tabloları oluşturulur
-- =====================================================

-- =====================================================
-- 1. CONVERSATIONS TABLE (Sohbetler)
-- =====================================================
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_1_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    user_2_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    last_message TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Aynı iki kullanıcı arasında sadece 1 sohbet olabilir
    CONSTRAINT unique_conversation UNIQUE (user_1_id, user_2_id),
    -- Kullanıcı kendisiyle sohbet başlatamaz
    CONSTRAINT different_users CHECK (user_1_id != user_2_id)
);

-- Enable RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view their conversations" ON conversations;
DROP POLICY IF EXISTS "Authenticated users can create conversations" ON conversations;
DROP POLICY IF EXISTS "Conversation participants can update" ON conversations;

-- Policies for conversations
CREATE POLICY "Users can view their conversations" ON conversations
    FOR SELECT USING (
        auth.uid() = user_1_id OR auth.uid() = user_2_id
    );

CREATE POLICY "Authenticated users can create conversations" ON conversations
    FOR INSERT WITH CHECK (
        auth.uid() = user_1_id OR auth.uid() = user_2_id
    );

CREATE POLICY "Conversation participants can update" ON conversations
    FOR UPDATE USING (
        auth.uid() = user_1_id OR auth.uid() = user_2_id
    );

-- Enable realtime (ignore error if already added)
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;

-- =====================================================
-- 2. MESSAGES TABLE (Mesajlar)
-- =====================================================
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Conversation participants can view messages" ON messages;
DROP POLICY IF EXISTS "Conversation participants can send messages" ON messages;

-- Policies for messages
CREATE POLICY "Conversation participants can view messages" ON messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conversations c
            WHERE c.id = messages.conversation_id
            AND (auth.uid() = c.user_1_id OR auth.uid() = c.user_2_id)
        )
    );

CREATE POLICY "Conversation participants can send messages" ON messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
            SELECT 1 FROM conversations c
            WHERE c.id = messages.conversation_id
            AND (auth.uid() = c.user_1_id OR auth.uid() = c.user_2_id)
        )
    );

-- Enable realtime
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE messages;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;

-- =====================================================
-- 3. TRIGGER: Update conversation on new message
-- =====================================================
CREATE OR REPLACE FUNCTION update_conversation_on_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations
    SET last_message = NEW.message, updated_at = NOW()
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_message_sent ON messages;
CREATE TRIGGER on_message_sent
    AFTER INSERT ON messages
    FOR EACH ROW EXECUTE FUNCTION update_conversation_on_message();

-- =====================================================
-- DONE! Messaging tables are ready.
-- =====================================================
