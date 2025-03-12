-- Converted from Oracle to PostgreSQL
-- Original: FWSAFS.SP_SA_TSACT011
-- Conversion date: 2024-01-09

CREATE SCHEMA IF NOT EXISTS fwsafs;

CREATE OR REPLACE FUNCTION fwsafs.sp_sa_tsact011(
    INOUT p_result_cd INTEGER    -- Error code
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $function$
DECLARE
    -- Variables
    v_log_on CHAR(1) := 'Y';   -- Log output flag
    v_buy_est_ym DATE;
    v_timestamp TIMESTAMP;
    tmp_tsact058 RECORD;
    v_req_title_txt TEXT;

    -- Custom exception
    e_proc_success EXCEPTION;

BEGIN
    -- Initialize result code
    p_result_cd := 0;

    -- Get current timestamp
    SELECT CURRENT_TIMESTAMP INTO v_timestamp;

    -- Main cursor replaced with FOR loop
    FOR tmp_tsact058 IN 
        SELECT a.*
        FROM tsact058 a
        WHERE NOT EXISTS (
            SELECT 1  -- Changed from b.* to 1 for efficiency
            FROM tisact010 b
            WHERE b.co_id = a.co_id
        )
        AND (a.req_no LIKE 'Q%' OR a.req_no LIKE 'T%')
    LOOP
        -- Process each record
        BEGIN
            IF tmp_tsact058.req_div_cd = '11' THEN
                -- Main insert operations
                INSERT INTO tisact010 (
                    co_id,           -- Company ID
                    pur_req_no,      -- Purchase request number
                    snd_dt,          -- Send datetime
                    req_titl_txt,    -- Request title text
                    req_tgt_txt,     -- Request target text
                    buy_est_ymd,     -- Buy estimate date
                    rmk_txt,         -- Remarks text
                    pur_cl_cd,       -- Purchase classification code
                    slbz_emp_no,     -- Sales employee number
                    rel_cst_rt,      -- Related cost rate
                    sttl_stts_cd,    -- Settlement status code
                    pur_cnfr_no,     -- Purchase confirmation number
                    aply_div_cd,     -- Apply division code
                    int_aply_cpl_yn, -- Internal apply complete flag
                    regr_id,         -- Registrant ID
                    reg_dt,          -- Registration datetime
                    updr_id,         -- Updater ID
                    upd_dt,          -- Update datetime
                    err_msg          -- Error message
                )
                VALUES (
                    tmp_tsact058.co_id,
                    tmp_tsact058.req_no,
                    v_timestamp,
                    v_req_title_txt,
                    '',
                    tmp_tsact058.buy_est_ymd,
                    tmp_tsact058.req_rsn_txt,
                    tmp_tsact058.req_div_cd,
                    tmp_tsact058.slbz_emp_no,
                    0,
                    tmp_tsact058.ack_stts_cd,
                    '',
                    'I',
                    'N',
                    'SYSTEM',
                    CURRENT_TIMESTAMP,
                    'SYSTEM',
                    CURRENT_TIMESTAMP,
                    NULL
                );

                -- Insert into TISACT011
                INSERT INTO tisact011 (
                    co_id,            -- Company ID
                    pur_req_no,       -- Purchase request number
                    pur_req_seq,      -- Purchase request sequence
                    gd_no,            -- Good number
                    snd_dt,           -- Send datetime
                    ctr_cd,           -- Center code
                    gd_unit_cd,       -- Good unit code
                    pur_req_tot_qty,  -- Purchase request total quantity
                    pur_req_unprc,    -- Purchase request unit price
                    buy_tot_at,       -- Buy total amount
                    est_sales_at,     -- Estimate sales amount
                    est_sales_prft_rt,-- Estimate sales profit rate
                    bcnr_id,          -- Business partner ID
                    strg_wh_cd,       -- Storage warehouse code
                    dlv_req_ymd,      -- Delivery request date
                    tarf_rt,          -- Tariff rate
                    aply_div_cd,      -- Apply division code
                    int_aply_cpl_yn,  -- Internal apply complete flag
                    regr_id,          -- Registrant ID
                    reg_dt,           -- Registration datetime
                    updr_id,          -- Updater ID
                    upd_dt,           -- Update datetime
                    err_msg,          -- Error message
                    nfxat_gd_yn,      -- Non-fixed good flag
                    bas_unit_cd,      -- Base unit code
                    avg_wt,           -- Average weight
                    cvt_unit_qty      -- Convert unit quantity
                )
                VALUES (
                    tmp_tsact058.co_id,
                    tmp_tsact058.req_no,
                    '10',
                    tmp_tsact058.gd_no,
                    v_timestamp,
                    tmp_tsact058.lgs_ctr_id,
                    tmp_tsact058.gd_unit_cd,
                    tmp_tsact058.req_cnt_qty,
                    0,
                    0,
                    0,
                    0,
                    tmp_tsact058.bcnr_id,
                    '',
                    tmp_tsact058.buy_est_ymd,
                    0,
                    'I',
                    'N',
                    'SYSTEM',
                    CURRENT_TIMESTAMP,
                    'SYSTEM',
                    CURRENT_TIMESTAMP,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL
                );

                -- Insert into TISACT013
                INSERT INTO tisact013 (
                    co_id,              -- Company ID
                    pur_req_no,         -- Purchase request number
                    pur_req_seq,        -- Purchase request sequence
                    snd_dt,             -- Send datetime
                    cust_id,            -- Customer ID
                    gd_no,              -- Good number
                    sale_unit_cd,       -- Sale unit code
                    sale_qty,           -- Sale quantity
                    sale_prc,           -- Sale price
                    est_sales_at,       -- Estimate sales amount
                    est_sales_prft_at,  -- Estimate sales profit amount
                    est_prft_rt,        -- Estimate profit rate
                    sale_est_ymd,       -- Sale estimate date
                    pur_prx_fee,        -- Purchase proxy fee
                    aply_irt_rt,        -- Apply interest rate
                    rlstk_prft_rt,      -- Real stock profit rate
                    ppyd_rt,            -- Prepaid rate
                    exi_ppyd_at,        -- Existing prepaid amount
                    rprs_cust_yn,       -- Representative customer flag
                    aply_div_cd,        -- Apply division code
                    int_aply_cpl_yn,    -- Internal apply complete flag
                    regr_id,            -- Registrant ID
                    reg_dt,             -- Registration datetime
                    updr_id,            -- Updater ID
                    upd_dt,             -- Update datetime
                    err_msg             -- Error message
                )
                VALUES (
                    tmp_tsact058.co_id,
                    tmp_tsact058.req_no,
                    '10',
                    v_timestamp,
                    tmp_tsact058.slst_id,
                    tmp_tsact058.gd_no,
                    tmp_tsact058.gd_unit_cd,
                    tmp_tsact058.req_cnt_qty,
                    tmp_tsact058.est_sale_at,
                    tmp_tsact058.req_cnt_qty * tmp_tsact058.est_sale_at,
                    0,
                    0,
                    '',
                    0,
                    0,
                    0,
                    0,
                    0,
                    '',
                    'I',
                    'N',
                    'SYSTEM',
                    CURRENT_TIMESTAMP,
                    'SYSTEM',
                    CURRENT_TIMESTAMP,
                    NULL
                );
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                -- Error handling
                p_result_cd := -1;
                RAISE;
        END;
    END LOOP;

    -- Success case
    p_result_cd := 0;
    RETURN p_result_cd;

EXCEPTION
    WHEN OTHERS THEN
        -- Global error handling
        p_result_cd := -2;
        RAISE;
END;
$function$;