CREATE OR REPLACE FUNCTION SP_SA_TSACT011(
    P_PUR_REQ_NO VARCHAR,  -- 구매 요청 번호
    OUT P_RESULT_CD INTEGER  -- 결과 코드 (OUT 파라미터)
) 
LANGUAGE plpgsql 
AS $$
DECLARE
    v_est_sales_at      NUMERIC(13)  := 0;   -- 예상 매출 금액
    v_est_sales_prft_at NUMERIC(13)  := 0;   -- 예상 매출 이익 금액
    v_est_sales_prft_rt NUMERIC(5,2) := 0;   -- 예상 매출 이익 율
    v_req_title_txt     VARCHAR(100) := '';  -- 요청 제목
    v_rprs_cust_yn      CHAR(1)    := '';    -- 로그 출력 여부
    n_count             INTEGER := 0;        -- 데이터 존재 유무 저장 변수
    v_sql_code          INTEGER := 0;        -- SQL 수행 결과값 저장 변수
    v_sql_msg           VARCHAR(200);        -- SQL 메시지
    v_log_on            CHAR(1)    := 'Y';   -- 로그 출력 여부
    v_buy_est_ym        DATE;
    v_timestamp         TIMESTAMP;

    -- TSACT058 레코드 타입 변수 (ROWTYPE 대체)
    tmp_tsact058 RECORD;

    -- CURSOR 선언
    CUR1 CURSOR FOR 
        SELECT * 
        FROM TSACT058 
        WHERE REQ_NO = P_PUR_REQ_NO 
          AND (REQ_NO LIKE 'Q%' OR REQ_NO LIKE 'T%')
          AND NOT EXISTS (
              SELECT 1 FROM TISACT010 
              WHERE TISACT010.CO_ID = TSACT058.CO_ID 
                AND TISACT010.PUR_REQ_NO = TSACT058.REQ_NO
          )
        ORDER BY CO_ID, REQ_NO;

