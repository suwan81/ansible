--
-- Name: dba; Type: SCHEMA; Schema: -; Owner: gpadmin
--

CREATE SCHEMA dba;


ALTER SCHEMA dba OWNER TO gpadmin;


--
-- Name: service_monitoring; Type: TABLE; Schema: dba; Owner: gpadmin; Tablespace:
--

DROP TABLE IF EXISTS dba.service_monitoring;
CREATE TABLE dba.service_monitoring (
    num integer
)
 DISTRIBUTED BY (num);


ALTER TABLE dba.service_monitoring OWNER TO gpadmin;

INSERT INTO dba.service_monitoring VALUES (generate_series(1,2000));
