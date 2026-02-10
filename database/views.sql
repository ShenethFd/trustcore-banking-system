CREATE OR REPLACE VIEW agent_transaction_summary AS
SELECT
    a.id                      AS agent_id,
    a.agent_code,
    a.agent_name,
    br.id                     AS branch_id,
    br.branch_name,
    COUNT(bt.id)              AS total_transactions,
    COALESCE(SUM(bt.amount), 0.00)::NUMERIC(18,2) AS total_amount
FROM agent a
LEFT JOIN branch br ON br.id = a.branch_id
LEFT JOIN bank_transaction bt ON bt.agent_id = a.id
GROUP BY a.id, a.agent_code, a.agent_name, br.id, br.branch_name;


CREATE OR REPLACE VIEW account_transaction_summary AS
SELECT
    sa.id                              AS savings_acc_id,
    sa.savings_acc_code,
    sa.account_number,
    sa.balance                          AS current_balance,
    COUNT(bt.id)                       AS total_transactions,
    COALESCE(SUM(bt.amount), 0.00)::NUMERIC(18,2)                                  AS total_amount,
    COALESCE(SUM(bt.amount) FILTER (WHERE bt.transaction_type ILIKE 'Deposit'), 0.00)::NUMERIC(18,2)    AS total_deposits,
    COALESCE(SUM(bt.amount) FILTER (WHERE bt.transaction_type ILIKE 'Withdrawal'), 0.00)::NUMERIC(18,2) AS total_withdrawals,
    MAX(bt.time_stamp)                 AS last_transaction_at
FROM savings_account sa
LEFT JOIN bank_transaction bt ON bt.savings_acc_id = sa.id
GROUP BY sa.id, sa.savings_acc_code, sa.account_number, sa.balance;


CREATE OR REPLACE VIEW active_fd_next_payout AS
SELECT
    fd.id                                    AS fd_id,
    fd.fd_code,
    sa.id                                    AS savings_acc_id,
    sa.savings_acc_code,
    sa.account_number,
    fd.amount,
    fd.start_date,
    tt.term_code,
    tt.duration_months,
    tt.fd_interest_rate,
    MAX(fic.credited_date)                   AS last_interest_credited_at,
    -- next payout = last credited date (if any) OR start_date  + term duration
    COALESCE(MAX(fic.credited_date)::date, fd.start_date)+ (INTERVAL '1 month')
                                            AS next_payout_date

FROM fixed_deposit fd
JOIN fd_term tt            ON tt.id = fd.term_id
JOIN account_status st     ON st.id = fd.status_id
JOIN savings_account sa    ON sa.id = fd.savings_acc_id
LEFT JOIN fd_interest_credit fic ON fic.fd_id = fd.id
WHERE st.status_name = 'ACTIVE'
GROUP BY fd.id, fd.fd_code, sa.id, sa.savings_acc_code, sa.account_number, fd.amount, fd.start_date, tt.term_code, tt.duration_months, tt.fd_interest_rate;

CREATE OR REPLACE VIEW monthly_interest_distribution AS
SELECT
    date_trunc('month', t.credited_at)::date                        AS month,
    ip.plan_name                                                     AS account_type,
    COUNT(*)                                                         AS interest_transactions,
    COALESCE(SUM(t.amount), 0.00)::NUMERIC(18,2)                     AS total_interest
FROM (
    -- FD interest credits (joins FD -> savings account -> plan)
    SELECT
        fic.credited_date::timestamp    AS credited_at,
        fic.credited_amount             AS amount,
        sa.plan_id                      AS plan_id
    FROM fd_interest_credit fic
    JOIN fixed_deposit fd ON fd.id = fic.fd_id
    JOIN savings_account sa ON sa.id = fd.savings_acc_id

    UNION ALL

    -- Interest posted as bank transactions (savings account interest)
    SELECT
        bt.time_stamp                    AS credited_at,
        bt.amount                        AS amount,
        sa.plan_id                       AS plan_id
    FROM bank_transaction bt
    JOIN savings_account sa ON sa.id = bt.savings_acc_id
    WHERE bt.transaction_type ILIKE 'Interest'
) t
JOIN interest_plan ip ON ip.id = t.plan_id
GROUP BY date_trunc('month', t.credited_at), ip.plan_name
ORDER BY month DESC, ip.plan_name;


CREATE OR REPLACE VIEW customer_activity_report AS
WITH tx AS (
    SELECT
        ah.customer_id,
        COUNT(bt.id) AS total_transactions,
        COALESCE(SUM(bt.amount) FILTER (WHERE bt.transaction_type ILIKE 'Deposit'), 0.00) AS total_deposits,
        COALESCE(SUM(bt.amount) FILTER (WHERE bt.transaction_type ILIKE 'Withdrawal'), 0.00) AS total_withdrawals,
        MAX(bt.time_stamp) AS last_transaction_at
    FROM account_holder ah
    JOIN bank_transaction bt ON bt.savings_acc_id = ah.savings_acc_id
    GROUP BY ah.customer_id
),
bal AS (
    SELECT
        ah.customer_id,
        COALESCE(SUM(sa.balance), 0.00) AS total_balance
    FROM account_holder ah
    JOIN savings_account sa ON sa.id = ah.savings_acc_id
    GROUP BY ah.customer_id
)
SELECT
    c.id                             AS customer_id,
    c.customer_code,
    c.first_name,
    c.last_name,
    COALESCE(tx.total_transactions, 0)                          AS total_transactions,
    COALESCE(tx.total_deposits, 0.00)::NUMERIC(18,2)            AS total_deposits,
    COALESCE(tx.total_withdrawals, 0.00)::NUMERIC(18,2)         AS total_withdrawals,
    (COALESCE(tx.total_deposits, 0.00) - COALESCE(tx.total_withdrawals, 0.00))::NUMERIC(18,2) AS net_flow,
    COALESCE(bal.total_balance, 0.00)::NUMERIC(18,2)            AS total_balance,
    tx.last_transaction_at                                        AS last_transaction_at
FROM customer c
LEFT JOIN tx  ON tx.customer_id = c.id
LEFT JOIN bal ON bal.customer_id = c.id
ORDER BY c.customer_code;

