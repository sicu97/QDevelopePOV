CREATE OR REPLACE PROCEDURE fwsafs.sp_sa_tsact011(
    p_pur_req_no IN VARCHAR,
    p_result_cd OUT INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    /*===============================================================*
     * MAIN TITLE   :  구매요청 I/F 테이블로 데이트를 생성한다.
     * PROCEDURE ID :  SP_SA_TISA010
     * PROGRAMMER   :  이 용 남
     *=============================================================*/
    -- Variable declarations
    v_est_sales_at      NUMERIC(13) := 0;    -- 예상 매출 금액
    v_est_sales_prft_at NUMERIC(13) := 0;    -- 예상 매출 이익 금액
    v_est_sales_prft_rt NUMERIC(5,2) := 0;   -- 예상 매출 이익 율
    v_req_title_txt     VARCHAR(100) := '';   -- 요청 제목
    v_rprs_cust_yn      CHAR(1) := '';       -- 로그 출력 여부
    n_count             INTEGER := 0;         -- 데이터 존재유무 저장 변수
    v_sql_code          INTEGER := 0;         -- SQL 수행 결과값 저장 변수
    v_sql_msg           VARCHAR(200);         -- sql message
    v_log_on            CHAR(1) := 'Y';      -- 로그 출력 여부
    v_buy_est_ym        DATE;
    v_timestamp         TIMESTAMP;
    tmp_tsact058        tsact058%ROWTYPE;

BEGIN
    p_result_cd := 0;

    -- Get current timestamp
    SELECT CURRENT_TIMESTAMP INTO v_timestamp;

    -- Main cursor processing
    FOR tmp_tsact058 IN 
        SELECT a.*
        FROM tsact058 a
        WHERE NOT EXISTS (
            SELECT 1
            FROM tisact010 b
            WHERE b.co_id = a.co_id
            AND b.pur_req_no = a.req_no
        )
        AND a.req_no = p_pur_req_no
        AND (a.req_no LIKE 'Q%' OR a.req_no LIKE 'T%')
        ORDER BY a.co_id, a.req_no
    LOOP
        -- Set request title based on request division code
        IF tmp_tsact058.req_div_cd = '11' THEN
            v_req_title_txt := '수발주 연결요청';
        ELSIF tmp_tsact058.req_div_cd = '12' THEN
            v_req_title_txt := '저장품 수급요청(한우/한돈/수입육) 요청';
        ELSIF tmp_tsact058.req_div_cd = '13' THEN
            v_req_title_txt := '저장품 수급요청(기타) ';
        END IF;

        -- Insert into TISACT010
        INSERT INTO tisact010 (
            co_id, pur_req_no, snd_dt, req_titl_txt, req_tgt_txt,
            buy_est_ymd, rmk_txt, pur_cl_cd, slbz_emp_no, rel_cst_rt,
            sttl_stts_cd, pur_cnfr_no, aply_div_cd, int_aply_cpl_yn,
            regr_id, reg_dt, updr_id, upd_dt, err_msg
        )
        VALUES (
            tmp_tsact058.co_id, tmp_tsact058.req_no, v_timestamp,
            v_req_title_txt, '', tmp_tsact058.buy_est_ymd,
            tmp_tsact058.req_rsn_txt, tmp_tsact058.req_div_cd,
            tmp_tsact058.slbz_emp_no, 0, tmp_tsact058.ack_stts_cd,
            '', 'I', 'N', 'SYSTEM', CURRENT_TIMESTAMP,
            'SYSTEM', CURRENT_TIMESTAMP, NULL
        );

        -- Insert into TISACT011
        INSERT INTO tisact011 (
            co_id, pur_req_no, pur_req_seq, gd_no, snd_dt,
            ctr_cd, gd_unit_cd, pur_req_tot_qty, pur_req_unprc,
            buy_tot_at, est_sales_at, est_sales_prft_rt, bcnr_id,
            strg_wh_cd, dlv_req_ymd, tarf_rt, aply_div_cd,
            int_aply_cpl_yn, regr_id, reg_dt, updr_id, upd_dt,
            err_msg, nfxat_gd_yn, bas_unit_cd, avg_wt, cvt_unit_qty
        )
        SELECT 
            tmp_tsact058.co_id, tmp_tsact058.req_no, '10',
            tmp_tsact058.gd_no, v_timestamp, tmp_tsact058.lgs_ctr_id,
            tmp_tsact058.gd_unit_cd, tmp_tsact058.req_cnt_qty,
            0, 0, 0, 0, tmp_tsact058.bcnr_id, '',
            tmp_tsact058.buy_est_ymd, 0, 'I', 'N',
            'SYSTEM', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP,
            NULL, b.nfxat_gd_yn, b.bas_unit_cd, b.avg_wt,
            COALESCE(a.req_cnt_qty,0) * COALESCE(b.avg_wt,0)
        FROM tsact058 a
        LEFT JOIN tcbcm009 b ON a.co_id = b.co_id AND a.gd_no = b.gd_no
        WHERE a.co_id = tmp_tsact058.co_id
        AND a.req_no = tmp_tsact058.req_no;

        -- Insert into TISACT013
        INSERT INTO tisact013 (
            co_id, pur_req_no, pur_req_seq, snd_dt, cust_id,
            gd_no, sale_unit_cd, sale_qty, sale_prc, est_sales_at,
            est_sales_prft_at, est_prft_rt, sale_est_ymd, pur_prx_fee,
            aply_irt_rt, rlstk_prft_rt, ppyd_rt, exi_ppyd_at,
            rprs_cust_yn, aply_div_cd, int_aply_cpl_yn, regr_id,
            reg_dt, updr_id, upd_dt, err_msg
        )
        VALUES (
            tmp_tsact058.co_id, tmp_tsact058.req_no, '10',
            v_timestamp, tmp_tsact058.slst_id, tmp_tsact058.gd_no,
            tmp_tsact058.gd_unit_cd, tmp_tsact058.req_cnt_qty,
            tmp_tsact058.est_sale_at,
            tmp_tsact058.req_cnt_qty * tmp_tsact058.est_sale_at,
            0, 0, '', 0, 0, 0, 0, 0, '', 'I', 'N',
            'SYSTEM', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP,
            NULL
        );

    END LOOP;

    COMMIT;
    p_result_cd := 0;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_result_cd := -2;
        -- Error handling
END;
$$;
