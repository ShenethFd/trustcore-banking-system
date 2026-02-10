-- Seed data (id lookups use SELECT to avoid relying on numeric ids)
-- Order: account_status, fd_term, interest_plan, withdrawal_policy, branch, agent, customer, savings_account, account_holder, fixed_deposit, bank_transaction

INSERT INTO account_status (status_name)
VALUES 
('ACTIVE'),
('INACTIVE'),
('CLOSED'),
('BLOCKED')
ON CONFLICT DO NOTHING;

INSERT INTO fd_term (term_code, duration_months, fd_interest_rate)
VALUES 
('FD-06M', 6, 13),
('FD-12M', 12, 14),
('FD-36M', 36, 15)
ON CONFLICT DO NOTHING;

INSERT INTO interest_plan (plan_name, interest_rate, minimum_balance, age_min, age_max)
VALUES 
('Joint Savings', 7, 5000, 20, 120),
('Senior Savings', 13, 1000, 60, 120),
('Adult Savings', 10, 1000, 20, 59),
('Teen Savings', 11, 500, 13, 19),
('Child Savings', 12, 0, 0, 12)
ON CONFLICT DO NOTHING;

INSERT INTO withdrawal_policy (minimum_balance_required, daily_limit, plan_id)
VALUES 
(100, 0, (SELECT id FROM interest_plan WHERE plan_name = 'Child Savings')),
(500, 1000, (SELECT id FROM interest_plan WHERE plan_name = 'Teen Savings')),
(1000, 100000, (SELECT id FROM interest_plan WHERE plan_name = 'Adult Savings')),
(5000, 200000, (SELECT id FROM interest_plan WHERE plan_name = 'Senior Savings')),
(5000, 500000, (SELECT id FROM interest_plan WHERE plan_name = 'Joint Savings'))
ON CONFLICT DO NOTHING;

INSERT INTO branch (branch_code, branch_name, district)
VALUES
('BR001', 'Colombo Main', 'Colombo'),
('BR002', 'Kandy Central', 'Kandy'),
('BR003', 'Galle Fort', 'Galle')
ON CONFLICT DO NOTHING;

INSERT INTO agent (agent_code, agent_name, branch_id)
VALUES
('AG001', 'Nimal Perera', (SELECT id FROM branch WHERE branch_code = 'BR001')),
('AG002', 'Sunil Fernando', (SELECT id FROM branch WHERE branch_code = 'BR002')),
('AG003', 'Kamal Silva', (SELECT id FROM branch WHERE branch_code = 'BR003'))
ON CONFLICT DO NOTHING;

INSERT INTO customer (customer_code, first_name, last_name, date_of_birth, branch_id, agent_id)
VALUES
('CUST001', 'Saman', 'Perera', '1995-02-15', (SELECT id FROM branch WHERE branch_code='BR001'), (SELECT id FROM agent WHERE agent_code='AG001')),
('CUST002', 'Kumara', 'Fernando', '1960-11-03', (SELECT id FROM branch WHERE branch_code='BR002'), (SELECT id FROM agent WHERE agent_code='AG002')),
('CUST003', 'Nadeesha', 'Silva', '1988-07-20', (SELECT id FROM branch WHERE branch_code='BR003'), (SELECT id FROM agent WHERE agent_code='AG003')),
('CUST004', 'Ishara', 'Jayasinghe', '1992-04-10', (SELECT id FROM branch WHERE branch_code='BR001'), (SELECT id FROM agent WHERE agent_code='AG001')),
('CUST005', 'Tharindu', 'Wijesinghe', '1990-09-22', (SELECT id FROM branch WHERE branch_code='BR001'), (SELECT id FROM agent WHERE agent_code='AG001'))
ON CONFLICT DO NOTHING;

INSERT INTO savings_account (savings_acc_code, account_number, plan_id, balance, opened_date, status_id, policy_id)
VALUES
('SA001', '100000000001', (SELECT id FROM interest_plan WHERE plan_name='Joint Savings'), 15000.00, '2025-01-01', (SELECT id FROM account_status WHERE status_name='ACTIVE'), (SELECT id FROM withdrawal_policy WHERE plan_id = (SELECT id FROM interest_plan WHERE plan_name = 'Joint Savings'))),
('SA002', '100000000002', (SELECT id FROM interest_plan WHERE plan_name='Senior Savings'), 100000.00, '2025-01-05', (SELECT id FROM account_status WHERE status_name='ACTIVE'), (SELECT id FROM withdrawal_policy WHERE plan_id = (SELECT id FROM interest_plan WHERE plan_name = 'Senior Savings'))),
('SA003', '100000000003', (SELECT id FROM interest_plan WHERE plan_name='Adult Savings'), 500000.00, '2025-02-10', (SELECT id FROM account_status WHERE status_name='ACTIVE'), (SELECT id FROM withdrawal_policy WHERE plan_id = (SELECT id FROM interest_plan WHERE plan_name = 'Adult Savings'))),
('SA004', '100000000004', (SELECT id FROM interest_plan WHERE plan_name='Teen Savings'), 2000.00, '2025-03-15', (SELECT id FROM account_status WHERE status_name='ACTIVE'), (SELECT id FROM withdrawal_policy WHERE plan_id = (SELECT id FROM interest_plan WHERE plan_name = 'Teen Savings'))),
('SA005', '100000000005', (SELECT id FROM interest_plan WHERE plan_name='Child Savings'), 800.00, '2025-04-20', (SELECT id FROM account_status WHERE status_name='ACTIVE'), (SELECT id FROM withdrawal_policy WHERE plan_id = (SELECT id FROM interest_plan WHERE plan_name = 'Child Savings'))),
('SA006', '100000000006', (SELECT id FROM interest_plan WHERE plan_name='Joint Savings'), 75000.00, '2025-03-01', (SELECT id FROM account_status WHERE status_name='ACTIVE'), (SELECT id FROM withdrawal_policy WHERE plan_id = (SELECT id FROM interest_plan WHERE plan_name = 'Joint Savings')))
ON CONFLICT DO NOTHING;

