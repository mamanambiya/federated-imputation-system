--
-- PostgreSQL database dump
--

-- Dumped from database version 15.13 (Debian 15.13-1.pgdg120+1)
-- Dumped by pg_dump version 15.13 (Debian 15.13-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: file_access_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_access_logs (
    id integer NOT NULL,
    file_id integer NOT NULL,
    user_id integer NOT NULL,
    action character varying(50) NOT NULL,
    ip_address character varying(45),
    user_agent character varying(500),
    "timestamp" timestamp without time zone
);


ALTER TABLE public.file_access_logs OWNER TO postgres;

--
-- Name: file_access_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.file_access_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.file_access_logs_id_seq OWNER TO postgres;

--
-- Name: file_access_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.file_access_logs_id_seq OWNED BY public.file_access_logs.id;


--
-- Name: file_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_records (
    id integer NOT NULL,
    uuid uuid,
    filename character varying(255) NOT NULL,
    original_filename character varying(255) NOT NULL,
    file_path character varying(500) NOT NULL,
    file_size bigint NOT NULL,
    file_type character varying(50) NOT NULL,
    mime_type character varying(100),
    checksum_md5 character varying(32),
    checksum_sha256 character varying(64),
    user_id integer NOT NULL,
    job_id character varying(36),
    is_public boolean,
    is_available boolean,
    is_processed boolean,
    processing_status character varying(50),
    expires_at timestamp without time zone,
    extra_metadata text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    accessed_at timestamp without time zone
);


ALTER TABLE public.file_records OWNER TO postgres;

--
-- Name: file_records_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.file_records_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.file_records_id_seq OWNER TO postgres;

--
-- Name: file_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.file_records_id_seq OWNED BY public.file_records.id;


--
-- Name: file_access_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_access_logs ALTER COLUMN id SET DEFAULT nextval('public.file_access_logs_id_seq'::regclass);


--
-- Name: file_records id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_records ALTER COLUMN id SET DEFAULT nextval('public.file_records_id_seq'::regclass);


--
-- Data for Name: file_access_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.file_access_logs (id, file_id, user_id, action, ip_address, user_agent, "timestamp") FROM stdin;
1	1	123	upload	\N	\N	2025-10-08 20:36:32.048233
2	1	123	download	\N	\N	2025-10-08 20:36:32.898707
3	2	123	upload	\N	\N	2025-10-08 20:41:30.529958
4	2	123	download	\N	\N	2025-10-08 20:41:30.789981
5	2	123	download	\N	\N	2025-10-08 20:41:30.915729
6	3	123	upload	\N	\N	2025-10-08 20:50:18.590723
7	3	123	download	\N	\N	2025-10-08 20:50:18.967474
8	3	123	download	\N	\N	2025-10-08 20:50:19.103502
\.


--
-- Data for Name: file_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.file_records (id, uuid, filename, original_filename, file_path, file_size, file_type, mime_type, checksum_md5, checksum_sha256, user_id, job_id, is_public, is_available, is_processed, processing_status, expires_at, extra_metadata, created_at, updated_at, accessed_at) FROM stdin;
1	3c4b6034-86ce-4bc3-a762-8e2f31e53f52	123_20251008_203631_ffea6f80.vcf.gz	testdata_chr22_49513151_50509881_phased.vcf.gz	/app/storage/uploads/123_20251008_203631_ffea6f80.vcf.gz	62449	input	application/octet-stream	7a0d2f501467a10198cad8e06a032a88	e1f96c90670dc736ce51e0093587fbaeb9c06fef98c565de2f4bead184636eda	123	b973f274-60ce-4999-937b-4307d56f43a0	f	t	f	\N	\N	\N	2025-10-08 20:36:32.016272	2025-10-08 20:36:32.016277	\N
2	4191e856-5897-45b5-a9c5-2cbcbd4501b1	123_20251008_204130_45922f67.vcf.gz	testdata_chr22_49513151_50509881_phased.vcf.gz	/app/storage/uploads/123_20251008_204130_45922f67.vcf.gz	62449	input	application/octet-stream	7a0d2f501467a10198cad8e06a032a88	e1f96c90670dc736ce51e0093587fbaeb9c06fef98c565de2f4bead184636eda	123	078966cd-b24c-42c6-a564-3bb9ee9153a5	f	t	f	\N	\N	\N	2025-10-08 20:41:30.520465	2025-10-08 20:41:30.520469	\N
3	fb4528ec-5fa7-4aae-9cdb-a560f1cfb6a0	123_20251008_205018_fdf8ae57.vcf.gz	testdata_chr22_49513151_50509881_phased.vcf.gz	/app/storage/uploads/123_20251008_205018_fdf8ae57.vcf.gz	62449	input	application/octet-stream	7a0d2f501467a10198cad8e06a032a88	e1f96c90670dc736ce51e0093587fbaeb9c06fef98c565de2f4bead184636eda	123	454251d5-f900-45fa-b973-98728d7bd9c3	f	t	f	\N	\N	\N	2025-10-08 20:50:18.581353	2025-10-08 20:50:18.581357	\N
\.


--
-- Name: file_access_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.file_access_logs_id_seq', 8, true);


--
-- Name: file_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.file_records_id_seq', 3, true);


--
-- Name: file_access_logs file_access_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_access_logs
    ADD CONSTRAINT file_access_logs_pkey PRIMARY KEY (id);


--
-- Name: file_records file_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_records
    ADD CONSTRAINT file_records_pkey PRIMARY KEY (id);


--
-- Name: ix_file_access_logs_file_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_file_access_logs_file_id ON public.file_access_logs USING btree (file_id);


--
-- Name: ix_file_access_logs_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_file_access_logs_id ON public.file_access_logs USING btree (id);


--
-- Name: ix_file_access_logs_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_file_access_logs_timestamp ON public.file_access_logs USING btree ("timestamp");


--
-- Name: ix_file_records_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_file_records_created_at ON public.file_records USING btree (created_at);


--
-- Name: ix_file_records_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_file_records_id ON public.file_records USING btree (id);


--
-- Name: ix_file_records_job_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_file_records_job_id ON public.file_records USING btree (job_id);


--
-- Name: ix_file_records_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_file_records_user_id ON public.file_records USING btree (user_id);


--
-- Name: ix_file_records_uuid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_file_records_uuid ON public.file_records USING btree (uuid);


--
-- PostgreSQL database dump complete
--

