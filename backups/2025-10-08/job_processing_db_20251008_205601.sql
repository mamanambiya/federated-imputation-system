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
-- Name: imputation_jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.imputation_jobs (
    id uuid NOT NULL,
    user_id integer NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    service_id integer NOT NULL,
    reference_panel_id integer NOT NULL,
    input_format character varying(20),
    build character varying(20),
    phasing boolean,
    population character varying(100),
    status character varying(20),
    progress_percentage integer,
    external_job_id character varying(200),
    input_file_id integer,
    input_file_name character varying(255),
    input_file_size integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    execution_time_seconds integer,
    error_message text,
    service_response json
);


ALTER TABLE public.imputation_jobs OWNER TO postgres;

--
-- Name: job_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_logs (
    id integer NOT NULL,
    job_id uuid,
    step_name character varying(100) NOT NULL,
    step_index integer,
    log_type character varying(20),
    message text NOT NULL,
    "timestamp" timestamp without time zone
);


ALTER TABLE public.job_logs OWNER TO postgres;

--
-- Name: job_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.job_logs_id_seq OWNER TO postgres;

--
-- Name: job_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.job_logs_id_seq OWNED BY public.job_logs.id;


--
-- Name: job_status_updates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_status_updates (
    id integer NOT NULL,
    job_id uuid,
    status character varying(20) NOT NULL,
    progress_percentage integer,
    message text,
    details json,
    "timestamp" timestamp without time zone
);


ALTER TABLE public.job_status_updates OWNER TO postgres;

--
-- Name: job_status_updates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_status_updates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.job_status_updates_id_seq OWNER TO postgres;

--
-- Name: job_status_updates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.job_status_updates_id_seq OWNED BY public.job_status_updates.id;


