# Test Queries for SP_SA_TSACT011

## Oracle Test Scripts

```sql
-- Create test table 
CREATE TABLE TSACT058 (
    CO_ID VARCHAR2(10),
    REQ_NO VARCHAR2(20),
    REQ_DIV_CD VARCHAR2(2),
    BUY_EST_YMD DATE,
    REQ_RSN_TXT VARCHAR2(1000),
    SLBZ_EMP_NO VARCHAR2(20),
    ACK_STTS_CD VARCHAR2(2),
    GD_NO VARCHAR2(20),
    LGS_CTR_ID VARCHAR2(10),
    GD_UNIT_CD VARCHAR2(3),
    REQ_CNT_QTY NUMBER,
    BCNR_ID VARCHAR2(10),
    SLST_ID VARCHAR2(10),
    EST_SALE_AT NUMBER
);

-- Test data
INSERT INTO TSACT058 VALUES (
    'TEST01', 'Q20231201001', '11',
    TO_DATE('2023-12-01', 'YYYY-MM-DD'),
    'Test Request', 'EMP123', '01',
    'GOOD001', 'CTR01', 'EA',
    100, 'SUP01', 'CST01', 5000
);

-- Execute procedure
DECLARE
    v_result NUMBER;
BEGIN
    SP_SA_TSACT011('TEST01', v_result);
    DBMS_OUTPUT.PUT_LINE('Result: ' || v_result);
END;

-- Verify results
SELECT * FROM TISACT010 WHERE co_id = 'TEST01' AND pur_req_no = 'Q20231201001';
SELECT * FROM TISACT011 WHERE co_id = 'TEST01' AND pur_req_no = 'Q20231201001';
SELECT * FROM TISACT013 WHERE co_id = 'TEST01' AND pur_req_no = 'Q20231201001';
```

## PostgreSQL Test Scripts

```sql
-- Create test table
CREATE TABLE tsact058 (
    co_id VARCHAR(10),
    req_no VARCHAR(20),
    req_div_cd VARCHAR(2),
    buy_est_ymd DATE,
    req_rsn_txt VARCHAR(1000),
    slbz_emp_no VARCHAR(20),
    ack_stts_cd VARCHAR(2),
    gd_no VARCHAR(20),
    lgs_ctr_id VARCHAR(10),
    gd_unit_cd VARCHAR(3),
    req_cnt_qty NUMERIC,
    bcnr_id VARCHAR(10),
    slst_id VARCHAR(10),
    est_sale_at NUMERIC
);

-- Test data
INSERT INTO tsact058 VALUES (
    'TEST01', 'Q20231201001', '11',
    '2023-12-01',
    'Test Request', 'EMP123', '01',
    'GOOD001', 'CTR01', 'EA',
    100, 'SUP01', 'CST01', 5000
);

-- Execute procedure
DO $$
DECLARE
    v_result INTEGER;
BEGIN
    CALL sp_sa_tsact011('TEST01', v_result);
    RAISE NOTICE 'Result: %', v_result;
END $$;

-- Verify results
SELECT * FROM tisact010 WHERE co_id = 'TEST01' AND pur_req_no = 'Q20231201001';
SELECT * FROM tisact011 WHERE co_id = 'TEST01' AND pur_req_no = 'Q20231201001';
SELECT * FROM tisact013 WHERE co_id = 'TEST01' AND pur_req_no = 'Q20231201001';
```

## Important Notes

1. The test cases verify:
   - Input data processing from TSACT058
   - Data insertion into TISACT010, TISACT011, and TISACT013
   - Proper handling of timestamps and dates
   - Error code returns

2. Expected behavior:
   - Both procedures should process the test record from TSACT058
   - Insert corresponding records into TISACT010, TISACT011, and TISACT013
   - Return success code (0) if everything works correctly

3. Table Dependencies:
   - Source: TSACT058
   - Target: TISACT010, TISACT011, TISACT013

4. Key differences between Oracle and PostgreSQL versions:
   - Date/timestamp handling syntax
   - Procedure call syntax
   - Output handling (DBMS_OUTPUT vs RAISE NOTICE)
   - Data type names (VARCHAR2 vs VARCHAR, NUMBER vs NUMERIC)