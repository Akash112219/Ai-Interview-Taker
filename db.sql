-- AI Interviewer PostgreSQL schema for Supabase deployment
-- This schema is Postgres-compatible and matches the Flask app queries.
-- Demo user/company seed data from the MySQL schema is intentionally omitted.

CREATE TABLE IF NOT EXISTS companies (
    id BIGSERIAL PRIMARY KEY,
    platform_id VARCHAR(6) UNIQUE,
    company_name VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    country VARCHAR(100),
    region VARCHAR(100),
    address TEXT,
    profile_img VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(200) GENERATED ALWAYS AS (COALESCE(first_name, '') || CASE WHEN first_name IS NOT NULL AND last_name IS NOT NULL AND last_name <> '' THEN ' ' ELSE '' END || COALESCE(last_name, '')) STORED,
    phone VARCHAR(20),
    country VARCHAR(100),
    region VARCHAR(100),
    address TEXT,
    profile_img VARCHAR(500),
    role VARCHAR(20) NOT NULL DEFAULT 'client',
    is_active BOOLEAN DEFAULT TRUE,
    cnic VARCHAR(20),
    designation VARCHAR(100),
    company_id BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_company_id ON users(company_id);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);

CREATE TABLE IF NOT EXISTS company_users (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    company_id BIGINT NOT NULL,
    employee_id VARCHAR(8) UNIQUE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_company_users_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_company_users_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_company_users_user_id ON company_users(user_id);
CREATE INDEX IF NOT EXISTS idx_company_users_company_id ON company_users(company_id);
CREATE INDEX IF NOT EXISTS idx_company_users_employee_id ON company_users(employee_id);

CREATE TABLE IF NOT EXISTS interviews (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    target_role VARCHAR(255),
    interview_type VARCHAR(20) DEFAULT 'self',
    overall_score NUMERIC(5,2),
    duration INTEGER,
    voice_language VARCHAR(50),
    status VARCHAR(20) DEFAULT 'pending',
    company_id BIGINT,
    employee_id VARCHAR(8),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    CONSTRAINT fk_interviews_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_interviews_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL,
    CONSTRAINT fk_interviews_employee FOREIGN KEY (employee_id) REFERENCES company_users(employee_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_interviews_user_id ON interviews(user_id);
CREATE INDEX IF NOT EXISTS idx_interviews_company_id ON interviews(company_id);
CREATE INDEX IF NOT EXISTS idx_interviews_employee_id ON interviews(employee_id);
CREATE INDEX IF NOT EXISTS idx_interviews_status ON interviews(status);
CREATE INDEX IF NOT EXISTS idx_interviews_created_at ON interviews(created_at);

CREATE TABLE IF NOT EXISTS subscription_plans (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    target_audience VARCHAR(20) NOT NULL,
    company_id BIGINT,
    monthly_price NUMERIC(10,2) NOT NULL DEFAULT 0,
    yearly_price NUMERIC(10,2) NOT NULL DEFAULT 0,
    monthly_discount INTEGER DEFAULT 0,
    yearly_discount INTEGER DEFAULT 0,
    monthly_promo VARCHAR(50),
    yearly_promo VARCHAR(50),
    features TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_subscription_plans_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_subscription_plans_name_audience ON subscription_plans(name, target_audience);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_target_audience ON subscription_plans(target_audience);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_company_id ON subscription_plans(company_id);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_is_active ON subscription_plans(is_active);

CREATE TABLE IF NOT EXISTS subscriptions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    plan_id BIGINT NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    billing_cycle VARCHAR(20) NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    discount_applied INTEGER DEFAULT 0,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    payment_method VARCHAR(50),
    transaction_id VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_subscriptions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_subscriptions_plan FOREIGN KEY (plan_id) REFERENCES subscription_plans(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan_id ON subscriptions(plan_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_start_date ON subscriptions(start_date);
CREATE INDEX IF NOT EXISTS idx_subscriptions_end_date ON subscriptions(end_date);

CREATE TABLE IF NOT EXISTS notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    type VARCHAR(20) DEFAULT 'system',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

CREATE TABLE IF NOT EXISTS support_tickets (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    ticket_number VARCHAR(20) UNIQUE NOT NULL,
    subject VARCHAR(255) NOT NULL,
    message TEXT,
    status VARCHAR(20) DEFAULT 'open',
    priority VARCHAR(20) DEFAULT 'medium',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    CONSTRAINT fk_support_tickets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_ticket_number ON support_tickets(ticket_number);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at ON support_tickets(created_at);

CREATE TABLE IF NOT EXISTS support_replies (
    id BIGSERIAL PRIMARY KEY,
    ticket_id BIGINT NOT NULL,
    user_id BIGINT,
    reply_text TEXT NOT NULL,
    is_admin_reply BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_support_replies_ticket FOREIGN KEY (ticket_id) REFERENCES support_tickets(id) ON DELETE CASCADE,
    CONSTRAINT fk_support_replies_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_support_replies_ticket_id ON support_replies(ticket_id);
CREATE INDEX IF NOT EXISTS idx_support_replies_user_id ON support_replies(user_id);

CREATE TABLE IF NOT EXISTS activities (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    action VARCHAR(255) NOT NULL,
    details TEXT,
    type VARCHAR(20) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_activities_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_activities_user_id ON activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_type ON activities(type);
CREATE INDEX IF NOT EXISTS idx_activities_created_at ON activities(created_at);

CREATE TABLE IF NOT EXISTS api_keys (
    id BIGSERIAL PRIMARY KEY,
    provider VARCHAR(50) NOT NULL,
    api_key VARCHAR(500) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    last_used TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_api_keys_provider ON api_keys(provider);
CREATE INDEX IF NOT EXISTS idx_api_keys_status ON api_keys(status);

CREATE TABLE IF NOT EXISTS company_documents (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL,
    document_type VARCHAR(100),
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100),
    uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_company_documents_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_company_documents_company_id ON company_documents(company_id);
CREATE INDEX IF NOT EXISTS idx_company_documents_document_type ON company_documents(document_type);

CREATE TABLE IF NOT EXISTS interview_questions (
    id BIGSERIAL PRIMARY KEY,
    interview_id BIGINT NOT NULL,
    question_text TEXT NOT NULL,
    user_answer TEXT,
    ai_feedback TEXT,
    score NUMERIC(5,2),
    question_order INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_interview_questions_interview FOREIGN KEY (interview_id) REFERENCES interviews(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_interview_questions_interview_id ON interview_questions(interview_id);
CREATE INDEX IF NOT EXISTS idx_interview_questions_question_order ON interview_questions(question_order);

CREATE TABLE IF NOT EXISTS password_reset_codes (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_password_reset_codes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_password_reset_codes_user_id ON password_reset_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_password_reset_codes_code ON password_reset_codes(code);

CREATE TABLE IF NOT EXISTS user_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    session_token VARCHAR(500) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    login_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    logout_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_user_sessions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_session_token ON user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_is_active ON user_sessions(is_active);

CREATE TABLE IF NOT EXISTS user_settings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    password_last_changed TIMESTAMP NULL,
    two_step_email BOOLEAN DEFAULT FALSE,
    two_step_sms BOOLEAN DEFAULT FALSE,
    two_step_app BOOLEAN DEFAULT FALSE,
    promo_email BOOLEAN DEFAULT TRUE,
    promo_sms BOOLEAN DEFAULT FALSE,
    login_alerts BOOLEAN DEFAULT TRUE,
    session_timeout INTEGER DEFAULT 30,
    profile_visibility VARCHAR(20) DEFAULT 'private',
    email_frequency VARCHAR(20) DEFAULT 'immediate',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_settings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id);

CREATE TABLE IF NOT EXISTS settings (
    id BIGSERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_group VARCHAR(50) DEFAULT 'general',
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS contact_sales (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payment_methods (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    name_on_card VARCHAR(255) NOT NULL,
    card_number VARCHAR(255) NOT NULL,
    expiry VARCHAR(10) NOT NULL,
    cvv VARCHAR(10) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payment_methods_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON payment_methods(user_id);

INSERT INTO settings (setting_key, setting_value, setting_group, description) VALUES
('site_name', 'AI Interviewer', 'general', 'The name of the platform'),
('maintenance_mode', 'false', 'general', 'Toggle maintenance mode'),
('allow_registration', 'true', 'security', 'Allow new user signups'),
('default_language', 'English', 'general', 'Default system language'),
('smtp_host', 'smtp-relay.brevo.com', 'email', 'SMTP Host address'),
('smtp_port', '587', 'email', 'SMTP Port number'),
('session_timeout_default', '30', 'security', 'Default session timeout in minutes'),
('ai_provider', 'openai', 'api', 'AI provider to use (openai, gemini)'),
('ai_model', 'gpt-4', 'api', 'Specific model name to use')
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO subscription_plans (name, target_audience, monthly_price, yearly_price, monthly_discount, yearly_discount, monthly_promo, yearly_promo, features)
VALUES
('Free Basic', 'individual', 0.00, 0.00, 0, 0, '', '', '1 Interview / month, No AI Feedback, Limited Voices'),
('Pro Individual', 'individual', 29.00, 290.00, 0, 20, 'Most Popular', 'Best Value', '5 Interviews / month, Basic AI Feedback, Standard Voices'),
('Enterprise Ultra', 'company', 199.00, 1900.00, 10, 25, '', 'Enterprise Deal', 'Unlimited Users, 24/7 Dedicated Support, Custom Form Integrations, White-label Branding')
ON CONFLICT (name, target_audience) DO NOTHING;
