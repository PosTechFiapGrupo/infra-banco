-- Create admin_user for emergency database operations
-- This user has full access but should be restricted by security group/IP whitelist

-- Create user (will be executed by master user)
CREATE USER 'admin_user'@'%' IDENTIFIED BY 'CHANGE_ME_IN_SECRETS_MANAGER';

-- Grant all privileges on database
GRANT ALL PRIVILEGES ON tech_challenge.* TO 'admin_user'@'%';

-- Grant privileges to grant privileges (superuser-like)
GRANT GRANT OPTION ON tech_challenge.* TO 'admin_user'@'%';

-- Flush privileges to apply changes
FLUSH PRIVILEGES;

-- WARNING: This user has full database access
-- Access should be restricted via:
-- 1. Security group rules (only allow specific IPs)
-- 2. VPN or bastion host
-- 3. IAM policies
-- 4. Audit logging
