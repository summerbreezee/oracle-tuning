--서브쿼리 사용 패턴[1]  : 서브쿼리 먼저 수행된 후, Main SQL의 컬럼 값과 비교하는 형태로 수행
SELECT * FROM  emp WHERE sal > (SELECT avg(sal) FROM emp);

--사용 패턴[2] : 서브쿼리 내에 Main SQL과의 연결조건이 존재하여, Main SQL에서 추출한 값을 상속받아 서브쿼리의 테이블에 해당 값이 존재하는지 체크하는 방식으로 수행된다. 물론 반대로 서브쿼리가 먼저 수행되고 Main SQL에 값을 전달할 수도 있다.
--실제 서브쿼리 사용시 성능 문제 발생 가능성 있음. 
SELECT c1, c2, c3
FROM SUBQUERY_2 t1
WHERE c2 = 'A'
AND EXISTS (	
	SELECT  /*+ NO_UNNEST*/
			'X'
	FROM SUBQUERY_T1 t1
	WHERE t1.c5 = t2.c2
)

--테스트[1] : 서브쿼리의 기본적인 특성 알아보기
SELECT  /*+ QB_NAME(A) */ coll
FROM (
	SELECT LEVEL coll
	FROM DUAL 
	CONNECT BY LEVEL <= 3
) a
WHERE a.coll IN (
		SELECT /*+ QB_NAME(A) */ coll --1,2,3가 각각 3개씩 출력
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
-- 서브쿼리에서 추출되는 데이터가 중복 값이 많더라도 Unique값만 처리하므로, 서브쿼리를 조인으로 변경하는 SQL작성시 서브쿼리의 중복된 데이터는 제거된다.


/* 서브쿼리의 동작방식 : 1) filter 동작방식 2) JOIN 동작방식
 * 
--1) filter 동작방식 
: filter 동작방식은 Main SQL에서 추출된 데이터 건수만큼 서브쿼리가 반복적으로 수행되며 처리되는 방식이다.
즉, Main SQL의 추출 결과에 대해서, 매 로우마다 서브쿼리에 조인 연결 값(input 값)을 제공한 후 수행해 보고, 결과가 TRUE일 경우 데이터를 추출한다.
Main SQL의 추출 결과가 100 만건이라면 서브쿼리는 최대 100만번 수행된다. 
-> 추출 건수가 많은 경우 서브쿼리를 Filter 동작방식으로 처리할 경우 성능상 비효율적인 경우가 더 많다.
*/  

-- <SUBQUERY_T1>
CREATE TABLE SUBQUERY_T1 AS 
SELECT LEVEL AS C4, CHR(65+MOD(LEVEL,26)) AS C5, LEVEL+9999 AS C6
FROM DUAL 
CONNECT BY LEVEL <= 250000;
--테이블 생성

BEGIN
	FOR I IN 1..6 LOOP
		INSERT INTO SUBQUERY_T1 SELECT * FROM SUBQUERY_T1;
		COMMIT;
	END LOOP;
END;

--250,000개의 데이터를 생성 한 후 동일한 테이블 값을 6번 반복하여 복사함

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


--[1]. Main SQL의 추출 결과가 많고, INPUT 값이 unique한 경우
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
 
--[2]. Main SQL의 추출 건수가 적고, INPUT 값이 unique한 경우
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

--[2]. Main SQL의 추출 건수는 많지만, INPUT 값의 종류가 26가지인 경우
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
 FILTER 동작 방식의 경우 항상 Main SQL 먼저 수행되며, 서브쿼리는 Main SQL에서 추출된 데이터의 값을 전달 받아 매번 확인하는 형태로 수행된다.
 이처럼 filter 오퍼레이션은 항상 한 가지 방법만을 고수하기 때문에 다양한 상황에서 유연하게 대처하기 어려운 동작 방식이라 볼 수 있다.
 만약 SQL의 실행계획를 점검하다 서브쿼리가 filter 동작방식으로 수행되고 있다면, 먼저 서브쿼리의 조인 연결 컬럼에 인덱스가 존재하는지 확인해야 한다.
 왜냐하면, 서브쿼리가 filter 동작방식으로 수행되는데, Full Table Scan으로 처리하고 있다면 심각한 성능 문제가 발생할 수 있기 때문이다.
*/
