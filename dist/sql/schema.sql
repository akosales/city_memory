-- ================================================
-- City Memory System - PostgreSQL Schema
-- ================================================

CREATE TABLE IF NOT EXISTS zone_memory (
    zone_id VARCHAR(50) PRIMARY KEY,
    heat DECIMAL(4,3) DEFAULT 0.000,
    last_incident TIMESTAMP,
    total_incidents INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS zone_events (
    id SERIAL PRIMARY KEY,
    zone_id VARCHAR(50) REFERENCES zone_memory(zone_id) ON DELETE CASCADE,
    event_type VARCHAR(30) NOT NULL,
    severity DECIMAL(3,2) DEFAULT 0.10,
    source_identifier VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS player_profiles (
    identifier VARCHAR(60) PRIMARY KEY,
    reputation DECIMAL(4,3) DEFAULT 0.500,
    volatility DECIMAL(3,2) DEFAULT 0.00,
    cooperation DECIMAL(3,2) DEFAULT 0.50,
    violence_tendency DECIMAL(3,2) DEFAULT 0.00,
    flee_tendency DECIMAL(3,2) DEFAULT 0.00,
    last_negative_event TIMESTAMP,
    last_positive_event TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS player_events (
    id SERIAL PRIMARY KEY,
    identifier VARCHAR(60) REFERENCES player_profiles(identifier) ON DELETE CASCADE,
    event_type VARCHAR(30) NOT NULL,
    impact DECIMAL(3,2) NOT NULL,
    context JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicle_history (
    plate VARCHAR(10) PRIMARY KEY,
    heat DECIMAL(4,3) DEFAULT 0.000,
    chase_count INTEGER DEFAULT 0,
    crime_association DECIMAL(3,2) DEFAULT 0.00,
    last_incident TIMESTAMP,
    first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicle_events (
    id SERIAL PRIMARY KEY,
    plate VARCHAR(10) REFERENCES vehicle_history(plate) ON DELETE CASCADE,
    event_type VARCHAR(30) NOT NULL,
    driver_identifier VARCHAR(60),
    zone_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS city_memory_logs (
    id SERIAL PRIMARY KEY,
    category VARCHAR(30),
    message TEXT,
    data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dispatch History
CREATE TABLE IF NOT EXISTS dispatch_history (
    id SERIAL PRIMARY KEY,
    call_id INTEGER NOT NULL,
    category VARCHAR(30),
    priority VARCHAR(10),
    message TEXT,
    caller_name VARCHAR(100),
    location_zone VARCHAR(100),
    location_street VARCHAR(200),
    coords_x DECIMAL(10,2),
    coords_y DECIMAL(10,2),
    coords_z DECIMAL(10,2),
    created_at TIMESTAMP,
    closed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    units_count INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_dispatch_history_created ON dispatch_history(created_at);
CREATE INDEX IF NOT EXISTS idx_dispatch_history_category ON dispatch_history(category);

-- MDT Notes
CREATE TABLE IF NOT EXISTS mdt_notes (
    id SERIAL PRIMARY KEY,
    identifier VARCHAR(60) NOT NULL,
    note TEXT NOT NULL,
    created_by VARCHAR(60),
    created_by_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_mdt_notes_identifier ON mdt_notes(identifier);

-- MDT Wanted
CREATE TABLE IF NOT EXISTS mdt_wanted (
    id SERIAL PRIMARY KEY,
    type VARCHAR(20) NOT NULL,
    target VARCHAR(100) NOT NULL,
    reason TEXT,
    created_by VARCHAR(60),
    created_by_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    active BOOLEAN DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_mdt_wanted_active ON mdt_wanted(active);

CREATE INDEX IF NOT EXISTS idx_zone_events_zone_id ON zone_events(zone_id);
CREATE INDEX IF NOT EXISTS idx_zone_events_created_at ON zone_events(created_at);
CREATE INDEX IF NOT EXISTS idx_player_events_identifier ON player_events(identifier);
CREATE INDEX IF NOT EXISTS idx_player_events_created_at ON player_events(created_at);
CREATE INDEX IF NOT EXISTS idx_vehicle_events_plate ON vehicle_events(plate);

INSERT INTO zone_memory (zone_id) VALUES 
    -- South LS
    ('grove_street'),
    ('davis'),
    ('strawberry'),
    ('rancho'),
    ('la_mesa'),
    ('el_burro'),
    ('cypress_flats'),
    -- Downtown
    ('pillbox_hill'),
    ('legion_square'),
    ('downtown'),
    ('mission_row'),
    ('textile_city'),
    ('alta'),
    ('burton'),
    -- Vinewood
    ('vinewood_boulevard'),
    ('vinewood_hills'),
    ('mirror_park'),
    ('east_vinewood'),
    ('west_vinewood'),
    ('rockford_hills'),
    -- Westside
    ('del_perro'),
    ('del_perro_pier'),
    ('vespucci'),
    ('vespucci_canals'),
    ('little_seoul'),
    ('morningwood'),
    ('richman'),
    -- Hafen
    ('port'),
    ('elysian_island'),
    ('terminal'),
    -- Flughafen
    ('airport'),
    ('airport_parking'),
    -- Blaine County
    ('sandy_shores'),
    ('harmony'),
    ('grand_senora'),
    ('grapeseed'),
    ('paleto_bay'),
    ('chumash'),
    ('zancudo'),
    -- Spezielle Orte
    ('casino'),
    ('maze_bank'),
    ('maze_bank_arena'),
    ('hospital_pillbox'),
    ('hospital_sandy'),
    ('hospital_paleto'),
    ('pd_mission_row'),
    ('pd_vespucci'),
    ('pd_sandy'),
    ('pd_paleto')
ON CONFLICT (zone_id) DO NOTHING;
