-- Data Sync
    -- show roles
    select database_role from v$database;
    -- show log sequence
    select group#,sequence#,status from v$log; -- primary
    select group#,sequence#,status from v$standby_log; -- standby
    -- show none tables
    select * from test2;
    -- create table and Insert;
    CREATE TABLE TEST2 (C1 INT PRIMARY KEY, C2 CHAR(100));
	INSERT INTO TEST2 VALUES (2023, 'Hoc vien Ngan hang');
	INSERT INTO TEST2 VALUES (2024, 'CNTT va Kinh te so');
    COMMIT;
    -- Query on both server
    SELECT * FROM TEST2;

-- Gap Resolution after Disconnect (Performance,Availability)
    -- shutdown imme, stop listener standby
    shutdown immediate; -- dis all session
    lsnrctl stop TAINGHE
    lsnrctl status
    -- ping (from pri)
    tnsping sta
    
    -- insert (from primary)
    INSERT INTO TEST2 VALUES (2022, 'HTTTQL');
    COMMIT;
    -- query (both)
    select * from test2
    -- check for gap
    set wrap off
    col db_unique_name for a10
    col gap_status for a10
    SELECT 
    DB_UNIQUE_NAME, SYNCHRONIZATION_STATUS, GAP_STATUS, ERROR
    FROM  
    GV$ARCHIVE_DEST_STATUS 
    WHERE 
    DEST_ID <= 2;
    
    -- reopen listener standby
    lsnrctl start TAINGHE
    lsnrctl status
    -- ping again
    tnsping sta
        set wrap off
    col db_unique_name for a10
    col gap_status for a10
    SELECT 
    DB_UNIQUE_NAME, SYNCHRONIZATION_STATUS, GAP_STATUS, ERROR
    FROM  
    GV$ARCHIVE_DEST_STATUS 
    WHERE 
    DEST_ID <= 2;
    -- query
    
-- Broker, Fast-Start Failover with Observer
    -- Common Information
    show configuration
    show configuration verbose
    -- Each database
    show database pri
    show database sta
    -- Testing
    ps -ef | grep -i pmon -- -ef: full, elec (PRI)
    kill -9 <UID> -- 9: SIGKILL (root)
    
    -- start primary again & check
    
-- Maximum Performance
    -- pre-check
    show configuration
    -- kill standby
    ps -ef | grep -i pmon
    kill -9 PID
    -- INSERT & test
    INSERT INTO test2 VALUES (2021, "Oracle Database");
    COMMIT;