PROMPT CREATE PROCEDURE FWSAFS.SP_SA_TSACT011 CREATED : [20150819 110011] LAST_DDL_TIME : [20181011 211654] ( FWSAFS.SP_SA_TSACT011)
PROMPT CREATED : [20150819 110011]
PROMPT LAST_DDL_TIME : [20181011 211654]
PROMPT TOBe object : [FWSAFS.SP_SA_TSACT011]
PROMPT 수집시간 :  [20211116150801]

CREATE OR REPLACE PROCEDURE "FWSAFS"."SP_SA_TSACT011" (
    --     P_IF_ID        IN     VARCHAR2    -- 인터페이스 ID
         P_PUR_REQ_NO    IN     VARCHAR2    --  구매요청번호
        ,P_RESULT_CD    OUT    INTEGER )    -- 에러 코드 )
IS
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
    E_PROC_SUCCESS                 EXCEPTION;
    E_PROC_ZERO_COUNT              EXCEPTION;
    E_PROC_FAILURE                 EXCEPTION;
    T_error                        EXCEPTION;


    ----------------------------------------------------
    -- 구매요청  정보 I/F 변수
    ----------------------------------------------------

    v_est_sales_at      NUMBER(13)  := 0;    -- 예상 매출 금액
    v_est_sales_prft_at NUMBER(13)  := 0;    -- 예상 매출 이익 금액
    v_est_sales_prft_rt NUMBER(5,2) := 0;    -- 예상 매출 이익 율

    v_req_title_txt     VARCHAR2(100) := '';  -- 요청 제목

    v_rprs_cust_yn      CHAR(1)    := '';    -- 로그 출력 여부
    n_count             NUMBER := 0;         -- 데이터 존재유무 저장 변수
    v_sql_code          NUMBER := 0;         -- SQL 수행 결과값 저장 변수
    v_sql_msg           VARCHAR2(200);       -- sql message
    v_log_on            CHAR(1)    := 'Y';   -- 로그 출력 여부

    v_buy_est_ym        DATE;

    tmp_tsact058 TSACT058%ROWTYPE;

    v_timestamp         TIMESTAMP;

    ----------------------------------------------------
    -- CURSOR 선언
    ----------------------------------------------------
    CURSOR CUR1 IS
       SELECT a.*
         FROM TSACT058 a
        WHERE 1 = 1
       -- AND a.REQ_YMD > TO_CHAR(SYSDATE-30,'YYYYMMDD')  -- 30일 이내 데이터
       -- AND a.STTL_STTS_CD = '3'                            -- 결재처리 상태가 승인 건만
          AND NOT EXISTS (SELECT b.*
                            FROM TISACT010 b
                           WHERE b.CO_ID = a.CO_ID
                             AND b.PUR_REQ_NO = a.REQ_NO ) -- I/F 데이터로 넘기지 않은 데이터
         AND a.REQ_NO = P_PUR_REQ_NO
         AND (a.REQ_NO LIKE 'Q%' OR a.REQ_NO LIKE 'T%')
        ORDER BY a.CO_ID, a.REQ_NO
      ;

BEGIN

    P_RESULT_CD := 0;

    ----------------------------------------------------
    -- timestamp 생성
    ----------------------------------------------------
    SELECT SYSTIMESTAMP
      INTO v_timestamp
      FROM DUAL ;

    ----------------------------------------------------
    -- cursor open
    ----------------------------------------------------
    OPEN CUR1;
/* 20151124 DBMS_OUTPUT 주석처리
    IF v_log_on = 'Y' THEN
           DBMS_OUTPUT.PUT_LINE('CUR1 OPEN SUCESS!!');
    END IF
    ;
*/


    ----------------------------------------------------
    -- fetch data
    ----------------------------------------------------
    LOOP
        FETCH CUR1 INTO tmp_tsact058
           ;

        EXIT   WHEN CUR1%NOTFOUND;
