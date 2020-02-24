--�������� ��� ����[1]  : �������� ���� ����� ��, Main SQL�� �÷� ���� ���ϴ� ���·� ����
SELECT * FROM  emp WHERE sal > (SELECT avg(sal) FROM emp);

--��� ����[2] : �������� ���� Main SQL���� ���������� �����Ͽ�, Main SQL���� ������ ���� ��ӹ޾� ���������� ���̺� �ش� ���� �����ϴ��� üũ�ϴ� ������� ����ȴ�. ���� �ݴ�� ���������� ���� ����ǰ� Main SQL�� ���� ������ ���� �ִ�.
--���� �������� ���� ���� ���� �߻� ���ɼ� ����. 
SELECT c1, c2, c3
FROM SUBQUERY_2 t1
WHERE c2 = 'A'
AND EXISTS (	
	SELECT  /*+ NO_UNNEST*/
			'X'
	FROM SUBQUERY_T1 t1
	WHERE t1.c5 = t2.c2
)

--�׽�Ʈ[1] : ���������� �⺻���� Ư�� �˾ƺ���
SELECT  /*+ QB_NAME(A) */ coll
FROM (
	SELECT LEVEL coll
	FROM DUAL 
	CONNECT BY LEVEL <= 3
) a
WHERE a.coll IN (
		SELECT /*+ QB_NAME(A) */ coll --1,2,3�� ���� 3���� ���
		FROM (
			SELECT LEVEL coll
			FROM DUAL 
			CONNECT BY LEVEL <= 3
				UNION ALL 
			SELECT LEVEL 
			FROM DUAL 
			CONNECT BY LEVEL <= 3
				UNION ALL 
			SELECT LEVEL 
			FROM DUAL 
			CONNECT BY LEVEL <= 3
		)
	);
-- ������������ ����Ǵ� �����Ͱ� �ߺ� ���� ������ Unique���� ó���ϹǷ�, ���������� �������� �����ϴ� SQL�ۼ��� ���������� �ߺ��� �����ʹ� ���ŵȴ�.


/* ���������� ���۹�� : 1) filter ���۹�� 2) JOIN ���۹��
 * 
--1) filter ���۹�� 
: filter ���۹���� Main SQL���� ����� ������ �Ǽ���ŭ ���������� �ݺ������� ����Ǹ� ó���Ǵ� ����̴�.
��, Main SQL�� ���� ����� ���ؼ�, �� �ο츶�� ���������� ���� ���� ��(input ��)�� ������ �� ������ ����, ����� TRUE�� ��� �����͸� �����Ѵ�.
Main SQL�� ���� ����� 100 �����̶�� ���������� �ִ� 100���� ����ȴ�. 
-> ���� �Ǽ��� ���� ��� ���������� Filter ���۹������ ó���� ��� ���ɻ� ��ȿ������ ��찡 �� ����.
*/  

-- <SUBQUERY_T1>
CREATE TABLE SUBQUERY_T1 AS 
SELECT LEVEL AS C4, CHR(65+MOD(LEVEL,26)) AS C5, LEVEL+9999 AS C6
FROM DUAL 
CONNECT BY LEVEL <= 250000;
--���̺� ����

BEGIN
	FOR I IN 1..6 LOOP
		INSERT INTO SUBQUERY_T1 SELECT * FROM SUBQUERY_T1;
		COMMIT;
	END LOOP;
END;

--250,000���� �����͸� ���� �� �� ������ ���̺� ���� 6�� �ݺ��Ͽ� ������

EXEC
DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'KJY',TABNAME='SUBQUERY_T1',CASCADE=>TRUE,ESTIMATE_PERCENT=>100);

CREATE INDEX SUBQUERY_T1_IDX_01 ON SUBQUERY_T1 (C4, C5);
CREATE INDEX SUBQUERY_T1_IDX_02 ON SUBQUERY_T1 (C5);