--
-- Name: job_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_templates (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    user_id integer NOT NULL,
    service_id integer NOT NULL,
    reference_panel_id integer NOT NULL,
    input_format character varying(20),
    build character varying(20),
    phasing boolean,
    population character varying(100),
    is_public boolean,
    usage_count integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.job_templates OWNER TO postgres;

--
-- Name: job_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.job_templates_id_seq OWNER TO postgres;

--
-- Name: job_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.job_templates_id_seq OWNED BY public.job_templates.id;


--
-- Name: file_access_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_access_logs ALTER COLUMN id SET DEFAULT nextval('public.file_access_logs_id_seq'::regclass);


--
-- Name: file_records id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_records ALTER COLUMN id SET DEFAULT nextval('public.file_records_id_seq'::regclass);


--
-- Name: job_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_logs ALTER COLUMN id SET DEFAULT nextval('public.job_logs_id_seq'::regclass);


--
-- Name: job_status_updates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_status_updates ALTER COLUMN id SET DEFAULT nextval('public.job_status_updates_id_seq'::regclass);


--
-- Name: job_templates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_templates ALTER COLUMN id SET DEFAULT nextval('public.job_templates_id_seq'::regclass);


--
-- Data for Name: file_access_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.file_access_logs (id, file_id, user_id, action, ip_address, user_agent, "timestamp") FROM stdin;
\.


--
-- Data for Name: file_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.file_records (id, uuid, filename, original_filename, file_path, file_size, file_type, mime_type, checksum_md5, checksum_sha256, user_id, job_id, is_public, is_available, is_processed, processing_status, expires_at, extra_metadata, created_at, updated_at, accessed_at) FROM stdin;
\.


--
-- Data for Name: imputation_jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.imputation_jobs (id, user_id, name, description, service_id, reference_panel_id, input_format, build, phasing, population, status, progress_percentage, external_job_id, input_file_id, input_file_name, input_file_size, created_at, updated_at, started_at, completed_at, execution_time_seconds, error_message, service_response) FROM stdin;
6587eeff-af44-4b77-b850-0e4d9b3a5fae	1	chr20.R50.merged.1.330k.recode.small.vcf - H3Africa Imputation Service	\N	1	37	vcf	hg38	t	\N	failed	0	\N	\N	chr20.R50.merged.1.330k.recode.small.vcf.gz	235859	2025-10-07 22:00:23.656162	2025-10-07 22:00:24.311465	2025-10-07 22:00:24.078015	2025-10-07 22:00:24.311471	0	Job processing error: [Errno -3] Temporary failure in name resolution	{}
b973f274-60ce-4999-937b-4307d56f43a0	1	Test Job - Jobs Page Fix Verification	Testing job submission after fixing JWT authentication	1	38	vcf	hg38	t	multi-ethnic	failed	0	\N	1	testdata_chr22_49513151_50509881_phased.vcf.gz	62449	2025-10-08 20:36:31.873495	2025-10-08 20:36:33.019965	2025-10-08 20:36:32.563856	2025-10-08 20:36:33.019973	0	No credentials configured for service H3Africa Imputation Service. Please add your API token in Settings → Service Credentials.	{}
078966cd-b24c-42c6-a564-3bb9ee9153a5	1	H3Africa Test Job - With Valid Credentials	Testing job submission with configured H3Africa API token	1	37	vcf	hg38	t	african	failed	10	job-20251008-204131-199	2	testdata_chr22_49513151_50509881_phased.vcf.gz	62449	2025-10-08 20:41:30.496496	2025-10-08 20:42:31.921357	2025-10-08 20:41:30.561874	2025-10-08 20:42:31.921365	61	Job failed: Job failed during execution	{"success": true, "message": "Your job was successfully added to the job queue.", "id": "job-20251008-204131-199"}
454251d5-f900-45fa-b973-98728d7bd9c3	1	Event Loop Fix Test Job	Testing job submission with synchronous HTTP client	1	37	vcf	hg38	t	african	failed	10	job-20251008-205019-206	3	testdata_chr22_49513151_50509881_phased.vcf.gz	62449	2025-10-08 20:50:18.552568	2025-10-08 20:51:19.898045	2025-10-08 20:50:18.767902	2025-10-08 20:51:19.898052	61	Job failed: Job failed during execution	{"success": true, "message": "Your job was successfully added to the job queue.", "id": "job-20251008-205019-206"}
\.


--
-- Data for Name: job_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_logs (id, job_id, step_name, step_index, log_type, message, "timestamp") FROM stdin;
\.


--
-- Data for Name: job_status_updates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_status_updates (id, job_id, status, progress_percentage, message, details, "timestamp") FROM stdin;
1	6587eeff-af44-4b77-b850-0e4d9b3a5fae	queued	0	Job queued for processing	{}	2025-10-07 22:00:23.823745
2	6587eeff-af44-4b77-b850-0e4d9b3a5fae	running	0	Job processing started	{}	2025-10-07 22:00:24.090224
3	6587eeff-af44-4b77-b850-0e4d9b3a5fae	failed	0	Job processing error: [Errno -3] Temporary failure in name resolution	{}	2025-10-07 22:00:24.315536
4	b973f274-60ce-4999-937b-4307d56f43a0	queued	0	Job queued for processing	{}	2025-10-08 20:36:32.354856
5	b973f274-60ce-4999-937b-4307d56f43a0	running	0	Job processing started	{}	2025-10-08 20:36:32.575259
6	b973f274-60ce-4999-937b-4307d56f43a0	failed	0	No credentials configured for service H3Africa Imputation Service. Please add your API token in Settings → Service Credentials.	{}	2025-10-08 20:36:33.02193
7	078966cd-b24c-42c6-a564-3bb9ee9153a5	queued	0	Job queued for processing	{}	2025-10-08 20:41:30.553281
8	078966cd-b24c-42c6-a564-3bb9ee9153a5	running	0	Job processing started	{}	2025-10-08 20:41:30.569608
9	078966cd-b24c-42c6-a564-3bb9ee9153a5	running	10	Job submitted to external service	{}	2025-10-08 20:41:31.690249
10	078966cd-b24c-42c6-a564-3bb9ee9153a5	failed	10	Job failed: Job failed during execution	{}	2025-10-08 20:42:31.922755
11	454251d5-f900-45fa-b973-98728d7bd9c3	queued	0	Job queued for processing	{}	2025-10-08 20:50:18.705623
12	454251d5-f900-45fa-b973-98728d7bd9c3	running	0	Job processing started	{}	2025-10-08 20:50:18.773502
13	454251d5-f900-45fa-b973-98728d7bd9c3	running	10	Job submitted to external service	{}	2025-10-08 20:50:19.649958
14	454251d5-f900-45fa-b973-98728d7bd9c3	failed	10	Job failed: Job failed during execution	{}	2025-10-08 20:51:19.905353
\.


--
-- Data for Name: job_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_templates (id, name, description, user_id, service_id, reference_panel_id, input_format, build, phasing, population, is_public, usage_count, created_at, updated_at) FROM stdin;
\.


--
-- Name: file_access_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.file_access_logs_id_seq', 1, false);


--
-- Name: file_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.file_records_id_seq', 1, false);


--
-- Name: job_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.job_logs_id_seq', 1, false);


--
-- Name: job_status_updates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.job_status_updates_id_seq', 14, true);


--
-- Name: job_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.job_templates_id_seq', 1, false);


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
-- Name: imputation_jobs imputation_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.imputation_jobs
    ADD CONSTRAINT imputation_jobs_pkey PRIMARY KEY (id);


--
-- Name: job_logs job_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_logs
    ADD CONSTRAINT job_logs_pkey PRIMARY KEY (id);


--
-- Name: job_status_updates job_status_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_status_updates
    ADD CONSTRAINT job_status_updates_pkey PRIMARY KEY (id);


--
-- Name: job_templates job_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_templates
    ADD CONSTRAINT job_templates_pkey PRIMARY KEY (id);


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
-- Name: ix_imputation_jobs_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_imputation_jobs_created_at ON public.imputation_jobs USING btree (created_at);


--
-- Name: ix_imputation_jobs_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_imputation_jobs_id ON public.imputation_jobs USING btree (id);


--
-- Name: ix_imputation_jobs_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_imputation_jobs_status ON public.imputation_jobs USING btree (status);


--
-- Name: ix_imputation_jobs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_imputation_jobs_user_id ON public.imputation_jobs USING btree (user_id);


--
-- Name: ix_job_logs_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_job_logs_id ON public.job_logs USING btree (id);


--
-- Name: ix_job_logs_job_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_job_logs_job_id ON public.job_logs USING btree (job_id);


--
-- Name: ix_job_logs_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_job_logs_timestamp ON public.job_logs USING btree ("timestamp");


--
-- Name: ix_job_status_updates_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_job_status_updates_id ON public.job_status_updates USING btree (id);


--
-- Name: ix_job_status_updates_job_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_job_status_updates_job_id ON public.job_status_updates USING btree (job_id);


--
-- Name: ix_job_status_updates_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_job_status_updates_timestamp ON public.job_status_updates USING btree ("timestamp");


--
-- Name: ix_job_templates_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_job_templates_id ON public.job_templates USING btree (id);


--
-- Name: job_logs job_logs_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_logs
    ADD CONSTRAINT job_logs_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.imputation_jobs(id);


--
-- Name: job_status_updates job_status_updates_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_status_updates
    ADD CONSTRAINT job_status_updates_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.imputation_jobs(id);


--
-- PostgreSQL database dump complete
--

