-- 2009scape global database structure

-- Create members table if it doesn't exist
CREATE TABLE IF NOT EXISTS `members` (
  `UID` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` varchar(15) DEFAULT NULL,
  `password` varchar(100) DEFAULT NULL,
  `credits` int(5) NOT NULL DEFAULT 0,
  `rights` int(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`UID`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create players table if it doesn't exist
CREATE TABLE IF NOT EXISTS `players` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `credits` int(11) DEFAULT 0,
  `client_rights` int(11) DEFAULT 0,
  `donator_credits` int(11) DEFAULT 0,
  `friends` text DEFAULT NULL,
  `ignores` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create game logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS `game_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` int(11) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  `action` varchar(255) NOT NULL,
  `details` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `player_id` (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;