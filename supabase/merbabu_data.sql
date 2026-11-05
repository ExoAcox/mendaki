-- =====================================================
-- MERBABU DATA INSERTION FOR SUPABASE
-- Jalankan script ini di SQL Editor pada Supabase Dashboard
-- Project: YOUR_PROJECT_ID
-- =====================================================

INSERT INTO public.mountains (
    id, name, elevation_mdpl, location, province, difficulty, estimated_time, status, gpx_file_url, is_offline_ready
) VALUES (
    'merbabu',
    'Gunung Merbabu',
    3145,
    'Boyolali, Magelang & Semarang',
    'Jawa Tengah',
    'Sedang',
    '6 - 8 Jam',
    'Buka (Aman)',
    'https://YOUR_PROJECT_ID.supabase.co/storage/v1/object/public/gpx/merbabu.gpx',
    TRUE
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    elevation_mdpl = EXCLUDED.elevation_mdpl,
    location = EXCLUDED.location,
    province = EXCLUDED.province,
    gpx_file_url = EXCLUDED.gpx_file_url,
    is_offline_ready = EXCLUDED.is_offline_ready;

INSERT INTO public.routes (id, mountain_id, name, basecamp_name, distance_km, estimated_duration, elevation_gain_meters, difficulty) VALUES
    ('merbabu-selo', 'merbabu', 'Via Selo', 'Basecamp Selo', 6.2, '6 - 7 Jam', 1289, 'Sedang'),
    ('merbabu-suwanting', 'merbabu', 'Via Suwanting', 'Basecamp Swanting', 7.1, '8 - 9 Jam', 1849, 'Sangat Curam'),
    ('merbabu-wekas', 'merbabu', 'Via Wekas', 'Basecamp Wekas', 5.8, '6 - 7 Jam', 1335, 'Sedang'),
    ('merbabu-thekelan', 'merbabu', 'Via Thekelan', 'Basecamp Thekelan', 6.5, '7 - 8 Jam', 1450, 'Menantang'),
    ('merbabu-cuntel', 'merbabu', 'Via Cuntel', 'Basecamp Cuntel', 6.0, '6 - 7 Jam', 1380, 'Sedang')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    basecamp_name = EXCLUDED.basecamp_name,
    distance_km = EXCLUDED.distance_km,
    estimated_duration = EXCLUDED.estimated_duration,
    elevation_gain_meters = EXCLUDED.elevation_gain_meters,
    difficulty = EXCLUDED.difficulty;

INSERT INTO public.waypoints (route_id, name, latitude, longitude, elevation, type, has_water, tent_capacity, signal_info) VALUES
    ('merbabu-selo', 'AIR', -7.4441224, 110.4332852, NULL, 'water', TRUE, NULL, NULL),
    ('merbabu-selo', 'AIR', -7.4596150, 110.4291667, NULL, 'water', TRUE, NULL, NULL),
    ('merbabu-selo', 'BASECAMP SELO', -7.4845300, 110.4599550, 1856, 'basecamp', TRUE, NULL, 'Telkomsel 4G, Indosat, XL'),
    ('merbabu-suwanting', 'BASECAMP SWANTING', -7.4743810, 110.3982000, NULL, 'basecamp', TRUE, NULL, 'Telkomsel 4G, Indosat, XL'),
    ('merbabu-thekelan', 'BASECAMP THEKELAN', -7.4108000, 110.4263430, NULL, 'basecamp', TRUE, NULL, 'Telkomsel 4G, Indosat, XL'),
    ('merbabu-wekas', 'BASECAMP WEKAS', -7.4321030, 110.4142260, NULL, 'basecamp', TRUE, NULL, 'Telkomsel 4G, Indosat, XL'),
    ('merbabu-suwanting', 'BASECAMP  GRENDEN', -7.4624904, 110.3949930, 1296.4, 'basecamp', TRUE, NULL, 'Telkomsel 4G, Indosat, XL'),
    ('merbabu-selo', 'CABANG', -7.4726860, 110.4545920, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-suwanting', 'CAMP CANTIGI TUNGGAL', -7.4512455, 110.4324564, NULL, 'camp', FALSE, 20, NULL),
    ('merbabu-selo', 'CAMP', -7.4483014, 110.4288746, 2805, 'camp', FALSE, 20, NULL),
    ('merbabu-selo', 'CAMP', -7.4542515, 110.4375694, 3123.6, 'camp', FALSE, 20, NULL),
    ('merbabu-cuntel', 'BASECAMP CUNTEL', -7.4171718, 110.4186981, NULL, 'basecamp', TRUE, NULL, 'Telkomsel 4G, Indosat, XL'),
    ('merbabu-thekelan', 'HELIPAD', -7.4475359, 110.4397020, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-suwanting', 'JEMBATAN HATI', -7.4598349, 110.4037106, 1667.6, 'pos', FALSE, NULL, NULL),
    ('merbabu-thekelan', 'JEMBATAN SETAN', -7.4480658, 110.4409606, NULL, 'hazard', FALSE, NULL, NULL),
    ('merbabu-selo', 'KENDI KENCANA', -7.4495232, 110.4305132, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-selo', 'KENTENG SONGO', -7.4536744, 110.4405631, NULL, 'summit', FALSE, NULL, 'Edge Telkomsel'),
    ('merbabu-suwanting', 'LEMBAH CEMORO', -7.4691558, 110.4139933, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-suwanting', 'LEMBAH GOSONG', -7.4696857, 110.4098861, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-suwanting', 'LEMBAH MANDING', -7.4636429, 110.4222975, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-suwanting', 'LEMBAH NGRIJAN', -7.4679861, 110.4165668, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-suwanting', 'LEMBAHN MITO', -7.4666150, 110.4190833, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-selo', 'PARKIR', -7.4586059, 110.4023738, 1436, 'basecamp', FALSE, NULL, NULL),
    ('merbabu-selo', 'PEMANCAR', -7.4423689, 110.4370053, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-selo', 'PINTU RIMBA', -7.4619574, 110.3914393, NULL, 'basecamp', FALSE, NULL, NULL),
    ('merbabu-selo', 'PINTU RIMBA', -7.4705630, 110.4047333, NULL, 'basecamp', FALSE, NULL, NULL),
    ('merbabu-selo', 'POS 1 DOK MALANG', -7.4733040, 110.4557410, 2200, 'pos', FALSE, NULL, 'Telkomsel 2 Bar'),
    ('merbabu-suwanting', 'POS 1 LEMBAH LEMPONG', -7.4702380, 110.4063833, NULL, 'pos', FALSE, NULL, 'Telkomsel 2 Bar'),
    ('merbabu-thekelan', 'POS 1 PENDING', -7.4213231, 110.4298066, NULL, 'pos', FALSE, NULL, 'Telkomsel 2 Bar'),
    ('merbabu-suwanting', 'POS 1 SANGAR', -7.4571658, 110.4084287, NULL, 'pos', FALSE, NULL, 'Telkomsel 2 Bar'),
    ('merbabu-wekas', 'POS 1 TEGAL ARUM', -7.4337621, 110.4212585, NULL, 'pos', FALSE, NULL, 'Telkomsel 2 Bar'),
    ('merbabu-cuntel', 'POS 1 WATU PUTUT', -7.4304218, 110.4275542, NULL, 'pos', FALSE, NULL, 'Telkomsel 2 Bar'),
    ('merbabu-selo', 'POS 1.5', -7.4703482, 110.4540992, NULL, 'pos', FALSE, NULL, 'Telkomsel 2 Bar'),
    ('merbabu-thekelan', 'POS 2 KEDOKAN', -7.4343777, 110.4290337, NULL, 'pos', FALSE, NULL, 'Telkomsel 1 Bar'),
    ('merbabu-suwanting', 'POS 2 LAWU', -7.4535197, 110.4119839, NULL, 'pos', FALSE, NULL, 'Telkomsel 1 Bar'),
    ('merbabu-selo', 'POS 2 PANDEAN GUNUNG', -7.4685189, 110.4510226, NULL, 'pos', FALSE, NULL, 'Telkomsel 1 Bar'),
    ('merbabu-cuntel', 'POS 2 PARENG PUTIH', -7.4276851, 110.4324564, NULL, 'pos', FALSE, NULL, 'Telkomsel 1 Bar'),
    ('merbabu-selo', 'POS 2', -7.4420571, 110.4298737, NULL, 'pos', FALSE, NULL, 'Telkomsel 1 Bar'),
    ('merbabu-selo', 'POS 3 (AIR)', -7.4514397, 110.4218111, 2312.2, 'water', TRUE, NULL, 'Telkomsel 1 Bar'),
    ('merbabu-thekelan', 'POS 3 GUMUK MENTUL', -7.4303569, 110.4360336, NULL, 'pos', FALSE, NULL, 'Telkomsel 1 Bar'),
    ('merbabu-cuntel', 'POS 3 KERGO PASAR', -7.4381059, 110.4317278, NULL, 'pos', FALSE, NULL, 'Telkomsel 1 Bar'),
    ('merbabu-selo', 'POS 3 WAKPEY', -7.4686002, 110.4462938, NULL, 'pos', FALSE, NULL, 'Telkomsel 1 Bar'),
    ('merbabu-selo', 'POS 3', -7.4462331, 110.4374497, NULL, 'pos', FALSE, NULL, 'Telkomsel 1 Bar'),
    ('merbabu-selo', 'POS 3', -7.4595320, 110.4302333, NULL, 'pos', FALSE, NULL, 'Telkomsel 1 Bar'),
    ('merbabu-selo', 'POS 4', -7.4501414, 110.4268035, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-suwanting', 'POS 4 LEMPONG SAMPAN', -7.4331832, 110.4366520, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-selo', 'POS 4 SABANA 1', -7.4654270, 110.4453370, 2790, 'camp', FALSE, 50, NULL),
    ('merbabu-selo', 'POS 5 SABANA 2', -7.4605663, 110.4437650, NULL, 'camp', FALSE, 50, NULL),
    ('merbabu-selo', 'POS BAYANGAN GUMUK', -7.4277720, 110.4261852, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-selo', 'POS BAYANGAN', -7.4361421, 110.4241979, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-selo', 'POS BAYANGAN', -7.4210139, 110.4222533, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-selo', 'POS BAYANGAN', -7.4328299, 110.4204661, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-selo', 'POS BAYANGAN', -7.4267950, 110.4251918, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-selo', 'PUNCAK SYARIEF', -7.4497219, 110.4427713, NULL, 'summit', FALSE, NULL, 'Edge Telkomsel'),
    ('merbabu-selo', 'PUNCAK TRIANGULASI', -7.4542291, 110.4397240, NULL, 'summit', FALSE, NULL, 'Edge Telkomsel'),
    ('merbabu-selo', 'SABANA 1', -7.4586238, 110.4324627, NULL, 'camp', FALSE, 50, NULL),
    ('merbabu-selo', 'SABANA 2', -7.4552669, 110.4338034, NULL, 'camp', FALSE, 50, NULL),
    ('merbabu-selo', 'SABANA 3', -7.4544720, 110.4356583, NULL, 'camp', FALSE, 50, NULL),
    ('merbabu-selo', 'TIKET PENDAKIAN', -7.4620409, 110.3964547, 1317.8, 'basecamp', FALSE, NULL, NULL),
    ('merbabu-thekelan', 'WATU GUBUK', -7.4389552, 110.4384219, NULL, 'pos', FALSE, NULL, NULL),
    ('merbabu-cuntel', 'WATU KUMPUL', -7.4458798, 110.4358129, NULL, 'pos', FALSE, NULL, NULL)
;