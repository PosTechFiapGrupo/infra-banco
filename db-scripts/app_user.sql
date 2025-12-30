-- Create app_user for application database access
-- This user has read/write permissions but no DDL permissions

-- Create user (will be executed by master user)
CREATE USER 'app_user'@'%' IDENTIFIED BY 'CHANGE_ME_IN_SECRETS_MANAGER';

-- Grant privileges on database
GRANT SELECT, INSERT, UPDATE, DELETE ON tech_challenge.* TO 'app_user'@'%';

-- Grant EXECUTE for stored procedures (if needed)
GRANT EXECUTE ON tech_challenge.* TO 'app_user'@'%';

-- Flush privileges to apply changes
FLUSH PRIVILEGES;

-- Note: No CREATE, ALTER, DROP permissions - app_user cannot modify schema
