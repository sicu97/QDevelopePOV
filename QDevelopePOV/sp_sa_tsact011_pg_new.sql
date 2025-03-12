-- PROMPT CREATE PROCEDURE FWSAFS.SP_SA_TSACT011 
-- Original Oracle procedure converted to PostgreSQL
-- Original creation/modification dates preserved in comments:
-- CREATED : [20150819 110011]
-- LAST_DDL_TIME : [20181011 211654]
-- 수집시간 :  [20211116150801]

CREATE OR REPLACE PROCEDURE sp_sa_tsact011(
    -- P_IF_ID IN VARCHAR2    -- 인터페이스 ID
    p_pur_req_no VARCHAR,   -- 구매요청번호
    INOUT p_result_cd INTEGER    -- 에러 코드
)
LANGUAGE plpgsql
AS $procedure$
/*===============================================================*
 * MAIN TITLE   :  구매요청 I/F 테이블로 데이트를 생성한다.
 * PROCEDURE ID :  SP_SA_TISA010
 * 일      자   :  2015-07-12
   수      정   :
 * PROGRAMMER   :  이 용 남
 * 비      고   :  1. 구매요청        TSACT058  ==> TISACT010 (구매요청 마스터 I/F 데이터 생성)
 *                 2. 구매요청 상품   TSACT058  ==> TISACT011 (구매요청 상품   I/F 데이터 생성)
                   3. 구매요청 판매   TSACT058  ==> TISACT013 (구매요청 판매   I/F 데이터 생성)
 *=============================================================*/
DECLARE
    ----------------------------------------------------
    -- 구매요청  정보 I/F 변수
    ----------------------------------------------------
    v_est_sales_at      NUMERIC(13) := 0;    -- 예상 매출 금액
    v_est_sales_prft_at NUMERIC(13) := 0;    -- 예상 매출 이익 금액
    v_est_sales_prft_rt NUMERIC(5,2) := 0;   -- 예상 매출 이익 율
    v_req_title_txt     VARCHAR(100) := '';   -- 요청 제목
    v_rprs_cust_yn      CHAR(1) := '';       -- 로그 출력 여부
    n_count             INTEGER := 0;         -- 데이터 존재유무 저장 변수
    v_sql_code          INTEGER := 0;         -- SQL 수행 결과값 저장 변수
    v_sql_msg           VARCHAR(200);         -- sql message
    v_log_on            CHAR(1) := 'Y';       -- 로그 출력 여부
    v_buy_est_ym        DATE;
    v_timestamp         TIMESTAMP;
    tmp_tsact058        tsact058%ROWTYPE;

