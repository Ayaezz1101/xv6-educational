SELECT
    parent_inum,
    child_inum,
    name,
    path,
    last_update_tick
FROM directory_state
ORDER BY path; 



SELECT
    path,
    inum,
    file_off,
    readable,
    writable,
    last_update_tick
FROM file_objects_state
ORDER BY inum;



SELECT
    tick,
    pid,
    op_name,
    path,
    fd,
    file_off,
    file_ref
FROM fs_events
WHERE layer='FILE'
ORDER BY tick DESC
LIMIT 20;