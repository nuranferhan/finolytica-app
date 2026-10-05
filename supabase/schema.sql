-- Users tablosu
CREATE TABLE users (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  currency TEXT DEFAULT 'TRY',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Categories tablosu
CREATE TABLE categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  type TEXT CHECK (type IN ('income', 'expense')) NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Transactions tablosu
CREATE TABLE transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  type TEXT CHECK (type IN ('income', 'expense')) NOT NULL,
  description TEXT,
  date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Investments tablosu
CREATE TABLE investments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  symbol TEXT NOT NULL,
  name TEXT NOT NULL,
  type TEXT CHECK (type IN ('stock', 'crypto', 'gold', 'forex')) NOT NULL,
  amount DECIMAL(15,8) NOT NULL,
  purchase_price DECIMAL(15,2) NOT NULL,
  current_price DECIMAL(15,2),
  purchase_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- RLS Politikaları
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE investments ENABLE ROW LEVEL SECURITY;

-- Users politikaları
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);

-- Categories politikaları
CREATE POLICY "Users can manage own categories" ON categories FOR ALL USING (auth.uid() = user_id);

-- Transactions politikaları  
CREATE POLICY "Users can manage own transactions" ON transactions FOR ALL USING (auth.uid() = user_id);

-- Investments politikaları
CREATE POLICY "Users can manage own investments" ON investments FOR ALL USING (auth.uid() = user_id);

-- Eksik INSERT politikası
CREATE POLICY "Users can insert own data" ON users FOR INSERT WITH CHECK (auth.uid() = id);

-- Otomatik profil oluşturma function'ı
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, currency)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Kullanıcı'),
    'TRY'
  );
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Hata olursa log'la ama trigger'ı başarısız yapma
    RAISE WARNING 'Could not create user profile: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger oluştur
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Test için function
CREATE OR REPLACE FUNCTION public.test_user_creation()
RETURNS TEXT AS $$
BEGIN
  RETURN 'User creation function is ready!';
END;
$$ LANGUAGE plpgsql;

SELECT public.test_user_creation();

SELECT user_id, title, amount, type, created_at 
FROM transactions 
ORDER BY created_at DESC;

-- Önce trigger'ı sil
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Sonra fonksiyonu sil
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Sonra yeni fonksiyonu oluştur
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Önce kullanıcı profilini oluştur
  INSERT INTO public.users (id, email, full_name, currency)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Kullanıcı'),
    'TRY'
  );
  
  -- Sonra default kategorileri oluştur (constants.dart'taki ile uyumlu)
  INSERT INTO public.categories (name, icon, color, type, user_id) VALUES
    -- Gider Kategorileri
    ('Gıda & İçecek', '🍕', '4294936283', 'expense', NEW.id),
    ('Ulaşım', '🚗', '4283354564', 'expense', NEW.id),
    ('Kira', '🏠', '4281558481', 'expense', NEW.id),
    ('Eğlence', '🎬', '4284481716', 'expense', NEW.id),
    ('Sağlık', '💊', '4293256814', 'expense', NEW.id),
    ('Alışveriş', '🛍️', '4292817493', 'expense', NEW.id),
    ('Diğer', '📊', '4282400255', 'expense', NEW.id),
    
    -- Gelir Kategorileri
    ('Maaş', '💰', '4285479655', 'income', NEW.id),
    ('Freelance', '💼', '4287137790', 'income', NEW.id),
    ('Yatırım Getiri', '📈', '4278241428', 'income', NEW.id),
    ('Diğer', '📊', '4282400255', 'income', NEW.id);
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Hata olursa log'la ama trigger'ı başarısız yapma
    RAISE WARNING 'Could not create user profile or categories: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger'ı yeniden oluştur
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Mevcut kullanıcılar için kategorileri oluştur (eğer yoksa)
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN SELECT id FROM public.users LOOP
        -- Kullanıcının kategorisi var mı kontrol et
        IF NOT EXISTS (SELECT 1 FROM public.categories WHERE user_id = user_record.id) THEN
            -- Kategorileri oluştur
            INSERT INTO public.categories (name, icon, color, type, user_id) VALUES
                -- Gider Kategorileri
                ('Gıda & İçecek', '🍕', '4294936283', 'expense', user_record.id),
                ('Ulaşım', '🚗', '4283354564', 'expense', user_record.id),
                ('Kira', '🏠', '4281558481', 'expense', user_record.id),
                ('Eğlence', '🎬', '4284481716', 'expense', user_record.id),
                ('Sağlık', '💊', '4293256814', 'expense', user_record.id),
                ('Alışveriş', '🛍️', '4292817493', 'expense', user_record.id),
                ('Diğer', '📊', '4282400255', 'expense', user_record.id),
                
                -- Gelir Kategorileri
                ('Maaş', '💰', '4285479655', 'income', user_record.id),
                ('Freelance', '💼', '4287137790', 'income', user_record.id),
                ('Yatırım Getiri', '📈', '4278241428', 'income', user_record.id),
                ('Diğer', '📊', '4282400255', 'income', user_record.id);
            
            RAISE NOTICE 'Categories created for user: %', user_record.id;
        END IF;
    END LOOP;
END;
$$;

-- Mevcut investments tablosunu güncelle
ALTER TABLE investments ADD COLUMN IF NOT EXISTS last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Yeni tablo: Savings Goals (Tasarruf Hedefleri)
CREATE TABLE IF NOT EXISTS savings_goals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  target_amount DECIMAL(15,2) NOT NULL,
  current_amount DECIMAL(15,2) DEFAULT 0,
  target_date DATE,
  category TEXT DEFAULT 'general', -- 'emergency', 'vacation', 'house', 'car', 'general'
  color TEXT DEFAULT '4285479655',
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Yeni tablo: Exchange Rates (Döviz Kurları)
CREATE TABLE IF NOT EXISTS exchange_rates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  base_currency TEXT NOT NULL DEFAULT 'TRY',
  target_currency TEXT NOT NULL,
  rate DECIMAL(15,6) NOT NULL,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(base_currency, target_currency)
);