BEGIN
    -- 기본 반환 값 초기화
    P_RESULT_CD := 0;

    -- timestamp 생성
    SELECT NOW() INTO v_timestamp;

    -- Cursor 열기
    OPEN CUR1;

    -- 데이터 Fetch Loop
    LOOP
        FETCH CUR1 INTO tmp_tsact058;
        EXIT WHEN NOT FOUND;

        -- 구매 요청 제목 설정
        IF tmp_tsact058.REQ_DIV_CD = '11' THEN
            v_req_title_txt := '수발주 연결요청';
        ELSIF tmp_tsact058.REQ_DIV_CD = '12' THEN
            v_req_title_txt := '저장품 수급요청(한우/한돈/수입육) 요청';
        ELSIF tmp_tsact058.REQ_DIV_CD = '13' THEN
            v_req_title_txt := '저장품 수급요청(기타)';
        END IF;

        -- 1. 구매요청 마스터 I/F 테이블 INSERT
        BEGIN
            INSERT INTO TISACT010 (
                CO_ID, PUR_REQ_NO, SND_DT, REQ_TITL_TXT, REQ_TGT_TXT, BUY_EST_YMD, 
                RMK_TXT, PUR_CL_CD, SLBZ_EMP_NO, REL_CST_RT, STTL_STTS_CD, 
                PUR_CNFR_NO, APLY_DIV_CD, INT_APLY_CPL_YN, REGR_ID, REG_DT, UPDR_ID, UPD_DT, ERR_MSG
            ) VALUES (
                tmp_tsact058.CO_ID, tmp_tsact058.REQ_NO, v_timestamp, v_req_title_txt, '', 
                tmp_tsact058.BUY_EST_YMD, tmp_tsact058.REQ_RSN_TXT, tmp_tsact058.REQ_DIV_CD, 
                tmp_tsact058.SLBZ_EMP_NO, 0, tmp_tsact058.ACK_STTS_CD, '', 
                'I', 'N', 'SYSTEM', NOW(), 'SYSTEM', NOW(), NULL
            );

        EXCEPTION
            WHEN OTHERS THEN
                v_sql_msg := '[TISACT010 INSERT Error] [' || SQLSTATE || '] ' || SQLERRM;
                RAISE EXCEPTION '%', v_sql_msg;
        END;

        -- 2. 구매요청 상품 I/F 협력사 테이블 INSERT
        BEGIN
            INSERT INTO TISACT011 (
                CO_ID, PUR_REQ_NO, PUR_REQ_SEQ, GD_NO, SND_DT, CTR_CD, GD_UNIT_CD, PUR_REQ_TOT_QTY, 
                PUR_REQ_UNPRC, BUY_TOT_AT, EST_SALES_AT, EST_SALES_PRFT_RT, BCNR_ID, STRG_WH_CD, 
                DLV_REQ_YMD, TARF_RT, APLY_DIV_CD, INT_APLY_CPL_YN, REGR_ID, REG_DT, UPDR_ID, UPD_DT, 
                ERR_MSG, NFXAT_GD_YN, BAS_UNIT_CD, AVG_WT, CVT_UNIT_QTY
            )
            SELECT
                tmp_tsact058.CO_ID, tmp_tsact058.REQ_NO, '10', tmp_tsact058.GD_NO, v_timestamp, 
                tmp_tsact058.LGS_CTR_ID, tmp_tsact058.GD_UNIT_CD, tmp_tsact058.REQ_CNT_QTY, 
                0, 0, 0, 0, tmp_tsact058.BCNR_ID, '', tmp_tsact058.BUY_EST_YMD, 
                0, 'I', 'N', 'SYSTEM', NOW(), 'SYSTEM', NOW(), NULL, 
                B.NFXAT_GD_YN, B.BAS_UNIT_CD, B.AVG_WT, 
                COALESCE(A.REQ_CNT_QTY,0) * COALESCE(B.AVG_WT,0) 
            FROM TSACT058 A
            LEFT JOIN TCBCM009 B
                ON A.CO_ID = B.CO_ID AND A.GD_NO = B.GD_NO
            WHERE A.CO_ID = tmp_tsact058.CO_ID
              AND A.REQ_NO = tmp_tsact058.REQ_NO;

        EXCEPTION
            WHEN OTHERS THEN
                v_sql_msg := '[TISACT011 INSERT Error] [' || SQLSTATE || '] ' || SQLERRM;
                RAISE EXCEPTION '%', v_sql_msg;
        END;

        -- 3. 구매요청 판매 I/F 테이블 INSERT
        BEGIN
            INSERT INTO TISACT013 (
                CO_ID, PUR_REQ_NO, PUR_REQ_SEQ, SND_DT, CUST_ID, GD_NO, SALE_UNIT_CD, 
                SALE_QTY, SALE_PRC, EST_SALES_AT, EST_SALES_PRFT_AT, EST_PRFT_RT, 
                SALE_EST_YMD, PUR_PRX_FEE, APLY_IRT_RT, RLSTK_PRFT_RT, PPYD_RT, 
                EXI_PPYD_AT, RPRS_CUST_YN, APLY_DIV_CD, INT_APLY_CPL_YN, REGR_ID, REG_DT, UPDR_ID, UPD_DT, ERR_MSG
            ) VALUES (
                tmp_tsact058.CO_ID, tmp_tsact058.REQ_NO, '10', v_timestamp, tmp_tsact058.SLST_ID, 
                tmp_tsact058.GD_NO, tmp_tsact058.GD_UNIT_CD, tmp_tsact058.REQ_CNT_QTY, 
                tmp_tsact058.EST_SALE_AT, tmp_tsact058.REQ_CNT_QTY * tmp_tsact058.EST_SALE_AT, 
                0, 0, '', 0, 0, 0, 0, 0, '', 'I', 'N', 'SYSTEM', NOW(), 'SYSTEM', NOW(), NULL
            );

        EXCEPTION
            WHEN OTHERS THEN
                v_sql_msg := '[TISACT013 INSERT Error] [' || SQLSTATE || '] ' || SQLERRM;
                RAISE EXCEPTION '%', v_sql_msg;
        END;

        COMMIT;
    END LOOP;

    CLOSE CUR1;

    -- 성공
    P_RESULT_CD := 0;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        P_RESULT_CD := -1;
END;
$$;
