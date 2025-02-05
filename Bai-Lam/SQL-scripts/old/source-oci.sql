-- Check mode
SELECT NAME, DB_UNIQUE_NAME, OPEN_MODE, LOG_MODE, FLASHBACK_ON, FORCE_LOGGING, SWITCHOVER_STATUS, DATABASE_ROLE FROM V$DATABASE;

-- Check log l�st
ARCHIVE LOG LIST;

-- Turn on archive log
alter database archivelog;

-- Open: Open DF & ORLs
alter database open;

-- Check again
ARCHIVE LOG LIST;

-- Does the DB have ARLs?
SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME, APPLIED FROM V$ARCHIVED_LOG ORDER BY SEQUENCE#;

-- Turn force logging mode on
select group#,sequence#,status,members from v$log;
ALTER DATABASE FORCE LOGGING;
SELECT NAME, DB_UNIQUE_NAME, OPEN_MODE, LOG_MODE, FLASHBACK_ON, FORCE_LOGGING FROM V$DATABASE;

-- switch
ALTER SYSTEM SWITCH LOGFILE;
SELECT MEMBER FROM V$LOGFILE;
ARCHIVE LOG LIST;
SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME, APPLIED FROM V$ARCHIVED_LOG ORDER BY SEQUENCE#;

-- Create SRLs
select GROUP#,THREAD#,SEQUENCE#,bytes/1024/1024 from v$log;
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 4 ('/u02/oradata/shbfin/stb_redo04.log') SIZE 200M; 
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 5 ('/u02/oradata/shbfin/stb_redo05.log') SIZE 200M; 
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 6 ('/u02/oradata/shbfin/stb_redo06.log') SIZE 200M; 
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 7 ('/u02/oradata/shbfin/stb_redo07.log') SIZE 200M;

select thread#, group#, sequence#, status, bytes/1024/1024 from v$standby_log;
SELECT TYPE, MEMBER FROM V$LOGFILE ORDER BY GROUP#;

-- Some support config
ALTER SYSTEM SET LOCAL_LISTENER='(ADDRESS=(PROTOCOl=TCP)(HOST=source)(PORT=1521))' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_MAX_PROCESSES=30 SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_FORMAT='ora_%t_%s_%r.arc' SCOPE=SPFILE; 
ALTER SYSTEM SET DB_RECOVERY_FILE_DEST_SIZE = 5G      SCOPE=SPFILE;
ALTER SYSTEM SET DB_RECOVERY_FILE_DEST = '/u02/oradata/shbfin/fra/'  SCOPE=SPFILE;
ALTER SYSTEM SET DB_FLASHBACK_RETENTION_TARGET = 60    SCOPE=SPFILE;
ALTER SYSTEM SET REMOTE_LOGIN_PASSWORDFILE=EXCLUSIVE   SCOPE=SPFILE;
ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO SCOPE=SPFILE;

CREATE PFILE FROM SPFILE;

-- Verify changes
SHUTDOWN IMMEDIATE;
STARTUP;


-- Turn Flashback mode on
ALTER DATABASE FLASHBACK ON; -- Require Fast Recovery Area
SELECT NAME, DB_UNIQUE_NAME, OPEN_MODE, LOG_MODE, FLASHBACK_ON, FORCE_LOGGING FROM V$DATABASE;

-- +++++++++++++ Config Data Guard

-- Redo Transport 
	ALTER SYSTEM SET LOG_ARCHIVE_DEST_2=
	'SERVICE=sta ASYNC
	VALID_FOR=(ALL_LOGFILES,PRIMARY_ROLE)
	DB_UNIQUE_NAME=sta' SCOPE=SPFILE;

