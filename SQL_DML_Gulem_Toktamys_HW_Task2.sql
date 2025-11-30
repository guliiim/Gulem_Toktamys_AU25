--1. Create table ‘table_to_delete’ and fill it
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;

--2. Lookup how much space this table consumes with the following query:
SELECT *, 
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS index,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS table_size
FROM (
  SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes,0) AS table_bytes
  FROM (
    SELECT c.oid,
           nspname AS table_schema,
           relname AS table_name,
           c.reltuples AS row_estimate,
           pg_total_relation_size(c.oid) AS total_bytes,
           pg_indexes_size(c.oid) AS index_bytes,
           pg_total_relation_size(reltoastrelid) AS toast_bytes
    FROM pg_class c
    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE relkind = 'r'
  ) a
) a
WHERE table_name LIKE '%table_to_delete%';

-- Initial table size: 575 MB
--results:
--Successfully run. Total query runtime: 110 msec. 1 rows affected
-- "18156"	"public"	"table_to_delete"	9.999563e+06	602611712	0	8192	602603520	total="575 MB"	"0 bytes"	"8192 bytes"	table_size="575 MB"


--3. Issue the following DELETE operation on ‘table_to_delete’:
--a) Note how much time it takes to perform this DELETE statement;
DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;
--DELETE removes almost 3.33 million rows but does not immediately free disk space. 
--DELETE duration: 11.05 seconds
--results:
--DELETE 3333333
--Query returned successfully in 11 secs 50 msec.

--b) Lookup how much space this table consumes after previous DELETE;
SELECT *,
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS index_size,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS table_size
FROM (
    SELECT *,
           total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
    FROM (
        SELECT c.oid,
               nspname AS table_schema,
               relname AS table_name,
               c.reltuples AS row_estimate,
               pg_total_relation_size(c.oid) AS total_bytes,
               pg_indexes_size(c.oid) AS index_bytes,
               pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';
--Table size after DELETE is still 575 MB. Disk space is not reclaimed automatically after DELETE
--results:
--"18156"	"public"	"table_to_delete"	9.999563e+06	602611712	0	8192	602603520	"575 MB"	"0 bytes"	"8192 bytes"	"575 MB"
--Successfully run. Total query runtime: 60 msec. 1 rows affected

--c) Perform the following command: 
VACUUM FULL VERBOSE table_to_delete;
--VACUUM FULL physically rewrites the table and removes dead tuples.
--Duration: 5.712 seconds
--results:
--ИНФОРМАЦИЯ:  очистка "public.table_to_delete"
--ИНФОРМАЦИЯ:  "public.table_to_delete": найдено удаляемых версий строк: 0, неудаляемых: 6666667, просмотрено страниц: 73536
--VACUUM
--Query returned successfully in 5 secs 712 msec.

--d) Check space consumption of the table once again and make conclusions;
SELECT *,
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS index_size,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS table_size
FROM (
    SELECT *,
           total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
    FROM (
        SELECT c.oid,
               nspname AS table_schema,
               relname AS table_name,
               c.reltuples AS row_estimate,
               pg_total_relation_size(c.oid) AS total_bytes,
               pg_indexes_size(c.oid) AS index_bytes,
               pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';
---Table size after VACUUM FULL: 383 MB, space reclaimed: 192 MB
-- Dead tuples removed and table compacted
--results:
--"18156"	"public"	"table_to_delete"	6.666667e+06	401580032	0	8192	401571840	"383 MB"	"0 bytes"	"8192 bytes"	"383 MB"

--e) Recreate ‘table_to_delete’ table;
DROP TABLE IF EXISTS table_to_delete;
--DROP TABLE
--Query returned successfully in 115 msec.

CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, (10^7)::int) x;
--Table recreated to full 10 million rows for TRUNCATE testing
--Recreate duration: 15.690 seconds
--results:
--SELECT 10000000
--Query returned successfully in 15 secs 690 msec.


--4. Issue the following TRUNCATE operation: TRUNCATE table_to_delete;
--a) Note how much time it takes to perform this TRUNCATE statement.
TRUNCATE table_to_delete;
-- TRUNCATE removes all rows instantly
-- Duration: 1.179 seconds
-- Much faster than DELETE (11 seconds) and does not leave dead tuples
--results:
--TRUNCATE TABLE
--Query returned successfully in 1 secs 179 msec.

--b) Compare with previous results and make conclusion.
--DELETE 1/3 of rows took almost 11 sec, but disk space was not freed automatically.
--VACUUM FULL after DELETE took almost 5.7 sec and reclaimed space, reducing table from 575 MB to 383 MB.
--TRUNCATE removed all rows instantly in almost 1.2 sec and immediately freed nearly all table space from 575 MB to 8 KB.
--TRUNCATE is much faster than DELETE for large tables. TRUNCATE does not leave dead tuples, so no VACUUM needed. For clearing an entire table quickly, TRUNCATE is the best option.
--DELETE is useful when you need to remove specific rows, but it can be slow and requires VACUUM to reclaim space.

--c) Check space consumption of the table once again and make conclusions;
SELECT *,
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS index_size,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS table_size
FROM (
    SELECT *,
           total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
    FROM (
        SELECT c.oid,
               nspname AS table_schema,
               relname AS table_name,
               c.reltuples AS row_estimate,
               pg_total_relation_size(c.oid) AS total_bytes,
               pg_indexes_size(c.oid) AS index_bytes,
               pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';
--Table size after TRUNCATE is 8192 bytes
--TRUNCATE releases space immediately, unlike DELETE which needs VACUUM FULL
--results:
--"18166"	"public"	"table_to_delete"	0	8192	0	8192	0	"8192 bytes"	"0 bytes"	"8192 bytes"	"0 bytes"