-- Yeni tablo: Watchlist (İzleme Listesi) - Basit döviz takibi için
CREATE TABLE IF NOT EXISTS watchlist (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  symbol TEXT NOT NULL, -- USD, EUR, GBP vs
  name TEXT NOT NULL,
  type TEXT CHECK (type IN ('forex', 'crypto', 'stock')) DEFAULT 'forex',
  current_price DECIMAL(15,6),
  previous_price DECIMAL(15,6),
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(user_id, symbol)
);

-- Yeni tablo: Goal Transactions (Hedef için yapılan işlemler)
CREATE TABLE IF NOT EXISTS goal_transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  goal_id UUID REFERENCES savings_goals(id) ON DELETE CASCADE,
  amount DECIMAL(15,2) NOT NULL,
  description TEXT,
  transaction_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- RLS Politikaları
ALTER TABLE savings_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE exchange_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE watchlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_transactions ENABLE ROW LEVEL SECURITY;

-- Savings Goals politikaları
CREATE POLICY "Users can manage own goals" ON savings_goals FOR ALL USING (auth.uid() = user_id);

-- Exchange Rates politikaları (herkes okuyabilir, sadmin update eder)
CREATE POLICY "Everyone can view exchange rates" ON exchange_rates FOR SELECT USING (true);

-- Watchlist politikaları
CREATE POLICY "Users can manage own watchlist" ON watchlist FOR ALL USING (auth.uid() = user_id);

-- Goal Transactions politikaları
CREATE POLICY "Users can manage own goal transactions" ON goal_transactions FOR ALL USING (auth.uid() = user_id);

-- Default döviz kurları ekle
INSERT INTO exchange_rates (base_currency, target_currency, rate) VALUES
('TRY', 'USD', 0.030),
('TRY', 'EUR', 0.028),
('TRY', 'GBP', 0.024),
('TRY', 'CHF', 0.027)
ON CONFLICT (base_currency, target_currency) DO NOTHING;

-- Fonksiyon: Hedef tamamlanma kontrolü
CREATE OR REPLACE FUNCTION check_goal_completion()
RETURNS TRIGGER AS $$
BEGIN
  -- Hedef tutara ulaşıldıysa tamamla
  IF NEW.current_amount >= (SELECT target_amount FROM savings_goals WHERE id = NEW.goal_id) THEN
    UPDATE savings_goals 
    SET is_completed = TRUE, completed_at = NOW() 
    WHERE id = NEW.goal_id AND NOT is_completed;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Goal transaction eklendiğinde hedef tutarını güncelle
CREATE OR REPLACE FUNCTION update_goal_amount()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE savings_goals 
    SET current_amount = current_amount + NEW.amount 
    WHERE id = NEW.goal_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE savings_goals 
    SET current_amount = current_amount - OLD.amount,
        is_completed = FALSE,
        completed_at = NULL
    WHERE id = OLD.goal_id;
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE savings_goals 
    SET current_amount = current_amount - OLD.amount + NEW.amount 
    WHERE id = NEW.goal_id;
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers
DROP TRIGGER IF EXISTS goal_transaction_trigger ON goal_transactions;
CREATE TRIGGER goal_transaction_trigger
  AFTER INSERT OR UPDATE OR DELETE ON goal_transactions
  FOR EACH ROW EXECUTE FUNCTION update_goal_amount();

