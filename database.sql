-- AI Interviewer Database Schema
-- This database supports three types of users: admin, company, and clients (individual and company users)
-- Company users are linked to companies via company_id in the users table

-- Create database
CREATE DATABASE IF NOT EXISTS ai_interviewer;
USE ai_interviewer;

-- Users table (supports all user types: admin, company, client, company_user)
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(200) GENERATED ALWAYS AS (CONCAT(first_name, ' ', last_name)) STORED,
    phone VARCHAR(20),
    country VARCHAR(100),
    region VARCHAR(100), -- State/Province
    address TEXT,
    profile_img VARCHAR(500),
    role ENUM('admin', 'company', 'client', 'company_user') NOT NULL DEFAULT 'client',
    is_active BOOLEAN DEFAULT TRUE,
    cnic VARCHAR(20), -- National ID for company users
    designation VARCHAR(100), -- Job title for company users
    company_id INT, -- Links company_user to companies table
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_company_id (company_id),
    INDEX idx_is_active (is_active)
);

-- Companies table (for company accounts)
CREATE TABLE companies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    platform_id VARCHAR(6) UNIQUE, -- 6 character alphanumeric ID
    company_name VARCHAR(255) NOT NULL,
    first_name VARCHAR(100), -- Admin contact first name
    last_name VARCHAR(100), -- Admin contact last name
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    country VARCHAR(100),
    region VARCHAR(100),
    address TEXT,
    profile_img VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_company_name (company_name)
);

-- Add foreign key constraint for company_id in users table
ALTER TABLE users ADD CONSTRAINT fk_users_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL;

-- Company Users mapping table (for the 8-character specific employee ID)
CREATE TABLE company_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    company_id INT NOT NULL,
    employee_id VARCHAR(8) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_company_id (company_id),
    INDEX idx_employee_id (employee_id)
);

-- Interviews table
CREATE TABLE interviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    target_role VARCHAR(255),
    interview_type ENUM('self', 'company') DEFAULT 'self',
    overall_score DECIMAL(5,2), -- e.g., 85.50
    duration INT, -- in minutes
    voice_language VARCHAR(50),
    status ENUM('pending', 'in_progress', 'completed', 'cancelled') DEFAULT 'pending',
    company_id INT, -- For company-assigned interviews
    employee_id VARCHAR(8), -- From company_users mapping
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL,
    FOREIGN KEY (employee_id) REFERENCES company_users(employee_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_company_id (company_id),
    INDEX idx_employee_id (employee_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- Subscription Plans table (predefined plans)
CREATE TABLE subscription_plans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    target_audience ENUM('individual', 'company') NOT NULL,
    company_id INT, -- For company-specific plans
    monthly_price DECIMAL(10,2) NOT NULL,
    yearly_price DECIMAL(10,2) NOT NULL,
    monthly_discount INT DEFAULT 0, -- Percentage
    yearly_discount INT DEFAULT 0, -- Percentage
    monthly_promo VARCHAR(50), -- Promotion tag
    yearly_promo VARCHAR(50), -- Promotion tag
    features TEXT, -- Comma-separated features
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_target_audience (target_audience),
    INDEX idx_company_id (company_id),
    INDEX idx_is_active (is_active)
);

-- Subscriptions table (user purchases)
CREATE TABLE subscriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    plan_id INT NOT NULL,
    status ENUM('active', 'inactive', 'cancelled', 'expired') DEFAULT 'active',
    billing_cycle ENUM('monthly', 'yearly') NOT NULL,
    price DECIMAL(10,2) NOT NULL, -- Final price after discount
    currency VARCHAR(3) DEFAULT 'USD',
    discount_applied INT DEFAULT 0, -- Percentage discount applied
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    payment_method VARCHAR(50), -- stripe, paypal, etc.
    transaction_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES subscription_plans(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_plan_id (plan_id),
    INDEX idx_status (status),
    INDEX idx_start_date (start_date),
    INDEX idx_end_date (end_date)
);

-- Notifications table
CREATE TABLE notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    type ENUM('admin', 'company', 'system') DEFAULT 'system',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_type (type),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
);

-- Support tickets table
CREATE TABLE support_tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    ticket_number VARCHAR(20) UNIQUE NOT NULL,
    subject VARCHAR(255) NOT NULL,
    message TEXT,
    status ENUM('open', 'in_progress', 'resolved', 'closed') DEFAULT 'open',
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_ticket_number (ticket_number),
    INDEX idx_created_at (created_at)
);

-- Support ticket replies table
CREATE TABLE support_replies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id INT NOT NULL,
    user_id INT, -- NULL for admin/system replies
    reply_text TEXT NOT NULL,
    is_admin_reply BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES support_tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_ticket_id (ticket_id),
    INDEX idx_user_id (user_id)
);

