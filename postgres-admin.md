Notes sur administration serveur Postgres
=========================================

Notes sur la partie système de Postgres et le montage d'un serveur "qualité production" pour l'utilisation pédagogique.


Docs générales
--------------

* Références <https://github.com/dhamaniasad/awesome-postgres>
* Client <https://dbeaver.io/download/>
* Fonctionnement de postgres <http://www.interdb.jp/pg/>
* SQL moderne <https://modern-sql.com/>

Représentation physique des pages (tables et index)
---------------------------------------------------


* Extension pour accéder aux pages <https://www.postgresql.org/docs/current/pageinspect.html>
* Série de 8 posts : <https://habr.com/en/company/postgrespro/blog/441962/>
* Série de posts dont la structure interce des BTrees <http://www.louisemeta.com/blog/>, voir son outil <https://github.com/louiseGrandjonc/pageinspect_inspector> poru représenter graphiquement les pages des index
* <https://www.8kdata.com/blog/postgresql-page-layout/> : super illustrations
* 3 posts bien root (assez proche de la suite en fait) <https://fritshoogland.wordpress.com/2017/07/01/postgresql-block-internals/>

On reprend la table <https://habr.com/en/company/postgrespro/blog/441962/>

```sql
-- Après avoir crée les extensions et donné les droits
-- CREATE EXTENSION pgstattuple;
-- CREATE EXTENSION pgstattuple;
-- GRANT pg_stat_scan_tables TO romulus;

CREATE table t(a integer, b text, c boolean);
CREATE index on t(a);
ANALYZE t;

\dS t
--                                      Table "public.t"
--  Column |  Type   | Collation | Nullable | Default | Storage  | Stats target | Description 
-- --------+---------+-----------+----------+---------+----------+--------------+-------------
--  a      | integer |           |          |         | plain    |              | 
--  b      | text    |           |          |         | extended |              | 
--  c      | boolean |           |          |         | plain    |              | 
-- Indexes:
--     "t_a_idx" btree (a)

SELECT relpages, reltuples FROM pg_class WHERE relname = 't';
SELECT * FROM page_header(get_raw_page('t', 0));
-- ERROR:  block number 0 is out of range for relation "t"
SELECT octet_length(get_raw_page('t', 0));
-- ERROR:  block number 0 is out of range for relation "t"

-- l'index est vide, sa racine c'est la meta page
SELECT * FROM bt_metap('t_a_idx');
-- -[ RECORD 1 ]-----------+-------
-- magic                   | 340322
-- version                 | 3
-- root                    | 0
-- level                   | 0
-- fastroot                | 0
-- fastlevel               | 0
-- oldest_xact             | 0
-- last_cleanup_num_tuples | -1

-- on ajoute un tuple
INSERT INTO t VALUES(random()*1000, md5((random()*1000)::text), random() < 0.5)
ON CONFLICT DO NOTHING;

select * from t;
--   a  |                b                 | c 
-- -----+----------------------------------+---
--  314 | 23ce47fb7a085d06ba01254b611d1622 | f

-- psql -d romulus -tA -c "select encode(get_raw_page::bytea, 'hex') from get_raw_page('t',0)" | xxd -p -r | od -A d -t x1


SELECT * FROM page_header(get_raw_page('t', 0));
--      lsn     | checksum | flags | lower | upper | special | pagesize | version | prune_xid 
-- -------------+----------+-------+-------+-------+---------+----------+---------+-----------
--  1F/9F1C10B0 |        0 |     0 |    28 |  8128 |    8192 |     8192 |       4 |         0
-- (1 row)

-- pour avoir les attributs découpés, utiliser heap_page_item_attrs
-- SELECT * FROM heap_page_item_attrs(get_raw_page('t', 0), 't'::regclass);
SELECT lp, lp_off, lp_len, t_xmin, t_xmax, t_ctid, t_hoff, t_data FROM heap_page_items(get_raw_page('t', 0));
--  lp | lp_off | lp_len | t_xmin | t_xmax | t_ctid | t_hoff |                                     t_data                                     
-- ----+--------+--------+--------+--------+--------+--------+--------------------------------------------------------------------------------
--   1 |   8128 |     62 |   1707 |      0 | (0,1)  |     24 | \x3a01000043323363653437666237613038356430366261303132353462363131643136323200

-- Une seule page pour les données
SELECT * FROM pgstattuple('t');

-- On a bien une seule page et une profondeur de 0
SELECT * FROM bt_metap('t_a_idx');      
-- -[ RECORD 1 ]-----------+-------
-- magic                   | 340322
-- version                 | 3
-- root                    | 1
-- level                   | 0
-- fastroot                | 1
-- fastlevel               | 0
-- oldest_xact             | 0
-- last_cleanup_num_tuples | -1

SELECT * FROM bt_page_stats('t_a_idx', 1);
-- -[ RECORD 1 ]-+-----
-- blkno         | 1
-- type          | l
-- live_items    | 1
-- dead_items    | 0
-- avg_item_size | 16
-- page_size     | 8192
-- free_size     | 8128
-- btpo_prev     | 0
-- btpo_next     | 0
-- btpo          | 0
-- btpo_flags    | 3


-- une seule page pour l'index (hors la meta page numéro 0)
SELECT * FROM pgstatindex('t_a_idx');


-- on voit que ça pointe vers le tuple (0,1) (page 0, offset 1)
SELECT * FROM bt_page_items('t_a_idx', 1);
--  itemoffset | ctid  | itemlen | nulls | vars |          data           
-- ------------+-------+---------+-------+------+-------------------------
--           1 | (0,1) |      16 | f     | f    | 00 01 00 00 00 00 00 00


INSERT INTO t VALUES(random()*1000, md5((random()*1000)::text), random() < 0.5)
ON CONFLICT DO NOTHING;

 
select * from t;
--   a  |                b                 | c 
-- -----+----------------------------------+---
--  314 | 23ce47fb7a085d06ba01254b611d1622 | f
--  400 | 0c30f2afe1fbd117cf260accd2611bf2 | f

INSERT INTO t(a,b,c)
SELECT random()*1000, md5((random()*1000)::text), random() < 0.5
FROM generate_series(1,10) as s(id)
ON CONFLICT DO NOTHING;

SELECT lp, lp_off, lp_len, t_xmin, t_xmax, t_ctid, t_hoff, t_data FROM heap_page_items(get_raw_page('t', 0));
--  lp | lp_off | lp_len | t_xmin | t_xmax | t_ctid | t_hoff |                                     t_data                                     
-- ----+--------+--------+--------+--------+--------+--------+--------------------------------------------------------------------------------
--   1 |   8128 |     62 |   1707 |      0 | (0,1)  |     24 | \x3a01000043323363653437666237613038356430366261303132353462363131643136323200
--   2 |   8064 |     62 |   1708 |      0 | (0,2)  |     24 | \x9001000043306333306632616665316662643131376366323630616363643236313162663200
--   3 |   8000 |     62 |   1709 |      0 | (0,3)  |     24 | \x8f01000043386164323733363164633933366366666261316532316133616561333039613600
--   4 |   7936 |     62 |   1709 |      0 | (0,4)  |     24 | \x6f00000043663562613734393732323961393961383765343530336336633130656436303401
--   5 |   7872 |     62 |   1709 |      0 | (0,5)  |     24 | \xab01000043373836303036653539363762636262303832373162333762313363626236373300
--   6 |   7808 |     62 |   1709 |      0 | (0,6)  |     24 | \xaf01000043376135333063366335316265613136353031306136373337653534626137373600
--   7 |   7744 |     62 |   1709 |      0 | (0,7)  |     24 | \x9900000043356533653863666562393136623836633138356238646261613838326262616500
--   8 |   7680 |     62 |   1709 |      0 | (0,8)  |     24 | \xe700000043386537613366363232363732633865353836626233656436363133653564613901
--   9 |   7616 |     62 |   1709 |      0 | (0,9)  |     24 | \x0b02000043313937633136326265636534343335633863623334343961626164323130633401
--  10 |   7552 |     62 |   1709 |      0 | (0,10) |     24 | \x6202000043383534316661333736633330326565646231373564326537616166633035613100
--  11 |   7488 |     62 |   1709 |      0 | (0,11) |     24 | \x4c03000043643339623037656335336631333566316235303066623965393265303237306300
--  12 |   7424 |     62 |   1709 |      0 | (0,12) |     24 | \x2d03000043633431343934656363623331373630653162326466613330643663633161373900
-- (12 rows)

-- un tuple à une longeur de 62B (lp_len), avec les données utilisateur qui commencent à 24B (t_off)
-- soit un t_data de longueur 62-24 = 38B (ce que l'on peut vérifier, les mots hexa étant codé sur 38*2=76 digits)
-- on "imagine" un badding de 2B pour que lp_off soit aligné sur des multiples de 8B (en 64bits)

-- on calcule le nombre 24B
-- voir https://www.2ndquadrant.com/en/blog/on-rocks-and-sand/

-- https://www.postgresql.org/docs/current/functions-admin.html#FUNCTIONS-ADMIN-DBSIZE
SELECT pg_column_size(row()) AS byte_header,
       pg_column_size(row(0::integer)) AS byte_integer,
       pg_column_size(row('23ce47fb7a085d06ba01254b611d1622'::text)) AS byte_text,
       pg_column_size(row(0::boolean)) AS byte_bool,
       pg_column_size(row(0::integer, '23ce47fb7a085d06ba01254b611d1622'::text, 0::boolean)) AS bytes;
--  byte_header | byte_integer | byte_text | byte_bool | bytes 
-- -------------+--------------+-----------+-----------+-------
--           24 |           28 |        57 |        25 |    62

-- SELECT char_length('23ce47fb7a085d06ba01254b611d1622');
-- The storage requirement for a short string (up to 126 bytes) is 1 byte plus the actual string, which includes the space padding in the case of character. Longer strings have 4 bytes of overhead instead of 1. Long strings are compressed by the system automatically, so the physical requirement on disk might be less. Very long values are also stored in background tables so that they do not interfere with rapid access to shorter column values. In any case, the longest possible character string that can be stored is about 1 GB. (The maximum value that will be allowed for n in the data type declaration is less than that. It wouldn't be useful to change this because with multibyte character encodings the number of characters and bytes can be quite different. If you desire to store long strings with no specific upper limit, use text or character varying without a length specifier, rather than making up an arbitrary length limit.)
-- NB, les hash MD5 sont sur 32 caractères, avec le \0 on a 33B + 24B header  = 57B


SELECT * FROM page_header(get_raw_page('t', 0));
--      lsn     | checksum | flags | lower | upper | special | pagesize | version | prune_xid 
-- -------------+----------+-------+-------+-------+---------+----------+---------+-----------
--  1F/9F1C1E00 |        0 |     0 |    72 |  7424 |    8192 |     8192 |       4 |         0

-- Avec 12 tuples, on a bien un "free space" entre les octets 
--  - 72 (24B de header + 12*4B de pointeur) 
--  - 7424 (qu'on retrouve comme offset lp_off du dernier tuple introduit)


-- On interroge la page de l'index
SELECT itemoffset, ctid FROM bt_page_items('t_a_idx', 1);
--  itemoffset |  ctid  
-- ------------+--------
--           1 | (0,4)
--           2 | (0,7)
--           3 | (0,8)
--           4 | (0,1)
--           5 | (0,3)
--           6 | (0,2)
--           7 | (0,5)
--           8 | (0,6)
--           9 | (0,9)
--          10 | (0,10)
--          11 | (0,12)
--          12 | (0,11)

-- on y retrouve bien l'ordre croissant des id de tuples
select a, n FROM t JOIN (select a, row_number() over() as n  from t) as t2 USING(a) ORDER BY a;
--   a  | n  
-- -----+----
--  111 |  4
--  153 |  7
--  231 |  8
--  314 |  1
--  399 |  3
--  400 |  2
--  427 |  5
--  431 |  6
--  523 |  9
--  610 | 10
--  813 | 12
--  844 | 11
-- (12 rows)

SELECT * FROM bt_page_stats('t_a_idx', 1);
--  blkno | type | live_items | dead_items | avg_item_size | page_size | free_size | btpo_prev | btpo_next | btpo | btpo_flags 
-- -------+------+------------+------------+---------------+-----------+-----------+-----------+-----------+------+------------
--      1 | l    |         12 |          0 |            16 |      8192 |      7908 |         0 |         0 |    0 |          3


-- une entrée de feuille a une taille de 16B, +4B pour le pointeur en début de page ?
-- le header dune page bttree fait 44 = 24B (pour une page) + 20B = 5fields * 4B de la partie opaque (BTPageOpaqueData) ajoutée en fin ?
-- https://github.com/postgres/postgres/blob/master/src/backend/access/nbtree/README
-- https://github.com/postgres/postgres/blob/master/src/include/access/nbtree.h
-- https://github.com/postgres/postgres/blob/master/src/backend/access/nbtree/nbtpage.c


-- ATTENTION : quand on modifie les données après un DELETE, les pointeurs d'index "restent" jusqu'au vacuum car les tuples sont là dans le HEAP, mais invisible pour la transaction
-- TODO EXAMPLE

-- On recommence

DROP TABLE t;
CREATE table t(a integer, b text, c boolean);
CREATE index on t(a);

INSERT INTO t(a,b,c)
SELECT s.id, md5((random()*1000)::text), random() < 0.5
FROM generate_series(1,407) as s(id)
ORDER BY random()
ON CONFLICT DO NOTHING;
-- INSERT 0 407
ANALYZE t;


SELECT * FROM bt_metap('t_a_idx');
--  magic  | version | root | level | fastroot | fastlevel | oldest_xact | last_cleanup_num_tuples 
-- --------+---------+------+-------+----------+-----------+-------------+-------------------------
--  340322 |       3 |    1 |     0 |        1 |         0 |           0 |                      -1


SELECT * FROM bt_page_stats('t_a_idx', 1);
--  blkno | type | live_items | dead_items | avg_item_size | page_size | free_size | btpo_prev | btpo_next | btpo | btpo_flags 
-- -------+------+------------+------------+---------------+-----------+-----------+-----------+-----------+------+------------
--      1 | l    |        407 |          0 |            16 |      8192 |         8 |         0 |         0 |    0 |          3

-- On est sur le point de déborder


INSERT INTO t VALUES(407, md5((random()*1000)::text), random() < 0.5) ON CONFLICT DO NOTHING;
SELECT * FROM bt_metap('t_a_idx');
--  magic  | version | root | level | fastroot | fastlevel | oldest_xact | last_cleanup_num_tuples 
-- --------+---------+------+-------+----------+-----------+-------------+-------------------------
--  340322 |       3 |    3 |     1 |        3 |         1 |           0 |                      -1

-- On voit 
  -- * qu'on a créée une racine (page #3)
  -- * que la page #1 a été rééquilibré à 90% de remplissage car c'est une page la plus à gauche (BTREE_DEFAULT_FILLFACTOR dans nbtree.h) 367/408 = 0.8995
  -- * qu'elle pointe vers (btpo_next) la page #2


SELECT * FROM bt_page_stats('t_a_idx', 3);
--  blkno | type | live_items | dead_items | avg_item_size | page_size | free_size | btpo_prev | btpo_next | btpo | btpo_flags 
-- -------+------+------------+------------+---------------+-----------+-----------+-----------+-----------+------+------------
--      3 | r    |          2 |          0 |            12 |      8192 |      8116 |         0 |         0 |    1 |          2

SELECT * FROM bt_page_items('t_a_idx', 3);
--  itemoffset |  ctid  | itemlen | nulls | vars |          data           
-- ------------+--------+---------+-------+------+-------------------------
--           1 | (1,0)  |       8 | f     | f    | 
--           2 | (2,21) |      16 | f     | f    | 6f 01 00 00 00 00 00 00

-- https://www.postgresql.org/docs/current/pageinspect.html
-- In a B-tree leaf page, ctid points to a heap tuple. In an internal page, the block number part of ctid points to another page in the index itself, while the offset part (the second number) is ignored and is usually 1.


SELECT * FROM bt_page_stats('t_a_idx', 1);
 blkno | type | live_items | dead_items | avg_item_size | page_size | free_size | btpo_prev | btpo_next | btpo | btpo_flags 
-------+------+------------+------------+---------------+-----------+-----------+-----------+-----------+------+------------
     1 | l    |        367 |          0 |            16 |      8192 |       808 |         0 |         2 |    0 |          1


SELECT * FROM bt_page_stats('t_a_idx', 2);
 blkno | type | live_items | dead_items | avg_item_size | page_size | free_size | btpo_prev | btpo_next | btpo | btpo_flags 
-------+------+------------+------------+---------------+-----------+-----------+-----------+-----------+------+------------
     2 | l    |         42 |          0 |            16 |      8192 |      7308 |         1 |         0 |    0 |          1


INSERT INTO t(a,b,c)
SELECT random()*65535, md5((random()*65535)::text), random() < 0.5
FROM generate_series(1,65535) as s(id)
ORDER BY random()
ON CONFLICT DO NOTHING;
```