DROP TRIGGER IF EXISTS goal_completion_trigger ON goal_transactions;  
CREATE TRIGGER goal_completion_trigger
  AFTER INSERT OR UPDATE ON goal_transactions
  FOR EACH ROW EXECUTE FUNCTION check_goal_completion();

  -- Önce mevcut trigger'ları ve fonksiyonları temizle
DROP TRIGGER IF EXISTS goal_transaction_trigger ON goal_transactions;
DROP TRIGGER IF EXISTS goal_completion_trigger ON goal_transactions;
DROP FUNCTION IF EXISTS update_goal_amount();
DROP FUNCTION IF EXISTS check_goal_completion();

-- Yeni ve düzeltilmiş fonksiyon: Goal amount güncelleme
CREATE OR REPLACE FUNCTION update_goal_amount()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Yeni kayıt eklendiğinde hedefteki mevcut tutarı artır
    UPDATE savings_goals 
    SET current_amount = COALESCE(current_amount, 0) + NEW.amount 
    WHERE id = NEW.goal_id;
    
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Kayıt silindiğinde hedefteki tutarı azalt ve tamamlanmış durumunu sıfırla
    UPDATE savings_goals 
    SET 
      current_amount = GREATEST(COALESCE(current_amount, 0) - OLD.amount, 0),
      is_completed = FALSE,
      completed_at = NULL
    WHERE id = OLD.goal_id;
    
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Kayıt güncellendiğinde fark kadar ayarla
    UPDATE savings_goals 
    SET current_amount = COALESCE(current_amount, 0) - OLD.amount + NEW.amount 
    WHERE id = NEW.goal_id;
    
    RETURN NEW;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Hedef tamamlanma kontrolü fonksiyonu
CREATE OR REPLACE FUNCTION check_goal_completion()
RETURNS TRIGGER AS $$
DECLARE
  goal_record savings_goals%ROWTYPE;
BEGIN
  -- Güncellenmiş hedfi al
  SELECT * INTO goal_record 
  FROM savings_goals 
  WHERE id = NEW.goal_id;
  
  -- Eğer mevcut tutar hedef tutara ulaştıysa tamamla
  IF goal_record.current_amount >= goal_record.target_amount AND NOT goal_record.is_completed THEN
    UPDATE savings_goals 
    SET 
      is_completed = TRUE, 
      completed_at = NOW(),
      current_amount = target_amount -- Tam tutarı ayarla
    WHERE id = NEW.goal_id;
    
    RAISE NOTICE 'Goal completed: %', goal_record.title;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ları yeniden oluştur
CREATE TRIGGER goal_transaction_trigger
  AFTER INSERT OR UPDATE OR DELETE ON goal_transactions
  FOR EACH ROW 
  EXECUTE FUNCTION update_goal_amount();

CREATE TRIGGER goal_completion_trigger
  AFTER INSERT OR UPDATE ON goal_transactions
  FOR EACH ROW 
  EXECUTE FUNCTION check_goal_completion();

-- Test için mevcut verileri kontrol et ve düzelt
DO $$
DECLARE
  goal_record RECORD;
  calculated_amount DECIMAL(15,2);
BEGIN
  FOR goal_record IN SELECT id, title FROM savings_goals LOOP
    -- Her hedef için mevcut işlemlerden toplam tutarı hesapla
    SELECT COALESCE(SUM(amount), 0) 
    INTO calculated_amount
    FROM goal_transactions 
    WHERE goal_id = goal_record.id;
    
    -- Hesaplanan tutar ile mevcut tutarı eşitle
    UPDATE savings_goals 
    SET 
      current_amount = calculated_amount,
      is_completed = (calculated_amount >= target_amount),
      completed_at = CASE 
        WHEN calculated_amount >= target_amount AND NOT is_completed THEN NOW() 
        WHEN calculated_amount < target_amount THEN NULL 
        ELSE completed_at 
      END
    WHERE id = goal_record.id;
    
    RAISE NOTICE 'Goal % updated with amount %', goal_record.title, calculated_amount;
  END LOOP;
END;
$$;

-- Kullanıcı bakiyesini hesaplayan SQL fonksiyon
CREATE OR REPLACE FUNCTION calculate_user_balance(user_uuid UUID)
RETURNS DECIMAL(15,2) AS $$
DECLARE
  total_income DECIMAL(15,2) := 0;
  total_expense DECIMAL(15,2) := 0;
  net_balance DECIMAL(15,2) := 0;