BEGIN
    -- Initialize result code
    p_result_cd := 0;

    -- Get current timestamp
    v_timestamp := CURRENT_TIMESTAMP;

    -- Main processing loop
    FOR tmp_tsact058 IN 
        SELECT a.*
        FROM tsact058 a
        WHERE 1 = 1
        -- AND a.req_ymd > TO_CHAR(CURRENT_DATE - INTERVAL '30 days', 'YYYYMMDD')
        -- AND a.sttl_stts_cd = '3'
        AND NOT EXISTS (
            SELECT 1 
            FROM tisact010 b
            WHERE b.co_id = a.co_id
            AND b.pur_req_no = a.req_no
        )
        AND a.req_no = p_pur_req_no
        AND (a.req_no LIKE 'Q%' OR a.req_no LIKE 'T%')
        ORDER BY a.co_id, a.req_no
    LOOP
        BEGIN
            -- Insert into TISACT010
            IF tmp_tsact058.req_div_cd = '11' THEN
                INSERT INTO tisact010 (
                    co_id, pur_req_no, snd_dt, req_titl_txt, req_tgt_txt,
                    buy_est_ymd, rmk_txt, pur_cl_cd, slbz_emp_no, rel_cst_rt,
                    sttl_stts_cd, pur_cnfr_no, aply_div_cd, int_aply_cpl_yn,
                    regr_id, reg_dt, updr_id, upd_dt, err_msg
                ) VALUES (
                    tmp_tsact058.co_id,         -- 회사 ID
                    tmp_tsact058.req_no,        -- 요청 번호
                    v_timestamp,                -- 전송 일시
                    v_req_title_txt,            -- 요청 제목 내용
                    '',                         -- 요청 목적 내용
                    tmp_tsact058.buy_est_ymd,   -- 매입 예상 일자
                    tmp_tsact058.req_rsn_txt,   -- 요청 사유 내용
                    tmp_tsact058.req_div_cd,    -- 구매 유형 코드
                    tmp_tsact058.slbz_emp_no,   -- 영업 사원 번호
                    0,                          -- 관련 비용 율
                    tmp_tsact058.ack_stts_cd,   -- 승인 상태 코드
                    '',                         -- 구매 품의 번호
                    'I',                        -- 적용 구분 코드
                    'N',                        -- 내부적용완료여부
                    'SYSTEM',                   -- 등록자 ID
                    CURRENT_TIMESTAMP,          -- 등록 일시
                    'SYSTEM',                   -- 수정자 ID
                    CURRENT_TIMESTAMP,          -- 수정 일시
                    NULL                        -- 오류 메시지
                );
            END IF;

            -- Insert into TISACT011
            INSERT INTO tisact011 (
                co_id, pur_req_no, pur_req_seq, gd_no, snd_dt,
                ctr_cd, gd_unit_cd, pur_req_tot_qty, pur_req_unprc,
                buy_tot_at, est_sales_at, est_sales_prft_rt, bcnr_id,
                strg_wh_cd, dlv_req_ymd, tarf_rt, aply_div_cd, 
                int_aply_cpl_yn, regr_id, reg_dt, updr_id, upd_dt,
                err_msg, nfxat_gd_yn, bas_unit_cd, avg_wt, cvt_unit_qty
            ) VALUES (
                tmp_tsact058.co_id,            -- 회사 ID
                tmp_tsact058.req_no,           -- 구매 요청 번호
                '10',                          -- 구매 요청 일련번호
                tmp_tsact058.gd_no,            -- 상품 번호
                v_timestamp,                   -- 전송일시
                tmp_tsact058.lgs_ctr_id,       -- 센터 코드
                tmp_tsact058.gd_unit_cd,       -- 상품 단위 코드
                tmp_tsact058.req_cnt_qty,      -- 구매 요청 총 량
                0,                             -- 구매 요청 단가
                0,                             -- 매입 총 금액
                0,                             -- 예상 매출 금액
                0,                             -- 예상 매출 이익 율
                tmp_tsact058.bcnr_id,          -- 협력사 ID
                '',                            -- 보관 창고 코드
                tmp_tsact058.buy_est_ymd,      -- 납품 요청 일자
                0,                             -- 관세 율
                'I',                           -- 적용 구분 코드
                'N',                           -- 내부적용완료여부
                'SYSTEM',                      -- 등록자 ID
                CURRENT_TIMESTAMP,             -- 등록 일시
                'SYSTEM',                      -- 수정자 ID
                CURRENT_TIMESTAMP,             -- 수정 일시
                NULL,                          -- 오류 메시지
                'N',                           -- 비정량 상품여부 
                '',                           -- 기본단위코드
                0,                            -- 평균중량
                0                             -- 환산단위 수량
            );

            -- Insert into TISACT013
            INSERT INTO tisact013 (
                co_id, pur_req_no, pur_req_seq, snd_dt,
                cust_id, gd_no, sale_unit_cd, sale_qty,
                sale_prc, est_sales_at, est_sales_prft_at,
                est_prft_rt, sale_est_ymd, pur_prx_fee,
                aply_irt_rt, rlstk_prft_rt, ppyd_rt,
                exi_ppyd_at, rprs_cust_yn, aply_div_cd,
                int_aply_cpl_yn, regr_id, reg_dt,
                updr_id, upd_dt, err_msg
            ) VALUES (
                tmp_tsact058.co_id,            -- 회사 ID
                tmp_tsact058.req_no,           -- 구매 요청 번호
                '10',                          -- 구매 요청 일련번호
                v_timestamp,                   -- 전송 일시
                tmp_tsact058.slst_id,          -- 고객 ID
                tmp_tsact058.gd_no,            -- 상품 번호
                tmp_tsact058.gd_unit_cd,       -- 상품 단위 코드
                tmp_tsact058.req_cnt_qty,      -- 판매 량
                tmp_tsact058.est_sale_at,      -- 판매 가
                tmp_tsact058.req_cnt_qty * tmp_tsact058.est_sale_at, -- 예상 매출 금액
                0,                             -- 예상 매출 이익 금액
                0,                             -- 예상 이익 율
                NULL,                          -- 판매 예상 일자
                0,                             -- 구매 대행 수수료
                0,                             -- 적용 금리
                0,                             -- 출고증 이익 율
                0,                             -- 선수금 율
                0,                             -- 기존 선수금 금액
                '',                            -- 대표 고객 여부
                'I',                           -- 적용 구분 코드
                'N',                           -- 내부적용완료여부
                'SYSTEM',                      -- 등록자 ID
                CURRENT_TIMESTAMP,             -- 등록 일시
                'SYSTEM',                      -- 수정자 ID
                CURRENT_TIMESTAMP,             -- 수정 일시
                NULL                           -- 오류 메시지
            );

        EXCEPTION
            WHEN OTHERS THEN
                -- Handle exceptions
                GET STACKED DIAGNOSTICS 
                    v_sql_code = RETURNED_SQLSTATE,
                    v_sql_msg = MESSAGE_TEXT;
                
                p_result_cd := -1;
                -- Could add error logging here if needed
        END;
    END LOOP;

    RETURN;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS 
            v_sql_code = RETURNED_SQLSTATE,
            v_sql_msg = MESSAGE_TEXT;
        
        p_result_cd := -2;
        -- Could add error logging here if needed
END;
$procedure$;