/* 20151124 DBMS_OUTPUT 주석처리
        IF v_log_on = 'Y' THEN
                  DBMS_OUTPUT.PUT_LINE('CUR1 FETCH SUCESS!!');
        END IF ;
*/
         --------------------------------------------------------

        --------------------------------------------------------------------------
        -- 1.구매요청 마스터 I/F 테이블을 생성한다.
        --------------------------------------------------------------------------
        BEGIN
            IF tmp_tsact058.REQ_DIV_CD = '11' THEN
                v_req_title_txt := '수발주 연결요청';
            ELSIF tmp_tsact058.REQ_DIV_CD = '12' THEN
                v_req_title_txt := '저장품 수급요청(한우/한돈/수입육) 요청';
            ELSIF tmp_tsact058.REQ_DIV_CD = '13' THEN
                v_req_title_txt := '저장품 수급요청(기타) ';
            END IF;

            INSERT INTO TISACT010 (
                      CO_ID         -- 회사 ID
                    , PUR_REQ_NO    -- 구매 요청 번호
                    , SND_DT        -- 전송 일시
                    , REQ_TITL_TXT  -- 요청 제목 내용
                    , REQ_TGT_TXT   -- 요청 목적 내용
                    , BUY_EST_YMD   -- 매입 예상 일자
                    , RMK_TXT       -- 비고 내용
                    , PUR_CL_CD     -- 구매 유형 코드
                    , SLBZ_EMP_NO   -- 영업 사원 번호
                    , REL_CST_RT    -- 관련 비용 율
                    , STTL_STTS_CD  -- 결제 상태 코드
                    , PUR_CNFR_NO   -- 구매 품의 번호
                    , APLY_DIV_CD   -- 적용 구분 코드
                    , INT_APLY_CPL_YN  -- 내부적용완료여부
                    , REGR_ID       -- 등록자 ID
                    , REG_DT        -- 등록 일시
                    , UPDR_ID       -- 수정자 ID
                    , UPD_DT        -- 수정 일시
                    , ERR_MSG       --오류 메시지
                  )
                  VALUES (
                      tmp_tsact058.CO_ID         -- 회사 ID
                    , tmp_tsact058.REQ_NO        -- 요청 번호
                    , v_timestamp                -- 전송 일시
                    , v_req_title_txt            -- 요청 제목 내용
                    , ''                         -- 요청 목적 내용
                    , tmp_tsact058.BUY_EST_YMD   -- 매입 예상 일자
                    , tmp_tsact058.REQ_RSN_TXT   -- 요청 사유 내용
                 --   , tmp_tsact058.PUR_CL_CD     -- 구매 유형 코드
                    , tmp_tsact058.REQ_DIV_CD
                    , tmp_tsact058.SLBZ_EMP_NO   -- 영업 사원 번호
                    , 0                          -- 관련 비용 율
                    , tmp_tsact058.ACK_STTS_CD   -- 승인 상태 코드
                    , ''                         -- 구매 품의 번호
                    , 'I'                        -- 적용 구분 코드
                    , 'N'                        -- 내부적용완료여부
                    , 'SYSTEM'                   -- 등록자 ID
                    , SYSDATE                    -- 등록 일시
                    , 'SYSTEM'                   -- 수정자 ID
                    , SYSDATE                    -- 수정 일시
                    , null                       --오류 메시지
                  );

                  EXCEPTION
                      WHEN E_PROC_FAILURE THEN
/* 20151124 DBMS_OUTPUT 주석처리
                           IF v_log_on = 'Y' THEN
                              DBMS_OUTPUT.PUT_LINE('REQ_NO  ==>' || tmp_tsact058.REQ_NO);
                           END IF ;
*/
                           v_sql_msg := '[ TISACT010 INSERT Error ]'||':['|| TO_CHAR(SQLCODE) ||']' ||':['|| TO_CHAR(SQLERRM) ||']';
