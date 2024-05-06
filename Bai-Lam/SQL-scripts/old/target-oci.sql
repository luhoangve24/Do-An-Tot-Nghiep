-- After duplicate
create pfile from spfile;
SELECT TYPE, MEMBER FROM V$LOGFILE ORDER BY GROUP#;
-- Check ORLs
select GROUP#,THREAD#,SEQUENCE#,  bytes/1024/1024 from v$log;
-- Check somethings...
show parameter name;
show parameter local_listener;
show parameter log_archive_dest_1;

--  Config Dataguard

	-- Create Standby Control File
	ALTER DATABASE CREATE STANDBY CONTROLFILE AS '/u02/oradata/shbfin/control_standby.ctl';
	SHUTDOWN IMMEDIATE;
	STARTUP MOUNT;
    
    -- Create Standby Redo Log
        -- ERROR: I MUST REMOVE THE STANDBY LOG I HAVE CREATE BEFORE BACKUP :)
        -- alter database drop standby logfile group 4; (5,6,7);
        
        alter database drop standby logfile group 4;
        alter database drop standby logfile group 5;
        alter database drop standby logfile group 6;
        alter database drop standby logfile group 7;
        
        SHOW PARAMETER NAME;
        SELECT TYPE,MEMBER FROM V$LOGFILE;
        ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 4 ('/u02/oradata/shbfin/stb_redo04.log') SIZE 200M; 
        ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 5 ('/u02/oradata/shbfin/stb_redo05.log') SIZE 200M; 
        ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 6 ('/u02/oradata/shbfin/stb_redo06.log') SIZE 200M; 
        ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 7 ('/u02/oradata/shbfin/stb_redo07.log') SIZE 200M;
        select thread#, group#, sequence#, status, bytes from v$standby_log;
        

	
	-- Set for remote archive location
	ALTER SYSTEM SET LOG_ARCHIVE_DEST_2=
	'SERVICE=pri ASYNC
	VALID_FOR=(ALL_LOGFILES,PRIMARY_ROLE)
	DB_UNIQUE_NAME=pri' SCOPE=SPFILE;     
    	-- Some others configuration
	ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_1=ENABLE;
	ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=ENABLE;
	ALTER SYSTEM SET LOG_ARCHIVE_MAX_PROCESSES=30;
	ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(sta,pri)';
	ALTER SYSTEM SET FAL_CLIENT='sta';
	ALTER SYSTEM SET FAL_SERVER='pri';
	-- ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO;
	ALTER DATABASE SET STANDBY DATABASE TO MAXIMIZE PERFORMANCE;
    
    -- Check
	SELECT DB_UNIQUE_NAME, SWITCHOVER_STATUS, DATABASE_ROLE, OPEN_MODE,PROTECTION_MODE FROM V$DATABASE;
    -- Pre-Check
	SELECT NAME, DB_UNIQUE_NAME, OPEN_MODE, LOG_MODE, FLASHBACK_ON, FORCE_LOGGING FROM V$DATABASE;
    
    	-- FLASHBACK
	ALTER DATABASE FLASHBACK ON;
	CREATE PFILE FROM SPFILE;
    ALTER DATABASE OPEN;
    
    ARCHIVE LOG LIST;
    
    -- Turn the MRP on
    ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT;
 ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;
    -- Check the backup archive has been applied
   
    ALTER SESSION SET nls_date_format='DD-MON-YYYY HH24:MI:SS';
     select thread#, group#, sequence#, status, bytes from v$standby_log;
	SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME, APPLIED FROM V$ARCHIVED_LOG ORDER BY SEQUENCE#;
    
    -- Check for process
    SELECT  PROCESS, STATUS, SEQUENCE# FROM V$MANAGED_STANDBY;
    
-- ++++++ TESTING
    select group#, sequence#, status, bytes/1024/1024 from v$standby_log;
    SELECT * FROM test1;
    
    
    SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME, APPLIED FROM V$ARCHIVED_LOG ORDER BY SEQUENCE#;

-- After Switchover
   SELECT * FROM  GV$ARCHIVE_DEST_STATUS;
   
   SELECT * FROM v$log_history;
    

SELECT 
ARCH.THREAD# "Instance", 
ARCH.SEQUENCE# "Log nh?n m?i nh?t",
APPL.SEQUENCE# "Log ?ã áp d?ng",
(ARCH.SEQUENCE# - APPL.SEQUENCE#) "?? tr?" 
FROM
    (SELECT THREAD# ,SEQUENCE# 
        FROM V$ARCHIVED_LOG 
        WHERE (THREAD#, FIRST_TIME)
            IN (SELECT THREAD#, MAX(FIRST_TIME)
                    FROM V$ARCHIVED_LOG 
                    GROUP BY THREAD#)
    ) ARCH,
    (SELECT THREAD# ,SEQUENCE# 
        FROM V$LOG_HISTORY 
        WHERE (THREAD#, FIRST_TIME)
            IN (SELECT THREAD#, MAX(FIRST_TIME) 
                    FROM V$LOG_HISTORY 
                    GROUP BY THREAD#)
    ) APPL
WHERE
    ARCH.THREAD# = APPL.THREAD#;
    

select * from v$log_history;
select dest_id, standby_dest, sequence#, 
            applied, archived, registrar, end_of_redo
       from v$archived_log join v$database
            using (resetlogs_change#)
       order by 3,1;
       
       
SELECT 
    ARCH.THREAD# "Instance", 
    ARCH.SEQUENCE# "Log nh?n m?i nh?t",
    APPL.SEQUENCE# "Log ?ã áp d?ng",
    (ARCH.SEQUENCE# - APPL.SEQUENCE#) "?? tr?" 
FROM
    (SELECT THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG 
        WHERE (THREAD#, FIRST_TIME) IN (SELECT THREAD#, MAX(FIRST_TIME)
        FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,
    (SELECT THREAD# ,SEQUENCE# FROM V$LOG_HISTORY 
        WHERE (THREAD#, FIRST_TIME) IN (SELECT THREAD#, MAX(FIRST_TIME) 
        FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL
WHERE
    ARCH.THREAD# = APPL.THREAD#;