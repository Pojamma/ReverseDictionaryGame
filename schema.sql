CREATE TABLE IF NOT EXISTS packs (
  pack_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE IF NOT EXISTS puzzles (
  id TEXT PRIMARY KEY,
  pack_id TEXT NOT NULL REFERENCES packs(pack_id),
  type TEXT CHECK(type IN ('definition','emoji','riddle')) NOT NULL,
  clue TEXT NOT NULL,
  answer TEXT NOT NULL,
  alt_answers TEXT DEFAULT '[]',        -- JSON array as text
  category TEXT,
  difficulty INTEGER CHECK(difficulty BETWEEN 1 AND 3) DEFAULT 1,
  length INTEGER,
  hints TEXT DEFAULT '[]',              -- JSON array as text
  tags TEXT DEFAULT '[]',               -- JSON array as text
  points INTEGER DEFAULT 10,
  is_active INTEGER DEFAULT 1
);

-- Example inserts
INSERT INTO packs (pack_id,name,description) VALUES
('base','Base Pack','Core puzzles for all modes')
ON CONFLICT(pack_id) DO NOTHING;
