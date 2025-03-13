CREATE OR REPLACE PROCEDURE sp_sa_tsact011(
    p_pur_req_no varchar,
    INOUT p_result_cd integer
) 
AS $$
DECLARE
    v_log_on char(1);
    v_timestamp timestamp;
    v_req_title_txt varchar;
    v_err_msg text;
    v_err_detail text;
    v_err_hint text;
BEGIN
    p_result_cd := 0;
    v_log_on := 'Y';
    v_timestamp := CURRENT_TIMESTAMP;

    FOR tmp_tsact058 IN 
    SELECT * FROM tsact058 a 
    WHERE NOT EXISTS (ㅌ₩
        SELECT 1 FROM tisact010 b 
        WHERE b.co_id = a.co_id 
        AND b.pur_req_no = a.req_no
    )
    AND (a.req_no LIKE 'Q%' OR a.req_no LIKE 'T%')
    LOOP
        IF tmp_tsact058.req_div_cd = '11' THEN
            BEGIN
                INSERT INTO tisact010 (co_id, pur_req_no, snd_dt, req_titl_txt, req_tgt_txt,
                    buy_est_ymd, rmk_txt, pur_cl_cd, slbz_emp_no, rel_cst_rt,
                    sttl_stts_cd, pur_cnfr_no, aply_div_cd, int_aply_cpl_yn,
                    regr_id, reg_dt, updr_id, upd_dt, err_msg)
                VALUES (tmp_tsact058.co_id, tmp_tsact058.req_no, v_timestamp,
                    v_req_title_txt, '', tmp_tsact058.buy_est_ymd,
                    tmp_tsact058.req_rsn_txt, tmp_tsact058.req_div_cd,
                    tmp_tsact058.slbz_emp_no, 0, tmp_tsact058.ack_stts_cd,
                    '', 'I', 'N', 'SYSTEM', CURRENT_TIMESTAMP,
                    'SYSTEM', CURRENT_TIMESTAMP, NULL);

                INSERT INTO tisact011 (co_id, pur_req_no, pur_req_seq, gd_no, snd_dt,
                    ctr_cd, gd_unit_cd, pur_req_tot_qty, pur_req_unprc,
                    buy_tot_at, est_sales_at, est_sales_prft_rt, bcnr_id,
                    strg_wh_cd, dlv_req_ymd, tarf_rt, aply_div_cd,
                    int_aply_cpl_yn, regr_id, reg_dt, updr_id, upd_dt,
                    err_msg, nfxat_gd_yn, bas_unit_cd, avg_wt, cvt_unit_qty)
                VALUES (tmp_tsact058.co_id, tmp_tsact058.req_no, '10',
                    tmp_tsact058.gd_no, v_timestamp, tmp_tsact058.lgs_ctr_id,
                    tmp_tsact058.gd_unit_cd, tmp_tsact058.req_cnt_qty,
                    0, 0, 0, 0, tmp_tsact058.bcnr_id, '',
                    tmp_tsact058.buy_est_ymd, 0, 'I', 'N',
                    'SYSTEM', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP,
                    NULL, NULL, NULL, NULL, NULL);

                INSERT INTO tisact013 (co_id, pur_req_no, pur_req_seq, snd_dt, cust_id,
                    gd_no, sale_unit_cd, sale_qty, sale_prc, est_sales_at,
                    est_sales_prft_at, est_prft_rt, sale_est_ymd,
                    pur_prx_fee, aply_irt_rt, rlstk_prft_rt, ppyd_rt,
                    exi_ppyd_at, rprs_cust_yn, aply_div_cd, int_aply_cpl_yn,
                    regr_id, reg_dt, updr_id, upd_dt, err_msg)
                VALUES (tmp_tsact058.co_id, tmp_tsact058.req_no, '10',
                    v_timestamp, tmp_tsact058.slst_id, tmp_tsact058.gd_no,
                    tmp_tsact058.gd_unit_cd, tmp_tsact058.req_cnt_qty,
                    tmp_tsact058.est_sale_at,
                    tmp_tsact058.req_cnt_qty * tmp_tsact058.est_sale_at,
                    0, 0, NULL, 0, 0, 0, 0, 0, '',
                    'I', 'N', 'SYSTEM', CURRENT_TIMESTAMP,
                    'SYSTEM', CURRENT_TIMESTAMP, NULL);
            EXCEPTION 
                WHEN OTHERS THEN
                    GET STACKED DIAGNOSTICS 
                        v_err_msg = MESSAGE_TEXT,
                        v_err_detail = PG_EXCEPTION_DETAIL,
                        v_err_hint = PG_EXCEPTION_HINT;
                    p_result_cd := -1;
                    RETURN;
            END;
        END IF;
    END LOOP;

EXCEPTION 
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS 
            v_err_msg = MESSAGE_TEXT,
            v_err_detail = PG_EXCEPTION_DETAIL,
            v_err_hint = PG_EXCEPTION_HINT;
        p_result_cd := -2;
END;
$$ LANGUAGE plpgsql;