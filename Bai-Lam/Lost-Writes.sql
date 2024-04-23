-- Scenario: No LWP
-- Primary
show parameter lost;
select database_role from v$database;
    -- Create tablespace for test Lost Writes
create tablespace lostwrite datafile '/u02/oradata/shbfin/test.dbf' size 100M;
    -- Verify & Lost Write Protection
select * from dba_data_files;
select tablespace_name,status,bigfile,contents,logging,allocation_type,encrypted,lost_write_protect,chunk_tablespace from dba_tablespaces;


    create table losttable 
    (id number, 
    payload varchar2(100)) 
    tablespace lostwrite;
    
    select current_scn from v$database; -- 3127919
    
        -- Import Data
    insert into losttable(id,payload) values (1, '2 trieu VND');
    COMMIT;
    ALTER SYSTEM CHECKPOINT; -- 3129448
    ALTER SYSTEM flush buffer_cache;
    
        -- Find where data resides
    select rowid, dbms_rowid.ROWID_BLOCK_NUMBER(rowid), a.* from losttable a;
    select block_id, blocks from dba_extents where segment_name='LOSTTABLE';
    
        -- Update table
    update losttable
    set payload = '5 trieu VND'
    where id = 1;
    commit;
    select current_scn from v$database; -- 3131165
    alter system checkpoint;
    alter system flush buffer_cache;

            -- Query again after simulating
    select * from losttable;
    
            -- Update again
    UPDATE losttable
    SET payload = '9 trieu VND'
    WHERE id = 1;
    ROLLBACK;
    select * from losttable;
-- Standby
show parameter lost;
select database_role from v$database;
    -- Check for auto sync creating
    select * from dba_data_files;
    select * from lost_table;
    
    
-- Scenario: LWP
