--2) 조인 동작방식
--테스트 [1] : filter 동작 방식으로 수행되어 성능 문제가 발생하는 SQL
var b1 number
var b2 NUMBER 
EXEC :b1 := 249990
EXEC :b2 := 250210

SELECT C1, C2, C3
FROM SUBQUERY_T2 T2 
WHERE C1 >= :b1 AND C1 <= :b2
AND EXISTS
(
	SELECT /*+ NO_UNNEST*/ 'x'
	FROM SUBQUERY_T1 T1 
	WHERE T1.C6 = T2.C3 AND T1.C6 >= :b1
)

/*
FILTER 동작반식으로 수행한 위 테스트의 경우 테이블 t1의 칼럼 c6에 인덱스가 없어 Main SQL의 추출 건수만큼 SUBQUERY_T1 테이블을 반복적으로 FULL TABLE Scan 한다.
컬럼 c6에 인덱스를 생성해주면 성능이 개선될것이지만 실 운영환경에서는 인덱스를 생성하는 개선방법을 적용하지 못할 수 있다.
테스트[1]의 성능을 개선하기 위해 가장 중요한 포인트는 반복적인 full table scan을 줄이는 것이다.
그러므로 서브쿼리를 조인 동작방식으로 변경하고, Hash Join Semi으로 수행하도록   UNNEST_HASH_S 힌트를 부여하였다. 
*/

var b1 number
var b2 NUMBER 
EXEC :b1 := 249990
EXEC :b2 := 250210

SELECT C1, C2, C3
FROM SUBQUERY_T2 T2 
WHERE C1 >= :b1 AND C1 <= :b2
AND EXISTS
(
	SELECT /*+ UNNEST_HASH_SJ*/ 'x'
	FROM SUBQUERY_T1 T1 
	WHERE T1.C6 = T2.C3 AND T1.C6 >= :b1
);

/* 
Main SQL의 추출 건수는 매우 많고 서브쿼리에 있는 상수 조건이 매우 효율적이어서, 서브쿼리를 먼저 수행해야 효율적인 처리가 되는 SQL이 있다고 가정하자.
이런 경우 filter와 조인 동작방식 중 어떤 동작방식이 유리한지 알아보자.
*/

var b1 NUMBER
var b2 NUMBER
var b3 NUMBER
var b4 NUMBER
EXEC :b1 := 1
EXEC :b2 := 450210
EXEC :b3 := 100000
EXEC :b4 := 100004

SELECT C4, C5, C6
FROM SUBQUERY_T1 T1 
WHERE C6 >= :b1 AND C6 <= :b2
AND EXISTS (
	SELECT /*+ UNNEST_HASH_SJ*/ 'x'
	FROM SUBQUERY_T2 T2 
	WHERE T2.C1 = T1.C4 
	AND T2.C3 >= :b3 AND T2.C3 <= :b4
);