-- Set up list of Primary and Standby for enabling the database to send redo data
	ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(pri,sta)';
	ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_1=ENABLE;
	ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=ENABLE;

	-- Set up Fetch Archive Log and File Manager
	ALTER SYSTEM SET FAL_CLIENT='pri';
	ALTER SYSTEM SET FAL_SERVER='sta';
    
	-- Set up protection mode
	ALTER DATABASE SET STANDBY DATABASE TO MAXIMIZE PERFORMANCE;
    
    	-- Verify CHANGES
	SHUTDOWN IMMEDIATE;
	STARTUP;
    
    CREATE PFILE FROM SPFILE;
    
    ALTER SESSION SET nls_date_format='DD-MON-YYYY HH24:MI:SS';
	SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME, APPLIED   FROM V$ARCHIVED_LOG ORDER BY SEQUENCE#;
	SELECT DB_UNIQUE_NAME, SWITCHOVER_STATUS, DATABASE_ROLE, OPEN_MODE,PROTECTION_MODE FROM V$DATABASE;
    
    ARCHIVE LOG LIST;
    
    -- Check after done Standby
    SELECT * FROM  GV$ARCHIVE_DEST_STATUS;
    
    -- Check for Switch
    SELECT DB_UNIQUE_NAME, SWITCHOVER_STATUS, DATABASE_ROLE, OPEN_MODE,PROTECTION_MODE FROM V$DATABASE;
    
    -- Check for Process
    SELECT  PROCESS, STATUS, SEQUENCE# FROM V$MANAGED_STANDBY;
    
-- +++++ TESTING
	CREATE TABLE TEST1 (C1 INT PRIMARY KEY, C2 CHAR(6));
	INSERT INTO TEST1 VALUES (52, 'rap');
	INSERT INTO TEST1 VALUES (56, 'cap');
	COMMIT;
    select group#,sequence#,status, bytes/1024/1024 from v$log;
    ALTER SYSTEM CHECKPOINT;
    ALTER SYSTEM SWITCH LOGFILE;
    
    SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME, APPLIED FROM V$ARCHIVED_LOG ORDER BY SEQUENCE#;

    ALTER SYSTEM ARCHIVE LOG CURRENT;
    SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME, APPLIED FROM V$ARCHIVED_LOG ORDER BY SEQUENCE#;
    ARCHIVE LOG LIST;
    
    -- 2
    INSERT INTO TEST1 VALUES (53, '1rap');
	INSERT INTO TEST1 VALUES (54, '2cap');
    INSERT INTO TEST1 VALUES (55, '3rap');
	INSERT INTO TEST1 VALUES (57, '4cap');
    COMMIT;
    ALTER SYSTEM SWITCH LOGFILE;
    ALTER SYSTEM ARCHIVE LOG CURRENT;
    
     SELECT * FROM  GV$ARCHIVE_DEST_STATUS;
-- MONITOR
    select
       severity,
       error_code,
       to_char(timestamp,'DD-MON-YYYY HH24:MI:SS') "timestamp",
       message
    from
       v$dataguard_status
    where
       dest_id=2;
       
       
       SELECT ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received",
        APPL.SEQUENCE# "Last Sequence Applied",
        (ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference" 
        FROM
        (SELECT THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME )
        IN (SELECT THREAD#,MAX(FIRST_TIME) 
        FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,
        (SELECT THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME )
        IN (SELECT THREAD#,MAX(FIRST_TIME) 
        FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL
        WHERE
        ARCH.THREAD# = APPL.THREAD#
        ORDER BY 1;
        
--
SELECT * FROM v$log_history;


SELECT ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received",
APPL.SEQUENCE# "Last Sequence Applied",
(ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference" 
FROM
(SELECT THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME )
IN (SELECT THREAD#,MAX(FIRST_TIME) 
FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,
(SELECT THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME )
IN (SELECT THREAD#,MAX(FIRST_TIME) 
FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL
WHERE
ARCH.THREAD# = APPL.THREAD#
ORDER BY 1;

SELECT 
    ARCH.THREAD# "Instance", 
    ARCH.SEQUENCE# "Log nh?n m?i nh?t",
    APPL.SEQUENCE# "Log ?� �p d?ng",
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
    SELECT * FROM v$Log_history;
    
    SELECT THREAD# "Thread",SEQUENCE# "Last Sequence Generated" FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$ARCHIVED_LOG GROUP BY THREAD#) ORDER BY 1;
    
-- TEST FOR V$LOG_HISTORY
    INSERT INTO TEST1 VALUES (60, '9rap');
	INSERT INTO TEST1 VALUES (61, '8cap');
    ARCHIVE LOG LIST;
    COMMIT;
    ALTER SYSTEM SWITCH LOGFILE;
    ALTER SYSTEM ARCHIVE LOG CURRENT;