-- <SUBQUERY_T2>
CREATE TABLE SUBQUERY_T2 AS 
SELECT LEVEL AS C1, CHR(65+MOD(LEVEL,26)) AS C2, LEVEL+9999 AS C3, CHR(65+MOD(LEVEL,26)) AS C4
FROM DUAL 
CONNECT BY LEVEL <= 500000;

EXEC
DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'KJY',TABNAME='SUBQUERY_T2',CASCADE=>TRUE,ESTIMATE_PERCENT=>100);

CREATE INDEX SUBQUERY_T2_IDX_01 ON SUBQUERY_T2(C2, C1);
ALTER TABLE SUBQUERY_T2 ADD CONSTRAINT PK_SUBQUERY_2 PRIMARY KEY (C1);

-- <SUBQUERY_T3>
CREATE TABLE SUBQUERY_T3 AS 
SELECT LEVEL AS C1, CHR(65+MOD(LEVEL,26)) AS C2, LEVEL+9999 AS C3
FROM DUAL 
CONNECT BY LEVEL <= 500000;

EXEC
DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'KJY',TABNAME='SUBQUERY_T2',CASCADE=>TRUE,ESTIMATE_PERCENT=>100);

CREATE INDEX SUBQUERY_T3_IDX_01 ON SUBQUERY_T3(C1, C2);
ALTER TABLE SUBQUERY_T3 ADD CONSTRAINT PK_SUBQUERY_T3 PRIMARY KEY (C1);


--[1]. Main SQL�� ���� ����� ����, INPUT ���� unique�� ���
var b1 NUMBER
var b2 NUMBER
EXEC :b1 :=20000
EXEC :b2 :=400000

SELECT C1, C2, C3 
FROM SUBQUERY_T2 T2 
WHERE C1 >= :b1 AND C1 <= :b2
 AND EXISTS (
 	SELECT /*+ NO_UNNEST*/ 'x'
 	FROM SUBQUERY_T1 T1 
 	WHERE T1.C4  = T2.C1 
 );
 
--[2]. Main SQL�� ���� �Ǽ��� ����, INPUT ���� unique�� ���
var b1 NUMBER
var b2 NUMBER
EXEC :b1 :=20000
EXEC :b2 :=20004

SELECT C1, C2, C3
FROM SUBQUERY_T2 T2 
WHERE C1  >= :b1 AND C1 <= :b2 
 AND EXISTS (
	SELECT /*+ NO_UNNEST*/ 'x'
	FROM SUBQUERY_T1 T1 
	WHERE T1.C4 = T2.C1
);

--[2]. Main SQL�� ���� �Ǽ��� ������, INPUT ���� ������ 26������ ���
var b1 NUMBER
var b2 NUMBER
EXEC :b1 :=20000
EXEC :b2 :=400000

SELECT C1, C2, C3
FROM SUBQUERY_T2 T2 
WHERE C1  >= :b1 AND C1 <= :b2 
 AND EXISTS (
	SELECT /*+ NO_UNNEST*/ 'x'
	FROM SUBQUERY_T1 T1 
	WHERE T1.C5 = T2.C2
);


/*
 FILTER ���� ����� ��� �׻� Main SQL ���� ����Ǹ�, ���������� Main SQL���� ����� �������� ���� ���� �޾� �Ź� Ȯ���ϴ� ���·� ����ȴ�.
 ��ó�� filter ���۷��̼��� �׻� �� ���� ������� ����ϱ� ������ �پ��� ��Ȳ���� �����ϰ� ��ó�ϱ� ����� ���� ����̶� �� �� �ִ�.
 ���� SQL�� �����ȹ�� �����ϴ� ���������� filter ���۹������ ����ǰ� �ִٸ�, ���� ���������� ���� ���� �÷��� �ε����� �����ϴ��� Ȯ���ؾ� �Ѵ�.
 �ֳ��ϸ�, ���������� filter ���۹������ ����Ǵµ�, Full Table Scan���� ó���ϰ� �ִٸ� �ɰ��� ���� ������ �߻��� �� �ֱ� �����̴�.
*/
