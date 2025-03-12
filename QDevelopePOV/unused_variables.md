# Unused Variables in SP_SA_TSACT011

The following variables in the stored procedure SP_SA_TSACT011 are unused and can be safely commented out:

## Variables to Comment Out

1. `v_est_sales_at NUMBER(13) := 0;`
   - Declared as "예상 매출 금액" (expected sales amount)
   - This variable is never used in any calculations or assignments
   - All sales calculations use direct values or other variables

2. `v_est_sales_prft_at NUMBER(13) := 0;`
   - Declared as "예상 매출 이익 금액" (expected sales profit amount)
   - Not used in any profit calculations or assignments
   - Profit calculations use other variables or direct values

3. `v_est_sales_prft_rt NUMBER(5,2) := 0;`
   - Declared as "예상 매출 이익 율" (expected sales profit rate)
   - Not used in any rate calculations
   - Rate calculations use other variables or direct values

4. `v_rprs_cust_yn CHAR(1) := '';`
   - Declared as "로그 출력 여부" (log output flag)
   - Never used in the procedure
   - Other logging controls are handled differently

5. `v_sql_msg VARCHAR2(200);`
   - Declared as "sql message"
   - Never used for error handling
   - Error handling uses SQLERRM directly instead (as seen in lines 434, 443)

## Recommendation

These variables can be safely commented out as they are not used in any:
- Assignments
- Calculations
- Conditional statements
- Return values
- Output parameters

When commenting out these variables, maintain the original comments for documentation purposes and add a note indicating they were removed due to being unused.