BEGIN
  -- Toplam geliri hesapla
  SELECT COALESCE(SUM(amount), 0) 
  INTO total_income
  FROM transactions 
  WHERE user_id = user_uuid AND type = 'income';
  
  -- Toplam gideri hesapla
  SELECT COALESCE(SUM(amount), 0) 
  INTO total_expense
  FROM transactions 
  WHERE user_id = user_uuid AND type = 'expense';
  
  -- Net bakiyeyi hesapla
  net_balance := total_income - total_expense;
  
  -- Debug log
  RAISE NOTICE 'User % balance: Income=%, Expense=%, Balance=%', 
    user_uuid, total_income, total_expense, net_balance;
  
  RETURN net_balance;
END;
$$ LANGUAGE plpgsql;

-- Test fonksiyonu
CREATE OR REPLACE FUNCTION test_user_balance()
RETURNS TEXT AS $$
DECLARE
  test_user_id UUID;
  balance DECIMAL(15,2);
BEGIN
  -- İlk kullanıcının ID'sini al
  SELECT id INTO test_user_id FROM users LIMIT 1;
  
  IF test_user_id IS NULL THEN
    RETURN 'No users found to test';
  END IF;
  
  -- Bakiyeyi hesapla
  SELECT calculate_user_balance(test_user_id) INTO balance;
  
  RETURN 'Test user ' || test_user_id || ' balance: ' || balance;
END;
$$ LANGUAGE plpgsql;

-- Fonksiyonu test et
SELECT test_user_balance();

-- Tüm kullanıcıların bakiyelerini göster
SELECT 
  u.email,
  u.full_name,
  calculate_user_balance(u.id) as current_balance
FROM users u
ORDER BY current_balance DESC;

-- ============ TASARRUF HEDEFİ TRANSACTION SYNC TRIGGER'LARI ============

-- Önce mevcut trigger'ları ve fonksiyonları temizle
DROP TRIGGER IF EXISTS goal_transaction_trigger ON goal_transactions;
DROP TRIGGER IF EXISTS goal_completion_trigger ON goal_transactions;
DROP TRIGGER IF EXISTS sync_goal_to_main_transactions ON goal_transactions;
DROP FUNCTION IF EXISTS update_goal_amount();
DROP FUNCTION IF EXISTS check_goal_completion();
DROP FUNCTION IF EXISTS sync_goal_transaction_to_main();

-- 1. FONKSIYON: Goal transaction'ını ana transactions'a sync etme
CREATE OR REPLACE FUNCTION sync_goal_transaction_to_main()
RETURNS TRIGGER AS $$
DECLARE
  savings_category_id UUID;
  goal_title TEXT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Hedef bilgilerini al
    SELECT title INTO goal_title 
    FROM savings_goals 
    WHERE id = NEW.goal_id;
    
    -- "Tasarruf" kategorisini bul veya oluştur
    SELECT id INTO savings_category_id
    FROM categories 
    WHERE user_id = NEW.user_id 
      AND name = 'Tasarruf' 
      AND type = 'expense';
    
    -- Eğer Tasarruf kategorisi yoksa oluştur
    IF savings_category_id IS NULL THEN
      INSERT INTO categories (user_id, name, icon, color, type) 
      VALUES (NEW.user_id, 'Tasarruf', '🎯', '4285479655', 'expense')
      RETURNING id INTO savings_category_id;
      
      RAISE NOTICE 'Created Tasarruf category: %', savings_category_id;
    END IF;
    
    -- Ana transactions tablosuna gider kaydı ekle
    INSERT INTO transactions (
      user_id,
      category_id, 
      title,
      amount,
      type,
      description,
      date
    ) VALUES (
      NEW.user_id,
      savings_category_id,
      'Hedef: ' || COALESCE(goal_title, 'Bilinmeyen Hedef'),
      NEW.amount,
      'expense',
      CASE 
        WHEN NEW.description IS NOT NULL AND NEW.description != '' 
        THEN 'Tasarruf hedefi - ' || NEW.description
        ELSE 'Tasarruf hedefi için para aktarımı'
      END,
      NEW.transaction_date
    );
    
    RAISE NOTICE 'Synced goal transaction to main transactions: Amount=%, Goal=%', 
      NEW.amount, goal_title;
    
    RETURN NEW;
    
  ELSIF TG_OP = 'DELETE' THEN
    -- Goal transaction silindiğinde ana transaction'ı da sil
    DELETE FROM transactions 
    WHERE user_id = OLD.user_id 
      AND amount = OLD.amount 
      AND type = 'expense'
      AND date = OLD.transaction_date
      AND description LIKE '%Tasarruf hedefi%'
      AND created_at >= OLD.created_at - INTERVAL '1 minute'
      AND created_at <= OLD.created_at + INTERVAL '1 minute';
    
    RAISE NOTICE 'Deleted synced transaction for goal deletion';
    
    RETURN OLD;
    
  ELSIF TG_OP = 'UPDATE' THEN
    -- Goal transaction güncellendiğinde ana transaction'ı da güncelle
    -- Bu durumda eski kaydı sil, yeni kayıt ekle
    
    -- Eski kaydı sil
    DELETE FROM transactions 
    WHERE user_id = OLD.user_id 
      AND amount = OLD.amount 
      AND type = 'expense'
      AND date = OLD.transaction_date
      AND description LIKE '%Tasarruf hedefi%';
    
    -- Yeni kayıt için aynı logic'i çalıştır
    SELECT title INTO goal_title 
    FROM savings_goals 
    WHERE id = NEW.goal_id;
    
    SELECT id INTO savings_category_id
    FROM categories 
    WHERE user_id = NEW.user_id 
      AND name = 'Tasarruf' 
      AND type = 'expense';
    
    IF savings_category_id IS NULL THEN
      INSERT INTO categories (user_id, name, icon, color, type) 
      VALUES (NEW.user_id, 'Tasarruf', '🎯', '4285479655', 'expense')
      RETURNING id INTO savings_category_id;
    END IF;
    
    INSERT INTO transactions (
      user_id,
      category_id, 
      title,
      amount,
      type,
      description,
      date
    ) VALUES (
      NEW.user_id,
      savings_category_id,
      'Hedef: ' || COALESCE(goal_title, 'Bilinmeyen Hedef'),
      NEW.amount,
      'expense',
      CASE 
        WHEN NEW.description IS NOT NULL AND NEW.description != '' 
        THEN 'Tasarruf hedefi - ' || NEW.description
        ELSE 'Tasarruf hedefi için para aktarımı'
      END,
      NEW.transaction_date
    );
    
    RETURN NEW;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. FONKSIYON: Goal amount güncelleme (eski fonksiyon ama sadeleştirilmiş)
