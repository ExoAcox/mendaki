-- =====================================================
-- DATABASE SCHEMA & SEED DATA (MENDAKI APP)
-- =====================================================
-- File ini berisi DDL tabel, Row Level Security (RLS),
-- dan data awal dummy agar kontributor dapat langsung
-- menguji aplikasi Mendaki.

-- -----------------------------------------------------
-- 1. Table: mountain
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.mountain (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    routes TEXT[] NOT NULL,
    elevation SMALLINT NOT NULL,
    location JSONB NOT NULL,
    city TEXT[] NOT NULL,
    province TEXT[] NOT NULL,
    estimated_time JSONB NOT NULL,
    difficulty TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open',
    asset_url TEXT NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- -----------------------------------------------------
-- 2. Table: route
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.route (
    id TEXT PRIMARY KEY,
    mountain TEXT NOT NULL REFERENCES public.mountain(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    distance SMALLINT NOT NULL,
    elevation SMALLINT NOT NULL,
    has_water BOOLEAN NOT NULL DEFAULT false,
    "estimatedTime" JSONB,
    city TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- -----------------------------------------------------
-- 3. Row Level Security (RLS)
-- -----------------------------------------------------
ALTER TABLE public.mountain ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read on mountain" ON public.mountain;
CREATE POLICY "Allow public read on mountain" ON public.mountain FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Allow public read on route" ON public.route;
CREATE POLICY "Allow public read on route" ON public.route FOR SELECT TO anon, authenticated USING (true);

-- =====================================================
-- 4. DUMMY SEED DATA FOR CONTRIBUTORS
-- =====================================================

-- 4.1 Seed: Table mountain
INSERT INTO public.mountain (
    id,
    name,
    routes,
    elevation,
    location,
    city,
    province,
    estimated_time,
    difficulty,
    status,
    asset_url,
    image_url
) VALUES
(
    'prau',
    'Gunung Prau',
    ARRAY['prau-patakbanteng', 'prau-dieng', 'prau-kalilembu'],
    2590,
    '{"latitude": -7.1856, "longitude": 109.9234}'::jsonb,
    ARRAY['Wonosobo', 'Batang', 'Kendal'],
    ARRAY['Jawa Tengah'],
    '{"min": 3, "max": 4}'::jsonb,
    'easy',
    'open',
    'https://your-supabase-storage/prau.gpx',
    'https://your-supabase-storage/prau.jpg',
),
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    routes = EXCLUDED.routes,
    elevation = EXCLUDED.elevation,
    location = EXCLUDED.location,
    city = EXCLUDED.city,
    province = EXCLUDED.province,
    estimated_time = EXCLUDED.estimated_time,
    difficulty = EXCLUDED.difficulty,
    status = EXCLUDED.status,
    asset_url = EXCLUDED.asset_url,
    image_url = EXCLUDED.image_url,
    updated_at = now();

-- 4.2 Seed: Table route
INSERT INTO public.route (
    id,
    mountain,
    name,
    distance,
    elevation,
    has_water,
    "estimatedTime",
    city
) VALUES
(
    'prau-patakbanteng',
    'prau',
    'Patakbanteng',
    4,
    2000,
    false,
    '{"min": 2, "max": 3}'::jsonb,
    'Wonosobo',
),
ON CONFLICT (id) DO UPDATE SET
    mountain = EXCLUDED.mountain,
    name = EXCLUDED.name,
    distance = EXCLUDED.distance,
    elevation = EXCLUDED.elevation,
    has_water = EXCLUDED.has_water,
    "estimatedTime" = EXCLUDED."estimatedTime",
    city = EXCLUDED.city,
    updated_at = now();
