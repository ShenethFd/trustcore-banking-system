-- ----------------------------
-- FD_Term
-- ----------------------------
CREATE TABLE fd_term (
    id BIGSERIAL PRIMARY KEY,
    term_code VARCHAR(10) UNIQUE NOT NULL,
    duration_months INT NOT NULL,
    fd_interest_rate INT NOT NULL
);

-- ----------------------------
-- Account_Status
-- ----------------------------
CREATE TABLE account_status (
    id BIGSERIAL PRIMARY KEY,
    status_name VARCHAR(20) CHECK (status_name IN ('ACTIVE', 'INACTIVE', 'CLOSED', 'BLOCKED')) NOT NULL
);

-- ----------------------------
-- Interest_Plan
-- ----------------------------
CREATE TABLE interest_plan (
    id BIGSERIAL PRIMARY KEY,
    plan_name VARCHAR(20) NOT NULL,
    interest_rate INT NOT NULL,
    minimum_balance NUMERIC(10,2) NOT NULL,
    age_min INT NOT NULL,
    age_max INT NOT NULL
);

-- ----------------------------
-- Withdrawal_Policy
-- ----------------------------
CREATE TABLE withdrawal_policy (
    id BIGSERIAL PRIMARY KEY,
    minimum_balance_required NUMERIC(10,2) NOT NULL,
    daily_limit NUMERIC(10,2) NOT NULL,
    plan_id BIGINT UNIQUE,
    CONSTRAINT fk_withdrawal_plan FOREIGN KEY (plan_id)
        REFERENCES interest_plan(id)
);

-- ----------------------------
-- Branch
-- ----------------------------
CREATE TABLE branch (
    id BIGSERIAL PRIMARY KEY,
    branch_code VARCHAR(10) UNIQUE NOT NULL,
    branch_name VARCHAR(50) NOT NULL,
    district VARCHAR(20) NOT NULL
);

-- ----------------------------
-- Agent
-- ----------------------------
CREATE TABLE agent (
    id BIGSERIAL PRIMARY KEY,
    agent_code VARCHAR(10) UNIQUE NOT NULL,
    agent_name VARCHAR(20) NOT NULL,
    branch_id BIGINT NOT NULL REFERENCES branch(id)
);

-- ----------------------------
-- Customer
-- ----------------------------
CREATE TABLE customer (
    id BIGSERIAL PRIMARY KEY,
    customer_code VARCHAR(10) UNIQUE NOT NULL,
    first_name VARCHAR(25) NOT NULL,
    last_name VARCHAR(25) NOT NULL,
    date_of_birth DATE NOT NULL,
    branch_id BIGINT NOT NULL REFERENCES branch(id),
    agent_id BIGINT NOT NULL REFERENCES agent(id)
);

-- ----------------------------
-- Savings_Account
-- ----------------------------
CREATE TABLE savings_account (
    id BIGSERIAL PRIMARY KEY,
    savings_acc_code VARCHAR(12) UNIQUE NOT NULL,
    account_number CHAR(12) NOT NULL,
    plan_id BIGINT NOT NULL REFERENCES interest_plan(id),
    balance NUMERIC(10,2) NOT NULL,
    opened_date DATE NOT NULL,
    status_id BIGINT NOT NULL REFERENCES account_status(id),
    policy_id BIGINT REFERENCES withdrawal_policy(id)
);

-- ----------------------------
-- Account_Holder (M:N)
-- ----------------------------
CREATE TABLE account_holder (
    savings_acc_id BIGINT NOT NULL REFERENCES savings_account(id),
    customer_id BIGINT NOT NULL REFERENCES customer(id),
    PRIMARY KEY (savings_acc_id, customer_id)
);

-- ----------------------------
-- Fixed_Deposit (1:1 with Savings_Account)
-- ----------------------------
CREATE TABLE fixed_deposit (
    id BIGSERIAL PRIMARY KEY,
    fd_code VARCHAR(10) UNIQUE NOT NULL,
    savings_acc_id BIGINT UNIQUE NOT NULL REFERENCES savings_account(id),
    term_id BIGINT NOT NULL REFERENCES fd_term(id),
    amount NUMERIC(10,2) NOT NULL,
    start_date DATE NOT NULL,
    status_id BIGINT NOT NULL REFERENCES account_status(id)
);

-- ----------------------------
-- Bank_Transaction
-- ----------------------------
CREATE TABLE bank_transaction (
    id BIGSERIAL PRIMARY KEY,
    transaction_code VARCHAR(12) UNIQUE NOT NULL,
    savings_acc_id BIGINT NOT NULL REFERENCES savings_account(id),
    transaction_type VARCHAR(20) NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    time_stamp TIMESTAMP NOT NULL,
    reference_number VARCHAR(30),
    agent_id BIGINT NOT NULL REFERENCES agent(id)
);

-- ----------------------------
-- FD_Interest_Credit 
-- ----------------------------
CREATE TABLE fd_interest_credit (
    id BIGSERIAL PRIMARY KEY,
    fd_id BIGINT NOT NULL REFERENCES fixed_deposit(id),
    credited_date TIMESTAMP NOT NULL,
    credited_amount NUMERIC(10,2) NOT NULL,
    transaction_id BIGINT UNIQUE NOT NULL REFERENCES bank_transaction(id)
);

-- ----------------------------
-- Auditlog_Table
-- ----------------------------
CREATE TABLE auditlog_table (
    id BIGSERIAL PRIMARY KEY,
    audit_code VARCHAR(10) UNIQUE NOT NULL,
    entity_id BIGINT NOT NULL,
    entity_name VARCHAR(30) NOT NULL,
    action_type VARCHAR(30) NOT NULL,
    action_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    performed_by VARCHAR(25) NOT NULL
);