CREATE OR REPLACE FUNCTION update_goal_amount()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Yeni kayıt eklendiğinde hedefteki mevcut tutarı artır
    UPDATE savings_goals 
    SET current_amount = COALESCE(current_amount, 0) + NEW.amount 
    WHERE id = NEW.goal_id;
    
    RETURN NEW;
    
  ELSIF TG_OP = 'DELETE' THEN
    -- Kayıt silindiğinde hedefteki tutarı azalt ve tamamlanmış durumunu kontrol et
    UPDATE savings_goals 
    SET current_amount = GREATEST(COALESCE(current_amount, 0) - OLD.amount, 0)
    WHERE id = OLD.goal_id;
    
    -- Tamamlanma durumunu kontrol et
    UPDATE savings_goals
    SET 
      is_completed = (current_amount >= target_amount),
      completed_at = CASE 
        WHEN current_amount >= target_amount THEN COALESCE(completed_at, NOW())
        ELSE NULL 
      END
    WHERE id = OLD.goal_id;
    
    RETURN OLD;
    
  ELSIF TG_OP = 'UPDATE' THEN
    -- Kayıt güncellendiğinde fark kadar ayarla
    UPDATE savings_goals 
    SET current_amount = COALESCE(current_amount, 0) - OLD.amount + NEW.amount 
    WHERE id = NEW.goal_id;
    
    RETURN NEW;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. FONKSIYON: Goal tamamlanma kontrolü
CREATE OR REPLACE FUNCTION check_goal_completion()
RETURNS TRIGGER AS $$
DECLARE
  goal_record savings_goals%ROWTYPE;
BEGIN
  -- Güncellenmiş hedefi al
  SELECT * INTO goal_record 
  FROM savings_goals 
  WHERE id = NEW.goal_id;
  
  -- Eğer mevcut tutar hedef tutara ulaştıysa tamamla
  IF goal_record.current_amount >= goal_record.target_amount AND NOT goal_record.is_completed THEN
    UPDATE savings_goals 
    SET 
      is_completed = TRUE, 
      completed_at = NOW()
    WHERE id = NEW.goal_id;
    
    RAISE NOTICE 'Goal completed: %', goal_record.title;
  ELSIF goal_record.current_amount < goal_record.target_amount AND goal_record.is_completed THEN
    -- Eğer tutar düştüyse tamamlanmış durumunu kaldır
    UPDATE savings_goals 
    SET 
      is_completed = FALSE, 
      completed_at = NULL
    WHERE id = NEW.goal_id;
    
    RAISE NOTICE 'Goal uncompleted: %', goal_record.title;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============ TRIGGER'LARI OLUŞTUR ============

