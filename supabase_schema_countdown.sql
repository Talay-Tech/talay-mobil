-- Countdown Settings Table
-- Zamanlayıcı ayarları için tablo

CREATE TABLE countdown_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  is_active BOOLEAN DEFAULT true,
  main_title TEXT NOT NULL,
  sub_title TEXT,
  description TEXT,
  target_date TIMESTAMPTZ NOT NULL,
  expired_message TEXT DEFAULT 'Süre doldu',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Sadece tek kayıt olmasını sağla (singleton pattern)
CREATE UNIQUE INDEX countdown_settings_singleton ON countdown_settings ((true));

-- Row Level Security
ALTER TABLE countdown_settings ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir
CREATE POLICY "Everyone can view countdown_settings" 
  ON countdown_settings FOR SELECT 
  USING (true);

-- Sadece adminler değiştirebilir
CREATE POLICY "Only admins can insert countdown_settings" 
  ON countdown_settings FOR INSERT 
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Only admins can update countdown_settings" 
  ON countdown_settings FOR UPDATE 
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Only admins can delete countdown_settings" 
  ON countdown_settings FOR DELETE 
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_countdown_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER countdown_settings_updated_at
  BEFORE UPDATE ON countdown_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_countdown_updated_at();

-- Örnek veri ekle
INSERT INTO countdown_settings (main_title, sub_title, description, target_date, expired_message)
VALUES (
  'Büyük Açılış',
  'Yeni dönem başlıyor',
  'Heyecan verici yeniliklerle dolu yeni dönemimize hazır olun!',
  '2026-06-01 00:00:00+03',
  'Etkinlik başladı!'
);
