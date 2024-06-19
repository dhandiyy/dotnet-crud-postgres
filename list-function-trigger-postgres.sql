--Using postgresql

-- 1.
CREATE TABLE gudang (
  gudang_id SERIAL PRIMARY KEY,
  nama_gudang VARCHAR(50) NOT NULL,
  alamat TEXT NOT NULL,
  kapasitas_gudang INT NOT NULL
);


CREATE TABLE barang (
	barang_id SERIAL PRIMARY KEY,
	nama_barang VARCHAR(50) NOT NULL,
	harga_barang DECIMAL(10,2) NOT NULL,
	stok_barang INT NOT NULL,
	tanggal_kadaluarsa DATE NOT NULL,
	gudang_id INTEGER NOT NULL,
	FOREIGN KEY (gudang_id) REFERENCES gudang(gudang_id)
);

INSERT INTO gudang (nama_gudang, alamat, kapasitas_gudang) VALUES
('Gudang Pusat', 'Jl. Merdeka No.1, Jakarta', 1000),
('Gudang Cabang A', 'Jl. Sudirman No.20, Bandung', 800),
('Gudang Cabang B', 'Jl. Ahmad Yani No.15, Surabaya', 600),
('Gudang Cabang C', 'Jl. Diponegoro No.35, Yogyakarta', 500),
('Gudang Cabang D', 'Jl. Gatot Subroto No.10, Medan', 700);

INSERT INTO barang (nama_barang, harga_barang, stok_barang, tanggal_kadaluarsa, gudang_id) VALUES
('Beras', 12000.50, 100, '2025-12-31', 1),
('Gula', 15000.75, 200, '2024-10-15', 1),
('Minyak Goreng', 25000.99, 150, '2023-08-10', 2),
('Tepung Terigu', 9000.20, 180, '2024-05-01', 2),
('Susu', 18000.30, 120, '2023-12-31', 3),
('Kopi', 22000.40, 130, '2024-03-20', 3),
('Mie Instan', 3000.15, 500, '2025-01-01', 4),
('Kecap', 8000.45, 300, '2024-07-10', 4),
('Roti', 5000.25, 50, '2023-06-25', 5),
('Air Mineral', 4000.10, 400, '2024-09-30', 5);

CREATE INDEX idx_gudang_nama ON gudang (nama_gudang);
CREATE INDEX idx_barang_nama ON barang (nama_barang);
-------------------------------

-- 2.
CREATE PROCEDURE procedure_get_data(
	p_page INT,
	p_page_size INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    sql_query TEXT;
	offset_val INT;
BEGIN
	offset_val := (p_page-1)*p_page_size;
	sql_query := format('
		SELECT g.gudang_id, g.nama_gudang, b.barang_id, b.nama_barang, b.harga_barang, b.tanggal_kadaluarsa
		FROM gudang g
		JOIN barang b on g.gudang_id=b.gudang_id
		LIMIT %L OFFSET %L', p_page_size, offset_val);
EXECUTE sql_query;
END;
$$;

CALL procedure_get_data(1, 10);
-------------------------------


-- 3.
CREATE TABLE expired_log (
    log_id SERIAL PRIMARY KEY,
    gudang_id INT NOT NULL,
    barang_id INT NOT NULL,
    nama_barang VARCHAR(50),
    tanggal_kadaluarsa DATE,
    log_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION check_expired_items()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO expired_log (gudang_id, barang_id, nama_barang, tanggal_kadaluarsa)
    SELECT g.gudang_id, b.barang_id, b.nama_barang, b.tanggal_kadaluarsa
    FROM barang b
    JOIN gudang g ON b.gudang_id = g.gudang_id
    WHERE b.gudang_id = NEW.gudang_id
      AND b.tanggal_kadaluarsa < CURRENT_DATE;
      
    RAISE NOTICE 'Expired items checked and logged for Gudang ID: %', NEW.gudang_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_expired_items
AFTER INSERT ON barang
FOR EACH ROW
EXECUTE FUNCTION check_expired_items();

INSERT INTO barang (nama_barang, harga_barang, stok_barang, tanggal_kadaluarsa, gudang_id)
VALUES ('New Item3', 10000.00, 50, '2025-12-31', 1);
-------------------------------

CREATE OR REPLACE FUNCTION create_gudang(
    p_nama_gudang VARCHAR(50),
    p_alamat TEXT,
    p_kapasitas_gudang INT
)
RETURNS INTEGER AS $$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO gudang (nama_gudang, alamat, kapasitas_gudang)
    VALUES (p_nama_gudang, p_alamat, p_kapasitas_gudang)
    RETURNING gudang_id INTO new_id;
    
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_gudang(p_nama_gudang VARCHAR(50), p_alamat TEXT, p_kapasitas_gudang INT)
IS 'Creates new record in the gudang table';

-----------------------------
CREATE OR REPLACE FUNCTION update_gudang(
    p_gudang_id INTEGER,
    p_nama_gudang VARCHAR(50),
    p_alamat TEXT,
    p_kapasitas_gudang INT
)
RETURNS VOID AS $$
BEGIN
    UPDATE gudang
    SET
        nama_gudang = p_nama_gudang,
        alamat = p_alamat,
        kapasitas_gudang = p_kapasitas_gudang
    WHERE gudang_id = p_gudang_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_gudang(p_gudang_id INTEGER, p_nama_gudang VARCHAR(50), p_alamat TEXT, p_kapasitas_gudang INT)
IS 'Updates gudang table based on gudang_id';

----------------------------------
CREATE OR REPLACE FUNCTION read_gudang()
RETURNS TABLE (
    gudang_id INTEGER,
    nama_gudang VARCHAR(50),
    alamat TEXT,
    kapasitas_gudang INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT gudang.gudang_id, gudang.nama_gudang, gudang.alamat, gudang.kapasitas_gudang
    FROM gudang;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION read_gudang()
IS 'Returns all records from the gudang table';
-----------------------------------

CREATE OR REPLACE FUNCTION delete_gudang(
    p_gudang_id INTEGER
)
RETURNS VOID AS $$
BEGIN
	DELETE FROM gudang
    WHERE gudang_id = p_gudang_id;

    UPDATE barang
    SET gudang_id = DEFAULT
    WHERE gudang_id = p_gudang_id;
    
END;
$$ LANGUAGE plpgsql;
-----------------------------------







