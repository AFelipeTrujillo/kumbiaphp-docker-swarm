-- Initialization script for KumbiaPHP database
-- This script runs automatically when creating the MySQL container

-- Create additional database if needed
-- The main database is already created with environment variables

-- Example table for users
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- TODO: check how to create preload data with migrations
-- Insert example user
-- INSERT INTO users (username, email, password) VALUES 
--('admin', 'admin@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi')
--ON DUPLICATE KEY UPDATE username = username;

-- Additional MySQL configurations
SET GLOBAL sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO';

-- Informative comment
SELECT 'Database initialized correctly for KumbiaPHP' as Status; 