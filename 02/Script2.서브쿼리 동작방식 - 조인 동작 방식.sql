--2) ���� ���۹��
--�׽�Ʈ [1] : filter ���� ������� ����Ǿ� ���� ������ �߻��ϴ� SQL
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
FILTER ���۹ݽ����� ������ �� �׽�Ʈ�� ��� ���̺� t1�� Į�� c6�� �ε����� ���� Main SQL�� ���� �Ǽ���ŭ SUBQUERY_T1 ���̺��� �ݺ������� FULL TABLE Scan �Ѵ�.
�÷� c6�� �ε����� �������ָ� ������ �����ɰ������� �� �ȯ�濡���� �ε����� �����ϴ� ��������� �������� ���� �� �ִ�.
�׽�Ʈ[1]�� ������ �����ϱ� ���� ���� �߿��� ����Ʈ�� �ݺ����� full table scan�� ���̴� ���̴�.
�׷��Ƿ� ���������� ���� ���۹������ �����ϰ�, Hash Join Semi���� �����ϵ���   UNNEST_HASH_S ��Ʈ�� �ο��Ͽ���. 
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
Main SQL�� ���� �Ǽ��� �ſ� ���� ���������� �ִ� ��� ������ �ſ� ȿ�����̾, ���������� ���� �����ؾ� ȿ������ ó���� �Ǵ� SQL�� �ִٰ� ��������.
�̷� ��� filter�� ���� ���۹�� �� � ���۹���� �������� �˾ƺ���.
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