-- 1. Ana transactions tablosuna sync için trigger (YENİ)
CREATE TRIGGER sync_goal_to_main_transactions
  AFTER INSERT OR UPDATE OR DELETE ON goal_transactions
  FOR EACH ROW 
  EXECUTE FUNCTION sync_goal_transaction_to_main();

-- 2. Goal amount güncelleme için trigger  
CREATE TRIGGER goal_transaction_trigger
  AFTER INSERT OR UPDATE OR DELETE ON goal_transactions
  FOR EACH ROW 
  EXECUTE FUNCTION update_goal_amount();

-- 3. Goal tamamlanma kontrolü için trigger
CREATE TRIGGER goal_completion_trigger
  AFTER INSERT OR UPDATE ON goal_transactions
  FOR EACH ROW 
  EXECUTE FUNCTION check_goal_completion();

-- ============ TEST VE MEVCUT VERİLERİ DÜZELT ============

-- Mevcut goal_transactions verilerini ana transactions'a sync et
DO $$
DECLARE
  goal_transaction_record RECORD;
  savings_category_id UUID;
  goal_title TEXT;
BEGIN
  RAISE NOTICE 'Starting sync of existing goal_transactions to main transactions...';
  
  FOR goal_transaction_record IN 
    SELECT gt.*, sg.title as goal_title
    FROM goal_transactions gt
    JOIN savings_goals sg ON gt.goal_id = sg.id
    ORDER BY gt.created_at
  LOOP
    -- "Tasarruf" kategorisini bul veya oluştur
    SELECT id INTO savings_category_id
    FROM categories 
    WHERE user_id = goal_transaction_record.user_id 
      AND name = 'Tasarruf' 
      AND type = 'expense';
    
    IF savings_category_id IS NULL THEN
      INSERT INTO categories (user_id, name, icon, color, type) 
      VALUES (goal_transaction_record.user_id, 'Tasarruf', '🎯', '4285479655', 'expense')
      RETURNING id INTO savings_category_id;
      
      RAISE NOTICE 'Created Tasarruf category for user: %', goal_transaction_record.user_id;
    END IF;
    
    -- Ana transactions tablosunda bu kayıt var mı kontrol et
    IF NOT EXISTS (
      SELECT 1 FROM transactions 
      WHERE user_id = goal_transaction_record.user_id 
        AND amount = goal_transaction_record.amount
        AND type = 'expense'
        AND date = goal_transaction_record.transaction_date
        AND description LIKE '%Tasarruf hedefi%'
    ) THEN
      -- Yoksa ekle
      INSERT INTO transactions (
        user_id,
        category_id, 
        title,
        amount,
        type,
        description,
        date
      ) VALUES (
        goal_transaction_record.user_id,
        savings_category_id,
        'Hedef: ' || goal_transaction_record.goal_title,
        goal_transaction_record.amount,
        'expense',
        CASE 
          WHEN goal_transaction_record.description IS NOT NULL AND goal_transaction_record.description != '' 
          THEN 'Tasarruf hedefi - ' || goal_transaction_record.description
          ELSE 'Tasarruf hedefi için para aktarımı'
        END,
        goal_transaction_record.transaction_date
      );
      
      RAISE NOTICE 'Synced goal transaction: Amount=%, Goal=%', 
        goal_transaction_record.amount, goal_transaction_record.goal_title;
    ELSE
      RAISE NOTICE 'Transaction already exists for goal transaction: %', goal_transaction_record.id;
    END IF;
  END LOOP;
  
  RAISE NOTICE 'Completed sync of existing goal_transactions to main transactions';
END;
$$;

-- ============ TEST FONKSİYONU ============

-- Test için basit fonksiyon
CREATE OR REPLACE FUNCTION test_goal_transaction_sync()
RETURNS TEXT AS $$
DECLARE
  test_result TEXT;
  goal_count INTEGER;
  transaction_count INTEGER;
BEGIN
  -- Goal transactions sayısı
  SELECT COUNT(*) INTO goal_count FROM goal_transactions;
  
  -- Tasarruf kategorisindeki transactions sayısı
  SELECT COUNT(*) INTO transaction_count 
  FROM transactions t
  JOIN categories c ON t.category_id = c.id
  WHERE c.name = 'Tasarruf' AND c.type = 'expense';
  
  test_result := 'Goal Transactions: ' || goal_count || 
                ', Synced Main Transactions: ' || transaction_count;
  
  RETURN test_result;
