-- =====================================================
-- DATABASE SCHEMA EXAMPLE
-- =====================================================

-- 1. Table: mountain
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

-- 2. Table: route
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

-- 3. Foreign Key Constraint (Memungkinkan 1x hit API relasi mountain -> route)
ALTER TABLE public.route ADD CONSTRAINT fk_route_mountain FOREIGN KEY (mountain) REFERENCES public.mountain(id) ON DELETE CASCADE;

-- 4. Row Level Security (RLS)
ALTER TABLE public.mountain ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read on mountain" ON public.mountain FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow public read on route" ON public.route FOR SELECT TO anon, authenticated USING (true);
