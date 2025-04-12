#!/bin/bash
set -e

echo "Starting 2009scape database initialization..."

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
until mysqladmin ping -h localhost -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent; do
    echo "MySQL not ready yet... waiting 5 seconds"
    sleep 5
done

# Initialize database if it doesn't exist
echo "Checking if database needs initialization..."
DB_EXISTS=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW DATABASES LIKE 'global';" | grep -c "global" || echo "0")

if [ "$DB_EXISTS" = "0" ]; then
    echo "Creating database from SQL files..."
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" < /home/jordan/2009scape/server/db_exports/global.sql
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" < /home/jordan/2009scape/server/db_exports/testuser.sql
    echo "Database initialized!"
fi

# Create admin user if it doesn't exist (in the members table based on your SQL)
echo "Checking for admin user..."
ADMIN_EXISTS=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -N -B -e "SELECT COUNT(*) FROM global.members WHERE username='admin';" 2>/dev/null || echo "0")

if [ "$ADMIN_EXISTS" = "0" ]; then
    echo "Creating admin user..."
    # Password is 'admin123' - in production you should use a secure password
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" global -e "INSERT INTO members (username, password, credits, rights) VALUES ('admin', 'e3274be5c857fb42ab72d786e281b4b8', 1000, 2);"
    echo "Admin user created!"
else
    echo "Admin user already exists."
fi

echo "Database initialization completed!"