/* 20151124 DBMS_OUTPUT 주석처리
                           DBMS_OUTPUT.PUT_LINE('Error Msg : ' || v_sql_msg);
*/

                           RAISE E_PROC_FAILURE;
                      WHEN OTHERS THEN
/* 20151124 DBMS_OUTPUT 주석처리
                           IF v_log_on = 'Y' THEN
                              DBMS_OUTPUT.PUT_LINE('REQ_NO  ==>' || tmp_tsact058.REQ_NO);
                           END IF ;
*/
                           v_sql_msg := '[ TISACT010 INSERT Error ]'||':['|| TO_CHAR(SQLCODE) ||']' ||':['|| TO_CHAR(SQLERRM) ||']';
/* 20151124 DBMS_OUTPUT 주석처리
                           DBMS_OUTPUT.PUT_LINE('Error Msg : ' || v_sql_msg);
*/
                            RAISE E_PROC_FAILURE ;

        END ;

        --------------------------------------------------------------------------
        -- 2.구매요청 상품 I/F 협력사 테이블을 생성한다.
        --------------------------------------------------------------------------
        BEGIN

            INSERT INTO TISACT011 (
                     CO_ID             --회사 ID
                    ,PUR_REQ_NO        --구매 요청 번호
                    ,PUR_REQ_SEQ       --구매 요청 일련번호
                    ,GD_NO             --상품 번호
                    ,SND_DT            --전송일시
                    ,CTR_CD            --센터 코드
                    ,GD_UNIT_CD        --상품 단위 코드
                    ,PUR_REQ_TOT_QTY   --구매 요청 총 량
                    ,PUR_REQ_UNPRC     --구매 요청 단가
                    ,BUY_TOT_AT        --매입 총 금액
                    ,EST_SALES_AT      --예상 매출 금액
                    ,EST_SALES_PRFT_RT --예상 매출 이익 율
                    ,BCNR_ID           --협력사 ID
                    ,STRG_WH_CD        --보관 창고 코드
                    ,DLV_REQ_YMD       --납품 요청 일자
                    ,TARF_RT           --관세 율
                    ,APLY_DIV_CD       --적용 구분 코드
                    ,INT_APLY_CPL_YN   -- 내부적용완료여부
                    ,REGR_ID           --등록자 ID
                    ,REG_DT            --등록 일시
                    ,UPDR_ID           --수정자 ID
                    ,UPD_DT            --수정 일시
                    ,ERR_MSG           --오류 메시지

                    ,NFXAT_GD_YN       -- 비정량 상품여부
                    ,BAS_UNIT_CD       -- 기본단위코드
                    ,AVG_WT            -- 평균중량 (표준중량)
                    ,CVT_UNIT_QTY      -- 환산단위 수량
                  )
                SELECT
                    tmp_tsact058.CO_ID            --회사 ID
                    , tmp_tsact058.REQ_NO           --구매 요청 번호
                    , '10'                          --구매 요청 일련번호
                    , tmp_tsact058.GD_NO            --상품 번호
                    , v_timestamp                   --전송일시
                    , tmp_tsact058.LGS_CTR_ID       --물류 센터 ID
                    , tmp_tsact058.GD_UNIT_CD       --상품 단위 코드
                    , tmp_tsact058.REQ_CNT_QTY      --요청 수량
                    , 0                             --구매 요청 단가
                    , 0                             --매입 총 금액
                    , 0                             --예상 매출 금액
                    , 0                             --예상 매출 이익 율
                    , tmp_tsact058.BCNR_ID          --협력사 ID
                    , ''                            --보관 창고 코드
                    , tmp_tsact058.BUY_EST_YMD      --납품 요청 일자
                    , 0                            --관세 율
                    , 'I'                          --적용 구분 코드
                    , 'N'                          --내부적용완료여부
                    , 'SYSTEM'                     --등록자 ID
                    , SYSDATE                      --등록 일시
                    , 'SYSTEM'                     --수정자 ID
                    , SYSDATE                      --수정 일시
                    , null                         --오류 메시지

                    , B.NFXAT_GD_YN  /* 비정량 상품여부 */
                    , B.BAS_UNIT_CD  /* 기본 단위 코드 */
                    , B.AVG_WT       /* 평균중량 */
                    , NVL(A.REQ_CNT_QTY,0) * NVL(B.AVG_WT,0) as CVT_UNIT_QTY /* 환산단위 수량 */
                FROM TSACT058 A
                LEFT OUTER JOIN TCBCM009 B
                ON  A.CO_ID = B.CO_ID
                AND A.GD_NO = B.GD_NO
                WHERE A.CO_ID   = tmp_tsact058.CO_ID
                AND   A.REQ_NO  = tmp_tsact058.REQ_NO;
                  /*
                  VALUES (
                     tmp_tsact058.CO_ID            --회사 ID
                    ,tmp_tsact058.REQ_NO           --구매 요청 번호
                    ,'10'                          --구매 요청 일련번호
                    ,tmp_tsact058.GD_NO            --상품 번호
                    ,v_timestamp                   --전송일시
                    ,tmp_tsact058.LGS_CTR_ID       --물류 센터 ID
                    ,tmp_tsact058.GD_UNIT_CD       --상품 단위 코드
                    ,tmp_tsact058.REQ_CNT_QTY      --요청 수량
                    ,0                             --구매 요청 단가
                    ,0                             --매입 총 금액
                    ,0                             --예상 매출 금액
                    ,0                             --예상 매출 이익 율
                    ,tmp_tsact058.BCNR_ID          --협력사 ID
                    ,''                            --보관 창고 코드
                    ,tmp_tsact058.BUY_EST_YMD      --납품 요청 일자
                    , 0                            --관세 율
                    , 'N'                          --적용 구분 코드
                    , 'N'                          --내부적용완료여부
                    , 'SYSTEM'                     --등록자 ID
                    , SYSDATE                      --등록 일시
                    , 'SYSTEM'                     --수정자 ID
                    , SYSDATE                      --수정 일시
                    , null                         --오류 메시지
                    , (SELECT NFXAT_GD_YN
                        FROM TCBCM009
                        WHERE CO_ID = tmp_tsact058.CO_ID
                        AND GD_NO = tmp_tsact058.GD_NO )                    -- 비정량 상품여부
                    , (SELECT BAS_UNIT_CD
                        FROM TCBCM009
                        WHERE CO_ID = tmp_tsact058.CO_ID
                        AND GD_NO = tmp_tsact058.GD_NO )                           -- 기본단위코드
                    , (SELECT AVG_WT
                        FROM TCBCM009
                        WHERE CO_ID = tmp_tsact058.CO_ID
                        AND GD_NO = tmp_tsact058.GD_NO )                            -- 평균중량 (표준중량)
                    , (SELECT NVL(tmp_tsact058.REQ_CNT_QTY,0) * NVL(AVG_WT,0)
                        FROM TCBCM009
                        WHERE CO_ID = tmp_tsact058.CO_ID
                        AND GD_NO   = tmp_tsact058.GD_NO )                            -- 환산단위 수량
                  );
                  */

                  EXCEPTION
                      WHEN E_PROC_FAILURE THEN
