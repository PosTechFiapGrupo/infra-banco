-- Create migration_user for database migrations
-- This user has DDL permissions to run Alembic migrations

-- Create user (will be executed by master user)
CREATE USER 'migration_user'@'%' IDENTIFIED BY 'CHANGE_ME_IN_SECRETS_MANAGER';

-- Grant all privileges on database (including DDL)
GRANT ALL PRIVILEGES ON tech_challenge.* TO 'migration_user'@'%';

-- Flush privileges to apply changes
FLUSH PRIVILEGES;

-- Note: migration_user can CREATE, ALTER, DROP tables, indexes, etc.
-- This is necessary for Alembic migrations to work
