CREATE OR REPLACE PROCEDURE fwsafs.sp_sa_tsact011(
    IN p_pur_req_no VARCHAR(255),
    OUT p_result_cd INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    -- 구매요청 정보 I/F 변수
    v_est_sales_at NUMERIC(13, 0) := 0;  -- 예상 매출 금액
    v_est_sales_prft_at NUMERIC(13, 0) := 0;  -- 예상 매출 이익 금액
    v_est_sales_prft_rt NUMERIC(5, 2) := 0;  -- 예상 매출 이익 율
    v_req_title_txt VARCHAR(100) := '';  -- 요청 제목
    v_rprs_cust_yn CHAR(1) := '';  -- 로그 출력 여부
    n_count INTEGER := 0;  -- 데이터 존재유무 저장 변수
    v_sql_code INTEGER := 0;  -- SQL 수행 결과값 저장 변수
    v_sql_msg VARCHAR(200);  -- sql message
    v_log_on CHAR(1) := 'Y';  -- 로그 출력 여부
    v_buy_est_ym DATE;
    tmp_tsact058 TSACT058%ROWTYPE;
    v_timestamp TIMESTAMP;
    -- CURSOR 선언
    cur1 CURSOR FOR
        SELECT a.*
        FROM TSACT058 a
        WHERE 1 = 1
          -- AND a.REQ_YMD > TO_CHAR(SYSDATE-30,'YYYYMMDD')  -- 30일 이내 데이터
          -- AND a.STTL_STTS_CD = '3'  -- 결재처리 상태가 승인 건만
          AND NOT EXISTS (SELECT 1
                          FROM TISACT010 b
                          WHERE b.co_id = a.co_id
                            AND b.pur_req_no = a.req_no)  -- I/F 데이터로 넘기지 않은 데이터
          AND a.req_no = p_pur_req_no
          AND (a.req_no LIKE 'Q%' OR a.req_no LIKE 'T%')
        ORDER BY a.co_id, a.req_no;
BEGIN
    p_result_cd := 0;
    -- timestamp 생성
    v_timestamp := current_timestamp;
    -- cursor open
    OPEN cur1;
    -- fetch data
    LOOP
        FETCH cur1 INTO tmp_tsact058;
        EXIT WHEN NOT FOUND;
        -- 1.구매요청 마스터 I/F 테이블을 생성한다.
        BEGIN
            IF tmp_tsact058.req_div_cd = '11' THEN
                v_req_title_txt := '수발주 연결요청';
            ELSIF tmp_tsact058.req_div_cd = '12' THEN
                v_req_title_txt := '저장품 수급요청(한우/한돈/수입육) 요청';
            ELSIF tmp_tsact058.req_div_cd = '13' THEN
                v_req_title_txt := '저장품 수급요청(기타) ';
            END IF;
            INSERT INTO TISACT010 (
                co_id, pur_req_no, snd_dt, req_titl_txt, req_tgt_txt, buy_est_ymd,
                rmk_txt, pur_cl_cd, slbz_emp_no, rel_cst_rt, sttl_stts_cd, pur_cnfr_no,
                aply_div_cd, int_aply_cpl_yn, regr_id, reg_dt, updr_id, upd_dt, err_msg
            ) VALUES (
                tmp_tsact058.co_id, tmp_tsact058.req_no, v_timestamp, v_req_title_txt,
                '', tmp_tsact058.buy_est_ymd, tmp_tsact058.req_rsn_txt, tmp_tsact058.req_div_cd,
                tmp_tsact058.slbz_emp_no, 0, tmp_tsact058.ack_stts_cd, '', 'I', 'N',
                'SYSTEM', current_timestamp, 'SYSTEM', current_timestamp, null
            );
        EXCEPTION
            WHEN OTHERS THEN
                v_sql_msg := '[ TISACT010 INSERT Error ]' || ':[' || SQLERRM || ']';
                p_result_cd := -1;
                CLOSE cur1;
                ROLLBACK;
                RETURN;
        END;
        -- 2.구매요청 상품 I/F 협력사 테이블을 생성한다.
        BEGIN
            INSERT INTO TISACT011 (
                co_id, pur_req_no, pur_req_seq, gd_no, snd_dt, ctr_cd, gd_unit_cd,
                pur_req_tot_qty, pur_req_unprc, buy_tot_at, est_sales_at, est_sales_prft_rt,
                bcnr_id, strg_wh_cd, dlv_req_ymd, tarf_rt, aply_div_cd, int_aply_cpl_yn,
                regr_id, reg_dt, updr_id, upd_dt, err_msg, nfxat_gd_yn, bas_unit_cd, avg_wt, cvt_unit_qty
            ) SELECT
                tmp_tsact058.co_id, tmp_tsact058.req_no, '10', tmp_tsact058.gd_no, v_timestamp,
                tmp_tsact058.lgs_ctr_id, tmp_tsact058.gd_unit_cd, tmp_tsact058.req_cnt_qty, 0, 0, 0, 0,
                tmp_tsact058.bcnr_id, '', tmp_tsact058.buy_est_ymd, 0, 'I', 'N',
                'SYSTEM', current_timestamp, 'SYSTEM', current_timestamp, null,
                b.nfxat_gd_yn, b.bas_unit_cd, b.avg_wt, COALESCE(a.req_cnt_qty, 0) * COALESCE(b.avg_wt, 0)
            FROM TSACT058 a
            LEFT JOIN TCBCM009 b ON a.co_id = b.co_id AND a.gd_no = b.gd_no
            WHERE a.co_id = tmp_tsact058.co_id AND a.req_no = tmp_tsact058.req_no;
        EXCEPTION
            WHEN OTHERS THEN
                v_sql_msg := '[ TISACT011 INSERT Error ]' || ':[' || SQLERRM || ']';
                p_result_cd := -1;
                CLOSE cur1;
                ROLLBACK;
                RETURN;
        END;
        -- 3.구매요청 판매 I/F 테이블을 생성한다.
        BEGIN
            INSERT INTO TISACT013 (
                co_id, pur_req_no, pur_req_seq, snd_dt, cust_id, gd_no, sale_unit_cd,
                sale_qty, sale_prc, est_sales_at, est_sales_prft_at, est_prft_rt,
                sale_est_ymd, pur_prx_fee, aply_irt_rt, rlstk_prft_rt, p