/* 20151124 DBMS_OUTPUT 주석처리
                           IF v_log_on = 'Y' THEN
                              DBMS_OUTPUT.PUT_LINE('REQ_NO  ==>' || tmp_tsact058.REQ_NO);
                           END IF ;
*/
                           v_sql_msg := '[ TISACT011 INSERT Error ]'||':['|| TO_CHAR(SQLCODE) ||']' ||':['|| TO_CHAR(SQLERRM) ||']';
/* 20151124 DBMS_OUTPUT 주석처리
                           DBMS_OUTPUT.PUT_LINE('Error Msg : ' || v_sql_msg);
*/
                           RAISE E_PROC_FAILURE;
                      WHEN OTHERS THEN
/* 20151124 DBMS_OUTPUT 주석처리
                           IF v_log_on = 'Y' THEN
                              DBMS_OUTPUT.PUT_LINE('REQ_NO  ==>' || tmp_tsact058.REQ_NO);
                           END IF ;
*/
                           v_sql_msg := '[ TISACT011 INSERT Error ]'||':['|| TO_CHAR(SQLCODE) ||']' ||':['|| TO_CHAR(SQLERRM) ||']';
/* 20151124 DBMS_OUTPUT 주석처리
                           DBMS_OUTPUT.PUT_LINE('Error Msg : ' || v_sql_msg);
*/
                            RAISE E_PROC_FAILURE ;

        END ;

        --------------------------------------------------------------------------
        -- 3.구매요청 판매 I/F 테이블을 생성한다.
        --------------------------------------------------------------------------
        BEGIN
            INSERT INTO TISACT013 (
                     CO_ID            --회사 ID
                    ,PUR_REQ_NO       --구매 요청 번호
                    ,PUR_REQ_SEQ      --구매 요청 일련번호
                    ,SND_DT           --전송 일시
                    ,CUST_ID          --고객 ID
                    ,GD_NO            --상품 번호
                    ,SALE_UNIT_CD     --판매 단위 코드
                    ,SALE_QTY         --판매 량
                    ,SALE_PRC         --판매 가
                    ,EST_SALES_AT     --예상 매출 금액
                    ,EST_SALES_PRFT_AT --예상 매출 이익 율
                    ,EST_PRFT_RT      --예상 이익 율
                    ,SALE_EST_YMD     --판매 예상 일자
                    ,PUR_PRX_FEE      --구매 대행 수수료
                    ,APLY_IRT_RT      --적용 금리
                    ,RLSTK_PRFT_RT    --출고증 이익 율
                    ,PPYD_RT          --선수금 율
                    ,EXI_PPYD_AT      --기존 선수금 금액
                    ,RPRS_CUST_YN     --대표 고객 여부
                    ,APLY_DIV_CD      --적용 구분 코드
                    ,INT_APLY_CPL_YN  -- 내부적용완료여부
                    ,REGR_ID          --등록자 ID
                    ,REG_DT           --등록 일시
                    ,UPDR_ID          --수정자 ID
                    ,UPD_DT           --수정 일시
                    ,ERR_MSG          --오류 메시지
                  )
                  VALUES (
                     tmp_tsact058.CO_ID            --회사 ID
                    ,tmp_tsact058.REQ_NO           --구매 요청 번호
                    ,'10'                          --구매 요청 일련번호
                    ,v_timestamp                   --전송 일시
                    ,tmp_tsact058.SLST_ID          --고객 ID
                    ,tmp_tsact058.GD_NO            --상품 번호
                    ,tmp_tsact058.GD_UNIT_CD       --상품 단위 코드
                    ,tmp_tsact058.REQ_CNT_QTY      --판매 량
                    ,tmp_tsact058.EST_SALE_AT      --판매 가
                    ,tmp_tsact058.REQ_CNT_QTY * tmp_tsact058.EST_SALE_AT --예상 매출 금액
                    , 0                            --예상 매출 이익 금액
                    , 0                            --예상 이익 율
                    , ''                           --판매 예상 일자
                    , 0                            --구매 대행 수수료
                    , 0                            --적용 금리
                    , 0   --출고증 이익 율 (계약 이익 율)
                    , 0        --선수금 율
                    , 0                       --기존 선수금 금액
                    , ''                  --대표 고객 여부
                    , 'I'                -- 적용 구분 코드
                    , 'N'                -- 내부적용완료여부
                    , 'SYSTEM'           -- 등록자 ID
                    , SYSDATE            -- 등록 일시
                    , 'SYSTEM'           -- 수정자 ID
                    , SYSDATE            -- 수정 일시
                    , null               --오류 메시지
                  );

                  EXCEPTION
                      WHEN E_PROC_FAILURE THEN