Performances et indexation
--------------------------

* <http://use-the-index-luke.com/>

Monitoring
----------

### pg_stat_statements (extension)

The module must be loaded by adding pg_stat_statements to shared_preload_libraries in postgresql.conf, 

<https://www.postgresql.org/docs/current/pgstatstatements.html>



### pgmetrics (program)

* <https://github.com/rapidloop/pgmetrics>
* <https://pgmetrics.io/> 

Le soft sur lequel s'appuie l'offre <https://pgdash.io/>

### Open PostgreSQL Monitoring (OPM)

Porté par Dalibo

* <https://opm.readthedocs.io/>
* Sonde Nagios <https://github.com/OPMDG/check_pgactivity>

Voir pour nagios : <https://severalnines.com/blog/how-monitor-postgresql-using-nagios>

### PoWA

PoWA (PostgreSQL Workload Analyzer) is a performance tool for PostgreSQL 9.4 and newer allowing to collect, aggregate and purge statistics on multiple PostgreSQL instances from various Stats Extensions.

<https://powa.readthedocs.io/en/latest/>

Tuning de configuration
-----------------------

* <https://www.postgresql.org/docs/current/runtime-config-resource.html>
* <https://pgtune.leopard.in.ua/#/>
* <http://pgconfigurator.cybertec.at/>
* <https://github.com/jfcoz/postgresqltuner>


### Synchro

Test de la méthode de synchro (pour flush les données sur le disque)
<https://www.postgresql.org/docs/current/pgtestfsync.html>


### HugePages

<https://www.postgresql.org/docs/current/kernel-resources.html#LINUX-HUGE-PAGES>
<https://www.kernel.org/doc/Documentation/vm/hugetlbpage.txt>


Backup
------

* <https://pgbackrest.org/>
* <https://www.pgbarman.org/> par 2ndQuadrant

TimescaleDB
-----------

_TimescaleDB is an open-source database designed to make SQL scalable for time-series data. It is engineered up from PostgreSQL, providing automatic partitioning across time and space (partitioning key), as well as full SQL support. TimescaleDB is packaged as a PostgreSQL extension._

* <https://github.com/timescale/timescaledb>
* <https://docs.timescale.com/v1.3/getting-started/installation/ubuntu/installation-apt-ubuntu>
* <https://github.com/timescale/timescaledb-tune>
* Utilisable comme datasource pour Grafana <https://grafana.com/docs/features/datasources/postgres/>


Misc
----

* Mass loader <https://github.com/dimitri/pgloader> (au dessus de \copy COPY )
