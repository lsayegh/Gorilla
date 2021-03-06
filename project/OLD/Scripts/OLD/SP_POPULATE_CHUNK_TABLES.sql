USE gorilla
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'SP_POPULATE_CHUNK_TABLES')
	DROP PROCEDURE SP_POPULATE_CHUNK_TABLES
GO

CREATE PROCEDURE dbo.SP_POPULATE_CHUNK_TABLES
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @pk_id INT
	DECLARE @N1 SMALLINT
	DECLARE @N2 SMALLINT
	DECLARE @N3 SMALLINT
	DECLARE @N4 SMALLINT
	DECLARE @N5 SMALLINT
	DECLARE @draw_until INT

	CREATE TABLE #TEMP_QUADRUPLE
	(
		Q1 SMALLINT,
		Q2 SMALLINT,
		Q3 SMALLINT,
		Q4 SMALLINT
	)

	CREATE TABLE #TEMP_TRIPLE
	(
		T1 SMALLINT,
		T2 SMALLINT,
		T3 SMALLINT
	)

	CREATE TABLE #TEMP_DOUBLE
	(
		D1 SMALLINT,
		D2 SMALLINT
	)
	
	SET @draw_until = (SELECT MIN(pk_id) FROM (SELECT TOP 5 pk_id FROM dbo.winner ORDER BY pk_id DESC) A )
	
	CREATE INDEX IX_Q1 ON #TEMP_QUADRUPLE (Q1, Q2, Q3, Q4)
	CREATE INDEX IX_D1 ON #TEMP_DOUBLE (D1, D2)
	CREATE INDEX IX_T1 ON #TEMP_TRIPLE (T1, T2, T3)

	DECLARE batch_cursor CURSOR FOR 
	SELECT pk_id, N1, N2, N3, N4, N5
	FROM winner

	OPEN batch_cursor
	FETCH NEXT FROM batch_cursor INTO @pk_id, @n1, @n2, @n3, @n4, @n5
	WHILE ( @@fetch_status = 0 )
		BEGIN
			INSERT INTO #TEMP_quadruple (Q1, Q2, Q3, Q4)
			SELECT N1, N2, N3, N4
			FROM (	SELECT N1 = @N1, N2 = @N2, N3 = @N3, N4 = @N4 UNION
					SELECT N1 = @N1, N2 = @N2, N3 = @N3, N4 = @N5 UNION
					SELECT N1 = @N1, N2 = @N3, N3 = @N4, N4 = @N5 UNION
					SELECT N1 = @N1, N2 = @N2, N3 = @N4, N4 = @N5 UNION
					SELECT N1 = @N2, N2 = @N3, N3 = @N4, N4 = @N5
				) A
			WHERE NOT EXISTS (SELECT 1 FROM #TEMP_quadruple X WHERE A.N1 = X.Q1 AND A.N2 = X.Q2 AND A.N3 = X.Q3 AND A.N4 = X.Q4)
			
			INSERT INTO #TEMP_TRIPLE (T1, T2, T3)
			SELECT N1, N2, N3
			FROM (	SELECT N1 = @N1, N2 = @N2, N3 = @N3 UNION
					SELECT N1 = @N1, N2 = @N2, N3 = @N4 UNION
					SELECT N1 = @N1, N2 = @N2, N3 = @N5 UNION
					SELECT N1 = @N1, N2 = @N3, N3 = @N4 UNION
					SELECT N1 = @N1, N2 = @N3, N3 = @N5 UNION
					SELECT N1 = @N1, N2 = @N4, N3 = @N5 UNION
					SELECT N1 = @N2, N2 = @N3, N3 = @N4 UNION
					SELECT N1 = @N2, N2 = @N3, N3 = @N5 UNION
					SELECT N1 = @N2, N2 = @N4, N3 = @N5 UNION
					SELECT N1 = @N3, N2 = @N4, N3 = @N5
					
				) A
			WHERE NOT EXISTS (SELECT 1 FROM #TEMP_TRIPLE X WHERE A.N1 = X.T1 AND A.N2 = X.T2 AND A.N3 = X.T3)
		
			IF @pk_id >= @draw_until
				BEGIN
					INSERT INTO #TEMP_DOUBLE(D1, D2)
					SELECT N1, N2
					FROM (	SELECT N1 = @N1, N2 = @N2 UNION
							SELECT N1 = @N1, N2 = @N3 UNION
							SELECT N1 = @N1, N2 = @N4 UNION
							SELECT N1 = @N1, N2 = @N5 UNION
							SELECT N1 = @N2, N2 = @N3 UNION
							SELECT N1 = @N2, N2 = @N4 UNION
							SELECT N1 = @N2, N2 = @N5 UNION
							SELECT N1 = @N3, N2 = @N4 UNION
							SELECT N1 = @N3, N2 = @N5 UNION
							SELECT N1 = @N4, N2 = @N5
						) A
					WHERE NOT EXISTS (SELECT 1 FROM #TEMP_DOUBLE X WHERE A.N1 = X.D1 AND A.N2 = X.D2)
				END
		
		
			FETCH NEXT FROM batch_cursor INTO @pk_id, @n1, @n2, @n3, @n4, @n5
		END
	CLOSE batch_cursor
	DEALLOCATE batch_cursor	

	IF EXISTS (SELECT 1 FROM #TEMP_QUADRUPLE)
		BEGIN
			TRUNCATE TABLE dbo.CHUNK_QUADRUPLET
			
			INSERT INTO dbo.CHUNK_QUADRUPLET(C1, C2, C3, C4)
			SELECT Q1, Q2, Q3, Q4
			FROM #TEMP_QUADRUPLE
		END
		
		
	IF EXISTS (SELECT 1 FROM #TEMP_TRIPLE)
		BEGIN
			TRUNCATE TABLE dbo.CHUNK_TRIPLET
			
			INSERT INTO dbo.CHUNK_TRIPLET(T1, T2, T3)
			SELECT T1, T2, T3
			FROM #TEMP_TRIPLE
		END

	IF EXISTS (SELECT 1 FROM #TEMP_DOUBLE)
		BEGIN
			TRUNCATE TABLE dbo.CHUNK_DOUBLET
			
			INSERT INTO dbo.CHUNK_DOUBLET(D1, D2)
			SELECT D1, D2
			FROM #TEMP_DOUBLE
		END

	--SELECT * FROM quadruple
	--SELECT * FROM triple
	--SELECT * FROM [double]


	DROP TABLE #TEMP_QUADRUPLE
	DROP TABLE #TEMP_TRIPLE
	DROP TABLE #TEMP_DOUBLE
END
GO