USE EX_SYS;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DailyBackup
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BackupPath NVARCHAR(500);
    DECLARE @BackupName NVARCHAR(200);
    DECLARE @DateStamp VARCHAR(20);

    SET @DateStamp = CONVERT(VARCHAR(8), GETDATE(), 112) + '_' +
                     REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');

    SET @BackupName = 'EX_SYS_Full_' + @DateStamp + '.bak';
    SET @BackupPath = 'E:\SQLBackups\ExamSystem\' + @BackupName;

    BACKUP DATABASE EX_SYS
    TO DISK = @BackupPath
    WITH INIT, 
         NAME = 'EX_SYS Full Backup',
         STATS = 10;
END;
GO
























USE EX_SYS;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ManualBackup
    @BackupType VARCHAR(10) = 'FULL'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BackupPath NVARCHAR(500);
    DECLARE @BackupName NVARCHAR(200);
    DECLARE @DateStamp VARCHAR(20);

    SET @DateStamp = CONVERT(VARCHAR(8), GETDATE(), 112) + '_' +
                     REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');

    IF @BackupType = 'FULL'
    BEGIN
        SET @BackupName = 'EX_SYS_Full_' + @DateStamp + '.bak';
        SET @BackupPath = 'E:\SQLBackups\ExamSystem\' + @BackupName;

        BACKUP DATABASE EX_SYS
        TO DISK = @BackupPath
        WITH INIT, NAME = 'Manual Full Backup', STATS = 10;
    END
    ELSE IF @BackupType = 'DIFF'
    BEGIN
        SET @BackupName = 'EX_SYS_Diff_' + @DateStamp + '.bak';
        SET @BackupPath = 'E:\SQLBackups\ExamSystem\' + @BackupName;

        BACKUP DATABASE EX_SYS
        TO DISK = @BackupPath
        WITH DIFFERENTIAL, INIT, NAME = 'Manual Differential Backup', STATS = 10;
    END
    ELSE IF @BackupType = 'LOG'
    BEGIN
        SET @BackupName = 'EX_SYS_Log_' + @DateStamp + '.trn';
        SET @BackupPath = 'E:\SQLBackups\ExamSystem\' + @BackupName;

        BACKUP LOG EX_SYS
        TO DISK = @BackupPath
        WITH INIT, NAME = 'Manual Log Backup', STATS = 10;
    END
    ELSE
    BEGIN
        RAISERROR('Invalid Backup Type. Use FULL, DIFF, or LOG.',16,1);
    END
END;
GO