END;
$$ LANGUAGE plpgsql;

-- Test et
SELECT test_goal_transaction_sync();

-- ============ MEVCUT VERİLERİ KONTROL ET ============

-- Kullanıcıların goal transactions vs ana transactions karşılaştırması
SELECT 
  u.email,
  u.full_name,
  COUNT(gt.*) as goal_transactions_count,
  COALESCE(SUM(gt.amount), 0) as total_goal_amount,
  COUNT(t.*) as main_transactions_count,
  COALESCE(SUM(t.amount), 0) as total_savings_transactions
FROM users u
LEFT JOIN goal_transactions gt ON u.id = gt.user_id
LEFT JOIN transactions t ON u.id = t.user_id 
  AND t.category_id IN (
    SELECT id FROM categories 
    WHERE user_id = u.id AND name = 'Tasarruf' AND type = 'expense'
  )
GROUP BY u.id, u.email, u.full_name
ORDER BY u.email;

-- ============ HEDEF TAMAMLANMA SAYISI SORUNU DÜZELTMESİ ============

-- 1. Önce mevcut trigger'ları güncelle
DROP TRIGGER IF EXISTS goal_completion_trigger ON goal_transactions;
DROP FUNCTION IF EXISTS check_goal_completion();

-- 2. Yeni ve geliştirilmiş goal completion fonksiyonu
CREATE OR REPLACE FUNCTION check_goal_completion()
RETURNS TRIGGER AS $$
DECLARE
  goal_record savings_goals%ROWTYPE;
  was_completed BOOLEAN;
BEGIN
  -- Güncellenmiş hedefi al
  SELECT * INTO goal_record 
  FROM savings_goals 
  WHERE id = NEW.goal_id;
  
  -- Önceki tamamlanma durumunu kaydet
  was_completed := goal_record.is_completed;
  
  -- Eğer mevcut tutar hedef tutara ulaştıysa tamamla
  IF goal_record.current_amount >= goal_record.target_amount AND NOT goal_record.is_completed THEN
    UPDATE savings_goals 
    SET 
      is_completed = TRUE, 
      completed_at = NOW()
    WHERE id = NEW.goal_id;
    
    RAISE NOTICE '✅ Goal completed: % (%.2f/%.2f)', 
      goal_record.title, goal_record.current_amount, goal_record.target_amount;
      
  ELSIF goal_record.current_amount < goal_record.target_amount AND goal_record.is_completed THEN
    -- Eğer tutar düştüyse tamamlanmış durumunu kaldır
    UPDATE savings_goals 
    SET 
      is_completed = FALSE, 
      completed_at = NULL
    WHERE id = NEW.goal_id;
    
    RAISE NOTICE '❌ Goal uncompleted: % (%.2f/%.2f)', 
      goal_record.title, goal_record.current_amount, goal_record.target_amount;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Trigger'ı yeniden oluştur
CREATE TRIGGER goal_completion_trigger
  AFTER INSERT OR UPDATE ON goal_transactions
  FOR EACH ROW 
  EXECUTE FUNCTION check_goal_completion();