-- Activities/Logs table
CREATE TABLE activities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT, -- NULL for system activities
    action VARCHAR(255) NOT NULL,
    details TEXT,
    type ENUM('admin', 'company', 'client', 'system') NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_type (type),
    INDEX idx_created_at (created_at)
);

-- API Keys table (for AI model integration)
CREATE TABLE api_keys (
    id INT AUTO_INCREMENT PRIMARY KEY,
    provider VARCHAR(50) NOT NULL, -- 'openai', 'anthropic', etc.
    api_key VARCHAR(500) NOT NULL,
    status ENUM('active', 'inactive', 'expired') DEFAULT 'active',
    last_used TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_provider (provider),
    INDEX idx_status (status)
);

-- Company documents table
CREATE TABLE company_documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    company_id INT NOT NULL,
    document_type VARCHAR(100), -- 'registration', 'license', 'certificate', etc.
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INT,
    mime_type VARCHAR(100),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_company_id (company_id),
    INDEX idx_document_type (document_type)
);

-- Interview feedback/questions table (optional, for detailed interview data)
CREATE TABLE interview_questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    interview_id INT NOT NULL,
    question_text TEXT NOT NULL,
    user_answer TEXT,
    ai_feedback TEXT,
    score DECIMAL(5,2),
    question_order INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (interview_id) REFERENCES interviews(id) ON DELETE CASCADE,
    INDEX idx_interview_id (interview_id),
    INDEX idx_question_order (question_order)
);

-- Password reset codes table
CREATE TABLE IF NOT EXISTS password_reset_codes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_code (code)
);

-- User sessions table (for tracking login sessions)
CREATE TABLE user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_token VARCHAR(500) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    login_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logout_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_session_token (session_token),
    INDEX idx_is_active (is_active)
);

-- User settings table (for storing user preferences and security settings)
CREATE TABLE user_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    -- Password settings
    password_last_changed TIMESTAMP NULL,
    -- 2-Step Authentication settings
    two_step_email BOOLEAN DEFAULT FALSE,
    two_step_sms BOOLEAN DEFAULT FALSE,
    two_step_app BOOLEAN DEFAULT FALSE,
    -- Notification preferences
    promo_email BOOLEAN DEFAULT TRUE,
    promo_sms BOOLEAN DEFAULT FALSE,
    -- Security settings
    login_alerts BOOLEAN DEFAULT TRUE,
    session_timeout INT DEFAULT 30, -- minutes
    -- Privacy settings
    profile_visibility ENUM('public', 'private', 'company_only') DEFAULT 'private',
    -- Communication preferences
    email_frequency ENUM('immediate', 'daily', 'weekly', 'never') DEFAULT 'immediate',
    -- Created and updated timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
);

-- Platform settings table (global configurations)
CREATE TABLE IF NOT EXISTS settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_group VARCHAR(50) DEFAULT 'general', -- 'general', 'email', 'security', 'api'
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert default platform settings
INSERT IGNORE INTO settings (setting_key, setting_value, setting_group, description) VALUES
('site_name', 'AI Interviewer', 'general', 'The name of the platform'),
('maintenance_mode', 'false', 'general', 'Toggle maintenance mode'),
('allow_registration', 'true', 'security', 'Allow new user signups'),
('default_language', 'English', 'general', 'Default system language'),
('smtp_host', 'smtp-relay.brevo.com', 'email', 'SMTP Host address'),
('smtp_port', '587', 'email', 'SMTP Port number'),
('session_timeout_default', '30', 'security', 'Default session timeout in minutes'),
('ai_provider', 'openai', 'api', 'AI provider to use (openai, gemini)'),
('ai_model', 'gpt-4', 'api', 'Specific model name to use');

-- Insert demo data
-- Demo users
INSERT INTO users (username, email, password_hash, first_name, last_name, role) VALUES
('admin', 'admin@demo.com', 'scrypt:32768:8:1$jiyyABdpyMRmrdui$db34da9dc483bc9ab76ff57f39bbe2843f1f582f8d923059407e254c7b6539b0cad32406c94ed0a48b32dce0592082926c4987c2ba46645251aaa198db71ec7d', 'System', 'Admin', 'admin'),
('company', 'company@demo.com', 'scrypt:32768:8:1$jiyyABdpyMRmrdui$db34da9dc483bc9ab76ff57f39bbe2843f1f582f8d923059407e254c7b6539b0cad32406c94ed0a48b32dce0592082926c4987c2ba46645251aaa198db71ec7d', 'Main', 'Company', 'company'),
('client', 'client@demo.com', 'scrypt:32768:8:1$jiyyABdpyMRmrdui$db34da9dc483bc9ab76ff57f39bbe2843f1f582f8d923059407e254c7b6539b0cad32406c94ed0a48b32dce0592082926c4987c2ba46645251aaa198db71ec7d', 'John', 'Client', 'client'),
('company_user', 'companyuser@demo.com', 'scrypt:32768:8:1$jiyyABdpyMRmrdui$db34da9dc483bc9ab76ff57f39bbe2843f1f582f8d923059407e254c7b6539b0cad32406c94ed0a48b32dce0592082926c4987c2ba46645251aaa198db71ec7d', 'Jane', 'User', 'company_user');

