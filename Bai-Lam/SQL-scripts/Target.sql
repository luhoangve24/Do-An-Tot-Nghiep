-- Status
SELECT 
    DB_UNIQUE_NAME, 
    OPEN_MODE, 
    LOG_MODE, 
    FLASHBACK_ON, 
    FORCE_LOGGING,
    DATABASE_ROLE,
    SWITCHOVER_STATUS
FROM 
    V$DATABASE;
    
-- Processes
SELECT
    PROCESS, STATUS, SEQUENCE# 
FROM 
    V$MANAGED_STANDBY;
-- ALLOCATED: active, but not connected to PDB
-- CLOSING: completed to archived redo logs
-- CONNECTED: network etablished to PDB
-- IDLE: not performing any activities
-- APPLYING_LOG: apply

-- Info about Standby Redo Logs
SELECT 
    GROUP#, SEQUENCE#, STATUS, BYTES/1024/1024 as SJZE 
FROM 
    V$STANDBY_LOG;
    

-- Infor about Delay
SELECT 
ARCH.THREAD# "Instance", 
ARCH.SEQUENCE# "Log nhan moi nhat",
APPL.SEQUENCE# "Log da ap dung",
(ARCH.SEQUENCE# - APPL.SEQUENCE#) "Do tre" 
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