-- 4. Yeni fonksiyon: Kullanıcının tamamlanmış hedef sayısını hesapla
CREATE OR REPLACE FUNCTION get_completed_goals_count(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  completed_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO completed_count
  FROM savings_goals 
  WHERE user_id = user_uuid 
    AND is_completed = TRUE;
    
  RAISE NOTICE 'User % has % completed goals', user_uuid, completed_count;
  
  RETURN completed_count;
END;
$$ LANGUAGE plpgsql;

-- 5. Finansal özet fonksiyonu - KAPSAMLI
CREATE OR REPLACE FUNCTION get_financial_summary(user_uuid UUID)
RETURNS TABLE(
  total_goals_target DECIMAL(15,2),
  total_goals_current DECIMAL(15,2),
  completed_goals INTEGER,
  total_goals INTEGER,
  goals_progress DECIMAL(5,2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(sg.target_amount), 0) as total_goals_target,
    COALESCE(SUM(sg.current_amount), 0) as total_goals_current,
    COUNT(CASE WHEN sg.is_completed THEN 1 END)::INTEGER as completed_goals,
    COUNT(*)::INTEGER as total_goals,
    CASE 
      WHEN COALESCE(SUM(sg.target_amount), 0) > 0 
      THEN (COALESCE(SUM(sg.current_amount), 0) / COALESCE(SUM(sg.target_amount), 1) * 100)::DECIMAL(5,2)
      ELSE 0::DECIMAL(5,2)
    END as goals_progress
  FROM savings_goals sg
  WHERE sg.user_id = user_uuid;
END;
$$ LANGUAGE plpgsql;

-- 6. Test ve mevcut verileri düzelt
DO $$
DECLARE
  goal_record RECORD;
  calculated_amount DECIMAL(15,2);
  should_be_completed BOOLEAN;
BEGIN
  RAISE NOTICE '🔧 Starting goal completion status fix...';
  
  FOR goal_record IN 
    SELECT id, title, target_amount, current_amount, is_completed
    FROM savings_goals 
    ORDER BY title
  LOOP
    -- Her hedef için mevcut işlemlerden toplam tutarı yeniden hesapla
    SELECT COALESCE(SUM(amount), 0) 
    INTO calculated_amount
    FROM goal_transactions 
    WHERE goal_id = goal_record.id;
    
    -- Tamamlanma durumunu belirle
    should_be_completed := (calculated_amount >= goal_record.target_amount);
    
    -- Hedefi güncelle
    UPDATE savings_goals 
    SET 
      current_amount = calculated_amount,
      is_completed = should_be_completed,
      completed_at = CASE 
        WHEN should_be_completed AND NOT goal_record.is_completed THEN NOW() 
        WHEN NOT should_be_completed THEN NULL 
        ELSE completed_at 
      END
    WHERE id = goal_record.id;
    
    RAISE NOTICE 'Goal: % | Amount: %.2f/%.2f | Completed: % -> %', 
      goal_record.title, calculated_amount, goal_record.target_amount,
      goal_record.is_completed, should_be_completed;
  END LOOP;
  
  RAISE NOTICE '✅ Goal completion status fix completed';
END;
$$;

-- 7. Test fonksiyonu
CREATE OR REPLACE FUNCTION test_goal_completion_counts()
RETURNS TEXT AS $$
DECLARE
  user_record RECORD;
  summary_data RECORD;
  result_text TEXT := '';
BEGIN
  result_text := 'GOAL COMPLETION SUMMARY:' || E'\n';
  result_text := result_text || '========================' || E'\n';
  
  FOR user_record IN 
    SELECT id, email, full_name FROM users 
    WHERE id IN (SELECT DISTINCT user_id FROM savings_goals)
  LOOP
    -- Finansal özeti al
    SELECT * INTO summary_data
    FROM get_financial_summary(user_record.id);
    
    result_text := result_text || 
      'User: ' || COALESCE(user_record.full_name, user_record.email) || E'\n' ||
      '  Total Goals: ' || summary_data.total_goals || E'\n' ||
      '  Completed: ' || summary_data.completed_goals || E'\n' ||
      '  Progress: ' || summary_data.goals_progress || '%' || E'\n' ||
      '  Target: ₺' || summary_data.total_goals_target || E'\n' ||
      '  Current: ₺' || summary_data.total_goals_current || E'\n' ||
      '------------------------' || E'\n';
  END LOOP;
  
  RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Test et
SELECT test_goal_completion_counts();

-- 8. View oluştur - kolay raporlama için
CREATE OR REPLACE VIEW goals_summary_view AS
SELECT 
  u.email,
  u.full_name,
  COUNT(sg.*) as total_goals,
  COUNT(CASE WHEN sg.is_completed THEN 1 END) as completed_goals,
  COALESCE(SUM(sg.target_amount), 0) as total_target,
  COALESCE(SUM(sg.current_amount), 0) as total_current,
  CASE 
    WHEN COALESCE(SUM(sg.target_amount), 0) > 0 
    THEN ROUND((COALESCE(SUM(sg.current_amount), 0) / COALESCE(SUM(sg.target_amount), 1) * 100)::NUMERIC, 2)
    ELSE 0
  END as progress_percentage
FROM users u
LEFT JOIN savings_goals sg ON u.id = sg.user_id
GROUP BY u.id, u.email, u.full_name
ORDER BY u.email;

-- Test view
SELECT * FROM goals_summary_view;

-- Tüm view'ları listele
SELECT table_name, view_definition 
FROM information_schema.views 
WHERE table_schema = 'public';

-- Tablonuzun yapısını görelim
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'savings_goals' 
AND table_schema = 'public';

DROP VIEW public.goals_summary_view;

CREATE VIEW public.goals_summary_view AS 
SELECT 
  COALESCE(sum(sg.target_amount), (0)::numeric) AS total_target,
  COALESCE(sum(sg.current_amount), (0)::numeric) AS total_current
FROM savings_goals sg
WHERE sg.user_id = auth.uid();

SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'savings_goals';

ALTER TABLE public.savings_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_own_savings_goals" ON public.savings_goals
FOR ALL USING (auth.uid() = user_id);