-- Demo company
INSERT INTO companies (platform_id, company_name, first_name, last_name, email, country) VALUES
('M1X9K2', 'MedxAnalysis Tech', 'Company', 'Admin', 'company@demo.com', 'Pakistan');

-- Link company user to company in users table
UPDATE users SET company_id = (SELECT id FROM companies WHERE email = 'company@demo.com') WHERE role = 'company_user';

-- Insert into company_users table for the specific employee_id
INSERT INTO company_users (user_id, company_id, employee_id) VALUES
((SELECT id FROM users WHERE email = 'companyuser@demo.com'), (SELECT id FROM companies WHERE email = 'company@demo.com'), 'ME12A45B');

-- Demo subscription plans
INSERT INTO subscription_plans (name, target_audience, monthly_price, yearly_price, monthly_discount, yearly_discount, monthly_promo, yearly_promo, features) VALUES
('Free Basic', 'individual', 0.00, 0.00, 0, 0, '', '', '1 Interview / month, No AI Feedback, Limited Voices'),
('Pro Individual', 'individual', 29.00, 290.00, 0, 20, 'Most Popular', 'Best Value', '5 Interviews / month, Basic AI Feedback, Standard Voices'),
('Enterprise Ultra', 'company', 199.00, 1900.00, 10, 25, '', 'Enterprise Deal', 'Unlimited Users, 24/7 Dedicated Support, Custom Form Integrations, White-label Branding');

-- Demo subscriptions (using plan_id references)
INSERT INTO subscriptions (user_id, plan_id, status, billing_cycle, price, currency, start_date, end_date) VALUES
(3, 1, 'active', 'monthly', 0.00, 'USD', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 MONTH)),
(4, 2, 'active', 'monthly', 29.00, 'USD', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 MONTH));

-- Demo notifications
INSERT INTO notifications (user_id, title, message, type) VALUES
(3, 'Welcome to AI Interviewer', 'Your account has been successfully created. Start practicing interviews today!', 'system'),
(4, 'Company Interview Assigned', 'Tech Corp Inc. has assigned you a Senior React Developer interview.', 'company');

-- Demo interviews
INSERT INTO interviews (user_id, target_role, interview_type, duration, status, company_id) VALUES
(4, 'Senior Frontend Developer', 'company', 45, 'in_progress', 1),
(3, 'Product Manager', 'company', 30, 'in_progress', 1);

-- Demo user settings
INSERT INTO user_settings (user_id, two_step_email, promo_email, login_alerts) VALUES
(1, TRUE, FALSE, TRUE), -- Admin: 2FA email enabled, no promo emails, login alerts enabled
(2, FALSE, TRUE, TRUE), -- Company: no 2FA, promo emails enabled, login alerts enabled
(3, TRUE, TRUE, FALSE), -- Client: 2FA email enabled, promo emails enabled, no login alerts
(4, FALSE, TRUE, TRUE); -- Company user: no 2FA, promo emails enabled, login alerts enabled

-- Demo activities
INSERT INTO activities (user_id, action, type) VALUES
(1, 'User logged in', 'admin'),
(2, 'Company profile updated', 'company'),
(3, 'Interview completed', 'client'),
(NULL, 'System maintenance completed', 'system');

-- Demo API keys (placeholder)
INSERT INTO api_keys (provider, api_key, status) VALUES
('openai', 'sk-proj-placeholder-key', 'active'),
('anthropic', 'sk-ant-placeholder-key', 'inactive');

-- Create indexes for better performance
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_interviews_created_at ON interviews(created_at);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_support_tickets_created_at ON support_tickets(created_at);
CREATE INDEX idx_activities_created_at ON activities(created_at);

-- Contact Sales Table
CREATE TABLE `contact_sales` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `subject` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `status` enum('pending','contacted','resolved') DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Payment methods table (for storing user cards)
CREATE TABLE IF NOT EXISTS payment_methods (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    name_on_card VARCHAR(255) NOT NULL,
    card_number VARCHAR(255) NOT NULL,
    expiry VARCHAR(10) NOT NULL,
    cvv VARCHAR(10) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
);