/* 20151124 DBMS_OUTPUT 주석처리
                           IF v_log_on = 'Y' THEN
                              DBMS_OUTPUT.PUT_LINE('REQ_NO  ==>' || tmp_tsact058.REQ_NO);
                           END IF ;
*/
                           v_sql_msg := '[ TISACT013 INSERT Error ]'||':['|| TO_CHAR(SQLCODE) ||']' ||':['|| TO_CHAR(SQLERRM) ||']';
/* 20151124 DBMS_OUTPUT 주석처리
                           DBMS_OUTPUT.PUT_LINE('Error Msg : ' || v_sql_msg);
*/
                           RAISE E_PROC_FAILURE;
                      WHEN OTHERS THEN
/* 20151124 DBMS_OUTPUT 주석처리
                           IF v_log_on = 'Y' THEN
                              DBMS_OUTPUT.PUT_LINE('REQ_NO  ==>' || tmp_tsact058.REQ_NO);
                           END IF ;
*/
                           v_sql_msg := '[ TISACT013 INSERT Error ]'||':['|| TO_CHAR(SQLCODE) ||']' ||':['|| TO_CHAR(SQLERRM) ||']';
/* 20151124 DBMS_OUTPUT 주석처리
                           DBMS_OUTPUT.PUT_LINE('Error Msg : ' || v_sql_msg);
*/
                            RAISE E_PROC_FAILURE ;
        END ;

        COMMIT;
      END LOOP;

      CLOSE CUR1;

      P_RESULT_CD := 0;

      RAISE E_PROC_SUCCESS;

      EXCEPTION
           WHEN E_PROC_SUCCESS THEN     -- 처리완료 USER EXCEPTION
               -- PUT_BATCH_LOG(S_CO_ID, S_BTCH_EXE_YMD, S_BTCH_BZ_CD, S_BTCH_PGM_ID, S_BTCH_PGM_NM||'(종료)', 'E', 'C', S_PRS_MTD_TXT, '정상종료', S_PRSR_ID );
               P_RESULT_CD := 0;

                COMMIT;
                RETURN;
           WHEN E_PROC_FAILURE THEN
                ROLLBACK ;
