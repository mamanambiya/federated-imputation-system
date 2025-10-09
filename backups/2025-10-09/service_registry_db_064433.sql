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
-- Name: imputation_services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.imputation_services (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    slug character varying(100),
    service_type character varying(50) NOT NULL,
    api_type character varying(50) NOT NULL,
    base_url character varying(500) NOT NULL,
    description text,
    version character varying(50),
    requires_auth boolean,
    auth_type character varying(50),
    max_file_size_mb integer,
    supported_formats json,
    supported_builds json,
    api_config json,
    is_active boolean,
    is_available boolean,
    last_health_check timestamp without time zone,
    health_status character varying(20),
    response_time_ms double precision,
    error_message text,
    first_unhealthy_at timestamp without time zone,
    cpu_available integer,
    cpu_total integer,
    memory_available_gb double precision,
    memory_total_gb double precision,
    storage_available_gb double precision,
    storage_total_gb double precision,
    queue_capacity integer,
    queue_current integer,
    location_country character varying(100),
    location_city character varying(100),
    location_datacenter character varying(200),
    location_latitude double precision,
    location_longitude double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.imputation_services OWNER TO postgres;

--
-- Name: imputation_services_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.imputation_services_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.imputation_services_id_seq OWNER TO postgres;

--
-- Name: imputation_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.imputation_services_id_seq OWNED BY public.imputation_services.id;


--
-- Name: reference_panels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reference_panels (
    id integer NOT NULL,
    service_id integer NOT NULL,
    name character varying(200) NOT NULL,
    slug character varying(100),
    display_name character varying(200),
    description text,
    population character varying(100),
    build character varying(20),
    samples_count integer,
    variants_count integer,
    is_available boolean,
    is_public boolean,
    requires_permission boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.reference_panels OWNER TO postgres;

--
-- Name: reference_panels_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reference_panels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.reference_panels_id_seq OWNER TO postgres;

--
-- Name: reference_panels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reference_panels_id_seq OWNED BY public.reference_panels.id;


--
-- Name: service_health_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_health_logs (
    id integer NOT NULL,
    service_id integer NOT NULL,
    status character varying(20) NOT NULL,
    response_time_ms double precision,
    error_message text,
    checked_at timestamp without time zone
);


ALTER TABLE public.service_health_logs OWNER TO postgres;

--
-- Name: service_health_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.service_health_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.service_health_logs_id_seq OWNER TO postgres;

--
-- Name: service_health_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.service_health_logs_id_seq OWNED BY public.service_health_logs.id;


--
-- Name: imputation_services id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.imputation_services ALTER COLUMN id SET DEFAULT nextval('public.imputation_services_id_seq'::regclass);


--
-- Name: reference_panels id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reference_panels ALTER COLUMN id SET DEFAULT nextval('public.reference_panels_id_seq'::regclass);


--
-- Name: service_health_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_health_logs ALTER COLUMN id SET DEFAULT nextval('public.service_health_logs_id_seq'::regclass);


--
-- Data for Name: imputation_services; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.imputation_services (id, name, slug, service_type, api_type, base_url, description, version, requires_auth, auth_type, max_file_size_mb, supported_formats, supported_builds, api_config, is_active, is_available, last_health_check, health_status, response_time_ms, error_message, first_unhealthy_at, cpu_available, cpu_total, memory_available_gb, memory_total_gb, storage_available_gb, storage_total_gb, queue_capacity, queue_current, location_country, location_city, location_datacenter, location_latitude, location_longitude, created_at, updated_at) FROM stdin;
1	H3Africa Imputation Service	h3africa-imputation-service	h3africa	michigan	https://impute.afrigen-d.org	Pan-African imputation service with African-specific reference panels	1.0	t	token	500	["vcf", "vcf.gz"]	["hg19", "hg38"]	{}	t	t	2025-10-09 06:43:34.958716	healthy	14.493	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	South Africa	Cape Town	ILiFU, University of Cape Town	-33.9249	18.4241	2025-08-04 12:51:39.700497	2025-10-09 06:43:34.959099
3	eLwazi MALI Node - Imputation Service	elwazi-mali-node---imputation-service	wes	ga4gh	http://elwazi-node.icermali.org:6000	GA4GH WES service at eLwazi Node supporting Nextflow and Snakemake workflows	\N	f	\N	500	["vcf", "vcf.gz"]	["hg19", "hg38"]	\N	t	f	2025-10-09 06:43:35.36824	unhealthy	\N	All connection attempts failed	2025-10-07 21:19:08.734231	\N	\N	\N	\N	\N	\N	\N	\N	Mali	Bamako	ICERMALI (Institut Cerba pour la Recherche Médicale en Afrique)	12.6392	-8.0029	2025-08-04 12:51:46.237638	2025-10-09 06:43:35.368764
5	eLwazi Omics Platform	elwazi-omics-platform	imputation	dnastack	https://platform.elwazi.org	eLwazi Omics Platform for genomic data analysis and imputation workflows	\N	t	token	500	["vcf", "vcf.gz"]	["hg19", "hg38"]	\N	t	f	2025-10-09 06:43:35.718066	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:19:09.063503	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2025-08-04 13:23:17.890315	2025-10-09 06:43:35.71936
2	Michigan Imputation Server	michigan-imputation-server	imputation	michigan	https://imputationserver.sph.umich.edu/	Fast and accurate genotype imputation service	1.0	t	token	500	["vcf", "vcf.gz"]	["hg19", "hg38"]	{}	f	t	2025-10-09 02:04:16.214277	healthy	852.461	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2025-08-04 12:51:39.72505	2025-10-09 02:04:16.214783
4	eLwazi ILIFU Node - Imputation Service	elwazi-ilifu-node---imputation-service	wes	ga4gh	http://ga4gh-starter-kit.ilifu.ac.za:6000	GA4GH WES starter kit deployment at ILIFU for imputation workflows	\N	f	\N	500	["vcf", "vcf.gz"]	["hg19", "hg38"]	\N	t	t	2025-10-09 06:43:34.907951	healthy	12.822	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	South Africa	Cape Town	ILiFU, University of Cape Town	-33.9249	18.4241	2025-08-04 12:51:46.262406	2025-10-09 06:43:34.90859
\.


--
-- Data for Name: reference_panels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reference_panels (id, service_id, name, slug, display_name, description, population, build, samples_count, variants_count, is_available, is_public, requires_permission, created_at, updated_at) FROM stdin;
28	2	HRC r1.1 2016	michigan-panel-1-6	HRC r1.1 2016	Haplotype Reference Consortium	Mixed	hg38	32488	39635008	t	t	f	2025-08-04 12:51:39.772389	2025-08-04 12:51:39.772402
29	2	1000G Phase 3 v5	michigan-panel-2-7	1000G Phase 3 v5	1000 Genomes Project Phase 3	Mixed	hg38	2504	49143605	t	t	f	2025-08-04 12:51:39.779209	2025-08-04 12:51:39.779222
30	2	CAAPA African American	michigan-panel-3-8	CAAPA African American	Consortium on Asthma among African-ancestry Populations	African American	hg38	883	31163897	t	t	f	2025-08-04 12:51:39.784926	2025-08-04 12:51:39.784938
35	5	African Genomics Panel	elwazi-african-v1-13	African Genomics Panel	Comprehensive African genomics reference panel	African	hg38	8000	25000000	t	t	f	2025-08-04 13:23:17.901153	2025-08-04 13:23:17.901174
36	5	Pan-African Diversity Panel	elwazi-pan-african-v2-14	Pan-African Diversity Panel	Pan-African population diversity reference panel	Pan-African	hg38	6500	22000000	t	t	f	2025-08-04 13:23:17.90803	2025-08-04 13:23:17.908043
38	1	1000G Phase 3 v5	1000g-phase3-v5	1000 Genomes Phase 3 Version 5	Global multi-ethnic reference panel with 2,504 samples from 26 populations across Europe, East Asia, South Asia, Africa, and the Americas. Contains 81,027,987 biallelic SNPs on chromosomes 1-22 and X.	Multi-ethnic	hg38	2504	81027987	t	t	f	2025-10-07 21:48:04.612564	2025-10-07 21:48:04.612564
37	1	H3AFRICA v6	apps@h3africa-v6hc-s@1.0.0	H3Africa Reference Panel v6 (Build 38)	African-specific reference panel with 4,447 samples from 22 African countries. Contains 130,028,596 biallelic SNPs across chromosomes 1-22.	African	hg38	4447	130028596	t	t	f	2025-10-07 21:48:04.612564	2025-10-07 21:48:04.612564
39	4	1000G Phase 3 v5	1000g-phase3-v5-ilifu	1000 Genomes Phase 3 v5 (hg38)	Global multi-ethnic reference panel with 2,504 samples from 26 populations across Europe, East Asia, South Asia, Africa, and the Americas. Contains 81,027,987 biallelic SNPs on chromosomes 1-22 and X. Available via WES workflow execution.	Multi-ethnic	hg38	2504	81027987	t	t	f	2025-10-09 03:19:33.391603	2025-10-09 03:19:33.391603
40	3	1000G Phase 3 v5	1000g-phase3-v5-mali	1000 Genomes Phase 3 v5 (hg38)	Global multi-ethnic reference panel with 2,504 samples from 26 populations. Available via WES workflow execution when service is online.	Multi-ethnic	hg38	2504	81027987	f	t	f	2025-10-09 03:22:47.493508	2025-10-09 03:22:47.493508
\.


--
-- Data for Name: service_health_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_health_logs (id, service_id, status, response_time_ms, error_message, checked_at) FROM stdin;
1	1	unhealthy	482.336	HTTP 404: <!DOCTYPE html>\n<html class="no-js" lang="en-US">\n\n<!-- head -->\n<head>\n\n<!-- meta -->\n<meta charset="UTF-8" />\n<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">\n<m	2025-10-07 21:19:09.074677
2	2	timeout	\N	Service health check timed out	2025-10-07 21:19:09.07468
3	3	unhealthy	\N	All connection attempts failed	2025-10-07 21:19:09.074681
4	4	unhealthy	11.370999999999999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 21:19:09.074682
5	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:19:09.074683
6	1	unhealthy	322.004	HTTP 404: <!DOCTYPE html>\n<html class="no-js" lang="en-US">\n\n<!-- head -->\n<head>\n\n<!-- meta -->\n<meta charset="UTF-8" />\n<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">\n<m	2025-10-07 21:22:04.28646
7	2	timeout	\N	Service health check timed out	2025-10-07 21:22:04.384776
8	3	unhealthy	\N	All connection attempts failed	2025-10-07 21:22:04.787813
9	4	unhealthy	10.289	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 21:22:04.821449
10	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:22:05.023106
11	1	unhealthy	465.306	HTTP 404: <!DOCTYPE html>\n<html class="no-js" lang="en-US">\n\n<!-- head -->\n<head>\n\n<!-- meta -->\n<meta charset="UTF-8" />\n<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">\n<m	2025-10-07 21:24:40.191947
12	2	timeout	\N	Service health check timed out	2025-10-07 21:24:40.19195
13	3	unhealthy	\N	All connection attempts failed	2025-10-07 21:24:40.19195
14	4	unhealthy	8.162	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 21:24:40.191951
15	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:24:40.191952
16	2	timeout	\N	Service health check timed out	2025-10-07 21:30:11.439366
17	3	unhealthy	\N	All connection attempts failed	2025-10-07 21:30:11.439369
18	4	unhealthy	10.812999999999999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 21:30:11.439369
19	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:30:11.43937
20	1	unhealthy	629.266	HTTP 404: <!DOCTYPE html>\n<html class="no-js" lang="en-US">\n\n<!-- head -->\n<head>\n\n<!-- meta -->\n<meta charset="UTF-8" />\n<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">\n<m	2025-10-07 21:30:11.439371
21	2	timeout	\N	Service health check timed out	2025-10-07 21:33:14.485952
22	1	unhealthy	608.348	HTTP 404: <!DOCTYPE html>\n<html class="no-js" lang="en-US">\n\n<!-- head -->\n<head>\n\n<!-- meta -->\n<meta charset="UTF-8" />\n<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">\n<m	2025-10-07 21:33:14.89837
23	3	unhealthy	\N	All connection attempts failed	2025-10-07 21:33:15.150796
24	4	unhealthy	8.399000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 21:33:15.18085
25	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:33:15.369282
26	1	unhealthy	445.198	HTTP 404: <!DOCTYPE html>\n<html class="no-js" lang="en-US">\n\n<!-- head -->\n<head>\n\n<!-- meta -->\n<meta charset="UTF-8" />\n<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">\n<m	2025-10-07 21:35:42.505056
27	3	unhealthy	\N	All connection attempts failed	2025-10-07 21:35:42.505059
28	4	unhealthy	7.984	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 21:35:42.50506
29	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:35:42.50506
30	2	timeout	\N	Service health check timed out	2025-10-07 21:35:42.505061
31	1	healthy	36.549	\N	2025-10-07 21:36:25.353683
32	2	timeout	\N	Service health check timed out	2025-10-07 21:37:09.397073
33	1	healthy	20.168	\N	2025-10-07 21:37:21.982626
34	2	timeout	\N	Service health check timed out	2025-10-07 21:37:22.143293
35	3	unhealthy	\N	All connection attempts failed	2025-10-07 21:37:22.221642
36	4	unhealthy	9.748	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 21:37:22.254683
37	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:37:22.292213
38	1	healthy	477.9	\N	2025-10-07 21:40:09.158949
39	2	timeout	\N	Service health check timed out	2025-10-07 21:40:39.391157
40	3	unhealthy	\N	All connection attempts failed	2025-10-07 21:40:39.706122
41	4	unhealthy	7.348000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 21:40:39.771484
42	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:40:39.808612
43	1	healthy	19.174	\N	2025-10-07 21:41:12.977842
44	2	timeout	\N	Service health check timed out	2025-10-07 21:41:12.977845
45	3	unhealthy	\N	All connection attempts failed	2025-10-07 21:41:12.977845
46	4	unhealthy	7.9030000000000005	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 21:41:12.977846
47	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:41:12.977847
48	1	healthy	21.78	\N	2025-10-07 21:44:09.246419
49	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:44:39.463458
50	2	timeout	\N	Service health check timed out	2025-10-07 21:44:39.480936
51	3	unhealthy	\N	All connection attempts failed	2025-10-07 21:44:39.710319
52	4	unhealthy	8.753	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 21:44:39.76727
53	1	healthy	17.866	\N	2025-10-07 21:46:43.652614
54	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:46:43.652616
55	2	timeout	\N	Service health check timed out	2025-10-07 21:46:43.652617
56	3	unhealthy	\N	All connection attempts failed	2025-10-07 21:46:43.652618
122	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 22:52:57.286186
123	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 22:58:28.468768
57	4	unhealthy	8.588999999999999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 21:46:43.652618
58	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:52:14.850133
59	1	healthy	176.69199999999998	\N	2025-10-07 21:52:14.850135
60	2	timeout	\N	Service health check timed out	2025-10-07 21:52:14.850136
61	3	unhealthy	\N	All connection attempts failed	2025-10-07 21:52:14.850137
62	4	unhealthy	7.176	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 21:52:14.850138
63	1	healthy	18.264	\N	2025-10-07 21:54:15.120216
64	2	timeout	\N	Service health check timed out	2025-10-07 21:54:45.345768
65	3	unhealthy	\N	All connection attempts failed	2025-10-07 21:54:45.376781
66	4	unhealthy	9.445	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 21:54:45.413492
67	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:54:45.601357
68	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 21:57:45.783047
69	1	healthy	19.147000000000002	\N	2025-10-07 21:57:45.783049
70	2	timeout	\N	Service health check timed out	2025-10-07 21:57:45.78305
71	3	unhealthy	\N	All connection attempts failed	2025-10-07 21:57:45.783051
72	4	unhealthy	7.609999999999999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 21:57:45.783052
73	1	healthy	176.99599999999998	\N	2025-10-07 22:03:16.571928
74	2	timeout	\N	Service health check timed out	2025-10-07 22:03:16.571931
75	3	unhealthy	\N	All connection attempts failed	2025-10-07 22:03:16.571932
76	4	unhealthy	6.597	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 22:03:16.571932
77	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 22:03:16.571933
78	1	healthy	17.347	\N	2025-10-07 22:08:48.390275
79	2	timeout	\N	Service health check timed out	2025-10-07 22:08:48.390278
80	3	unhealthy	\N	All connection attempts failed	2025-10-07 22:08:48.390278
81	4	unhealthy	7.792999999999999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 22:08:48.390279
82	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 22:08:48.39028
83	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 22:14:19.345191
84	1	healthy	332.086	\N	2025-10-07 22:14:19.345194
85	2	timeout	\N	Service health check timed out	2025-10-07 22:14:19.345195
86	3	unhealthy	\N	All connection attempts failed	2025-10-07 22:14:19.345196
87	4	unhealthy	10.869	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 22:14:19.345196
88	1	healthy	367.86400000000003	\N	2025-10-07 22:19:51.230316
89	2	timeout	\N	Service health check timed out	2025-10-07 22:19:51.230319
90	3	unhealthy	\N	All connection attempts failed	2025-10-07 22:19:51.23032
91	4	unhealthy	27.376	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 22:19:51.23032
92	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 22:19:51.230321
93	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 22:25:22.723785
94	1	healthy	167.53	\N	2025-10-07 22:25:22.723787
95	2	timeout	\N	Service health check timed out	2025-10-07 22:25:22.723788
96	3	unhealthy	\N	All connection attempts failed	2025-10-07 22:25:22.723789
97	4	unhealthy	6.6579999999999995	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 22:25:22.723789
98	1	healthy	20.531000000000002	\N	2025-10-07 22:30:53.44272
99	2	timeout	\N	Service health check timed out	2025-10-07 22:30:53.442722
100	3	unhealthy	\N	All connection attempts failed	2025-10-07 22:30:53.442723
101	4	unhealthy	9.19	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 22:30:53.442724
102	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 22:30:53.442724
103	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 22:36:24.379204
104	1	healthy	165.647	\N	2025-10-07 22:36:24.379207
105	2	timeout	\N	Service health check timed out	2025-10-07 22:36:24.379208
106	3	unhealthy	\N	All connection attempts failed	2025-10-07 22:36:24.379208
107	4	unhealthy	7.113	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 22:36:24.379209
108	1	healthy	174.299	\N	2025-10-07 22:41:55.581569
109	2	timeout	\N	Service health check timed out	2025-10-07 22:41:55.581571
110	3	unhealthy	\N	All connection attempts failed	2025-10-07 22:41:55.581572
111	4	unhealthy	7.047000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 22:41:55.581573
112	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 22:41:55.581574
113	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 22:47:26.536718
114	1	healthy	172.445	\N	2025-10-07 22:47:26.53672
115	2	timeout	\N	Service health check timed out	2025-10-07 22:47:26.536721
116	3	unhealthy	\N	All connection attempts failed	2025-10-07 22:47:26.536722
117	4	unhealthy	10.466	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 22:47:26.536723
118	1	healthy	17.705	\N	2025-10-07 22:52:57.286181
119	2	timeout	\N	Service health check timed out	2025-10-07 22:52:57.286184
120	3	unhealthy	\N	All connection attempts failed	2025-10-07 22:52:57.286185
121	4	unhealthy	6.726	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 22:52:57.286185
124	1	healthy	163.216	\N	2025-10-07 22:58:28.468771
125	2	timeout	\N	Service health check timed out	2025-10-07 22:58:28.468772
126	3	unhealthy	\N	All connection attempts failed	2025-10-07 22:58:28.468772
127	4	unhealthy	7.4510000000000005	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 22:58:28.468773
138	1	healthy	15.823	\N	2025-10-07 23:15:00.926806
139	2	timeout	\N	Service health check timed out	2025-10-07 23:15:00.926808
140	3	unhealthy	\N	All connection attempts failed	2025-10-07 23:15:00.926809
141	4	unhealthy	6.152	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 23:15:00.92681
142	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 23:15:00.926811
128	1	healthy	18.846	\N	2025-10-07 23:03:59.104895
129	2	timeout	\N	Service health check timed out	2025-10-07 23:03:59.104898
130	3	unhealthy	\N	All connection attempts failed	2025-10-07 23:03:59.104898
131	4	unhealthy	9.627	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 23:03:59.104899
132	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 23:03:59.1049
143	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 23:20:32.031447
144	1	healthy	322.649	\N	2025-10-07 23:20:32.031449
145	2	timeout	\N	Service health check timed out	2025-10-07 23:20:32.03145
146	3	unhealthy	\N	All connection attempts failed	2025-10-07 23:20:32.031451
147	4	unhealthy	9.304	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 23:20:32.031452
158	1	healthy	17.607999999999997	\N	2025-10-07 23:37:04.88142
159	2	timeout	\N	Service health check timed out	2025-10-07 23:37:04.881423
160	3	unhealthy	\N	All connection attempts failed	2025-10-07 23:37:04.881423
161	4	unhealthy	9.303	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 23:37:04.881424
162	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 23:37:04.881425
173	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 23:53:38.732896
174	1	healthy	169.766	\N	2025-10-07 23:53:38.732898
175	2	timeout	\N	Service health check timed out	2025-10-07 23:53:38.732899
176	3	unhealthy	\N	All connection attempts failed	2025-10-07 23:53:38.7329
177	4	unhealthy	9.004	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 23:53:38.732901
133	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 23:09:30.044843
134	1	healthy	170.687	\N	2025-10-07 23:09:30.044846
135	2	timeout	\N	Service health check timed out	2025-10-07 23:09:30.044846
136	3	unhealthy	\N	All connection attempts failed	2025-10-07 23:09:30.044847
137	4	unhealthy	7.155	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 23:09:30.044848
148	1	healthy	25.215	\N	2025-10-07 23:26:02.892516
149	2	timeout	\N	Service health check timed out	2025-10-07 23:26:02.892519
150	3	unhealthy	\N	All connection attempts failed	2025-10-07 23:26:02.89252
151	4	unhealthy	7.702	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 23:26:02.892521
152	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 23:26:02.892521
153	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 23:31:34.242908
154	1	healthy	172.08499999999998	\N	2025-10-07 23:31:34.24291
155	2	timeout	\N	Service health check timed out	2025-10-07 23:31:34.242911
156	3	unhealthy	\N	All connection attempts failed	2025-10-07 23:31:34.242911
157	4	unhealthy	7.033	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 23:31:34.242912
163	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 23:42:36.464992
164	1	healthy	680.275	\N	2025-10-07 23:42:36.464995
165	2	timeout	\N	Service health check timed out	2025-10-07 23:42:36.464996
166	3	unhealthy	\N	All connection attempts failed	2025-10-07 23:42:36.464996
167	4	unhealthy	8.266	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 23:42:36.464997
168	1	healthy	19.86	\N	2025-10-07 23:48:07.606679
169	2	timeout	\N	Service health check timed out	2025-10-07 23:48:07.606682
170	3	unhealthy	\N	All connection attempts failed	2025-10-07 23:48:07.606682
171	4	unhealthy	6.832999999999999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 23:48:07.606683
172	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 23:48:07.606684
178	1	healthy	16.887	\N	2025-10-07 23:59:09.358431
179	2	timeout	\N	Service health check timed out	2025-10-07 23:59:09.358434
180	3	unhealthy	\N	All connection attempts failed	2025-10-07 23:59:09.358435
181	4	unhealthy	7.127	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-07 23:59:09.358435
182	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-07 23:59:09.358436
183	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 00:04:40.920551
184	1	healthy	165.328	\N	2025-10-08 00:04:40.920553
185	2	timeout	\N	Service health check timed out	2025-10-08 00:04:40.920554
186	3	unhealthy	\N	All connection attempts failed	2025-10-08 00:04:40.920555
187	4	unhealthy	6.928	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 00:04:40.920555
188	1	healthy	16.026	\N	2025-10-08 00:10:11.548541
189	2	timeout	\N	Service health check timed out	2025-10-08 00:10:11.548543
190	3	unhealthy	\N	All connection attempts failed	2025-10-08 00:10:11.548544
923	1	healthy	38.639	\N	2025-10-09 06:27:33.106205
191	4	unhealthy	8.606000000000002	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 00:10:11.548545
192	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 00:10:11.548545
193	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 00:15:42.494417
194	1	healthy	172.91400000000002	\N	2025-10-08 00:15:42.49442
195	2	timeout	\N	Service health check timed out	2025-10-08 00:15:42.494421
196	3	unhealthy	\N	All connection attempts failed	2025-10-08 00:15:42.494421
197	4	unhealthy	7.757	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 00:15:42.494422
198	1	healthy	18.196	\N	2025-10-08 00:21:13.529793
199	2	timeout	\N	Service health check timed out	2025-10-08 00:21:13.529795
200	3	unhealthy	\N	All connection attempts failed	2025-10-08 00:21:13.529796
201	4	unhealthy	7.358	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 00:21:13.529797
202	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 00:21:13.529798
203	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 00:26:44.625739
204	1	healthy	169.685	\N	2025-10-08 00:26:44.625742
205	2	timeout	\N	Service health check timed out	2025-10-08 00:26:44.625742
206	3	unhealthy	\N	All connection attempts failed	2025-10-08 00:26:44.625743
207	4	unhealthy	9.572000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 00:26:44.625744
208	1	healthy	17.006	\N	2025-10-08 00:32:15.251692
209	2	timeout	\N	Service health check timed out	2025-10-08 00:32:15.251694
210	3	unhealthy	\N	All connection attempts failed	2025-10-08 00:32:15.251695
211	4	unhealthy	8.899000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 00:32:15.251696
212	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 00:32:15.251696
213	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 00:37:47.56879
214	1	healthy	169.046	\N	2025-10-08 00:37:47.568793
215	2	timeout	\N	Service health check timed out	2025-10-08 00:37:47.568794
216	3	unhealthy	\N	All connection attempts failed	2025-10-08 00:37:47.568794
217	4	unhealthy	6.697	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 00:37:47.568795
218	1	healthy	171.574	\N	2025-10-08 00:43:18.359731
219	2	timeout	\N	Service health check timed out	2025-10-08 00:43:18.359734
228	1	healthy	19.694	\N	2025-10-08 00:54:20.498309
220	3	unhealthy	\N	All connection attempts failed	2025-10-08 00:43:18.359735
221	4	unhealthy	11.617	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 00:43:18.359735
222	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 00:43:18.359736
233	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 00:59:51.751679
234	1	healthy	172.201	\N	2025-10-08 00:59:51.751682
235	2	timeout	\N	Service health check timed out	2025-10-08 00:59:51.751683
236	3	unhealthy	\N	All connection attempts failed	2025-10-08 00:59:51.751683
237	4	unhealthy	8.561	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 00:59:51.751684
223	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 00:48:49.612166
224	1	healthy	483.093	\N	2025-10-08 00:48:49.612169
225	2	timeout	\N	Service health check timed out	2025-10-08 00:48:49.612169
226	3	unhealthy	\N	All connection attempts failed	2025-10-08 00:48:49.61217
227	4	unhealthy	6.473999999999999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 00:48:49.612171
238	1	healthy	20.102999999999998	\N	2025-10-08 01:05:22.387232
239	2	timeout	\N	Service health check timed out	2025-10-08 01:05:22.387235
240	3	unhealthy	\N	All connection attempts failed	2025-10-08 01:05:22.387235
241	4	unhealthy	7.405	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 01:05:22.387236
242	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 01:05:22.387237
229	2	timeout	\N	Service health check timed out	2025-10-08 00:54:20.498311
230	3	unhealthy	\N	All connection attempts failed	2025-10-08 00:54:20.498312
231	4	unhealthy	7.636	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 00:54:20.498313
232	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 00:54:20.498313
243	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 01:10:54.442223
244	1	healthy	163.356	\N	2025-10-08 01:10:54.442226
245	2	timeout	\N	Service health check timed out	2025-10-08 01:10:54.442226
246	3	unhealthy	\N	All connection attempts failed	2025-10-08 01:10:54.442227
247	4	unhealthy	6.308	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 01:10:54.442228
248	1	healthy	18.301000000000002	\N	2025-10-08 01:16:25.073483
249	2	timeout	\N	Service health check timed out	2025-10-08 01:16:25.073486
250	3	unhealthy	\N	All connection attempts failed	2025-10-08 01:16:25.073487
251	4	unhealthy	8.942	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 01:16:25.073487
252	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 01:16:25.073488
253	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 01:21:56.014362
254	1	healthy	169.659	\N	2025-10-08 01:21:56.014365
255	2	timeout	\N	Service health check timed out	2025-10-08 01:21:56.014366
256	3	unhealthy	\N	All connection attempts failed	2025-10-08 01:21:56.014367
452	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 04:57:04.923141
257	4	unhealthy	9.222	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 01:21:56.014367
258	1	healthy	17.584	\N	2025-10-08 01:27:27.057091
259	2	timeout	\N	Service health check timed out	2025-10-08 01:27:27.057094
260	3	unhealthy	\N	All connection attempts failed	2025-10-08 01:27:27.057095
261	4	unhealthy	6.848	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 01:27:27.057095
262	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 01:27:27.057096
263	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 01:32:58.157254
264	1	healthy	323.57099999999997	\N	2025-10-08 01:32:58.157256
265	2	timeout	\N	Service health check timed out	2025-10-08 01:32:58.157257
266	3	unhealthy	\N	All connection attempts failed	2025-10-08 01:32:58.157258
267	4	unhealthy	9.314	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 01:32:58.157258
268	1	healthy	15.76	\N	2025-10-08 01:38:28.785822
269	2	timeout	\N	Service health check timed out	2025-10-08 01:38:28.785824
270	3	unhealthy	\N	All connection attempts failed	2025-10-08 01:38:28.785825
271	4	unhealthy	7.842	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 01:38:28.785826
272	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 01:38:28.785826
273	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 01:44:00.90728
274	1	healthy	172.346	\N	2025-10-08 01:44:00.907282
275	2	timeout	\N	Service health check timed out	2025-10-08 01:44:00.907283
276	3	unhealthy	\N	All connection attempts failed	2025-10-08 01:44:00.907284
277	4	unhealthy	6.857	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 01:44:00.907284
278	1	healthy	16.918	\N	2025-10-08 01:49:31.538132
279	2	timeout	\N	Service health check timed out	2025-10-08 01:49:31.538134
280	3	unhealthy	\N	All connection attempts failed	2025-10-08 01:49:31.538135
281	4	unhealthy	8.529	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 01:49:31.538136
282	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 01:49:31.538137
283	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 01:55:02.505555
284	1	healthy	168.041	\N	2025-10-08 01:55:02.505558
285	2	timeout	\N	Service health check timed out	2025-10-08 01:55:02.505559
286	3	unhealthy	\N	All connection attempts failed	2025-10-08 01:55:02.50556
287	4	unhealthy	7.25	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 01:55:02.50556
288	1	healthy	19.903000000000002	\N	2025-10-08 02:00:33.394367
289	2	timeout	\N	Service health check timed out	2025-10-08 02:00:33.394369
290	3	unhealthy	\N	All connection attempts failed	2025-10-08 02:00:33.39437
291	4	unhealthy	6.893	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 02:00:33.394371
292	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 02:00:33.394371
293	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 02:06:04.37706
294	1	healthy	18.44	\N	2025-10-08 02:06:04.377063
295	2	timeout	\N	Service health check timed out	2025-10-08 02:06:04.377064
296	3	unhealthy	\N	All connection attempts failed	2025-10-08 02:06:04.377064
297	4	unhealthy	9.885	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 02:06:04.377065
298	1	healthy	19.291	\N	2025-10-08 02:11:35.009892
299	2	timeout	\N	Service health check timed out	2025-10-08 02:11:35.009894
300	3	unhealthy	\N	All connection attempts failed	2025-10-08 02:11:35.009895
301	4	unhealthy	7.055	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 02:11:35.009896
302	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 02:11:35.009897
303	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 02:17:06.977682
304	1	healthy	169.274	\N	2025-10-08 02:17:06.977685
305	2	timeout	\N	Service health check timed out	2025-10-08 02:17:06.977686
306	3	unhealthy	\N	All connection attempts failed	2025-10-08 02:17:06.977687
307	4	unhealthy	6.877000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 02:17:06.977687
318	1	healthy	14.735	\N	2025-10-08 02:33:39.590221
319	2	timeout	\N	Service health check timed out	2025-10-08 02:33:39.590224
320	3	unhealthy	\N	All connection attempts failed	2025-10-08 02:33:39.590225
321	4	unhealthy	7.7669999999999995	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 02:33:39.590225
322	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 02:33:39.590226
308	1	healthy	18.25	\N	2025-10-08 02:22:37.615934
309	2	timeout	\N	Service health check timed out	2025-10-08 02:22:37.615937
310	3	unhealthy	\N	All connection attempts failed	2025-10-08 02:22:37.615938
311	4	unhealthy	8.892000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 02:22:37.615938
312	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 02:22:37.615939
313	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 02:28:08.711268
314	1	healthy	168.90800000000002	\N	2025-10-08 02:28:08.71127
315	2	timeout	\N	Service health check timed out	2025-10-08 02:28:08.711271
316	3	unhealthy	\N	All connection attempts failed	2025-10-08 02:28:08.711272
453	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 05:02:36.272452
454	1	healthy	165.293	\N	2025-10-08 05:02:36.272454
317	4	unhealthy	6.844	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 02:28:08.711273
323	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 02:39:10.672724
324	1	healthy	318.701	\N	2025-10-08 02:39:10.672726
325	2	timeout	\N	Service health check timed out	2025-10-08 02:39:10.672727
326	3	unhealthy	\N	All connection attempts failed	2025-10-08 02:39:10.672728
327	4	unhealthy	8.938	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 02:39:10.672728
328	1	healthy	170.974	\N	2025-10-08 02:44:41.453281
329	2	timeout	\N	Service health check timed out	2025-10-08 02:44:41.453283
330	3	unhealthy	\N	All connection attempts failed	2025-10-08 02:44:41.453284
331	4	unhealthy	6.2059999999999995	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 02:44:41.453285
332	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 02:44:41.453285
333	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 02:50:12.788968
334	1	healthy	169.86200000000002	\N	2025-10-08 02:50:12.78897
335	2	timeout	\N	Service health check timed out	2025-10-08 02:50:12.788971
336	3	unhealthy	\N	All connection attempts failed	2025-10-08 02:50:12.788972
337	4	unhealthy	7.2700000000000005	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 02:50:12.788972
338	1	healthy	17.073999999999998	\N	2025-10-08 02:55:43.430628
339	2	timeout	\N	Service health check timed out	2025-10-08 02:55:43.43063
340	3	unhealthy	\N	All connection attempts failed	2025-10-08 02:55:43.430631
341	4	unhealthy	9.418	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 02:55:43.430632
342	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 02:55:43.430632
343	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 03:01:14.371504
344	1	healthy	168.87	\N	2025-10-08 03:01:14.371506
345	2	timeout	\N	Service health check timed out	2025-10-08 03:01:14.371507
346	3	unhealthy	\N	All connection attempts failed	2025-10-08 03:01:14.371508
347	4	unhealthy	6.436	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 03:01:14.371508
348	1	healthy	15.827	\N	2025-10-08 03:06:45.986284
349	2	timeout	\N	Service health check timed out	2025-10-08 03:06:45.986286
350	3	unhealthy	\N	All connection attempts failed	2025-10-08 03:06:45.986287
351	4	unhealthy	6.774	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 03:06:45.986287
352	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 03:06:45.986288
353	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 03:12:16.931697
354	1	healthy	173.93200000000002	\N	2025-10-08 03:12:16.931699
355	2	timeout	\N	Service health check timed out	2025-10-08 03:12:16.9317
356	3	unhealthy	\N	All connection attempts failed	2025-10-08 03:12:16.9317
357	4	unhealthy	8.964	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 03:12:16.931701
358	1	healthy	15.942000000000002	\N	2025-10-08 03:17:47.558862
359	2	timeout	\N	Service health check timed out	2025-10-08 03:17:47.558864
360	3	unhealthy	\N	All connection attempts failed	2025-10-08 03:17:47.558865
361	4	unhealthy	6.255	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 03:17:47.558865
362	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 03:17:47.558866
363	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 03:23:18.750488
364	1	healthy	165.866	\N	2025-10-08 03:23:18.750491
365	2	timeout	\N	Service health check timed out	2025-10-08 03:23:18.750492
366	3	unhealthy	\N	All connection attempts failed	2025-10-08 03:23:18.750493
367	4	unhealthy	9.548	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 03:23:18.750493
368	1	healthy	20.154999999999998	\N	2025-10-08 03:28:49.630905
369	2	timeout	\N	Service health check timed out	2025-10-08 03:28:49.630907
370	3	unhealthy	\N	All connection attempts failed	2025-10-08 03:28:49.630908
371	4	unhealthy	9.232000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 03:28:49.630909
372	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 03:28:49.630909
373	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 03:34:20.562318
374	1	healthy	165.043	\N	2025-10-08 03:34:20.562321
375	2	timeout	\N	Service health check timed out	2025-10-08 03:34:20.562322
376	3	unhealthy	\N	All connection attempts failed	2025-10-08 03:34:20.562323
377	4	unhealthy	6.989999999999999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 03:34:20.562323
378	1	healthy	16.621	\N	2025-10-08 03:39:51.682648
379	2	timeout	\N	Service health check timed out	2025-10-08 03:39:51.682651
380	3	unhealthy	\N	All connection attempts failed	2025-10-08 03:39:51.682652
381	4	unhealthy	7.4079999999999995	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 03:39:51.682652
382	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 03:39:51.682653
383	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 03:45:22.921409
384	1	healthy	472.12100000000004	\N	2025-10-08 03:45:22.921411
388	1	healthy	16.633	\N	2025-10-08 03:50:53.550779
385	2	timeout	\N	Service health check timed out	2025-10-08 03:45:22.921412
386	3	unhealthy	\N	All connection attempts failed	2025-10-08 03:45:22.921412
455	2	timeout	\N	Service health check timed out	2025-10-08 05:02:36.272455
387	4	unhealthy	8.456	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 03:45:22.921413
398	1	healthy	15.258000000000001	\N	2025-10-08 04:01:55.511775
399	2	timeout	\N	Service health check timed out	2025-10-08 04:01:55.511777
400	3	unhealthy	\N	All connection attempts failed	2025-10-08 04:01:55.511778
401	4	unhealthy	8.999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 04:01:55.511778
402	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 04:01:55.511779
389	2	timeout	\N	Service health check timed out	2025-10-08 03:50:53.550782
390	3	unhealthy	\N	All connection attempts failed	2025-10-08 03:50:53.550782
391	4	unhealthy	7.967999999999999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 03:50:53.550783
392	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 03:50:53.550784
403	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 04:07:26.584405
404	1	healthy	166.719	\N	2025-10-08 04:07:26.584408
405	2	timeout	\N	Service health check timed out	2025-10-08 04:07:26.584408
406	3	unhealthy	\N	All connection attempts failed	2025-10-08 04:07:26.584409
407	4	unhealthy	7.39	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 04:07:26.58441
393	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 03:56:24.879268
394	1	healthy	168.089	\N	2025-10-08 03:56:24.87927
395	2	timeout	\N	Service health check timed out	2025-10-08 03:56:24.879271
396	3	unhealthy	\N	All connection attempts failed	2025-10-08 03:56:24.879271
397	4	unhealthy	6.5040000000000004	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 03:56:24.879272
408	1	healthy	20.589	\N	2025-10-08 04:12:57.46457
409	2	timeout	\N	Service health check timed out	2025-10-08 04:12:57.464572
410	3	unhealthy	\N	All connection attempts failed	2025-10-08 04:12:57.464573
411	4	unhealthy	6.757	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 04:12:57.464574
412	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 04:12:57.464574
413	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 04:18:28.405795
414	1	healthy	164.524	\N	2025-10-08 04:18:28.405798
415	2	timeout	\N	Service health check timed out	2025-10-08 04:18:28.405799
416	3	unhealthy	\N	All connection attempts failed	2025-10-08 04:18:28.405799
417	4	unhealthy	9.414	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 04:18:28.4058
418	1	healthy	16.121	\N	2025-10-08 04:23:59.033838
419	2	timeout	\N	Service health check timed out	2025-10-08 04:23:59.033841
420	3	unhealthy	\N	All connection attempts failed	2025-10-08 04:23:59.033841
421	4	unhealthy	6.558	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 04:23:59.033842
422	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 04:23:59.033843
423	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 04:29:30.412338
424	1	healthy	172.822	\N	2025-10-08 04:29:30.412341
425	2	timeout	\N	Service health check timed out	2025-10-08 04:29:30.412341
426	3	unhealthy	\N	All connection attempts failed	2025-10-08 04:29:30.412342
427	4	unhealthy	7.974	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 04:29:30.412343
428	1	healthy	17.243000000000002	\N	2025-10-08 04:35:01.045926
429	2	timeout	\N	Service health check timed out	2025-10-08 04:35:01.045929
430	3	unhealthy	\N	All connection attempts failed	2025-10-08 04:35:01.04593
431	4	unhealthy	9.534	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 04:35:01.045931
432	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 04:35:01.045932
433	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 04:40:31.985854
434	1	healthy	171.732	\N	2025-10-08 04:40:31.985856
435	2	timeout	\N	Service health check timed out	2025-10-08 04:40:31.985857
436	3	unhealthy	\N	All connection attempts failed	2025-10-08 04:40:31.985858
437	4	unhealthy	6.946	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 04:40:31.985858
438	1	healthy	323.398	\N	2025-10-08 04:46:03.350723
439	2	timeout	\N	Service health check timed out	2025-10-08 04:46:03.350726
440	3	unhealthy	\N	All connection attempts failed	2025-10-08 04:46:03.350726
441	4	unhealthy	6.867	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 04:46:03.350727
442	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 04:46:03.350728
443	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 04:51:34.295762
444	1	healthy	170.571	\N	2025-10-08 04:51:34.295764
445	2	timeout	\N	Service health check timed out	2025-10-08 04:51:34.295765
446	3	unhealthy	\N	All connection attempts failed	2025-10-08 04:51:34.295766
447	4	unhealthy	10.565	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 04:51:34.295766
448	1	healthy	16.218	\N	2025-10-08 04:57:04.923137
449	2	timeout	\N	Service health check timed out	2025-10-08 04:57:04.923139
450	3	unhealthy	\N	All connection attempts failed	2025-10-08 04:57:04.92314
451	4	unhealthy	6.612	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 04:57:04.923141
638	1	healthy	14.446	\N	2025-10-08 19:18:22.738484
456	3	unhealthy	\N	All connection attempts failed	2025-10-08 05:02:36.272455
457	4	unhealthy	6.889	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 05:02:36.272456
458	1	healthy	15.844000000000001	\N	2025-10-08 05:08:06.897867
459	2	timeout	\N	Service health check timed out	2025-10-08 05:08:06.897869
460	3	unhealthy	\N	All connection attempts failed	2025-10-08 05:08:06.89787
461	4	unhealthy	8.747	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 05:08:06.897871
462	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 05:08:06.897872
463	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 05:13:37.825916
464	1	healthy	165.697	\N	2025-10-08 05:13:37.825919
465	2	timeout	\N	Service health check timed out	2025-10-08 05:13:37.82592
466	3	unhealthy	\N	All connection attempts failed	2025-10-08 05:13:37.82592
467	4	unhealthy	7.664	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 05:13:37.825921
468	1	healthy	19.238000000000003	\N	2025-10-08 05:19:08.703389
469	2	timeout	\N	Service health check timed out	2025-10-08 05:19:08.703391
478	1	healthy	20.615000000000002	\N	2025-10-08 05:30:10.438709
470	3	unhealthy	\N	All connection attempts failed	2025-10-08 05:19:08.703392
471	4	unhealthy	6.985	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 05:19:08.703392
472	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 05:19:08.703393
483	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 05:35:41.816141
484	1	healthy	171.186	\N	2025-10-08 05:35:41.816143
485	2	timeout	\N	Service health check timed out	2025-10-08 05:35:41.816144
486	3	unhealthy	\N	All connection attempts failed	2025-10-08 05:35:41.816145
487	4	unhealthy	7.039	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 05:35:41.816145
498	1	healthy	16.451	\N	2025-10-08 05:52:14.698736
499	2	timeout	\N	Service health check timed out	2025-10-08 05:52:14.698739
500	3	unhealthy	\N	All connection attempts failed	2025-10-08 05:52:14.69874
501	4	unhealthy	7.154	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 05:52:14.698741
502	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 05:52:14.698741
473	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 05:24:39.646976
474	1	healthy	165.465	\N	2025-10-08 05:24:39.646979
475	2	timeout	\N	Service health check timed out	2025-10-08 05:24:39.646979
476	3	unhealthy	\N	All connection attempts failed	2025-10-08 05:24:39.64698
477	4	unhealthy	9.588	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 05:24:39.646981
488	1	healthy	24.163	\N	2025-10-08 05:41:12.45716
489	2	timeout	\N	Service health check timed out	2025-10-08 05:41:12.457162
490	3	unhealthy	\N	All connection attempts failed	2025-10-08 05:41:12.457163
491	4	unhealthy	9.880999999999998	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 05:41:12.457164
492	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 05:41:12.457165
479	2	timeout	\N	Service health check timed out	2025-10-08 05:30:10.438711
480	3	unhealthy	\N	All connection attempts failed	2025-10-08 05:30:10.438712
481	4	unhealthy	7.864	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 05:30:10.438712
482	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 05:30:10.438713
493	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 05:46:43.619948
494	1	healthy	316.85400000000004	\N	2025-10-08 05:46:43.619951
495	2	timeout	\N	Service health check timed out	2025-10-08 05:46:43.619952
496	3	unhealthy	\N	All connection attempts failed	2025-10-08 05:46:43.619952
497	4	unhealthy	6.959	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 05:46:43.619953
503	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 05:57:45.641911
504	1	healthy	170.09	\N	2025-10-08 05:57:45.641914
505	2	timeout	\N	Service health check timed out	2025-10-08 05:57:45.641915
506	3	unhealthy	\N	All connection attempts failed	2025-10-08 05:57:45.641915
507	4	unhealthy	9.402000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 05:57:45.641916
508	1	healthy	212.709	\N	2025-10-08 17:20:27.732924
509	2	timeout	\N	Service health check timed out	2025-10-08 17:20:27.732926
510	3	unhealthy	\N	All connection attempts failed	2025-10-08 17:20:27.732928
511	4	unhealthy	29.593	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 17:20:27.732929
512	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 17:20:27.732929
513	1	healthy	26.471999999999998	\N	2025-10-08 17:20:46.949154
514	2	timeout	\N	Service health check timed out	2025-10-08 17:21:17.450828
515	3	unhealthy	\N	All connection attempts failed	2025-10-08 17:21:17.649708
516	4	unhealthy	11.913	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 17:21:17.693998
517	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 17:21:17.888999
518	1	healthy	20.212999999999997	\N	2025-10-08 17:25:58.39538
519	2	timeout	\N	Service health check timed out	2025-10-08 17:25:58.395382
520	3	unhealthy	\N	All connection attempts failed	2025-10-08 17:25:58.395383
528	1	healthy	18.053	\N	2025-10-08 17:35:29.06035
529	2	timeout	\N	Service health check timed out	2025-10-08 17:35:59.318647
539	1	healthy	353.80699999999996	\N	2025-10-08 17:44:54.84891
521	4	unhealthy	7.962999999999999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 17:25:58.395383
522	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 17:25:58.395384
523	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 17:31:29.07732
524	1	healthy	18.808	\N	2025-10-08 17:31:29.077322
525	2	timeout	\N	Service health check timed out	2025-10-08 17:31:29.077323
526	3	unhealthy	\N	All connection attempts failed	2025-10-08 17:31:29.077324
527	4	unhealthy	14.361	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 17:31:29.077324
530	3	unhealthy	\N	All connection attempts failed	2025-10-08 17:35:59.430117
531	4	unhealthy	11.969999999999999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 17:35:59.525234
532	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 17:35:59.760335
533	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 17:39:23.838287
534	1	healthy	87.275	\N	2025-10-08 17:39:23.83829
535	2	timeout	\N	Service health check timed out	2025-10-08 17:39:23.838291
536	3	unhealthy	\N	All connection attempts failed	2025-10-08 17:39:23.838291
537	4	unhealthy	156.736	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 17:39:23.838292
538	1	healthy	14.149000000000001	\N	2025-10-08 17:44:35.320265
544	2	timeout	\N	Service health check timed out	2025-10-08 17:45:05.678217
548	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 17:50:25.679171
549	1	healthy	17.526	\N	2025-10-08 17:50:25.679174
550	2	timeout	\N	Service health check timed out	2025-10-08 17:50:25.679174
551	3	unhealthy	\N	All connection attempts failed	2025-10-08 17:50:25.679175
552	4	unhealthy	13.116	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 17:50:25.679176
563	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 18:06:58.377437
564	1	healthy	165.118	\N	2025-10-08 18:06:58.37744
565	2	timeout	\N	Service health check timed out	2025-10-08 18:06:58.377441
566	3	unhealthy	\N	All connection attempts failed	2025-10-08 18:06:58.377441
567	4	unhealthy	6.971	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 18:06:58.377442
578	1	healthy	173.292	\N	2025-10-08 18:23:31.650761
579	2	timeout	\N	Service health check timed out	2025-10-08 18:23:31.650764
580	3	unhealthy	\N	All connection attempts failed	2025-10-08 18:23:31.650764
581	4	unhealthy	7.941	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 18:23:31.650765
582	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 18:23:31.650766
584	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 18:25:42.893699
588	1	healthy	168.064	\N	2025-10-08 18:29:02.701557
589	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 18:29:02.70156
590	2	timeout	\N	Service health check timed out	2025-10-08 18:29:02.701561
591	3	unhealthy	\N	All connection attempts failed	2025-10-08 18:29:02.701561
592	4	unhealthy	11.499	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 18:29:02.701562
593	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 18:34:33.48806
594	1	healthy	16.458000000000002	\N	2025-10-08 18:34:33.488063
595	2	timeout	\N	Service health check timed out	2025-10-08 18:34:33.488064
596	3	unhealthy	\N	All connection attempts failed	2025-10-08 18:34:33.488065
597	4	unhealthy	7.244	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 18:34:33.488065
608	1	healthy	336.894	\N	2025-10-08 18:51:06.591877
609	2	timeout	\N	Service health check timed out	2025-10-08 18:51:06.591879
610	3	unhealthy	\N	All connection attempts failed	2025-10-08 18:51:06.59188
611	4	unhealthy	7.318	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 18:51:06.591881
612	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 18:51:06.591881
540	2	timeout	\N	Service health check timed out	2025-10-08 17:44:54.848913
541	3	unhealthy	\N	All connection attempts failed	2025-10-08 17:44:54.848914
542	4	unhealthy	7.927999999999999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 17:44:54.848914
543	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 17:44:54.848915
545	3	unhealthy	\N	All connection attempts failed	2025-10-08 17:45:05.799696
546	4	unhealthy	8.072	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 17:45:05.881515
547	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 17:45:06.073068
553	1	healthy	56.785000000000004	\N	2025-10-08 17:55:56.646347
554	2	timeout	\N	Service health check timed out	2025-10-08 17:55:56.64635
555	3	unhealthy	\N	All connection attempts failed	2025-10-08 17:55:56.646351
556	4	unhealthy	12.600999999999999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 17:55:56.646351
557	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 17:55:56.646352
558	1	healthy	17.825	\N	2025-10-08 18:01:27.442502
559	2	timeout	\N	Service health check timed out	2025-10-08 18:01:27.44255
560	3	unhealthy	\N	All connection attempts failed	2025-10-08 18:01:27.442551
561	4	unhealthy	8.207	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 18:01:27.442552
562	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 18:01:27.442553
568	1	healthy	18.933	\N	2025-10-08 18:12:29.434626
569	2	timeout	\N	Service health check timed out	2025-10-08 18:12:29.434629
570	3	unhealthy	\N	All connection attempts failed	2025-10-08 18:12:29.43463
571	4	unhealthy	9.582	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 18:12:29.434631
572	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 18:12:29.434632
573	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 18:18:00.373275
574	1	healthy	174.05499999999998	\N	2025-10-08 18:18:00.373277
575	2	timeout	\N	Service health check timed out	2025-10-08 18:18:00.373278
576	3	unhealthy	\N	All connection attempts failed	2025-10-08 18:18:00.373279
577	4	unhealthy	7.016	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 18:18:00.37328
583	1	healthy	17.284999999999997	\N	2025-10-08 18:25:12.643723
585	2	timeout	\N	Service health check timed out	2025-10-08 18:25:42.912639
586	3	unhealthy	\N	All connection attempts failed	2025-10-08 18:25:43.172286
587	4	unhealthy	8.002	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 18:25:43.204966
598	1	healthy	167.442	\N	2025-10-08 18:40:04.429741
599	2	timeout	\N	Service health check timed out	2025-10-08 18:40:04.429744
600	3	unhealthy	\N	All connection attempts failed	2025-10-08 18:40:04.429745
601	4	unhealthy	8.364999999999998	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 18:40:04.429746
602	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 18:40:04.429747
603	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 18:45:35.480837
604	1	healthy	17.03	\N	2025-10-08 18:45:35.48084
605	2	timeout	\N	Service health check timed out	2025-10-08 18:45:35.480841
606	3	unhealthy	\N	All connection attempts failed	2025-10-08 18:45:35.480841
607	4	unhealthy	10.952	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 18:45:35.480842
613	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 18:56:37.397789
614	1	healthy	16.394	\N	2025-10-08 18:56:37.397791
615	2	timeout	\N	Service health check timed out	2025-10-08 18:56:37.397792
616	3	unhealthy	\N	All connection attempts failed	2025-10-08 18:56:37.397793
617	4	unhealthy	8.234	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 18:56:37.397793
618	1	healthy	483.074	\N	2025-10-08 19:02:09.682684
619	2	timeout	\N	Service health check timed out	2025-10-08 19:02:09.682687
620	3	unhealthy	\N	All connection attempts failed	2025-10-08 19:02:09.682688
621	4	unhealthy	11.296000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 19:02:09.682689
622	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 19:02:09.682689
623	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 19:07:40.534773
624	1	healthy	26.294999999999998	\N	2025-10-08 19:07:40.534776
625	2	timeout	\N	Service health check timed out	2025-10-08 19:07:40.534777
626	3	unhealthy	\N	All connection attempts failed	2025-10-08 19:07:40.534777
627	4	unhealthy	11.834000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 19:07:40.534778
628	1	healthy	169.324	\N	2025-10-08 19:12:39.14292
629	2	timeout	\N	Service health check timed out	2025-10-08 19:13:09.505666
630	3	unhealthy	\N	All connection attempts failed	2025-10-08 19:13:09.884339
631	4	unhealthy	8.494	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 19:13:10.434151
632	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 19:13:10.99832
633	2	timeout	\N	Service health check timed out	2025-10-08 19:13:11.026056
634	3	unhealthy	\N	All connection attempts failed	2025-10-08 19:13:11.026058
635	4	unhealthy	7.01	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 19:13:11.026059
636	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 19:13:11.02606
637	1	healthy	26.511	\N	2025-10-08 19:13:11.02606
639	1	healthy	20.119	\N	2025-10-08 19:18:42.086265
640	2	timeout	\N	Service health check timed out	2025-10-08 19:18:42.086268
641	3	unhealthy	\N	All connection attempts failed	2025-10-08 19:18:42.086269
642	4	unhealthy	29.57	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 19:18:42.08627
643	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 19:18:42.08627
646	4	unhealthy	6.685	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 19:18:53.157082
650	2	timeout	\N	Service health check timed out	2025-10-08 19:19:53.373815
644	2	timeout	\N	Service health check timed out	2025-10-08 19:18:53.076598
647	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 19:18:53.196177
652	4	unhealthy	9.605	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 19:19:53.552399
645	3	unhealthy	\N	All connection attempts failed	2025-10-08 19:18:53.122174
648	1	healthy	15.935999999999998	\N	2025-10-08 19:19:23.13144
649	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 19:19:53.220081
651	3	unhealthy	\N	All connection attempts failed	2025-10-08 19:19:53.486731
653	1	healthy	23.86	\N	2025-10-08 19:26:49.035075
654	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 19:26:49.035078
655	2	timeout	\N	Service health check timed out	2025-10-08 19:26:49.035079
656	3	unhealthy	\N	All connection attempts failed	2025-10-08 19:26:49.03508
657	4	unhealthy	12.093	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 19:26:49.035081
658	1	healthy	16.441000000000003	\N	2025-10-08 19:28:00.65347
659	2	timeout	\N	Service health check timed out	2025-10-08 19:28:00.653473
660	3	unhealthy	\N	All connection attempts failed	2025-10-08 19:28:00.653474
661	4	unhealthy	10.927	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 19:28:00.653474
662	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 19:28:00.653475
663	1	healthy	15.802	\N	2025-10-08 19:40:29.809161
664	1	healthy	28.472	\N	2025-10-08 19:40:49.167375
665	2	timeout	\N	Service health check timed out	2025-10-08 19:40:49.167378
666	3	unhealthy	\N	All connection attempts failed	2025-10-08 19:40:49.167379
667	4	unhealthy	10.406	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 19:40:49.167379
668	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 19:40:49.16738
669	2	timeout	\N	Service health check timed out	2025-10-08 19:41:00.050768
670	3	unhealthy	\N	All connection attempts failed	2025-10-08 19:41:00.097437
671	4	unhealthy	7.896	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 19:41:00.273116
672	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 19:41:00.497466
673	2	timeout	\N	Service health check timed out	2025-10-08 19:56:20.539727
674	3	unhealthy	\N	All connection attempts failed	2025-10-08 19:56:20.53973
675	4	unhealthy	11.183	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 19:56:20.539731
676	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 19:56:20.539731
677	1	healthy	318.268	\N	2025-10-08 19:56:20.539732
678	1	healthy	171.21	\N	2025-10-08 20:11:51.743143
679	2	timeout	\N	Service health check timed out	2025-10-08 20:11:51.743146
680	3	unhealthy	\N	All connection attempts failed	2025-10-08 20:11:51.743147
681	4	unhealthy	9.931000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 20:11:51.743148
682	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 20:11:51.743148
683	1	healthy	173.06099999999998	\N	2025-10-08 20:27:23.255631
684	2	timeout	\N	Service health check timed out	2025-10-08 20:27:23.255634
685	3	unhealthy	\N	All connection attempts failed	2025-10-08 20:27:23.255635
686	4	unhealthy	10.19	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 20:27:23.255636
687	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 20:27:23.255636
688	1	healthy	17.311	\N	2025-10-08 20:42:54.299343
689	2	timeout	\N	Service health check timed out	2025-10-08 20:42:54.299345
690	3	unhealthy	\N	All connection attempts failed	2025-10-08 20:42:54.299346
691	4	unhealthy	9.996	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 20:42:54.299347
692	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 20:42:54.299348
693	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 20:58:25.660345
694	1	healthy	317.373	\N	2025-10-08 20:58:25.660347
695	2	timeout	\N	Service health check timed out	2025-10-08 20:58:25.660348
696	3	unhealthy	\N	All connection attempts failed	2025-10-08 20:58:25.660349
697	4	unhealthy	10.694	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 20:58:25.66035
698	1	healthy	45.744	\N	2025-10-08 21:13:56.772467
699	2	timeout	\N	Service health check timed out	2025-10-08 21:13:56.77247
700	3	unhealthy	\N	All connection attempts failed	2025-10-08 21:13:56.772471
701	4	unhealthy	10.259	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 21:13:56.772471
702	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 21:13:56.772472
703	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 21:29:28.149532
704	1	healthy	24.022000000000002	\N	2025-10-08 21:29:28.149535
705	2	timeout	\N	Service health check timed out	2025-10-08 21:29:28.149536
706	3	unhealthy	\N	All connection attempts failed	2025-10-08 21:29:28.149536
707	4	unhealthy	10.809	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 21:29:28.149537
708	1	healthy	173.82600000000002	\N	2025-10-08 21:33:30.615811
709	2	timeout	\N	Service health check timed out	2025-10-08 21:34:00.970664
710	3	unhealthy	\N	All connection attempts failed	2025-10-08 21:34:01.013262
711	4	unhealthy	8.904	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 21:34:01.063054
712	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 21:34:01.258657
713	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 21:44:59.378465
714	1	healthy	166.185	\N	2025-10-08 21:44:59.378468
715	2	timeout	\N	Service health check timed out	2025-10-08 21:44:59.378468
716	3	unhealthy	\N	All connection attempts failed	2025-10-08 21:44:59.378469
718	1	healthy	25.528	\N	2025-10-08 21:47:24.218088
719	2	timeout	\N	Service health check timed out	2025-10-08 21:47:54.445752
717	4	unhealthy	12.444	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 21:44:59.37847
721	4	unhealthy	7.423	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 21:47:54.556077
723	1	healthy	743.365	\N	2025-10-08 22:01:14.013377
724	2	timeout	\N	Service health check timed out	2025-10-08 22:01:14.01338
725	3	unhealthy	\N	All connection attempts failed	2025-10-08 22:01:14.013381
726	4	unhealthy	26.476	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 22:01:14.013382
727	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 22:01:14.013383
720	3	unhealthy	\N	All connection attempts failed	2025-10-08 21:47:54.500534
722	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 21:47:54.740764
728	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 22:16:45.845433
729	1	healthy	16.247	\N	2025-10-08 22:16:45.845436
730	2	timeout	\N	Service health check timed out	2025-10-08 22:16:45.845437
731	3	unhealthy	\N	All connection attempts failed	2025-10-08 22:16:45.845437
732	4	unhealthy	10.121	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 22:16:45.845438
733	1	healthy	14.056000000000001	\N	2025-10-08 22:16:51.459228
734	2	timeout	\N	Service health check timed out	2025-10-08 22:17:21.693365
735	3	unhealthy	\N	All connection attempts failed	2025-10-08 22:17:21.733536
736	4	unhealthy	6.916	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 22:17:21.776109
737	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 22:17:22.050191
738	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 22:32:17.232238
739	1	healthy	16.242	\N	2025-10-08 22:32:17.232241
740	2	timeout	\N	Service health check timed out	2025-10-08 22:32:17.232242
741	3	unhealthy	\N	All connection attempts failed	2025-10-08 22:32:17.232242
742	4	unhealthy	10.429	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 22:32:17.232243
743	1	healthy	178.655	\N	2025-10-08 22:40:39.680903
744	2	timeout	\N	Service health check timed out	2025-10-08 22:41:09.911935
745	3	unhealthy	\N	All connection attempts failed	2025-10-08 22:41:10.136114
746	4	unhealthy	7.986999999999999	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 22:41:10.173453
747	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 22:41:10.207583
748	1	healthy	35.462	\N	2025-10-08 22:47:49.078524
749	2	timeout	\N	Service health check timed out	2025-10-08 22:47:49.078531
750	3	unhealthy	\N	All connection attempts failed	2025-10-08 22:47:49.078532
751	4	unhealthy	10.702	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 22:47:49.078532
752	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 22:47:49.078533
753	2	timeout	\N	Service health check timed out	2025-10-08 23:03:20.438227
754	3	unhealthy	\N	All connection attempts failed	2025-10-08 23:03:20.43823
755	4	unhealthy	9.790000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 23:03:20.43823
756	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 23:03:20.438231
757	1	healthy	329.78499999999997	\N	2025-10-08 23:03:20.438232
758	1	healthy	16.773	\N	2025-10-08 23:18:52.227207
759	2	timeout	\N	Service health check timed out	2025-10-08 23:18:52.22721
760	3	unhealthy	\N	All connection attempts failed	2025-10-08 23:18:52.227211
761	4	unhealthy	9.503	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 23:18:52.227211
762	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 23:18:52.227212
763	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 23:34:23.722798
764	1	healthy	164.37099999999998	\N	2025-10-08 23:34:23.722801
765	2	timeout	\N	Service health check timed out	2025-10-08 23:34:23.722801
766	3	unhealthy	\N	All connection attempts failed	2025-10-08 23:34:23.722802
767	4	unhealthy	9.709000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 23:34:23.722803
768	1	healthy	19.068	\N	2025-10-08 23:49:55.554214
769	2	timeout	\N	Service health check timed out	2025-10-08 23:49:55.554216
770	3	unhealthy	\N	All connection attempts failed	2025-10-08 23:49:55.554217
771	4	unhealthy	13.168	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-08 23:49:55.554217
772	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-08 23:49:55.554218
773	5	unhealthy	\N	[Errno -3] Temporary failure in name resolution	2025-10-09 00:06:54.17252
774	1	unhealthy	\N	[Errno -3] Temporary failure in name resolution	2025-10-09 00:06:54.179832
775	2	unhealthy	\N	[Errno -3] Temporary failure in name resolution	2025-10-09 00:06:54.179835
776	3	unhealthy	\N	[Errno -3] Temporary failure in name resolution	2025-10-09 00:06:54.179836
777	4	unhealthy	\N	[Errno -3] Temporary failure in name resolution	2025-10-09 00:06:54.179837
778	1	healthy	182.90200000000002	\N	2025-10-09 01:46:01.63508
779	2	healthy	862.5129999999999	\N	2025-10-09 01:46:01.635083
780	3	unhealthy	\N	All connection attempts failed	2025-10-09 01:46:01.635085
781	4	unhealthy	9.608	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 01:46:01.635085
782	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 01:46:01.635086
783	1	healthy	15.77	\N	2025-10-09 01:48:07.895314
784	2	healthy	861.874	\N	2025-10-09 01:48:08.83437
785	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 01:48:09.02345
786	3	unhealthy	\N	All connection attempts failed	2025-10-09 01:48:09.422724
787	4	unhealthy	10.233	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 01:48:09.455217
788	1	healthy	14.135	\N	2025-10-09 01:48:34.794307
789	2	healthy	601.693	\N	2025-10-09 01:48:35.432959
790	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 01:48:35.525429
791	3	unhealthy	\N	All connection attempts failed	2025-10-09 01:48:35.863994
792	4	unhealthy	7.433000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 01:48:35.909515
793	1	healthy	168.545	\N	2025-10-09 02:01:02.397347
794	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 02:01:02.397349
795	3	unhealthy	\N	All connection attempts failed	2025-10-09 02:01:02.39735
796	4	unhealthy	6.9030000000000005	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 02:01:02.397351
797	1	healthy	16.171000000000003	\N	2025-10-09 02:04:14.764468
800	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 02:04:15.338708
803	3	unhealthy	\N	All connection attempts failed	2025-10-09 02:04:16.625831
806	1	healthy	15.125	\N	2025-10-09 02:10:22.910583
809	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 02:10:23.397242
810	1	healthy	13.652	\N	2025-10-09 02:16:02.975233
811	3	unhealthy	\N	All connection attempts failed	2025-10-09 02:16:02.975235
812	4	unhealthy	7.131	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 02:16:02.975236
813	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 02:16:02.975237
822	3	unhealthy	\N	All connection attempts failed	2025-10-09 03:01:05.036573
823	4	unhealthy	8.636	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 03:01:05.036576
824	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 03:01:05.036577
825	1	healthy	13.43	\N	2025-10-09 03:01:05.036577
798	3	unhealthy	\N	All connection attempts failed	2025-10-09 02:04:15.068474
801	2	healthy	852.461	\N	2025-10-09 02:04:16.215521
804	4	unhealthy	6.756	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 02:04:16.683857
807	3	unhealthy	\N	All connection attempts failed	2025-10-09 02:10:23.320932
818	1	healthy	17.224	\N	2025-10-09 02:46:04.452765
819	3	unhealthy	\N	All connection attempts failed	2025-10-09 02:46:04.452768
820	4	unhealthy	10.029	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 02:46:04.452768
821	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 02:46:04.452769
799	4	unhealthy	9.717	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 02:04:15.117143
802	1	healthy	3.691	\N	2025-10-09 02:04:16.367867
805	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 02:04:16.736813
808	4	unhealthy	7.601	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 02:10:23.359323
814	1	healthy	16.267	\N	2025-10-09 02:31:03.705742
815	3	unhealthy	\N	All connection attempts failed	2025-10-09 02:31:03.705745
816	4	unhealthy	10.452	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 02:31:03.705745
817	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 02:31:03.705746
826	1	healthy	16.641	\N	2025-10-09 03:16:05.618448
827	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 03:16:05.61845
828	4	unhealthy	8.881	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 03:16:05.618451
829	3	unhealthy	\N	All connection attempts failed	2025-10-09 03:16:05.618452
830	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 03:16:58.339694
831	3	unhealthy	\N	All connection attempts failed	2025-10-09 03:16:58.339696
832	4	healthy	8.923	\N	2025-10-09 03:16:58.339697
833	1	healthy	13.174	\N	2025-10-09 03:16:58.339698
834	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 03:17:34.229452
835	3	unhealthy	\N	All connection attempts failed	2025-10-09 03:17:34.229455
836	4	healthy	10.01	\N	2025-10-09 03:17:34.229456
837	1	healthy	12.859	\N	2025-10-09 03:17:34.229457
838	4	healthy	10.019	\N	2025-10-09 03:18:16.740198
839	1	healthy	13.665000000000001	\N	2025-10-09 03:18:16.875571
840	3	unhealthy	\N	All connection attempts failed	2025-10-09 03:18:17.304399
841	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 03:18:17.34804
842	3	unhealthy	\N	All connection attempts failed	2025-10-09 03:32:34.975162
843	1	healthy	15.66	\N	2025-10-09 03:32:34.975165
844	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 03:32:34.975166
845	4	healthy	11.037999999999998	\N	2025-10-09 03:32:34.975166
846	1	healthy	166.109	\N	2025-10-09 03:47:35.866294
847	3	unhealthy	\N	All connection attempts failed	2025-10-09 03:47:35.866296
848	4	healthy	11.367	\N	2025-10-09 03:47:35.866297
849	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 03:47:35.866298
850	1	healthy	17.252	\N	2025-10-09 04:02:36.455722
851	3	unhealthy	\N	All connection attempts failed	2025-10-09 04:02:36.455725
852	4	healthy	11.985000000000001	\N	2025-10-09 04:02:36.455725
853	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 04:02:36.455726
854	1	healthy	471.709	\N	2025-10-09 04:17:37.49586
855	3	unhealthy	\N	All connection attempts failed	2025-10-09 04:17:37.495862
856	4	healthy	11.258000000000001	\N	2025-10-09 04:17:37.495863
857	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 04:17:37.495863
858	1	healthy	316.139	\N	2025-10-09 04:32:38.532361
859	3	unhealthy	\N	All connection attempts failed	2025-10-09 04:32:38.532363
860	4	healthy	10.711	\N	2025-10-09 04:32:38.532364
861	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 04:32:38.532365
862	1	healthy	17.104000000000003	\N	2025-10-09 04:47:39.279099
863	3	unhealthy	\N	All connection attempts failed	2025-10-09 04:47:39.279102
864	4	healthy	12.52	\N	2025-10-09 04:47:39.279102
865	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 04:47:39.279103
866	1	healthy	16.907	\N	2025-10-09 05:02:39.868977
867	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 05:02:39.868979
868	4	unhealthy	12.194	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 05:02:39.86898
869	3	unhealthy	\N	All connection attempts failed	2025-10-09 05:02:39.86898
870	1	healthy	17.895999999999997	\N	2025-10-09 05:17:40.459642
871	3	unhealthy	\N	All connection attempts failed	2025-10-09 05:17:40.459645
872	4	unhealthy	9.579	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 05:17:40.459645
873	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 05:17:40.459646
874	1	healthy	324.921	\N	2025-10-09 05:32:41.509125
875	3	unhealthy	\N	All connection attempts failed	2025-10-09 05:32:41.509128
876	4	unhealthy	10.522	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 05:32:41.509128
877	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 05:32:41.509129
878	1	healthy	164.403	\N	2025-10-09 05:47:42.394268
879	3	unhealthy	\N	All connection attempts failed	2025-10-09 05:47:42.39427
880	4	unhealthy	10.171	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 05:47:42.394271
881	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 05:47:42.394272
882	1	healthy	168.789	\N	2025-10-09 06:02:43.1351
883	3	unhealthy	\N	All connection attempts failed	2025-10-09 06:02:43.135102
884	4	unhealthy	9.448	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 06:02:43.135103
885	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 06:02:43.135104
886	1	healthy	16.037	\N	2025-10-09 06:04:23.959865
887	3	unhealthy	\N	All connection attempts failed	2025-10-09 06:04:24.231595
888	4	unhealthy	11.296000000000001	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 06:04:24.351692
889	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 06:04:24.672673
890	1	unhealthy	\N	[Errno -3] Temporary failure in name resolution	2025-10-09 06:22:13.775271
891	3	unhealthy	\N	[Errno -3] Temporary failure in name resolution	2025-10-09 06:22:13.812105
892	4	unhealthy	\N	[Errno -3] Temporary failure in name resolution	2025-10-09 06:22:13.817789
893	5	unhealthy	\N	[Errno -3] Temporary failure in name resolution	2025-10-09 06:22:13.817793
924	3	unhealthy	\N	All connection attempts failed	2025-10-09 06:27:33.106208
925	4	unhealthy	11.4	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 06:27:33.106209
926	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 06:27:33.10621
927	1	healthy	13.626	\N	2025-10-09 06:29:22.985049
928	3	unhealthy	\N	All connection attempts failed	2025-10-09 06:29:23.290427
929	4	unhealthy	7.225	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 06:29:23.422165
930	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 06:29:23.755632
931	1	healthy	20.951999999999998	\N	2025-10-09 06:31:38.660266
932	3	unhealthy	\N	All connection attempts failed	2025-10-09 06:31:38.660268
933	4	unhealthy	11.401	HTTP 404: <!doctype html>\n<html lang=en>\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try agai	2025-10-09 06:31:38.660269
934	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 06:31:38.66027
935	1	healthy	21.18	\N	2025-10-09 06:34:45.74601
936	3	unhealthy	\N	All connection attempts failed	2025-10-09 06:34:45.746012
937	4	healthy	9.873	\N	2025-10-09 06:34:45.746013
938	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 06:34:45.746015
939	4	healthy	12.183	\N	2025-10-09 06:35:47.178371
940	1	healthy	321.609	\N	2025-10-09 06:35:47.63332
941	3	unhealthy	\N	All connection attempts failed	2025-10-09 06:35:47.884124
942	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 06:35:47.981185
943	4	healthy	12.822	\N	2025-10-09 06:43:34.909563
944	1	healthy	14.493	\N	2025-10-09 06:43:34.959601
945	3	unhealthy	\N	All connection attempts failed	2025-10-09 06:43:35.36951
946	5	unhealthy	\N	[Errno -2] Name or service not known	2025-10-09 06:43:35.720084
\.


--
-- Name: imputation_services_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.imputation_services_id_seq', 5, true);


--
-- Name: reference_panels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reference_panels_id_seq', 40, true);


--
-- Name: service_health_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_health_logs_id_seq', 946, true);


--
-- Name: imputation_services imputation_services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.imputation_services
    ADD CONSTRAINT imputation_services_pkey PRIMARY KEY (id);


--
-- Name: reference_panels reference_panels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reference_panels
    ADD CONSTRAINT reference_panels_pkey PRIMARY KEY (id);


--
-- Name: service_health_logs service_health_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_health_logs
    ADD CONSTRAINT service_health_logs_pkey PRIMARY KEY (id);


--
-- Name: ix_imputation_services_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_imputation_services_id ON public.imputation_services USING btree (id);


--
-- Name: ix_imputation_services_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_imputation_services_name ON public.imputation_services USING btree (name);


--
-- Name: ix_imputation_services_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_imputation_services_slug ON public.imputation_services USING btree (slug);


--
-- Name: ix_reference_panels_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_reference_panels_id ON public.reference_panels USING btree (id);


--
-- Name: ix_reference_panels_service_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_reference_panels_service_id ON public.reference_panels USING btree (service_id);


--
-- Name: ix_reference_panels_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_reference_panels_slug ON public.reference_panels USING btree (slug);


--
-- Name: ix_service_health_logs_checked_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_service_health_logs_checked_at ON public.service_health_logs USING btree (checked_at);


--
-- Name: ix_service_health_logs_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_service_health_logs_id ON public.service_health_logs USING btree (id);


--
-- Name: ix_service_health_logs_service_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_service_health_logs_service_id ON public.service_health_logs USING btree (service_id);


--
-- Name: reference_panels reference_panels_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reference_panels
    ADD CONSTRAINT reference_panels_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.imputation_services(id);


--
-- PostgreSQL database dump complete
--

