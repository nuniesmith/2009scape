-- Insert admin user if it doesn't exist
INSERT INTO `members` (`username`, `password`, `credits`, `rights`)
SELECT 'admin', 'e3274be5c857fb42ab72d786e281b4b8', 1000, 2
FROM dual
WHERE NOT EXISTS (
    SELECT 1 FROM `members` WHERE `username` = 'admin'
) LIMIT 1;

-- Insert a test user if it doesn't exist
INSERT INTO `members` (`username`, `password`, `credits`, `rights`)
SELECT 'test', '098f6bcd4621d373cade4e832627b4f6', 500, 0
FROM dual
WHERE NOT EXISTS (
    SELECT 1 FROM `members` WHERE `username` = 'test'
) LIMIT 1;