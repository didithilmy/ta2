CREATE TABLE IF NOT EXISTS test_entry (
    id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    entry TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS matakuliah (
    kode_mk VARCHAR(20) NOT NULL PRIMARY KEY,
    nama TEXT NOT NULL
);

INSERT IGNORE INTO matakuliah VALUES ('IF2212', 'Pemrograman Berorientasi Objek STI');
INSERT IGNORE INTO matakuliah VALUES ('II2230', 'Jaringan Komputer');
INSERT IGNORE INTO matakuliah VALUES ('II2240', 'Analisis Kebutuhan Sistem');
INSERT IGNORE INTO matakuliah VALUES ('II2250', 'Manajemen Basis Data');
INSERT IGNORE INTO matakuliah VALUES ('II3121', 'Analisis Kebutuhan Enterprise');
INSERT IGNORE INTO matakuliah VALUES ('II3220', 'Arsitektur Enterprise');

CREATE TABLE IF NOT EXISTS pengambilan_mk (
    id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    kode_mk VARCHAR(20) NOT NULL,
    user TEXT NOT NULL
)