-- Copyright 2004-2018 H2 Group. Multiple-Licensed under the MPL 2.0,
-- and the EPL 1.0 (http://h2database.com/html/license.html).
-- Initial Developer: H2 Group
--

CREATE TABLE TEST(A INT, B INT, C INT);
> ok

INSERT INTO TEST VALUES (1, 1, 1), (1, 1, 2), (1, 1, 3), (1, 2, 1), (1, 2, 2), (1, 2, 3),
    (2, 1, 1), (2, 1, 2), (2, 1, 3), (2, 2, 1), (2, 2, 2), (2, 2, 3);
> update count: 12

SELECT * FROM TEST ORDER BY A, B;
> A B C
> - - -
> 1 1 1
> 1 1 2
> 1 1 3
> 1 2 1
> 1 2 2
> 1 2 3
> 2 1 1
> 2 1 2
> 2 1 3
> 2 2 1
> 2 2 2
> 2 2 3
> rows (partially ordered): 12

SELECT * FROM TEST ORDER BY A, B, C FETCH FIRST 4 ROWS ONLY;
> A B C
> - - -
> 1 1 1
> 1 1 2
> 1 1 3
> 1 2 1
> rows (ordered): 4

SELECT * FROM TEST ORDER BY A, B, C FETCH FIRST 4 ROWS WITH TIES;
> A B C
> - - -
> 1 1 1
> 1 1 2
> 1 1 3
> 1 2 1
> rows (ordered): 4

SELECT * FROM TEST ORDER BY A, B FETCH FIRST 4 ROWS WITH TIES;
> A B C
> - - -
> 1 1 1
> 1 1 2
> 1 1 3
> 1 2 1
> 1 2 2
> 1 2 3
> rows (partially ordered): 6

SELECT * FROM TEST ORDER BY A FETCH FIRST ROW WITH TIES;
> A B C
> - - -
> 1 1 1
> 1 1 2
> 1 1 3
> 1 2 1
> 1 2 2
> 1 2 3
> rows (partially ordered): 6

SELECT TOP (1) WITH TIES * FROM TEST ORDER BY A;
> A B C
> - - -
> 1 1 1
> 1 1 2
> 1 1 3
> 1 2 1
> 1 2 2
> 1 2 3
> rows (partially ordered): 6

SELECT TOP 1 PERCENT WITH TIES * FROM TEST ORDER BY A;
> A B C
> - - -
> 1 1 1
> 1 1 2
> 1 1 3
> 1 2 1
> 1 2 2
> 1 2 3
> rows (partially ordered): 6

SELECT TOP 51 PERCENT WITH TIES * FROM TEST ORDER BY A, B;
> A B C
> - - -
> 1 1 1
> 1 1 2
> 1 1 3
> 1 2 1
> 1 2 2
> 1 2 3
> 2 1 1
> 2 1 2
> 2 1 3
> rows (partially ordered): 9

SELECT * FROM TEST ORDER BY A, B OFFSET 3 ROWS FETCH NEXT 1 ROW WITH TIES;
> A B C
> - - -
> 1 2 1
> 1 2 2
> 1 2 3
> rows (partially ordered): 3

SELECT * FROM TEST FETCH NEXT ROWS ONLY;
> A B C
> - - -
> 1 1 1
> rows: 1

SELECT * FROM TEST FETCH FIRST 101 PERCENT ROWS ONLY;
> exception INVALID_VALUE_2

SELECT * FROM TEST FETCH FIRST -1 PERCENT ROWS ONLY;
> exception INVALID_VALUE_2

SELECT * FROM TEST FETCH FIRST 0 PERCENT ROWS ONLY;
> A B C
> - - -
> rows: 0

SELECT * FROM TEST FETCH FIRST 1 PERCENT ROWS ONLY;
> A B C
> - - -
> 1 1 1
> rows: 1

SELECT * FROM TEST FETCH FIRST 10 PERCENT ROWS ONLY;
> A B C
> - - -
> 1 1 1
> 1 1 2
> rows: 2

SELECT * FROM TEST OFFSET 2 ROWS FETCH NEXT 10 PERCENT ROWS ONLY;
> A B C
> - - -
> 1 1 3
> 1 2 1
> rows: 2

CREATE INDEX TEST_A_IDX ON TEST(A);
> ok

CREATE INDEX TEST_A_B_IDX ON TEST(A, B);
> ok

SELECT * FROM TEST ORDER BY A FETCH FIRST 1 ROW WITH TIES;
> A B C
> - - -
> 1 1 1
> 1 1 2
> 1 1 3
> 1 2 1
> 1 2 2
> 1 2 3
> rows (partially ordered): 6

SELECT * FROM TEST ORDER BY A, B OFFSET 3 ROWS FETCH NEXT 1 ROW WITH TIES;
> A B C
> - - -
> 1 2 1
> 1 2 2
> 1 2 3
> rows (partially ordered): 3

SELECT * FROM TEST FETCH FIRST 1 ROW WITH TIES;
> exception WITH_TIES_WITHOUT_ORDER_BY

(SELECT * FROM TEST) UNION (SELECT 1, 2, 4) ORDER BY A, B OFFSET 3 ROWS FETCH NEXT 1 ROW WITH TIES;
> A B C
> - - -
> 1 2 1
> 1 2 2
> 1 2 3
> 1 2 4
> rows (partially ordered): 4

(SELECT * FROM TEST) UNION (SELECT 1, 2, 4) ORDER BY A, B OFFSET 3 ROWS FETCH NEXT 50 PERCENT ROWS ONLY;
> A B C
> - - -
> 1 2 1
> 1 2 2
> 1 2 3
> 1 2 4
> 2 1 1
> 2 1 2
> 2 1 3
> rows (partially ordered): 7

(SELECT * FROM TEST) UNION (SELECT 1, 2, 4) ORDER BY A, B OFFSET 3 ROWS FETCH NEXT 40 PERCENT ROWS WITH TIES;
> A B C
> - - -
> 1 2 1
> 1 2 2
> 1 2 3
> 1 2 4
> 2 1 1
> 2 1 2
> 2 1 3
> rows (partially ordered): 7

(SELECT * FROM TEST) UNION (SELECT 1, 2, 4) FETCH NEXT 1 ROW WITH TIES;
> exception WITH_TIES_WITHOUT_ORDER_BY

EXPLAIN SELECT * FROM TEST ORDER BY A, B OFFSET 3 ROWS FETCH NEXT 1 ROW WITH TIES;
>> SELECT TEST.A, TEST.B, TEST.C FROM PUBLIC.TEST /* PUBLIC.TEST_A_B_IDX */ ORDER BY 1, 2 OFFSET 3 ROWS FETCH NEXT ROW WITH TIES /* index sorted */

EXPLAIN SELECT * FROM TEST ORDER BY A, B OFFSET 3 ROWS FETCH NEXT 1 PERCENT ROWS WITH TIES;
>> SELECT TEST.A, TEST.B, TEST.C FROM PUBLIC.TEST /* PUBLIC.TEST_A_B_IDX */ ORDER BY 1, 2 OFFSET 3 ROWS FETCH NEXT 1 PERCENT ROWS WITH TIES /* index sorted */

DROP TABLE TEST;
> ok

CREATE TABLE TEST(A NUMERIC, B NUMERIC);
> ok

INSERT INTO TEST VALUES (0, 1), (0.0, 2), (0, 3), (1, 4);
> update count: 4

SELECT A, B FROM TEST ORDER BY A FETCH FIRST 1 ROW WITH TIES;
> A   B
> --- -
> 0   1
> 0   3
> 0.0 2
> rows (partially ordered): 3

DROP TABLE TEST;
> ok

CREATE TABLE TEST(A INT, B INT);
> ok

INSERT INTO TEST VALUES (1, 1), (1, 2), (2, 1), (2, 2), (2, 3);
> update count: 5

SELECT A, COUNT(B) FROM TEST GROUP BY A OFFSET 1;
> A COUNT(B)
> - --------
> 2 3
> rows: 1

DROP TABLE TEST;
> ok

CREATE TABLE TEST1(A INT, B INT, C INT) AS SELECT 1, 2, 3;
> ok

CREATE TABLE TEST2(A INT, B INT, C INT) AS SELECT 4, 5, 6;
> ok

SELECT A, B FROM TEST1 UNION SELECT A, B FROM TEST2 ORDER BY 1.1;
> exception ORDER_BY_NOT_IN_RESULT

DROP TABLE TEST1;
> ok

DROP TABLE TEST2;
> ok

-- Disallowed mixed OFFSET/FETCH/LIMIT/TOP clauses
CREATE TABLE TEST (ID BIGINT);
> ok

SELECT TOP 1 ID FROM TEST OFFSET 1 ROW;
> exception SYNTAX_ERROR_1

SELECT TOP 1 ID FROM TEST FETCH NEXT ROW ONLY;
> exception SYNTAX_ERROR_1

SELECT TOP 1 ID FROM TEST LIMIT 1;
> exception SYNTAX_ERROR_1

SELECT ID FROM TEST OFFSET 1 ROW LIMIT 1;
> exception SYNTAX_ERROR_1

SELECT ID FROM TEST FETCH NEXT ROW ONLY LIMIT 1;
> exception SYNTAX_ERROR_1

DROP TABLE TEST;
> ok

-- ORDER BY with parameter
CREATE TABLE TEST(A INT, B INT);
> ok

INSERT INTO TEST VALUES (1, 1), (1, 2), (2, 1), (2, 2);
> update count: 4

SELECT * FROM TEST ORDER BY ?, ? FETCH FIRST ROW ONLY;
{
1, 2
> A B
> - -
> 1 1
> rows (ordered): 1
-1, 2
> A B
> - -
> 2 1
> rows (ordered): 1
1, -2
> A B
> - -
> 1 2
> rows (ordered): 1
-1, -2
> A B
> - -
> 2 2
> rows (ordered): 1
2, -1
> A B
> - -
> 2 1
> rows (ordered): 1
}
> update count: 0

DROP TABLE TEST;
> ok

CREATE TABLE TEST1(A INT, B INT, C INT) AS SELECT 1, 2, 3;
> ok

CREATE TABLE TEST2(A INT, D INT) AS SELECT 4, 5;
> ok

SELECT * FROM TEST1, TEST2;
> A B C A D
> - - - - -
> 1 2 3 4 5
> rows: 1

SELECT * EXCEPT (A) FROM TEST1;
> B C
> - -
> 2 3
> rows: 1

SELECT * EXCEPT (TEST1.A) FROM TEST1;
> B C
> - -
> 2 3
> rows: 1

SELECT * EXCEPT (PUBLIC.TEST1.A) FROM TEST1;
> B C
> - -
> 2 3
> rows: 1

SELECT * EXCEPT (SCRIPT.PUBLIC.TEST1.A) FROM TEST1;
> B C
> - -
> 2 3
> rows: 1

SELECT * EXCEPT (Z) FROM TEST1;
> exception COLUMN_NOT_FOUND_1

SELECT * EXCEPT (B, TEST1.B) FROM TEST1;
> exception DUPLICATE_COLUMN_NAME_1

SELECT * EXCEPT (A) FROM TEST1, TEST2;
> exception AMBIGUOUS_COLUMN_NAME_1

SELECT * EXCEPT (TEST1.A, B, TEST2.D) FROM TEST1, TEST2;
> C A
> - -
> 3 4
> rows: 1

SELECT TEST1.*, TEST2.* FROM TEST1, TEST2;
> A B C A D
> - - - - -
> 1 2 3 4 5
> rows: 1

SELECT TEST1.* EXCEPT (A), TEST2.* EXCEPT (A) FROM TEST1, TEST2;
> B C D
> - - -
> 2 3 5
> rows: 1

SELECT TEST1.* EXCEPT (A), TEST2.* EXCEPT (D) FROM TEST1, TEST2;
> B C A
> - - -
> 2 3 4
> rows: 1

SELECT * EXCEPT (T1.A, T2.D) FROM TEST1 T1, TEST2 T2;
> B C A
> - - -
> 2 3 4
> rows: 1

DROP TABLE TEST1, TEST2;
> ok