/* 20151124 DBMS_OUTPUT 주석처리
                DBMS_OUTPUT.PUT_LINE('SQLCODE = ' || TO_CHAR(SQLCODE));
                DBMS_OUTPUT.PUT_LINE('SQLCODE = ' || '1 '||SQLERRM);
*/
                P_RESULT_CD := -1;
                --PUT_BATCH_LOG(S_CO_ID, S_BTCH_EXE_YMD, S_BTCH_BZ_CD, S_BTCH_PGM_ID, S_BTCH_PGM_NM, 'E', 'R', S_PRS_MTD_TXT,  SUBSTR(pis_msge, 1, 500), S_PRSR_ID );
                RETURN;
           WHEN OTHERS THEN
                ROLLBACK ;
/* 20151124 DBMS_OUTPUT 주석처리
                DBMS_OUTPUT.PUT_LINE('SQLCODE = ' || TO_CHAR(SQLCODE));
                DBMS_OUTPUT.PUT_LINE('SQLCODE = ' || '2 '||SQLERRM);
*/
                P_RESULT_CD := -2;
                --PUT_BATCH_LOG(S_CO_ID, S_BTCH_EXE_YMD, S_BTCH_BZ_CD, S_BTCH_PGM_ID, S_BTCH_PGM_NM, 'E', 'R', S_PRS_MTD_TXT,  SUBSTR('['||SQLCODE||']'||SQLERRM, 1, 500), S_PRSR_ID );
                RETURN;

END SP_SA_TSACT011;
/