INSERT INTO account_holder (savings_acc_id, customer_id)
VALUES
((SELECT id FROM savings_account WHERE savings_acc_code='SA001'), (SELECT id FROM customer WHERE customer_code='CUST001')),
((SELECT id FROM savings_account WHERE savings_acc_code='SA002'), (SELECT id FROM customer WHERE customer_code='CUST002')),
((SELECT id FROM savings_account WHERE savings_acc_code='SA003'), (SELECT id FROM customer WHERE customer_code='CUST003')),
((SELECT id FROM savings_account WHERE savings_acc_code='SA006'), (SELECT id FROM customer WHERE customer_code='CUST004')),
((SELECT id FROM savings_account WHERE savings_acc_code='SA006'), (SELECT id FROM customer WHERE customer_code='CUST005'))
ON CONFLICT DO NOTHING;

INSERT INTO fixed_deposit (fd_code, savings_acc_id, term_id, amount, start_date, status_id)
VALUES
('FD001', (SELECT id FROM savings_account WHERE savings_acc_code='SA001'), (SELECT id FROM fd_term WHERE term_code='FD-06M'), 10000.00, '2025-01-10', (SELECT id FROM account_status WHERE status_name='ACTIVE')),
('FD002', (SELECT id FROM savings_account WHERE savings_acc_code='SA002'), (SELECT id FROM fd_term WHERE term_code='FD-12M'), 50000.00, '2025-01-15', (SELECT id FROM account_status WHERE status_name='ACTIVE'))
ON CONFLICT DO NOTHING;

INSERT INTO bank_transaction (transaction_code, savings_acc_id, transaction_type, amount, time_stamp, reference_number, agent_id)
VALUES
('TXN001', (SELECT id FROM savings_account WHERE savings_acc_code='SA001'), 'Deposit', 5000.00, '2025-01-01 10:00:00', 'REF001', (SELECT id FROM agent WHERE agent_code='AG001')),
('TXN002', (SELECT id FROM savings_account WHERE savings_acc_code='SA002'), 'Deposit', 50000.00, '2025-01-05 11:30:00', 'REF002', (SELECT id FROM agent WHERE agent_code='AG002')),
('TXN003', (SELECT id FROM savings_account WHERE savings_acc_code='SA003'), 'Deposit', 100000.00, '2025-02-10 09:45:00', 'REF003', (SELECT id FROM agent WHERE agent_code='AG003'))
ON CONFLICT DO NOTHING;

-- ...existing code...

INSERT INTO customer (customer_code, first_name, last_name, date_of_birth, branch_id, agent_id)
VALUES
('CUST006', 'Malsha', 'Perera', '1998-08-12', (SELECT id FROM branch WHERE branch_code='BR002'), (SELECT id FROM agent WHERE agent_code='AG002')),
('CUST007', 'Chathuri', 'Kumarasinghe', '2001-05-30', (SELECT id FROM branch WHERE branch_code='BR003'), (SELECT id FROM agent WHERE agent_code='AG003'))
ON CONFLICT DO NOTHING;

INSERT INTO account_holder (savings_acc_id, customer_id)
VALUES
((SELECT id FROM savings_account WHERE savings_acc_code='SA004'), (SELECT id FROM customer WHERE customer_code='CUST006')),
((SELECT id FROM savings_account WHERE savings_acc_code='SA005'), (SELECT id FROM customer WHERE customer_code='CUST007'))
ON CONFLICT DO NOTHING;

-- ...existing code...

-- Add interest bank transactions (used by monthly_interest_distribution) and link them to FDs

INSERT INTO bank_transaction (transaction_code, savings_acc_id, transaction_type, amount, time_stamp, reference_number, agent_id)
VALUES
('TXN_INT_001', (SELECT id FROM savings_account WHERE savings_acc_code='SA001'), 'Interest', 130.00, '2025-02-10 00:00:00', 'INTREF001', (SELECT id FROM agent WHERE agent_code='AG001')),
('TXN_INT_002', (SELECT id FROM savings_account WHERE savings_acc_code='SA002'), 'Interest', 500.00, '2025-02-15 00:00:00', 'INTREF002', (SELECT id FROM agent WHERE agent_code='AG002'))
ON CONFLICT DO NOTHING;

INSERT INTO fd_interest_credit (fd_id, credited_date, credited_amount, transaction_id)
VALUES
(
  (SELECT id FROM fixed_deposit WHERE fd_code='FD001'),
  '2025-02-10 00:00:00',
  130.00,
  (SELECT id FROM bank_transaction WHERE transaction_code='TXN_INT_001')
),
(
  (SELECT id FROM fixed_deposit WHERE fd_code='FD002'),
  '2025-02-15 00:00:00',
  500.00,
  (SELECT id FROM bank_transaction WHERE transaction_code='TXN_INT_002')
)
ON CONFLICT DO NOTHING;