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
-- Name: alerts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alerts (
    id integer NOT NULL,
    alert_type character varying(50) NOT NULL,
    severity character varying(20) NOT NULL,
    title character varying(200) NOT NULL,
    description text NOT NULL,
    service_name character varying(100),
    metric_name character varying(100),
    metric_value double precision,
    threshold_value double precision,
    is_active boolean,
    is_acknowledged boolean,
    acknowledged_by character varying(100),
    acknowledged_at timestamp without time zone,
    resolved_at timestamp without time zone,
    alert_metadata json,
    triggered_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.alerts OWNER TO postgres;

--
-- Name: alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.alerts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alerts_id_seq OWNER TO postgres;

--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.alerts_id_seq OWNED BY public.alerts.id;


--
-- Name: service_health; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_health (
    id integer NOT NULL,
    service_name character varying(100) NOT NULL,
    status character varying(20) NOT NULL,
    response_time_ms double precision,
    error_message text,
    endpoint_url character varying(500),
    http_status_code integer,
    checked_at timestamp without time zone
);


ALTER TABLE public.service_health OWNER TO postgres;

--
-- Name: service_health_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.service_health_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.service_health_id_seq OWNER TO postgres;

--
-- Name: service_health_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.service_health_id_seq OWNED BY public.service_health.id;


--
-- Name: system_metrics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_metrics (
    id integer NOT NULL,
    cpu_usage_percent double precision,
    cpu_count integer,
    load_average_1m double precision,
    load_average_5m double precision,
    load_average_15m double precision,
    memory_total_gb double precision,
    memory_used_gb double precision,
    memory_available_gb double precision,
    memory_usage_percent double precision,
    disk_total_gb double precision,
    disk_used_gb double precision,
    disk_free_gb double precision,
    disk_usage_percent double precision,
    network_bytes_sent double precision,
    network_bytes_recv double precision,
    network_packets_sent double precision,
    network_packets_recv double precision,
    collected_at timestamp without time zone
);


ALTER TABLE public.system_metrics OWNER TO postgres;

--
-- Name: system_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.system_metrics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.system_metrics_id_seq OWNER TO postgres;

--
-- Name: system_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.system_metrics_id_seq OWNED BY public.system_metrics.id;


--
-- Name: alerts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts ALTER COLUMN id SET DEFAULT nextval('public.alerts_id_seq'::regclass);


--
-- Name: service_health id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_health ALTER COLUMN id SET DEFAULT nextval('public.service_health_id_seq'::regclass);


--
-- Name: system_metrics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_metrics ALTER COLUMN id SET DEFAULT nextval('public.system_metrics_id_seq'::regclass);


--
-- Data for Name: alerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alerts (id, alert_type, severity, title, description, service_name, metric_name, metric_value, threshold_value, is_active, is_acknowledged, acknowledged_by, acknowledged_at, resolved_at, alert_metadata, triggered_at, updated_at) FROM stdin;
1	service_down	high	Service api-gateway is down	Service api-gateway failed health check: [Errno -3] Temporary failure in name resolution	api-gateway	\N	\N	\N	t	f	\N	\N	\N	{}	2025-10-08 17:02:49.765421	2025-10-08 17:02:49.765424
7	service_down	high	Service job-processor is down	Service job-processor failed health check: All connection attempts failed	job-processor	\N	\N	\N	t	f	\N	\N	\N	{}	2025-10-08 17:19:59.660166	2025-10-08 17:19:59.660168
8	service_down	high	Service notification is down	Service notification failed health check: All connection attempts failed	notification	\N	\N	\N	t	f	\N	\N	\N	{}	2025-10-08 17:19:59.660173	2025-10-08 17:19:59.660174
9	high_cpu	medium	High CPU Usage	CPU usage is 98.0%	\N	cpu_usage_percent	98	80	t	f	\N	\N	\N	{}	2025-10-08 17:19:59.660176	2025-10-08 17:19:59.660177
10	high_memory	medium	High Memory Usage	Memory usage is 90.4%	\N	memory_usage_percent	90.4	85	t	f	\N	\N	\N	{}	2025-10-08 17:36:12.487834	2025-10-08 17:36:12.487837
11	service_down	high	Service user-service is down	Service user-service failed health check: 	user-service	\N	\N	\N	t	f	\N	\N	\N	{}	2025-10-08 19:06:39.698033	2025-10-08 19:06:39.711417
12	service_down	high	Service service-registry is down	Service service-registry failed health check: 	service-registry	\N	\N	\N	t	f	\N	\N	\N	{}	2025-10-08 19:06:39.711421	2025-10-08 19:06:39.711422
13	service_down	high	Service file-manager is down	Service file-manager failed health check: 	file-manager	\N	\N	\N	t	f	\N	\N	\N	{}	2025-10-08 19:06:39.711424	2025-10-08 19:06:39.711424
\.


--
-- Data for Name: service_health; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_health (id, service_name, status, response_time_ms, error_message, endpoint_url, http_status_code, checked_at) FROM stdin;
1	api-gateway	unhealthy	24.135	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 17:02:49.76818
2	user-service	healthy	15.273	\N	http://user-service:8001/health	200	2025-10-08 17:02:49.768182
3	service-registry	healthy	16.424999999999997	\N	http://service-registry:8002/health	200	2025-10-08 17:02:49.768183
4	job-processor	healthy	17.743	\N	http://job-processor:8003/health	200	2025-10-08 17:02:49.768184
5	file-manager	healthy	15.952999999999998	\N	http://file-manager:8004/health	200	2025-10-08 17:02:49.768185
6	notification	healthy	16.95	\N	http://notification:8005/health	200	2025-10-08 17:02:49.768186
7	api-gateway	healthy	388.731	\N	http://api-gateway:8000/health	200	2025-10-08 17:03:21.172462
8	user-service	healthy	13.226999999999999	\N	http://user-service:8001/health	200	2025-10-08 17:03:21.172465
9	service-registry	healthy	12.977	\N	http://service-registry:8002/health	200	2025-10-08 17:03:21.172465
10	job-processor	healthy	13.636000000000001	\N	http://job-processor:8003/health	200	2025-10-08 17:03:21.172466
11	file-manager	healthy	14.472999999999999	\N	http://file-manager:8004/health	200	2025-10-08 17:03:21.172467
12	notification	healthy	16.279	\N	http://notification:8005/health	200	2025-10-08 17:03:21.172467
13	api-gateway	healthy	343.43	\N	http://api-gateway:8000/health	200	2025-10-08 17:03:52.528745
14	user-service	healthy	18.905	\N	http://user-service:8001/health	200	2025-10-08 17:03:52.528747
15	service-registry	healthy	16.257	\N	http://service-registry:8002/health	200	2025-10-08 17:03:52.528748
16	job-processor	healthy	18.432000000000002	\N	http://job-processor:8003/health	200	2025-10-08 17:03:52.528748
17	file-manager	healthy	17.87	\N	http://file-manager:8004/health	200	2025-10-08 17:03:52.528749
18	notification	healthy	18.768	\N	http://notification:8005/health	200	2025-10-08 17:03:52.52875
19	api-gateway	healthy	320.97700000000003	\N	http://api-gateway:8000/health	200	2025-10-08 17:04:23.863207
20	user-service	healthy	17.235	\N	http://user-service:8001/health	200	2025-10-08 17:04:23.86321
21	service-registry	healthy	18.654	\N	http://service-registry:8002/health	200	2025-10-08 17:04:23.86321
22	job-processor	healthy	18.266000000000002	\N	http://job-processor:8003/health	200	2025-10-08 17:04:23.863211
23	file-manager	healthy	19.752	\N	http://file-manager:8004/health	200	2025-10-08 17:04:23.863211
24	notification	healthy	19.701	\N	http://notification:8005/health	200	2025-10-08 17:04:23.863212
25	api-gateway	healthy	373.529	\N	http://api-gateway:8000/health	200	2025-10-08 17:04:55.253481
26	user-service	healthy	18.316	\N	http://user-service:8001/health	200	2025-10-08 17:04:55.253484
27	service-registry	healthy	18.067	\N	http://service-registry:8002/health	200	2025-10-08 17:04:55.253485
28	job-processor	healthy	17.955	\N	http://job-processor:8003/health	200	2025-10-08 17:04:55.253485
29	file-manager	healthy	17.187	\N	http://file-manager:8004/health	200	2025-10-08 17:04:55.253486
30	notification	healthy	18.244	\N	http://notification:8005/health	200	2025-10-08 17:04:55.253486
31	api-gateway	healthy	488.587	\N	http://api-gateway:8000/health	200	2025-10-08 17:05:26.762939
32	user-service	healthy	17.836000000000002	\N	http://user-service:8001/health	200	2025-10-08 17:05:26.762942
33	service-registry	healthy	17.4	\N	http://service-registry:8002/health	200	2025-10-08 17:05:26.762943
34	job-processor	healthy	20.332	\N	http://job-processor:8003/health	200	2025-10-08 17:05:26.762943
35	file-manager	healthy	21.447999999999997	\N	http://file-manager:8004/health	200	2025-10-08 17:05:26.762944
36	notification	healthy	18.03	\N	http://notification:8005/health	200	2025-10-08 17:05:26.762944
37	api-gateway	healthy	318.447	\N	http://api-gateway:8000/health	200	2025-10-08 17:05:58.09908
38	user-service	healthy	15.848	\N	http://user-service:8001/health	200	2025-10-08 17:05:58.099083
39	service-registry	healthy	13.736	\N	http://service-registry:8002/health	200	2025-10-08 17:05:58.099083
40	job-processor	healthy	15.014	\N	http://job-processor:8003/health	200	2025-10-08 17:05:58.099084
41	file-manager	healthy	16.694	\N	http://file-manager:8004/health	200	2025-10-08 17:05:58.099085
42	notification	healthy	16.26	\N	http://notification:8005/health	200	2025-10-08 17:05:58.099085
43	api-gateway	healthy	348.45500000000004	\N	http://api-gateway:8000/health	200	2025-10-08 17:06:29.458338
44	user-service	healthy	16.772	\N	http://user-service:8001/health	200	2025-10-08 17:06:29.45834
45	service-registry	healthy	14.113999999999999	\N	http://service-registry:8002/health	200	2025-10-08 17:06:29.458341
46	job-processor	healthy	16.447	\N	http://job-processor:8003/health	200	2025-10-08 17:06:29.458341
47	file-manager	healthy	17.619	\N	http://file-manager:8004/health	200	2025-10-08 17:06:29.458342
48	notification	healthy	17.791	\N	http://notification:8005/health	200	2025-10-08 17:06:29.458343
49	api-gateway	healthy	325.604	\N	http://api-gateway:8000/health	200	2025-10-08 17:07:00.79999
50	user-service	healthy	17.373	\N	http://user-service:8001/health	200	2025-10-08 17:07:00.799992
51	service-registry	healthy	17.155	\N	http://service-registry:8002/health	200	2025-10-08 17:07:00.799993
52	job-processor	healthy	17.055	\N	http://job-processor:8003/health	200	2025-10-08 17:07:00.799994
53	file-manager	healthy	18.249000000000002	\N	http://file-manager:8004/health	200	2025-10-08 17:07:00.799994
54	notification	healthy	17.822999999999997	\N	http://notification:8005/health	200	2025-10-08 17:07:00.799995
55	api-gateway	healthy	312.29200000000003	\N	http://api-gateway:8000/health	200	2025-10-08 17:07:32.12543
56	user-service	healthy	15.121	\N	http://user-service:8001/health	200	2025-10-08 17:07:32.125433
57	service-registry	healthy	14.924	\N	http://service-registry:8002/health	200	2025-10-08 17:07:32.125433
58	job-processor	healthy	14.369	\N	http://job-processor:8003/health	200	2025-10-08 17:07:32.125434
59	file-manager	healthy	16.032999999999998	\N	http://file-manager:8004/health	200	2025-10-08 17:07:32.125434
60	notification	healthy	15.587	\N	http://notification:8005/health	200	2025-10-08 17:07:32.125435
61	api-gateway	healthy	340.391	\N	http://api-gateway:8000/health	200	2025-10-08 17:08:03.477035
62	user-service	healthy	13.063	\N	http://user-service:8001/health	200	2025-10-08 17:08:03.477038
63	service-registry	healthy	12.946	\N	http://service-registry:8002/health	200	2025-10-08 17:08:03.477038
64	job-processor	healthy	13.824	\N	http://job-processor:8003/health	200	2025-10-08 17:08:03.477039
65	file-manager	healthy	15.100000000000001	\N	http://file-manager:8004/health	200	2025-10-08 17:08:03.47704
66	notification	healthy	13.509	\N	http://notification:8005/health	200	2025-10-08 17:08:03.47704
67	api-gateway	healthy	341.961	\N	http://api-gateway:8000/health	200	2025-10-08 17:08:34.832151
68	user-service	healthy	20.695999999999998	\N	http://user-service:8001/health	200	2025-10-08 17:08:34.832153
69	service-registry	healthy	20.456	\N	http://service-registry:8002/health	200	2025-10-08 17:08:34.832154
70	job-processor	healthy	20.328	\N	http://job-processor:8003/health	200	2025-10-08 17:08:34.832154
71	file-manager	healthy	19.607	\N	http://file-manager:8004/health	200	2025-10-08 17:08:34.832155
72	notification	healthy	20.673000000000002	\N	http://notification:8005/health	200	2025-10-08 17:08:34.832156
73	api-gateway	healthy	320.041	\N	http://api-gateway:8000/health	200	2025-10-08 17:09:06.163279
74	user-service	healthy	11.528	\N	http://user-service:8001/health	200	2025-10-08 17:09:06.163281
75	service-registry	healthy	10.392999999999999	\N	http://service-registry:8002/health	200	2025-10-08 17:09:06.163282
76	job-processor	healthy	12.414	\N	http://job-processor:8003/health	200	2025-10-08 17:09:06.163283
77	file-manager	healthy	12.355	\N	http://file-manager:8004/health	200	2025-10-08 17:09:06.163283
78	notification	healthy	12.916	\N	http://notification:8005/health	200	2025-10-08 17:09:06.163284
79	api-gateway	healthy	331.06600000000003	\N	http://api-gateway:8000/health	200	2025-10-08 17:09:37.504063
80	user-service	healthy	11.620000000000001	\N	http://user-service:8001/health	200	2025-10-08 17:09:37.504065
81	service-registry	healthy	10.552999999999999	\N	http://service-registry:8002/health	200	2025-10-08 17:09:37.504065
82	job-processor	healthy	12.578000000000001	\N	http://job-processor:8003/health	200	2025-10-08 17:09:37.504066
83	file-manager	healthy	11.532	\N	http://file-manager:8004/health	200	2025-10-08 17:09:37.504066
84	notification	healthy	14.008	\N	http://notification:8005/health	200	2025-10-08 17:09:37.504067
85	api-gateway	healthy	315.882	\N	http://api-gateway:8000/health	200	2025-10-08 17:10:08.834023
86	user-service	healthy	12.546	\N	http://user-service:8001/health	200	2025-10-08 17:10:08.834026
87	service-registry	healthy	11.419	\N	http://service-registry:8002/health	200	2025-10-08 17:10:08.834026
88	job-processor	healthy	13.187000000000001	\N	http://job-processor:8003/health	200	2025-10-08 17:10:08.834027
89	file-manager	healthy	13.099	\N	http://file-manager:8004/health	200	2025-10-08 17:10:08.834027
90	notification	healthy	13.568999999999999	\N	http://notification:8005/health	200	2025-10-08 17:10:08.834028
91	api-gateway	healthy	314.503	\N	http://api-gateway:8000/health	200	2025-10-08 17:10:40.165673
92	user-service	healthy	14.233	\N	http://user-service:8001/health	200	2025-10-08 17:10:40.165675
93	service-registry	healthy	14.040000000000001	\N	http://service-registry:8002/health	200	2025-10-08 17:10:40.165676
94	job-processor	healthy	13.896	\N	http://job-processor:8003/health	200	2025-10-08 17:10:40.165677
95	file-manager	healthy	13.777	\N	http://file-manager:8004/health	200	2025-10-08 17:10:40.165677
96	notification	healthy	14.349	\N	http://notification:8005/health	200	2025-10-08 17:10:40.165678
97	api-gateway	healthy	316.928	\N	http://api-gateway:8000/health	200	2025-10-08 17:11:11.493754
98	user-service	healthy	13.622	\N	http://user-service:8001/health	200	2025-10-08 17:11:11.493756
99	service-registry	healthy	13.485000000000001	\N	http://service-registry:8002/health	200	2025-10-08 17:11:11.493757
100	job-processor	healthy	14.461	\N	http://job-processor:8003/health	200	2025-10-08 17:11:11.493757
101	file-manager	healthy	14.564	\N	http://file-manager:8004/health	200	2025-10-08 17:11:11.493758
102	notification	healthy	15.157	\N	http://notification:8005/health	200	2025-10-08 17:11:11.493759
103	api-gateway	healthy	340.055	\N	http://api-gateway:8000/health	200	2025-10-08 17:11:42.846741
104	user-service	healthy	30.113999999999997	\N	http://user-service:8001/health	200	2025-10-08 17:11:42.846744
105	service-registry	healthy	29.428	\N	http://service-registry:8002/health	200	2025-10-08 17:11:42.846745
106	job-processor	healthy	29.301000000000002	\N	http://job-processor:8003/health	200	2025-10-08 17:11:42.846745
107	file-manager	healthy	31.213	\N	http://file-manager:8004/health	200	2025-10-08 17:11:42.846746
108	notification	healthy	31.862000000000002	\N	http://notification:8005/health	200	2025-10-08 17:11:42.846747
109	api-gateway	healthy	354.31800000000004	\N	http://api-gateway:8000/health	200	2025-10-08 17:12:14.213235
110	user-service	healthy	16.337	\N	http://user-service:8001/health	200	2025-10-08 17:12:14.213237
111	service-registry	healthy	18.051000000000002	\N	http://service-registry:8002/health	200	2025-10-08 17:12:14.213237
112	job-processor	healthy	18.095	\N	http://job-processor:8003/health	200	2025-10-08 17:12:14.213238
113	file-manager	healthy	17.704	\N	http://file-manager:8004/health	200	2025-10-08 17:12:14.213239
114	notification	healthy	18.449	\N	http://notification:8005/health	200	2025-10-08 17:12:14.213239
115	api-gateway	healthy	327.649	\N	http://api-gateway:8000/health	200	2025-10-08 17:12:45.553618
116	user-service	healthy	13.758	\N	http://user-service:8001/health	200	2025-10-08 17:12:45.553621
117	service-registry	healthy	14.862	\N	http://service-registry:8002/health	200	2025-10-08 17:12:45.553621
118	job-processor	healthy	14.741999999999999	\N	http://job-processor:8003/health	200	2025-10-08 17:12:45.553622
119	file-manager	healthy	16.184	\N	http://file-manager:8004/health	200	2025-10-08 17:12:45.553623
120	notification	healthy	15.774	\N	http://notification:8005/health	200	2025-10-08 17:12:45.553623
121	api-gateway	healthy	314.564	\N	http://api-gateway:8000/health	200	2025-10-08 17:13:16.881728
122	user-service	healthy	17.412	\N	http://user-service:8001/health	200	2025-10-08 17:13:16.881731
123	service-registry	healthy	16.910999999999998	\N	http://service-registry:8002/health	200	2025-10-08 17:13:16.881731
124	job-processor	healthy	16.964	\N	http://job-processor:8003/health	200	2025-10-08 17:13:16.881732
125	file-manager	healthy	16.831	\N	http://file-manager:8004/health	200	2025-10-08 17:13:16.881732
126	notification	healthy	17.427000000000003	\N	http://notification:8005/health	200	2025-10-08 17:13:16.881733
127	api-gateway	healthy	648.458	\N	http://api-gateway:8000/health	200	2025-10-08 17:13:48.54057
128	user-service	healthy	15.74	\N	http://user-service:8001/health	200	2025-10-08 17:13:48.540573
129	service-registry	healthy	15.264	\N	http://service-registry:8002/health	200	2025-10-08 17:13:48.540573
130	job-processor	healthy	15.291	\N	http://job-processor:8003/health	200	2025-10-08 17:13:48.540574
131	file-manager	healthy	15.652	\N	http://file-manager:8004/health	200	2025-10-08 17:13:48.540575
132	notification	healthy	16.355	\N	http://notification:8005/health	200	2025-10-08 17:13:48.540575
133	api-gateway	healthy	312.704	\N	http://api-gateway:8000/health	200	2025-10-08 17:14:19.866994
134	user-service	healthy	16.567999999999998	\N	http://user-service:8001/health	200	2025-10-08 17:14:19.866997
135	service-registry	healthy	16.016	\N	http://service-registry:8002/health	200	2025-10-08 17:14:19.866998
136	job-processor	healthy	16.046000000000003	\N	http://job-processor:8003/health	200	2025-10-08 17:14:19.866998
137	file-manager	healthy	15.941	\N	http://file-manager:8004/health	200	2025-10-08 17:14:19.866999
138	notification	healthy	16.51	\N	http://notification:8005/health	200	2025-10-08 17:14:19.867
139	api-gateway	healthy	308.91400000000004	\N	http://api-gateway:8000/health	200	2025-10-08 17:14:51.190677
140	user-service	healthy	10.834	\N	http://user-service:8001/health	200	2025-10-08 17:14:51.190679
141	service-registry	healthy	11.248	\N	http://service-registry:8002/health	200	2025-10-08 17:14:51.19068
142	job-processor	healthy	13.302	\N	http://job-processor:8003/health	200	2025-10-08 17:14:51.19068
143	file-manager	healthy	12.872	\N	http://file-manager:8004/health	200	2025-10-08 17:14:51.190681
144	notification	healthy	12.447	\N	http://notification:8005/health	200	2025-10-08 17:14:51.190682
145	api-gateway	healthy	307.061	\N	http://api-gateway:8000/health	200	2025-10-08 17:15:22.517909
146	user-service	healthy	13.376000000000001	\N	http://user-service:8001/health	200	2025-10-08 17:15:22.517912
147	service-registry	healthy	15.716000000000001	\N	http://service-registry:8002/health	200	2025-10-08 17:15:22.517912
148	job-processor	healthy	15.598	\N	http://job-processor:8003/health	200	2025-10-08 17:15:22.517913
149	file-manager	healthy	15.816	\N	http://file-manager:8004/health	200	2025-10-08 17:15:22.517914
150	notification	healthy	15.383000000000001	\N	http://notification:8005/health	200	2025-10-08 17:15:22.517914
151	api-gateway	healthy	483.777	\N	http://api-gateway:8000/health	200	2025-10-08 17:15:54.027524
152	user-service	healthy	30.314	\N	http://user-service:8001/health	200	2025-10-08 17:15:54.027527
153	service-registry	healthy	30.162000000000003	\N	http://service-registry:8002/health	200	2025-10-08 17:15:54.027528
154	job-processor	healthy	30.596999999999998	\N	http://job-processor:8003/health	200	2025-10-08 17:15:54.027528
155	file-manager	healthy	31.617	\N	http://file-manager:8004/health	200	2025-10-08 17:15:54.027529
156	notification	healthy	31.169	\N	http://notification:8005/health	200	2025-10-08 17:15:54.027529
157	api-gateway	healthy	316.269	\N	http://api-gateway:8000/health	200	2025-10-08 17:16:25.357266
158	user-service	healthy	13.74	\N	http://user-service:8001/health	200	2025-10-08 17:16:25.357269
159	service-registry	healthy	13.237	\N	http://service-registry:8002/health	200	2025-10-08 17:16:25.357269
160	job-processor	healthy	15.184	\N	http://job-processor:8003/health	200	2025-10-08 17:16:25.35727
161	file-manager	healthy	15.084999999999999	\N	http://file-manager:8004/health	200	2025-10-08 17:16:25.357271
162	notification	healthy	15.007	\N	http://notification:8005/health	200	2025-10-08 17:16:25.357271
5935	api-gateway	healthy	991.996	\N	http://api-gateway:8000/health	200	2025-10-08 17:19:59.673597
5936	user-service	healthy	64.357	\N	http://user-service:8001/health	200	2025-10-08 17:19:59.6736
5937	service-registry	healthy	63.861000000000004	\N	http://service-registry:8002/health	200	2025-10-08 17:19:59.6736
5938	job-processor	unhealthy	32.507	All connection attempts failed	http://job-processor:8003/health	\N	2025-10-08 17:19:59.673601
5939	file-manager	healthy	63.615	\N	http://file-manager:8004/health	200	2025-10-08 17:19:59.673602
5940	notification	unhealthy	25.742	All connection attempts failed	http://notification:8005/health	\N	2025-10-08 17:19:59.673602
5941	api-gateway	healthy	520.359	\N	http://api-gateway:8000/health	200	2025-10-08 17:20:31.227282
5942	user-service	healthy	20.823999999999998	\N	http://user-service:8001/health	200	2025-10-08 17:20:31.227285
5943	service-registry	healthy	20.78	\N	http://service-registry:8002/health	200	2025-10-08 17:20:31.227285
5944	job-processor	healthy	42.662	\N	http://job-processor:8003/health	200	2025-10-08 17:20:31.227286
5945	file-manager	healthy	42.217999999999996	\N	http://file-manager:8004/health	200	2025-10-08 17:20:31.227287
5946	notification	healthy	42.08	\N	http://notification:8005/health	200	2025-10-08 17:20:31.227287
5947	api-gateway	healthy	367.379	\N	http://api-gateway:8000/health	200	2025-10-08 17:21:02.612644
5948	user-service	healthy	34.141999999999996	\N	http://user-service:8001/health	200	2025-10-08 17:21:02.612646
5949	service-registry	healthy	33.13	\N	http://service-registry:8002/health	200	2025-10-08 17:21:02.612647
5950	job-processor	healthy	32.98800000000001	\N	http://job-processor:8003/health	200	2025-10-08 17:21:02.612648
5951	file-manager	healthy	32.895	\N	http://file-manager:8004/health	200	2025-10-08 17:21:02.612648
5952	notification	healthy	32.799	\N	http://notification:8005/health	200	2025-10-08 17:21:02.612649
5953	api-gateway	healthy	358.89300000000003	\N	http://api-gateway:8000/health	200	2025-10-08 17:21:33.984708
5954	user-service	healthy	13.818	\N	http://user-service:8001/health	200	2025-10-08 17:21:33.984711
5955	service-registry	healthy	13.602	\N	http://service-registry:8002/health	200	2025-10-08 17:21:33.984712
5956	job-processor	healthy	15.235	\N	http://job-processor:8003/health	200	2025-10-08 17:21:33.984713
5957	file-manager	healthy	15.151	\N	http://file-manager:8004/health	200	2025-10-08 17:21:33.984713
5958	notification	healthy	15.091000000000001	\N	http://notification:8005/health	200	2025-10-08 17:21:33.984714
5959	api-gateway	healthy	346.14099999999996	\N	http://api-gateway:8000/health	200	2025-10-08 17:22:05.341486
5960	user-service	healthy	18.544999999999998	\N	http://user-service:8001/health	200	2025-10-08 17:22:05.341489
5961	service-registry	healthy	18.403	\N	http://service-registry:8002/health	200	2025-10-08 17:22:05.34149
5962	job-processor	healthy	19.77	\N	http://job-processor:8003/health	200	2025-10-08 17:22:05.341491
5963	file-manager	healthy	19.705000000000002	\N	http://file-manager:8004/health	200	2025-10-08 17:22:05.341491
5964	notification	healthy	19.608	\N	http://notification:8005/health	200	2025-10-08 17:22:05.341492
5965	api-gateway	healthy	362.755	\N	http://api-gateway:8000/health	200	2025-10-08 17:22:36.719098
5966	user-service	healthy	26.585	\N	http://user-service:8001/health	200	2025-10-08 17:22:36.719116
5967	service-registry	healthy	26.612000000000002	\N	http://service-registry:8002/health	200	2025-10-08 17:22:36.719117
5968	job-processor	healthy	26.224999999999998	\N	http://job-processor:8003/health	200	2025-10-08 17:22:36.719118
5969	file-manager	healthy	27.529	\N	http://file-manager:8004/health	200	2025-10-08 17:22:36.719118
5970	notification	healthy	27.498	\N	http://notification:8005/health	200	2025-10-08 17:22:36.719119
5971	api-gateway	healthy	307.49199999999996	\N	http://api-gateway:8000/health	200	2025-10-08 17:23:08.038636
5972	user-service	healthy	14.133	\N	http://user-service:8001/health	200	2025-10-08 17:23:08.038639
5973	service-registry	healthy	8.757	\N	http://service-registry:8002/health	200	2025-10-08 17:23:08.03864
5974	job-processor	healthy	15.018	\N	http://job-processor:8003/health	200	2025-10-08 17:23:08.03864
5975	file-manager	healthy	14.007	\N	http://file-manager:8004/health	200	2025-10-08 17:23:08.038641
5976	notification	healthy	15.358	\N	http://notification:8005/health	200	2025-10-08 17:23:08.038642
5977	api-gateway	healthy	350.762	\N	http://api-gateway:8000/health	200	2025-10-08 17:23:39.401447
5978	user-service	healthy	16.543	\N	http://user-service:8001/health	200	2025-10-08 17:23:39.40145
5979	service-registry	healthy	16.049999999999997	\N	http://service-registry:8002/health	200	2025-10-08 17:23:39.401451
5980	job-processor	healthy	16.092	\N	http://job-processor:8003/health	200	2025-10-08 17:23:39.401451
5981	file-manager	healthy	15.993	\N	http://file-manager:8004/health	200	2025-10-08 17:23:39.401452
5982	notification	healthy	16.59	\N	http://notification:8005/health	200	2025-10-08 17:23:39.401452
5983	api-gateway	healthy	312.547	\N	http://api-gateway:8000/health	200	2025-10-08 17:24:10.72733
5984	user-service	healthy	13.212	\N	http://user-service:8001/health	200	2025-10-08 17:24:10.727332
5985	service-registry	healthy	18.259999999999998	\N	http://service-registry:8002/health	200	2025-10-08 17:24:10.727333
5986	job-processor	healthy	17.687	\N	http://job-processor:8003/health	200	2025-10-08 17:24:10.727334
5987	file-manager	healthy	17.946	\N	http://file-manager:8004/health	200	2025-10-08 17:24:10.727335
5988	notification	healthy	17.38	\N	http://notification:8005/health	200	2025-10-08 17:24:10.727336
5989	api-gateway	healthy	337.555	\N	http://api-gateway:8000/health	200	2025-10-08 17:24:42.078407
5990	user-service	healthy	16.049	\N	http://user-service:8001/health	200	2025-10-08 17:24:42.07841
5991	service-registry	healthy	17.253999999999998	\N	http://service-registry:8002/health	200	2025-10-08 17:24:42.078411
5992	job-processor	healthy	16.805	\N	http://job-processor:8003/health	200	2025-10-08 17:24:42.078411
5993	file-manager	healthy	18.308999999999997	\N	http://file-manager:8004/health	200	2025-10-08 17:24:42.078412
5994	notification	healthy	18.241	\N	http://notification:8005/health	200	2025-10-08 17:24:42.078413
5995	api-gateway	healthy	323.747	\N	http://api-gateway:8000/health	200	2025-10-08 17:25:13.415525
5996	user-service	healthy	15.442	\N	http://user-service:8001/health	200	2025-10-08 17:25:13.415527
5997	service-registry	healthy	15.294	\N	http://service-registry:8002/health	200	2025-10-08 17:25:13.415528
5998	job-processor	healthy	15.190999999999999	\N	http://job-processor:8003/health	200	2025-10-08 17:25:13.415528
5999	file-manager	healthy	15.112	\N	http://file-manager:8004/health	200	2025-10-08 17:25:13.415529
6000	notification	healthy	15.082	\N	http://notification:8005/health	200	2025-10-08 17:25:13.415529
6001	api-gateway	healthy	349.47	\N	http://api-gateway:8000/health	200	2025-10-08 17:25:44.778008
6002	user-service	healthy	15.768	\N	http://user-service:8001/health	200	2025-10-08 17:25:44.77801
6003	service-registry	healthy	18.246	\N	http://service-registry:8002/health	200	2025-10-08 17:25:44.778011
6004	job-processor	healthy	17.756	\N	http://job-processor:8003/health	200	2025-10-08 17:25:44.778012
6005	file-manager	healthy	19.209	\N	http://file-manager:8004/health	200	2025-10-08 17:25:44.778012
6006	notification	healthy	17.62	\N	http://notification:8005/health	200	2025-10-08 17:25:44.778013
6007	api-gateway	healthy	335.834	\N	http://api-gateway:8000/health	200	2025-10-08 17:26:16.124431
6008	user-service	healthy	13.880999999999998	\N	http://user-service:8001/health	200	2025-10-08 17:26:16.124434
6009	service-registry	healthy	14.762	\N	http://service-registry:8002/health	200	2025-10-08 17:26:16.124434
6010	job-processor	healthy	14.985999999999999	\N	http://job-processor:8003/health	200	2025-10-08 17:26:16.124435
6011	file-manager	healthy	16.225	\N	http://file-manager:8004/health	200	2025-10-08 17:26:16.124435
6012	notification	healthy	16.211	\N	http://notification:8005/health	200	2025-10-08 17:26:16.124436
6013	api-gateway	healthy	557.2669999999999	\N	http://api-gateway:8000/health	200	2025-10-08 17:26:47.692331
6014	user-service	healthy	12.728	\N	http://user-service:8001/health	200	2025-10-08 17:26:47.692334
6015	service-registry	healthy	16.222	\N	http://service-registry:8002/health	200	2025-10-08 17:26:47.692334
6016	job-processor	healthy	14.325	\N	http://job-processor:8003/health	200	2025-10-08 17:26:47.692335
6017	file-manager	healthy	15.552	\N	http://file-manager:8004/health	200	2025-10-08 17:26:47.692336
6018	notification	healthy	14.005	\N	http://notification:8005/health	200	2025-10-08 17:26:47.692336
6019	api-gateway	healthy	626.3879999999999	\N	http://api-gateway:8000/health	200	2025-10-08 17:27:19.33108
6020	user-service	healthy	28.844	\N	http://user-service:8001/health	200	2025-10-08 17:27:19.331083
6021	service-registry	healthy	12.149999999999999	\N	http://service-registry:8002/health	200	2025-10-08 17:27:19.331083
6022	job-processor	healthy	12.857000000000001	\N	http://job-processor:8003/health	200	2025-10-08 17:27:19.331084
6023	file-manager	healthy	15.630999999999998	\N	http://file-manager:8004/health	200	2025-10-08 17:27:19.331085
6024	notification	healthy	26.811	\N	http://notification:8005/health	200	2025-10-08 17:27:19.331085
6025	api-gateway	healthy	318.563	\N	http://api-gateway:8000/health	200	2025-10-08 17:27:50.666419
6026	user-service	healthy	14.546999999999999	\N	http://user-service:8001/health	200	2025-10-08 17:27:50.666421
6027	service-registry	healthy	14.371	\N	http://service-registry:8002/health	200	2025-10-08 17:27:50.666422
6028	job-processor	healthy	16.704	\N	http://job-processor:8003/health	200	2025-10-08 17:27:50.666423
6029	file-manager	healthy	16.302	\N	http://file-manager:8004/health	200	2025-10-08 17:27:50.666423
6030	notification	healthy	15.915	\N	http://notification:8005/health	200	2025-10-08 17:27:50.666424
6031	api-gateway	healthy	320.846	\N	http://api-gateway:8000/health	200	2025-10-08 17:28:22.000203
6032	user-service	healthy	12.965000000000002	\N	http://user-service:8001/health	200	2025-10-08 17:28:22.000205
6033	service-registry	healthy	12.426	\N	http://service-registry:8002/health	200	2025-10-08 17:28:22.000206
6034	job-processor	healthy	14.043999999999999	\N	http://job-processor:8003/health	200	2025-10-08 17:28:22.000207
6035	file-manager	healthy	13.956	\N	http://file-manager:8004/health	200	2025-10-08 17:28:22.000207
6036	notification	healthy	13.363	\N	http://notification:8005/health	200	2025-10-08 17:28:22.000208
6037	api-gateway	healthy	398.98	\N	http://api-gateway:8000/health	200	2025-10-08 17:28:53.411893
6038	user-service	healthy	16.676	\N	http://user-service:8001/health	200	2025-10-08 17:28:53.411896
6039	service-registry	healthy	16.526	\N	http://service-registry:8002/health	200	2025-10-08 17:28:53.411897
6040	job-processor	healthy	32.370999999999995	\N	http://job-processor:8003/health	200	2025-10-08 17:28:53.411897
6041	file-manager	healthy	31.959	\N	http://file-manager:8004/health	200	2025-10-08 17:28:53.411898
6042	notification	healthy	32.608	\N	http://notification:8005/health	200	2025-10-08 17:28:53.411898
6043	api-gateway	healthy	301.776	\N	http://api-gateway:8000/health	200	2025-10-08 17:29:24.725229
6044	user-service	healthy	11.418	\N	http://user-service:8001/health	200	2025-10-08 17:29:24.725231
6045	service-registry	healthy	10.078	\N	http://service-registry:8002/health	200	2025-10-08 17:29:24.725232
6046	job-processor	healthy	12.644	\N	http://job-processor:8003/health	200	2025-10-08 17:29:24.725233
6047	file-manager	healthy	12.578000000000001	\N	http://file-manager:8004/health	200	2025-10-08 17:29:24.725233
6048	notification	healthy	13.178	\N	http://notification:8005/health	200	2025-10-08 17:29:24.725234
6049	api-gateway	healthy	369.097	\N	http://api-gateway:8000/health	200	2025-10-08 17:29:56.109805
6050	user-service	healthy	12.639	\N	http://user-service:8001/health	200	2025-10-08 17:29:56.109808
6051	service-registry	healthy	12.135	\N	http://service-registry:8002/health	200	2025-10-08 17:29:56.109809
6052	job-processor	healthy	14.041	\N	http://job-processor:8003/health	200	2025-10-08 17:29:56.109809
6053	file-manager	healthy	13.964	\N	http://file-manager:8004/health	200	2025-10-08 17:29:56.10981
6054	notification	healthy	13.396	\N	http://notification:8005/health	200	2025-10-08 17:29:56.109811
6055	api-gateway	healthy	334.774	\N	http://api-gateway:8000/health	200	2025-10-08 17:30:27.460338
6056	user-service	healthy	17.744	\N	http://user-service:8001/health	200	2025-10-08 17:30:27.460341
6057	service-registry	healthy	14.324	\N	http://service-registry:8002/health	200	2025-10-08 17:30:27.460342
6058	job-processor	healthy	17.318	\N	http://job-processor:8003/health	200	2025-10-08 17:30:27.460342
6059	file-manager	healthy	17.239	\N	http://file-manager:8004/health	200	2025-10-08 17:30:27.460343
6060	notification	healthy	17.222	\N	http://notification:8005/health	200	2025-10-08 17:30:27.460343
6061	api-gateway	healthy	418.89799999999997	\N	http://api-gateway:8000/health	200	2025-10-08 17:30:58.893296
6062	user-service	healthy	19.732	\N	http://user-service:8001/health	200	2025-10-08 17:30:58.893298
6063	service-registry	healthy	18.764	\N	http://service-registry:8002/health	200	2025-10-08 17:30:58.893299
6064	job-processor	healthy	20.874	\N	http://job-processor:8003/health	200	2025-10-08 17:30:58.893299
6065	file-manager	healthy	20.813000000000002	\N	http://file-manager:8004/health	200	2025-10-08 17:30:58.8933
6066	notification	healthy	41.111000000000004	\N	http://notification:8005/health	200	2025-10-08 17:30:58.893301
6067	api-gateway	healthy	379.82500000000005	\N	http://api-gateway:8000/health	200	2025-10-08 17:31:30.283856
6068	user-service	healthy	10.693	\N	http://user-service:8001/health	200	2025-10-08 17:31:30.283859
6069	service-registry	healthy	18.483	\N	http://service-registry:8002/health	200	2025-10-08 17:31:30.283859
6070	job-processor	healthy	13.491	\N	http://job-processor:8003/health	200	2025-10-08 17:31:30.28386
6071	file-manager	healthy	10.723	\N	http://file-manager:8004/health	200	2025-10-08 17:31:30.283861
6072	notification	healthy	11.620999999999999	\N	http://notification:8005/health	200	2025-10-08 17:31:30.283861
6073	api-gateway	healthy	361.65799999999996	\N	http://api-gateway:8000/health	200	2025-10-08 17:32:01.659815
6074	user-service	healthy	13.922	\N	http://user-service:8001/health	200	2025-10-08 17:32:01.659818
6075	service-registry	healthy	13.207	\N	http://service-registry:8002/health	200	2025-10-08 17:32:01.659818
6076	job-processor	healthy	15.84	\N	http://job-processor:8003/health	200	2025-10-08 17:32:01.659819
6077	file-manager	healthy	15.751999999999999	\N	http://file-manager:8004/health	200	2025-10-08 17:32:01.65982
6078	notification	healthy	15.131	\N	http://notification:8005/health	200	2025-10-08 17:32:01.65982
6079	api-gateway	healthy	336.544	\N	http://api-gateway:8000/health	200	2025-10-08 17:32:33.011186
6080	user-service	healthy	15.827999999999998	\N	http://user-service:8001/health	200	2025-10-08 17:32:33.011189
6081	service-registry	healthy	15.608	\N	http://service-registry:8002/health	200	2025-10-08 17:32:33.011189
6082	job-processor	healthy	15.548	\N	http://job-processor:8003/health	200	2025-10-08 17:32:33.01119
6083	file-manager	healthy	16.608	\N	http://file-manager:8004/health	200	2025-10-08 17:32:33.011191
6084	notification	healthy	16.267	\N	http://notification:8005/health	200	2025-10-08 17:32:33.011191
6085	api-gateway	healthy	310.14000000000004	\N	http://api-gateway:8000/health	200	2025-10-08 17:33:04.331364
6086	user-service	healthy	12.246	\N	http://user-service:8001/health	200	2025-10-08 17:33:04.331367
6087	service-registry	healthy	10.822999999999999	\N	http://service-registry:8002/health	200	2025-10-08 17:33:04.331368
6088	job-processor	healthy	13.391	\N	http://job-processor:8003/health	200	2025-10-08 17:33:04.331368
6089	file-manager	healthy	14.123	\N	http://file-manager:8004/health	200	2025-10-08 17:33:04.331369
6090	notification	healthy	14.568	\N	http://notification:8005/health	200	2025-10-08 17:33:04.331369
6091	api-gateway	healthy	328.933	\N	http://api-gateway:8000/health	200	2025-10-08 17:33:35.672204
6092	user-service	healthy	15.013	\N	http://user-service:8001/health	200	2025-10-08 17:33:35.672206
6093	service-registry	healthy	12.158000000000001	\N	http://service-registry:8002/health	200	2025-10-08 17:33:35.672207
6094	job-processor	healthy	14.113000000000001	\N	http://job-processor:8003/health	200	2025-10-08 17:33:35.672207
6095	file-manager	healthy	15.214	\N	http://file-manager:8004/health	200	2025-10-08 17:33:35.672208
6096	notification	healthy	13.795	\N	http://notification:8005/health	200	2025-10-08 17:33:35.672209
6097	api-gateway	healthy	309.096	\N	http://api-gateway:8000/health	200	2025-10-08 17:34:06.995928
6098	user-service	healthy	15.7	\N	http://user-service:8001/health	200	2025-10-08 17:34:06.995931
6099	service-registry	healthy	15.478	\N	http://service-registry:8002/health	200	2025-10-08 17:34:06.995932
6100	job-processor	healthy	15.366	\N	http://job-processor:8003/health	200	2025-10-08 17:34:06.995932
6101	file-manager	healthy	16.796	\N	http://file-manager:8004/health	200	2025-10-08 17:34:06.995933
6102	notification	healthy	16.739	\N	http://notification:8005/health	200	2025-10-08 17:34:06.995934
6103	api-gateway	healthy	327.093	\N	http://api-gateway:8000/health	200	2025-10-08 17:34:38.333442
6104	user-service	healthy	13.113	\N	http://user-service:8001/health	200	2025-10-08 17:34:38.333444
6105	service-registry	healthy	10.888	\N	http://service-registry:8002/health	200	2025-10-08 17:34:38.333445
6106	job-processor	healthy	12.403	\N	http://job-processor:8003/health	200	2025-10-08 17:34:38.333446
6107	file-manager	healthy	16.849	\N	http://file-manager:8004/health	200	2025-10-08 17:34:38.333447
6108	notification	healthy	16.8	\N	http://notification:8005/health	200	2025-10-08 17:34:38.333447
6109	api-gateway	healthy	305.91	\N	http://api-gateway:8000/health	200	2025-10-08 17:35:09.678271
6110	user-service	healthy	14.79	\N	http://user-service:8001/health	200	2025-10-08 17:35:09.678274
6111	service-registry	healthy	13.774	\N	http://service-registry:8002/health	200	2025-10-08 17:35:09.678274
6112	job-processor	healthy	15.921999999999999	\N	http://job-processor:8003/health	200	2025-10-08 17:35:09.678275
6113	file-manager	healthy	15.858	\N	http://file-manager:8004/health	200	2025-10-08 17:35:09.678276
6114	notification	healthy	15.808	\N	http://notification:8005/health	200	2025-10-08 17:35:09.678276
6115	api-gateway	healthy	296.602	\N	http://api-gateway:8000/health	200	2025-10-08 17:35:40.987776
6116	user-service	healthy	15.252	\N	http://user-service:8001/health	200	2025-10-08 17:35:40.987778
6117	service-registry	healthy	15.095	\N	http://service-registry:8002/health	200	2025-10-08 17:35:40.987779
6118	job-processor	healthy	14.987	\N	http://job-processor:8003/health	200	2025-10-08 17:35:40.98778
6119	file-manager	healthy	14.914	\N	http://file-manager:8004/health	200	2025-10-08 17:35:40.987781
6120	notification	healthy	15.54	\N	http://notification:8005/health	200	2025-10-08 17:35:40.987782
6121	api-gateway	healthy	453.378	\N	http://api-gateway:8000/health	200	2025-10-08 17:36:12.491711
6122	user-service	healthy	42.88	\N	http://user-service:8001/health	200	2025-10-08 17:36:12.491714
6123	service-registry	healthy	36.958	\N	http://service-registry:8002/health	200	2025-10-08 17:36:12.491715
6124	job-processor	healthy	37.254000000000005	\N	http://job-processor:8003/health	200	2025-10-08 17:36:12.491716
6125	file-manager	healthy	46.467	\N	http://file-manager:8004/health	200	2025-10-08 17:36:12.491716
6126	notification	healthy	45.467	\N	http://notification:8005/health	200	2025-10-08 17:36:12.491717
6127	api-gateway	healthy	151070.318	\N	http://api-gateway:8000/health	200	2025-10-08 17:39:27.915016
6128	user-service	healthy	41825.311	\N	http://user-service:8001/health	200	2025-10-08 17:39:27.915019
6129	service-registry	healthy	19560.348	\N	http://service-registry:8002/health	200	2025-10-08 17:39:27.91502
6130	job-processor	healthy	6432.683	\N	http://job-processor:8003/health	200	2025-10-08 17:39:27.91502
6131	file-manager	healthy	6296.035	\N	http://file-manager:8004/health	200	2025-10-08 17:39:27.915021
6132	notification	healthy	6121.029	\N	http://notification:8005/health	200	2025-10-08 17:39:27.915022
6133	api-gateway	healthy	679.3900000000001	\N	http://api-gateway:8000/health	200	2025-10-08 17:39:59.62136
6134	user-service	healthy	15.157	\N	http://user-service:8001/health	200	2025-10-08 17:39:59.621363
6135	service-registry	healthy	13.06	\N	http://service-registry:8002/health	200	2025-10-08 17:39:59.621364
6136	job-processor	healthy	14.770999999999999	\N	http://job-processor:8003/health	200	2025-10-08 17:39:59.621364
6137	file-manager	healthy	28.171000000000003	\N	http://file-manager:8004/health	200	2025-10-08 17:39:59.621365
6138	notification	healthy	28.682	\N	http://notification:8005/health	200	2025-10-08 17:39:59.621365
6139	api-gateway	healthy	307.192	\N	http://api-gateway:8000/health	200	2025-10-08 17:40:30.940559
6140	user-service	healthy	10.715	\N	http://user-service:8001/health	200	2025-10-08 17:40:30.940562
6141	service-registry	healthy	9.382	\N	http://service-registry:8002/health	200	2025-10-08 17:40:30.940563
6142	job-processor	healthy	11.641	\N	http://job-processor:8003/health	200	2025-10-08 17:40:30.940563
6143	file-manager	healthy	14.628	\N	http://file-manager:8004/health	200	2025-10-08 17:40:30.940564
6144	notification	healthy	15.346	\N	http://notification:8005/health	200	2025-10-08 17:40:30.940565
6145	api-gateway	healthy	302.80899999999997	\N	http://api-gateway:8000/health	200	2025-10-08 17:41:02.255433
6146	user-service	healthy	10.445	\N	http://user-service:8001/health	200	2025-10-08 17:41:02.255435
6147	service-registry	healthy	10.246	\N	http://service-registry:8002/health	200	2025-10-08 17:41:02.255436
6148	job-processor	healthy	11.998999999999999	\N	http://job-processor:8003/health	200	2025-10-08 17:41:02.255437
6149	file-manager	healthy	10.451	\N	http://file-manager:8004/health	200	2025-10-08 17:41:02.255437
6150	notification	healthy	11.677	\N	http://notification:8005/health	200	2025-10-08 17:41:02.255438
6151	api-gateway	healthy	312.461	\N	http://api-gateway:8000/health	200	2025-10-08 17:41:33.579043
6152	user-service	healthy	14.793000000000001	\N	http://user-service:8001/health	200	2025-10-08 17:41:33.579045
6153	service-registry	healthy	14.623000000000001	\N	http://service-registry:8002/health	200	2025-10-08 17:41:33.579046
6154	job-processor	healthy	16.722	\N	http://job-processor:8003/health	200	2025-10-08 17:41:33.579047
6155	file-manager	healthy	16.323	\N	http://file-manager:8004/health	200	2025-10-08 17:41:33.579047
6156	notification	healthy	16.471	\N	http://notification:8005/health	200	2025-10-08 17:41:33.579048
6157	api-gateway	healthy	336.483	\N	http://api-gateway:8000/health	200	2025-10-08 17:42:04.924619
6158	user-service	healthy	7.023	\N	http://user-service:8001/health	200	2025-10-08 17:42:04.924621
6159	service-registry	healthy	15.487	\N	http://service-registry:8002/health	200	2025-10-08 17:42:04.924622
6160	job-processor	healthy	12.753	\N	http://job-processor:8003/health	200	2025-10-08 17:42:04.924623
6161	file-manager	healthy	17.648	\N	http://file-manager:8004/health	200	2025-10-08 17:42:04.924623
6162	notification	healthy	18.018	\N	http://notification:8005/health	200	2025-10-08 17:42:04.924624
6163	api-gateway	healthy	308.328	\N	http://api-gateway:8000/health	200	2025-10-08 17:42:36.242759
6164	user-service	healthy	9.54	\N	http://user-service:8001/health	200	2025-10-08 17:42:36.242761
6165	service-registry	healthy	7.896999999999999	\N	http://service-registry:8002/health	200	2025-10-08 17:42:36.242762
6166	job-processor	healthy	13.309	\N	http://job-processor:8003/health	200	2025-10-08 17:42:36.242763
6167	file-manager	healthy	13.976	\N	http://file-manager:8004/health	200	2025-10-08 17:42:36.242763
6168	notification	healthy	14.719	\N	http://notification:8005/health	200	2025-10-08 17:42:36.242764
6169	api-gateway	healthy	312.127	\N	http://api-gateway:8000/health	200	2025-10-08 17:43:07.565803
6170	user-service	healthy	13.638000000000002	\N	http://user-service:8001/health	200	2025-10-08 17:43:07.565805
6171	service-registry	healthy	15.847	\N	http://service-registry:8002/health	200	2025-10-08 17:43:07.565806
6172	job-processor	healthy	13.223	\N	http://job-processor:8003/health	200	2025-10-08 17:43:07.565806
6173	file-manager	healthy	15.028	\N	http://file-manager:8004/health	200	2025-10-08 17:43:07.565807
6174	notification	healthy	14.968	\N	http://notification:8005/health	200	2025-10-08 17:43:07.565807
6175	api-gateway	healthy	303.557	\N	http://api-gateway:8000/health	200	2025-10-08 17:43:38.879457
6176	user-service	healthy	12.253	\N	http://user-service:8001/health	200	2025-10-08 17:43:38.879459
6177	service-registry	healthy	11.776	\N	http://service-registry:8002/health	200	2025-10-08 17:43:38.87946
6178	job-processor	healthy	13.839	\N	http://job-processor:8003/health	200	2025-10-08 17:43:38.879461
6179	file-manager	healthy	13.786	\N	http://file-manager:8004/health	200	2025-10-08 17:43:38.879461
6180	notification	healthy	13.187000000000001	\N	http://notification:8005/health	200	2025-10-08 17:43:38.879462
6181	api-gateway	healthy	294.57	\N	http://api-gateway:8000/health	200	2025-10-08 17:44:10.187857
6182	user-service	healthy	11.847999999999999	\N	http://user-service:8001/health	200	2025-10-08 17:44:10.187859
6183	service-registry	healthy	11.402000000000001	\N	http://service-registry:8002/health	200	2025-10-08 17:44:10.18786
6184	job-processor	healthy	12.754	\N	http://job-processor:8003/health	200	2025-10-08 17:44:10.18786
6185	file-manager	healthy	13.373	\N	http://file-manager:8004/health	200	2025-10-08 17:44:10.187861
6186	notification	healthy	12.436	\N	http://notification:8005/health	200	2025-10-08 17:44:10.187862
6187	api-gateway	healthy	498.889	\N	http://api-gateway:8000/health	200	2025-10-08 17:44:41.697566
6188	user-service	healthy	11.697000000000001	\N	http://user-service:8001/health	200	2025-10-08 17:44:41.697569
6189	service-registry	healthy	13.24	\N	http://service-registry:8002/health	200	2025-10-08 17:44:41.69757
6190	job-processor	healthy	13.164	\N	http://job-processor:8003/health	200	2025-10-08 17:44:41.69757
6191	file-manager	healthy	13.107000000000001	\N	http://file-manager:8004/health	200	2025-10-08 17:44:41.697571
6192	notification	healthy	13.751	\N	http://notification:8005/health	200	2025-10-08 17:44:41.697571
6193	api-gateway	healthy	347.21200000000005	\N	http://api-gateway:8000/health	200	2025-10-08 17:45:13.057743
6194	user-service	healthy	27.116	\N	http://user-service:8001/health	200	2025-10-08 17:45:13.057746
6195	service-registry	healthy	26.488	\N	http://service-registry:8002/health	200	2025-10-08 17:45:13.057746
6196	job-processor	healthy	26.515	\N	http://job-processor:8003/health	200	2025-10-08 17:45:13.057747
6197	file-manager	healthy	26.438	\N	http://file-manager:8004/health	200	2025-10-08 17:45:13.057748
6198	notification	healthy	26.384999999999998	\N	http://notification:8005/health	200	2025-10-08 17:45:13.057748
6199	api-gateway	healthy	408.992	\N	http://api-gateway:8000/health	200	2025-10-08 17:45:44.479612
6200	user-service	healthy	19.712	\N	http://user-service:8001/health	200	2025-10-08 17:45:44.479615
6201	service-registry	healthy	15.001999999999999	\N	http://service-registry:8002/health	200	2025-10-08 17:45:44.479616
6202	job-processor	healthy	20.116	\N	http://job-processor:8003/health	200	2025-10-08 17:45:44.479616
6203	file-manager	healthy	18.673	\N	http://file-manager:8004/health	200	2025-10-08 17:45:44.479617
6204	notification	healthy	14.411	\N	http://notification:8005/health	200	2025-10-08 17:45:44.479618
6205	api-gateway	healthy	388.327	\N	http://api-gateway:8000/health	200	2025-10-08 17:46:15.885482
6206	user-service	healthy	19.596	\N	http://user-service:8001/health	200	2025-10-08 17:46:15.885485
6207	service-registry	healthy	16.597	\N	http://service-registry:8002/health	200	2025-10-08 17:46:15.885486
6208	job-processor	healthy	19.227	\N	http://job-processor:8003/health	200	2025-10-08 17:46:15.885486
6209	file-manager	healthy	19.158	\N	http://file-manager:8004/health	200	2025-10-08 17:46:15.885487
6210	notification	healthy	19.088	\N	http://notification:8005/health	200	2025-10-08 17:46:15.885488
6211	api-gateway	healthy	309.113	\N	http://api-gateway:8000/health	200	2025-10-08 17:46:47.204419
6212	user-service	healthy	15.913	\N	http://user-service:8001/health	200	2025-10-08 17:46:47.204421
6213	service-registry	healthy	15.748999999999999	\N	http://service-registry:8002/health	200	2025-10-08 17:46:47.204422
6214	job-processor	healthy	15.623	\N	http://job-processor:8003/health	200	2025-10-08 17:46:47.204422
6215	file-manager	healthy	14.938999999999998	\N	http://file-manager:8004/health	200	2025-10-08 17:46:47.204423
6216	notification	healthy	16.168	\N	http://notification:8005/health	200	2025-10-08 17:46:47.204424
6217	api-gateway	healthy	315.56600000000003	\N	http://api-gateway:8000/health	200	2025-10-08 17:47:18.533042
6218	user-service	healthy	15.706999999999999	\N	http://user-service:8001/health	200	2025-10-08 17:47:18.533044
6219	service-registry	healthy	13.841	\N	http://service-registry:8002/health	200	2025-10-08 17:47:18.533045
6220	job-processor	healthy	15.266	\N	http://job-processor:8003/health	200	2025-10-08 17:47:18.533046
6221	file-manager	healthy	16.832	\N	http://file-manager:8004/health	200	2025-10-08 17:47:18.533046
6222	notification	healthy	16.416	\N	http://notification:8005/health	200	2025-10-08 17:47:18.533047
6223	api-gateway	healthy	331.511	\N	http://api-gateway:8000/health	200	2025-10-08 17:47:49.874606
6224	user-service	healthy	15.872	\N	http://user-service:8001/health	200	2025-10-08 17:47:49.874609
6225	service-registry	healthy	15.453	\N	http://service-registry:8002/health	200	2025-10-08 17:47:49.87461
6226	job-processor	healthy	15.499	\N	http://job-processor:8003/health	200	2025-10-08 17:47:49.87461
6227	file-manager	healthy	15.424999999999999	\N	http://file-manager:8004/health	200	2025-10-08 17:47:49.874611
6228	notification	healthy	15.334	\N	http://notification:8005/health	200	2025-10-08 17:47:49.874612
6229	api-gateway	healthy	303.684	\N	http://api-gateway:8000/health	200	2025-10-08 17:48:21.187867
6230	user-service	healthy	14.054	\N	http://user-service:8001/health	200	2025-10-08 17:48:21.187869
6231	service-registry	healthy	13.912	\N	http://service-registry:8002/health	200	2025-10-08 17:48:21.18787
6232	job-processor	healthy	13.822	\N	http://job-processor:8003/health	200	2025-10-08 17:48:21.187871
6233	file-manager	healthy	14.864	\N	http://file-manager:8004/health	200	2025-10-08 17:48:21.187871
6234	notification	healthy	14.817	\N	http://notification:8005/health	200	2025-10-08 17:48:21.187872
6235	api-gateway	healthy	321.213	\N	http://api-gateway:8000/health	200	2025-10-08 17:48:52.519224
6236	user-service	healthy	14.648	\N	http://user-service:8001/health	200	2025-10-08 17:48:52.519227
6237	service-registry	healthy	12.515	\N	http://service-registry:8002/health	200	2025-10-08 17:48:52.519227
6238	job-processor	healthy	13.982	\N	http://job-processor:8003/health	200	2025-10-08 17:48:52.519228
6239	file-manager	healthy	15.716000000000001	\N	http://file-manager:8004/health	200	2025-10-08 17:48:52.519229
6240	notification	healthy	15.313	\N	http://notification:8005/health	200	2025-10-08 17:48:52.519229
6241	api-gateway	healthy	360.16700000000003	\N	http://api-gateway:8000/health	200	2025-10-08 17:49:23.889606
6242	user-service	healthy	17.853	\N	http://user-service:8001/health	200	2025-10-08 17:49:23.889609
6243	service-registry	healthy	11.869	\N	http://service-registry:8002/health	200	2025-10-08 17:49:23.88961
6244	job-processor	healthy	23.168000000000003	\N	http://job-processor:8003/health	200	2025-10-08 17:49:23.889611
6245	file-manager	healthy	23.102999999999998	\N	http://file-manager:8004/health	200	2025-10-08 17:49:23.889611
6246	notification	healthy	27.5	\N	http://notification:8005/health	200	2025-10-08 17:49:23.889612
6247	api-gateway	healthy	686.0070000000001	\N	http://api-gateway:8000/health	200	2025-10-08 17:49:55.595366
6248	user-service	healthy	22.41	\N	http://user-service:8001/health	200	2025-10-08 17:49:55.595369
6249	service-registry	healthy	20.997	\N	http://service-registry:8002/health	200	2025-10-08 17:49:55.59537
6250	job-processor	healthy	26.468	\N	http://job-processor:8003/health	200	2025-10-08 17:49:55.595371
6251	file-manager	healthy	36.13	\N	http://file-manager:8004/health	200	2025-10-08 17:49:55.595371
6252	notification	healthy	23.054000000000002	\N	http://notification:8005/health	200	2025-10-08 17:49:55.595372
6253	api-gateway	healthy	445.272	\N	http://api-gateway:8000/health	200	2025-10-08 17:50:27.067186
6254	user-service	healthy	51.604	\N	http://user-service:8001/health	200	2025-10-08 17:50:27.067188
6255	service-registry	healthy	50.321	\N	http://service-registry:8002/health	200	2025-10-08 17:50:27.067189
6256	job-processor	healthy	66.4	\N	http://job-processor:8003/health	200	2025-10-08 17:50:27.06719
6257	file-manager	healthy	66.318	\N	http://file-manager:8004/health	200	2025-10-08 17:50:27.06719
6258	notification	healthy	66.238	\N	http://notification:8005/health	200	2025-10-08 17:50:27.067191
6259	api-gateway	healthy	305.65799999999996	\N	http://api-gateway:8000/health	200	2025-10-08 17:50:58.388609
6260	user-service	healthy	13.401	\N	http://user-service:8001/health	200	2025-10-08 17:50:58.388611
6261	service-registry	healthy	11.758	\N	http://service-registry:8002/health	200	2025-10-08 17:50:58.388612
6262	job-processor	healthy	13.667	\N	http://job-processor:8003/health	200	2025-10-08 17:50:58.388613
6263	file-manager	healthy	14.163	\N	http://file-manager:8004/health	200	2025-10-08 17:50:58.388613
6264	notification	healthy	14.624	\N	http://notification:8005/health	200	2025-10-08 17:50:58.388614
6265	api-gateway	healthy	867.355	\N	http://api-gateway:8000/health	200	2025-10-08 17:51:30.272792
6266	user-service	healthy	34.092	\N	http://user-service:8001/health	200	2025-10-08 17:51:30.272794
6267	service-registry	healthy	23.157	\N	http://service-registry:8002/health	200	2025-10-08 17:51:30.272795
6268	job-processor	healthy	33.417	\N	http://job-processor:8003/health	200	2025-10-08 17:51:30.272795
6269	file-manager	healthy	32.656	\N	http://file-manager:8004/health	200	2025-10-08 17:51:30.272796
6270	notification	healthy	32.59	\N	http://notification:8005/health	200	2025-10-08 17:51:30.272797
6271	api-gateway	healthy	384.025	\N	http://api-gateway:8000/health	200	2025-10-08 17:52:01.681795
6272	user-service	healthy	38.991	\N	http://user-service:8001/health	200	2025-10-08 17:52:01.681798
6273	service-registry	healthy	38.464999999999996	\N	http://service-registry:8002/health	200	2025-10-08 17:52:01.681798
6274	job-processor	healthy	48.879	\N	http://job-processor:8003/health	200	2025-10-08 17:52:01.681799
6275	file-manager	healthy	48.793000000000006	\N	http://file-manager:8004/health	200	2025-10-08 17:52:01.6818
6276	notification	healthy	49.504	\N	http://notification:8005/health	200	2025-10-08 17:52:01.6818
6277	api-gateway	healthy	375.652	\N	http://api-gateway:8000/health	200	2025-10-08 17:52:33.073266
6278	user-service	healthy	24.641	\N	http://user-service:8001/health	200	2025-10-08 17:52:33.073269
6279	service-registry	healthy	25.998	\N	http://service-registry:8002/health	200	2025-10-08 17:52:33.073269
6280	job-processor	healthy	27.882	\N	http://job-processor:8003/health	200	2025-10-08 17:52:33.07327
6281	file-manager	healthy	28.793	\N	http://file-manager:8004/health	200	2025-10-08 17:52:33.073271
6282	notification	healthy	31.398000000000003	\N	http://notification:8005/health	200	2025-10-08 17:52:33.073272
6283	api-gateway	healthy	359.223	\N	http://api-gateway:8000/health	200	2025-10-08 17:53:04.455037
6284	user-service	healthy	21.518	\N	http://user-service:8001/health	200	2025-10-08 17:53:04.45504
6285	service-registry	healthy	20.243000000000002	\N	http://service-registry:8002/health	200	2025-10-08 17:53:04.455041
6286	job-processor	healthy	22.123	\N	http://job-processor:8003/health	200	2025-10-08 17:53:04.455042
6287	file-manager	healthy	22.027	\N	http://file-manager:8004/health	200	2025-10-08 17:53:04.455043
6288	notification	healthy	22.478	\N	http://notification:8005/health	200	2025-10-08 17:53:04.455043
6289	api-gateway	healthy	319.20799999999997	\N	http://api-gateway:8000/health	200	2025-10-08 17:53:35.785628
6290	user-service	healthy	13.511000000000001	\N	http://user-service:8001/health	200	2025-10-08 17:53:35.78563
6291	service-registry	healthy	11.412	\N	http://service-registry:8002/health	200	2025-10-08 17:53:35.785631
6292	job-processor	healthy	12.741000000000001	\N	http://job-processor:8003/health	200	2025-10-08 17:53:35.785632
6293	file-manager	healthy	14.705	\N	http://file-manager:8004/health	200	2025-10-08 17:53:35.785633
6294	notification	healthy	13.488999999999999	\N	http://notification:8005/health	200	2025-10-08 17:53:35.785633
6295	api-gateway	healthy	326.456	\N	http://api-gateway:8000/health	200	2025-10-08 17:54:07.123275
6296	user-service	healthy	18.022	\N	http://user-service:8001/health	200	2025-10-08 17:54:07.123277
6297	service-registry	healthy	17.517999999999997	\N	http://service-registry:8002/health	200	2025-10-08 17:54:07.123278
6298	job-processor	healthy	19.918000000000003	\N	http://job-processor:8003/health	200	2025-10-08 17:54:07.123279
6299	file-manager	healthy	19.209	\N	http://file-manager:8004/health	200	2025-10-08 17:54:07.12328
6300	notification	healthy	19.184	\N	http://notification:8005/health	200	2025-10-08 17:54:07.12328
6301	api-gateway	healthy	317.96999999999997	\N	http://api-gateway:8000/health	200	2025-10-08 17:54:38.452685
6302	user-service	healthy	13.069	\N	http://user-service:8001/health	200	2025-10-08 17:54:38.452688
6303	service-registry	healthy	12.921	\N	http://service-registry:8002/health	200	2025-10-08 17:54:38.452688
6304	job-processor	healthy	15.022	\N	http://job-processor:8003/health	200	2025-10-08 17:54:38.452689
6305	file-manager	healthy	15.109	\N	http://file-manager:8004/health	200	2025-10-08 17:54:38.45269
6306	notification	healthy	14.678999999999998	\N	http://notification:8005/health	200	2025-10-08 17:54:38.452691
6307	api-gateway	healthy	331.931	\N	http://api-gateway:8000/health	200	2025-10-08 17:55:09.799315
6308	user-service	healthy	16.095000000000002	\N	http://user-service:8001/health	200	2025-10-08 17:55:09.799318
6309	service-registry	healthy	15.841000000000001	\N	http://service-registry:8002/health	200	2025-10-08 17:55:09.799319
6310	job-processor	healthy	16.990000000000002	\N	http://job-processor:8003/health	200	2025-10-08 17:55:09.79932
6311	file-manager	healthy	16.916	\N	http://file-manager:8004/health	200	2025-10-08 17:55:09.799321
6312	notification	healthy	17.555	\N	http://notification:8005/health	200	2025-10-08 17:55:09.799322
6313	api-gateway	healthy	335.51599999999996	\N	http://api-gateway:8000/health	200	2025-10-08 17:55:41.146438
6314	user-service	healthy	15.507	\N	http://user-service:8001/health	200	2025-10-08 17:55:41.146441
6315	service-registry	healthy	12.636	\N	http://service-registry:8002/health	200	2025-10-08 17:55:41.146442
6316	job-processor	healthy	13.831	\N	http://job-processor:8003/health	200	2025-10-08 17:55:41.146442
6317	file-manager	healthy	11.802999999999999	\N	http://file-manager:8004/health	200	2025-10-08 17:55:41.146443
6318	notification	healthy	13.504999999999999	\N	http://notification:8005/health	200	2025-10-08 17:55:41.146443
6319	api-gateway	healthy	313.061	\N	http://api-gateway:8000/health	200	2025-10-08 17:56:12.471928
6320	user-service	healthy	10.200000000000001	\N	http://user-service:8001/health	200	2025-10-08 17:56:12.471931
6321	service-registry	healthy	10.050999999999998	\N	http://service-registry:8002/health	200	2025-10-08 17:56:12.471932
6322	job-processor	healthy	12.126	\N	http://job-processor:8003/health	200	2025-10-08 17:56:12.471932
6323	file-manager	healthy	12.103	\N	http://file-manager:8004/health	200	2025-10-08 17:56:12.471933
6324	notification	healthy	11.436	\N	http://notification:8005/health	200	2025-10-08 17:56:12.471933
6325	api-gateway	healthy	637.61	\N	http://api-gateway:8000/health	200	2025-10-08 17:56:44.122547
6326	user-service	healthy	12.073	\N	http://user-service:8001/health	200	2025-10-08 17:56:44.122549
6327	service-registry	healthy	14.244	\N	http://service-registry:8002/health	200	2025-10-08 17:56:44.12255
6328	job-processor	healthy	12.283000000000001	\N	http://job-processor:8003/health	200	2025-10-08 17:56:44.122551
6329	file-manager	healthy	17.302000000000003	\N	http://file-manager:8004/health	200	2025-10-08 17:56:44.122552
6330	notification	healthy	15.104	\N	http://notification:8005/health	200	2025-10-08 17:56:44.122552
6331	api-gateway	healthy	310.428	\N	http://api-gateway:8000/health	200	2025-10-08 17:57:15.44436
6332	user-service	healthy	15.817000000000002	\N	http://user-service:8001/health	200	2025-10-08 17:57:15.444362
6333	service-registry	healthy	15.671000000000001	\N	http://service-registry:8002/health	200	2025-10-08 17:57:15.444363
6334	job-processor	healthy	14.322	\N	http://job-processor:8003/health	200	2025-10-08 17:57:15.444363
6335	file-manager	healthy	14.258	\N	http://file-manager:8004/health	200	2025-10-08 17:57:15.444364
6336	notification	healthy	15.249	\N	http://notification:8005/health	200	2025-10-08 17:57:15.444364
6337	api-gateway	healthy	326.61400000000003	\N	http://api-gateway:8000/health	200	2025-10-08 17:57:46.781916
6338	user-service	healthy	12.479000000000001	\N	http://user-service:8001/health	200	2025-10-08 17:57:46.781918
6339	service-registry	healthy	10.938	\N	http://service-registry:8002/health	200	2025-10-08 17:57:46.781919
6340	job-processor	healthy	12.895	\N	http://job-processor:8003/health	200	2025-10-08 17:57:46.78192
6341	file-manager	healthy	14.286999999999999	\N	http://file-manager:8004/health	200	2025-10-08 17:57:46.78192
6342	notification	healthy	14.248000000000001	\N	http://notification:8005/health	200	2025-10-08 17:57:46.781921
6343	api-gateway	healthy	318.49499999999995	\N	http://api-gateway:8000/health	200	2025-10-08 17:58:18.115102
6344	user-service	healthy	11.144	\N	http://user-service:8001/health	200	2025-10-08 17:58:18.115105
6345	service-registry	healthy	11.766	\N	http://service-registry:8002/health	200	2025-10-08 17:58:18.115106
6346	job-processor	healthy	12.342	\N	http://job-processor:8003/health	200	2025-10-08 17:58:18.115106
6347	file-manager	healthy	13.57	\N	http://file-manager:8004/health	200	2025-10-08 17:58:18.115107
6348	notification	healthy	13.15	\N	http://notification:8005/health	200	2025-10-08 17:58:18.115108
6349	api-gateway	healthy	320.98199999999997	\N	http://api-gateway:8000/health	200	2025-10-08 17:58:49.45007
6350	user-service	healthy	16.686	\N	http://user-service:8001/health	200	2025-10-08 17:58:49.450073
6351	service-registry	healthy	16.518	\N	http://service-registry:8002/health	200	2025-10-08 17:58:49.450073
6352	job-processor	healthy	16.42	\N	http://job-processor:8003/health	200	2025-10-08 17:58:49.450074
6353	file-manager	healthy	16.324	\N	http://file-manager:8004/health	200	2025-10-08 17:58:49.450075
6354	notification	healthy	16.937	\N	http://notification:8005/health	200	2025-10-08 17:58:49.450076
6355	api-gateway	healthy	323.1	\N	http://api-gateway:8000/health	200	2025-10-08 17:59:20.783128
6356	user-service	healthy	11.891	\N	http://user-service:8001/health	200	2025-10-08 17:59:20.78313
6357	service-registry	healthy	11.442	\N	http://service-registry:8002/health	200	2025-10-08 17:59:20.783131
6358	job-processor	healthy	12.481000000000002	\N	http://job-processor:8003/health	200	2025-10-08 17:59:20.783131
6359	file-manager	healthy	12.408000000000001	\N	http://file-manager:8004/health	200	2025-10-08 17:59:20.783132
6360	notification	healthy	12.822999999999999	\N	http://notification:8005/health	200	2025-10-08 17:59:20.783133
6361	api-gateway	healthy	334.517	\N	http://api-gateway:8000/health	200	2025-10-08 17:59:52.12913
6362	user-service	healthy	17.723	\N	http://user-service:8001/health	200	2025-10-08 17:59:52.129132
6363	service-registry	healthy	17.584	\N	http://service-registry:8002/health	200	2025-10-08 17:59:52.129133
6364	job-processor	healthy	17.493000000000002	\N	http://job-processor:8003/health	200	2025-10-08 17:59:52.129134
6365	file-manager	healthy	17.401	\N	http://file-manager:8004/health	200	2025-10-08 17:59:52.129134
6366	notification	healthy	18.402	\N	http://notification:8005/health	200	2025-10-08 17:59:52.129135
6367	api-gateway	healthy	340.771	\N	http://api-gateway:8000/health	200	2025-10-08 18:00:23.483549
6368	user-service	healthy	16.187	\N	http://user-service:8001/health	200	2025-10-08 18:00:23.483551
6369	service-registry	healthy	15.611	\N	http://service-registry:8002/health	200	2025-10-08 18:00:23.483552
6370	job-processor	healthy	17.728	\N	http://job-processor:8003/health	200	2025-10-08 18:00:23.483553
6371	file-manager	healthy	17.649	\N	http://file-manager:8004/health	200	2025-10-08 18:00:23.483553
6372	notification	healthy	17.735	\N	http://notification:8005/health	200	2025-10-08 18:00:23.483554
6373	api-gateway	healthy	316.426	\N	http://api-gateway:8000/health	200	2025-10-08 18:00:54.812259
6374	user-service	healthy	14.487	\N	http://user-service:8001/health	200	2025-10-08 18:00:54.812261
6375	service-registry	healthy	14.033	\N	http://service-registry:8002/health	200	2025-10-08 18:00:54.812262
6376	job-processor	healthy	14.078999999999999	\N	http://job-processor:8003/health	200	2025-10-08 18:00:54.812262
6377	file-manager	healthy	13.971	\N	http://file-manager:8004/health	200	2025-10-08 18:00:54.812263
6378	notification	healthy	14.616999999999999	\N	http://notification:8005/health	200	2025-10-08 18:00:54.812263
6379	api-gateway	healthy	314.083	\N	http://api-gateway:8000/health	200	2025-10-08 18:01:26.144555
6380	user-service	healthy	11.802	\N	http://user-service:8001/health	200	2025-10-08 18:01:26.144557
6381	service-registry	healthy	12.921	\N	http://service-registry:8002/health	200	2025-10-08 18:01:26.144558
6382	job-processor	healthy	12.831	\N	http://job-processor:8003/health	200	2025-10-08 18:01:26.144559
6383	file-manager	healthy	13.555	\N	http://file-manager:8004/health	200	2025-10-08 18:01:26.144559
6384	notification	healthy	14.266	\N	http://notification:8005/health	200	2025-10-08 18:01:26.14456
6385	api-gateway	healthy	343.74100000000004	\N	http://api-gateway:8000/health	200	2025-10-08 18:01:57.500442
6386	user-service	healthy	14.951	\N	http://user-service:8001/health	200	2025-10-08 18:01:57.500444
6387	service-registry	healthy	13.588	\N	http://service-registry:8002/health	200	2025-10-08 18:01:57.500445
6388	job-processor	healthy	15.269	\N	http://job-processor:8003/health	200	2025-10-08 18:01:57.500446
6389	file-manager	healthy	19.598999999999997	\N	http://file-manager:8004/health	200	2025-10-08 18:01:57.500447
6390	notification	healthy	19.528	\N	http://notification:8005/health	200	2025-10-08 18:01:57.500447
6391	api-gateway	healthy	309.20300000000003	\N	http://api-gateway:8000/health	200	2025-10-08 18:02:28.823018
6392	user-service	healthy	13.676	\N	http://user-service:8001/health	200	2025-10-08 18:02:28.823021
6393	service-registry	healthy	13.514999999999999	\N	http://service-registry:8002/health	200	2025-10-08 18:02:28.823021
6394	job-processor	healthy	13.452	\N	http://job-processor:8003/health	200	2025-10-08 18:02:28.823022
6395	file-manager	healthy	14.626999999999999	\N	http://file-manager:8004/health	200	2025-10-08 18:02:28.823023
6396	notification	healthy	14.566	\N	http://notification:8005/health	200	2025-10-08 18:02:28.823023
6397	api-gateway	healthy	311.847	\N	http://api-gateway:8000/health	200	2025-10-08 18:03:00.145992
6398	user-service	healthy	12.31	\N	http://user-service:8001/health	200	2025-10-08 18:03:00.145994
6399	service-registry	healthy	14.226	\N	http://service-registry:8002/health	200	2025-10-08 18:03:00.145995
6400	job-processor	healthy	13.816	\N	http://job-processor:8003/health	200	2025-10-08 18:03:00.145995
6401	file-manager	healthy	13.891	\N	http://file-manager:8004/health	200	2025-10-08 18:03:00.145996
6402	notification	healthy	14.603	\N	http://notification:8005/health	200	2025-10-08 18:03:00.145997
6403	api-gateway	healthy	308.876	\N	http://api-gateway:8000/health	200	2025-10-08 18:03:31.4659
6404	user-service	healthy	15.302	\N	http://user-service:8001/health	200	2025-10-08 18:03:31.465903
6405	service-registry	healthy	15.091000000000001	\N	http://service-registry:8002/health	200	2025-10-08 18:03:31.465903
6406	job-processor	healthy	14.956000000000001	\N	http://job-processor:8003/health	200	2025-10-08 18:03:31.465904
6407	file-manager	healthy	14.854	\N	http://file-manager:8004/health	200	2025-10-08 18:03:31.465904
6408	notification	healthy	15.544	\N	http://notification:8005/health	200	2025-10-08 18:03:31.465905
6409	api-gateway	healthy	335.132	\N	http://api-gateway:8000/health	200	2025-10-08 18:04:02.812792
6410	user-service	healthy	11.858	\N	http://user-service:8001/health	200	2025-10-08 18:04:02.812794
6411	service-registry	healthy	11.405	\N	http://service-registry:8002/health	200	2025-10-08 18:04:02.812795
6412	job-processor	healthy	19.965	\N	http://job-processor:8003/health	200	2025-10-08 18:04:02.812795
6413	file-manager	healthy	19.352	\N	http://file-manager:8004/health	200	2025-10-08 18:04:02.812796
6414	notification	healthy	19.288	\N	http://notification:8005/health	200	2025-10-08 18:04:02.812796
6415	api-gateway	healthy	315.224	\N	http://api-gateway:8000/health	200	2025-10-08 18:04:34.138388
6416	user-service	healthy	12.356	\N	http://user-service:8001/health	200	2025-10-08 18:04:34.13839
6417	service-registry	healthy	10.356	\N	http://service-registry:8002/health	200	2025-10-08 18:04:34.138391
6418	job-processor	healthy	12.331	\N	http://job-processor:8003/health	200	2025-10-08 18:04:34.138392
6419	file-manager	healthy	13.459999999999999	\N	http://file-manager:8004/health	200	2025-10-08 18:04:34.138392
6420	notification	healthy	13.023	\N	http://notification:8005/health	200	2025-10-08 18:04:34.138393
6421	api-gateway	healthy	321.603	\N	http://api-gateway:8000/health	200	2025-10-08 18:05:05.473042
6422	user-service	healthy	16.134	\N	http://user-service:8001/health	200	2025-10-08 18:05:05.473044
6423	service-registry	healthy	16.066	\N	http://service-registry:8002/health	200	2025-10-08 18:05:05.473045
6424	job-processor	healthy	15.663	\N	http://job-processor:8003/health	200	2025-10-08 18:05:05.473046
6425	file-manager	healthy	15.726	\N	http://file-manager:8004/health	200	2025-10-08 18:05:05.473046
6426	notification	healthy	16.365000000000002	\N	http://notification:8005/health	200	2025-10-08 18:05:05.473047
6427	api-gateway	healthy	358.118	\N	http://api-gateway:8000/health	200	2025-10-08 18:05:36.842124
6428	user-service	healthy	13.668	\N	http://user-service:8001/health	200	2025-10-08 18:05:36.842126
6429	service-registry	healthy	13.193	\N	http://service-registry:8002/health	200	2025-10-08 18:05:36.842127
6430	job-processor	healthy	13.223	\N	http://job-processor:8003/health	200	2025-10-08 18:05:36.842128
6431	file-manager	healthy	14.202	\N	http://file-manager:8004/health	200	2025-10-08 18:05:36.842128
6432	notification	healthy	14.142999999999999	\N	http://notification:8005/health	200	2025-10-08 18:05:36.842129
6433	api-gateway	healthy	312.93	\N	http://api-gateway:8000/health	200	2025-10-08 18:06:08.166041
6434	user-service	healthy	14.466	\N	http://user-service:8001/health	200	2025-10-08 18:06:08.166043
6435	service-registry	healthy	12.616999999999999	\N	http://service-registry:8002/health	200	2025-10-08 18:06:08.166044
6436	job-processor	healthy	12.508999999999999	\N	http://job-processor:8003/health	200	2025-10-08 18:06:08.166044
6437	file-manager	healthy	11.985000000000001	\N	http://file-manager:8004/health	200	2025-10-08 18:06:08.166045
6438	notification	healthy	13.668	\N	http://notification:8005/health	200	2025-10-08 18:06:08.166045
6439	api-gateway	healthy	318.78299999999996	\N	http://api-gateway:8000/health	200	2025-10-08 18:06:39.49395
6440	user-service	healthy	11.294	\N	http://user-service:8001/health	200	2025-10-08 18:06:39.493952
6441	service-registry	healthy	11.113	\N	http://service-registry:8002/health	200	2025-10-08 18:06:39.493953
6442	job-processor	healthy	17.657	\N	http://job-processor:8003/health	200	2025-10-08 18:06:39.493954
6443	file-manager	healthy	17.575	\N	http://file-manager:8004/health	200	2025-10-08 18:06:39.493954
6444	notification	healthy	17.476	\N	http://notification:8005/health	200	2025-10-08 18:06:39.493955
6445	api-gateway	healthy	407.652	\N	http://api-gateway:8000/health	200	2025-10-08 18:07:10.913295
6446	user-service	healthy	29.662000000000003	\N	http://user-service:8001/health	200	2025-10-08 18:07:10.913297
6447	service-registry	healthy	29.419	\N	http://service-registry:8002/health	200	2025-10-08 18:07:10.913298
6448	job-processor	healthy	28.849	\N	http://job-processor:8003/health	200	2025-10-08 18:07:10.913299
6449	file-manager	healthy	29.425	\N	http://file-manager:8004/health	200	2025-10-08 18:07:10.913299
6450	notification	healthy	30.018	\N	http://notification:8005/health	200	2025-10-08 18:07:10.9133
6451	api-gateway	healthy	318.284	\N	http://api-gateway:8000/health	200	2025-10-08 18:07:42.242647
6452	user-service	healthy	12.81	\N	http://user-service:8001/health	200	2025-10-08 18:07:42.24265
6453	service-registry	healthy	12.368	\N	http://service-registry:8002/health	200	2025-10-08 18:07:42.242651
6454	job-processor	healthy	13.919	\N	http://job-processor:8003/health	200	2025-10-08 18:07:42.242651
6455	file-manager	healthy	13.823	\N	http://file-manager:8004/health	200	2025-10-08 18:07:42.242652
6456	notification	healthy	13.742	\N	http://notification:8005/health	200	2025-10-08 18:07:42.242653
6457	api-gateway	healthy	305.271	\N	http://api-gateway:8000/health	200	2025-10-08 18:08:13.558289
6458	user-service	healthy	12.599	\N	http://user-service:8001/health	200	2025-10-08 18:08:13.558292
6459	service-registry	healthy	12.144	\N	http://service-registry:8002/health	200	2025-10-08 18:08:13.558292
6460	job-processor	healthy	13.437	\N	http://job-processor:8003/health	200	2025-10-08 18:08:13.558293
6461	file-manager	healthy	13.377	\N	http://file-manager:8004/health	200	2025-10-08 18:08:13.558294
6462	notification	healthy	13.971	\N	http://notification:8005/health	200	2025-10-08 18:08:13.558294
6463	api-gateway	healthy	308.594	\N	http://api-gateway:8000/health	200	2025-10-08 18:08:44.878879
6464	user-service	healthy	11.745000000000001	\N	http://user-service:8001/health	200	2025-10-08 18:08:44.878882
6465	service-registry	healthy	12.186	\N	http://service-registry:8002/health	200	2025-10-08 18:08:44.878883
6466	job-processor	healthy	14.22	\N	http://job-processor:8003/health	200	2025-10-08 18:08:44.878883
6467	file-manager	healthy	14.164	\N	http://file-manager:8004/health	200	2025-10-08 18:08:44.878884
6468	notification	healthy	13.589	\N	http://notification:8005/health	200	2025-10-08 18:08:44.878885
6469	api-gateway	healthy	312.784	\N	http://api-gateway:8000/health	200	2025-10-08 18:09:16.202827
6470	user-service	healthy	15.34	\N	http://user-service:8001/health	200	2025-10-08 18:09:16.20283
6471	service-registry	healthy	15.181000000000001	\N	http://service-registry:8002/health	200	2025-10-08 18:09:16.202831
6472	job-processor	healthy	15.042	\N	http://job-processor:8003/health	200	2025-10-08 18:09:16.202831
6473	file-manager	healthy	14.947999999999999	\N	http://file-manager:8004/health	200	2025-10-08 18:09:16.202832
6474	notification	healthy	15.636000000000001	\N	http://notification:8005/health	200	2025-10-08 18:09:16.202833
6475	api-gateway	healthy	313.99399999999997	\N	http://api-gateway:8000/health	200	2025-10-08 18:09:47.52775
6476	user-service	healthy	14.732999999999999	\N	http://user-service:8001/health	200	2025-10-08 18:09:47.527753
6477	service-registry	healthy	14.718	\N	http://service-registry:8002/health	200	2025-10-08 18:09:47.527754
6478	job-processor	healthy	14.325	\N	http://job-processor:8003/health	200	2025-10-08 18:09:47.527755
6479	file-manager	healthy	15.695	\N	http://file-manager:8004/health	200	2025-10-08 18:09:47.527755
6480	notification	healthy	15.291	\N	http://notification:8005/health	200	2025-10-08 18:09:47.527756
6481	api-gateway	healthy	313.758	\N	http://api-gateway:8000/health	200	2025-10-08 18:10:18.852048
6482	user-service	healthy	15.32	\N	http://user-service:8001/health	200	2025-10-08 18:10:18.85205
6483	service-registry	healthy	15.171000000000001	\N	http://service-registry:8002/health	200	2025-10-08 18:10:18.852051
6484	job-processor	healthy	15.067	\N	http://job-processor:8003/health	200	2025-10-08 18:10:18.852052
6485	file-manager	healthy	15.027000000000001	\N	http://file-manager:8004/health	200	2025-10-08 18:10:18.852052
6486	notification	healthy	15.453	\N	http://notification:8005/health	200	2025-10-08 18:10:18.852053
6487	api-gateway	healthy	327.834	\N	http://api-gateway:8000/health	200	2025-10-08 18:10:50.189834
6488	user-service	healthy	14.052	\N	http://user-service:8001/health	200	2025-10-08 18:10:50.189837
6489	service-registry	healthy	13.584000000000001	\N	http://service-registry:8002/health	200	2025-10-08 18:10:50.189837
6490	job-processor	healthy	16.051	\N	http://job-processor:8003/health	200	2025-10-08 18:10:50.189838
6491	file-manager	healthy	15.620999999999999	\N	http://file-manager:8004/health	200	2025-10-08 18:10:50.189839
6492	notification	healthy	15.096	\N	http://notification:8005/health	200	2025-10-08 18:10:50.189839
6493	api-gateway	healthy	309.819	\N	http://api-gateway:8000/health	200	2025-10-08 18:11:21.510123
6494	user-service	healthy	15.606	\N	http://user-service:8001/health	200	2025-10-08 18:11:21.510125
6495	service-registry	healthy	15.5	\N	http://service-registry:8002/health	200	2025-10-08 18:11:21.510126
6496	job-processor	healthy	14.921	\N	http://job-processor:8003/health	200	2025-10-08 18:11:21.510127
6497	file-manager	healthy	14.555	\N	http://file-manager:8004/health	200	2025-10-08 18:11:21.510127
6498	notification	healthy	15.69	\N	http://notification:8005/health	200	2025-10-08 18:11:21.510128
6499	api-gateway	healthy	385.243	\N	http://api-gateway:8000/health	200	2025-10-08 18:11:52.909795
6500	user-service	healthy	17.674	\N	http://user-service:8001/health	200	2025-10-08 18:11:52.909798
6501	service-registry	healthy	17.169	\N	http://service-registry:8002/health	200	2025-10-08 18:11:52.909798
6502	job-processor	healthy	19.173	\N	http://job-processor:8003/health	200	2025-10-08 18:11:52.909799
6503	file-manager	healthy	18.732	\N	http://file-manager:8004/health	200	2025-10-08 18:11:52.9098
6504	notification	healthy	18.8	\N	http://notification:8005/health	200	2025-10-08 18:11:52.9098
6505	api-gateway	healthy	357.203	\N	http://api-gateway:8000/health	200	2025-10-08 18:12:24.279509
6506	user-service	healthy	17.394	\N	http://user-service:8001/health	200	2025-10-08 18:12:24.279512
6507	service-registry	healthy	17.177	\N	http://service-registry:8002/health	200	2025-10-08 18:12:24.279512
6508	job-processor	healthy	19.102999999999998	\N	http://job-processor:8003/health	200	2025-10-08 18:12:24.279513
6509	file-manager	healthy	19.032	\N	http://file-manager:8004/health	200	2025-10-08 18:12:24.279513
6510	notification	healthy	18.961	\N	http://notification:8005/health	200	2025-10-08 18:12:24.279514
6511	api-gateway	healthy	319.42900000000003	\N	http://api-gateway:8000/health	200	2025-10-08 18:12:55.612815
6512	user-service	healthy	12.766	\N	http://user-service:8001/health	200	2025-10-08 18:12:55.612817
6513	service-registry	healthy	13.303	\N	http://service-registry:8002/health	200	2025-10-08 18:12:55.612818
6514	job-processor	healthy	14.314	\N	http://job-processor:8003/health	200	2025-10-08 18:12:55.612819
6515	file-manager	healthy	14.203000000000001	\N	http://file-manager:8004/health	200	2025-10-08 18:12:55.612819
6516	notification	healthy	14.828	\N	http://notification:8005/health	200	2025-10-08 18:12:55.61282
6517	api-gateway	healthy	617.992	\N	http://api-gateway:8000/health	200	2025-10-08 18:13:27.242609
6518	user-service	healthy	20.099	\N	http://user-service:8001/health	200	2025-10-08 18:13:27.242612
6519	service-registry	healthy	19.912	\N	http://service-registry:8002/health	200	2025-10-08 18:13:27.242613
6520	job-processor	healthy	19.834	\N	http://job-processor:8003/health	200	2025-10-08 18:13:27.242614
6521	file-manager	healthy	19.073	\N	http://file-manager:8004/health	200	2025-10-08 18:13:27.242614
6522	notification	healthy	20.278000000000002	\N	http://notification:8005/health	200	2025-10-08 18:13:27.242615
6523	api-gateway	healthy	336.532	\N	http://api-gateway:8000/health	200	2025-10-08 18:13:58.589323
6524	user-service	healthy	11.168000000000001	\N	http://user-service:8001/health	200	2025-10-08 18:13:58.589326
6525	service-registry	healthy	13.504	\N	http://service-registry:8002/health	200	2025-10-08 18:13:58.589327
6526	job-processor	healthy	13.100000000000001	\N	http://job-processor:8003/health	200	2025-10-08 18:13:58.589327
6527	file-manager	healthy	13.76	\N	http://file-manager:8004/health	200	2025-10-08 18:13:58.589328
6528	notification	healthy	14.216	\N	http://notification:8005/health	200	2025-10-08 18:13:58.589328
6529	api-gateway	healthy	308.398	\N	http://api-gateway:8000/health	200	2025-10-08 18:14:29.907938
6530	user-service	healthy	14.600999999999999	\N	http://user-service:8001/health	200	2025-10-08 18:14:29.907941
6531	service-registry	healthy	14.161	\N	http://service-registry:8002/health	200	2025-10-08 18:14:29.907942
6532	job-processor	healthy	15.674000000000001	\N	http://job-processor:8003/health	200	2025-10-08 18:14:29.907942
6533	file-manager	healthy	15.579	\N	http://file-manager:8004/health	200	2025-10-08 18:14:29.907943
6534	notification	healthy	15.566	\N	http://notification:8005/health	200	2025-10-08 18:14:29.907944
6535	api-gateway	healthy	306.831	\N	http://api-gateway:8000/health	200	2025-10-08 18:15:01.22904
6536	user-service	healthy	14.041	\N	http://user-service:8001/health	200	2025-10-08 18:15:01.229043
6537	service-registry	healthy	13.602	\N	http://service-registry:8002/health	200	2025-10-08 18:15:01.229043
6538	job-processor	healthy	13.641	\N	http://job-processor:8003/health	200	2025-10-08 18:15:01.229044
6539	file-manager	healthy	12.921999999999999	\N	http://file-manager:8004/health	200	2025-10-08 18:15:01.229045
6540	notification	healthy	13.798	\N	http://notification:8005/health	200	2025-10-08 18:15:01.229045
6541	api-gateway	healthy	324.352	\N	http://api-gateway:8000/health	200	2025-10-08 18:15:32.564234
6542	user-service	healthy	16.358	\N	http://user-service:8001/health	200	2025-10-08 18:15:32.564237
6543	service-registry	healthy	16.173	\N	http://service-registry:8002/health	200	2025-10-08 18:15:32.564237
6544	job-processor	healthy	16.067	\N	http://job-processor:8003/health	200	2025-10-08 18:15:32.564238
6545	file-manager	healthy	15.994000000000002	\N	http://file-manager:8004/health	200	2025-10-08 18:15:32.564239
6546	notification	healthy	16.695999999999998	\N	http://notification:8005/health	200	2025-10-08 18:15:32.564239
6547	api-gateway	healthy	309.487	\N	http://api-gateway:8000/health	200	2025-10-08 18:16:03.889762
6548	user-service	healthy	13.868	\N	http://user-service:8001/health	200	2025-10-08 18:16:03.889764
6549	service-registry	healthy	13.655000000000001	\N	http://service-registry:8002/health	200	2025-10-08 18:16:03.889765
6550	job-processor	healthy	13.540999999999999	\N	http://job-processor:8003/health	200	2025-10-08 18:16:03.889765
6551	file-manager	healthy	13.457	\N	http://file-manager:8004/health	200	2025-10-08 18:16:03.889766
6552	notification	healthy	14.08	\N	http://notification:8005/health	200	2025-10-08 18:16:03.889767
6553	api-gateway	healthy	332.694	\N	http://api-gateway:8000/health	200	2025-10-08 18:16:35.234304
6554	user-service	healthy	10.411	\N	http://user-service:8001/health	200	2025-10-08 18:16:35.234306
6555	service-registry	healthy	11.429	\N	http://service-registry:8002/health	200	2025-10-08 18:16:35.234307
6556	job-processor	healthy	12.415000000000001	\N	http://job-processor:8003/health	200	2025-10-08 18:16:35.234308
6557	file-manager	healthy	13.703	\N	http://file-manager:8004/health	200	2025-10-08 18:16:35.234308
6558	notification	healthy	24.514	\N	http://notification:8005/health	200	2025-10-08 18:16:35.234309
6559	api-gateway	healthy	324.835	\N	http://api-gateway:8000/health	200	2025-10-08 18:17:06.568933
6560	user-service	healthy	14.454	\N	http://user-service:8001/health	200	2025-10-08 18:17:06.568936
6561	service-registry	healthy	13.993	\N	http://service-registry:8002/health	200	2025-10-08 18:17:06.568937
6562	job-processor	healthy	12.863	\N	http://job-processor:8003/health	200	2025-10-08 18:17:06.568937
6563	file-manager	healthy	12.77	\N	http://file-manager:8004/health	200	2025-10-08 18:17:06.568938
6564	notification	healthy	13.85	\N	http://notification:8005/health	200	2025-10-08 18:17:06.568938
6565	api-gateway	healthy	330.058	\N	http://api-gateway:8000/health	200	2025-10-08 18:17:37.909111
6566	user-service	healthy	12.992999999999999	\N	http://user-service:8001/health	200	2025-10-08 18:17:37.909114
6567	service-registry	healthy	13.912	\N	http://service-registry:8002/health	200	2025-10-08 18:17:37.909114
6568	job-processor	healthy	13.827	\N	http://job-processor:8003/health	200	2025-10-08 18:17:37.909115
6569	file-manager	healthy	14.876999999999999	\N	http://file-manager:8004/health	200	2025-10-08 18:17:37.909116
6570	notification	healthy	14.768	\N	http://notification:8005/health	200	2025-10-08 18:17:37.909116
6571	api-gateway	healthy	306.398	\N	http://api-gateway:8000/health	200	2025-10-08 18:18:09.225743
6572	user-service	healthy	12.258	\N	http://user-service:8001/health	200	2025-10-08 18:18:09.225746
6573	service-registry	healthy	13.25	\N	http://service-registry:8002/health	200	2025-10-08 18:18:09.225746
6574	job-processor	healthy	9.171999999999999	\N	http://job-processor:8003/health	200	2025-10-08 18:18:09.225747
6575	file-manager	healthy	11.261000000000001	\N	http://file-manager:8004/health	200	2025-10-08 18:18:09.225748
6576	notification	healthy	9.638	\N	http://notification:8005/health	200	2025-10-08 18:18:09.225748
6577	api-gateway	healthy	330.486	\N	http://api-gateway:8000/health	200	2025-10-08 18:18:40.566964
6578	user-service	healthy	14.946	\N	http://user-service:8001/health	200	2025-10-08 18:18:40.566967
6579	service-registry	healthy	14.795000000000002	\N	http://service-registry:8002/health	200	2025-10-08 18:18:40.566967
6580	job-processor	healthy	14.721	\N	http://job-processor:8003/health	200	2025-10-08 18:18:40.566968
6581	file-manager	healthy	14.684	\N	http://file-manager:8004/health	200	2025-10-08 18:18:40.566969
6582	notification	healthy	15.351	\N	http://notification:8005/health	200	2025-10-08 18:18:40.566969
6583	api-gateway	healthy	310.20799999999997	\N	http://api-gateway:8000/health	200	2025-10-08 18:19:11.887795
6584	user-service	healthy	14.173	\N	http://user-service:8001/health	200	2025-10-08 18:19:11.887797
6585	service-registry	healthy	14.021	\N	http://service-registry:8002/health	200	2025-10-08 18:19:11.887797
6586	job-processor	healthy	13.918	\N	http://job-processor:8003/health	200	2025-10-08 18:19:11.887798
6587	file-manager	healthy	13.844000000000001	\N	http://file-manager:8004/health	200	2025-10-08 18:19:11.887799
6588	notification	healthy	14.561	\N	http://notification:8005/health	200	2025-10-08 18:19:11.887799
6589	api-gateway	healthy	320.848	\N	http://api-gateway:8000/health	200	2025-10-08 18:19:43.2272
6590	user-service	healthy	14.536	\N	http://user-service:8001/health	200	2025-10-08 18:19:43.227203
6591	service-registry	healthy	13.966	\N	http://service-registry:8002/health	200	2025-10-08 18:19:43.227204
6592	job-processor	healthy	16.317	\N	http://job-processor:8003/health	200	2025-10-08 18:19:43.227204
6593	file-manager	healthy	15.684	\N	http://file-manager:8004/health	200	2025-10-08 18:19:43.227205
6594	notification	healthy	15.588	\N	http://notification:8005/health	200	2025-10-08 18:19:43.227206
6595	api-gateway	healthy	348.135	\N	http://api-gateway:8000/health	200	2025-10-08 18:20:14.586262
6596	user-service	healthy	11.834000000000001	\N	http://user-service:8001/health	200	2025-10-08 18:20:14.586264
6597	service-registry	healthy	11.76	\N	http://service-registry:8002/health	200	2025-10-08 18:20:14.586265
6598	job-processor	healthy	14.02	\N	http://job-processor:8003/health	200	2025-10-08 18:20:14.586265
6599	file-manager	healthy	13.950000000000001	\N	http://file-manager:8004/health	200	2025-10-08 18:20:14.586266
6600	notification	healthy	11.876	\N	http://notification:8005/health	200	2025-10-08 18:20:14.586267
6601	api-gateway	healthy	314.024	\N	http://api-gateway:8000/health	200	2025-10-08 18:20:45.909635
6602	user-service	healthy	14.722000000000001	\N	http://user-service:8001/health	200	2025-10-08 18:20:45.909637
6603	service-registry	healthy	14.609	\N	http://service-registry:8002/health	200	2025-10-08 18:20:45.909638
6604	job-processor	healthy	15.661999999999999	\N	http://job-processor:8003/health	200	2025-10-08 18:20:45.909638
6605	file-manager	healthy	15.623	\N	http://file-manager:8004/health	200	2025-10-08 18:20:45.909639
6606	notification	healthy	16.195	\N	http://notification:8005/health	200	2025-10-08 18:20:45.90964
6607	api-gateway	healthy	330.274	\N	http://api-gateway:8000/health	200	2025-10-08 18:21:17.251681
6608	user-service	healthy	16.012999999999998	\N	http://user-service:8001/health	200	2025-10-08 18:21:17.251684
6609	service-registry	healthy	15.426	\N	http://service-registry:8002/health	200	2025-10-08 18:21:17.251685
6610	job-processor	healthy	15.488999999999999	\N	http://job-processor:8003/health	200	2025-10-08 18:21:17.251685
6611	file-manager	healthy	15.928	\N	http://file-manager:8004/health	200	2025-10-08 18:21:17.251686
6612	notification	healthy	16.652	\N	http://notification:8005/health	200	2025-10-08 18:21:17.251687
6613	api-gateway	healthy	323.172	\N	http://api-gateway:8000/health	200	2025-10-08 18:21:48.586311
6614	user-service	healthy	16.892	\N	http://user-service:8001/health	200	2025-10-08 18:21:48.586313
6615	service-registry	healthy	16.756	\N	http://service-registry:8002/health	200	2025-10-08 18:21:48.586314
6616	job-processor	healthy	16.663	\N	http://job-processor:8003/health	200	2025-10-08 18:21:48.586315
6617	file-manager	healthy	15.866000000000001	\N	http://file-manager:8004/health	200	2025-10-08 18:21:48.586315
6618	notification	healthy	17.016	\N	http://notification:8005/health	200	2025-10-08 18:21:48.586316
6619	api-gateway	healthy	348.66700000000003	\N	http://api-gateway:8000/health	200	2025-10-08 18:22:19.945856
6620	user-service	healthy	14.466	\N	http://user-service:8001/health	200	2025-10-08 18:22:19.945858
6621	service-registry	healthy	14.327	\N	http://service-registry:8002/health	200	2025-10-08 18:22:19.945858
6622	job-processor	healthy	15.885	\N	http://job-processor:8003/health	200	2025-10-08 18:22:19.945859
6623	file-manager	healthy	13.549	\N	http://file-manager:8004/health	200	2025-10-08 18:22:19.94586
6624	notification	healthy	15.215	\N	http://notification:8005/health	200	2025-10-08 18:22:19.94586
6625	api-gateway	healthy	321.872	\N	http://api-gateway:8000/health	200	2025-10-08 18:22:51.280054
6626	user-service	healthy	12.843	\N	http://user-service:8001/health	200	2025-10-08 18:22:51.280057
6627	service-registry	healthy	11.827	\N	http://service-registry:8002/health	200	2025-10-08 18:22:51.280057
6628	job-processor	healthy	13.598	\N	http://job-processor:8003/health	200	2025-10-08 18:22:51.280058
6629	file-manager	healthy	13.197000000000001	\N	http://file-manager:8004/health	200	2025-10-08 18:22:51.280059
6630	notification	healthy	14.187	\N	http://notification:8005/health	200	2025-10-08 18:22:51.280059
6631	api-gateway	healthy	421.515	\N	http://api-gateway:8000/health	200	2025-10-08 18:23:22.715855
6632	user-service	healthy	15.931000000000001	\N	http://user-service:8001/health	200	2025-10-08 18:23:22.715858
6633	service-registry	healthy	13.966	\N	http://service-registry:8002/health	200	2025-10-08 18:23:22.715859
6634	job-processor	healthy	15.056999999999999	\N	http://job-processor:8003/health	200	2025-10-08 18:23:22.715859
6635	file-manager	healthy	16.645	\N	http://file-manager:8004/health	200	2025-10-08 18:23:22.71586
6636	notification	healthy	15.67	\N	http://notification:8005/health	200	2025-10-08 18:23:22.71586
6637	api-gateway	healthy	322.685	\N	http://api-gateway:8000/health	200	2025-10-08 18:23:54.048397
6638	user-service	healthy	11.304	\N	http://user-service:8001/health	200	2025-10-08 18:23:54.0484
6639	service-registry	healthy	9.767	\N	http://service-registry:8002/health	200	2025-10-08 18:23:54.0484
6640	job-processor	healthy	12.684000000000001	\N	http://job-processor:8003/health	200	2025-10-08 18:23:54.048401
6641	file-manager	healthy	13.291	\N	http://file-manager:8004/health	200	2025-10-08 18:23:54.048402
6642	notification	healthy	13.882	\N	http://notification:8005/health	200	2025-10-08 18:23:54.048402
6643	api-gateway	healthy	329.445	\N	http://api-gateway:8000/health	200	2025-10-08 18:24:25.389975
6644	user-service	healthy	20.806	\N	http://user-service:8001/health	200	2025-10-08 18:24:25.389978
6645	service-registry	healthy	20.523	\N	http://service-registry:8002/health	200	2025-10-08 18:24:25.389978
6646	job-processor	healthy	20.403000000000002	\N	http://job-processor:8003/health	200	2025-10-08 18:24:25.389979
6647	file-manager	healthy	20.32	\N	http://file-manager:8004/health	200	2025-10-08 18:24:25.38998
6648	notification	healthy	20.26	\N	http://notification:8005/health	200	2025-10-08 18:24:25.389981
6649	api-gateway	healthy	317.469	\N	http://api-gateway:8000/health	200	2025-10-08 18:24:56.719886
6650	user-service	healthy	26.161	\N	http://user-service:8001/health	200	2025-10-08 18:24:56.719889
6651	service-registry	healthy	23.293000000000003	\N	http://service-registry:8002/health	200	2025-10-08 18:24:56.71989
6652	job-processor	healthy	25.080000000000002	\N	http://job-processor:8003/health	200	2025-10-08 18:24:56.719891
6653	file-manager	healthy	25.145	\N	http://file-manager:8004/health	200	2025-10-08 18:24:56.719891
6654	notification	healthy	24.750999999999998	\N	http://notification:8005/health	200	2025-10-08 18:24:56.719892
6655	api-gateway	healthy	309.705	\N	http://api-gateway:8000/health	200	2025-10-08 18:25:28.041479
6656	user-service	healthy	11.06	\N	http://user-service:8001/health	200	2025-10-08 18:25:28.041481
6657	service-registry	healthy	11.532	\N	http://service-registry:8002/health	200	2025-10-08 18:25:28.041482
6658	job-processor	healthy	12.992	\N	http://job-processor:8003/health	200	2025-10-08 18:25:28.041483
6659	file-manager	healthy	12.588999999999999	\N	http://file-manager:8004/health	200	2025-10-08 18:25:28.041483
6660	notification	healthy	12.684000000000001	\N	http://notification:8005/health	200	2025-10-08 18:25:28.041484
6661	api-gateway	healthy	328.475	\N	http://api-gateway:8000/health	200	2025-10-08 18:25:59.382247
6662	user-service	healthy	15.456	\N	http://user-service:8001/health	200	2025-10-08 18:25:59.382249
6663	service-registry	healthy	15.261999999999999	\N	http://service-registry:8002/health	200	2025-10-08 18:25:59.38225
6664	job-processor	healthy	15.172	\N	http://job-processor:8003/health	200	2025-10-08 18:25:59.382251
6665	file-manager	healthy	14.488	\N	http://file-manager:8004/health	200	2025-10-08 18:25:59.382252
6666	notification	healthy	15.405999999999999	\N	http://notification:8005/health	200	2025-10-08 18:25:59.382253
6667	api-gateway	healthy	319.385	\N	http://api-gateway:8000/health	200	2025-10-08 18:26:30.714734
6668	user-service	healthy	14.572	\N	http://user-service:8001/health	200	2025-10-08 18:26:30.714737
6669	service-registry	healthy	14.364999999999998	\N	http://service-registry:8002/health	200	2025-10-08 18:26:30.714738
6670	job-processor	healthy	14.241999999999999	\N	http://job-processor:8003/health	200	2025-10-08 18:26:30.714739
6671	file-manager	healthy	14.136	\N	http://file-manager:8004/health	200	2025-10-08 18:26:30.71474
6672	notification	healthy	14.588000000000001	\N	http://notification:8005/health	200	2025-10-08 18:26:30.71474
6673	api-gateway	healthy	341.552	\N	http://api-gateway:8000/health	200	2025-10-08 18:27:02.076133
6674	user-service	healthy	15.166	\N	http://user-service:8001/health	200	2025-10-08 18:27:02.076135
6675	service-registry	healthy	15.008000000000001	\N	http://service-registry:8002/health	200	2025-10-08 18:27:02.076136
6676	job-processor	healthy	14.915	\N	http://job-processor:8003/health	200	2025-10-08 18:27:02.076137
6677	file-manager	healthy	14.25	\N	http://file-manager:8004/health	200	2025-10-08 18:27:02.076137
6678	notification	healthy	15.661000000000001	\N	http://notification:8005/health	200	2025-10-08 18:27:02.076138
6679	api-gateway	healthy	340.09299999999996	\N	http://api-gateway:8000/health	200	2025-10-08 18:27:33.430624
6680	user-service	healthy	21.673000000000002	\N	http://user-service:8001/health	200	2025-10-08 18:27:33.430627
6681	service-registry	healthy	21.402	\N	http://service-registry:8002/health	200	2025-10-08 18:27:33.430628
6682	job-processor	healthy	23.075	\N	http://job-processor:8003/health	200	2025-10-08 18:27:33.430628
6683	file-manager	healthy	23.194	\N	http://file-manager:8004/health	200	2025-10-08 18:27:33.430629
6684	notification	healthy	22.743	\N	http://notification:8005/health	200	2025-10-08 18:27:33.430629
6685	api-gateway	healthy	338.75	\N	http://api-gateway:8000/health	200	2025-10-08 18:28:04.77961
6686	user-service	healthy	19.614	\N	http://user-service:8001/health	200	2025-10-08 18:28:04.779612
6687	service-registry	healthy	15.792	\N	http://service-registry:8002/health	200	2025-10-08 18:28:04.779613
6688	job-processor	healthy	17.316000000000003	\N	http://job-processor:8003/health	200	2025-10-08 18:28:04.779613
6689	file-manager	healthy	17.226000000000003	\N	http://file-manager:8004/health	200	2025-10-08 18:28:04.779614
6690	notification	healthy	17.152	\N	http://notification:8005/health	200	2025-10-08 18:28:04.779615
6691	api-gateway	healthy	369.769	\N	http://api-gateway:8000/health	200	2025-10-08 18:28:36.163918
6692	user-service	healthy	17.066000000000003	\N	http://user-service:8001/health	200	2025-10-08 18:28:36.16392
6693	service-registry	healthy	16.489	\N	http://service-registry:8002/health	200	2025-10-08 18:28:36.163921
6694	job-processor	healthy	16.570999999999998	\N	http://job-processor:8003/health	200	2025-10-08 18:28:36.163922
6695	file-manager	healthy	17.064	\N	http://file-manager:8004/health	200	2025-10-08 18:28:36.163922
6696	notification	healthy	17.666999999999998	\N	http://notification:8005/health	200	2025-10-08 18:28:36.163923
6697	api-gateway	healthy	402.647	\N	http://api-gateway:8000/health	200	2025-10-08 18:29:07.576994
6698	user-service	healthy	17.971999999999998	\N	http://user-service:8001/health	200	2025-10-08 18:29:07.576996
6699	service-registry	healthy	17.797	\N	http://service-registry:8002/health	200	2025-10-08 18:29:07.576997
6700	job-processor	healthy	17.675	\N	http://job-processor:8003/health	200	2025-10-08 18:29:07.576998
6701	file-manager	healthy	17.585	\N	http://file-manager:8004/health	200	2025-10-08 18:29:07.576999
6702	notification	healthy	18.183999999999997	\N	http://notification:8005/health	200	2025-10-08 18:29:07.576999
6703	api-gateway	healthy	337.286	\N	http://api-gateway:8000/health	200	2025-10-08 18:29:38.927039
6704	user-service	healthy	11.916	\N	http://user-service:8001/health	200	2025-10-08 18:29:38.927041
6705	service-registry	healthy	13.379999999999999	\N	http://service-registry:8002/health	200	2025-10-08 18:29:38.927042
6706	job-processor	healthy	14.628	\N	http://job-processor:8003/health	200	2025-10-08 18:29:38.927043
6707	file-manager	healthy	12.649000000000001	\N	http://file-manager:8004/health	200	2025-10-08 18:29:38.927043
6708	notification	healthy	14.322	\N	http://notification:8005/health	200	2025-10-08 18:29:38.927044
6709	api-gateway	healthy	656.856	\N	http://api-gateway:8000/health	200	2025-10-08 18:30:10.59985
6710	user-service	healthy	35.168	\N	http://user-service:8001/health	200	2025-10-08 18:30:10.599852
6711	service-registry	healthy	34.922000000000004	\N	http://service-registry:8002/health	200	2025-10-08 18:30:10.599853
6712	job-processor	healthy	34.833000000000006	\N	http://job-processor:8003/health	200	2025-10-08 18:30:10.599854
6713	file-manager	healthy	35.175	\N	http://file-manager:8004/health	200	2025-10-08 18:30:10.599854
6714	notification	healthy	35.126	\N	http://notification:8005/health	200	2025-10-08 18:30:10.599855
6715	api-gateway	healthy	316.529	\N	http://api-gateway:8000/health	200	2025-10-08 18:30:41.929739
6716	user-service	healthy	13.529	\N	http://user-service:8001/health	200	2025-10-08 18:30:41.929742
6717	service-registry	healthy	13.372	\N	http://service-registry:8002/health	200	2025-10-08 18:30:41.929743
6718	job-processor	healthy	13.277000000000001	\N	http://job-processor:8003/health	200	2025-10-08 18:30:41.929743
6719	file-manager	healthy	14.624	\N	http://file-manager:8004/health	200	2025-10-08 18:30:41.929744
6720	notification	healthy	14.186	\N	http://notification:8005/health	200	2025-10-08 18:30:41.929745
6721	api-gateway	healthy	317.007	\N	http://api-gateway:8000/health	200	2025-10-08 18:31:13.264738
6722	user-service	healthy	17.377	\N	http://user-service:8001/health	200	2025-10-08 18:31:13.264741
6723	service-registry	healthy	17.138	\N	http://service-registry:8002/health	200	2025-10-08 18:31:13.264742
6724	job-processor	healthy	17.028000000000002	\N	http://job-processor:8003/health	200	2025-10-08 18:31:13.264742
6725	file-manager	healthy	16.927999999999997	\N	http://file-manager:8004/health	200	2025-10-08 18:31:13.264743
6726	notification	healthy	17.519	\N	http://notification:8005/health	200	2025-10-08 18:31:13.264744
6727	api-gateway	healthy	346.022	\N	http://api-gateway:8000/health	200	2025-10-08 18:31:44.629674
6728	user-service	healthy	23.566	\N	http://user-service:8001/health	200	2025-10-08 18:31:44.629676
6729	service-registry	healthy	22.77	\N	http://service-registry:8002/health	200	2025-10-08 18:31:44.629677
6730	job-processor	healthy	22.646	\N	http://job-processor:8003/health	200	2025-10-08 18:31:44.629678
6731	file-manager	healthy	22.543	\N	http://file-manager:8004/health	200	2025-10-08 18:31:44.629678
6732	notification	healthy	23.101	\N	http://notification:8005/health	200	2025-10-08 18:31:44.629679
6733	api-gateway	healthy	312.953	\N	http://api-gateway:8000/health	200	2025-10-08 18:32:15.954392
6734	user-service	healthy	13.344999999999999	\N	http://user-service:8001/health	200	2025-10-08 18:32:15.954394
6735	service-registry	healthy	12.911000000000001	\N	http://service-registry:8002/health	200	2025-10-08 18:32:15.954395
6736	job-processor	healthy	14.833	\N	http://job-processor:8003/health	200	2025-10-08 18:32:15.954395
6737	file-manager	healthy	14.785	\N	http://file-manager:8004/health	200	2025-10-08 18:32:15.954396
6738	notification	healthy	14.718	\N	http://notification:8005/health	200	2025-10-08 18:32:15.954397
6739	api-gateway	healthy	330.141	\N	http://api-gateway:8000/health	200	2025-10-08 18:32:47.297202
6740	user-service	healthy	16.469	\N	http://user-service:8001/health	200	2025-10-08 18:32:47.297205
6741	service-registry	healthy	16.229	\N	http://service-registry:8002/health	200	2025-10-08 18:32:47.297206
6742	job-processor	healthy	16.102	\N	http://job-processor:8003/health	200	2025-10-08 18:32:47.297206
6743	file-manager	healthy	15.995	\N	http://file-manager:8004/health	200	2025-10-08 18:32:47.297207
6744	notification	healthy	16.599	\N	http://notification:8005/health	200	2025-10-08 18:32:47.297208
6745	api-gateway	healthy	322.745	\N	http://api-gateway:8000/health	200	2025-10-08 18:33:18.632819
6746	user-service	healthy	12.571	\N	http://user-service:8001/health	200	2025-10-08 18:33:18.632821
6747	service-registry	healthy	13.663	\N	http://service-registry:8002/health	200	2025-10-08 18:33:18.632822
6748	job-processor	healthy	18.922	\N	http://job-processor:8003/health	200	2025-10-08 18:33:18.632822
6749	file-manager	healthy	18.844	\N	http://file-manager:8004/health	200	2025-10-08 18:33:18.632823
6750	notification	healthy	18.267	\N	http://notification:8005/health	200	2025-10-08 18:33:18.632823
6751	api-gateway	healthy	361.867	\N	http://api-gateway:8000/health	200	2025-10-08 18:33:50.007422
6752	user-service	healthy	19.084	\N	http://user-service:8001/health	200	2025-10-08 18:33:50.007425
6753	service-registry	healthy	18.55	\N	http://service-registry:8002/health	200	2025-10-08 18:33:50.007426
6754	job-processor	healthy	18.598	\N	http://job-processor:8003/health	200	2025-10-08 18:33:50.007426
6755	file-manager	healthy	18.504	\N	http://file-manager:8004/health	200	2025-10-08 18:33:50.007427
6756	notification	healthy	19.287	\N	http://notification:8005/health	200	2025-10-08 18:33:50.007428
6757	api-gateway	healthy	329.697	\N	http://api-gateway:8000/health	200	2025-10-08 18:34:21.356899
6758	user-service	healthy	13.878	\N	http://user-service:8001/health	200	2025-10-08 18:34:21.356901
6759	service-registry	healthy	13.702	\N	http://service-registry:8002/health	200	2025-10-08 18:34:21.356902
6760	job-processor	healthy	13.594999999999999	\N	http://job-processor:8003/health	200	2025-10-08 18:34:21.356903
6761	file-manager	healthy	13.474	\N	http://file-manager:8004/health	200	2025-10-08 18:34:21.356903
6762	notification	healthy	14.024	\N	http://notification:8005/health	200	2025-10-08 18:34:21.356904
6763	api-gateway	healthy	314.06800000000004	\N	http://api-gateway:8000/health	200	2025-10-08 18:34:52.68348
6764	user-service	healthy	14.248999999999999	\N	http://user-service:8001/health	200	2025-10-08 18:34:52.683483
6765	service-registry	healthy	14.066	\N	http://service-registry:8002/health	200	2025-10-08 18:34:52.683484
6766	job-processor	healthy	13.956	\N	http://job-processor:8003/health	200	2025-10-08 18:34:52.683484
6767	file-manager	healthy	15.233	\N	http://file-manager:8004/health	200	2025-10-08 18:34:52.683485
6768	notification	healthy	15.193999999999999	\N	http://notification:8005/health	200	2025-10-08 18:34:52.683486
6769	api-gateway	healthy	325.09900000000005	\N	http://api-gateway:8000/health	200	2025-10-08 18:35:24.020091
6770	user-service	healthy	12.274000000000001	\N	http://user-service:8001/health	200	2025-10-08 18:35:24.020093
6771	service-registry	healthy	9.886000000000001	\N	http://service-registry:8002/health	200	2025-10-08 18:35:24.020094
6772	job-processor	healthy	11.871	\N	http://job-processor:8003/health	200	2025-10-08 18:35:24.020095
6773	file-manager	healthy	11.786	\N	http://file-manager:8004/health	200	2025-10-08 18:35:24.020095
6774	notification	healthy	12.501999999999999	\N	http://notification:8005/health	200	2025-10-08 18:35:24.020096
6775	api-gateway	healthy	342.968	\N	http://api-gateway:8000/health	200	2025-10-08 18:35:55.374974
6776	user-service	healthy	34.313	\N	http://user-service:8001/health	200	2025-10-08 18:35:55.374976
6777	service-registry	healthy	34.101	\N	http://service-registry:8002/health	200	2025-10-08 18:35:55.374977
6778	job-processor	healthy	34.011	\N	http://job-processor:8003/health	200	2025-10-08 18:35:55.374978
6779	file-manager	healthy	33.296	\N	http://file-manager:8004/health	200	2025-10-08 18:35:55.374978
6780	notification	healthy	34.618	\N	http://notification:8005/health	200	2025-10-08 18:35:55.374979
6781	api-gateway	healthy	520.91	\N	http://api-gateway:8000/health	200	2025-10-08 18:36:26.911396
6782	user-service	healthy	19.254	\N	http://user-service:8001/health	200	2025-10-08 18:36:26.911399
6783	service-registry	healthy	29.881	\N	http://service-registry:8002/health	200	2025-10-08 18:36:26.911399
6784	job-processor	healthy	29.785	\N	http://job-processor:8003/health	200	2025-10-08 18:36:26.9114
6785	file-manager	healthy	37.664	\N	http://file-manager:8004/health	200	2025-10-08 18:36:26.911401
6786	notification	healthy	37.608999999999995	\N	http://notification:8005/health	200	2025-10-08 18:36:26.911401
6787	api-gateway	healthy	341.93800000000005	\N	http://api-gateway:8000/health	200	2025-10-08 18:36:58.265459
6788	user-service	healthy	17.615	\N	http://user-service:8001/health	200	2025-10-08 18:36:58.265462
6789	service-registry	healthy	15.299	\N	http://service-registry:8002/health	200	2025-10-08 18:36:58.265463
6790	job-processor	healthy	17.183	\N	http://job-processor:8003/health	200	2025-10-08 18:36:58.265463
6791	file-manager	healthy	17.058	\N	http://file-manager:8004/health	200	2025-10-08 18:36:58.265464
6792	notification	healthy	17.659000000000002	\N	http://notification:8005/health	200	2025-10-08 18:36:58.265465
6793	api-gateway	healthy	368.149	\N	http://api-gateway:8000/health	200	2025-10-08 18:37:29.647009
6794	user-service	healthy	15.306999999999999	\N	http://user-service:8001/health	200	2025-10-08 18:37:29.647012
6795	service-registry	healthy	15.199	\N	http://service-registry:8002/health	200	2025-10-08 18:37:29.647012
6796	job-processor	healthy	15.116	\N	http://job-processor:8003/health	200	2025-10-08 18:37:29.647013
6797	file-manager	healthy	16.412	\N	http://file-manager:8004/health	200	2025-10-08 18:37:29.647014
6798	notification	healthy	16.358	\N	http://notification:8005/health	200	2025-10-08 18:37:29.647014
6799	api-gateway	healthy	361.98900000000003	\N	http://api-gateway:8000/health	200	2025-10-08 18:38:01.028013
6800	user-service	healthy	13.747	\N	http://user-service:8001/health	200	2025-10-08 18:38:01.028015
6801	service-registry	healthy	13.536	\N	http://service-registry:8002/health	200	2025-10-08 18:38:01.028016
6802	job-processor	healthy	13.415	\N	http://job-processor:8003/health	200	2025-10-08 18:38:01.028016
6803	file-manager	healthy	14.331	\N	http://file-manager:8004/health	200	2025-10-08 18:38:01.028017
6804	notification	healthy	15.904000000000002	\N	http://notification:8005/health	200	2025-10-08 18:38:01.028018
6805	api-gateway	healthy	323.432	\N	http://api-gateway:8000/health	200	2025-10-08 18:38:32.363042
6806	user-service	healthy	14.253	\N	http://user-service:8001/health	200	2025-10-08 18:38:32.363045
6807	service-registry	healthy	15.544	\N	http://service-registry:8002/health	200	2025-10-08 18:38:32.363046
6808	job-processor	healthy	15.419	\N	http://job-processor:8003/health	200	2025-10-08 18:38:32.363046
6809	file-manager	healthy	16.764999999999997	\N	http://file-manager:8004/health	200	2025-10-08 18:38:32.363047
6810	notification	healthy	16.695	\N	http://notification:8005/health	200	2025-10-08 18:38:32.363047
6811	api-gateway	healthy	365.85200000000003	\N	http://api-gateway:8000/health	200	2025-10-08 18:39:03.741654
6812	user-service	healthy	15.474	\N	http://user-service:8001/health	200	2025-10-08 18:39:03.741657
6813	service-registry	healthy	15.282	\N	http://service-registry:8002/health	200	2025-10-08 18:39:03.741657
6814	job-processor	healthy	15.173	\N	http://job-processor:8003/health	200	2025-10-08 18:39:03.741658
6815	file-manager	healthy	14.459	\N	http://file-manager:8004/health	200	2025-10-08 18:39:03.741659
6816	notification	healthy	15.613999999999999	\N	http://notification:8005/health	200	2025-10-08 18:39:03.741659
6817	api-gateway	healthy	441.487	\N	http://api-gateway:8000/health	200	2025-10-08 18:39:35.197048
6818	user-service	healthy	21.299	\N	http://user-service:8001/health	200	2025-10-08 18:39:35.197051
6819	service-registry	healthy	19.325	\N	http://service-registry:8002/health	200	2025-10-08 18:39:35.197052
6820	job-processor	healthy	19.209	\N	http://job-processor:8003/health	200	2025-10-08 18:39:35.197052
6821	file-manager	healthy	19.12	\N	http://file-manager:8004/health	200	2025-10-08 18:39:35.197053
6822	notification	healthy	19.008	\N	http://notification:8005/health	200	2025-10-08 18:39:35.197053
6823	api-gateway	healthy	357.153	\N	http://api-gateway:8000/health	200	2025-10-08 18:40:06.567659
6824	user-service	healthy	15.581	\N	http://user-service:8001/health	200	2025-10-08 18:40:06.567662
6825	service-registry	healthy	13.173	\N	http://service-registry:8002/health	200	2025-10-08 18:40:06.567662
6826	job-processor	healthy	14.762	\N	http://job-processor:8003/health	200	2025-10-08 18:40:06.567663
6827	file-manager	healthy	16.386000000000003	\N	http://file-manager:8004/health	200	2025-10-08 18:40:06.567664
6828	notification	healthy	16.305	\N	http://notification:8005/health	200	2025-10-08 18:40:06.567664
6829	api-gateway	healthy	663.918	\N	http://api-gateway:8000/health	200	2025-10-08 18:40:38.246415
6830	user-service	healthy	22.128	\N	http://user-service:8001/health	200	2025-10-08 18:40:38.246418
6831	service-registry	healthy	21.854	\N	http://service-registry:8002/health	200	2025-10-08 18:40:38.246419
6832	job-processor	healthy	21.731	\N	http://job-processor:8003/health	200	2025-10-08 18:40:38.24642
6833	file-manager	healthy	21.645	\N	http://file-manager:8004/health	200	2025-10-08 18:40:38.24642
6834	notification	healthy	22.109	\N	http://notification:8005/health	200	2025-10-08 18:40:38.246421
6835	api-gateway	healthy	324.219	\N	http://api-gateway:8000/health	200	2025-10-08 18:41:09.584817
6836	user-service	healthy	16.475	\N	http://user-service:8001/health	200	2025-10-08 18:41:09.584819
6837	service-registry	healthy	10.122000000000002	\N	http://service-registry:8002/health	200	2025-10-08 18:41:09.58482
6838	job-processor	healthy	13.835999999999999	\N	http://job-processor:8003/health	200	2025-10-08 18:41:09.584821
6839	file-manager	healthy	14.32	\N	http://file-manager:8004/health	200	2025-10-08 18:41:09.584821
6840	notification	healthy	14.755	\N	http://notification:8005/health	200	2025-10-08 18:41:09.584822
6841	api-gateway	healthy	314.35200000000003	\N	http://api-gateway:8000/health	200	2025-10-08 18:41:40.914507
6842	user-service	healthy	17.853	\N	http://user-service:8001/health	200	2025-10-08 18:41:40.914509
6843	service-registry	healthy	17.694000000000003	\N	http://service-registry:8002/health	200	2025-10-08 18:41:40.91451
6844	job-processor	healthy	17.585	\N	http://job-processor:8003/health	200	2025-10-08 18:41:40.91451
6845	file-manager	healthy	17.488	\N	http://file-manager:8004/health	200	2025-10-08 18:41:40.914511
6846	notification	healthy	18.259	\N	http://notification:8005/health	200	2025-10-08 18:41:40.914512
6847	api-gateway	healthy	316.339	\N	http://api-gateway:8000/health	200	2025-10-08 18:42:12.242861
6848	user-service	healthy	14.142999999999999	\N	http://user-service:8001/health	200	2025-10-08 18:42:12.242864
6849	service-registry	healthy	13.647	\N	http://service-registry:8002/health	200	2025-10-08 18:42:12.242865
6850	job-processor	healthy	14.829	\N	http://job-processor:8003/health	200	2025-10-08 18:42:12.242866
6851	file-manager	healthy	12.966	\N	http://file-manager:8004/health	200	2025-10-08 18:42:12.242866
6852	notification	healthy	14.533000000000001	\N	http://notification:8005/health	200	2025-10-08 18:42:12.242867
6853	api-gateway	healthy	332.177	\N	http://api-gateway:8000/health	200	2025-10-08 18:42:43.593923
6854	user-service	healthy	13.194	\N	http://user-service:8001/health	200	2025-10-08 18:42:43.593926
6855	service-registry	healthy	12.727	\N	http://service-registry:8002/health	200	2025-10-08 18:42:43.593927
6856	job-processor	healthy	12.321	\N	http://job-processor:8003/health	200	2025-10-08 18:42:43.593928
6857	file-manager	healthy	13.794	\N	http://file-manager:8004/health	200	2025-10-08 18:42:43.593928
6858	notification	healthy	13.343	\N	http://notification:8005/health	200	2025-10-08 18:42:43.593929
6859	api-gateway	healthy	351.345	\N	http://api-gateway:8000/health	200	2025-10-08 18:43:14.961024
6860	user-service	healthy	15.360999999999999	\N	http://user-service:8001/health	200	2025-10-08 18:43:14.961027
6861	service-registry	healthy	14.746	\N	http://service-registry:8002/health	200	2025-10-08 18:43:14.961027
6862	job-processor	healthy	16.512	\N	http://job-processor:8003/health	200	2025-10-08 18:43:14.961028
6863	file-manager	healthy	16.054	\N	http://file-manager:8004/health	200	2025-10-08 18:43:14.961029
6864	notification	healthy	16.157	\N	http://notification:8005/health	200	2025-10-08 18:43:14.961029
6865	api-gateway	healthy	304.665	\N	http://api-gateway:8000/health	200	2025-10-08 18:43:46.279445
6866	user-service	healthy	14.331	\N	http://user-service:8001/health	200	2025-10-08 18:43:46.279448
6867	service-registry	healthy	13.831	\N	http://service-registry:8002/health	200	2025-10-08 18:43:46.279449
6868	job-processor	healthy	14.850999999999999	\N	http://job-processor:8003/health	200	2025-10-08 18:43:46.279449
6869	file-manager	healthy	14.767000000000001	\N	http://file-manager:8004/health	200	2025-10-08 18:43:46.27945
6870	notification	healthy	16.438000000000002	\N	http://notification:8005/health	200	2025-10-08 18:43:46.279451
6871	api-gateway	healthy	317.235	\N	http://api-gateway:8000/health	200	2025-10-08 18:44:17.611026
6872	user-service	healthy	17.815	\N	http://user-service:8001/health	200	2025-10-08 18:44:17.611028
6873	service-registry	healthy	17.329	\N	http://service-registry:8002/health	200	2025-10-08 18:44:17.611029
6874	job-processor	healthy	18.991	\N	http://job-processor:8003/health	200	2025-10-08 18:44:17.61103
6875	file-manager	healthy	18.526	\N	http://file-manager:8004/health	200	2025-10-08 18:44:17.611031
6876	notification	healthy	18.654	\N	http://notification:8005/health	200	2025-10-08 18:44:17.611031
6877	api-gateway	unhealthy	20.681	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:44:48.646538
6878	user-service	healthy	15.705	\N	http://user-service:8001/health	200	2025-10-08 18:44:48.64654
6879	service-registry	healthy	12.802	\N	http://service-registry:8002/health	200	2025-10-08 18:44:48.646541
6880	job-processor	healthy	16.015	\N	http://job-processor:8003/health	200	2025-10-08 18:44:48.646542
6881	file-manager	healthy	12.959999999999999	\N	http://file-manager:8004/health	200	2025-10-08 18:44:48.646542
6882	notification	healthy	14.437	\N	http://notification:8005/health	200	2025-10-08 18:44:48.646543
6883	api-gateway	unhealthy	32.799	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:45:19.719713
6884	user-service	healthy	31.029999999999998	\N	http://user-service:8001/health	200	2025-10-08 18:45:19.719715
6885	service-registry	healthy	54.827	\N	http://service-registry:8002/health	200	2025-10-08 18:45:19.719716
6886	job-processor	healthy	53.829	\N	http://job-processor:8003/health	200	2025-10-08 18:45:19.719717
6887	file-manager	healthy	39.851	\N	http://file-manager:8004/health	200	2025-10-08 18:45:19.719718
6888	notification	healthy	35.665	\N	http://notification:8005/health	200	2025-10-08 18:45:19.719718
6889	api-gateway	unhealthy	13.606	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:45:50.746503
6890	user-service	healthy	11.878	\N	http://user-service:8001/health	200	2025-10-08 18:45:50.746506
6891	service-registry	healthy	11.431999999999999	\N	http://service-registry:8002/health	200	2025-10-08 18:45:50.746506
6892	job-processor	healthy	13.851	\N	http://job-processor:8003/health	200	2025-10-08 18:45:50.746507
6893	file-manager	healthy	12.822	\N	http://file-manager:8004/health	200	2025-10-08 18:45:50.746507
6894	notification	healthy	13.013	\N	http://notification:8005/health	200	2025-10-08 18:45:50.746508
6895	api-gateway	unhealthy	15.059	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:46:21.772432
6896	user-service	healthy	11.34	\N	http://user-service:8001/health	200	2025-10-08 18:46:21.772435
6897	service-registry	healthy	12.522	\N	http://service-registry:8002/health	200	2025-10-08 18:46:21.772435
6898	job-processor	healthy	12.46	\N	http://job-processor:8003/health	200	2025-10-08 18:46:21.772436
6899	file-manager	healthy	14.037	\N	http://file-manager:8004/health	200	2025-10-08 18:46:21.772436
6900	notification	healthy	13.59	\N	http://notification:8005/health	200	2025-10-08 18:46:21.772437
6901	api-gateway	unhealthy	19.508000000000003	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:46:52.81082
6902	user-service	healthy	19.721	\N	http://user-service:8001/health	200	2025-10-08 18:46:52.810823
6903	service-registry	healthy	17.465	\N	http://service-registry:8002/health	200	2025-10-08 18:46:52.810823
6904	job-processor	healthy	19.185000000000002	\N	http://job-processor:8003/health	200	2025-10-08 18:46:52.810824
6905	file-manager	healthy	20.637	\N	http://file-manager:8004/health	200	2025-10-08 18:46:52.810824
6906	notification	healthy	20.16	\N	http://notification:8005/health	200	2025-10-08 18:46:52.810825
6907	api-gateway	unhealthy	25.974	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:47:23.852556
6908	user-service	healthy	23.292	\N	http://user-service:8001/health	200	2025-10-08 18:47:23.852559
6909	service-registry	healthy	22.821	\N	http://service-registry:8002/health	200	2025-10-08 18:47:23.85256
6910	job-processor	healthy	25.717	\N	http://job-processor:8003/health	200	2025-10-08 18:47:23.85256
6911	file-manager	healthy	24.509	\N	http://file-manager:8004/health	200	2025-10-08 18:47:23.852561
6912	notification	healthy	24.448	\N	http://notification:8005/health	200	2025-10-08 18:47:23.852562
6913	api-gateway	unhealthy	14.663	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:47:54.885709
6914	user-service	healthy	16.500999999999998	\N	http://user-service:8001/health	200	2025-10-08 18:47:54.885711
6915	service-registry	healthy	15.980999999999998	\N	http://service-registry:8002/health	200	2025-10-08 18:47:54.885712
6916	job-processor	healthy	17.146	\N	http://job-processor:8003/health	200	2025-10-08 18:47:54.885713
6917	file-manager	healthy	17.058	\N	http://file-manager:8004/health	200	2025-10-08 18:47:54.885713
6918	notification	healthy	17.492	\N	http://notification:8005/health	200	2025-10-08 18:47:54.885714
6919	api-gateway	unhealthy	17.468999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:48:25.920204
6920	user-service	healthy	18.436	\N	http://user-service:8001/health	200	2025-10-08 18:48:25.920207
6921	service-registry	healthy	14.895	\N	http://service-registry:8002/health	200	2025-10-08 18:48:25.920208
6922	job-processor	healthy	17.959	\N	http://job-processor:8003/health	200	2025-10-08 18:48:25.920208
6923	file-manager	healthy	17.887	\N	http://file-manager:8004/health	200	2025-10-08 18:48:25.920209
6924	notification	healthy	17.145	\N	http://notification:8005/health	200	2025-10-08 18:48:25.920209
6925	api-gateway	unhealthy	16.164	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:48:56.948846
6926	user-service	healthy	13.513	\N	http://user-service:8001/health	200	2025-10-08 18:48:56.948849
6927	service-registry	healthy	12.274999999999999	\N	http://service-registry:8002/health	200	2025-10-08 18:48:56.948849
6928	job-processor	healthy	14.395	\N	http://job-processor:8003/health	200	2025-10-08 18:48:56.94885
6929	file-manager	healthy	13.350000000000001	\N	http://file-manager:8004/health	200	2025-10-08 18:48:56.948851
6930	notification	healthy	14.363000000000001	\N	http://notification:8005/health	200	2025-10-08 18:48:56.948851
6931	api-gateway	unhealthy	14.538	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:49:27.978968
6932	user-service	healthy	15.763	\N	http://user-service:8001/health	200	2025-10-08 18:49:27.978971
6933	service-registry	healthy	13.252	\N	http://service-registry:8002/health	200	2025-10-08 18:49:27.978971
6934	job-processor	healthy	15.409	\N	http://job-processor:8003/health	200	2025-10-08 18:49:27.978972
6935	file-manager	healthy	15.509	\N	http://file-manager:8004/health	200	2025-10-08 18:49:27.978973
6936	notification	healthy	14.599	\N	http://notification:8005/health	200	2025-10-08 18:49:27.978973
6937	api-gateway	unhealthy	17.163	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:49:59.010528
6938	user-service	healthy	14.562999999999999	\N	http://user-service:8001/health	200	2025-10-08 18:49:59.010531
6939	service-registry	healthy	14.335	\N	http://service-registry:8002/health	200	2025-10-08 18:49:59.010532
6940	job-processor	healthy	16.393	\N	http://job-processor:8003/health	200	2025-10-08 18:49:59.010532
6941	file-manager	healthy	16.303	\N	http://file-manager:8004/health	200	2025-10-08 18:49:59.010533
6942	notification	healthy	16.153000000000002	\N	http://notification:8005/health	200	2025-10-08 18:49:59.010534
6943	api-gateway	unhealthy	15.86	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:50:30.044061
6944	user-service	healthy	18.033	\N	http://user-service:8001/health	200	2025-10-08 18:50:30.044063
6945	service-registry	healthy	17.852	\N	http://service-registry:8002/health	200	2025-10-08 18:50:30.044064
6946	job-processor	healthy	17.753999999999998	\N	http://job-processor:8003/health	200	2025-10-08 18:50:30.044065
6947	file-manager	healthy	17.063	\N	http://file-manager:8004/health	200	2025-10-08 18:50:30.044065
6948	notification	healthy	18.068	\N	http://notification:8005/health	200	2025-10-08 18:50:30.044066
6949	api-gateway	unhealthy	13.415	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:51:01.072665
6950	user-service	healthy	12.369	\N	http://user-service:8001/health	200	2025-10-08 18:51:01.072668
6951	service-registry	healthy	11.107000000000001	\N	http://service-registry:8002/health	200	2025-10-08 18:51:01.072669
6952	job-processor	healthy	13.4	\N	http://job-processor:8003/health	200	2025-10-08 18:51:01.07267
6953	file-manager	healthy	13.186	\N	http://file-manager:8004/health	200	2025-10-08 18:51:01.07267
6954	notification	healthy	13.771	\N	http://notification:8005/health	200	2025-10-08 18:51:01.072671
6955	api-gateway	unhealthy	15.855	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:51:32.102244
6956	user-service	healthy	14.828	\N	http://user-service:8001/health	200	2025-10-08 18:51:32.102246
6957	service-registry	healthy	12.969	\N	http://service-registry:8002/health	200	2025-10-08 18:51:32.102247
6958	job-processor	healthy	14.446	\N	http://job-processor:8003/health	200	2025-10-08 18:51:32.102248
6959	file-manager	healthy	15.488	\N	http://file-manager:8004/health	200	2025-10-08 18:51:32.102248
6960	notification	healthy	15.405999999999999	\N	http://notification:8005/health	200	2025-10-08 18:51:32.102249
6961	api-gateway	unhealthy	21.436	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:52:03.138509
6962	user-service	healthy	15.671999999999999	\N	http://user-service:8001/health	200	2025-10-08 18:52:03.138512
6963	service-registry	healthy	19.325	\N	http://service-registry:8002/health	200	2025-10-08 18:52:03.138513
6964	job-processor	healthy	18.016000000000002	\N	http://job-processor:8003/health	200	2025-10-08 18:52:03.138514
6965	file-manager	healthy	17.124	\N	http://file-manager:8004/health	200	2025-10-08 18:52:03.138514
6966	notification	healthy	17.318	\N	http://notification:8005/health	200	2025-10-08 18:52:03.138515
6967	api-gateway	unhealthy	23.506	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:52:34.195282
6968	user-service	healthy	16.59	\N	http://user-service:8001/health	200	2025-10-08 18:52:34.195284
6969	service-registry	healthy	16.442999999999998	\N	http://service-registry:8002/health	200	2025-10-08 18:52:34.195285
6970	job-processor	healthy	16.347	\N	http://job-processor:8003/health	200	2025-10-08 18:52:34.195286
6971	file-manager	healthy	16.229	\N	http://file-manager:8004/health	200	2025-10-08 18:52:34.195286
6972	notification	healthy	16.16	\N	http://notification:8005/health	200	2025-10-08 18:52:34.195287
6973	api-gateway	unhealthy	16.037	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:53:05.222959
6974	user-service	healthy	13.932	\N	http://user-service:8001/health	200	2025-10-08 18:53:05.222961
6975	service-registry	healthy	9.947	\N	http://service-registry:8002/health	200	2025-10-08 18:53:05.222962
6976	job-processor	healthy	10.809	\N	http://job-processor:8003/health	200	2025-10-08 18:53:05.222963
6977	file-manager	healthy	14.353	\N	http://file-manager:8004/health	200	2025-10-08 18:53:05.222963
6978	notification	healthy	11.68	\N	http://notification:8005/health	200	2025-10-08 18:53:05.222964
6979	api-gateway	unhealthy	22.251	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:53:36.262066
6980	user-service	healthy	16.589	\N	http://user-service:8001/health	200	2025-10-08 18:53:36.262069
6981	service-registry	healthy	14.951	\N	http://service-registry:8002/health	200	2025-10-08 18:53:36.26207
6982	job-processor	healthy	21.084	\N	http://job-processor:8003/health	200	2025-10-08 18:53:36.262071
6983	file-manager	healthy	20.53	\N	http://file-manager:8004/health	200	2025-10-08 18:53:36.262071
6984	notification	healthy	20.11	\N	http://notification:8005/health	200	2025-10-08 18:53:36.262072
6985	api-gateway	unhealthy	15.834000000000001	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:54:07.290809
6986	user-service	healthy	13.347	\N	http://user-service:8001/health	200	2025-10-08 18:54:07.290811
6987	service-registry	healthy	12.888	\N	http://service-registry:8002/health	200	2025-10-08 18:54:07.290812
6988	job-processor	healthy	13.953	\N	http://job-processor:8003/health	200	2025-10-08 18:54:07.290813
6989	file-manager	healthy	14.947999999999999	\N	http://file-manager:8004/health	200	2025-10-08 18:54:07.290813
6990	notification	healthy	13.637	\N	http://notification:8005/health	200	2025-10-08 18:54:07.290814
6991	api-gateway	unhealthy	20.241	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:54:38.322914
6992	user-service	healthy	18.37	\N	http://user-service:8001/health	200	2025-10-08 18:54:38.322917
6993	service-registry	healthy	17.785	\N	http://service-registry:8002/health	200	2025-10-08 18:54:38.322918
6994	job-processor	healthy	18.048000000000002	\N	http://job-processor:8003/health	200	2025-10-08 18:54:38.322918
6995	file-manager	healthy	17.975	\N	http://file-manager:8004/health	200	2025-10-08 18:54:38.322919
6996	notification	healthy	16.746000000000002	\N	http://notification:8005/health	200	2025-10-08 18:54:38.32292
6997	api-gateway	unhealthy	17.701999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:55:09.351918
6998	user-service	healthy	14.39	\N	http://user-service:8001/health	200	2025-10-08 18:55:09.35192
6999	service-registry	healthy	12.623000000000001	\N	http://service-registry:8002/health	200	2025-10-08 18:55:09.351921
7000	job-processor	healthy	13.975	\N	http://job-processor:8003/health	200	2025-10-08 18:55:09.351922
7001	file-manager	healthy	15.296000000000001	\N	http://file-manager:8004/health	200	2025-10-08 18:55:09.351922
7002	notification	healthy	15.239	\N	http://notification:8005/health	200	2025-10-08 18:55:09.351923
7003	api-gateway	unhealthy	19.453000000000003	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:55:40.38791
7004	user-service	healthy	14.562000000000001	\N	http://user-service:8001/health	200	2025-10-08 18:55:40.387913
7005	service-registry	healthy	15.278	\N	http://service-registry:8002/health	200	2025-10-08 18:55:40.387914
7006	job-processor	healthy	15.110999999999999	\N	http://job-processor:8003/health	200	2025-10-08 18:55:40.387914
7007	file-manager	healthy	15.355	\N	http://file-manager:8004/health	200	2025-10-08 18:55:40.387915
7008	notification	healthy	16.785999999999998	\N	http://notification:8005/health	200	2025-10-08 18:55:40.387915
7009	api-gateway	unhealthy	16.357	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:56:11.418773
7010	user-service	healthy	14.149000000000001	\N	http://user-service:8001/health	200	2025-10-08 18:56:11.418776
7011	service-registry	healthy	13.707	\N	http://service-registry:8002/health	200	2025-10-08 18:56:11.418777
7012	job-processor	healthy	15.504	\N	http://job-processor:8003/health	200	2025-10-08 18:56:11.418778
7013	file-manager	healthy	16.091	\N	http://file-manager:8004/health	200	2025-10-08 18:56:11.418778
7014	notification	healthy	14.794	\N	http://notification:8005/health	200	2025-10-08 18:56:11.418779
7015	api-gateway	unhealthy	33.811	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:56:42.469605
7016	user-service	healthy	15.865	\N	http://user-service:8001/health	200	2025-10-08 18:56:42.469608
7017	service-registry	healthy	27.990000000000002	\N	http://service-registry:8002/health	200	2025-10-08 18:56:42.469609
7018	job-processor	healthy	31.516000000000002	\N	http://job-processor:8003/health	200	2025-10-08 18:56:42.46961
7019	file-manager	healthy	32.838	\N	http://file-manager:8004/health	200	2025-10-08 18:56:42.46961
7020	notification	healthy	33.047	\N	http://notification:8005/health	200	2025-10-08 18:56:42.469611
7021	api-gateway	unhealthy	23.626	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:57:13.516576
7022	user-service	healthy	24.994	\N	http://user-service:8001/health	200	2025-10-08 18:57:13.516579
7023	service-registry	healthy	24.547	\N	http://service-registry:8002/health	200	2025-10-08 18:57:13.51658
7024	job-processor	healthy	24.346	\N	http://job-processor:8003/health	200	2025-10-08 18:57:13.51658
7025	file-manager	healthy	23.913	\N	http://file-manager:8004/health	200	2025-10-08 18:57:13.516581
7026	notification	healthy	24.514	\N	http://notification:8005/health	200	2025-10-08 18:57:13.516582
7027	api-gateway	unhealthy	16.094	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:57:44.550143
7028	user-service	healthy	19.924999999999997	\N	http://user-service:8001/health	200	2025-10-08 18:57:44.550146
7029	service-registry	healthy	19.508000000000003	\N	http://service-registry:8002/health	200	2025-10-08 18:57:44.550147
7030	job-processor	healthy	19.555	\N	http://job-processor:8003/health	200	2025-10-08 18:57:44.550147
7031	file-manager	healthy	19.484	\N	http://file-manager:8004/health	200	2025-10-08 18:57:44.550148
7032	notification	healthy	20.136999999999997	\N	http://notification:8005/health	200	2025-10-08 18:57:44.550149
7033	api-gateway	unhealthy	15.802	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:58:15.584297
7034	user-service	healthy	14.705	\N	http://user-service:8001/health	200	2025-10-08 18:58:15.5843
7035	service-registry	healthy	13.161000000000001	\N	http://service-registry:8002/health	200	2025-10-08 18:58:15.584301
7036	job-processor	healthy	15.91	\N	http://job-processor:8003/health	200	2025-10-08 18:58:15.584302
7037	file-manager	healthy	15.823	\N	http://file-manager:8004/health	200	2025-10-08 18:58:15.584303
7038	notification	healthy	15.75	\N	http://notification:8005/health	200	2025-10-08 18:58:15.584303
7039	api-gateway	unhealthy	18.948	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:58:46.646718
7040	user-service	healthy	17.465	\N	http://user-service:8001/health	200	2025-10-08 18:58:46.646721
7041	service-registry	healthy	17.304	\N	http://service-registry:8002/health	200	2025-10-08 18:58:46.646721
7042	job-processor	healthy	17.19	\N	http://job-processor:8003/health	200	2025-10-08 18:58:46.646722
7043	file-manager	healthy	20.410999999999998	\N	http://file-manager:8004/health	200	2025-10-08 18:58:46.646723
7044	notification	healthy	17.636	\N	http://notification:8005/health	200	2025-10-08 18:58:46.646724
7045	api-gateway	unhealthy	13.662	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:59:17.688746
7046	user-service	healthy	16.702	\N	http://user-service:8001/health	200	2025-10-08 18:59:17.688749
7047	service-registry	healthy	14.312	\N	http://service-registry:8002/health	200	2025-10-08 18:59:17.68875
7048	job-processor	healthy	18.540999999999997	\N	http://job-processor:8003/health	200	2025-10-08 18:59:17.68875
7049	file-manager	healthy	18.474999999999998	\N	http://file-manager:8004/health	200	2025-10-08 18:59:17.688751
7050	notification	healthy	20.576	\N	http://notification:8005/health	200	2025-10-08 18:59:17.688751
7051	api-gateway	unhealthy	35.308	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 18:59:48.752737
7052	user-service	healthy	12.315	\N	http://user-service:8001/health	200	2025-10-08 18:59:48.752741
7053	service-registry	healthy	12.072	\N	http://service-registry:8002/health	200	2025-10-08 18:59:48.752741
7054	job-processor	healthy	13.209	\N	http://job-processor:8003/health	200	2025-10-08 18:59:48.752742
7055	file-manager	healthy	12.087	\N	http://file-manager:8004/health	200	2025-10-08 18:59:48.752743
7056	notification	healthy	26.273	\N	http://notification:8005/health	200	2025-10-08 18:59:48.752743
7057	api-gateway	unhealthy	21.195999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:00:19.788497
7058	user-service	healthy	16.776	\N	http://user-service:8001/health	200	2025-10-08 19:00:19.788499
7059	service-registry	healthy	16.317999999999998	\N	http://service-registry:8002/health	200	2025-10-08 19:00:19.7885
7060	job-processor	healthy	15.915	\N	http://job-processor:8003/health	200	2025-10-08 19:00:19.7885
7061	file-manager	healthy	20.641	\N	http://file-manager:8004/health	200	2025-10-08 19:00:19.788501
7062	notification	healthy	20.173	\N	http://notification:8005/health	200	2025-10-08 19:00:19.788502
7063	api-gateway	unhealthy	51.893	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:00:50.855778
7064	user-service	healthy	17.729000000000003	\N	http://user-service:8001/health	200	2025-10-08 19:00:50.855783
7065	service-registry	healthy	20.475	\N	http://service-registry:8002/health	200	2025-10-08 19:00:50.855783
7066	job-processor	healthy	20.371	\N	http://job-processor:8003/health	200	2025-10-08 19:00:50.855784
7067	file-manager	healthy	40.209	\N	http://file-manager:8004/health	200	2025-10-08 19:00:50.855784
7068	notification	healthy	46.794000000000004	\N	http://notification:8005/health	200	2025-10-08 19:00:50.855785
7069	api-gateway	unhealthy	26.104	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:01:21.897045
7070	user-service	healthy	19.77	\N	http://user-service:8001/health	200	2025-10-08 19:01:21.897047
7071	service-registry	healthy	19.732	\N	http://service-registry:8002/health	200	2025-10-08 19:01:21.897048
7072	job-processor	healthy	19.412	\N	http://job-processor:8003/health	200	2025-10-08 19:01:21.897049
7073	file-manager	healthy	17.3	\N	http://file-manager:8004/health	200	2025-10-08 19:01:21.897049
7074	notification	healthy	20.439	\N	http://notification:8005/health	200	2025-10-08 19:01:21.89705
7075	api-gateway	unhealthy	26.384999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:01:52.94423
7076	user-service	healthy	24.579	\N	http://user-service:8001/health	200	2025-10-08 19:01:52.944233
7077	service-registry	healthy	25.662999999999997	\N	http://service-registry:8002/health	200	2025-10-08 19:01:52.944234
7078	job-processor	healthy	26.088	\N	http://job-processor:8003/health	200	2025-10-08 19:01:52.944234
7079	file-manager	healthy	27.131	\N	http://file-manager:8004/health	200	2025-10-08 19:01:52.944235
7080	notification	healthy	30.406	\N	http://notification:8005/health	200	2025-10-08 19:01:52.944236
7081	api-gateway	unhealthy	25.489	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:02:23.991999
7082	user-service	healthy	12.869	\N	http://user-service:8001/health	200	2025-10-08 19:02:23.992002
7083	service-registry	healthy	13.562	\N	http://service-registry:8002/health	200	2025-10-08 19:02:23.992002
7084	job-processor	healthy	16.19	\N	http://job-processor:8003/health	200	2025-10-08 19:02:23.992003
7085	file-manager	healthy	16.135	\N	http://file-manager:8004/health	200	2025-10-08 19:02:23.992004
7086	notification	healthy	16.14	\N	http://notification:8005/health	200	2025-10-08 19:02:23.992004
7087	api-gateway	unhealthy	40.362	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:02:55.048103
7088	user-service	healthy	10.425	\N	http://user-service:8001/health	200	2025-10-08 19:02:55.048106
7089	service-registry	healthy	11.030999999999999	\N	http://service-registry:8002/health	200	2025-10-08 19:02:55.048107
7090	job-processor	healthy	13.757	\N	http://job-processor:8003/health	200	2025-10-08 19:02:55.048108
7091	file-manager	healthy	12.066	\N	http://file-manager:8004/health	200	2025-10-08 19:02:55.048108
7092	notification	healthy	33.512	\N	http://notification:8005/health	200	2025-10-08 19:02:55.048109
7093	api-gateway	unhealthy	34.285000000000004	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:03:26.143236
7094	user-service	healthy	41.867000000000004	\N	http://user-service:8001/health	200	2025-10-08 19:03:26.14324
7095	service-registry	healthy	40.503	\N	http://service-registry:8002/health	200	2025-10-08 19:03:26.14324
7096	job-processor	healthy	43.589999999999996	\N	http://job-processor:8003/health	200	2025-10-08 19:03:26.143241
7097	file-manager	healthy	43.461	\N	http://file-manager:8004/health	200	2025-10-08 19:03:26.143242
7098	notification	healthy	43.339999999999996	\N	http://notification:8005/health	200	2025-10-08 19:03:26.143242
7099	api-gateway	unhealthy	11443.151	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:04:09.831822
7100	user-service	healthy	7560.425	\N	http://user-service:8001/health	200	2025-10-08 19:04:09.836824
7101	service-registry	healthy	9176.527	\N	http://service-registry:8002/health	200	2025-10-08 19:04:09.836826
7102	job-processor	healthy	9139.385	\N	http://job-processor:8003/health	200	2025-10-08 19:04:09.836827
7103	file-manager	healthy	9022.319	\N	http://file-manager:8004/health	200	2025-10-08 19:04:09.836828
7104	notification	healthy	9233.980000000001	\N	http://notification:8005/health	200	2025-10-08 19:04:09.836829
7105	api-gateway	unhealthy	5569.848999999999	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:04:48.417292
7106	user-service	healthy	5437.158	\N	http://user-service:8001/health	200	2025-10-08 19:04:48.417296
7107	service-registry	healthy	5428.437	\N	http://service-registry:8002/health	200	2025-10-08 19:04:48.417297
7108	job-processor	healthy	5426.078	\N	http://job-processor:8003/health	200	2025-10-08 19:04:48.417298
7109	file-manager	healthy	5428.053	\N	http://file-manager:8004/health	200	2025-10-08 19:04:48.417298
7110	notification	healthy	5426.294000000001	\N	http://notification:8005/health	200	2025-10-08 19:04:48.417299
7111	api-gateway	unhealthy	22.540999999999997	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:05:19.492102
7112	user-service	healthy	26.966	\N	http://user-service:8001/health	200	2025-10-08 19:05:19.492104
7113	service-registry	healthy	26.653	\N	http://service-registry:8002/health	200	2025-10-08 19:05:19.492105
7114	job-processor	healthy	26.523999999999997	\N	http://job-processor:8003/health	200	2025-10-08 19:05:19.492106
7115	file-manager	healthy	26.429000000000002	\N	http://file-manager:8004/health	200	2025-10-08 19:05:19.492106
7116	notification	healthy	27.02	\N	http://notification:8005/health	200	2025-10-08 19:05:19.492107
7117	api-gateway	unhealthy	53.368	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:05:50.593495
7118	user-service	healthy	69.87	\N	http://user-service:8001/health	200	2025-10-08 19:05:50.593498
7119	service-registry	healthy	61.959	\N	http://service-registry:8002/health	200	2025-10-08 19:05:50.593499
7120	job-processor	healthy	74.583	\N	http://job-processor:8003/health	200	2025-10-08 19:05:50.5935
7121	file-manager	healthy	69.025	\N	http://file-manager:8004/health	200	2025-10-08 19:05:50.5935
7122	notification	healthy	78.13199999999999	\N	http://notification:8005/health	200	2025-10-08 19:05:50.593501
7123	api-gateway	unhealthy	11633.857		http://api-gateway:8000/health	\N	2025-10-08 19:06:39.761481
7124	user-service	unhealthy	10851.761		http://user-service:8001/health	\N	2025-10-08 19:06:39.761485
7125	service-registry	unhealthy	10735.275		http://service-registry:8002/health	\N	2025-10-08 19:06:39.761486
7126	job-processor	unhealthy	10587.866		http://job-processor:8003/health	\N	2025-10-08 19:06:39.761486
7127	file-manager	unhealthy	10486.181999999999		http://file-manager:8004/health	\N	2025-10-08 19:06:39.761487
7128	notification	unhealthy	10408.195		http://notification:8005/health	\N	2025-10-08 19:06:39.761487
7129	api-gateway	unhealthy	21.205000000000002	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:07:10.883
7130	user-service	healthy	26.91	\N	http://user-service:8001/health	200	2025-10-08 19:07:10.883003
7131	service-registry	healthy	27.124	\N	http://service-registry:8002/health	200	2025-10-08 19:07:10.883004
7132	job-processor	healthy	26.981	\N	http://job-processor:8003/health	200	2025-10-08 19:07:10.883004
7133	file-manager	healthy	28.319	\N	http://file-manager:8004/health	200	2025-10-08 19:07:10.883005
7134	notification	healthy	29.105	\N	http://notification:8005/health	200	2025-10-08 19:07:10.883005
7135	api-gateway	unhealthy	29.261	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:07:41.927071
7136	user-service	healthy	17.752	\N	http://user-service:8001/health	200	2025-10-08 19:07:41.927074
7137	service-registry	healthy	26.817	\N	http://service-registry:8002/health	200	2025-10-08 19:07:41.927075
7138	job-processor	healthy	26.741	\N	http://job-processor:8003/health	200	2025-10-08 19:07:41.927075
7139	file-manager	healthy	25.680999999999997	\N	http://file-manager:8004/health	200	2025-10-08 19:07:41.927076
7140	notification	healthy	25.953	\N	http://notification:8005/health	200	2025-10-08 19:07:41.927077
7141	api-gateway	unhealthy	22.826	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:08:12.964796
7142	user-service	healthy	17.979	\N	http://user-service:8001/health	200	2025-10-08 19:08:12.964798
7143	service-registry	healthy	14.094000000000001	\N	http://service-registry:8002/health	200	2025-10-08 19:08:12.964799
7144	job-processor	healthy	16.504	\N	http://job-processor:8003/health	200	2025-10-08 19:08:12.9648
7145	file-manager	healthy	18.191	\N	http://file-manager:8004/health	200	2025-10-08 19:08:12.9648
7146	notification	healthy	18.055000000000003	\N	http://notification:8005/health	200	2025-10-08 19:08:12.964801
7147	api-gateway	unhealthy	23.064	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:08:44.004152
7148	user-service	healthy	17.016	\N	http://user-service:8001/health	200	2025-10-08 19:08:44.004155
7149	service-registry	healthy	9.77	\N	http://service-registry:8002/health	200	2025-10-08 19:08:44.004156
7150	job-processor	healthy	17.049000000000003	\N	http://job-processor:8003/health	200	2025-10-08 19:08:44.004157
7151	file-manager	healthy	19.259999999999998	\N	http://file-manager:8004/health	200	2025-10-08 19:08:44.004157
7152	notification	healthy	18.215	\N	http://notification:8005/health	200	2025-10-08 19:08:44.004158
7153	api-gateway	unhealthy	35.37	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:09:15.060061
7154	user-service	healthy	20.66	\N	http://user-service:8001/health	200	2025-10-08 19:09:15.060064
7155	service-registry	healthy	23.445	\N	http://service-registry:8002/health	200	2025-10-08 19:09:15.060065
7156	job-processor	healthy	34.13	\N	http://job-processor:8003/health	200	2025-10-08 19:09:15.060066
7157	file-manager	healthy	33.946999999999996	\N	http://file-manager:8004/health	200	2025-10-08 19:09:15.060066
7158	notification	healthy	34.423	\N	http://notification:8005/health	200	2025-10-08 19:09:15.060067
7159	api-gateway	unhealthy	24.858	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:09:46.099201
7160	user-service	healthy	21.599	\N	http://user-service:8001/health	200	2025-10-08 19:09:46.099204
7161	service-registry	healthy	21.128	\N	http://service-registry:8002/health	200	2025-10-08 19:09:46.099205
7162	job-processor	healthy	21.175	\N	http://job-processor:8003/health	200	2025-10-08 19:09:46.099205
7163	file-manager	healthy	21.080000000000002	\N	http://file-manager:8004/health	200	2025-10-08 19:09:46.099206
7164	notification	healthy	22.16	\N	http://notification:8005/health	200	2025-10-08 19:09:46.099206
7165	api-gateway	unhealthy	40.417	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:10:17.155394
7166	user-service	healthy	13.424	\N	http://user-service:8001/health	200	2025-10-08 19:10:17.155396
7167	service-registry	healthy	14.281	\N	http://service-registry:8002/health	200	2025-10-08 19:10:17.155397
7168	job-processor	healthy	22.389	\N	http://job-processor:8003/health	200	2025-10-08 19:10:17.155398
7169	file-manager	healthy	18.53	\N	http://file-manager:8004/health	200	2025-10-08 19:10:17.155398
7170	notification	healthy	24.542	\N	http://notification:8005/health	200	2025-10-08 19:10:17.155399
7171	api-gateway	unhealthy	22.131	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:10:48.197509
7172	user-service	healthy	23.695999999999998	\N	http://user-service:8001/health	200	2025-10-08 19:10:48.197511
7173	service-registry	healthy	23.060000000000002	\N	http://service-registry:8002/health	200	2025-10-08 19:10:48.197512
7174	job-processor	healthy	22.914	\N	http://job-processor:8003/health	200	2025-10-08 19:10:48.197512
7175	file-manager	healthy	23.408	\N	http://file-manager:8004/health	200	2025-10-08 19:10:48.197513
7176	notification	healthy	23.316	\N	http://notification:8005/health	200	2025-10-08 19:10:48.197514
7177	api-gateway	unhealthy	28.523	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:11:19.259127
7178	user-service	healthy	25.78	\N	http://user-service:8001/health	200	2025-10-08 19:11:19.25913
7179	service-registry	healthy	36.117999999999995	\N	http://service-registry:8002/health	200	2025-10-08 19:11:19.25913
7180	job-processor	healthy	36.007	\N	http://job-processor:8003/health	200	2025-10-08 19:11:19.259131
7181	file-manager	healthy	38.203	\N	http://file-manager:8004/health	200	2025-10-08 19:11:19.259132
7182	notification	healthy	38.149	\N	http://notification:8005/health	200	2025-10-08 19:11:19.259132
7183	api-gateway	unhealthy	25.233999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:11:50.304154
7184	user-service	healthy	23.677	\N	http://user-service:8001/health	200	2025-10-08 19:11:50.304156
7185	service-registry	healthy	16.845	\N	http://service-registry:8002/health	200	2025-10-08 19:11:50.304157
7186	job-processor	healthy	22.873	\N	http://job-processor:8003/health	200	2025-10-08 19:11:50.304158
7187	file-manager	healthy	23.852999999999998	\N	http://file-manager:8004/health	200	2025-10-08 19:11:50.304158
7188	notification	healthy	26.698	\N	http://notification:8005/health	200	2025-10-08 19:11:50.304159
7189	api-gateway	unhealthy	27.532999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:12:21.353648
7190	user-service	healthy	28.118000000000002	\N	http://user-service:8001/health	200	2025-10-08 19:12:21.353651
7191	service-registry	healthy	27.882	\N	http://service-registry:8002/health	200	2025-10-08 19:12:21.353652
7192	job-processor	healthy	28.293	\N	http://job-processor:8003/health	200	2025-10-08 19:12:21.353652
7193	file-manager	healthy	32.856	\N	http://file-manager:8004/health	200	2025-10-08 19:12:21.353653
7194	notification	healthy	31.064999999999998	\N	http://notification:8005/health	200	2025-10-08 19:12:21.353653
7195	api-gateway	unhealthy	28.68	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:12:52.399376
7196	user-service	healthy	15.198	\N	http://user-service:8001/health	200	2025-10-08 19:12:52.399379
7197	service-registry	healthy	14.94	\N	http://service-registry:8002/health	200	2025-10-08 19:12:52.39938
7198	job-processor	healthy	18.801	\N	http://job-processor:8003/health	200	2025-10-08 19:12:52.39938
7199	file-manager	healthy	16.962999999999997	\N	http://file-manager:8004/health	200	2025-10-08 19:12:52.399381
7200	notification	healthy	20.073	\N	http://notification:8005/health	200	2025-10-08 19:12:52.399382
7201	api-gateway	unhealthy	34.702999999999996	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:13:23.44691
7202	user-service	healthy	12.336	\N	http://user-service:8001/health	200	2025-10-08 19:13:23.446913
7203	service-registry	healthy	14.718	\N	http://service-registry:8002/health	200	2025-10-08 19:13:23.446914
7204	job-processor	healthy	16.046999999999997	\N	http://job-processor:8003/health	200	2025-10-08 19:13:23.446914
7205	file-manager	healthy	17.975	\N	http://file-manager:8004/health	200	2025-10-08 19:13:23.446915
7206	notification	healthy	21.978	\N	http://notification:8005/health	200	2025-10-08 19:13:23.446916
7207	api-gateway	unhealthy	27.825	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:13:54.501441
7208	user-service	healthy	28.589	\N	http://user-service:8001/health	200	2025-10-08 19:13:54.501446
7209	service-registry	healthy	28.304	\N	http://service-registry:8002/health	200	2025-10-08 19:13:54.501447
7210	job-processor	healthy	31.924	\N	http://job-processor:8003/health	200	2025-10-08 19:13:54.501447
7211	file-manager	healthy	31.837999999999997	\N	http://file-manager:8004/health	200	2025-10-08 19:13:54.501448
7212	notification	healthy	32.448	\N	http://notification:8005/health	200	2025-10-08 19:13:54.501449
7213	api-gateway	unhealthy	31.112000000000002	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:14:25.549411
7214	user-service	healthy	23.456	\N	http://user-service:8001/health	200	2025-10-08 19:14:25.549414
7215	service-registry	healthy	28.512	\N	http://service-registry:8002/health	200	2025-10-08 19:14:25.549415
7216	job-processor	healthy	28.407999999999998	\N	http://job-processor:8003/health	200	2025-10-08 19:14:25.549416
7217	file-manager	healthy	27.747	\N	http://file-manager:8004/health	200	2025-10-08 19:14:25.549417
7218	notification	healthy	28.51	\N	http://notification:8005/health	200	2025-10-08 19:14:25.549418
7219	api-gateway	unhealthy	34.155	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:14:56.808082
7220	user-service	healthy	237.61499999999998	\N	http://user-service:8001/health	200	2025-10-08 19:14:56.808085
7221	service-registry	healthy	34.717999999999996	\N	http://service-registry:8002/health	200	2025-10-08 19:14:56.808086
7222	job-processor	healthy	34.583000000000006	\N	http://job-processor:8003/health	200	2025-10-08 19:14:56.808086
7223	file-manager	healthy	34.449	\N	http://file-manager:8004/health	200	2025-10-08 19:14:56.808088
7224	notification	healthy	37.662	\N	http://notification:8005/health	200	2025-10-08 19:14:56.808088
7225	api-gateway	unhealthy	28.599	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:15:27.85062
7226	user-service	healthy	24.061	\N	http://user-service:8001/health	200	2025-10-08 19:15:27.850623
7227	service-registry	healthy	24.17	\N	http://service-registry:8002/health	200	2025-10-08 19:15:27.850624
7228	job-processor	healthy	24.384	\N	http://job-processor:8003/health	200	2025-10-08 19:15:27.850624
7229	file-manager	healthy	26.483	\N	http://file-manager:8004/health	200	2025-10-08 19:15:27.850625
7230	notification	healthy	26.423	\N	http://notification:8005/health	200	2025-10-08 19:15:27.850626
7231	api-gateway	unhealthy	23.851	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:15:58.892388
7232	user-service	healthy	19.421999999999997	\N	http://user-service:8001/health	200	2025-10-08 19:15:58.892391
7233	service-registry	healthy	14.867999999999999	\N	http://service-registry:8002/health	200	2025-10-08 19:15:58.892391
7234	job-processor	healthy	14.781	\N	http://job-processor:8003/health	200	2025-10-08 19:15:58.892392
7235	file-manager	healthy	14.758000000000001	\N	http://file-manager:8004/health	200	2025-10-08 19:15:58.892393
7236	notification	healthy	18.401	\N	http://notification:8005/health	200	2025-10-08 19:15:58.892393
7237	api-gateway	unhealthy	21.475	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:16:29.946309
7238	user-service	healthy	19.581	\N	http://user-service:8001/health	200	2025-10-08 19:16:29.946312
7239	service-registry	healthy	17.822000000000003	\N	http://service-registry:8002/health	200	2025-10-08 19:16:29.946313
7240	job-processor	healthy	21.124	\N	http://job-processor:8003/health	200	2025-10-08 19:16:29.946313
7241	file-manager	healthy	34.765	\N	http://file-manager:8004/health	200	2025-10-08 19:16:29.946314
7242	notification	healthy	35.321	\N	http://notification:8005/health	200	2025-10-08 19:16:29.946315
7243	api-gateway	unhealthy	40.38	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:17:01.003232
7244	user-service	healthy	34.785000000000004	\N	http://user-service:8001/health	200	2025-10-08 19:17:01.003235
7245	service-registry	healthy	34.519	\N	http://service-registry:8002/health	200	2025-10-08 19:17:01.003236
7246	job-processor	healthy	33.97	\N	http://job-processor:8003/health	200	2025-10-08 19:17:01.003237
7247	file-manager	healthy	34.671	\N	http://file-manager:8004/health	200	2025-10-08 19:17:01.003238
7248	notification	healthy	34.230999999999995	\N	http://notification:8005/health	200	2025-10-08 19:17:01.003238
7249	api-gateway	unhealthy	17.88	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:17:32.037515
7250	user-service	healthy	14.028	\N	http://user-service:8001/health	200	2025-10-08 19:17:32.037519
7251	service-registry	healthy	10.904	\N	http://service-registry:8002/health	200	2025-10-08 19:17:32.03752
7252	job-processor	healthy	13.572000000000001	\N	http://job-processor:8003/health	200	2025-10-08 19:17:32.037521
7253	file-manager	healthy	14.156	\N	http://file-manager:8004/health	200	2025-10-08 19:17:32.037522
7254	notification	healthy	15.333	\N	http://notification:8005/health	200	2025-10-08 19:17:32.037522
7255	api-gateway	unhealthy	30.139	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:18:03.080496
7256	user-service	healthy	22.443	\N	http://user-service:8001/health	200	2025-10-08 19:18:03.080498
7257	service-registry	healthy	19.765	\N	http://service-registry:8002/health	200	2025-10-08 19:18:03.080499
7258	job-processor	healthy	26.061999999999998	\N	http://job-processor:8003/health	200	2025-10-08 19:18:03.0805
7259	file-manager	healthy	26.389	\N	http://file-manager:8004/health	200	2025-10-08 19:18:03.0805
7260	notification	healthy	26.834	\N	http://notification:8005/health	200	2025-10-08 19:18:03.080501
7261	api-gateway	unhealthy	23.743	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:18:34.150951
7262	user-service	healthy	34.01499999999999	\N	http://user-service:8001/health	200	2025-10-08 19:18:34.150954
7263	service-registry	healthy	33.791000000000004	\N	http://service-registry:8002/health	200	2025-10-08 19:18:34.150955
7264	job-processor	healthy	35.151	\N	http://job-processor:8003/health	200	2025-10-08 19:18:34.150956
7265	file-manager	healthy	32.864	\N	http://file-manager:8004/health	200	2025-10-08 19:18:34.150956
7266	notification	healthy	34.816	\N	http://notification:8005/health	200	2025-10-08 19:18:34.150957
7267	api-gateway	unhealthy	25.391000000000002	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:19:05.189206
7268	user-service	healthy	23.338	\N	http://user-service:8001/health	200	2025-10-08 19:19:05.189209
7269	service-registry	healthy	22.884999999999998	\N	http://service-registry:8002/health	200	2025-10-08 19:19:05.18921
7270	job-processor	healthy	22.914	\N	http://job-processor:8003/health	200	2025-10-08 19:19:05.18921
7271	file-manager	healthy	22.244	\N	http://file-manager:8004/health	200	2025-10-08 19:19:05.189211
7272	notification	healthy	23.015	\N	http://notification:8005/health	200	2025-10-08 19:19:05.189212
7273	api-gateway	unhealthy	21.425	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:19:36.236971
7274	user-service	healthy	24.747999999999998	\N	http://user-service:8001/health	200	2025-10-08 19:19:36.236974
7275	service-registry	healthy	24.076	\N	http://service-registry:8002/health	200	2025-10-08 19:19:36.236975
7276	job-processor	healthy	23.949	\N	http://job-processor:8003/health	200	2025-10-08 19:19:36.236976
7277	file-manager	healthy	24	\N	http://file-manager:8004/health	200	2025-10-08 19:19:36.236976
7278	notification	healthy	24.865000000000002	\N	http://notification:8005/health	200	2025-10-08 19:19:36.236977
7279	api-gateway	unhealthy	26.505000000000003	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:20:07.275839
7280	user-service	healthy	13.321	\N	http://user-service:8001/health	200	2025-10-08 19:20:07.275842
7281	service-registry	healthy	12.206	\N	http://service-registry:8002/health	200	2025-10-08 19:20:07.275843
7282	job-processor	healthy	14.392999999999999	\N	http://job-processor:8003/health	200	2025-10-08 19:20:07.275844
7283	file-manager	healthy	17.923000000000002	\N	http://file-manager:8004/health	200	2025-10-08 19:20:07.275845
7284	notification	healthy	17.881	\N	http://notification:8005/health	200	2025-10-08 19:20:07.275845
7285	api-gateway	unhealthy	13.124	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:20:38.314394
7286	user-service	healthy	15.566	\N	http://user-service:8001/health	200	2025-10-08 19:20:38.314397
7287	service-registry	healthy	14.182	\N	http://service-registry:8002/health	200	2025-10-08 19:20:38.314397
7288	job-processor	healthy	17.878	\N	http://job-processor:8003/health	200	2025-10-08 19:20:38.314398
7289	file-manager	healthy	17.456	\N	http://file-manager:8004/health	200	2025-10-08 19:20:38.314399
7290	notification	healthy	17.041	\N	http://notification:8005/health	200	2025-10-08 19:20:38.314399
7291	api-gateway	unhealthy	26.768	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:21:09.367829
7292	user-service	healthy	21.968	\N	http://user-service:8001/health	200	2025-10-08 19:21:09.367832
7293	service-registry	healthy	21.445	\N	http://service-registry:8002/health	200	2025-10-08 19:21:09.367832
7294	job-processor	healthy	23.743	\N	http://job-processor:8003/health	200	2025-10-08 19:21:09.367833
7295	file-manager	healthy	22.973	\N	http://file-manager:8004/health	200	2025-10-08 19:21:09.367834
7296	notification	healthy	30.368	\N	http://notification:8005/health	200	2025-10-08 19:21:09.367834
7297	api-gateway	unhealthy	32.125	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:21:40.415749
7298	user-service	healthy	21.111	\N	http://user-service:8001/health	200	2025-10-08 19:21:40.415751
7299	service-registry	healthy	20.932	\N	http://service-registry:8002/health	200	2025-10-08 19:21:40.415752
7300	job-processor	healthy	20.767999999999997	\N	http://job-processor:8003/health	200	2025-10-08 19:21:40.415753
7301	file-manager	healthy	20.674000000000003	\N	http://file-manager:8004/health	200	2025-10-08 19:21:40.415754
7302	notification	healthy	21.457	\N	http://notification:8005/health	200	2025-10-08 19:21:40.415754
7303	api-gateway	unhealthy	25.198999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:22:11.473963
7304	user-service	healthy	38.574999999999996	\N	http://user-service:8001/health	200	2025-10-08 19:22:11.473966
7305	service-registry	healthy	38.372	\N	http://service-registry:8002/health	200	2025-10-08 19:22:11.473966
7306	job-processor	healthy	38.272	\N	http://job-processor:8003/health	200	2025-10-08 19:22:11.473967
7307	file-manager	healthy	38.186	\N	http://file-manager:8004/health	200	2025-10-08 19:22:11.473968
7308	notification	healthy	38.119	\N	http://notification:8005/health	200	2025-10-08 19:22:11.473968
7309	api-gateway	unhealthy	17.9	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:22:42.534608
7310	user-service	healthy	31.351999999999997	\N	http://user-service:8001/health	200	2025-10-08 19:22:42.534611
7311	service-registry	healthy	21.564	\N	http://service-registry:8002/health	200	2025-10-08 19:22:42.534611
7312	job-processor	healthy	32.417	\N	http://job-processor:8003/health	200	2025-10-08 19:22:42.534612
7313	file-manager	healthy	42.113	\N	http://file-manager:8004/health	200	2025-10-08 19:22:42.534613
7314	notification	healthy	32.059	\N	http://notification:8005/health	200	2025-10-08 19:22:42.534613
7315	api-gateway	unhealthy	29.211000000000002	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:23:13.580482
7316	user-service	healthy	27.812	\N	http://user-service:8001/health	200	2025-10-08 19:23:13.580484
7317	service-registry	healthy	27.003	\N	http://service-registry:8002/health	200	2025-10-08 19:23:13.580485
7318	job-processor	healthy	26.415000000000003	\N	http://job-processor:8003/health	200	2025-10-08 19:23:13.580486
7319	file-manager	healthy	26.613999999999997	\N	http://file-manager:8004/health	200	2025-10-08 19:23:13.580486
7320	notification	healthy	28.084	\N	http://notification:8005/health	200	2025-10-08 19:23:13.580487
7321	api-gateway	unhealthy	25.874000000000002	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:23:44.627232
7322	user-service	healthy	27.548	\N	http://user-service:8001/health	200	2025-10-08 19:23:44.627235
7323	service-registry	healthy	13.963	\N	http://service-registry:8002/health	200	2025-10-08 19:23:44.627236
7324	job-processor	healthy	26.143	\N	http://job-processor:8003/health	200	2025-10-08 19:23:44.627236
7325	file-manager	healthy	28.006	\N	http://file-manager:8004/health	200	2025-10-08 19:23:44.627237
7326	notification	healthy	27.936	\N	http://notification:8005/health	200	2025-10-08 19:23:44.627237
7327	api-gateway	unhealthy	30.107	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:24:15.680989
7328	user-service	healthy	25.679000000000002	\N	http://user-service:8001/health	200	2025-10-08 19:24:15.680992
7329	service-registry	unhealthy	20.072	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:24:15.680993
7330	job-processor	healthy	28.383	\N	http://job-processor:8003/health	200	2025-10-08 19:24:15.680994
7331	file-manager	healthy	30.594	\N	http://file-manager:8004/health	200	2025-10-08 19:24:15.680994
7332	notification	healthy	30.536	\N	http://notification:8005/health	200	2025-10-08 19:24:15.680995
7333	api-gateway	unhealthy	50.247	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:24:46.751223
7334	user-service	healthy	29.808	\N	http://user-service:8001/health	200	2025-10-08 19:24:46.751225
7335	service-registry	unhealthy	29.601	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:24:46.751226
7336	job-processor	healthy	38.083	\N	http://job-processor:8003/health	200	2025-10-08 19:24:46.751227
7337	file-manager	healthy	39.335	\N	http://file-manager:8004/health	200	2025-10-08 19:24:46.751227
7338	notification	healthy	39.209	\N	http://notification:8005/health	200	2025-10-08 19:24:46.751228
7339	api-gateway	unhealthy	31.482000000000003	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:25:17.799221
7340	user-service	healthy	29.076999999999998	\N	http://user-service:8001/health	200	2025-10-08 19:25:17.799224
7341	service-registry	unhealthy	28.476000000000003	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:25:17.799225
7342	job-processor	healthy	28.528000000000002	\N	http://job-processor:8003/health	200	2025-10-08 19:25:17.799225
7343	file-manager	healthy	28.413	\N	http://file-manager:8004/health	200	2025-10-08 19:25:17.799226
7344	notification	healthy	29.092	\N	http://notification:8005/health	200	2025-10-08 19:25:17.799227
7345	api-gateway	unhealthy	42.623000000000005	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:25:48.859012
7346	user-service	healthy	19.657	\N	http://user-service:8001/health	200	2025-10-08 19:25:48.859015
7347	service-registry	unhealthy	36.971	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:25:48.859016
7348	job-processor	healthy	19.544999999999998	\N	http://job-processor:8003/health	200	2025-10-08 19:25:48.859016
7349	file-manager	healthy	26.912	\N	http://file-manager:8004/health	200	2025-10-08 19:25:48.859017
7350	notification	healthy	27.325	\N	http://notification:8005/health	200	2025-10-08 19:25:48.859017
7351	api-gateway	unhealthy	21.399	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:26:19.909098
7352	user-service	healthy	19.511	\N	http://user-service:8001/health	200	2025-10-08 19:26:19.9091
7353	service-registry	unhealthy	19.309	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:26:19.909101
7354	job-processor	healthy	21.329	\N	http://job-processor:8003/health	200	2025-10-08 19:26:19.909102
7355	file-manager	healthy	22.659	\N	http://file-manager:8004/health	200	2025-10-08 19:26:19.909102
7356	notification	healthy	22.318	\N	http://notification:8005/health	200	2025-10-08 19:26:19.909103
7357	api-gateway	unhealthy	21.37	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:26:50.946067
7358	user-service	healthy	9.674	\N	http://user-service:8001/health	200	2025-10-08 19:26:50.946069
7359	service-registry	unhealthy	12.215	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:26:50.94607
7360	job-processor	healthy	10.352	\N	http://job-processor:8003/health	200	2025-10-08 19:26:50.94607
7361	file-manager	healthy	11.289	\N	http://file-manager:8004/health	200	2025-10-08 19:26:50.946071
7362	notification	healthy	14.091	\N	http://notification:8005/health	200	2025-10-08 19:26:50.946071
7363	api-gateway	unhealthy	30.484	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:27:21.992222
7364	user-service	healthy	24.11	\N	http://user-service:8001/health	200	2025-10-08 19:27:21.992225
7427	file-manager	healthy	18.328	\N	http://file-manager:8004/health	200	2025-10-08 19:32:32.389852
7365	service-registry	unhealthy	16.809	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:27:21.992225
7366	job-processor	healthy	24.358999999999998	\N	http://job-processor:8003/health	200	2025-10-08 19:27:21.992226
7367	file-manager	healthy	24.848	\N	http://file-manager:8004/health	200	2025-10-08 19:27:21.992226
7368	notification	healthy	25.253	\N	http://notification:8005/health	200	2025-10-08 19:27:21.992227
7369	api-gateway	unhealthy	26.44	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:27:53.037149
7370	user-service	healthy	17.682	\N	http://user-service:8001/health	200	2025-10-08 19:27:53.037152
7371	service-registry	unhealthy	23.907999999999998	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:27:53.037152
7372	job-processor	healthy	17.887	\N	http://job-processor:8003/health	200	2025-10-08 19:27:53.037153
7373	file-manager	healthy	23.154999999999998	\N	http://file-manager:8004/health	200	2025-10-08 19:27:53.037154
7374	notification	healthy	23.886999999999997	\N	http://notification:8005/health	200	2025-10-08 19:27:53.037155
7375	api-gateway	unhealthy	28.51	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:28:24.08101
7376	user-service	healthy	9.655999999999999	\N	http://user-service:8001/health	200	2025-10-08 19:28:24.081012
7377	service-registry	unhealthy	9.528	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:28:24.081013
7378	job-processor	healthy	11.385	\N	http://job-processor:8003/health	200	2025-10-08 19:28:24.081014
7379	file-manager	healthy	13.03	\N	http://file-manager:8004/health	200	2025-10-08 19:28:24.081015
7380	notification	healthy	13.592	\N	http://notification:8005/health	200	2025-10-08 19:28:24.081015
7381	api-gateway	unhealthy	13.861	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:28:55.110118
7382	user-service	healthy	9.245	\N	http://user-service:8001/health	200	2025-10-08 19:28:55.11012
7383	service-registry	unhealthy	14.122	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:28:55.110121
7384	job-processor	healthy	11.181	\N	http://job-processor:8003/health	200	2025-10-08 19:28:55.110122
7385	file-manager	healthy	11.925	\N	http://file-manager:8004/health	200	2025-10-08 19:28:55.110122
7386	notification	healthy	12.774000000000001	\N	http://notification:8005/health	200	2025-10-08 19:28:55.110123
7387	api-gateway	unhealthy	17.655	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:29:26.140652
7388	user-service	healthy	9.51	\N	http://user-service:8001/health	200	2025-10-08 19:29:26.140655
7389	service-registry	unhealthy	13.046000000000001	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:29:26.140656
7390	job-processor	healthy	10.831	\N	http://job-processor:8003/health	200	2025-10-08 19:29:26.140656
7391	file-manager	healthy	11.74	\N	http://file-manager:8004/health	200	2025-10-08 19:29:26.140657
7392	notification	healthy	12.512	\N	http://notification:8005/health	200	2025-10-08 19:29:26.140658
7393	api-gateway	unhealthy	18.517	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:29:57.176367
7394	user-service	healthy	12.984	\N	http://user-service:8001/health	200	2025-10-08 19:29:57.17637
7395	service-registry	unhealthy	17.180999999999997	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:29:57.176371
7396	job-processor	healthy	13.064	\N	http://job-processor:8003/health	200	2025-10-08 19:29:57.176371
7397	file-manager	healthy	13.972	\N	http://file-manager:8004/health	200	2025-10-08 19:29:57.176372
7398	notification	healthy	13.894	\N	http://notification:8005/health	200	2025-10-08 19:29:57.176373
7399	api-gateway	unhealthy	15.908999999999999	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:30:28.216445
7400	user-service	healthy	9.870000000000001	\N	http://user-service:8001/health	200	2025-10-08 19:30:28.216448
7401	service-registry	unhealthy	20.217	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:30:28.216449
7402	job-processor	healthy	11.667	\N	http://job-processor:8003/health	200	2025-10-08 19:30:28.21645
7403	file-manager	healthy	12.606	\N	http://file-manager:8004/health	200	2025-10-08 19:30:28.21645
7404	notification	healthy	15.327	\N	http://notification:8005/health	200	2025-10-08 19:30:28.216451
7405	api-gateway	unhealthy	19.652	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:30:59.251549
7406	user-service	healthy	16.889000000000003	\N	http://user-service:8001/health	200	2025-10-08 19:30:59.251552
7407	service-registry	unhealthy	16.897	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:30:59.251552
7408	job-processor	healthy	16.108999999999998	\N	http://job-processor:8003/health	200	2025-10-08 19:30:59.251553
7409	file-manager	healthy	16.154999999999998	\N	http://file-manager:8004/health	200	2025-10-08 19:30:59.251554
7410	notification	healthy	17.156000000000002	\N	http://notification:8005/health	200	2025-10-08 19:30:59.251554
7411	api-gateway	unhealthy	24.861	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:31:30.29231
7412	user-service	healthy	13.414	\N	http://user-service:8001/health	200	2025-10-08 19:31:30.292313
7413	service-registry	unhealthy	13.265	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:31:30.292314
7414	job-processor	healthy	16.398	\N	http://job-processor:8003/health	200	2025-10-08 19:31:30.292314
7415	file-manager	healthy	17.084	\N	http://file-manager:8004/health	200	2025-10-08 19:31:30.292315
7416	notification	healthy	22.926	\N	http://notification:8005/health	200	2025-10-08 19:31:30.292316
7417	api-gateway	unhealthy	37.757	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:32:01.345282
7418	user-service	healthy	12.606	\N	http://user-service:8001/health	200	2025-10-08 19:32:01.345284
7419	service-registry	unhealthy	19.936	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:32:01.345285
7420	job-processor	healthy	12.197	\N	http://job-processor:8003/health	200	2025-10-08 19:32:01.345286
7421	file-manager	healthy	15.286	\N	http://file-manager:8004/health	200	2025-10-08 19:32:01.345286
7422	notification	healthy	18.322000000000003	\N	http://notification:8005/health	200	2025-10-08 19:32:01.345287
7423	api-gateway	unhealthy	23.366	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:32:32.389848
7424	user-service	healthy	17.348	\N	http://user-service:8001/health	200	2025-10-08 19:32:32.38985
7425	service-registry	unhealthy	17.297	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:32:32.389851
7426	job-processor	healthy	16.619	\N	http://job-processor:8003/health	200	2025-10-08 19:32:32.389852
7428	notification	healthy	18.253999999999998	\N	http://notification:8005/health	200	2025-10-08 19:32:32.389853
7429	api-gateway	unhealthy	26.131999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:33:03.452176
7430	user-service	healthy	20.725	\N	http://user-service:8001/health	200	2025-10-08 19:33:03.452178
7431	service-registry	unhealthy	24.112000000000002	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:33:03.452179
7432	job-processor	healthy	36.549	\N	http://job-processor:8003/health	200	2025-10-08 19:33:03.45218
7433	file-manager	healthy	36.464000000000006	\N	http://file-manager:8004/health	200	2025-10-08 19:33:03.45218
7434	notification	healthy	36.492999999999995	\N	http://notification:8005/health	200	2025-10-08 19:33:03.452181
7435	api-gateway	unhealthy	20.469	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:33:34.489003
7436	user-service	healthy	11.584000000000001	\N	http://user-service:8001/health	200	2025-10-08 19:33:34.489005
7437	service-registry	unhealthy	13.802999999999999	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:33:34.489006
7438	job-processor	healthy	11.168000000000001	\N	http://job-processor:8003/health	200	2025-10-08 19:33:34.489007
7439	file-manager	healthy	11.071	\N	http://file-manager:8004/health	200	2025-10-08 19:33:34.489007
7440	notification	healthy	13.998999999999999	\N	http://notification:8005/health	200	2025-10-08 19:33:34.489008
7441	api-gateway	unhealthy	21.724	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:34:05.529615
7442	user-service	healthy	12.451	\N	http://user-service:8001/health	200	2025-10-08 19:34:05.529617
7443	service-registry	unhealthy	14.909	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:34:05.529618
7444	job-processor	healthy	13.498	\N	http://job-processor:8003/health	200	2025-10-08 19:34:05.529619
7445	file-manager	healthy	14.191	\N	http://file-manager:8004/health	200	2025-10-08 19:34:05.529619
7446	notification	healthy	14.954	\N	http://notification:8005/health	200	2025-10-08 19:34:05.52962
7447	api-gateway	unhealthy	50.511	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:34:36.599026
7448	user-service	healthy	10.587	\N	http://user-service:8001/health	200	2025-10-08 19:34:36.599029
7449	service-registry	unhealthy	33.365	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:34:36.599029
7450	job-processor	healthy	30.720000000000002	\N	http://job-processor:8003/health	200	2025-10-08 19:34:36.59903
7451	file-manager	healthy	31.676999999999996	\N	http://file-manager:8004/health	200	2025-10-08 19:34:36.599031
7452	notification	healthy	31.596	\N	http://notification:8005/health	200	2025-10-08 19:34:36.599031
7453	api-gateway	unhealthy	22.020000000000003	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:35:07.633605
7454	user-service	healthy	17.365	\N	http://user-service:8001/health	200	2025-10-08 19:35:07.633608
7455	service-registry	unhealthy	14.244	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:35:07.633609
7456	job-processor	healthy	19.380000000000003	\N	http://job-processor:8003/health	200	2025-10-08 19:35:07.633609
7457	file-manager	healthy	19.276	\N	http://file-manager:8004/health	200	2025-10-08 19:35:07.63361
7458	notification	healthy	19.904	\N	http://notification:8005/health	200	2025-10-08 19:35:07.63361
7459	api-gateway	unhealthy	31.497999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:35:38.687702
7460	user-service	healthy	14.123	\N	http://user-service:8001/health	200	2025-10-08 19:35:38.687705
7461	service-registry	unhealthy	27.327	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:35:38.687705
7462	job-processor	healthy	15.07	\N	http://job-processor:8003/health	200	2025-10-08 19:35:38.687706
7463	file-manager	healthy	15.424	\N	http://file-manager:8004/health	200	2025-10-08 19:35:38.687707
7464	notification	healthy	14.067	\N	http://notification:8005/health	200	2025-10-08 19:35:38.687707
7465	api-gateway	unhealthy	22.326999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:36:09.734284
7466	user-service	healthy	10.437	\N	http://user-service:8001/health	200	2025-10-08 19:36:09.734287
7467	service-registry	unhealthy	30.198	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:36:09.734288
7468	job-processor	healthy	14.189	\N	http://job-processor:8003/health	200	2025-10-08 19:36:09.734288
7469	file-manager	healthy	16.365000000000002	\N	http://file-manager:8004/health	200	2025-10-08 19:36:09.734289
7470	notification	healthy	16.878	\N	http://notification:8005/health	200	2025-10-08 19:36:09.734289
7471	api-gateway	unhealthy	22.057	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:36:40.774841
7472	user-service	healthy	11.56	\N	http://user-service:8001/health	200	2025-10-08 19:36:40.774843
7473	service-registry	unhealthy	15.157	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:36:40.774844
7474	job-processor	healthy	21.195	\N	http://job-processor:8003/health	200	2025-10-08 19:36:40.774845
7475	file-manager	healthy	22.198	\N	http://file-manager:8004/health	200	2025-10-08 19:36:40.774845
7476	notification	healthy	22.613999999999997	\N	http://notification:8005/health	200	2025-10-08 19:36:40.774846
7477	api-gateway	unhealthy	21.305999999999997	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:37:11.809217
7478	user-service	healthy	16.358	\N	http://user-service:8001/health	200	2025-10-08 19:37:11.809219
7479	service-registry	unhealthy	17.128	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:37:11.80922
7480	job-processor	healthy	19.087	\N	http://job-processor:8003/health	200	2025-10-08 19:37:11.809221
7481	file-manager	healthy	18.997	\N	http://file-manager:8004/health	200	2025-10-08 19:37:11.809221
7482	notification	healthy	18.408	\N	http://notification:8005/health	200	2025-10-08 19:37:11.809222
7483	api-gateway	unhealthy	21.557	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:37:42.854501
7484	user-service	healthy	11.268	\N	http://user-service:8001/health	200	2025-10-08 19:37:42.854504
7485	service-registry	unhealthy	16.594	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:37:42.854504
7486	job-processor	healthy	17.892000000000003	\N	http://job-processor:8003/health	200	2025-10-08 19:37:42.854505
7487	file-manager	healthy	17.721	\N	http://file-manager:8004/health	200	2025-10-08 19:37:42.854506
7488	notification	healthy	18.265	\N	http://notification:8005/health	200	2025-10-08 19:37:42.854506
7489	api-gateway	unhealthy	19.496	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:38:13.900339
7490	user-service	healthy	27.07	\N	http://user-service:8001/health	200	2025-10-08 19:38:13.900341
7491	service-registry	unhealthy	16.834	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:38:13.900342
7492	job-processor	healthy	26.051000000000002	\N	http://job-processor:8003/health	200	2025-10-08 19:38:13.900343
7493	file-manager	healthy	25.335	\N	http://file-manager:8004/health	200	2025-10-08 19:38:13.900343
7494	notification	healthy	24.809	\N	http://notification:8005/health	200	2025-10-08 19:38:13.900344
7495	api-gateway	unhealthy	19.667	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:38:44.94409
7496	user-service	healthy	11.414	\N	http://user-service:8001/health	200	2025-10-08 19:38:44.944093
7497	service-registry	unhealthy	16.762	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:38:44.944094
7498	job-processor	healthy	16.708000000000002	\N	http://job-processor:8003/health	200	2025-10-08 19:38:44.944095
7499	file-manager	healthy	12.834999999999999	\N	http://file-manager:8004/health	200	2025-10-08 19:38:44.944095
7500	notification	healthy	23.088	\N	http://notification:8005/health	200	2025-10-08 19:38:44.944096
7501	api-gateway	unhealthy	21.662	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:39:15.993896
7502	user-service	healthy	17.464	\N	http://user-service:8001/health	200	2025-10-08 19:39:15.993898
7503	service-registry	unhealthy	17.482	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:39:15.993899
7504	job-processor	healthy	16.979999999999997	\N	http://job-processor:8003/health	200	2025-10-08 19:39:15.9939
7505	file-manager	healthy	19.211	\N	http://file-manager:8004/health	200	2025-10-08 19:39:15.9939
7506	notification	healthy	21.610999999999997	\N	http://notification:8005/health	200	2025-10-08 19:39:15.993901
7507	api-gateway	unhealthy	18.114	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:39:47.031181
7508	user-service	healthy	20.554	\N	http://user-service:8001/health	200	2025-10-08 19:39:47.031183
7509	service-registry	unhealthy	12.709	[Errno -3] Temporary failure in name resolution	http://service-registry:8002/health	\N	2025-10-08 19:39:47.031184
7510	job-processor	healthy	18.247	\N	http://job-processor:8003/health	200	2025-10-08 19:39:47.031185
7511	file-manager	healthy	18.144000000000002	\N	http://file-manager:8004/health	200	2025-10-08 19:39:47.031185
7512	notification	healthy	19.298	\N	http://notification:8005/health	200	2025-10-08 19:39:47.031186
7513	api-gateway	unhealthy	24.94	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:40:18.103047
7514	user-service	healthy	13.517	\N	http://user-service:8001/health	200	2025-10-08 19:40:18.10305
7515	service-registry	unhealthy	6.8500000000000005	All connection attempts failed	http://service-registry:8002/health	\N	2025-10-08 19:40:18.103051
7516	job-processor	healthy	14.576	\N	http://job-processor:8003/health	200	2025-10-08 19:40:18.103051
7517	file-manager	healthy	12.789	\N	http://file-manager:8004/health	200	2025-10-08 19:40:18.103052
7518	notification	healthy	13.742	\N	http://notification:8005/health	200	2025-10-08 19:40:18.103052
7519	api-gateway	unhealthy	24.035	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:40:49.140487
7520	user-service	healthy	15.546000000000001	\N	http://user-service:8001/health	200	2025-10-08 19:40:49.140489
7521	service-registry	healthy	15.895	\N	http://service-registry:8002/health	200	2025-10-08 19:40:49.14049
7522	job-processor	healthy	16.424999999999997	\N	http://job-processor:8003/health	200	2025-10-08 19:40:49.14049
7523	file-manager	healthy	20.708000000000002	\N	http://file-manager:8004/health	200	2025-10-08 19:40:49.140491
7524	notification	healthy	16.912	\N	http://notification:8005/health	200	2025-10-08 19:40:49.140492
7525	api-gateway	unhealthy	26.110000000000003	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:41:20.184263
7526	user-service	healthy	18.674	\N	http://user-service:8001/health	200	2025-10-08 19:41:20.184266
7527	service-registry	healthy	11.966	\N	http://service-registry:8002/health	200	2025-10-08 19:41:20.184267
7528	job-processor	healthy	12.396	\N	http://job-processor:8003/health	200	2025-10-08 19:41:20.184267
7529	file-manager	healthy	13.719999999999999	\N	http://file-manager:8004/health	200	2025-10-08 19:41:20.184268
7530	notification	healthy	12.749	\N	http://notification:8005/health	200	2025-10-08 19:41:20.184268
7531	api-gateway	unhealthy	20.219	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:41:51.219104
7532	user-service	healthy	12.372	\N	http://user-service:8001/health	200	2025-10-08 19:41:51.219107
7533	service-registry	healthy	12.739	\N	http://service-registry:8002/health	200	2025-10-08 19:41:51.219108
7534	job-processor	healthy	13.59	\N	http://job-processor:8003/health	200	2025-10-08 19:41:51.219108
7535	file-manager	healthy	14.595	\N	http://file-manager:8004/health	200	2025-10-08 19:41:51.219109
7536	notification	healthy	15.249	\N	http://notification:8005/health	200	2025-10-08 19:41:51.21911
7537	api-gateway	unhealthy	19.186	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:42:22.255014
7538	user-service	healthy	17.564	\N	http://user-service:8001/health	200	2025-10-08 19:42:22.255017
7539	service-registry	healthy	17.394	\N	http://service-registry:8002/health	200	2025-10-08 19:42:22.255017
7540	job-processor	healthy	21.262	\N	http://job-processor:8003/health	200	2025-10-08 19:42:22.255018
7541	file-manager	healthy	20.677999999999997	\N	http://file-manager:8004/health	200	2025-10-08 19:42:22.255019
7542	notification	healthy	21.218999999999998	\N	http://notification:8005/health	200	2025-10-08 19:42:22.255019
7543	api-gateway	unhealthy	21.171	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:42:53.305886
7544	user-service	healthy	22.732	\N	http://user-service:8001/health	200	2025-10-08 19:42:53.305889
7545	service-registry	healthy	27.470000000000002	\N	http://service-registry:8002/health	200	2025-10-08 19:42:53.30589
7546	job-processor	healthy	26.822	\N	http://job-processor:8003/health	200	2025-10-08 19:42:53.30589
7547	file-manager	healthy	27.586	\N	http://file-manager:8004/health	200	2025-10-08 19:42:53.305891
7548	notification	healthy	26.488	\N	http://notification:8005/health	200	2025-10-08 19:42:53.305891
7549	api-gateway	unhealthy	30.799	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:43:24.349983
7550	user-service	healthy	17.997	\N	http://user-service:8001/health	200	2025-10-08 19:43:24.349985
7551	service-registry	healthy	15.606	\N	http://service-registry:8002/health	200	2025-10-08 19:43:24.349986
7552	job-processor	healthy	17.573999999999998	\N	http://job-processor:8003/health	200	2025-10-08 19:43:24.349987
7553	file-manager	healthy	18.267	\N	http://file-manager:8004/health	200	2025-10-08 19:43:24.349987
7554	notification	healthy	18.217000000000002	\N	http://notification:8005/health	200	2025-10-08 19:43:24.349988
7555	api-gateway	unhealthy	22.607	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:43:55.387255
7556	user-service	healthy	16.239	\N	http://user-service:8001/health	200	2025-10-08 19:43:55.387258
7557	service-registry	healthy	16.067	\N	http://service-registry:8002/health	200	2025-10-08 19:43:55.387259
7558	job-processor	healthy	15.51	\N	http://job-processor:8003/health	200	2025-10-08 19:43:55.387259
7559	file-manager	healthy	17.775	\N	http://file-manager:8004/health	200	2025-10-08 19:43:55.38726
7560	notification	healthy	17.64	\N	http://notification:8005/health	200	2025-10-08 19:43:55.387261
7561	api-gateway	unhealthy	27.266	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:44:26.431974
7562	user-service	healthy	12.994	\N	http://user-service:8001/health	200	2025-10-08 19:44:26.431977
7563	service-registry	healthy	16.84	\N	http://service-registry:8002/health	200	2025-10-08 19:44:26.431978
7564	job-processor	healthy	16.752	\N	http://job-processor:8003/health	200	2025-10-08 19:44:26.431978
7565	file-manager	healthy	16.843	\N	http://file-manager:8004/health	200	2025-10-08 19:44:26.431979
7566	notification	healthy	16.437	\N	http://notification:8005/health	200	2025-10-08 19:44:26.43198
7567	api-gateway	unhealthy	31.726999999999997	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:44:57.479331
7568	user-service	healthy	12.571	\N	http://user-service:8001/health	200	2025-10-08 19:44:57.479334
7569	service-registry	healthy	14.694	\N	http://service-registry:8002/health	200	2025-10-08 19:44:57.479335
7570	job-processor	healthy	18.49	\N	http://job-processor:8003/health	200	2025-10-08 19:44:57.479336
7571	file-manager	healthy	14.346	\N	http://file-manager:8004/health	200	2025-10-08 19:44:57.479336
7572	notification	healthy	17.776	\N	http://notification:8005/health	200	2025-10-08 19:44:57.479337
7573	api-gateway	unhealthy	19.627	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:45:28.519316
7574	user-service	healthy	15.592	\N	http://user-service:8001/health	200	2025-10-08 19:45:28.519318
7575	service-registry	healthy	14.716	\N	http://service-registry:8002/health	200	2025-10-08 19:45:28.519319
7576	job-processor	healthy	15.204	\N	http://job-processor:8003/health	200	2025-10-08 19:45:28.51932
7577	file-manager	healthy	19.529	\N	http://file-manager:8004/health	200	2025-10-08 19:45:28.519321
7578	notification	healthy	18.708	\N	http://notification:8005/health	200	2025-10-08 19:45:28.519321
7579	api-gateway	unhealthy	19.32	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:45:59.555471
7580	user-service	healthy	18.349	\N	http://user-service:8001/health	200	2025-10-08 19:45:59.555474
7581	service-registry	healthy	17.926000000000002	\N	http://service-registry:8002/health	200	2025-10-08 19:45:59.555475
7582	job-processor	healthy	21.115	\N	http://job-processor:8003/health	200	2025-10-08 19:45:59.555475
7583	file-manager	healthy	20.679	\N	http://file-manager:8004/health	200	2025-10-08 19:45:59.555476
7584	notification	healthy	20.781000000000002	\N	http://notification:8005/health	200	2025-10-08 19:45:59.555477
7585	api-gateway	unhealthy	27.900000000000002	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:46:30.598272
7586	user-service	healthy	16.654	\N	http://user-service:8001/health	200	2025-10-08 19:46:30.598274
7587	service-registry	healthy	16.494000000000003	\N	http://service-registry:8002/health	200	2025-10-08 19:46:30.598275
7588	job-processor	healthy	16.36	\N	http://job-processor:8003/health	200	2025-10-08 19:46:30.598276
7589	file-manager	healthy	16.259	\N	http://file-manager:8004/health	200	2025-10-08 19:46:30.598277
7590	notification	healthy	16.727	\N	http://notification:8005/health	200	2025-10-08 19:46:30.598278
7591	api-gateway	unhealthy	27.810000000000002	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:47:01.642999
7592	user-service	healthy	25.96	\N	http://user-service:8001/health	200	2025-10-08 19:47:01.643002
7593	service-registry	healthy	25.808999999999997	\N	http://service-registry:8002/health	200	2025-10-08 19:47:01.643003
7594	job-processor	healthy	29.598	\N	http://job-processor:8003/health	200	2025-10-08 19:47:01.643004
7595	file-manager	healthy	30.932000000000002	\N	http://file-manager:8004/health	200	2025-10-08 19:47:01.643004
7596	notification	healthy	28.961000000000002	\N	http://notification:8005/health	200	2025-10-08 19:47:01.643005
7597	api-gateway	unhealthy	24.819999999999997	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:47:32.683138
7598	user-service	healthy	21.536	\N	http://user-service:8001/health	200	2025-10-08 19:47:32.68314
7599	service-registry	healthy	19.823	\N	http://service-registry:8002/health	200	2025-10-08 19:47:32.683141
7600	job-processor	healthy	15.091000000000001	\N	http://job-processor:8003/health	200	2025-10-08 19:47:32.683142
7601	file-manager	healthy	19.477999999999998	\N	http://file-manager:8004/health	200	2025-10-08 19:47:32.683142
7602	notification	healthy	19.52	\N	http://notification:8005/health	200	2025-10-08 19:47:32.683143
7603	api-gateway	unhealthy	25.685	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:48:03.726486
7604	user-service	healthy	23.762999999999998	\N	http://user-service:8001/health	200	2025-10-08 19:48:03.726488
7605	service-registry	healthy	23.310000000000002	\N	http://service-registry:8002/health	200	2025-10-08 19:48:03.726489
7606	job-processor	healthy	22.914	\N	http://job-processor:8003/health	200	2025-10-08 19:48:03.726489
7607	file-manager	healthy	24.585	\N	http://file-manager:8004/health	200	2025-10-08 19:48:03.72649
7608	notification	healthy	24.114	\N	http://notification:8005/health	200	2025-10-08 19:48:03.726491
7609	api-gateway	unhealthy	30.488	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:48:34.773438
7610	user-service	healthy	28.222	\N	http://user-service:8001/health	200	2025-10-08 19:48:34.77344
7611	service-registry	healthy	26.539	\N	http://service-registry:8002/health	200	2025-10-08 19:48:34.773441
7612	job-processor	healthy	27.48	\N	http://job-processor:8003/health	200	2025-10-08 19:48:34.773442
7613	file-manager	healthy	28.012999999999998	\N	http://file-manager:8004/health	200	2025-10-08 19:48:34.773442
7614	notification	healthy	30.911	\N	http://notification:8005/health	200	2025-10-08 19:48:34.773443
7615	api-gateway	unhealthy	25.031000000000002	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:49:05.813618
7616	user-service	healthy	22.618	\N	http://user-service:8001/health	200	2025-10-08 19:49:05.81362
7617	service-registry	healthy	22.423	\N	http://service-registry:8002/health	200	2025-10-08 19:49:05.813621
7618	job-processor	healthy	22.473	\N	http://job-processor:8003/health	200	2025-10-08 19:49:05.813622
7619	file-manager	healthy	22.418	\N	http://file-manager:8004/health	200	2025-10-08 19:49:05.813622
7620	notification	healthy	26.355	\N	http://notification:8005/health	200	2025-10-08 19:49:05.813623
7621	api-gateway	unhealthy	27.791	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:49:36.863912
7622	user-service	healthy	8.654	\N	http://user-service:8001/health	200	2025-10-08 19:49:36.863915
7623	service-registry	healthy	9.069	\N	http://service-registry:8002/health	200	2025-10-08 19:49:36.863916
7624	job-processor	healthy	22.782	\N	http://job-processor:8003/health	200	2025-10-08 19:49:36.863917
7625	file-manager	healthy	24.150000000000002	\N	http://file-manager:8004/health	200	2025-10-08 19:49:36.863917
7626	notification	healthy	26.970000000000002	\N	http://notification:8005/health	200	2025-10-08 19:49:36.863918
7627	api-gateway	unhealthy	24.519	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:50:07.907042
7628	user-service	healthy	22.194	\N	http://user-service:8001/health	200	2025-10-08 19:50:07.907044
7629	service-registry	healthy	12.463000000000001	\N	http://service-registry:8002/health	200	2025-10-08 19:50:07.907045
7630	job-processor	healthy	14.5	\N	http://job-processor:8003/health	200	2025-10-08 19:50:07.907046
7631	file-manager	healthy	15.324000000000002	\N	http://file-manager:8004/health	200	2025-10-08 19:50:07.907047
7632	notification	healthy	19.127000000000002	\N	http://notification:8005/health	200	2025-10-08 19:50:07.907047
7633	api-gateway	unhealthy	37.926	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:50:38.956729
7634	user-service	healthy	15.907999999999998	\N	http://user-service:8001/health	200	2025-10-08 19:50:38.956732
7635	service-registry	healthy	16.989	\N	http://service-registry:8002/health	200	2025-10-08 19:50:38.956732
7636	job-processor	healthy	17.058	\N	http://job-processor:8003/health	200	2025-10-08 19:50:38.956733
7637	file-manager	healthy	17.558	\N	http://file-manager:8004/health	200	2025-10-08 19:50:38.956734
7638	notification	healthy	18.015	\N	http://notification:8005/health	200	2025-10-08 19:50:38.956735
7639	api-gateway	unhealthy	27.781	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:51:10.000382
7640	user-service	healthy	19.830000000000002	\N	http://user-service:8001/health	200	2025-10-08 19:51:10.000385
7641	service-registry	healthy	19.581999999999997	\N	http://service-registry:8002/health	200	2025-10-08 19:51:10.000386
7642	job-processor	healthy	20.628	\N	http://job-processor:8003/health	200	2025-10-08 19:51:10.000387
7643	file-manager	healthy	24.264999999999997	\N	http://file-manager:8004/health	200	2025-10-08 19:51:10.000387
7644	notification	healthy	24.799000000000003	\N	http://notification:8005/health	200	2025-10-08 19:51:10.000388
7645	api-gateway	unhealthy	32.602	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:51:41.050204
7646	user-service	healthy	24.423000000000002	\N	http://user-service:8001/health	200	2025-10-08 19:51:41.050206
7647	service-registry	healthy	23.931	\N	http://service-registry:8002/health	200	2025-10-08 19:51:41.050207
7648	job-processor	healthy	23.967	\N	http://job-processor:8003/health	200	2025-10-08 19:51:41.050208
7649	file-manager	healthy	30.349	\N	http://file-manager:8004/health	200	2025-10-08 19:51:41.050208
7650	notification	healthy	31.188	\N	http://notification:8005/health	200	2025-10-08 19:51:41.050209
7651	api-gateway	unhealthy	22.738999999999997	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:52:12.090963
7652	user-service	healthy	27.720000000000002	\N	http://user-service:8001/health	200	2025-10-08 19:52:12.090965
7653	service-registry	healthy	27.594	\N	http://service-registry:8002/health	200	2025-10-08 19:52:12.090966
7654	job-processor	healthy	27.684	\N	http://job-processor:8003/health	200	2025-10-08 19:52:12.090966
7655	file-manager	healthy	26.733	\N	http://file-manager:8004/health	200	2025-10-08 19:52:12.090967
7656	notification	healthy	27.907999999999998	\N	http://notification:8005/health	200	2025-10-08 19:52:12.090968
7657	api-gateway	unhealthy	27.517	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:52:43.130997
7658	user-service	healthy	13.151	\N	http://user-service:8001/health	200	2025-10-08 19:52:43.131
7659	service-registry	healthy	12.715	\N	http://service-registry:8002/health	200	2025-10-08 19:52:43.131001
7660	job-processor	healthy	16.337999999999997	\N	http://job-processor:8003/health	200	2025-10-08 19:52:43.131002
7661	file-manager	healthy	13.682	\N	http://file-manager:8004/health	200	2025-10-08 19:52:43.131002
7662	notification	healthy	23.599	\N	http://notification:8005/health	200	2025-10-08 19:52:43.131003
7663	api-gateway	unhealthy	30.989	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:53:14.179347
7664	user-service	healthy	19.188	\N	http://user-service:8001/health	200	2025-10-08 19:53:14.17935
7665	service-registry	healthy	18.969	\N	http://service-registry:8002/health	200	2025-10-08 19:53:14.179351
7666	job-processor	healthy	18.854	\N	http://job-processor:8003/health	200	2025-10-08 19:53:14.179351
7667	file-manager	healthy	22.535	\N	http://file-manager:8004/health	200	2025-10-08 19:53:14.179352
7668	notification	healthy	23	\N	http://notification:8005/health	200	2025-10-08 19:53:14.179353
7669	api-gateway	unhealthy	21.561	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:53:45.231315
7670	user-service	healthy	23.747	\N	http://user-service:8001/health	200	2025-10-08 19:53:45.231318
7671	service-registry	healthy	27.331999999999997	\N	http://service-registry:8002/health	200	2025-10-08 19:53:45.231319
7672	job-processor	healthy	27.548	\N	http://job-processor:8003/health	200	2025-10-08 19:53:45.23132
7673	file-manager	healthy	27.105	\N	http://file-manager:8004/health	200	2025-10-08 19:53:45.23132
7674	notification	healthy	26.697	\N	http://notification:8005/health	200	2025-10-08 19:53:45.231321
7675	api-gateway	unhealthy	28.71	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:54:16.273848
7676	user-service	healthy	25.597	\N	http://user-service:8001/health	200	2025-10-08 19:54:16.273851
7677	service-registry	healthy	26.584	\N	http://service-registry:8002/health	200	2025-10-08 19:54:16.273852
7678	job-processor	healthy	25.555999999999997	\N	http://job-processor:8003/health	200	2025-10-08 19:54:16.273852
7679	file-manager	healthy	26.063	\N	http://file-manager:8004/health	200	2025-10-08 19:54:16.273853
7680	notification	healthy	27.229	\N	http://notification:8005/health	200	2025-10-08 19:54:16.273854
7681	api-gateway	unhealthy	26.052	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:54:47.315122
7682	user-service	healthy	14.89	\N	http://user-service:8001/health	200	2025-10-08 19:54:47.315124
7683	service-registry	healthy	18.554000000000002	\N	http://service-registry:8002/health	200	2025-10-08 19:54:47.315125
7684	job-processor	healthy	23.843	\N	http://job-processor:8003/health	200	2025-10-08 19:54:47.315126
7685	file-manager	healthy	22.199	\N	http://file-manager:8004/health	200	2025-10-08 19:54:47.315126
7686	notification	healthy	23.176	\N	http://notification:8005/health	200	2025-10-08 19:54:47.315127
7687	api-gateway	unhealthy	37.677	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:55:18.367214
7688	user-service	healthy	9.513	\N	http://user-service:8001/health	200	2025-10-08 19:55:18.367216
7689	service-registry	healthy	17.992	\N	http://service-registry:8002/health	200	2025-10-08 19:55:18.367217
7690	job-processor	healthy	18.84	\N	http://job-processor:8003/health	200	2025-10-08 19:55:18.367218
7691	file-manager	healthy	20.379	\N	http://file-manager:8004/health	200	2025-10-08 19:55:18.367218
7692	notification	healthy	19.906	\N	http://notification:8005/health	200	2025-10-08 19:55:18.367219
7693	api-gateway	unhealthy	30.168	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:55:49.412443
7694	user-service	healthy	21.276	\N	http://user-service:8001/health	200	2025-10-08 19:55:49.412446
7695	service-registry	healthy	14.936	\N	http://service-registry:8002/health	200	2025-10-08 19:55:49.412447
7696	job-processor	healthy	15.469	\N	http://job-processor:8003/health	200	2025-10-08 19:55:49.412447
7697	file-manager	healthy	15.426	\N	http://file-manager:8004/health	200	2025-10-08 19:55:49.412448
7698	notification	healthy	18.705	\N	http://notification:8005/health	200	2025-10-08 19:55:49.412448
7699	api-gateway	unhealthy	23.546	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:56:20.452015
7700	user-service	healthy	21.478	\N	http://user-service:8001/health	200	2025-10-08 19:56:20.452018
7701	service-registry	healthy	21.236	\N	http://service-registry:8002/health	200	2025-10-08 19:56:20.452018
7702	job-processor	healthy	23.595000000000002	\N	http://job-processor:8003/health	200	2025-10-08 19:56:20.452019
7703	file-manager	healthy	23.017	\N	http://file-manager:8004/health	200	2025-10-08 19:56:20.452019
7704	notification	healthy	22.397	\N	http://notification:8005/health	200	2025-10-08 19:56:20.45202
7705	api-gateway	unhealthy	48.641999999999996	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:56:51.515668
7706	user-service	healthy	27.121	\N	http://user-service:8001/health	200	2025-10-08 19:56:51.515671
7707	service-registry	healthy	26.923	\N	http://service-registry:8002/health	200	2025-10-08 19:56:51.515671
7708	job-processor	healthy	26.806	\N	http://job-processor:8003/health	200	2025-10-08 19:56:51.515672
7709	file-manager	healthy	26.697	\N	http://file-manager:8004/health	200	2025-10-08 19:56:51.515673
7710	notification	healthy	27.174	\N	http://notification:8005/health	200	2025-10-08 19:56:51.515673
7711	api-gateway	unhealthy	32.373	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:57:22.562312
7712	user-service	healthy	12.703000000000001	\N	http://user-service:8001/health	200	2025-10-08 19:57:22.562315
7713	service-registry	healthy	13.793	\N	http://service-registry:8002/health	200	2025-10-08 19:57:22.562315
7714	job-processor	unhealthy	21.195999999999998	[Errno -3] Temporary failure in name resolution	http://job-processor:8003/health	\N	2025-10-08 19:57:22.562316
7715	file-manager	healthy	13.469999999999999	\N	http://file-manager:8004/health	200	2025-10-08 19:57:22.562316
7716	notification	healthy	13.882	\N	http://notification:8005/health	200	2025-10-08 19:57:22.562317
7717	api-gateway	unhealthy	44.366	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:57:53.624632
7718	user-service	healthy	9.723	\N	http://user-service:8001/health	200	2025-10-08 19:57:53.624635
7719	service-registry	healthy	41.660999999999994	\N	http://service-registry:8002/health	200	2025-10-08 19:57:53.624635
7720	job-processor	healthy	41.636	\N	http://job-processor:8003/health	200	2025-10-08 19:57:53.624636
7721	file-manager	healthy	41.201	\N	http://file-manager:8004/health	200	2025-10-08 19:57:53.624636
7722	notification	healthy	42.382999999999996	\N	http://notification:8005/health	200	2025-10-08 19:57:53.624637
7723	api-gateway	unhealthy	22.658	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:58:24.664902
7724	user-service	healthy	22.827	\N	http://user-service:8001/health	200	2025-10-08 19:58:24.664904
7725	service-registry	healthy	20.688000000000002	\N	http://service-registry:8002/health	200	2025-10-08 19:58:24.664905
7726	job-processor	healthy	22.384	\N	http://job-processor:8003/health	200	2025-10-08 19:58:24.664906
7727	file-manager	healthy	24.006	\N	http://file-manager:8004/health	200	2025-10-08 19:58:24.664906
7728	notification	healthy	23.918	\N	http://notification:8005/health	200	2025-10-08 19:58:24.664907
7729	api-gateway	unhealthy	25.29	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:58:55.712692
7730	user-service	healthy	8.827	\N	http://user-service:8001/health	200	2025-10-08 19:58:55.712695
7731	service-registry	healthy	16.108999999999998	\N	http://service-registry:8002/health	200	2025-10-08 19:58:55.712696
7732	job-processor	healthy	15.997999999999998	\N	http://job-processor:8003/health	200	2025-10-08 19:58:55.712696
7733	file-manager	healthy	17.548000000000002	\N	http://file-manager:8004/health	200	2025-10-08 19:58:55.712697
7734	notification	healthy	20.59	\N	http://notification:8005/health	200	2025-10-08 19:58:55.712697
7735	api-gateway	unhealthy	25.628	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:59:26.752456
7736	user-service	healthy	10.524000000000001	\N	http://user-service:8001/health	200	2025-10-08 19:59:26.752458
7737	service-registry	healthy	17.706	\N	http://service-registry:8002/health	200	2025-10-08 19:59:26.752459
7738	job-processor	healthy	16.714	\N	http://job-processor:8003/health	200	2025-10-08 19:59:26.75246
7739	file-manager	healthy	12.635	\N	http://file-manager:8004/health	200	2025-10-08 19:59:26.75246
7740	notification	healthy	9.523	\N	http://notification:8005/health	200	2025-10-08 19:59:26.752461
7741	api-gateway	unhealthy	33.26	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 19:59:57.817816
7742	user-service	healthy	43.115	\N	http://user-service:8001/health	200	2025-10-08 19:59:57.817819
7743	service-registry	healthy	42.943000000000005	\N	http://service-registry:8002/health	200	2025-10-08 19:59:57.81782
7744	job-processor	healthy	44.956999999999994	\N	http://job-processor:8003/health	200	2025-10-08 19:59:57.81782
7745	file-manager	healthy	44.477000000000004	\N	http://file-manager:8004/health	200	2025-10-08 19:59:57.817821
7746	notification	healthy	45.204	\N	http://notification:8005/health	200	2025-10-08 19:59:57.817822
7747	api-gateway	unhealthy	35.201	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:00:28.870709
7748	user-service	healthy	27.434	\N	http://user-service:8001/health	200	2025-10-08 20:00:28.870712
7749	service-registry	healthy	19.682000000000002	\N	http://service-registry:8002/health	200	2025-10-08 20:00:28.870713
7750	job-processor	healthy	33.641999999999996	\N	http://job-processor:8003/health	200	2025-10-08 20:00:28.870714
7751	file-manager	healthy	21.33	\N	http://file-manager:8004/health	200	2025-10-08 20:00:28.870714
7752	notification	healthy	20.906000000000002	\N	http://notification:8005/health	200	2025-10-08 20:00:28.870715
7753	api-gateway	unhealthy	24.018	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:00:59.913749
7754	user-service	healthy	21.562	\N	http://user-service:8001/health	200	2025-10-08 20:00:59.913752
7755	service-registry	healthy	21.397	\N	http://service-registry:8002/health	200	2025-10-08 20:00:59.913752
7756	job-processor	healthy	22.762999999999998	\N	http://job-processor:8003/health	200	2025-10-08 20:00:59.913753
7757	file-manager	healthy	22.343999999999998	\N	http://file-manager:8004/health	200	2025-10-08 20:00:59.913754
7758	notification	healthy	22.916	\N	http://notification:8005/health	200	2025-10-08 20:00:59.913755
7759	api-gateway	unhealthy	22.634999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:01:30.952663
7760	user-service	healthy	8.411	\N	http://user-service:8001/health	200	2025-10-08 20:01:30.952666
7761	service-registry	healthy	10.149000000000001	\N	http://service-registry:8002/health	200	2025-10-08 20:01:30.952667
7762	job-processor	healthy	15.718	\N	http://job-processor:8003/health	200	2025-10-08 20:01:30.952668
7763	file-manager	healthy	16.322	\N	http://file-manager:8004/health	200	2025-10-08 20:01:30.952668
7764	notification	healthy	8.057	\N	http://notification:8005/health	200	2025-10-08 20:01:30.952669
7765	api-gateway	unhealthy	158.341	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:02:02.125161
7766	user-service	healthy	144.982	\N	http://user-service:8001/health	200	2025-10-08 20:02:02.125163
7767	service-registry	healthy	142.686	\N	http://service-registry:8002/health	200	2025-10-08 20:02:02.125164
7768	job-processor	healthy	144.27499999999998	\N	http://job-processor:8003/health	200	2025-10-08 20:02:02.125165
7769	file-manager	healthy	19.123	\N	http://file-manager:8004/health	200	2025-10-08 20:02:02.125165
7770	notification	healthy	16.087	\N	http://notification:8005/health	200	2025-10-08 20:02:02.125166
7771	api-gateway	unhealthy	25.631	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:02:33.170902
7772	user-service	healthy	23.558	\N	http://user-service:8001/health	200	2025-10-08 20:02:33.170905
7773	service-registry	healthy	23.612000000000002	\N	http://service-registry:8002/health	200	2025-10-08 20:02:33.170913
7774	job-processor	healthy	26.343999999999998	\N	http://job-processor:8003/health	200	2025-10-08 20:02:33.170915
7775	file-manager	healthy	24.787	\N	http://file-manager:8004/health	200	2025-10-08 20:02:33.170915
7776	notification	healthy	26.072000000000003	\N	http://notification:8005/health	200	2025-10-08 20:02:33.170916
7777	api-gateway	unhealthy	22.936999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:03:04.208132
7778	user-service	healthy	14.706999999999999	\N	http://user-service:8001/health	200	2025-10-08 20:03:04.208135
7779	service-registry	healthy	20.595	\N	http://service-registry:8002/health	200	2025-10-08 20:03:04.208136
7780	job-processor	healthy	16.105	\N	http://job-processor:8003/health	200	2025-10-08 20:03:04.208137
7781	file-manager	healthy	20.441000000000003	\N	http://file-manager:8004/health	200	2025-10-08 20:03:04.208138
7782	notification	healthy	20.464	\N	http://notification:8005/health	200	2025-10-08 20:03:04.208138
7783	api-gateway	unhealthy	22.48	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:03:35.24654
7784	user-service	healthy	16.061	\N	http://user-service:8001/health	200	2025-10-08 20:03:35.246543
7785	service-registry	healthy	15.616	\N	http://service-registry:8002/health	200	2025-10-08 20:03:35.246544
7786	job-processor	healthy	16.191	\N	http://job-processor:8003/health	200	2025-10-08 20:03:35.246544
7787	file-manager	healthy	17.453	\N	http://file-manager:8004/health	200	2025-10-08 20:03:35.246545
7788	notification	healthy	18.216	\N	http://notification:8005/health	200	2025-10-08 20:03:35.246545
7789	api-gateway	unhealthy	46.571	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:04:06.311203
7790	user-service	healthy	20.551	\N	http://user-service:8001/health	200	2025-10-08 20:04:06.311206
7791	service-registry	healthy	21.523	\N	http://service-registry:8002/health	200	2025-10-08 20:04:06.311206
7792	job-processor	healthy	21.382	\N	http://job-processor:8003/health	200	2025-10-08 20:04:06.311207
7793	file-manager	healthy	26.365	\N	http://file-manager:8004/health	200	2025-10-08 20:04:06.311208
7794	notification	healthy	26.288	\N	http://notification:8005/health	200	2025-10-08 20:04:06.311208
7795	api-gateway	unhealthy	29.354000000000003	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:04:37.354919
7796	user-service	healthy	19.91	\N	http://user-service:8001/health	200	2025-10-08 20:04:37.354922
7797	service-registry	healthy	19.425	\N	http://service-registry:8002/health	200	2025-10-08 20:04:37.354923
7798	job-processor	healthy	23.993000000000002	\N	http://job-processor:8003/health	200	2025-10-08 20:04:37.354924
7799	file-manager	healthy	24.407999999999998	\N	http://file-manager:8004/health	200	2025-10-08 20:04:37.354924
7800	notification	healthy	25.637	\N	http://notification:8005/health	200	2025-10-08 20:04:37.354925
7801	api-gateway	unhealthy	25.151	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:05:08.395802
7802	user-service	healthy	11.839	\N	http://user-service:8001/health	200	2025-10-08 20:05:08.395805
7803	service-registry	healthy	13.798	\N	http://service-registry:8002/health	200	2025-10-08 20:05:08.395806
7804	job-processor	healthy	12.389000000000001	\N	http://job-processor:8003/health	200	2025-10-08 20:05:08.395806
7805	file-manager	healthy	14.293	\N	http://file-manager:8004/health	200	2025-10-08 20:05:08.395807
7806	notification	healthy	12.17	\N	http://notification:8005/health	200	2025-10-08 20:05:08.395808
7807	api-gateway	unhealthy	33.415	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:05:39.442733
7808	user-service	healthy	8.444999999999999	\N	http://user-service:8001/health	200	2025-10-08 20:05:39.442736
7809	service-registry	healthy	7.22	\N	http://service-registry:8002/health	200	2025-10-08 20:05:39.442737
7810	job-processor	healthy	11.273	\N	http://job-processor:8003/health	200	2025-10-08 20:05:39.442738
7811	file-manager	healthy	12.456999999999999	\N	http://file-manager:8004/health	200	2025-10-08 20:05:39.442738
7812	notification	healthy	12.491999999999999	\N	http://notification:8005/health	200	2025-10-08 20:05:39.442739
7813	api-gateway	unhealthy	21.838	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:06:10.501745
7814	user-service	healthy	31.426000000000002	\N	http://user-service:8001/health	200	2025-10-08 20:06:10.501748
7815	service-registry	healthy	35.669	\N	http://service-registry:8002/health	200	2025-10-08 20:06:10.501749
7816	job-processor	healthy	40.620000000000005	\N	http://job-processor:8003/health	200	2025-10-08 20:06:10.501749
7817	file-manager	healthy	40.171	\N	http://file-manager:8004/health	200	2025-10-08 20:06:10.50175
7818	notification	healthy	39.772	\N	http://notification:8005/health	200	2025-10-08 20:06:10.50175
7819	api-gateway	unhealthy	15.356	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:06:41.536251
7820	user-service	healthy	13.643	\N	http://user-service:8001/health	200	2025-10-08 20:06:41.536254
7821	service-registry	healthy	14.401	\N	http://service-registry:8002/health	200	2025-10-08 20:06:41.536255
7822	job-processor	healthy	16.281	\N	http://job-processor:8003/health	200	2025-10-08 20:06:41.536255
7823	file-manager	healthy	16.203	\N	http://file-manager:8004/health	200	2025-10-08 20:06:41.536256
7824	notification	healthy	16.131	\N	http://notification:8005/health	200	2025-10-08 20:06:41.536256
7825	api-gateway	unhealthy	17.144	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:07:12.573737
7826	user-service	healthy	19.717	\N	http://user-service:8001/health	200	2025-10-08 20:07:12.57374
7827	service-registry	healthy	17.16	\N	http://service-registry:8002/health	200	2025-10-08 20:07:12.57374
7828	job-processor	healthy	19.32	\N	http://job-processor:8003/health	200	2025-10-08 20:07:12.573741
7829	file-manager	healthy	19.245	\N	http://file-manager:8004/health	200	2025-10-08 20:07:12.573741
7830	notification	healthy	19.881	\N	http://notification:8005/health	200	2025-10-08 20:07:12.573742
7831	api-gateway	unhealthy	46.041	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:07:43.63573
7832	user-service	healthy	9.168000000000001	\N	http://user-service:8001/health	200	2025-10-08 20:07:43.635733
7833	service-registry	healthy	8.716	\N	http://service-registry:8002/health	200	2025-10-08 20:07:43.635734
7834	job-processor	healthy	23.961	\N	http://job-processor:8003/health	200	2025-10-08 20:07:43.635734
7835	file-manager	healthy	24.019	\N	http://file-manager:8004/health	200	2025-10-08 20:07:43.635735
7836	notification	healthy	23.078000000000003	\N	http://notification:8005/health	200	2025-10-08 20:07:43.635736
7837	api-gateway	unhealthy	19.608	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:08:14.674507
7838	user-service	healthy	17.277	\N	http://user-service:8001/health	200	2025-10-08 20:08:14.674509
7839	service-registry	healthy	17.535999999999998	\N	http://service-registry:8002/health	200	2025-10-08 20:08:14.67451
7840	job-processor	healthy	20.067999999999998	\N	http://job-processor:8003/health	200	2025-10-08 20:08:14.674511
7841	file-manager	healthy	19.185000000000002	\N	http://file-manager:8004/health	200	2025-10-08 20:08:14.674511
7842	notification	healthy	19.348	\N	http://notification:8005/health	200	2025-10-08 20:08:14.674512
7843	api-gateway	unhealthy	20.906000000000002	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:08:45.719103
7844	user-service	healthy	27.830000000000002	\N	http://user-service:8001/health	200	2025-10-08 20:08:45.719105
7845	service-registry	healthy	27.796000000000003	\N	http://service-registry:8002/health	200	2025-10-08 20:08:45.719106
7846	job-processor	healthy	27.107	\N	http://job-processor:8003/health	200	2025-10-08 20:08:45.719107
7847	file-manager	healthy	32.294999999999995	\N	http://file-manager:8004/health	200	2025-10-08 20:08:45.719107
7848	notification	healthy	31.262999999999998	\N	http://notification:8005/health	200	2025-10-08 20:08:45.719108
7849	api-gateway	unhealthy	17.131	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:09:16.751043
7850	user-service	healthy	17.293	\N	http://user-service:8001/health	200	2025-10-08 20:09:16.751046
7851	service-registry	healthy	15.959000000000001	\N	http://service-registry:8002/health	200	2025-10-08 20:09:16.751047
7852	job-processor	healthy	18.086000000000002	\N	http://job-processor:8003/health	200	2025-10-08 20:09:16.751047
7853	file-manager	healthy	18.019000000000002	\N	http://file-manager:8004/health	200	2025-10-08 20:09:16.751048
7854	notification	healthy	18.836	\N	http://notification:8005/health	200	2025-10-08 20:09:16.751048
7855	api-gateway	unhealthy	19.951	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:09:47.78764
7856	user-service	healthy	14.144	\N	http://user-service:8001/health	200	2025-10-08 20:09:47.787643
7857	service-registry	healthy	17.715	\N	http://service-registry:8002/health	200	2025-10-08 20:09:47.787643
7858	job-processor	healthy	17.944000000000003	\N	http://job-processor:8003/health	200	2025-10-08 20:09:47.787644
7859	file-manager	healthy	20.637	\N	http://file-manager:8004/health	200	2025-10-08 20:09:47.787645
7860	notification	healthy	21.229000000000003	\N	http://notification:8005/health	200	2025-10-08 20:09:47.787645
7861	api-gateway	unhealthy	33.696	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:10:18.833864
7862	user-service	healthy	26.796	\N	http://user-service:8001/health	200	2025-10-08 20:10:18.833867
7863	service-registry	healthy	26.657	\N	http://service-registry:8002/health	200	2025-10-08 20:10:18.833868
7864	job-processor	healthy	28.947	\N	http://job-processor:8003/health	200	2025-10-08 20:10:18.833868
7865	file-manager	healthy	31.543000000000003	\N	http://file-manager:8004/health	200	2025-10-08 20:10:18.833869
7866	notification	healthy	31.505	\N	http://notification:8005/health	200	2025-10-08 20:10:18.833869
7867	api-gateway	unhealthy	30.415000000000003	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:10:49.879467
7868	user-service	healthy	18.683000000000003	\N	http://user-service:8001/health	200	2025-10-08 20:10:49.879469
7869	service-registry	healthy	18.218999999999998	\N	http://service-registry:8002/health	200	2025-10-08 20:10:49.87947
7870	job-processor	healthy	17.839000000000002	\N	http://job-processor:8003/health	200	2025-10-08 20:10:49.879471
7871	file-manager	healthy	19.657	\N	http://file-manager:8004/health	200	2025-10-08 20:10:49.879471
7872	notification	healthy	19.248	\N	http://notification:8005/health	200	2025-10-08 20:10:49.879472
7873	api-gateway	unhealthy	18.25	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:11:20.916985
7874	user-service	healthy	11.399	\N	http://user-service:8001/health	200	2025-10-08 20:11:20.916988
7875	service-registry	healthy	14.79	\N	http://service-registry:8002/health	200	2025-10-08 20:11:20.916989
7876	job-processor	healthy	12.264000000000001	\N	http://job-processor:8003/health	200	2025-10-08 20:11:20.916989
7877	file-manager	healthy	13.959	\N	http://file-manager:8004/health	200	2025-10-08 20:11:20.91699
7878	notification	healthy	13.896	\N	http://notification:8005/health	200	2025-10-08 20:11:20.916991
7879	api-gateway	unhealthy	23.369	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:11:51.952352
7880	user-service	healthy	15.862000000000002	\N	http://user-service:8001/health	200	2025-10-08 20:11:51.952355
7881	service-registry	healthy	15.393	\N	http://service-registry:8002/health	200	2025-10-08 20:11:51.952356
7882	job-processor	healthy	15.439	\N	http://job-processor:8003/health	200	2025-10-08 20:11:51.952356
7883	file-manager	healthy	15.803999999999998	\N	http://file-manager:8004/health	200	2025-10-08 20:11:51.952357
7884	notification	healthy	15.730999999999998	\N	http://notification:8005/health	200	2025-10-08 20:11:51.952358
7885	api-gateway	unhealthy	23.026999999999997	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:12:22.994495
7886	user-service	healthy	27.863	\N	http://user-service:8001/health	200	2025-10-08 20:12:22.994498
7887	service-registry	healthy	27.659	\N	http://service-registry:8002/health	200	2025-10-08 20:12:22.994499
7888	job-processor	healthy	27.629	\N	http://job-processor:8003/health	200	2025-10-08 20:12:22.994499
7889	file-manager	healthy	26.898	\N	http://file-manager:8004/health	200	2025-10-08 20:12:22.9945
7890	notification	healthy	27.352	\N	http://notification:8005/health	200	2025-10-08 20:12:22.9945
7891	api-gateway	unhealthy	24.503	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:12:54.033253
7892	user-service	healthy	23.498	\N	http://user-service:8001/health	200	2025-10-08 20:12:54.033256
7893	service-registry	healthy	22.897000000000002	\N	http://service-registry:8002/health	200	2025-10-08 20:12:54.033257
7894	job-processor	healthy	22.796	\N	http://job-processor:8003/health	200	2025-10-08 20:12:54.033257
7895	file-manager	healthy	25.005	\N	http://file-manager:8004/health	200	2025-10-08 20:12:54.033258
7896	notification	healthy	24.582	\N	http://notification:8005/health	200	2025-10-08 20:12:54.033259
7897	api-gateway	unhealthy	21.769000000000002	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:13:25.070352
7898	user-service	healthy	14.964	\N	http://user-service:8001/health	200	2025-10-08 20:13:25.070355
7899	service-registry	healthy	14.046	\N	http://service-registry:8002/health	200	2025-10-08 20:13:25.070355
7900	job-processor	healthy	16.018	\N	http://job-processor:8003/health	200	2025-10-08 20:13:25.070356
7901	file-manager	healthy	16.495	\N	http://file-manager:8004/health	200	2025-10-08 20:13:25.070357
7902	notification	healthy	15.318	\N	http://notification:8005/health	200	2025-10-08 20:13:25.070357
7903	api-gateway	unhealthy	17.721	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:13:56.103734
7904	user-service	healthy	9.758	\N	http://user-service:8001/health	200	2025-10-08 20:13:56.103737
7905	service-registry	healthy	12.021	\N	http://service-registry:8002/health	200	2025-10-08 20:13:56.103738
7906	job-processor	healthy	11.959	\N	http://job-processor:8003/health	200	2025-10-08 20:13:56.103738
7907	file-manager	healthy	15.507	\N	http://file-manager:8004/health	200	2025-10-08 20:13:56.103739
7908	notification	healthy	18.376	\N	http://notification:8005/health	200	2025-10-08 20:13:56.10374
7909	api-gateway	unhealthy	25.309	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:14:27.146273
7910	user-service	healthy	28.346	\N	http://user-service:8001/health	200	2025-10-08 20:14:27.146276
7911	service-registry	healthy	16.217	\N	http://service-registry:8002/health	200	2025-10-08 20:14:27.146277
7912	job-processor	healthy	27.676	\N	http://job-processor:8003/health	200	2025-10-08 20:14:27.146277
7913	file-manager	healthy	27.262999999999998	\N	http://file-manager:8004/health	200	2025-10-08 20:14:27.146278
7914	notification	healthy	27.175	\N	http://notification:8005/health	200	2025-10-08 20:14:27.146279
7915	api-gateway	unhealthy	26.353	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:14:58.184939
7916	user-service	healthy	16.504	\N	http://user-service:8001/health	200	2025-10-08 20:14:58.184941
7917	service-registry	healthy	18.855	\N	http://service-registry:8002/health	200	2025-10-08 20:14:58.184942
7918	job-processor	healthy	18.317	\N	http://job-processor:8003/health	200	2025-10-08 20:14:58.184942
7919	file-manager	healthy	20.755	\N	http://file-manager:8004/health	200	2025-10-08 20:14:58.184943
7920	notification	healthy	20.807	\N	http://notification:8005/health	200	2025-10-08 20:14:58.184943
7921	api-gateway	unhealthy	25.695	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:15:29.222716
7922	user-service	healthy	19.311	\N	http://user-service:8001/health	200	2025-10-08 20:15:29.222718
7923	service-registry	healthy	21.928	\N	http://service-registry:8002/health	200	2025-10-08 20:15:29.222719
7924	job-processor	healthy	21.838	\N	http://job-processor:8003/health	200	2025-10-08 20:15:29.22272
7925	file-manager	healthy	23.607	\N	http://file-manager:8004/health	200	2025-10-08 20:15:29.22272
7926	notification	healthy	23.605999999999998	\N	http://notification:8005/health	200	2025-10-08 20:15:29.222721
7927	api-gateway	unhealthy	15.041	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:16:00.251098
7928	user-service	healthy	9.972	\N	http://user-service:8001/health	200	2025-10-08 20:16:00.2511
7929	service-registry	healthy	11.298	\N	http://service-registry:8002/health	200	2025-10-08 20:16:00.251101
7930	job-processor	healthy	13.465	\N	http://job-processor:8003/health	200	2025-10-08 20:16:00.251102
7931	file-manager	healthy	13.405999999999999	\N	http://file-manager:8004/health	200	2025-10-08 20:16:00.251102
7932	notification	healthy	15.793999999999999	\N	http://notification:8005/health	200	2025-10-08 20:16:00.251103
7933	api-gateway	unhealthy	22.899	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:16:31.285426
7934	user-service	healthy	7.939	\N	http://user-service:8001/health	200	2025-10-08 20:16:31.285429
7935	service-registry	healthy	16.579	\N	http://service-registry:8002/health	200	2025-10-08 20:16:31.28543
7936	job-processor	healthy	13.011	\N	http://job-processor:8003/health	200	2025-10-08 20:16:31.28543
7937	file-manager	healthy	8.469000000000001	\N	http://file-manager:8004/health	200	2025-10-08 20:16:31.285431
7938	notification	healthy	9.168000000000001	\N	http://notification:8005/health	200	2025-10-08 20:16:31.285431
7939	api-gateway	unhealthy	18.262	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:17:02.324986
7940	user-service	healthy	18.648	\N	http://user-service:8001/health	200	2025-10-08 20:17:02.324988
7941	service-registry	healthy	19.982	\N	http://service-registry:8002/health	200	2025-10-08 20:17:02.324989
7942	job-processor	healthy	19.902	\N	http://job-processor:8003/health	200	2025-10-08 20:17:02.32499
7943	file-manager	healthy	21.869	\N	http://file-manager:8004/health	200	2025-10-08 20:17:02.32499
7944	notification	healthy	21.438	\N	http://notification:8005/health	200	2025-10-08 20:17:02.324991
7945	api-gateway	unhealthy	20.654	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:17:33.364505
7946	user-service	healthy	23.641	\N	http://user-service:8001/health	200	2025-10-08 20:17:33.364508
7947	service-registry	healthy	21.822000000000003	\N	http://service-registry:8002/health	200	2025-10-08 20:17:33.364509
7948	job-processor	healthy	22.967000000000002	\N	http://job-processor:8003/health	200	2025-10-08 20:17:33.364509
7949	file-manager	healthy	25.765	\N	http://file-manager:8004/health	200	2025-10-08 20:17:33.36451
7950	notification	healthy	25.705	\N	http://notification:8005/health	200	2025-10-08 20:17:33.364511
7951	api-gateway	unhealthy	28.495	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:18:04.412722
7952	user-service	healthy	24.875999999999998	\N	http://user-service:8001/health	200	2025-10-08 20:18:04.412724
7953	service-registry	healthy	20.926000000000002	\N	http://service-registry:8002/health	200	2025-10-08 20:18:04.412725
7954	job-processor	healthy	28.367	\N	http://job-processor:8003/health	200	2025-10-08 20:18:04.412726
7955	file-manager	healthy	27.939	\N	http://file-manager:8004/health	200	2025-10-08 20:18:04.412726
7956	notification	healthy	30.904	\N	http://notification:8005/health	200	2025-10-08 20:18:04.412727
7957	api-gateway	unhealthy	20.761000000000003	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:18:35.445428
7958	user-service	healthy	19.893	\N	http://user-service:8001/health	200	2025-10-08 20:18:35.44543
7959	service-registry	healthy	12.091	\N	http://service-registry:8002/health	200	2025-10-08 20:18:35.445431
7960	job-processor	healthy	7.846000000000001	\N	http://job-processor:8003/health	200	2025-10-08 20:18:35.445432
7961	file-manager	healthy	17.968	\N	http://file-manager:8004/health	200	2025-10-08 20:18:35.445433
7962	notification	healthy	18.196	\N	http://notification:8005/health	200	2025-10-08 20:18:35.445434
7963	api-gateway	unhealthy	35.97	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:19:06.493556
7964	user-service	healthy	12.437999999999999	\N	http://user-service:8001/health	200	2025-10-08 20:19:06.493559
7965	service-registry	healthy	11.440000000000001	\N	http://service-registry:8002/health	200	2025-10-08 20:19:06.493559
7966	job-processor	healthy	14.087	\N	http://job-processor:8003/health	200	2025-10-08 20:19:06.49356
7967	file-manager	healthy	12.297	\N	http://file-manager:8004/health	200	2025-10-08 20:19:06.493561
7968	notification	healthy	18.779	\N	http://notification:8005/health	200	2025-10-08 20:19:06.493562
7969	api-gateway	unhealthy	23.631	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:19:37.537674
7970	user-service	healthy	21.156000000000002	\N	http://user-service:8001/health	200	2025-10-08 20:19:37.537676
7971	service-registry	healthy	20.974	\N	http://service-registry:8002/health	200	2025-10-08 20:19:37.537677
7972	job-processor	healthy	22.226	\N	http://job-processor:8003/health	200	2025-10-08 20:19:37.537678
7973	file-manager	healthy	22.125	\N	http://file-manager:8004/health	200	2025-10-08 20:19:37.537678
7974	notification	healthy	24.951999999999998	\N	http://notification:8005/health	200	2025-10-08 20:19:37.537679
7975	api-gateway	unhealthy	22.728	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:20:08.574997
7976	user-service	healthy	21.353	\N	http://user-service:8001/health	200	2025-10-08 20:20:08.574999
7977	service-registry	healthy	16.559	\N	http://service-registry:8002/health	200	2025-10-08 20:20:08.575
7978	job-processor	healthy	20.916	\N	http://job-processor:8003/health	200	2025-10-08 20:20:08.575001
7979	file-manager	healthy	21.715000000000003	\N	http://file-manager:8004/health	200	2025-10-08 20:20:08.575001
7980	notification	healthy	22.194	\N	http://notification:8005/health	200	2025-10-08 20:20:08.575002
7981	api-gateway	unhealthy	21.723	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:20:39.610757
7982	user-service	healthy	20.602	\N	http://user-service:8001/health	200	2025-10-08 20:20:39.61076
7983	service-registry	healthy	19.040000000000003	\N	http://service-registry:8002/health	200	2025-10-08 20:20:39.61076
7984	job-processor	healthy	22.115	\N	http://job-processor:8003/health	200	2025-10-08 20:20:39.610761
7985	file-manager	healthy	22.069	\N	http://file-manager:8004/health	200	2025-10-08 20:20:39.610762
7986	notification	healthy	22.75	\N	http://notification:8005/health	200	2025-10-08 20:20:39.610763
7987	api-gateway	unhealthy	23.259999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:21:10.647412
7988	user-service	healthy	19.931	\N	http://user-service:8001/health	200	2025-10-08 20:21:10.647414
7989	service-registry	healthy	24.225	\N	http://service-registry:8002/health	200	2025-10-08 20:21:10.647415
7990	job-processor	healthy	21.801000000000002	\N	http://job-processor:8003/health	200	2025-10-08 20:21:10.647415
7991	file-manager	healthy	22.522000000000002	\N	http://file-manager:8004/health	200	2025-10-08 20:21:10.647416
7992	notification	healthy	23.689999999999998	\N	http://notification:8005/health	200	2025-10-08 20:21:10.647417
7993	api-gateway	unhealthy	29.717	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:21:41.695833
7994	user-service	healthy	26.008	\N	http://user-service:8001/health	200	2025-10-08 20:21:41.695835
7995	service-registry	healthy	34.408	\N	http://service-registry:8002/health	200	2025-10-08 20:21:41.695836
7996	job-processor	healthy	28.765	\N	http://job-processor:8003/health	200	2025-10-08 20:21:41.695836
7997	file-manager	healthy	33.376999999999995	\N	http://file-manager:8004/health	200	2025-10-08 20:21:41.695837
7998	notification	healthy	33.442	\N	http://notification:8005/health	200	2025-10-08 20:21:41.695837
7999	api-gateway	unhealthy	23.239	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:22:12.744016
8000	user-service	healthy	24.328	\N	http://user-service:8001/health	200	2025-10-08 20:22:12.744018
8001	service-registry	healthy	23.82	\N	http://service-registry:8002/health	200	2025-10-08 20:22:12.744019
8002	job-processor	healthy	24.427	\N	http://job-processor:8003/health	200	2025-10-08 20:22:12.74402
8003	file-manager	healthy	25.769000000000002	\N	http://file-manager:8004/health	200	2025-10-08 20:22:12.74402
8004	notification	healthy	31.075	\N	http://notification:8005/health	200	2025-10-08 20:22:12.744021
8005	api-gateway	unhealthy	22.409	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:22:43.782769
8006	user-service	healthy	23.16	\N	http://user-service:8001/health	200	2025-10-08 20:22:43.782772
8007	service-registry	healthy	22.991999999999997	\N	http://service-registry:8002/health	200	2025-10-08 20:22:43.782772
8008	job-processor	healthy	23.907999999999998	\N	http://job-processor:8003/health	200	2025-10-08 20:22:43.782773
8009	file-manager	healthy	23.841	\N	http://file-manager:8004/health	200	2025-10-08 20:22:43.782774
8010	notification	healthy	24.452	\N	http://notification:8005/health	200	2025-10-08 20:22:43.782774
8011	api-gateway	unhealthy	33.595	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:23:14.831881
8012	user-service	healthy	19.414	\N	http://user-service:8001/health	200	2025-10-08 20:23:14.831883
8013	service-registry	healthy	18.983	\N	http://service-registry:8002/health	200	2025-10-08 20:23:14.831884
8014	job-processor	healthy	20.266	\N	http://job-processor:8003/health	200	2025-10-08 20:23:14.831885
8015	file-manager	healthy	19.389	\N	http://file-manager:8004/health	200	2025-10-08 20:23:14.831885
8016	notification	healthy	20.031	\N	http://notification:8005/health	200	2025-10-08 20:23:14.831886
8017	api-gateway	unhealthy	22.071	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:23:45.866887
8018	user-service	healthy	13.927	\N	http://user-service:8001/health	200	2025-10-08 20:23:45.86689
8019	service-registry	healthy	10.594	\N	http://service-registry:8002/health	200	2025-10-08 20:23:45.866891
8020	job-processor	healthy	18.277	\N	http://job-processor:8003/health	200	2025-10-08 20:23:45.866891
8021	file-manager	healthy	17.663999999999998	\N	http://file-manager:8004/health	200	2025-10-08 20:23:45.866892
8022	notification	healthy	20.167	\N	http://notification:8005/health	200	2025-10-08 20:23:45.866892
8023	api-gateway	unhealthy	24.235	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:24:16.905702
8024	user-service	healthy	13.167	\N	http://user-service:8001/health	200	2025-10-08 20:24:16.905705
8025	service-registry	healthy	16.866	\N	http://service-registry:8002/health	200	2025-10-08 20:24:16.905705
8026	job-processor	healthy	16.764999999999997	\N	http://job-processor:8003/health	200	2025-10-08 20:24:16.905706
8027	file-manager	healthy	18.811	\N	http://file-manager:8004/health	200	2025-10-08 20:24:16.905706
8028	notification	healthy	19.61	\N	http://notification:8005/health	200	2025-10-08 20:24:16.905707
8029	api-gateway	unhealthy	28.578	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:24:47.951673
8030	user-service	healthy	26.849999999999998	\N	http://user-service:8001/health	200	2025-10-08 20:24:47.951676
8031	service-registry	healthy	26.351	\N	http://service-registry:8002/health	200	2025-10-08 20:24:47.951676
8032	job-processor	healthy	25.872	\N	http://job-processor:8003/health	200	2025-10-08 20:24:47.951677
8033	file-manager	healthy	27.902	\N	http://file-manager:8004/health	200	2025-10-08 20:24:47.951677
8034	notification	healthy	27.85	\N	http://notification:8005/health	200	2025-10-08 20:24:47.951678
8035	api-gateway	unhealthy	14.587	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:25:18.982366
8036	user-service	healthy	13.622	\N	http://user-service:8001/health	200	2025-10-08 20:25:18.982369
8037	service-registry	healthy	11.754000000000001	\N	http://service-registry:8002/health	200	2025-10-08 20:25:18.98237
8038	job-processor	healthy	12.856	\N	http://job-processor:8003/health	200	2025-10-08 20:25:18.98237
8039	file-manager	healthy	17.078	\N	http://file-manager:8004/health	200	2025-10-08 20:25:18.982371
8040	notification	healthy	16.622999999999998	\N	http://notification:8005/health	200	2025-10-08 20:25:18.982371
8041	api-gateway	unhealthy	36.114	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:25:50.041099
8042	user-service	healthy	17.006	\N	http://user-service:8001/health	200	2025-10-08 20:25:50.041101
8043	service-registry	healthy	16.863	\N	http://service-registry:8002/health	200	2025-10-08 20:25:50.041102
8044	job-processor	healthy	33.645	\N	http://job-processor:8003/health	200	2025-10-08 20:25:50.041103
8045	file-manager	healthy	26.911	\N	http://file-manager:8004/health	200	2025-10-08 20:25:50.041103
8046	notification	healthy	33.748	\N	http://notification:8005/health	200	2025-10-08 20:25:50.041104
8047	api-gateway	unhealthy	20.442999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:26:21.076994
8048	user-service	healthy	19.151	\N	http://user-service:8001/health	200	2025-10-08 20:26:21.076997
8049	service-registry	healthy	21.402	\N	http://service-registry:8002/health	200	2025-10-08 20:26:21.076997
8050	job-processor	healthy	18.745	\N	http://job-processor:8003/health	200	2025-10-08 20:26:21.076998
8051	file-manager	healthy	18.651999999999997	\N	http://file-manager:8004/health	200	2025-10-08 20:26:21.076998
8052	notification	healthy	18.561999999999998	\N	http://notification:8005/health	200	2025-10-08 20:26:21.076999
8053	api-gateway	unhealthy	47.864999999999995	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:26:52.138262
8054	user-service	healthy	15.323	\N	http://user-service:8001/health	200	2025-10-08 20:26:52.138265
8055	service-registry	healthy	15.108	\N	http://service-registry:8002/health	200	2025-10-08 20:26:52.138266
8056	job-processor	healthy	14.578000000000001	\N	http://job-processor:8003/health	200	2025-10-08 20:26:52.138266
8057	file-manager	healthy	14.785	\N	http://file-manager:8004/health	200	2025-10-08 20:26:52.138267
8058	notification	healthy	15.443	\N	http://notification:8005/health	200	2025-10-08 20:26:52.138268
8059	api-gateway	unhealthy	29.852	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:27:23.180935
8060	user-service	healthy	22.041	\N	http://user-service:8001/health	200	2025-10-08 20:27:23.180938
8061	service-registry	healthy	21.906	\N	http://service-registry:8002/health	200	2025-10-08 20:27:23.180939
8062	job-processor	healthy	21.865	\N	http://job-processor:8003/health	200	2025-10-08 20:27:23.180939
8063	file-manager	healthy	21.797	\N	http://file-manager:8004/health	200	2025-10-08 20:27:23.18094
8064	notification	healthy	22.264	\N	http://notification:8005/health	200	2025-10-08 20:27:23.18094
8065	api-gateway	unhealthy	22.625	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:27:54.216855
8066	user-service	healthy	20.641	\N	http://user-service:8001/health	200	2025-10-08 20:27:54.216857
8067	service-registry	healthy	18.066	\N	http://service-registry:8002/health	200	2025-10-08 20:27:54.216858
8068	job-processor	healthy	21.184	\N	http://job-processor:8003/health	200	2025-10-08 20:27:54.216858
8069	file-manager	healthy	22.546	\N	http://file-manager:8004/health	200	2025-10-08 20:27:54.216859
8070	notification	healthy	22.141000000000002	\N	http://notification:8005/health	200	2025-10-08 20:27:54.21686
8071	api-gateway	unhealthy	24.472	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:28:25.25943
8072	user-service	healthy	25.503999999999998	\N	http://user-service:8001/health	200	2025-10-08 20:28:25.259433
8073	service-registry	healthy	25.335	\N	http://service-registry:8002/health	200	2025-10-08 20:28:25.259433
8074	job-processor	healthy	27.414	\N	http://job-processor:8003/health	200	2025-10-08 20:28:25.259434
8075	file-manager	healthy	26.558999999999997	\N	http://file-manager:8004/health	200	2025-10-08 20:28:25.259434
8076	notification	healthy	26.646	\N	http://notification:8005/health	200	2025-10-08 20:28:25.259435
8077	api-gateway	unhealthy	21.099	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:28:56.293187
8078	user-service	healthy	17.002	\N	http://user-service:8001/health	200	2025-10-08 20:28:56.29319
8079	service-registry	healthy	17.581	\N	http://service-registry:8002/health	200	2025-10-08 20:28:56.29319
8080	job-processor	healthy	16.635	\N	http://job-processor:8003/health	200	2025-10-08 20:28:56.293191
8081	file-manager	healthy	18.261	\N	http://file-manager:8004/health	200	2025-10-08 20:28:56.293192
8082	notification	healthy	18.218	\N	http://notification:8005/health	200	2025-10-08 20:28:56.293192
8083	api-gateway	unhealthy	28.753	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:29:27.342365
8084	user-service	healthy	22.826	\N	http://user-service:8001/health	200	2025-10-08 20:29:27.342368
8085	service-registry	healthy	23.641	\N	http://service-registry:8002/health	200	2025-10-08 20:29:27.342369
8086	job-processor	healthy	25.936	\N	http://job-processor:8003/health	200	2025-10-08 20:29:27.342369
8087	file-manager	healthy	25.531000000000002	\N	http://file-manager:8004/health	200	2025-10-08 20:29:27.34237
8088	notification	healthy	31.695	\N	http://notification:8005/health	200	2025-10-08 20:29:27.34237
8089	api-gateway	unhealthy	24.638	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:29:58.384251
8090	user-service	healthy	20.852	\N	http://user-service:8001/health	200	2025-10-08 20:29:58.384254
8091	service-registry	healthy	18.961	\N	http://service-registry:8002/health	200	2025-10-08 20:29:58.384254
8092	job-processor	healthy	22.156	\N	http://job-processor:8003/health	200	2025-10-08 20:29:58.384255
8093	file-manager	healthy	22.294	\N	http://file-manager:8004/health	200	2025-10-08 20:29:58.384256
8094	notification	healthy	22.263	\N	http://notification:8005/health	200	2025-10-08 20:29:58.384256
8095	api-gateway	unhealthy	19.702	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:30:29.426048
8096	user-service	healthy	24.444	\N	http://user-service:8001/health	200	2025-10-08 20:30:29.426051
8097	service-registry	healthy	24.295	\N	http://service-registry:8002/health	200	2025-10-08 20:30:29.426051
8098	job-processor	healthy	24.186	\N	http://job-processor:8003/health	200	2025-10-08 20:30:29.426052
8099	file-manager	healthy	23.631	\N	http://file-manager:8004/health	200	2025-10-08 20:30:29.426053
8100	notification	healthy	24.058	\N	http://notification:8005/health	200	2025-10-08 20:30:29.426053
8101	api-gateway	unhealthy	19.174	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:31:00.466014
8102	user-service	healthy	24.508	\N	http://user-service:8001/health	200	2025-10-08 20:31:00.466016
8103	service-registry	healthy	22.549	\N	http://service-registry:8002/health	200	2025-10-08 20:31:00.466017
8104	job-processor	healthy	24.298000000000002	\N	http://job-processor:8003/health	200	2025-10-08 20:31:00.466017
8105	file-manager	healthy	23.909	\N	http://file-manager:8004/health	200	2025-10-08 20:31:00.466018
8106	notification	healthy	24.538	\N	http://notification:8005/health	200	2025-10-08 20:31:00.466019
8107	api-gateway	unhealthy	22.244	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:31:31.503956
8108	user-service	healthy	9.025	\N	http://user-service:8001/health	200	2025-10-08 20:31:31.503958
8109	service-registry	healthy	18.981	\N	http://service-registry:8002/health	200	2025-10-08 20:31:31.503959
8110	job-processor	healthy	9.607	\N	http://job-processor:8003/health	200	2025-10-08 20:31:31.503959
8111	file-manager	healthy	18.269000000000002	\N	http://file-manager:8004/health	200	2025-10-08 20:31:31.50396
8112	notification	healthy	9.895	\N	http://notification:8005/health	200	2025-10-08 20:31:31.503961
8113	api-gateway	unhealthy	33.276	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:32:02.566599
8114	user-service	healthy	33.149	\N	http://user-service:8001/health	200	2025-10-08 20:32:02.566616
8115	service-registry	healthy	39.384	\N	http://service-registry:8002/health	200	2025-10-08 20:32:02.566617
8116	job-processor	healthy	39.449	\N	http://job-processor:8003/health	200	2025-10-08 20:32:02.566618
8117	file-manager	healthy	38.330000000000005	\N	http://file-manager:8004/health	200	2025-10-08 20:32:02.566618
8118	notification	healthy	38.953	\N	http://notification:8005/health	200	2025-10-08 20:32:02.566619
8119	api-gateway	unhealthy	38.431	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:32:33.624582
8120	user-service	healthy	33.708	\N	http://user-service:8001/health	200	2025-10-08 20:32:33.624585
8121	service-registry	healthy	33.469	\N	http://service-registry:8002/health	200	2025-10-08 20:32:33.624586
8122	job-processor	healthy	34.93	\N	http://job-processor:8003/health	200	2025-10-08 20:32:33.624587
8123	file-manager	healthy	34.812000000000005	\N	http://file-manager:8004/health	200	2025-10-08 20:32:33.624587
8124	notification	healthy	32.804	\N	http://notification:8005/health	200	2025-10-08 20:32:33.624588
8125	api-gateway	unhealthy	23.128	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:33:04.674476
8126	user-service	healthy	31.08	\N	http://user-service:8001/health	200	2025-10-08 20:33:04.674479
8127	service-registry	healthy	30.931	\N	http://service-registry:8002/health	200	2025-10-08 20:33:04.674479
8128	job-processor	healthy	30.849	\N	http://job-processor:8003/health	200	2025-10-08 20:33:04.67448
8129	file-manager	healthy	29.933	\N	http://file-manager:8004/health	200	2025-10-08 20:33:04.674481
8130	notification	healthy	31.087	\N	http://notification:8005/health	200	2025-10-08 20:33:04.674481
8131	api-gateway	unhealthy	25.886	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:33:35.718134
8132	user-service	healthy	17.561	\N	http://user-service:8001/health	200	2025-10-08 20:33:35.718137
8133	service-registry	healthy	17.392999999999997	\N	http://service-registry:8002/health	200	2025-10-08 20:33:35.718138
8134	job-processor	healthy	17.302999999999997	\N	http://job-processor:8003/health	200	2025-10-08 20:33:35.718139
8135	file-manager	healthy	17.102	\N	http://file-manager:8004/health	200	2025-10-08 20:33:35.718139
8136	notification	healthy	16.647	\N	http://notification:8005/health	200	2025-10-08 20:33:35.71814
8137	api-gateway	unhealthy	36.416	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:34:06.7679
8138	user-service	healthy	34.336999999999996	\N	http://user-service:8001/health	200	2025-10-08 20:34:06.767903
8139	service-registry	healthy	33.861000000000004	\N	http://service-registry:8002/health	200	2025-10-08 20:34:06.767904
8140	job-processor	healthy	33.882000000000005	\N	http://job-processor:8003/health	200	2025-10-08 20:34:06.767904
8141	file-manager	healthy	33.8	\N	http://file-manager:8004/health	200	2025-10-08 20:34:06.767905
8142	notification	healthy	34.611999999999995	\N	http://notification:8005/health	200	2025-10-08 20:34:06.767906
8143	api-gateway	unhealthy	21.296	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:34:37.806072
8144	user-service	healthy	19.784	\N	http://user-service:8001/health	200	2025-10-08 20:34:37.806074
8145	service-registry	healthy	19.580000000000002	\N	http://service-registry:8002/health	200	2025-10-08 20:34:37.806075
8146	job-processor	healthy	19.525000000000002	\N	http://job-processor:8003/health	200	2025-10-08 20:34:37.806076
8147	file-manager	healthy	19.467000000000002	\N	http://file-manager:8004/health	200	2025-10-08 20:34:37.806077
8148	notification	healthy	20.337	\N	http://notification:8005/health	200	2025-10-08 20:34:37.806078
8149	api-gateway	unhealthy	21.105	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:35:08.846471
8150	user-service	healthy	20.849	\N	http://user-service:8001/health	200	2025-10-08 20:35:08.846474
8151	service-registry	healthy	20.646	\N	http://service-registry:8002/health	200	2025-10-08 20:35:08.846474
8152	job-processor	healthy	24.750999999999998	\N	http://job-processor:8003/health	200	2025-10-08 20:35:08.846475
8153	file-manager	healthy	24.331	\N	http://file-manager:8004/health	200	2025-10-08 20:35:08.846476
8154	notification	healthy	23.927	\N	http://notification:8005/health	200	2025-10-08 20:35:08.846477
8155	api-gateway	unhealthy	23.637999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:35:39.891883
8156	user-service	healthy	22.212	\N	http://user-service:8001/health	200	2025-10-08 20:35:39.891886
8157	service-registry	healthy	20.829	\N	http://service-registry:8002/health	200	2025-10-08 20:35:39.891887
8158	job-processor	healthy	25.545	\N	http://job-processor:8003/health	200	2025-10-08 20:35:39.891887
8159	file-manager	healthy	26.152	\N	http://file-manager:8004/health	200	2025-10-08 20:35:39.891888
8160	notification	healthy	26.608	\N	http://notification:8005/health	200	2025-10-08 20:35:39.891888
8161	api-gateway	unhealthy	29.489	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:36:10.935172
8162	user-service	healthy	16.854	\N	http://user-service:8001/health	200	2025-10-08 20:36:10.935175
8163	service-registry	healthy	16.672	\N	http://service-registry:8002/health	200	2025-10-08 20:36:10.935175
8164	job-processor	healthy	16.591	\N	http://job-processor:8003/health	200	2025-10-08 20:36:10.935176
8165	file-manager	healthy	17.733999999999998	\N	http://file-manager:8004/health	200	2025-10-08 20:36:10.935177
8166	notification	healthy	16.285	\N	http://notification:8005/health	200	2025-10-08 20:36:10.935177
8167	api-gateway	unhealthy	29.250999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:36:41.976313
8168	user-service	healthy	9.543	\N	http://user-service:8001/health	200	2025-10-08 20:36:41.976316
8169	service-registry	healthy	14.42	\N	http://service-registry:8002/health	200	2025-10-08 20:36:41.976316
8170	job-processor	healthy	11.103	\N	http://job-processor:8003/health	200	2025-10-08 20:36:41.976317
8171	file-manager	healthy	22.023	\N	http://file-manager:8004/health	200	2025-10-08 20:36:41.976317
8172	notification	healthy	22.291999999999998	\N	http://notification:8005/health	200	2025-10-08 20:36:41.976318
8173	api-gateway	unhealthy	23.181	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:37:13.021604
8174	user-service	healthy	21.46	\N	http://user-service:8001/health	200	2025-10-08 20:37:13.021607
8175	service-registry	healthy	20.947	\N	http://service-registry:8002/health	200	2025-10-08 20:37:13.021608
8176	job-processor	healthy	20.962	\N	http://job-processor:8003/health	200	2025-10-08 20:37:13.021608
8177	file-manager	healthy	23.773	\N	http://file-manager:8004/health	200	2025-10-08 20:37:13.021609
8178	notification	healthy	23.709	\N	http://notification:8005/health	200	2025-10-08 20:37:13.021609
8179	api-gateway	unhealthy	18.317	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:37:44.063627
8180	user-service	healthy	16.692999999999998	\N	http://user-service:8001/health	200	2025-10-08 20:37:44.06363
8181	service-registry	healthy	19.634	\N	http://service-registry:8002/health	200	2025-10-08 20:37:44.063631
8182	job-processor	healthy	19.192	\N	http://job-processor:8003/health	200	2025-10-08 20:37:44.063631
8183	file-manager	healthy	19.571	\N	http://file-manager:8004/health	200	2025-10-08 20:37:44.063632
8184	notification	healthy	23.362000000000002	\N	http://notification:8005/health	200	2025-10-08 20:37:44.063632
8185	api-gateway	unhealthy	23.142	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:38:15.101437
8186	user-service	healthy	21.29	\N	http://user-service:8001/health	200	2025-10-08 20:38:15.101439
8187	service-registry	healthy	21.121000000000002	\N	http://service-registry:8002/health	200	2025-10-08 20:38:15.10144
8188	job-processor	healthy	21.008	\N	http://job-processor:8003/health	200	2025-10-08 20:38:15.10144
8189	file-manager	healthy	20.327	\N	http://file-manager:8004/health	200	2025-10-08 20:38:15.101441
8190	notification	healthy	21.524	\N	http://notification:8005/health	200	2025-10-08 20:38:15.101442
8191	api-gateway	unhealthy	17.742	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:38:46.153291
8192	user-service	healthy	28.687	\N	http://user-service:8001/health	200	2025-10-08 20:38:46.153294
8193	service-registry	healthy	28.054	\N	http://service-registry:8002/health	200	2025-10-08 20:38:46.153294
8194	job-processor	healthy	31.014	\N	http://job-processor:8003/health	200	2025-10-08 20:38:46.153295
8195	file-manager	healthy	30.875	\N	http://file-manager:8004/health	200	2025-10-08 20:38:46.153296
8196	notification	healthy	30.802	\N	http://notification:8005/health	200	2025-10-08 20:38:46.153296
8197	api-gateway	unhealthy	23.824	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:39:17.190251
8198	user-service	healthy	13.994	\N	http://user-service:8001/health	200	2025-10-08 20:39:17.190253
8199	service-registry	healthy	12.573	\N	http://service-registry:8002/health	200	2025-10-08 20:39:17.190254
8200	job-processor	healthy	13.899999999999999	\N	http://job-processor:8003/health	200	2025-10-08 20:39:17.190254
8201	file-manager	healthy	21.238	\N	http://file-manager:8004/health	200	2025-10-08 20:39:17.190255
8202	notification	healthy	20.622999999999998	\N	http://notification:8005/health	200	2025-10-08 20:39:17.190256
8203	api-gateway	unhealthy	22.515	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:39:48.238621
8204	user-service	healthy	19.528	\N	http://user-service:8001/health	200	2025-10-08 20:39:48.238626
8205	service-registry	healthy	19.364	\N	http://service-registry:8002/health	200	2025-10-08 20:39:48.238626
8206	job-processor	healthy	33.031	\N	http://job-processor:8003/health	200	2025-10-08 20:39:48.238627
8207	file-manager	healthy	20.16	\N	http://file-manager:8004/health	200	2025-10-08 20:39:48.238628
8208	notification	healthy	32.336999999999996	\N	http://notification:8005/health	200	2025-10-08 20:39:48.238628
8209	api-gateway	unhealthy	42.189	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:40:19.304565
8210	user-service	healthy	8.86	\N	http://user-service:8001/health	200	2025-10-08 20:40:19.304568
8211	service-registry	healthy	9.59	\N	http://service-registry:8002/health	200	2025-10-08 20:40:19.304569
8212	job-processor	healthy	40.08	\N	http://job-processor:8003/health	200	2025-10-08 20:40:19.304569
8213	file-manager	healthy	13.4	\N	http://file-manager:8004/health	200	2025-10-08 20:40:19.30457
8214	notification	healthy	35.448	\N	http://notification:8005/health	200	2025-10-08 20:40:19.30457
8215	api-gateway	unhealthy	34.261	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:40:50.357607
8216	user-service	healthy	14.8	\N	http://user-service:8001/health	200	2025-10-08 20:40:50.35761
8217	service-registry	healthy	14.338	\N	http://service-registry:8002/health	200	2025-10-08 20:40:50.357611
8218	job-processor	healthy	17.049000000000003	\N	http://job-processor:8003/health	200	2025-10-08 20:40:50.357611
8219	file-manager	healthy	16.427	\N	http://file-manager:8004/health	200	2025-10-08 20:40:50.357612
8220	notification	healthy	16.355	\N	http://notification:8005/health	200	2025-10-08 20:40:50.357612
8221	api-gateway	unhealthy	37.795	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:41:21.412989
8222	user-service	healthy	36.373000000000005	\N	http://user-service:8001/health	200	2025-10-08 20:41:21.412991
8223	service-registry	healthy	27.358	\N	http://service-registry:8002/health	200	2025-10-08 20:41:21.412992
8224	job-processor	healthy	35.95099999999999	\N	http://job-processor:8003/health	200	2025-10-08 20:41:21.412992
8225	file-manager	healthy	35.371	\N	http://file-manager:8004/health	200	2025-10-08 20:41:21.412993
8226	notification	healthy	35.607	\N	http://notification:8005/health	200	2025-10-08 20:41:21.412994
8227	api-gateway	unhealthy	21.322	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:41:52.449348
8228	user-service	healthy	13.207	\N	http://user-service:8001/health	200	2025-10-08 20:41:52.449351
8229	service-registry	healthy	19.493	\N	http://service-registry:8002/health	200	2025-10-08 20:41:52.449351
8230	job-processor	healthy	20.26	\N	http://job-processor:8003/health	200	2025-10-08 20:41:52.449352
8231	file-manager	healthy	23.084	\N	http://file-manager:8004/health	200	2025-10-08 20:41:52.449353
8232	notification	healthy	20.577	\N	http://notification:8005/health	200	2025-10-08 20:41:52.449353
8233	api-gateway	unhealthy	33.798	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:42:23.500156
8234	user-service	healthy	25.186	\N	http://user-service:8001/health	200	2025-10-08 20:42:23.500159
8235	service-registry	healthy	33.271	\N	http://service-registry:8002/health	200	2025-10-08 20:42:23.50016
8236	job-processor	healthy	24.759	\N	http://job-processor:8003/health	200	2025-10-08 20:42:23.50016
8237	file-manager	healthy	32.564	\N	http://file-manager:8004/health	200	2025-10-08 20:42:23.500161
8238	notification	healthy	32.668	\N	http://notification:8005/health	200	2025-10-08 20:42:23.500161
8239	api-gateway	unhealthy	34.441	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:42:54.561567
8240	user-service	healthy	31.986	\N	http://user-service:8001/health	200	2025-10-08 20:42:54.561569
8241	service-registry	healthy	29.270999999999997	\N	http://service-registry:8002/health	200	2025-10-08 20:42:54.56157
8242	job-processor	healthy	31.468000000000004	\N	http://job-processor:8003/health	200	2025-10-08 20:42:54.561571
8243	file-manager	healthy	35.198	\N	http://file-manager:8004/health	200	2025-10-08 20:42:54.561571
8244	notification	healthy	34.751999999999995	\N	http://notification:8005/health	200	2025-10-08 20:42:54.561572
8245	api-gateway	unhealthy	22.534	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:43:25.606492
8246	user-service	healthy	17.439	\N	http://user-service:8001/health	200	2025-10-08 20:43:25.606495
8247	service-registry	healthy	17.274	\N	http://service-registry:8002/health	200	2025-10-08 20:43:25.606496
8248	job-processor	healthy	18.433	\N	http://job-processor:8003/health	200	2025-10-08 20:43:25.606496
8249	file-manager	healthy	15.908999999999999	\N	http://file-manager:8004/health	200	2025-10-08 20:43:25.606497
8250	notification	healthy	17.184	\N	http://notification:8005/health	200	2025-10-08 20:43:25.606497
8251	api-gateway	unhealthy	17.002	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:43:56.650382
8252	user-service	healthy	23.915	\N	http://user-service:8001/health	200	2025-10-08 20:43:56.650385
8253	service-registry	healthy	23.407	\N	http://service-registry:8002/health	200	2025-10-08 20:43:56.650385
8254	job-processor	healthy	23.446	\N	http://job-processor:8003/health	200	2025-10-08 20:43:56.650386
8255	file-manager	healthy	26.113	\N	http://file-manager:8004/health	200	2025-10-08 20:43:56.650387
8256	notification	healthy	25.998	\N	http://notification:8005/health	200	2025-10-08 20:43:56.650387
8257	api-gateway	unhealthy	28.547	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:44:27.702631
8258	user-service	healthy	26.407	\N	http://user-service:8001/health	200	2025-10-08 20:44:27.702635
8259	service-registry	healthy	25.225	\N	http://service-registry:8002/health	200	2025-10-08 20:44:27.702636
8260	job-processor	healthy	27.012999999999998	\N	http://job-processor:8003/health	200	2025-10-08 20:44:27.702637
8261	file-manager	healthy	30.308999999999997	\N	http://file-manager:8004/health	200	2025-10-08 20:44:27.702637
8262	notification	healthy	30.200999999999997	\N	http://notification:8005/health	200	2025-10-08 20:44:27.702638
8263	api-gateway	unhealthy	31.389	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:44:58.761649
8264	user-service	healthy	16.119	\N	http://user-service:8001/health	200	2025-10-08 20:44:58.761652
8265	service-registry	healthy	9.971	\N	http://service-registry:8002/health	200	2025-10-08 20:44:58.761652
8266	job-processor	healthy	13.431999999999999	\N	http://job-processor:8003/health	200	2025-10-08 20:44:58.761653
8267	file-manager	healthy	23.609	\N	http://file-manager:8004/health	200	2025-10-08 20:44:58.761653
8268	notification	healthy	23.535	\N	http://notification:8005/health	200	2025-10-08 20:44:58.761654
8269	api-gateway	unhealthy	17.315	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:45:29.799699
8270	user-service	healthy	18.445	\N	http://user-service:8001/health	200	2025-10-08 20:45:29.799702
8271	service-registry	healthy	16.937	\N	http://service-registry:8002/health	200	2025-10-08 20:45:29.799703
8272	job-processor	healthy	17.978	\N	http://job-processor:8003/health	200	2025-10-08 20:45:29.799703
8273	file-manager	healthy	18.526	\N	http://file-manager:8004/health	200	2025-10-08 20:45:29.799704
8274	notification	healthy	18.095	\N	http://notification:8005/health	200	2025-10-08 20:45:29.799705
8275	api-gateway	unhealthy	23.857	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:46:00.837856
8276	user-service	healthy	9.632	\N	http://user-service:8001/health	200	2025-10-08 20:46:00.837859
8277	service-registry	healthy	10.382000000000001	\N	http://service-registry:8002/health	200	2025-10-08 20:46:00.83786
8278	job-processor	healthy	17.23	\N	http://job-processor:8003/health	200	2025-10-08 20:46:00.83786
8279	file-manager	healthy	17.726	\N	http://file-manager:8004/health	200	2025-10-08 20:46:00.837861
8280	notification	healthy	18.183999999999997	\N	http://notification:8005/health	200	2025-10-08 20:46:00.837861
8281	api-gateway	unhealthy	25.144	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:46:31.87817
8282	user-service	healthy	17.187	\N	http://user-service:8001/health	200	2025-10-08 20:46:31.878172
8283	service-registry	healthy	15.472	\N	http://service-registry:8002/health	200	2025-10-08 20:46:31.878173
8284	job-processor	healthy	16.437	\N	http://job-processor:8003/health	200	2025-10-08 20:46:31.878174
8285	file-manager	healthy	17.505	\N	http://file-manager:8004/health	200	2025-10-08 20:46:31.878174
8286	notification	healthy	17.455	\N	http://notification:8005/health	200	2025-10-08 20:46:31.878175
8287	api-gateway	unhealthy	41.289	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:47:02.938042
8288	user-service	healthy	39.062	\N	http://user-service:8001/health	200	2025-10-08 20:47:02.938045
8289	service-registry	healthy	39.870000000000005	\N	http://service-registry:8002/health	200	2025-10-08 20:47:02.938045
8290	job-processor	healthy	37.957	\N	http://job-processor:8003/health	200	2025-10-08 20:47:02.938046
8291	file-manager	healthy	37.182	\N	http://file-manager:8004/health	200	2025-10-08 20:47:02.938047
8292	notification	healthy	37.061	\N	http://notification:8005/health	200	2025-10-08 20:47:02.938047
8293	api-gateway	unhealthy	22.714000000000002	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:47:33.974802
8294	user-service	healthy	18.519000000000002	\N	http://user-service:8001/health	200	2025-10-08 20:47:33.974805
8295	service-registry	healthy	18.048000000000002	\N	http://service-registry:8002/health	200	2025-10-08 20:47:33.974806
8296	job-processor	healthy	20.884	\N	http://job-processor:8003/health	200	2025-10-08 20:47:33.974806
8297	file-manager	healthy	20.43	\N	http://file-manager:8004/health	200	2025-10-08 20:47:33.974807
8298	notification	healthy	19.897000000000002	\N	http://notification:8005/health	200	2025-10-08 20:47:33.974807
8299	api-gateway	unhealthy	48.671	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:48:05.039514
8300	user-service	healthy	46.483999999999995	\N	http://user-service:8001/health	200	2025-10-08 20:48:05.039517
8301	service-registry	healthy	46.36	\N	http://service-registry:8002/health	200	2025-10-08 20:48:05.039518
8302	job-processor	healthy	46.260999999999996	\N	http://job-processor:8003/health	200	2025-10-08 20:48:05.039519
8303	file-manager	healthy	39.735	\N	http://file-manager:8004/health	200	2025-10-08 20:48:05.039519
8304	notification	healthy	47.387	\N	http://notification:8005/health	200	2025-10-08 20:48:05.03952
8305	api-gateway	unhealthy	37.826	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:48:36.102699
8306	user-service	healthy	18.003999999999998	\N	http://user-service:8001/health	200	2025-10-08 20:48:36.102702
8307	service-registry	healthy	35.504	\N	http://service-registry:8002/health	200	2025-10-08 20:48:36.102703
8308	job-processor	healthy	32.315000000000005	\N	http://job-processor:8003/health	200	2025-10-08 20:48:36.102704
8309	file-manager	healthy	34.796	\N	http://file-manager:8004/health	200	2025-10-08 20:48:36.102704
8310	notification	healthy	31.986	\N	http://notification:8005/health	200	2025-10-08 20:48:36.102705
8311	api-gateway	unhealthy	34.832	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:49:07.149725
8312	user-service	healthy	17.585	\N	http://user-service:8001/health	200	2025-10-08 20:49:07.149728
8313	service-registry	healthy	17.117	\N	http://service-registry:8002/health	200	2025-10-08 20:49:07.149728
8314	job-processor	healthy	17.159	\N	http://job-processor:8003/health	200	2025-10-08 20:49:07.149729
8315	file-manager	healthy	19.782999999999998	\N	http://file-manager:8004/health	200	2025-10-08 20:49:07.14973
8316	notification	healthy	19.339	\N	http://notification:8005/health	200	2025-10-08 20:49:07.149731
8317	api-gateway	unhealthy	29.365	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:49:38.198441
8318	user-service	healthy	22.319	\N	http://user-service:8001/health	200	2025-10-08 20:49:38.198444
8319	service-registry	healthy	16.997999999999998	\N	http://service-registry:8002/health	200	2025-10-08 20:49:38.198445
8320	job-processor	unhealthy	13.457	All connection attempts failed	http://job-processor:8003/health	\N	2025-10-08 20:49:38.198446
8321	file-manager	healthy	24.323	\N	http://file-manager:8004/health	200	2025-10-08 20:49:38.198446
8322	notification	healthy	27.150000000000002	\N	http://notification:8005/health	200	2025-10-08 20:49:38.198447
8323	api-gateway	unhealthy	40.131	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:50:09.252388
8324	user-service	healthy	17.508	\N	http://user-service:8001/health	200	2025-10-08 20:50:09.252391
8325	service-registry	healthy	23.648	\N	http://service-registry:8002/health	200	2025-10-08 20:50:09.252392
8326	job-processor	healthy	19.699	\N	http://job-processor:8003/health	200	2025-10-08 20:50:09.252393
8327	file-manager	healthy	21.295	\N	http://file-manager:8004/health	200	2025-10-08 20:50:09.252393
8328	notification	healthy	21.965	\N	http://notification:8005/health	200	2025-10-08 20:50:09.252394
8329	api-gateway	unhealthy	38.731	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:50:40.313096
8330	user-service	healthy	11.627	\N	http://user-service:8001/health	200	2025-10-08 20:50:40.313098
8331	service-registry	healthy	11.333	\N	http://service-registry:8002/health	200	2025-10-08 20:50:40.313099
8332	job-processor	healthy	16.016	\N	http://job-processor:8003/health	200	2025-10-08 20:50:40.3131
8333	file-manager	healthy	22.793	\N	http://file-manager:8004/health	200	2025-10-08 20:50:40.313101
8334	notification	healthy	22.738	\N	http://notification:8005/health	200	2025-10-08 20:50:40.313101
8335	api-gateway	unhealthy	27.029999999999998	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:51:11.360912
8336	user-service	healthy	27.473000000000003	\N	http://user-service:8001/health	200	2025-10-08 20:51:11.360915
8337	service-registry	healthy	27.262999999999998	\N	http://service-registry:8002/health	200	2025-10-08 20:51:11.360916
8338	job-processor	healthy	28.16	\N	http://job-processor:8003/health	200	2025-10-08 20:51:11.360917
8339	file-manager	healthy	32.638	\N	http://file-manager:8004/health	200	2025-10-08 20:51:11.360918
8340	notification	healthy	27.820999999999998	\N	http://notification:8005/health	200	2025-10-08 20:51:11.360918
8341	api-gateway	unhealthy	34.967999999999996	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:51:42.41696
8342	user-service	healthy	32.353	\N	http://user-service:8001/health	200	2025-10-08 20:51:42.416962
8343	service-registry	healthy	32.288	\N	http://service-registry:8002/health	200	2025-10-08 20:51:42.416963
8344	job-processor	healthy	32.196000000000005	\N	http://job-processor:8003/health	200	2025-10-08 20:51:42.416964
8345	file-manager	healthy	32.416	\N	http://file-manager:8004/health	200	2025-10-08 20:51:42.416964
8346	notification	healthy	31.130000000000003	\N	http://notification:8005/health	200	2025-10-08 20:51:42.416965
8347	api-gateway	unhealthy	40.419	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:52:13.474548
8348	user-service	healthy	25.654	\N	http://user-service:8001/health	200	2025-10-08 20:52:13.474551
8349	service-registry	healthy	30.551	\N	http://service-registry:8002/health	200	2025-10-08 20:52:13.474552
8350	job-processor	healthy	30.442	\N	http://job-processor:8003/health	200	2025-10-08 20:52:13.474552
8351	file-manager	healthy	37.622	\N	http://file-manager:8004/health	200	2025-10-08 20:52:13.474553
8352	notification	healthy	31.532999999999998	\N	http://notification:8005/health	200	2025-10-08 20:52:13.474553
8353	api-gateway	unhealthy	14.061	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:52:44.506471
8354	user-service	healthy	13.341000000000001	\N	http://user-service:8001/health	200	2025-10-08 20:52:44.506473
8355	service-registry	healthy	11.617	\N	http://service-registry:8002/health	200	2025-10-08 20:52:44.506474
8356	job-processor	healthy	12.923	\N	http://job-processor:8003/health	200	2025-10-08 20:52:44.506475
8357	file-manager	healthy	14.243	\N	http://file-manager:8004/health	200	2025-10-08 20:52:44.506475
8358	notification	healthy	13.742	\N	http://notification:8005/health	200	2025-10-08 20:52:44.506476
8359	api-gateway	unhealthy	37.076	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:53:15.558346
8360	user-service	healthy	8.808	\N	http://user-service:8001/health	200	2025-10-08 20:53:15.558348
8361	service-registry	healthy	9.75	\N	http://service-registry:8002/health	200	2025-10-08 20:53:15.558349
8362	job-processor	unhealthy	34.677	[Errno -3] Temporary failure in name resolution	http://job-processor:8003/health	\N	2025-10-08 20:53:15.55835
8363	file-manager	healthy	26.645	\N	http://file-manager:8004/health	200	2025-10-08 20:53:15.558351
8364	notification	healthy	26.583	\N	http://notification:8005/health	200	2025-10-08 20:53:15.558351
8365	api-gateway	unhealthy	25.868	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:53:46.603585
8366	user-service	healthy	14	\N	http://user-service:8001/health	200	2025-10-08 20:53:46.603588
8367	service-registry	healthy	23.583	\N	http://service-registry:8002/health	200	2025-10-08 20:53:46.603589
8368	job-processor	healthy	23.174	\N	http://job-processor:8003/health	200	2025-10-08 20:53:46.603589
8369	file-manager	healthy	26.131999999999998	\N	http://file-manager:8004/health	200	2025-10-08 20:53:46.60359
8370	notification	healthy	23.970000000000002	\N	http://notification:8005/health	200	2025-10-08 20:53:46.603591
8371	api-gateway	unhealthy	23.145	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:54:17.640648
8372	user-service	healthy	11.821	\N	http://user-service:8001/health	200	2025-10-08 20:54:17.640651
8373	service-registry	healthy	15.12	\N	http://service-registry:8002/health	200	2025-10-08 20:54:17.640652
8374	job-processor	healthy	21.43	\N	http://job-processor:8003/health	200	2025-10-08 20:54:17.640652
8375	file-manager	healthy	22.425	\N	http://file-manager:8004/health	200	2025-10-08 20:54:17.640653
8376	notification	healthy	21.090999999999998	\N	http://notification:8005/health	200	2025-10-08 20:54:17.640653
8377	api-gateway	unhealthy	35.827999999999996	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:54:48.695251
8378	user-service	healthy	33.859	\N	http://user-service:8001/health	200	2025-10-08 20:54:48.695254
8379	service-registry	healthy	33.715	\N	http://service-registry:8002/health	200	2025-10-08 20:54:48.695254
8380	job-processor	healthy	33.597	\N	http://job-processor:8003/health	200	2025-10-08 20:54:48.695255
8381	file-manager	healthy	33.493	\N	http://file-manager:8004/health	200	2025-10-08 20:54:48.695256
8382	notification	healthy	34.498	\N	http://notification:8005/health	200	2025-10-08 20:54:48.695256
8383	api-gateway	unhealthy	35.257	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:55:19.744111
8384	user-service	healthy	17.576	\N	http://user-service:8001/health	200	2025-10-08 20:55:19.744114
8385	service-registry	healthy	17.388	\N	http://service-registry:8002/health	200	2025-10-08 20:55:19.744115
8386	job-processor	healthy	19.454	\N	http://job-processor:8003/health	200	2025-10-08 20:55:19.744115
8387	file-manager	healthy	17.034	\N	http://file-manager:8004/health	200	2025-10-08 20:55:19.744116
8388	notification	healthy	19.142	\N	http://notification:8005/health	200	2025-10-08 20:55:19.744117
8389	api-gateway	unhealthy	27.686	[Errno -3] Temporary failure in name resolution	http://api-gateway:8000/health	\N	2025-10-08 20:55:50.790806
8390	user-service	healthy	22.163999999999998	\N	http://user-service:8001/health	200	2025-10-08 20:55:50.79081
8391	service-registry	healthy	19.729	\N	http://service-registry:8002/health	200	2025-10-08 20:55:50.790811
8392	job-processor	healthy	22.231	\N	http://job-processor:8003/health	200	2025-10-08 20:55:50.790811
8393	file-manager	healthy	24.747999999999998	\N	http://file-manager:8004/health	200	2025-10-08 20:55:50.790812
8394	notification	healthy	24.695	\N	http://notification:8005/health	200	2025-10-08 20:55:50.790812
\.


--
-- Data for Name: system_metrics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.system_metrics (id, cpu_usage_percent, cpu_count, load_average_1m, load_average_5m, load_average_15m, memory_total_gb, memory_used_gb, memory_available_gb, memory_usage_percent, disk_total_gb, disk_used_gb, disk_free_gb, disk_usage_percent, network_bytes_sent, network_bytes_recv, network_packets_sent, network_packets_recv, collected_at) FROM stdin;
1	9	2	1.388671875	0.72119140625	0.5703125	7.751792907714844	4.012725830078125	3.3604164123535156	56.6	96.73210144042969	57.46638488769531	39.250091552734375	59.40777056630441	11190	9569	99	100	2025-10-08 17:02:49.771269
2	8.1	2	0.90576171875	0.67236328125	0.55810546875	7.751792907714844	4.069244384765625	3.3036727905273438	57.4	96.73210144042969	57.464664459228516	39.25181198120117	59.405992016638706	22366	19038	191	198	2025-10-08 17:03:21.174962
3	3	2	1.08154296875	0.73681640625	0.58251953125	7.751792907714844	4.086467742919922	3.2864532470703125	57.6	96.73210144042969	57.4660758972168	39.25040054321289	59.407451137207026	31873	27144	284	288	2025-10-08 17:03:52.531496
4	3	2	0.79052734375	0.697265625	0.5732421875	7.751792907714844	4.121086120605469	3.2517967224121094	58.1	96.73210144042969	57.46800231933594	39.24847412109375	59.409442639604315	43848	37976	401	399	2025-10-08 17:04:23.865375
5	2	2	1.865234375	0.95654296875	0.6630859375	7.751792907714844	3.9567031860351562	3.4161834716796875	55.9	96.73210144042969	57.454063415527344	39.262413024902344	59.39503283809992	53212	45892	491	485	2025-10-08 17:04:55.256062
6	73.5	2	1.9970703125	1.07275390625	0.7119140625	7.751792907714844	3.974864959716797	3.398021697998047	56.2	96.73210144042969	57.454132080078125	39.26234436035156	59.395103822343785	62597	53920	582	573	2025-10-08 17:05:26.768379
7	31.7	2	1.34521484375	1.0009765625	0.7001953125	7.751792907714844	3.9782676696777344	3.3946189880371094	56.2	96.73210144042969	57.454200744628906	39.26227569580078	59.39517480658766	72003	61878	673	660	2025-10-08 17:05:58.101549
8	2	2	0.86669921875	0.9189453125	0.6826171875	7.751792907714844	3.965801239013672	3.4070816040039062	56	96.73210144042969	57.45423126220703	39.262245178222656	59.39520635514049	81430	69878	765	748	2025-10-08 17:06:29.460542
9	0.5	2	0.5927734375	0.84765625	0.6669921875	7.751792907714844	3.9770126342773438	3.3958740234375	56.2	96.73210144042969	57.45425796508789	39.2622184753418	59.3952339601242	90795	77794	855	834	2025-10-08 17:07:00.802725
10	3.5	2	0.42041015625	0.78173828125	0.6494140625	7.751792907714844	3.9821128845214844	3.390766143798828	56.3	96.73210144042969	57.45427703857422	39.26219940185547	59.39525367796973	99985	85612	941	917	2025-10-08 17:07:32.127931
11	2.5	2	0.39599609375	0.73876953125	0.6376953125	7.751792907714844	3.9726295471191406	3.400257110595703	56.1	96.73210144042969	57.45429229736328	39.262184143066406	59.39526945224613	109140	93319	1026	998	2025-10-08 17:08:03.478919
12	18	2	0.31982421875	0.68359375	0.62255859375	7.751792907714844	3.9669876098632812	3.4058990478515625	56.1	96.73210144042969	57.454322814941406	39.26215362548828	59.39530100079897	118329	101068	1112	1080	2025-10-08 17:08:34.835353
13	53.5	2	0.25732421875	0.62353515625	0.6044921875	7.751792907714844	3.9902076721191406	3.3826560974121094	56.4	96.73210144042969	57.454349517822266	39.26212692260742	59.395328605782694	127490	108775	1197	1161	2025-10-08 17:09:06.165026
14	0.5	2	0.22314453125	0.57861328125	0.58984375	7.751792907714844	3.975635528564453	3.397228240966797	56.2	96.73210144042969	57.45436477661133	39.26211166381836	59.3953443800591	136684	116524	1283	1243	2025-10-08 17:09:37.505848
15	1	2	0.2978515625	0.56884765625	0.58642578125	7.751792907714844	3.981609344482422	3.3912429809570312	56.3	96.73210144042969	57.454383850097656	39.26209259033203	59.395364097904626	145863	124231	1368	1324	2025-10-08 17:10:08.838372
16	0.5	2	0.578125	0.6103515625	0.599609375	7.751792907714844	3.979644775390625	3.393218994140625	56.2	96.73210144042969	57.454410552978516	39.26206588745117	59.39539170288835	155067	131980	1454	1406	2025-10-08 17:10:40.168039
17	9	2	0.556640625	0.60546875	0.5986328125	7.751792907714844	3.9813461303710938	3.3915176391601562	56.2	96.73210144042969	57.45442581176758	39.26205062866211	59.39540747716477	164208	139687	1539	1487	2025-10-08 17:11:11.495454
18	1	2	0.6259765625	0.6123046875	0.6005859375	7.751792907714844	3.9859275817871094	3.3869285583496094	56.3	96.73210144042969	57.45444107055664	39.26203536987305	59.39542325144118	173394	147442	1625	1569	2025-10-08 17:11:42.849535
19	52.5	2	0.533203125	0.58642578125	0.591796875	7.751792907714844	3.989604949951172	3.383258819580078	56.4	96.73210144042969	57.4544563293457	39.262020111083984	59.395439025717586	182565	155161	1710	1650	2025-10-08 17:12:14.215108
20	53	2	0.57080078125	0.59375	0.59423828125	7.751792907714844	3.9962234497070312	3.376636505126953	56.4	96.73210144042969	57.454471588134766	39.26200485229492	59.395454799994006	192016	163244	1802	1739	2025-10-08 17:12:45.556434
21	19.3	2	0.5478515625	0.58984375	0.59326171875	7.751792907714844	3.986236572265625	3.3866233825683594	56.3	96.73210144042969	57.45448303222656	39.261993408203125	59.39546663070132	201512	171528	1894	1828	2025-10-08 17:13:16.884023
22	2	2	0.45654296875	0.56494140625	0.58447265625	7.751792907714844	3.961772918701172	3.411090850830078	56	96.73210144042969	57.45458221435547	39.26189422607422	59.39556916349801	211306	179739	1988	1919	2025-10-08 17:13:48.542417
23	0.5	2	1.10498046875	0.72998046875	0.638671875	7.751792907714844	3.9487037658691406	3.424152374267578	55.8	96.73210144042969	57.45460510253906	39.261871337890625	59.39559282491263	220693	187710	2079	2006	2025-10-08 17:14:19.869686
24	0.5	2	0.74560546875	0.68115234375	0.6259765625	7.751792907714844	3.9495468139648438	3.4233131408691406	55.8	96.73210144042969	57.454627990722656	39.26184844970703	59.39561648632725	230146	195723	2171	2094	2025-10-08 17:14:51.193357
25	29.4	2	0.5244140625	0.6318359375	0.611328125	7.751792907714844	3.946746826171875	3.4261093139648438	55.8	96.73210144042969	57.45467758178711	39.26179885864258	59.3956677527256	239907	204054	2267	2186	2025-10-08 17:15:22.531419
26	56.9	2	0.39697265625	0.5869140625	0.5966796875	7.751792907714844	3.9811439514160156	3.3917083740234375	56.2	96.73210144042969	57.4547119140625	39.26176452636719	59.39570324484753	249671	212368	2360	2275	2025-10-08 17:15:54.029617
27	12.2	2	0.34521484375	0.560546875	0.58740234375	7.751792907714844	3.973033905029297	3.399822235107422	56.1	96.73210144042969	57.45476531982422	39.26171112060547	59.39575845481498	259083	220339	2451	2362	2025-10-08 17:16:25.359739
990	98	2	3.39990234375	1.318359375	0.8388671875	7.751792907714844	4.195549011230469	3.2181167602539062	58.5	96.73210144042969	57.4643669128418	39.25210952758789	59.405684418248626	8093	9031	84	101	2025-10-08 17:19:59.684426
991	91.9	2	3.54052734375	1.58447265625	0.94677734375	7.751792907714844	5.227210998535156	2.1853370666503906	71.8	96.73210144042969	57.46471405029297	39.25176239013672	59.40604328303706	21420	19272	171	190	2025-10-08 17:20:31.229473
992	74.8	2	3.08056640625	1.669921875	0.998046875	7.751792907714844	5.494342803955078	1.9184341430664062	75.3	96.73210144042969	57.46414566040039	39.2523307800293	59.405455691240626	31666	28205	262	278	2025-10-08 17:21:02.614779
993	1.5	2	2.201171875	1.6025390625	0.99658203125	7.751792907714844	5.604637145996094	1.808013916015625	76.7	96.73210144042969	57.4644889831543	39.25198745727539	59.405810612459945	41112	36315	354	368	2025-10-08 17:21:33.986772
994	21.2	2	1.39013671875	1.46337890625	0.97021484375	7.751792907714844	5.583599090576172	1.8285980224609375	76.4	96.73210144042969	57.46482849121094	39.25164794921875	59.40616159011016	50516	44411	445	457	2025-10-08 17:22:05.346262
995	5	2	0.8310546875	1.3154296875	0.9384765625	7.751792907714844	5.5773773193359375	1.8347091674804688	76.3	96.73210144042969	57.464900970458984	39.2515754699707	59.406236517923126	59726	52185	531	539	2025-10-08 17:22:36.721011
996	8.6	2	0.56005859375	1.2041015625	0.912109375	7.751792907714844	5.553367614746094	1.8586311340332031	76	96.73210144042969	57.46476364135742	39.251712799072266	59.406094549435394	68924	59959	617	621	2025-10-08 17:23:08.040951
997	8.6	2	0.4189453125	1.1044921875	0.88818359375	7.751792907714844	5.562526702880859	1.8494720458984375	76.1	96.73210144042969	57.4648323059082	39.251644134521484	59.406165533679264	78108	67733	703	703	2025-10-08 17:23:39.405272
998	7.5	2	0.38916015625	1.02978515625	0.87060546875	7.751792907714844	5.560863494873047	1.8511085510253906	76.1	96.73210144042969	57.464962005615234	39.25151443481445	59.40629961502878	87293	75507	789	785	2025-10-08 17:24:10.72945
999	7.7	2	0.2841796875	0.9306640625	0.84228515625	7.751792907714844	5.578041076660156	1.8339462280273438	76.3	96.73210144042969	57.4648323059082	39.251644134521484	59.406165533679264	96480	83351	875	868	2025-10-08 17:24:42.081438
1000	12.2	2	0.23388671875	0.8564453125	0.81884765625	7.751792907714844	5.5873870849609375	1.8246002197265625	76.5	96.73210144042969	57.465057373046875	39.25141906738281	59.40639820425637	105678	91125	961	950	2025-10-08 17:25:13.417126
1001	16.6	2	0.20849609375	0.78955078125	0.7978515625	7.751792907714844	5.537635803222656	1.8743515014648438	75.8	96.73210144042969	57.46513748168945	39.251338958740234	59.40648101920755	114868	98900	1047	1032	2025-10-08 17:25:44.780103
1002	16.1	2	0.125	0.712890625	0.771484375	7.751792907714844	5.557018280029297	1.8549461364746094	76.1	96.73210144042969	57.46477508544922	39.25170135498047	59.40610638014271	124045	106675	1133	1114	2025-10-08 17:26:16.1268
1003	29	2	0.697265625	0.77880859375	0.79052734375	7.751792907714844	5.5514678955078125	1.8605003356933594	76	96.73210144042969	57.46501541137695	39.251461029052734	59.406354824996235	133377	114805	1221	1199	2025-10-08 17:26:47.69397
1004	8.5	2	1.00244140625	0.8466796875	0.81396484375	7.751792907714844	5.574424743652344	1.8374176025390625	76.3	96.73210144042969	57.465145111083984	39.2513313293457	59.40648890634576	142909	122778	1309	1284	2025-10-08 17:27:19.335316
1005	4	2	0.9013671875	0.83056640625	0.8095703125	7.751792907714844	5.591037750244141	1.8206291198730469	76.5	96.73210144042969	57.465267181396484	39.2512092590332	59.40661510055707	152385	130805	1401	1372	2025-10-08 17:27:50.668106
1006	2.5	2	0.5546875	0.7529296875	0.78466796875	7.751792907714844	5.596210479736328	1.8154563903808594	76.6	96.73210144042969	57.465179443359375	39.25129699707031	59.40652439846769	161826	138832	1493	1460	2025-10-08 17:28:22.00254
1007	13.6	2	0.72607421875	0.7880859375	0.796875	7.751792907714844	5.5933837890625	1.8182220458984375	76.5	96.73210144042969	57.46542739868164	39.25104904174805	59.40678073045942	171235	146887	1584	1548	2025-10-08 17:28:53.413838
1008	18.7	2	0.51904296875	0.728515625	0.7763671875	7.751792907714844	5.621219635009766	1.7903900146484375	76.9	96.73210144042969	57.46542739868164	39.25104904174805	59.40678073045942	180670	154914	1676	1636	2025-10-08 17:29:24.727246
1009	21.1	2	0.36572265625	0.67333984375	0.755859375	7.751792907714844	5.599971771240234	1.8116340637207031	76.6	96.73210144042969	57.46553421020508	39.25094223022461	59.406891150394316	190027	162857	1766	1722	2025-10-08 17:29:56.112035
1010	51	2	0.6953125	0.724609375	0.76953125	7.751792907714844	5.580112457275391	1.8314933776855469	76.4	96.73210144042969	57.46546936035156	39.251007080078125	59.40682410971956	199860	171286	1864	1816	2025-10-08 17:30:27.462925
1011	74.5	2	0.55615234375	0.6865234375	0.75439453125	7.751792907714844	5.618049621582031	1.7935409545898438	76.9	96.73210144042969	57.4655876159668	39.25088882446289	59.406946360361765	209795	179824	1962	1910	2025-10-08 17:30:58.894856
1012	17.6	2	1.0673828125	0.796875	0.7890625	7.751792907714844	5.60223388671875	1.809356689453125	76.7	96.73210144042969	57.46561813354492	39.250858306884766	59.40697790891459	219261	187851	2054	1998	2025-10-08 17:31:30.285674
1013	9	2	1.26171875	0.8681640625	0.8134765625	7.751792907714844	5.597358703613281	1.8142318725585938	76.6	96.73210144042969	57.46623229980469	39.250244140625	59.40761282354027	228705	195878	2146	2086	2025-10-08 17:32:01.662859
1014	3	2	0.998046875	0.833984375	0.80419921875	7.751792907714844	5.575313568115234	1.8362770080566406	76.3	96.73210144042969	57.46617889404297	39.25029754638672	59.40755761357281	238097	203797	2235	2172	2025-10-08 17:32:33.013469
1015	2.5	2	1.224609375	0.89892578125	0.8271484375	7.751792907714844	5.591587066650391	1.8199996948242188	76.5	96.73210144042969	57.46625518798828	39.250221252441406	59.407636484954885	248394	211980	2343	2261	2025-10-08 17:33:04.333826
1016	5.5	2	1.22705078125	0.9384765625	0.84228515625	7.751792907714844	5.583438873291016	1.8281402587890625	76.4	96.73210144042969	57.466312408447266	39.25016403198242	59.40769563849144	258625	220155	2449	2348	2025-10-08 17:33:35.673868
1017	2	2	0.79736328125	0.865234375	0.8193359375	7.751792907714844	5.613780975341797	1.7977371215820312	76.8	96.73210144042969	57.466243743896484	39.2502326965332	59.407624654247584	269372	229500	2562	2443	2025-10-08 17:34:06.998167
1018	8.6	2	0.7119140625	0.84375	0.81298828125	7.751792907714844	5.620552062988281	1.7909774780273438	76.9	96.73210144042969	57.466304779052734	39.25017166137695	59.40768775135324	278833	237435	2653	2527	2025-10-08 17:34:38.335369
1019	12.6	2	0.6025390625	0.80908203125	0.802734375	7.751792907714844	5.5720977783203125	1.8394317626953125	76.3	96.73210144042969	57.466392517089844	39.250083923339844	59.40777845344262	288238	245444	2744	2614	2025-10-08 17:35:09.680122
1020	7.6	2	0.5419921875	0.7783203125	0.79345703125	7.751792907714844	5.603828430175781	1.8077049255371094	76.7	96.73210144042969	57.46643829345703	39.250038146972656	59.407825776271864	297428	253219	2830	2696	2025-10-08 17:35:40.989294
1021	55.1	2	2.267578125	1.1708984375	0.9248046875	7.751792907714844	6.670509338378906	0.7409629821777344	90.4	96.73210144042969	57.460113525390625	39.25636291503906	59.40128733869816	306774	261162	2920	2782	2025-10-08 17:36:12.50787
1022	99	2	112.84033203125	54.2216796875	21.3720703125	7.751792907714844	5.5982513427734375	1.8478813171386719	76.2	96.73210144042969	57.460174560546875	39.25630187988281	59.40135043580382	319050	271638	3030	2890	2025-10-08 17:39:27.916877
1023	6	2	68.8486328125	49.1376953125	20.72314453125	7.751792907714844	5.603843688964844	1.8424072265625	76.2	96.73210144042969	57.460391998291016	39.25608444213867	59.401575219242716	329512	280508	3120	2976	2025-10-08 17:39:59.624354
1024	3	2	41.8291015625	44.47119140625	20.0732421875	7.751792907714844	5.5751190185546875	1.8712196350097656	75.9	96.73210144042969	57.46012496948242	39.256351470947266	59.401299169405476	338790	288349	3207	3059	2025-10-08 17:40:30.942648
1025	1	2	23.38671875	39.5673828125	19.33447265625	7.751792907714844	5.576618194580078	1.8697052001953125	75.9	96.73210144042969	57.460174560546875	39.25630187988281	59.40135043580382	347972	296124	3293	3141	2025-10-08 17:41:02.257665
1026	2.5	2	14.22509765625	35.80029296875	18.72314453125	7.751792907714844	5.588916778564453	1.8573875427246094	76	96.73210144042969	57.460105895996094	39.256370544433594	59.401279451559965	357174	303899	3379	3223	2025-10-08 17:41:33.580773
1027	1.5	2	8.97607421875	32.45849609375	18.15380859375	7.751792907714844	5.578884124755859	1.8674240112304688	75.9	96.73210144042969	57.46023178100586	39.25624465942383	59.40140958934037	366383	311674	3465	3305	2025-10-08 17:42:04.926393
1028	1.5	2	5.70654296875	29.431640625	17.60205078125	7.751792907714844	5.588783264160156	1.8575172424316406	76	96.73210144042969	57.467933654785156	39.24854278564453	59.40937165536045	375521	319407	3550	3386	2025-10-08 17:42:36.244514
1029	5.5	2	3.24267578125	26.19140625	16.95458984375	7.751792907714844	5.581127166748047	1.8651618957519531	75.9	96.73210144042969	57.46807861328125	39.24839782714844	59.40952151098639	384668	327140	3635	3467	2025-10-08 17:43:07.567675
1030	1	2	1.96435546875	23.6875	16.4140625	7.751792907714844	5.589881896972656	1.8563919067382812	76.1	96.73210144042969	57.4680061340332	39.248470306396484	59.40944658317342	393816	334873	3720	3548	2025-10-08 17:43:38.881628
1031	16	2	1.54345703125	21.51611328125	15.921875	7.751792907714844	5.577655792236328	1.8685760498046875	75.9	96.73210144042969	57.46813201904297	39.24834442138672	59.40957672095384	402956	342606	3805	3629	2025-10-08 17:44:10.18951
1032	52.5	2	1.087890625	19.4912109375	15.42431640625	7.751792907714844	3.0541954040527344	4.3922882080078125	43.3	96.73210144042969	57.46788787841797	39.24858856201172	59.40932433253121	412114	350339	3890	3710	2025-10-08 17:44:41.699237
1033	53.8	2	1.99658203125	17.68212890625	14.96826171875	7.751792907714844	3.936107635498047	3.510356903076172	54.7	96.73210144042969	57.46799087524414	39.24848556518555	59.409430808897014	421275	358072	3975	3791	2025-10-08 17:45:13.059903
1034	58.1	2	2.12060546875	16.21337890625	14.5654296875	7.751792907714844	4.5687103271484375	2.8777503967285156	62.9	96.73210144042969	57.46806335449219	39.2484130859375	59.409505736709974	430438	365805	4060	3872	2025-10-08 17:45:44.482799
1035	99.5	2	3.67041015625	15.25	14.296875	7.751792907714844	6.251003265380859	1.1947593688964844	84.6	96.73210144042969	57.46841812133789	39.2480583190918	59.40987248863661	439590	373538	4145	3953	2025-10-08 17:46:15.886776
1036	2.5	2	4.095703125	14.26416015625	13.99951171875	7.751792907714844	4.579181671142578	2.864917755126953	63	96.73210144042969	57.46846389770508	39.24801254272461	59.40991981146585	449595	382192	4231	4035	2025-10-08 17:46:47.206649
1037	7.5	2	2.4677734375	12.732421875	13.49560546875	7.751792907714844	3.971851348876953	3.4721755981445312	55.2	96.73210144042969	57.46863555908203	39.247840881347656	59.41009727207551	458755	389925	4316	4116	2025-10-08 17:47:18.535446
1038	5.6	2	1.62060546875	11.54541015625	13.07568359375	7.751792907714844	3.9290504455566406	3.514904022216797	54.7	96.73210144042969	57.46851348876953	39.247962951660156	59.4099710778642	467915	397658	4401	4197	2025-10-08 17:47:49.876323
1039	1	2	0.9814453125	10.4404296875	12.65869140625	7.751792907714844	3.906513214111328	3.53741455078125	54.4	96.73210144042969	57.46849822998047	39.24797821044922	59.40995530358778	477066	405391	4486	4278	2025-10-08 17:48:21.189457
1040	3	2	0.54541015625	9.2841796875	12.1884765625	7.751792907714844	3.901744842529297	3.5421371459960938	54.3	96.73210144042969	57.468360900878906	39.24811553955078	59.40981333510005	486201	413124	4571	4359	2025-10-08 17:48:52.520932
1041	4	2	0.41015625	8.41162109375	11.8046875	7.751792907714844	3.8946189880371094	3.549205780029297	54.2	96.73210144042969	57.46863555908203	39.247840881347656	59.41009727207551	495350	420857	4656	4440	2025-10-08 17:49:23.891475
1042	85	2	0.30029296875	7.6220703125	11.43310546875	7.751792907714844	3.973651885986328	3.469696044921875	55.2	96.73210144042969	57.46860885620117	39.247867584228516	59.41006966709178	504557	428632	4742	4522	2025-10-08 17:49:55.59942
1043	100	2	2.5849609375	7.45556640625	11.25390625	7.751792907714844	6.197906494140625	1.2424659729003906	84	96.73210144042969	57.468902587890625	39.24757385253906	59.41037332191276	514595	437286	4828	4604	2025-10-08 17:50:27.069431
1044	11.6	2	2.05126953125	6.79833984375	10.8935546875	7.751792907714844	5.730907440185547	1.7093772888183594	77.9	96.73210144042969	57.469017028808594	39.247459411621094	59.41049162898586	524610	445940	4914	4686	2025-10-08 17:50:58.392029
1045	72.9	2	3.20556640625	6.60009765625	10.69482421875	7.751792907714844	5.94439697265625	1.4773445129394531	80.9	96.73210144042969	57.469642639160156	39.24683380126953	59.41113837431885	534590	454502	5009	4777	2025-10-08 17:51:30.276102
1046	91.9	2	2.84716796875	6.18994140625	10.42724609375	7.751792907714844	7.036869049072266	0.3898124694824219	95	96.73210144042969	57.469425201416016	39.24705123901367	59.41091359087994	543728	462235	5094	4858	2025-10-08 17:52:01.683338
1047	7.1	2	2.10205078125	5.65576171875	10.09228515625	7.751792907714844	4.996284484863281	2.444488525390625	68.5	96.73210144042969	57.47603225708008	39.24044418334961	59.417743852567305	554655	471825	5181	4941	2025-10-08 17:52:33.087393
1048	3.5	2	1.330078125	5.12890625	9.77490234375	7.751792907714844	5.015758514404297	2.4251251220703125	68.7	96.73210144042969	57.47589111328125	39.24058532714844	59.41759794051047	563805	479558	5266	5022	2025-10-08 17:53:04.457192
1049	1	2	0.8671875	4.6533203125	9.46826171875	7.751792907714844	5.01177978515625	2.4291000366210938	68.7	96.73210144042969	57.47603988647461	39.24043655395508	59.417751739705515	572949	487291	5351	5103	2025-10-08 17:53:35.787865
1050	5.5	2	0.5244140625	4.20751953125	9.16552734375	7.751792907714844	5.042694091796875	2.398162841796875	69.1	96.73210144042969	57.47607421875	39.24040222167969	59.41778723182745	582128	495024	5436	5184	2025-10-08 17:54:07.125615
1051	1.5	2	0.560546875	3.81689453125	8.8515625	7.751792907714844	5.0529022216796875	2.3881874084472656	69.2	96.73210144042969	57.47599411010742	39.240482330322266	59.41770441687627	591284	502757	5521	5265	2025-10-08 17:54:38.454438
1052	2	2	0.49365234375	3.48388671875	8.57958984375	7.751792907714844	5.050662994384766	2.3904495239257812	69.2	96.73210144042969	57.47611999511719	39.2403564453125	59.41783455465669	600440	510490	5606	5346	2025-10-08 17:55:09.802026
1053	2	2	0.50830078125	3.1982421875	8.3212890625	7.751792907714844	5.042659759521484	2.398456573486328	69.1	96.73210144042969	57.47616958618164	39.24030685424805	59.41788582105503	609612	518223	5691	5427	2025-10-08 17:55:41.148926
1054	29.6	2	1.16796875	3.1123046875	8.12939453125	7.751792907714844	5.049308776855469	2.3917922973632812	69.1	96.73210144042969	57.47587203979492	39.240604400634766	59.41757822266496	618921	526381	5778	5512	2025-10-08 17:56:12.473946
1055	3.5	2	1.19873046875	2.8828125	7.86474609375	7.751792907714844	5.037147521972656	2.4039039611816406	69	96.73210144042969	57.47602081298828	39.240455627441406	59.41773202185999	628421	534312	5865	5596	2025-10-08 17:56:44.124846
1056	1.5	2	0.87353515625	2.63818359375	7.62353515625	7.751792907714844	5.045524597167969	2.395526885986328	69.1	96.73210144042969	57.47605514526367	39.240421295166016	59.41776751398192	637578	542045	5950	5677	2025-10-08 17:57:15.446428
1057	3.5	2	0.892578125	2.46630859375	7.40673828125	7.751792907714844	5.034793853759766	2.4062538146972656	69	96.73210144042969	57.47610092163086	39.24037551879883	59.41781483681117	646991	550030	6041	5764	2025-10-08 17:57:46.783904
1058	1	2	0.64453125	2.224609375	7.1416015625	7.751792907714844	5.040863037109375	2.400177001953125	69	96.73210144042969	57.476070404052734	39.24040603637695	59.41778328825834	656173	557805	6126	5846	2025-10-08 17:58:18.116982
1059	4	2	0.38916015625	2.0107421875	6.9130859375	7.751792907714844	5.051841735839844	2.3891944885253906	69.2	96.73210144042969	57.47614669799805	39.24032974243164	59.417862159640414	665565	565790	6217	5933	2025-10-08 17:58:49.452269
1060	1.5	2	0.31591796875	1.833984375	6.69677734375	7.751792907714844	5.0509185791015625	2.3900909423828125	69.2	96.73210144042969	57.47610855102539	39.2403678894043	59.41782272394938	674711	573523	6302	6014	2025-10-08 17:59:20.784996
1061	17	2	0.33251953125	1.689453125	6.4931640625	7.751792907714844	5.046180725097656	2.3948516845703125	69.1	96.73210144042969	57.476173400878906	39.24030303955078	59.417889764624135	684090	581466	6392	6100	2025-10-08 17:59:52.130962
1062	53.5	2	0.890625	1.6767578125	6.30908203125	7.751792907714844	5.067466735839844	2.3416366577148438	69.8	96.73210144042969	57.4985466003418	39.21792984008789	59.44101879741649	693281	589241	6478	6182	2025-10-08 18:00:23.486037
1063	29.3	2	0.5380859375	1.51416015625	6.10693359375	7.751792907714844	5.059520721435547	2.3494606018066406	69.7	96.73210144042969	57.498756408691406	39.21772003173828	59.44123569371719	702622	597184	6568	6268	2025-10-08 18:00:54.816575
1064	11.1	2	0.580078125	1.43212890625	5.9326171875	7.751792907714844	5.0565185546875	2.3525543212890625	69.7	96.73210144042969	57.49853515625	39.21794128417969	59.441006966709175	711826	604959	6654	6350	2025-10-08 18:01:26.146327
1065	1	2	0.4560546875	1.32470703125	5.7529296875	7.751792907714844	5.05126953125	2.3577880859375	69.6	96.73210144042969	57.50648880004883	39.20998764038086	59.4492293082901	721167	612902	6744	6436	2025-10-08 18:01:57.503327
1066	1.5	2	0.4462890625	1.22412109375	5.55419921875	7.751792907714844	5.054786682128906	2.3542556762695312	69.6	96.73210144042969	57.506473541259766	39.21000289916992	59.44921353401368	730401	620719	6831	6519	2025-10-08 18:02:28.825203
1067	1.5	2	0.322265625	1.12109375	5.38134765625	7.751792907714844	5.052459716796875	2.3565750122070312	69.6	96.73210144042969	57.506534576416016	39.20994186401367	59.44927663111933	739867	628746	6923	6607	2025-10-08 18:03:00.147995
1068	28.6	2	0.4453125	1.076171875	5.22998046875	7.751792907714844	5.050830841064453	2.3581695556640625	69.6	96.73210144042969	57.506526947021484	39.2099494934082	59.44926874398113	749653	637133	7020	6700	2025-10-08 18:03:31.468242
1069	3	2	0.2685546875	0.97216796875	5.0625	7.751792907714844	5.052387237548828	2.3566207885742188	69.6	96.73210144042969	57.50658416748047	39.20989227294922	59.449327897517676	759572	645629	7117	6793	2025-10-08 18:04:02.815015
1070	3	2	0.45849609375	0.9423828125	4.8994140625	7.751792907714844	5.059696197509766	2.3492965698242188	69.7	96.73210144042969	57.506587982177734	39.20988845825195	59.44933184108678	768996	653656	7209	6881	2025-10-08 18:04:34.140269
1071	2	2	0.2763671875	0.85107421875	4.7421875	7.751792907714844	5.064899444580078	2.3440780639648438	69.8	96.73210144042969	57.506649017333984	39.2098274230957	59.44939493819245	778396	661641	7300	6968	2025-10-08 18:05:05.475241
1072	8.5	2	0.4404296875	0.84619140625	4.61572265625	7.751792907714844	5.053615570068359	2.3553390502929688	69.6	96.73210144042969	57.50666809082031	39.209808349609375	59.44941465603796	787792	669626	7391	7055	2025-10-08 18:05:36.844726
1073	11.9	2	0.26513671875	0.76416015625	4.4677734375	7.751792907714844	5.065731048583984	2.3432273864746094	69.8	96.73210144042969	57.50684356689453	39.209632873535156	59.44959606021673	797151	677569	7481	7141	2025-10-08 18:06:08.167889
1074	20.1	2	0.4951171875	0.759765625	4.3271484375	7.751792907714844	5.071941375732422	2.3369979858398438	69.9	96.73210144042969	57.506710052490234	39.20976638793945	59.4494580352981	806576	685554	7572	7228	2025-10-08 18:06:39.495769
1075	1	2	0.37939453125	0.703125	4.193359375	7.751792907714844	5.0774078369140625	2.3315162658691406	69.9	96.73210144042969	57.50678253173828	39.209693908691406	59.44953296311106	815973	693539	7663	7315	2025-10-08 18:07:10.91587
1076	0.5	2	0.296875	0.6513671875	4.06396484375	7.751792907714844	5.080039978027344	2.3288803100585938	70	96.73210144042969	57.506622314453125	39.20985412597656	59.44936733320871	825411	701566	7755	7403	2025-10-08 18:07:42.244712
1077	10.6	2	0.232421875	0.59423828125	3.91748046875	7.751792907714844	5.067413330078125	2.3415184020996094	69.8	96.73210144042969	57.506744384765625	39.20973205566406	59.449493527420024	834626	709383	7842	7486	2025-10-08 18:08:13.56014
1078	1.5	2	0.1396484375	0.5361328125	3.79150390625	7.751792907714844	5.085842132568359	2.323101043701172	70	96.73210144042969	57.506710052490234	39.20976638793945	59.4494580352981	843974	717326	7932	7572	2025-10-08 18:08:44.880826
1079	3.5	2	0.68017578125	0.615234375	3.71240234375	7.751792907714844	5.0689697265625	2.3399658203125	69.8	96.73210144042969	57.50653839111328	39.209938049316406	59.44928057468844	853413	725353	8024	7660	2025-10-08 18:09:16.204936
1080	1	2	0.46435546875	0.57080078125	3.59814453125	7.751792907714844	5.080181121826172	2.328746795654297	70	96.73210144042969	57.50682830810547	39.20964813232422	59.44958028594031	862663	733170	8111	7743	2025-10-08 18:09:47.529499
1081	8.9	2	0.33154296875	0.5224609375	3.46875	7.751792907714844	5.090305328369141	2.3186073303222656	70.1	96.73210144042969	57.50690460205078	39.209571838378906	59.44965915732238	872074	741155	8202	7830	2025-10-08 18:10:18.853928
1082	2	2	0.2001953125	0.47119140625	3.35693359375	7.751792907714844	5.092750549316406	2.3161239624023438	70.1	96.73210144042969	57.50685119628906	39.209625244140625	59.44960394735494	881522	749182	8294	7918	2025-10-08 18:10:50.191594
1083	1.5	2	0.28076171875	0.45849609375	3.259765625	7.751792907714844	5.082798004150391	2.3260955810546875	70	96.73210144042969	57.50691604614258	39.20956039428711	59.44967098802969	890725	756957	8380	8000	2025-10-08 18:11:21.511854
1084	5	2	0.43505859375	0.47802734375	3.17578125	7.751792907714844	5.099761962890625	2.3091201782226562	70.2	96.73210144042969	57.50689697265625	39.20957946777344	59.44965127018417	900151	764984	8472	8088	2025-10-08 18:11:52.912091
1085	61.6	2	0.72216796875	0.52392578125	3.08984375	7.751792907714844	5.092319488525391	2.316558837890625	70.1	96.73210144042969	57.506690979003906	39.20978546142578	59.44943831745258	909325	772759	8558	8170	2025-10-08 18:12:24.281354
1086	83.4	2	0.4365234375	0.47265625	2.990234375	7.751792907714844	5.103328704833984	2.3055267333984375	70.3	96.73210144042969	57.50677490234375	39.20970153808594	59.44952507597285	918724	780744	8649	8257	2025-10-08 18:12:55.61411
1087	1.5	2	0.26318359375	0.42626953125	2.8935546875	7.751792907714844	5.100990295410156	2.3078689575195312	70.2	96.73210144042969	57.50688171386719	39.2095947265625	59.449635495907756	929240	789951	8739	8345	2025-10-08 18:13:27.244508
1088	2.5	2	0.1943359375	0.39306640625	2.7900390625	7.751792907714844	5.104015350341797	2.3048324584960938	70.3	96.73210144042969	57.50700759887695	39.209468841552734	59.44976563368818	938598	797894	8829	8431	2025-10-08 18:13:58.591736
1089	4	2	0.1171875	0.35400390625	2.69970703125	7.751792907714844	5.103515625	2.3053245544433594	70.3	96.73210144042969	57.507057189941406	39.20941925048828	59.449816900086525	947799	805669	8915	8513	2025-10-08 18:14:29.909982
1090	4	2	0.123046875	0.33447265625	2.61767578125	7.751792907714844	5.114757537841797	2.2940750122070312	70.4	96.73210144042969	57.50698471069336	39.20949172973633	59.44974197227355	957036	813486	9002	8596	2025-10-08 18:15:01.231179
1091	2	2	0.30322265625	0.36328125	2.5546875	7.751792907714844	5.115848541259766	2.2929763793945312	70.4	96.73210144042969	57.506736755371094	39.209739685058594	59.44948564028182	966351	821387	9091	8681	2025-10-08 18:15:32.566346
1092	18.7	2	0.16796875	0.3212890625	2.45849609375	7.751792907714844	5.119640350341797	2.289165496826172	70.5	96.73210144042969	57.50687789916992	39.209598541259766	59.44963155233866	975909	829522	9182	8768	2025-10-08 18:16:03.891747
1093	1.5	2	0.158203125	0.3056640625	2.38427734375	7.751792907714844	5.123859405517578	2.284931182861328	70.5	96.73210144042969	57.50694274902344	39.20953369140625	59.44969859301341	985745	837934	9277	8859	2025-10-08 18:16:35.236712
1094	1	2	0.1689453125	0.29150390625	2.3125	7.751792907714844	5.121601104736328	2.2871780395507812	70.5	96.73210144042969	57.50701904296875	39.20945739746094	59.44977746439548	994932	845709	9363	8941	2025-10-08 18:17:06.570813
1095	14.1	2	0.28857421875	0.310546875	2.25341796875	7.751792907714844	5.111003875732422	2.2977447509765625	70.4	96.73210144042969	57.507144927978516	39.20933151245117	59.4499076021759	1004059	853442	9448	9022	2025-10-08 18:17:37.910892
1096	7.5	2	0.2744140625	0.30615234375	2.1787109375	7.751792907714844	5.12164306640625	2.2871170043945312	70.5	96.73210144042969	57.50712966918945	39.209346771240234	59.44989182789949	1013262	861217	9534	9104	2025-10-08 18:18:09.22746
1097	4	2	0.28515625	0.3076171875	2.119140625	7.751792907714844	5.126956939697266	2.2817955017089844	70.6	96.73210144042969	57.507198333740234	39.20927810668945	59.449962812143355	1022461	868992	9620	9186	2025-10-08 18:18:40.568632
1098	4.1	2	0.39990234375	0.3271484375	2.06640625	7.751792907714844	5.130775451660156	2.2779693603515625	70.6	96.73210144042969	57.5072021484375	39.20927429199219	59.44996675571246	1031649	876767	9706	9268	2025-10-08 18:19:11.890432
1099	5.1	2	1.59375	0.60400390625	2.1025390625	7.751792907714844	5.126926422119141	2.2817764282226562	70.6	96.73210144042969	57.50736618041992	39.209110260009766	59.45013632918391	1040847	884542	9792	9350	2025-10-08 18:19:43.229744
1100	2	2	1.1083984375	0.59765625	2.044921875	7.751792907714844	5.137393951416016	2.2713088989257812	70.7	96.73210144042969	57.50739288330078	39.209083557128906	59.450163934167634	1050021	892317	9878	9432	2025-10-08 18:20:14.58828
1101	2.5	2	0.859375	0.58740234375	1.99365234375	7.751792907714844	5.138328552246094	2.2703704833984375	70.7	96.73210144042969	57.50718307495117	39.209293365478516	59.449947037866934	1059219	900092	9964	9514	2025-10-08 18:20:45.911241
1102	5.6	2	0.830078125	0.609375	1.95703125	7.751792907714844	5.140892028808594	2.2677955627441406	70.7	96.73210144042969	57.507232666015625	39.20924377441406	59.449998304265286	1068420	907867	10050	9596	2025-10-08 18:21:17.254163
1103	2.5	2	0.69140625	0.59912109375	1.90869140625	7.751792907714844	5.152595520019531	2.256103515625	70.9	96.73210144042969	57.507232666015625	39.20924377441406	59.449998304265286	1077617	915642	10136	9678	2025-10-08 18:21:48.58826
1104	27.6	2	0.69384765625	0.611328125	1.86376953125	7.751792907714844	5.1302490234375	2.2783355712890625	70.6	96.73210144042969	57.507720947265625	39.20875549316406	59.45050308111054	1086805	923417	10222	9760	2025-10-08 18:22:19.94816
1105	23.5	2	0.6484375	0.60205078125	1.8193359375	7.751792907714844	5.1753082275390625	2.233245849609375	71.2	96.73210144042969	57.507568359375	39.20890808105469	59.4503453383464	1095953	931150	10307	9841	2025-10-08 18:22:51.282055
1106	5.6	2	0.53515625	0.576171875	1.77099609375	7.751792907714844	5.230720520019531	2.1778182983398438	71.9	96.73210144042969	57.5077018737793	39.20877456665039	59.45048336326503	1105349	939135	10398	9928	2025-10-08 18:23:22.718169
1107	4	2	0.296875	0.51123046875	1.70361328125	7.751792907714844	5.230220794677734	2.1783065795898438	71.9	96.73210144042969	57.5078010559082	39.208675384521484	59.45058589606171	1114757	947120	10489	10015	2025-10-08 18:23:54.050375
1108	67.3	2	0.4541015625	0.52587890625	1.67041015625	7.751792907714844	5.224384307861328	2.1841354370117188	71.8	96.73210144042969	57.50778579711914	39.20869064331055	59.4505701217853	1124155	955105	10580	10102	2025-10-08 18:24:25.392127
1109	53.5	2	0.35498046875	0.49169921875	1.62109375	7.751792907714844	5.233375549316406	2.1751365661621094	71.9	96.73210144042969	57.50750732421875	39.20896911621094	59.450282241240735	1133556	963090	10671	10189	2025-10-08 18:24:56.722493
1110	2	2	0.26708984375	0.458984375	1.57373046875	7.751792907714844	5.2204437255859375	2.1880645751953125	71.8	96.73210144042969	57.507598876953125	39.20887756347656	59.45037688689923	1142983	971075	10762	10276	2025-10-08 18:25:28.044418
1111	2.5	2	0.302734375	0.453125	1.529296875	7.751792907714844	5.210655212402344	2.1978492736816406	71.6	96.73210144042969	57.507625579833984	39.2088508605957	59.45040449188295	1152356	979018	10852	10362	2025-10-08 18:25:59.384229
1112	2.6	2	0.1826171875	0.408203125	1.4794921875	7.751792907714844	5.2259368896484375	2.18255615234375	71.8	96.73210144042969	57.50775909423828	39.208717346191406	59.450542516801576	1161763	987003	10943	10449	2025-10-08 18:26:30.717209
1113	2.5	2	0.23486328125	0.39990234375	1.44140625	7.751792907714844	5.222515106201172	2.185962677001953	71.8	96.73210144042969	57.50782012939453	39.208656311035156	59.450605613907236	1171188	994988	11034	10536	2025-10-08 18:27:02.078245
1114	2	2	0.3369140625	0.40869140625	1.4111328125	7.751792907714844	5.2203826904296875	2.188091278076172	71.8	96.73210144042969	57.508148193359375	39.20832824707031	59.45094476085014	1180559	1002931	11124	10622	2025-10-08 18:27:33.43349
1115	4.5	2	0.1865234375	0.3623046875	1.3564453125	7.751792907714844	5.228057861328125	2.1804046630859375	71.9	96.73210144042969	57.50819396972656	39.208282470703125	59.450992083679374	1189764	1010706	11210	10704	2025-10-08 18:28:04.781746
1116	31.3	2	0.69580078125	0.4833984375	1.36474609375	7.751792907714844	5.230129241943359	2.1783103942871094	71.9	96.73210144042969	57.50853729248047	39.20793914794922	59.4513470048987	1199329	1018841	11301	10791	2025-10-08 18:28:36.167252
1117	7.5	2	0.42041015625	0.435546875	1.3203125	7.751792907714844	5.232074737548828	2.176349639892578	71.9	96.73210144042969	57.508331298828125	39.20814514160156	59.451134052167106	1209016	1027085	11392	10878	2025-10-08 18:29:07.579007
1118	22.1	2	0.31640625	0.40869140625	1.28173828125	7.751792907714844	5.240184783935547	2.168224334716797	72	96.73210144042969	57.508419036865234	39.20805740356445	59.451224754256494	1218316	1035173	11479	10962	2025-10-08 18:29:38.929598
1119	2	2	0.32958984375	0.39599609375	1.24365234375	7.751792907714844	5.254608154296875	2.1538009643554688	72.2	96.73210144042969	57.50815963745117	39.208316802978516	59.45095659155745	1227863	1043146	11567	11047	2025-10-08 18:30:10.602339
1120	2.5	2	0.26123046875	0.373046875	1.2080078125	7.751792907714844	5.246490478515625	2.161914825439453	72.1	96.73210144042969	57.508209228515625	39.20826721191406	59.451007857955794	1237071	1050921	11653	11129	2025-10-08 18:30:41.931901
1121	12.1	2	0.15673828125	0.3359375	1.16796875	7.751792907714844	5.263820648193359	2.144573211669922	72.3	96.73210144042969	57.50824737548828	39.208229064941406	59.45104729364683	1246264	1058766	11739	11212	2025-10-08 18:31:13.267984
1122	1	2	0.32666015625	0.3603515625	1.1455078125	7.751792907714844	5.267429351806641	2.140960693359375	72.4	96.73210144042969	57.50843811035156	39.208038330078125	59.451244472102005	1255465	1066541	11825	11294	2025-10-08 18:31:44.631731
1123	6.5	2	0.2646484375	0.3408203125	1.11279296875	7.751792907714844	5.265659332275391	2.1427230834960938	72.4	96.73210144042969	57.50851058959961	39.20796585083008	59.45131939991498	1264604	1074274	11910	11375	2025-10-08 18:32:15.956323
1124	3	2	0.15966796875	0.30712890625	1.07568359375	7.751792907714844	5.266796112060547	2.1415786743164062	72.4	96.73210144042969	57.5086784362793	39.20779800415039	59.45149291695553	1273767	1082007	11995	11456	2025-10-08 18:32:47.300162
1125	1.5	2	0.1689453125	0.29296875	1.0458984375	7.751792907714844	5.274726867675781	2.133636474609375	72.5	96.73210144042969	57.50849914550781	39.207977294921875	59.45130756920767	1283201	1090034	12087	11544	2025-10-08 18:33:18.634844
1126	13.6	2	0.38232421875	0.32470703125	1.02685546875	7.751792907714844	5.280010223388672	2.128345489501953	72.5	96.73210144042969	57.50880432128906	39.207672119140625	59.45162305473595	1292631	1098061	12179	11632	2025-10-08 18:33:50.009745
1127	1.5	2	0.53271484375	0.35888671875	1.013671875	7.751792907714844	5.290309906005859	2.118022918701172	72.7	96.73210144042969	57.508522033691406	39.20795440673828	59.45133123062229	1302066	1106088	12271	11720	2025-10-08 18:34:21.358934
1128	2.5	2	0.32177734375	0.3232421875	0.97998046875	7.751792907714844	5.283229827880859	2.1250953674316406	72.6	96.73210144042969	57.508792877197266	39.20768356323242	59.451611224028646	1311511	1114115	12363	11808	2025-10-08 18:34:52.685635
1129	3	2	0.27490234375	0.30810546875	0.95361328125	7.751792907714844	5.295921325683594	2.1124000549316406	72.7	96.73210144042969	57.50857162475586	39.20790481567383	59.45138249702063	1320940	1122100	12454	11895	2025-10-08 18:35:24.021966
1130	17.7	2	0.38037109375	0.32275390625	0.93310546875	7.751792907714844	5.293903350830078	2.114410400390625	72.7	96.73210144042969	57.50864791870117	39.207828521728516	59.451461368402704	1330379	1130085	12545	11982	2025-10-08 18:35:55.376889
1131	54.5	2	0.3779296875	0.32470703125	0.91259765625	7.751792907714844	5.3455810546875	2.062694549560547	73.4	96.73210144042969	57.50870132446289	39.2077751159668	59.45151657837015	1339816	1138112	12637	12070	2025-10-08 18:36:26.913658
1132	41.9	2	0.67236328125	0.39111328125	0.91552734375	7.751792907714844	5.320049285888672	2.0881423950195312	73.1	96.73210144042969	57.50896453857422	39.20751190185547	59.451788684638295	1349216	1146097	12728	12157	2025-10-08 18:36:58.268204
1133	6.5	2	0.59228515625	0.400390625	0.9013671875	7.751792907714844	5.315967559814453	2.0921592712402344	73	96.73210144042969	57.50882339477539	39.2076530456543	59.45164277258147	1358634	1154082	12819	12244	2025-10-08 18:37:29.649908
1134	5.1	2	0.5576171875	0.40478515625	0.88427734375	7.751792907714844	5.320396423339844	2.087696075439453	73.1	96.73210144042969	57.50899887084961	39.20747756958008	59.451824176760226	1367965	1162129	12907	12330	2025-10-08 18:38:01.030392
1135	10.1	2	0.5576171875	0.42724609375	0.87744140625	7.751792907714844	5.293842315673828	2.114208221435547	72.7	96.73210144042969	57.50907516479492	39.207401275634766	59.451903048142306	1377170	1169904	12993	12412	2025-10-08 18:38:32.365288
1136	17	2	0.52001953125	0.43310546875	0.865234375	7.751792907714844	5.311714172363281	2.096282958984375	73	96.73210144042969	57.509315490722656	39.20716094970703	59.45215149299583	1386366	1177679	13079	12494	2025-10-08 18:39:03.743852
1137	53	2	0.61083984375	0.46435546875	0.859375	7.751792907714844	5.325977325439453	2.0817604064941406	73.1	96.73210144042969	57.516502380371094	39.199974060058594	59.45958117718693	1395571	1185454	13165	12576	2025-10-08 18:39:35.1995
1138	24.7	2	1.0244140625	0.59228515625	0.89111328125	7.751792907714844	5.299060821533203	2.1081390380859375	72.8	96.73210144042969	57.5318489074707	39.184627532958984	59.47544615569053	1405131	1193854	13257	12668	2025-10-08 18:40:06.569836
1139	17.1	2	1.02783203125	0.63134765625	0.8955078125	7.751792907714844	5.338153839111328	2.069000244140625	73.3	96.73210144042969	57.53205108642578	39.184425354003906	59.475655164853016	1415441	1202163	13357	12758	2025-10-08 18:40:38.249014
1140	15.1	2	0.87158203125	0.63330078125	0.88818359375	7.751792907714844	5.329963684082031	2.0771408081054688	73.2	96.73210144042969	57.53211212158203	39.184364318847656	59.475718261958676	1425408	1210553	13454	12847	2025-10-08 18:41:09.588864
1141	1.5	2	0.7080078125	0.61181640625	0.87109375	7.751792907714844	5.294887542724609	2.1121673583984375	72.8	96.73210144042969	57.5318603515625	39.18461608886719	59.47545798639784	1434823	1218408	13544	12930	2025-10-08 18:41:40.916786
1142	4.5	2	0.615234375	0.599609375	0.8583984375	7.751792907714844	5.293857574462891	2.1131515502929688	72.7	96.73210144042969	57.53204345703125	39.18443298339844	59.47564727771481	1444024	1226267	13630	13014	2025-10-08 18:42:12.245087
1143	4.5	2	0.37158203125	0.54052734375	0.8291015625	7.751792907714844	5.302223205566406	2.1047401428222656	72.8	96.73210144042969	57.532142639160156	39.18433380126953	59.4757498105115	1453226	1234042	13716	13096	2025-10-08 18:42:43.595892
1144	20.6	2	0.427734375	0.5361328125	0.81689453125	7.751792907714844	5.323398590087891	2.0835189819335938	73.1	96.73210144042969	57.53224182128906	39.184234619140625	59.4758523433082	1462408	1241817	13802	13178	2025-10-08 18:43:14.964174
1145	3.5	2	0.87451171875	0.63525390625	0.83984375	7.751792907714844	5.313606262207031	2.0932655334472656	73	96.73210144042969	57.532196044921875	39.18428039550781	59.47580502047896	1471601	1249592	13888	13260	2025-10-08 18:43:46.28155
1146	13.6	2	0.751953125	0.6240234375	0.828125	7.751792907714844	5.292736053466797	2.1139869689941406	72.7	96.73210144042969	57.532291412353516	39.18418502807617	59.47590360970655	1480818	1257367	13974	13342	2025-10-08 18:44:17.613473
1147	15.6	2	0.76904296875	0.64306640625	0.8271484375	7.751792907714844	5.287670135498047	2.1190643310546875	72.7	96.73210144042969	57.53216552734375	39.18431091308594	59.47577347192613	1489448	1264176	14058	13418	2025-10-08 18:44:48.64802
1148	13.9	2	0.46484375	0.580078125	0.7998046875	7.751792907714844	5.29193115234375	2.11474609375	72.7	96.73210144042969	57.532379150390625	39.18409729003906	59.47599431179592	1499333	1271869	14149	13492	2025-10-08 18:45:19.721504
1149	0.5	2	0.76806640625	0.62939453125	0.8076171875	7.751792907714844	5.294551849365234	2.112079620361328	72.8	96.73210144042969	57.53229904174805	39.18417739868164	59.475911496844745	1509024	1279642	14237	13567	2025-10-08 18:45:50.747975
1150	5.1	2	0.52685546875	0.583984375	0.787109375	7.751792907714844	5.297218322753906	2.109375	72.8	96.73210144042969	57.53235626220703	39.184120178222656	59.475970650381306	1518850	1287415	14328	13642	2025-10-08 18:46:21.773774
1151	2	2	0.478515625	0.560546875	0.77197265625	7.751792907714844	5.2972564697265625	2.1092796325683594	72.8	96.73210144042969	57.532230377197266	39.18424606323242	59.47584051260088	1528192	1295108	14409	13716	2025-10-08 18:46:52.812666
1152	55.6	2	0.69580078125	0.60205078125	0.7783203125	7.751792907714844	5.311405181884766	2.0950927734375	73	96.73210144042969	57.532222747802734	39.18425369262695	59.47583262546268	1537490	1302721	14489	13789	2025-10-08 18:47:23.854392
1153	29.5	2	0.42041015625	0.54296875	0.751953125	7.751792907714844	5.2901611328125	2.1162872314453125	72.7	96.73210144042969	57.532508850097656	39.18396759033203	59.476128393145444	1546765	1310334	14569	13862	2025-10-08 18:47:54.887105
1154	4	2	0.57275390625	0.5634765625	0.75	7.751792907714844	5.291259765625	2.115154266357422	72.7	96.73210144042969	57.53248596191406	39.183990478515625	59.47610473173083	1556314	1318199	14655	13941	2025-10-08 18:48:25.921695
1155	1.5	2	0.345703125	0.50830078125	0.7236328125	7.751792907714844	5.2953948974609375	2.110973358154297	72.8	96.73210144042969	57.532474517822266	39.18400192260742	59.47609290102351	1565842	1326064	14741	14020	2025-10-08 18:48:56.950261
1156	1.5	2	0.26123046875	0.47412109375	0.7060546875	7.751792907714844	5.294109344482422	2.1122169494628906	72.8	96.73210144042969	57.532527923583984	39.1839485168457	59.47614811099097	1575405	1333929	14827	14099	2025-10-08 18:49:27.980283
1157	2	2	0.15673828125	0.42724609375	0.6826171875	7.751792907714844	5.295196533203125	2.1110877990722656	72.8	96.73210144042969	57.53251266479492	39.183963775634766	59.47613233671455	1584933	1341794	14913	14178	2025-10-08 18:49:59.011897
1158	1	2	0.09423828125	0.384765625	0.6591796875	7.751792907714844	5.300174713134766	2.106060028076172	72.8	96.73210144042969	57.532569885253906	39.18390655517578	59.476191490251104	1594444	1349617	14998	14256	2025-10-08 18:50:30.045541
1159	11.5	2	0.05126953125	0.3408203125	0.63232421875	7.751792907714844	5.307598114013672	2.098602294921875	72.9	96.73210144042969	57.5325813293457	39.183895111083984	59.47620332095841	1603982	1357482	15084	14335	2025-10-08 18:51:01.074003
1160	1.5	2	0.02978515625	0.30712890625	0.61181640625	7.751792907714844	5.295940399169922	2.110198974609375	72.8	96.73210144042969	57.53258514404297	39.18389129638672	59.47620726452752	1613520	1365347	15170	14414	2025-10-08 18:51:32.10361
1161	6	2	0.27783203125	0.3408203125	0.61376953125	7.751792907714844	5.305255889892578	2.100830078125	72.9	96.73210144042969	57.53260803222656	39.183868408203125	59.47623092594214	1623060	1373212	15256	14493	2025-10-08 18:52:03.140448
1162	17.5	2	0.22021484375	0.32275390625	0.59912109375	7.751792907714844	5.291896820068359	2.1141281127929688	72.7	96.73210144042969	57.53278350830078	39.183692932128906	59.4764123301209	1632567	1381035	15341	14571	2025-10-08 18:52:34.196784
1163	12.5	2	0.2626953125	0.3232421875	0.59033203125	7.751792907714844	5.304618835449219	2.1013526916503906	72.9	96.73210144042969	57.532554626464844	39.183921813964844	59.47617571597469	1641855	1388648	15421	14644	2025-10-08 18:53:05.224322
1164	0.5	2	0.20263671875	0.30224609375	0.572265625	7.751792907714844	5.295948028564453	2.1099853515625	72.8	96.73210144042969	57.532623291015625	39.18385314941406	59.476246700218546	1651131	1396261	15501	14717	2025-10-08 18:53:36.263588
1165	4.5	2	0.18994140625	0.28857421875	0.5576171875	7.751792907714844	5.302848815917969	2.103046417236328	72.9	96.73210144042969	57.532508850097656	39.18396759033203	59.476128393145444	1660403	1403874	15581	14790	2025-10-08 18:54:07.292173
1166	3	2	0.59423828125	0.35986328125	0.57080078125	7.751792907714844	5.316867828369141	2.0889854431152344	73.1	96.73210144042969	57.532657623291016	39.18381881713867	59.47628219234048	1669704	1411487	15661	14863	2025-10-08 18:54:38.324342
1167	1.5	2	0.43310546875	0.3408203125	0.55615234375	7.751792907714844	5.314994812011719	2.0908050537109375	73	96.73210144042969	57.53266906738281	39.183807373046875	59.47629402304779	1679005	1419100	15741	14936	2025-10-08 18:55:09.35338
1168	16.3	2	0.93359375	0.46875	0.5908203125	7.751792907714844	5.297946929931641	2.1078147888183594	72.8	96.73210144042969	57.53275680541992	39.183719635009766	59.47638472513718	1688317	1426713	15821	15009	2025-10-08 18:55:40.389859
1169	7.1	2	0.88330078125	0.51123046875	0.60107421875	7.751792907714844	5.309230804443359	2.0964927673339844	73	96.73210144042969	57.532718658447266	39.18375778198242	59.476345289446144	1698559	1435533	15912	15100	2025-10-08 18:56:11.420171
1170	5.4	2	0.61474609375	0.47802734375	0.58642578125	7.751792907714844	5.303932189941406	2.1017417907714844	72.9	96.73210144042969	57.53278732299805	39.18368911743164	59.476416273690006	1708373	1443741	15997	15180	2025-10-08 18:56:42.471305
1171	61.8	2	0.4453125	0.44775390625	0.57177734375	7.751792907714844	5.327484130859375	2.0781478881835938	73.2	96.73210144042969	57.53274154663086	39.18373489379883	59.47636895086076	1718198	1451949	16082	15260	2025-10-08 18:57:13.51795
1172	27.7	2	0.2685546875	0.40380859375	0.55126953125	7.751792907714844	5.318012237548828	2.087574005126953	73.1	96.73210144042969	57.532840728759766	39.18363571166992	59.476471483657456	1727953	1460115	16166	15339	2025-10-08 18:57:44.5517
1173	8.1	2	0.21435546875	0.37939453125	0.53759765625	7.751792907714844	5.329212188720703	2.076335906982422	73.2	96.73210144042969	57.53286361694336	39.18361282348633	59.47649514507207	1737706	1468239	16249	15417	2025-10-08 18:58:15.586101
1174	8	2	0.35888671875	0.38623046875	0.53369140625	7.751792907714844	5.312164306640625	2.0933303833007812	73	96.73210144042969	57.53296661376953	39.183509826660156	59.47660162143787	1747473	1476405	16333	15496	2025-10-08 18:58:46.648155
1175	6.5	2	0.66162109375	0.45947265625	0.5537109375	7.751792907714844	5.316692352294922	2.0887603759765625	73.1	96.73210144042969	57.53285217285156	39.183624267578125	59.47648331436477	1757243	1484571	16417	15575	2025-10-08 18:59:17.69008
1176	5	2	0.48046875	0.43115234375	0.54052734375	7.751792907714844	5.315120697021484	2.0902862548828125	73	96.73210144042969	57.532901763916016	39.18357467651367	59.47653458076311	1767025	1492737	16501	15654	2025-10-08 18:59:48.754424
1177	15.2	2	0.34765625	0.40478515625	0.52880859375	7.751792907714844	5.334194183349609	2.0711631774902344	73.3	96.73210144042969	57.533050537109375	39.18342590332031	59.476688379958155	1776739	1500945	16584	15734	2025-10-08 19:00:19.789921
1178	15.6	2	0.19189453125	0.3583984375	0.50830078125	7.751792907714844	5.313747406005859	2.091564178466797	73	96.73210144042969	57.53325271606445	39.183223724365234	59.476897389120644	1786521	1509111	16668	15813	2025-10-08 19:00:50.857418
1179	4.6	2	0.32763671875	0.37255859375	0.50830078125	7.751792907714844	5.31121826171875	2.0940628051757812	73	96.73210144042969	57.53300094604492	39.183475494384766	59.4766371135598	1796262	1517235	16751	15891	2025-10-08 19:01:21.898829
1180	28.1	2	0.83984375	0.49560546875	0.544921875	7.751792907714844	5.320892333984375	2.0843429565429688	73.1	96.73210144042969	57.533267974853516	39.18320846557617	59.47691316339705	1806442	1525903	16839	15975	2025-10-08 19:01:52.945788
1181	9.2	2	0.75390625	0.51171875	0.54833984375	7.751792907714844	5.299709320068359	2.1054306030273438	72.8	96.73210144042969	57.53350067138672	39.18297576904297	59.47715372111237	1816287	1534387	16924	16061	2025-10-08 19:02:23.99363
1182	86.5	2	1.49072265625	0.70458984375	0.611328125	7.751792907714844	5.665283203125	1.7383842468261719	77.6	96.73210144042969	57.52725601196289	39.1892204284668	59.47069809848985	1825995	1542511	17007	16139	2025-10-08 19:02:55.049709
1183	65.7	2	2.38232421875	1.021484375	0.72265625	7.751792907714844	6.627830505371094	0.77166748046875	90	96.73210144042969	57.526981353759766	39.18949508666992	59.4704141615144	1836598	1551556	17091	16218	2025-10-08 19:03:26.149054
1184	96.7	2	6.751953125	2.20703125	1.12890625	7.751792907714844	7.426784515380859	0.050922393798828125	99.3	96.73210144042969	57.52725601196289	39.1892204284668	59.47069809848985	1847543	1560920	17179	16301	2025-10-08 19:04:10.971189
1185	100	2	16.27783203125	5.2216796875	2.1904296875	7.751792907714844	7.091224670410156	0.32596588134765625	95.8	96.73210144042969	57.527137756347656	39.18933868408203	59.47057584784764	1859962	1571957	17281	16400	2025-10-08 19:04:48.437301
1186	95.5	2	11.3623046875	5.0625	2.23193359375	7.751792907714844	5.9911346435546875	1.4230766296386719	81.6	96.73210144042969	57.527244567871094	39.189231872558594	59.47068626778253	1871474	1582136	17366	16483	2025-10-08 19:05:19.494121
1187	94	2	8.53515625	5.001953125	2.3037109375	7.751792907714844	7.053169250488281	0.3583412170410156	95.4	96.73210144042969	57.527244567871094	39.189231872558594	59.47068626778253	1882102	1591181	17450	16562	2025-10-08 19:05:50.599904
1188	95.1	2	15.67041015625	7.20947265625	3.1689453125	7.751792907714844	7.436710357666016	0.0420684814453125	99.5	96.73210144042969	57.52740478515625	39.18907165527344	59.47085189768488	1889755	1597284	17497	16607	2025-10-08 19:06:39.77931
1189	34.5	2	11.337890625	7.15966796875	3.30810546875	7.751792907714844	5.303436279296875	2.1132736206054688	72.7	96.73210144042969	57.53388595581055	39.18259048461914	59.477552021591826	1910751	1615004	17625	16731	2025-10-08 19:07:10.88479
1190	15.8	2	6.87939453125	6.50830078125	3.232421875	7.751792907714844	5.297199249267578	2.1194915771484375	72.7	96.73210144042969	57.53400802612305	39.18246841430664	59.477678215803145	1920799	1623448	17714	16815	2025-10-08 19:07:41.92933
1191	25.1	2	4.92431640625	6.08740234375	3.197265625	7.751792907714844	5.326732635498047	2.0900039672851562	73	96.73210144042969	57.53385925292969	39.1826171875	59.477524416608105	1930529	1631574	17799	16895	2025-10-08 19:08:12.966449
1192	37.7	2	3.056640625	5.52099609375	3.099609375	7.751792907714844	5.323894500732422	2.092823028564453	73	96.73210144042969	57.5339469909668	39.18252944946289	59.47761511869749	1940699	1640347	17891	16983	2025-10-08 19:08:44.005805
1193	22.1	2	2.24755859375	5.087890625	3.03173828125	7.751792907714844	5.324573516845703	2.0920066833496094	73	96.73210144042969	57.53406524658203	39.182411193847656	59.4777373693397	1950434	1648473	17976	17063	2025-10-08 19:09:15.061754
1194	26	2	1.361328125	4.60009765625	2.93408203125	7.751792907714844	5.3155364990234375	2.101062774658203	72.9	96.73210144042969	57.53385925292969	39.1826171875	59.477524416608105	1960160	1656599	18061	17143	2025-10-08 19:09:46.1007
1195	28.1	2	1.38916015625	4.23583984375	2.8720703125	7.751792907714844	5.330097198486328	2.0864906311035156	73.1	96.73210144042969	57.534156799316406	39.18231964111328	59.47783201499818	1969633	1664473	18140	17217	2025-10-08 19:10:17.157389
1196	24.5	2	0.90869140625	3.845703125	2.78466796875	7.751792907714844	5.318012237548828	2.0985565185546875	72.9	96.73210144042969	57.5340461730957	39.182430267333984	59.477717651494174	1979351	1672599	18225	17297	2025-10-08 19:10:48.201839
1197	24.4	2	0.6298828125	3.4931640625	2.7001953125	7.751792907714844	5.317451477050781	2.099109649658203	72.9	96.73210144042969	57.53403091430664	39.18244552612305	59.47770187721777	1989093	1680725	18310	17377	2025-10-08 19:11:19.260912
1198	35.5	2	0.51708984375	3.1904296875	2.623046875	7.751792907714844	5.3180389404296875	2.098621368408203	72.9	96.73210144042969	57.5341796875	39.18229675292969	59.47785567641281	1998777	1688809	18394	17456	2025-10-08 19:11:50.306108
1199	25.5	2	0.52587890625	2.9326171875	2.55419921875	7.751792907714844	5.316566467285156	2.099964141845703	72.9	96.73210144042969	57.5340576171875	39.18241882324219	59.47772948220149	2008763	1697185	18483	17540	2025-10-08 19:12:21.355298
1200	27.4	2	0.501953125	2.6552734375	2.47412109375	7.751792907714844	5.321937561035156	2.094585418701172	73	96.73210144042969	57.53416442871094	39.18231201171875	59.47783990213639	2018263	1705059	18562	17614	2025-10-08 19:12:52.401037
1201	24.1	2	1.134765625	2.59375	2.4580078125	7.751792907714844	5.346931457519531	2.0695648193359375	73.3	96.73210144042969	57.53417205810547	39.18230438232422	59.4778477892746	2027778	1712975	18642	17689	2025-10-08 19:13:23.448253
1202	29.3	2	0.82958984375	2.376953125	2.38916015625	7.751792907714844	5.352405548095703	2.064075469970703	73.4	96.73210144042969	57.53423309326172	39.18224334716797	59.47791088638026	2037301	1720891	18722	17764	2025-10-08 19:13:54.503292
1203	73.7	2	0.58203125	2.1650390625	2.3173828125	7.751792907714844	5.342777252197266	2.0736961364746094	73.2	96.73210144042969	57.53416442871094	39.18231201171875	59.47783990213639	2046819	1728807	18802	17839	2025-10-08 19:14:25.552105
1204	47.2	2	0.5498046875	1.98583984375	2.25146484375	7.751792907714844	5.329547882080078	2.0868072509765625	73.1	96.73210144042969	57.53396224975586	39.18251419067383	59.4776308929739	2057065	1737442	18891	17923	2025-10-08 19:14:56.809879
1205	22.6	2	0.72900390625	1.89111328125	2.2109375	7.751792907714844	5.349536895751953	2.0668983459472656	73.3	96.73210144042969	57.534061431884766	39.18241500854492	59.477733425770595	2066650	1745400	18972	17999	2025-10-08 19:15:27.852064
1206	21.6	2	0.4931640625	1.724609375	2.14453125	7.751792907714844	5.33697509765625	2.079448699951172	73.2	96.73210144042969	57.53417205810547	39.18230438232422	59.4778477892746	2076156	1753316	19052	18074	2025-10-08 19:15:58.894218
1207	36.6	2	0.2978515625	1.55908203125	2.07470703125	7.751792907714844	5.340248107910156	2.076152801513672	73.2	96.73210144042969	57.534400939941406	39.18207550048828	59.47808440342081	2086173	1761785	19136	18155	2025-10-08 19:16:29.947894
1208	19.2	2	0.35302734375	1.45458984375	2.0234375	7.751792907714844	5.342647552490234	2.0737457275390625	73.2	96.73210144042969	57.5343132019043	39.18216323852539	59.477993701331435	2095693	1769701	19216	18230	2025-10-08 19:17:01.0048
1209	23.7	2	0.244140625	1.30712890625	1.9521484375	7.751792907714844	5.347984313964844	2.0683860778808594	73.3	96.73210144042969	57.53437805175781	39.182098388671875	59.47806074200619	2105220	1777617	19296	18305	2025-10-08 19:17:32.039228
1210	22.4	2	0.2041015625	1.1962890625	1.8935546875	7.751792907714844	5.33538818359375	2.080974578857422	73.2	96.73210144042969	57.534324645996094	39.182151794433594	59.478005532038736	2114696	1785491	19375	18379	2025-10-08 19:18:03.081997
1211	21	2	0.25830078125	1.11328125	1.84326171875	7.751792907714844	5.348152160644531	2.0681991577148438	73.3	96.73210144042969	57.53468322753906	39.181793212890625	59.47837622753447	2124465	1793657	19459	18458	2025-10-08 19:18:34.152609
1212	20.9	2	0.21826171875	1.021484375	1.78857421875	7.751792907714844	5.338092803955078	2.0782318115234375	73.2	96.73210144042969	57.534461975097656	39.18201446533203	59.47814750052647	2134163	1801741	19543	18537	2025-10-08 19:19:05.190668
1213	30.5	2	0.40283203125	0.98681640625	1.751953125	7.751792907714844	5.33935546875	2.0769615173339844	73.2	96.73210144042969	57.53465270996094	39.18182373046875	59.47834467898164	2143945	1809907	19627	18616	2025-10-08 19:19:36.23911
1214	23.9	2	0.28564453125	0.89306640625	1.69091796875	7.751792907714844	5.347339630126953	2.068950653076172	73.3	96.73210144042969	57.5344352722168	39.18204116821289	59.47811989554275	2153678	1818031	19710	18694	2025-10-08 19:20:07.277244
1215	22.2	2	0.37548828125	0.85498046875	1.65185546875	7.751792907714844	5.3394317626953125	2.076854705810547	73.2	96.73210144042969	57.534576416015625	39.18190002441406	59.47826580759957	2163429	1826155	19793	18772	2025-10-08 19:20:38.315816
1216	24	2	1.203125	0.9990234375	1.6728515625	7.751792907714844	5.392009735107422	2.023113250732422	73.9	96.73210144042969	57.5394172668457	39.177059173583984	59.483270196791985	2173231	1834363	19878	18852	2025-10-08 19:21:09.369577
1217	23.1	2	0.8017578125	0.91943359375	1.62353515625	7.751792907714844	5.389461517333984	2.0257530212402344	73.9	96.73210144042969	57.53975296020508	39.17672348022461	59.4836172308731	2182691	1842237	19957	18926	2025-10-08 19:21:40.417275
1218	22.1	2	0.484375	0.830078125	1.57080078125	7.751792907714844	5.402492523193359	2.0127105712890625	74	96.73210144042969	57.53984451293945	39.176631927490234	59.483711876531586	2192472	1850403	20041	19005	2025-10-08 19:22:11.475472
1219	24.6	2	0.4228515625	0.7705078125	1.52197265625	7.751792907714844	5.387111663818359	2.0280914306640625	73.8	96.73210144042969	57.53989791870117	39.176578521728516	59.48376708649903	2202418	1858737	20129	19088	2025-10-08 19:22:42.536287
1220	66.3	2	0.416015625	0.72900390625	1.4833984375	7.751792907714844	5.411380767822266	2.003551483154297	74.2	96.73210144042969	57.545372009277344	39.171104431152344	59.48942610816263	2211894	1866611	20208	19162	2025-10-08 19:23:13.581806
1221	74.7	2	0.658203125	0.7568359375	1.46630859375	7.751792907714844	5.380275726318359	2.032958984375	73.8	96.73210144042969	57.6214714050293	39.09500503540039	59.56809636820947	2221897	1874987	20297	19246	2025-10-08 19:23:44.628873
1222	80.5	2	0.94384765625	0.82666015625	1.4658203125	7.751792907714844	5.361854553222656	2.0515098571777344	73.5	96.73210144042969	57.62118911743164	39.09528732299805	59.56780454409581	2235429	1888057	20417	19364	2025-10-08 19:24:15.682997
1223	85.9	2	1.21630859375	0.9072265625	1.47119140625	7.751792907714844	5.368885040283203	2.0443763732910156	73.6	96.73210144042969	57.62173843383789	39.0947380065918	59.56837241804672	2247101	1898316	20505	19452	2025-10-08 19:24:46.753062
1224	76.3	2	1.3232421875	0.95361328125	1.4638671875	7.751792907714844	5.381828308105469	2.031402587890625	73.8	96.73210144042969	57.62174606323242	39.094730377197266	59.56838030518492	2258544	1908287	20589	19534	2025-10-08 19:25:17.801046
1225	60.6	2	1.814453125	1.08984375	1.49072265625	7.751792907714844	5.329914093017578	2.0833663940429688	73.1	96.73210144042969	57.621795654296875	39.09468078613281	59.56843157158327	2269405	1917871	20676	19625	2025-10-08 19:25:48.861171
1226	20	2	1.60693359375	1.11181640625	1.48486328125	7.751792907714844	5.387157440185547	2.025951385498047	73.9	96.73210144042969	57.62185287475586	39.09462356567383	59.56849072511983	2279990	1927047	20759	19709	2025-10-08 19:26:19.910822
1227	24.4	2	1.025390625	1.01953125	1.44091796875	7.751792907714844	5.402610778808594	2.0104598999023438	74.1	96.73210144042969	57.621707916259766	39.09476852416992	59.56834086949389	2290824	1936283	20846	19792	2025-10-08 19:26:50.947343
1228	28.3	2	0.8076171875	0.96826171875	1.41064453125	7.751792907714844	5.397480010986328	2.0155258178710938	74	96.73210144042969	57.62177658081055	39.09469985961914	59.56841185373776	2301479	1945357	20931	19873	2025-10-08 19:27:21.993817
1229	21.4	2	0.529296875	0.876953125	1.361328125	7.751792907714844	5.3985443115234375	2.0144081115722656	74	96.73210144042969	57.62161636352539	39.0948600769043	59.56824622383541	2312054	1954393	21014	19953	2025-10-08 19:27:53.038704
1230	6	2	0.53125	0.841796875	1.33349609375	7.751792907714844	5.368869781494141	2.0437889099121094	73.6	96.73210144042969	57.6217155456543	39.09476089477539	59.5683487566321	2323133	1963911	21100	20041	2025-10-08 19:28:24.082548
1231	2	2	0.462890625	0.79296875	1.30029296875	7.751792907714844	5.388950347900391	2.023651123046875	73.9	96.73210144042969	57.621700286865234	39.09477615356445	59.568332982355685	2333777	1972959	21183	20120	2025-10-08 19:28:55.111447
1232	5.5	2	0.57763671875	0.79541015625	1.28369140625	7.751792907714844	5.389102935791016	2.023456573486328	73.9	96.73210144042969	57.621826171875	39.09465026855469	59.56846312013611	2344222	1981799	21263	20196	2025-10-08 19:29:26.142011
1233	3.5	2	0.3486328125	0.7177734375	1.24169921875	7.751792907714844	5.388942718505859	2.0235671997070312	73.9	96.73210144042969	57.622005462646484	39.0944709777832	59.56864846788397	2354624	1990597	21342	20271	2025-10-08 19:29:57.178012
1234	3	2	0.31396484375	0.6689453125	1.20458984375	7.751792907714844	5.404228210449219	2.0082550048828125	74.1	96.73210144042969	57.62194061279297	39.09453582763672	59.56858142720921	2365322	1999729	21426	20352	2025-10-08 19:30:28.218032
1235	6.5	2	0.41064453125	0.6533203125	1.1806640625	7.751792907714844	5.3923187255859375	2.0201187133789062	73.9	96.73210144042969	57.622257232666016	39.09421920776367	59.5689087434448	2376100	2008887	21510	20432	2025-10-08 19:30:59.252963
1236	4.5	2	0.24755859375	0.58935546875	1.142578125	7.751792907714844	5.402069091796875	2.0103225708007812	74.1	96.73210144042969	57.62202072143555	39.09445571899414	59.56866424216039	2386855	2017997	21594	20512	2025-10-08 19:31:30.293817
1237	9	2	0.2294921875	0.54833984375	1.10986328125	7.751792907714844	5.414875030517578	1.9974861145019531	74.2	96.73210144042969	57.62204360961914	39.09443283081055	59.568687903575004	2397249	2026795	21673	20587	2025-10-08 19:32:01.346675
1238	20.2	2	0.28759765625	0.51953125	1.07861328125	7.751792907714844	5.40765380859375	2.0046653747558594	74.1	96.73210144042969	57.621761322021484	39.0947151184082	59.56839607946134	2407699	2035635	21753	20663	2025-10-08 19:32:32.391588
1239	54.8	2	0.734375	0.5849609375	1.08154296875	7.751792907714844	5.427448272705078	1.9848175048828125	74.4	96.73210144042969	57.62186813354492	39.094608306884766	59.568506499396236	2418354	2044683	21836	20742	2025-10-08 19:33:03.453888
1240	35.5	2	0.6044921875	0.5615234375	1.0576171875	7.751792907714844	5.422092437744141	1.990142822265625	74.3	96.73210144042969	57.62179183959961	39.09468460083008	59.56842762801416	2429005	2053691	21920	20822	2025-10-08 19:33:34.490514
1241	6	2	0.36474609375	0.50634765625	1.0224609375	7.751792907714844	5.419239044189453	1.9929580688476562	74.3	96.73210144042969	57.62184524536133	39.09463119506836	59.56848283798162	2439926	2062969	22008	20906	2025-10-08 19:34:05.531257
1242	5	2	0.27294921875	0.47216796875	0.9931640625	7.751792907714844	5.426300048828125	1.9858665466308594	74.4	96.73210144042969	57.62191390991211	39.09456253051758	59.56855382222548	2450489	2071935	22091	20985	2025-10-08 19:34:36.600641
1243	5.1	2	0.1513671875	0.41845703125	0.95556640625	7.751792907714844	5.423957824707031	1.9881668090820312	74.4	96.73210144042969	57.62205123901367	39.094425201416016	59.568695790713214	2461388	2081213	22179	21069	2025-10-08 19:35:07.635077
1244	11.2	2	0.1435546875	0.392578125	0.92919921875	7.751792907714844	5.429191589355469	1.9828910827636719	74.4	96.73210144042969	57.621891021728516	39.09458541870117	59.56853016081086	2472019	2090221	22263	21149	2025-10-08 19:35:38.689155
1245	4.5	2	0.2060546875	0.3857421875	0.90869140625	7.751792907714844	5.430057525634766	1.9819793701171875	74.4	96.73210144042969	57.622047424316406	39.09442901611328	59.56869184714411	2482885	2099479	22351	21233	2025-10-08 19:36:09.7358
1246	7.1	2	0.123046875	0.34716796875	0.87939453125	7.751792907714844	5.433269500732422	1.978729248046875	74.5	96.73210144042969	57.62199783325195	39.094478607177734	59.56864058074576	2493514	2108487	22435	21313	2025-10-08 19:36:40.776436
1247	6.1	2	0.13623046875	0.3291015625	0.85595703125	7.751792907714844	5.433296203613281	1.9786605834960938	74.5	96.73210144042969	57.62221145629883	39.09426498413086	59.56886142061556	2504129	2117495	22519	21393	2025-10-08 19:37:11.810657
1248	7	2	0.123046875	0.306640625	0.82763671875	7.751792907714844	5.427818298339844	1.9840888977050781	74.4	96.73210144042969	57.62236404418945	39.094112396240234	59.5690191633797	2515016	2126773	22607	21477	2025-10-08 19:37:42.855908
1249	5.6	2	0.13623046875	0.29150390625	0.8056640625	7.751792907714844	5.407310485839844	2.004619598388672	74.1	96.73210144042969	57.623111724853516	39.09336471557617	59.569792102924005	2525670	2135821	22690	21556	2025-10-08 19:38:13.902189
1250	13.1	2	0.08154296875	0.26220703125	0.779296875	7.751792907714844	5.39886474609375	2.0129737854003906	74	96.73210144042969	57.625	39.09147644042969	59.57174416963026	2536516	2145130	22772	21636	2025-10-08 19:38:44.945698
1251	15.2	2	0.1162109375	0.2529296875	0.7587890625	7.751792907714844	5.401756286621094	2.010028839111328	74.1	96.73210144042969	57.62525177001953	39.091224670410156	59.5720044451911	2547193	2154198	22855	21715	2025-10-08 19:39:15.995627
1252	5.5	2	0.06884765625	0.22705078125	0.732421875	7.751792907714844	5.321422576904297	2.0904808044433594	73	96.73210144042969	57.624855041503906	39.09162139892578	59.57159431400433	2557818	2163330	22937	21796	2025-10-08 19:39:47.032574
1253	63.8	2	0.35791015625	0.26708984375	0.72607421875	7.751792907714844	5.375713348388672	2.0359878540039062	73.7	96.73210144042969	57.625328063964844	39.091148376464844	59.57208331657316	2567871	2171796	23014	21870	2025-10-08 19:40:18.104691
1254	4.5	2	0.83251953125	0.39892578125	0.75537109375	7.751792907714844	5.386199951171875	2.0254440307617188	73.9	96.73210144042969	57.62543487548828	39.091041564941406	59.57219373650806	2578702	2181182	23097	21952	2025-10-08 19:40:49.141852
1255	6.5	2	0.50341796875	0.359375	0.72900390625	7.751792907714844	5.345939636230469	2.065685272216797	73.4	96.73210144042969	57.625457763671875	39.09101867675781	59.572217397922685	2588205	2189056	23176	22026	2025-10-08 19:41:20.185862
1256	23.4	2	0.46435546875	0.35693359375	0.71630859375	7.751792907714844	5.3819122314453125	2.0296669006347656	73.8	96.73210144042969	57.62533187866211	39.09114456176758	59.57208726014227	2597691	2196930	23255	22100	2025-10-08 19:41:51.220486
1257	10.6	2	0.2802734375	0.3212890625	0.69287109375	7.751792907714844	5.381618499755859	2.0299148559570312	73.8	96.73210144042969	57.62544631958008	39.09103012084961	59.57220556721538	2607200	2204846	23335	22175	2025-10-08 19:42:22.256311
1258	71.7	2	0.45849609375	0.35107421875	0.68798828125	7.751792907714844	5.407585144042969	2.00396728515625	74.1	96.73210144042969	57.62691879272461	39.08955764770508	59.57372778488935	2616689	2212720	23414	22249	2025-10-08 19:42:53.307538
1259	16.5	2	0.330078125	0.33203125	0.67041015625	7.751792907714844	5.372859954833984	2.0386581420898438	73.7	96.73210144042969	57.62725067138672	39.08922576904297	59.574070875401354	2626208	2220636	23494	22324	2025-10-08 19:43:24.351489
1260	9	2	0.279296875	0.31591796875	0.65283203125	7.751792907714844	5.3692779541015625	2.0421981811523438	73.7	96.73210144042969	57.62702941894531	39.089447021484375	59.573842148393354	2636031	2228846	23581	22406	2025-10-08 19:43:55.3914
1261	11.1	2	0.22119140625	0.30029296875	0.63525390625	7.751792907714844	5.375114440917969	2.0363121032714844	73.7	96.73210144042969	57.62689971923828	39.089576721191406	59.57370806704383	2645748	2236972	23666	22486	2025-10-08 19:44:26.433481
1262	5.5	2	0.1328125	0.27001953125	0.61474609375	7.751792907714844	5.3878631591796875	2.023456573486328	73.9	96.73210144042969	57.626976013183594	39.089500427246094	59.5737869384259	2655509	2245140	23752	22567	2025-10-08 19:44:57.480774
1263	11.6	2	0.1259765625	0.25390625	0.5966796875	7.751792907714844	5.382724761962891	2.0285415649414062	73.8	96.73210144042969	57.62704086303711	39.08943557739258	59.57385397910067	2665527	2253558	23842	22652	2025-10-08 19:45:28.52274
1264	4.5	2	0.24755859375	0.275390625	0.5927734375	7.751792907714844	5.3763580322265625	2.034862518310547	73.7	96.73210144042969	57.626949310302734	39.08952713012695	59.573759333442176	2675283	2261726	23928	22733	2025-10-08 19:45:59.556756
1265	20.5	2	0.5556640625	0.357421875	0.61083984375	7.751792907714844	5.398170471191406	2.0130043029785156	74	96.73210144042969	57.62702941894531	39.089447021484375	59.573842148393354	2685065	2269894	24014	22814	2025-10-08 19:46:30.599754
1266	24.5	2	0.92822265625	0.4794921875	0.64404296875	7.751792907714844	5.4173431396484375	1.9937705993652344	74.3	96.73210144042969	57.62715530395508	39.08932113647461	59.57397228617377	2695030	2278501	24103	22900	2025-10-08 19:47:01.644245
1267	23.7	2	0.90087890625	0.5126953125	0.64892578125	7.751792907714844	5.407451629638672	2.0036392211914062	74.2	96.73210144042969	57.627384185791016	39.08909225463867	59.57420890031998	2705088	2286919	24193	22985	2025-10-08 19:47:32.684854
1268	31.8	2	0.97119140625	0.58056640625	0.66650390625	7.751792907714844	5.409915924072266	2.001110076904297	74.2	96.73210144042969	57.62720489501953	39.089271545410156	59.57402355257212	2714842	2295045	24278	23065	2025-10-08 19:48:03.727927
1269	22.6	2	0.693359375	0.5546875	0.654296875	7.751792907714844	5.4097137451171875	2.001270294189453	74.2	96.73210144042969	57.62725830078125	39.08921813964844	59.574078762539564	2724333	2302919	24357	23139	2025-10-08 19:48:34.77508
1270	22	2	0.5498046875	0.533203125	0.642578125	7.751792907714844	5.404651641845703	2.0062904357910156	74.1	96.73210144042969	57.62724304199219	39.0892333984375	59.57406298826315	2734096	2311085	24441	23218	2025-10-08 19:49:05.814977
1271	24	2	0.33154296875	0.48095703125	0.62109375	7.751792907714844	5.376850128173828	2.0340423583984375	73.8	96.73210144042969	57.62771224975586	39.08876419067383	59.57454804726289	2743569	2318959	24520	23292	2025-10-08 19:49:36.865781
1272	26.5	2	0.42138671875	0.48291015625	0.6171875	7.751792907714844	5.378074645996094	2.032764434814453	73.8	96.73210144042969	57.627471923828125	39.08900451660156	59.57429960240936	2753347	2327125	24604	23371	2025-10-08 19:50:07.908391
1273	23.9	2	0.41162109375	0.4755859375	0.6103515625	7.751792907714844	5.372936248779297	2.0378379821777344	73.7	96.73210144042969	57.62765121459961	39.08882522583008	59.57448495015723	2762886	2335041	24684	23446	2025-10-08 19:50:38.958056
1274	26.4	2	0.40234375	0.46240234375	0.6015625	7.751792907714844	5.3874969482421875	2.0232505798339844	73.9	96.73210144042969	57.627357482910156	39.08911895751953	59.57418129533626	2772363	2342915	24763	23520	2025-10-08 19:51:10.002248
1275	25.1	2	0.3232421875	0.43408203125	0.5869140625	7.751792907714844	5.396270751953125	2.014415740966797	74	96.73210144042969	57.627525329589844	39.088951110839844	59.57435481237682	2782125	2351041	24848	23600	2025-10-08 19:51:41.051697
1276	24.7	2	0.60498046875	0.48828125	0.599609375	7.751792907714844	5.3692169189453125	2.041423797607422	73.7	96.73210144042969	57.62754440307617	39.088932037353516	59.57437453022233	2791603	2358915	24927	23674	2025-10-08 19:52:12.092256
1277	70.2	2	0.365234375	0.43994140625	0.5791015625	7.751792907714844	5.3707733154296875	2.039813995361328	73.7	96.73210144042969	57.627784729003906	39.08869171142578	59.574622975075854	2801144	2366831	25007	23749	2025-10-08 19:52:43.132404
1278	38.4	2	0.45654296875	0.4541015625	0.578125	7.751792907714844	5.378913879394531	2.0316429138183594	73.8	96.73210144042969	57.62765884399414	39.08881759643555	59.57449283729544	2810622	2374705	25086	23823	2025-10-08 19:53:14.180936
1279	22.7	2	0.275390625	0.4091796875	0.5576171875	7.751792907714844	5.366703033447266	2.043773651123047	73.6	96.73210144042969	57.62785339355469	39.088623046875	59.57469395931972	2820123	2382621	25166	23898	2025-10-08 19:53:45.232854
1280	30.2	2	0.21875	0.38427734375	0.54296875	7.751792907714844	5.3729248046875	2.03753662109375	73.7	96.73210144042969	57.62767791748047	39.08879852294922	59.574512555140956	2829637	2390537	25246	23973	2025-10-08 19:54:16.275366
1281	24.1	2	0.1318359375	0.34619140625	0.525390625	7.751792907714844	5.376800537109375	2.0336036682128906	73.8	96.73210144042969	57.62791061401367	39.088565826416016	59.57475311285627	2839145	2398453	25326	24048	2025-10-08 19:54:47.316668
1282	35.9	2	0.45361328125	0.419921875	0.5439453125	7.751792907714844	5.376041412353516	2.0343246459960938	73.8	96.73210144042969	57.62771224975586	39.08876419067383	59.57454804726289	2848663	2406369	25406	24123	2025-10-08 19:55:18.368894
1283	37.2	2	1.181640625	0.5703125	0.58837890625	7.751792907714844	5.388114929199219	2.022186279296875	73.9	96.73210144042969	57.62803649902344	39.08843994140625	59.57488325063669	2858125	2414243	25485	24197	2025-10-08 19:55:49.413946
1284	38.4	2	0.830078125	0.5458984375	0.5791015625	7.751792907714844	5.38800048828125	2.022369384765625	73.9	96.73210144042969	57.62762451171875	39.08885192871094	59.574457345173506	2867627	2422159	25565	24272	2025-10-08 19:56:20.453498
1285	44.4	2	0.66015625	0.5390625	0.5751953125	7.751792907714844	5.369014739990234	2.0411949157714844	73.7	96.73210144042969	57.62771224975586	39.08876419067383	59.57454804726289	2877143	2430075	25645	24347	2025-10-08 19:56:51.517163
1286	23.1	2	0.46142578125	0.50244140625	0.560546875	7.751792907714844	5.331760406494141	2.078632354736328	73.2	96.73210144042969	57.62742233276367	39.089054107666016	59.57424833601102	2886891	2438010	25728	24423	2025-10-08 19:57:22.563699
1287	24.5	2	0.9501953125	0.62060546875	0.59716796875	7.751792907714844	5.405975341796875	2.0038681030273438	74.1	96.73210144042969	57.627716064453125	39.08876037597656	59.57455199083199	2897624	2447085	25813	24504	2025-10-08 19:57:53.626303
1288	29.1	2	0.57470703125	0.5595703125	0.57666015625	7.751792907714844	5.408599853515625	2.0012054443359375	74.2	96.73210144042969	57.62767791748047	39.08879852294922	59.574512555140956	2907156	2455001	25893	24579	2025-10-08 19:58:24.666673
1289	25.5	2	0.9482421875	0.64990234375	0.60595703125	7.751792907714844	5.405662536621094	2.0040969848632812	74.1	96.73210144042969	57.627994537353516	39.08848190307617	59.574839871376554	2917179	2463419	25983	24664	2025-10-08 19:58:55.71437
1290	55.3	2	0.72119140625	0.61962890625	0.5966796875	7.751792907714844	5.392219543457031	2.0174598693847656	74	96.73210144042969	57.627689361572266	39.08878707885742	59.57452438584827	2926932	2471545	26068	24744	2025-10-08 19:59:26.754057
1291	21.4	2	0.51025390625	0.57568359375	0.58203125	7.751792907714844	5.381324768066406	2.028308868408203	73.8	96.73210144042969	57.62782287597656	39.088653564453125	59.57466241076689	2936704	2479713	26154	24825	2025-10-08 19:59:57.819306
1292	22.1	2	0.283203125	0.5107421875	0.55810546875	7.751792907714844	5.392818450927734	2.016765594482422	74	96.73210144042969	57.62784957885742	39.088626861572266	59.57469001575062	2946747	2488131	26244	24910	2025-10-08 20:00:28.872188
1293	22.5	2	0.31787109375	0.4931640625	0.54931640625	7.751792907714844	5.377666473388672	2.0318641662597656	73.8	96.73210144042969	57.62790298461914	39.08857345581055	59.57474522571806	2956498	2496257	26329	24990	2025-10-08 20:00:59.915466
1294	23.2	2	0.19091796875	0.44482421875	0.53076171875	7.751792907714844	5.3776092529296875	2.0318832397460938	73.8	96.73210144042969	57.6277961730957	39.088680267333984	59.57463480578317	2966282	2504425	26415	25071	2025-10-08 20:01:30.953989
1295	23.1	2	0.19482421875	0.41796875	0.51904296875	7.751792907714844	5.3802642822265625	2.029193878173828	73.8	96.73210144042969	57.62788391113281	39.088592529296875	59.57472550787255	2976535	2513062	26506	25157	2025-10-08 20:02:02.126565
1296	72.1	2	0.275390625	0.4228515625	0.51806640625	7.751792907714844	5.367710113525391	2.041698455810547	73.7	96.73210144042969	57.62788009643555	39.08859634399414	59.574721564303445	2986559	2521480	26596	25242	2025-10-08 20:02:33.172347
1297	50.3	2	0.29541015625	0.408203125	0.50927734375	7.751792907714844	5.378196716308594	2.031169891357422	73.8	96.73210144042969	57.62800598144531	39.088470458984375	59.57485170208386	2996603	2529898	26686	25327	2025-10-08 20:03:04.20962
1298	30.7	2	0.23095703125	0.3837890625	0.49755859375	7.751792907714844	5.383045196533203	2.0262794494628906	73.9	96.73210144042969	57.62794876098633	39.08852767944336	59.57479254854731	3006146	2537814	26766	25402	2025-10-08 20:03:35.251148
1299	33.5	2	0.41259765625	0.42333984375	0.5078125	7.751792907714844	5.379951477050781	2.029327392578125	73.8	96.73210144042969	57.6282958984375	39.08818054199219	59.57515141333574	3015653	2545730	26846	25477	2025-10-08 20:04:06.312641
1300	19.4	2	0.24853515625	0.38134765625	0.490234375	7.751792907714844	5.381961822509766	2.0272674560546875	73.8	96.73210144042969	57.628177642822266	39.08829879760742	59.57502916269352	3025406	2553896	26930	25556	2025-10-08 20:04:37.356836
1301	23.5	2	0.20751953125	0.35986328125	0.478515625	7.751792907714844	5.3752593994140625	2.0339279174804688	73.8	96.73210144042969	57.628543853759766	39.08793258666992	59.57540774532746	3034949	2561812	27010	25631	2025-10-08 20:05:08.397437
1302	21.6	2	0.11376953125	0.31787109375	0.4580078125	7.751792907714844	5.393024444580078	2.01611328125	74	96.73210144042969	57.635807037353516	39.08066940307617	59.582916300900635	3044469	2569728	27090	25706	2025-10-08 20:05:39.444465
1303	32.3	2	0.1826171875	0.31787109375	0.45166015625	7.751792907714844	5.394493103027344	2.014606475830078	74	96.73210144042969	57.63587188720703	39.080604553222656	59.58298334157539	3054215	2577852	27173	25784	2025-10-08 20:06:10.503295
1304	20.1	2	0.109375	0.2861328125	0.43701171875	7.751792907714844	5.392955780029297	2.016101837158203	74	96.73210144042969	57.6358757019043	39.08060073852539	59.5829872851445	3063997	2586018	27257	25863	2025-10-08 20:06:41.537782
1305	18.6	2	0.1279296875	0.27392578125	0.42822265625	7.751792907714844	5.373435974121094	2.0354766845703125	73.7	96.73210144042969	57.63607406616211	39.08040237426758	59.58319235073788	3073747	2594184	27341	25942	2025-10-08 20:07:12.575166
1306	21	2	0.07666015625	0.24658203125	0.41357421875	7.751792907714844	5.372581481933594	2.0362930297851562	73.7	96.73210144042969	57.63602828979492	39.080448150634766	59.583145027908635	3083253	2602100	27421	26017	2025-10-08 20:07:43.63739
1307	25.1	2	0.23779296875	0.26708984375	0.4140625	7.751792907714844	5.392051696777344	2.0167579650878906	74	96.73210144042969	57.63623809814453	39.080238342285156	59.583361924209335	3093036	2610266	27505	26096	2025-10-08 20:08:14.675946
1308	18.6	2	0.201171875	0.255859375	0.4052734375	7.751792907714844	5.355747222900391	2.052959442138672	73.5	96.73210144042969	57.636077880859375	39.08039855957031	59.58319629430699	3103039	2618642	27594	26180	2025-10-08 20:08:45.720377
1309	25.6	2	0.52392578125	0.328125	0.42431640625	7.751792907714844	5.365806579589844	2.0428810119628906	73.6	96.73210144042969	57.63631820678711	39.08015823364258	59.583444739160505	3112813	2626768	27679	26260	2025-10-08 20:09:16.75251
1310	20.8	2	1.43505859375	0.60498046875	0.515625	7.751792907714844	5.352363586425781	2.0562591552734375	73.5	96.73210144042969	57.636192321777344	39.080284118652344	59.58331460138009	3122522	2634852	27763	26339	2025-10-08 20:09:47.788914
1311	20	2	1.22705078125	0.62841796875	0.5263671875	7.751792907714844	5.352893829345703	2.0556793212890625	73.5	96.73210144042969	57.63644790649414	39.08002853393555	59.58357882051003	3132262	2642978	27848	26419	2025-10-08 20:10:18.835199
1312	19.3	2	1.064453125	0.640625	0.53369140625	7.751792907714844	5.358489990234375	2.0500450134277344	73.6	96.73210144042969	57.63650131225586	39.07997512817383	59.583634030477484	3141992	2651104	27933	26499	2025-10-08 20:10:49.8807
1313	45.8	2	0.64453125	0.578125	0.51611328125	7.751792907714844	5.360298156738281	2.0481796264648438	73.6	96.73210144042969	57.636512756347656	39.07996368408203	59.583645861184785	3151753	2659230	28018	26579	2025-10-08 20:11:20.918289
1314	28.4	2	0.5380859375	0.5556640625	0.51025390625	7.751792907714844	5.365497589111328	2.0429420471191406	73.6	96.73210144042969	57.63627243041992	39.080204010009766	59.583397416331266	3161434	2667314	28102	26658	2025-10-08 20:11:51.953628
1315	62.1	2	0.47216796875	0.53466796875	0.50390625	7.751792907714844	5.368000030517578	2.0404014587402344	73.7	96.73210144042969	57.636573791503906	39.07990264892578	59.58370895829045	3171189	2675440	28187	26738	2025-10-08 20:12:22.995939
1316	72.4	2	0.28466796875	0.482421875	0.486328125	7.751792907714844	5.373931884765625	2.0344161987304688	73.8	96.73210144042969	57.636295318603516	39.08018112182617	59.58342107774589	3180918	2683566	28272	26818	2025-10-08 20:12:54.034751
1317	18.9	2	0.28662109375	0.4599609375	0.4775390625	7.751792907714844	5.359836578369141	2.048473358154297	73.6	96.73210144042969	57.636619567871094	39.079856872558594	59.58375628111969	3190394	2691440	28351	26892	2025-10-08 20:13:25.071759
1318	22.7	2	0.17236328125	0.41455078125	0.4599609375	7.751792907714844	5.362396240234375	2.045867919921875	73.6	96.73210144042969	57.63640594482422	39.08007049560547	59.58353544124989	3199914	2699356	28431	26967	2025-10-08 20:13:56.105097
1319	26.3	2	0.26171875	0.41943359375	0.458984375	7.751792907714844	5.361568450927734	2.0466346740722656	73.6	96.73210144042969	57.636234283447266	39.08024215698242	59.58335798064023	3209420	2707272	28511	27042	2025-10-08 20:14:27.14762
1320	19	2	0.1572265625	0.37744140625	0.443359375	7.751792907714844	5.356578826904297	2.051593780517578	73.5	96.73210144042969	57.63624572753906	39.080230712890625	59.583369811347545	3218937	2715188	28591	27117	2025-10-08 20:14:58.186186
1321	19.2	2	0.15185546875	0.3564453125	0.4345703125	7.751792907714844	5.368873596191406	2.03924560546875	73.7	96.73210144042969	57.63631057739258	39.08016586303711	59.583436852022295	3228444	2723104	28671	27192	2025-10-08 20:15:29.223965
1322	18.4	2	0.1640625	0.33251953125	0.42333984375	7.751792907714844	5.366912841796875	2.0411720275878906	73.7	96.73210144042969	57.63619613647461	39.08028030395508	59.58331854494919	3237962	2731020	28751	27267	2025-10-08 20:16:00.252363
1323	21.4	2	0.3037109375	0.34765625	0.42578125	7.751792907714844	5.3664093017578125	2.0416336059570312	73.7	96.73210144042969	57.63624572753906	39.080230712890625	59.583369811347545	3247448	2738894	28830	27341	2025-10-08 20:16:31.286675
1324	22.1	2	0.18310546875	0.31298828125	0.4111328125	7.751792907714844	5.367084503173828	2.040912628173828	73.7	96.73210144042969	57.6364860534668	39.07999038696289	59.58361825620106	3257224	2747060	28914	27420	2025-10-08 20:17:02.326185
1325	20.1	2	0.109375	0.28173828125	0.396484375	7.751792907714844	5.3706512451171875	2.0372886657714844	73.7	96.73210144042969	57.64421844482422	39.07225799560547	59.591611870773974	3266980	2755226	28998	27499	2025-10-08 20:17:33.365783
1326	21.6	2	0.1337890625	0.26953125	0.3876953125	7.751792907714844	5.366950988769531	2.040924072265625	73.7	96.73210144042969	57.644168853759766	39.07230758666992	59.59156060437563	3277118	2763752	29087	27583	2025-10-08 20:18:04.414093
1327	21.2	2	0.31396484375	0.28857421875	0.38720703125	7.751792907714844	5.3619537353515625	2.0458641052246094	73.6	96.73210144042969	57.64448547363281	39.071990966796875	59.59188792061122	3286854	2771876	29170	27661	2025-10-08 20:18:35.446669
1328	33.2	2	0.2578125	0.2763671875	0.37841796875	7.751792907714844	5.365959167480469	2.041820526123047	73.7	96.73210144042969	57.64436340332031	39.072113037109375	59.59176172639991	3296598	2780002	29255	27741	2025-10-08 20:19:06.495055
1329	32.7	2	0.1552734375	0.24853515625	0.36376953125	7.751792907714844	5.3762664794921875	2.0314674377441406	73.8	96.73210144042969	57.644683837890625	39.07179260253906	59.592092986204605	3306585	2788378	29344	27825	2025-10-08 20:19:37.539097
1330	26.5	2	0.24072265625	0.25634765625	0.3623046875	7.751792907714844	5.36614990234375	2.0415496826171875	73.7	96.73210144042969	57.644195556640625	39.07228088378906	59.591588209359344	3316580	2796754	29433	27909	2025-10-08 20:20:08.576423
1331	25	2	0.14453125	0.23046875	0.3505859375	7.751792907714844	5.365550994873047	2.042095184326172	73.7	96.73210144042969	57.64451599121094	39.07196044921875	59.59191946916405	3326561	2805130	29522	27993	2025-10-08 20:20:39.61211
1332	28.6	2	0.21142578125	0.236328125	0.3486328125	7.751792907714844	5.374908447265625	2.032703399658203	73.8	96.73210144042969	57.644229888916016	39.07224655151367	59.59162370148129	3336533	2813506	29611	28077	2025-10-08 20:21:10.648703
1333	24.6	2	0.12744140625	0.21240234375	0.3369140625	7.751792907714844	5.365840911865234	2.0417022705078125	73.7	96.73210144042969	57.64444351196289	39.0720329284668	59.59184454135108	3346547	2821882	29700	28161	2025-10-08 20:21:41.697035
1334	21.7	2	0.15673828125	0.2080078125	0.3310546875	7.751792907714844	5.360912322998047	2.046588897705078	73.6	96.73210144042969	57.64442825317383	39.07204818725586	59.591828767074674	3356276	2830008	29785	28241	2025-10-08 20:22:12.745502
1335	71.8	2	0.09423828125	0.18701171875	0.3193359375	7.751792907714844	5.391700744628906	2.015758514404297	74	96.73210144042969	57.64460754394531	39.071868896484375	59.59201411482253	3366254	2838384	29874	28325	2025-10-08 20:22:43.784637
1336	34.3	2	0.1318359375	0.181640625	0.3115234375	7.751792907714844	5.3814849853515625	2.0259246826171875	73.9	96.73210144042969	57.644432067871094	39.072044372558594	59.59183271064378	3376245	2846760	29963	28409	2025-10-08 20:23:14.833071
1337	23.6	2	0.15283203125	0.1796875	0.3056640625	7.751792907714844	5.377811431884766	2.0295448303222656	73.8	96.73210144042969	57.644649505615234	39.07182693481445	59.592057494082674	3385711	2854634	30042	28483	2025-10-08 20:23:45.868209
1338	23.5	2	0.513671875	0.28369140625	0.33740234375	7.751792907714844	5.375629425048828	2.0316734313964844	73.8	96.73210144042969	57.64427185058594	39.07220458984375	59.591667080741416	3395187	2862508	30121	28557	2025-10-08 20:24:16.907062
1339	24	2	0.3095703125	0.25537109375	0.32568359375	7.751792907714844	5.374725341796875	2.0325469970703125	73.8	96.73210144042969	57.64452362060547	39.07195281982422	59.59192735630226	3404664	2870452	30200	28632	2025-10-08 20:24:47.95302
1340	24.6	2	0.47900390625	0.29638671875	0.3369140625	7.751792907714844	5.375652313232422	2.0315589904785156	73.8	96.73210144042969	57.64447021484375	39.07200622558594	59.591872146334815	3414141	2878326	30279	28706	2025-10-08 20:25:18.98372
1341	22.5	2	0.26513671875	0.26171875	0.3232421875	7.751792907714844	5.371280670166016	2.0358924865722656	73.7	96.73210144042969	57.64475631713867	39.071720123291016	59.592167914017566	3423632	2886200	30358	28780	2025-10-08 20:25:50.042316
1342	30.7	2	0.3427734375	0.2841796875	0.32861328125	7.751792907714844	5.380260467529297	2.026866912841797	73.9	96.73210144042969	57.644596099853516	39.07188034057617	59.59200228411522	3433347	2894324	30441	28858	2025-10-08 20:26:21.07821
1343	32.2	2	0.20654296875	0.255859375	0.31689453125	7.751792907714844	5.372333526611328	2.0347557067871094	73.8	96.73210144042969	57.644874572753906	39.07160186767578	59.59229016465979	3442990	2902394	30523	28936	2025-10-08 20:26:52.139671
1344	43.4	2	0.1865234375	0.24658203125	0.31103515625	7.751792907714844	5.378879547119141	2.028156280517578	73.8	96.73210144042969	57.64462661743164	39.07184982299805	59.59203383266806	3452730	2910518	30606	29014	2025-10-08 20:27:23.182109
1345	21.6	2	0.18603515625	0.23828125	0.30517578125	7.751792907714844	5.375907897949219	2.0310935974121094	73.8	96.73210144042969	57.64493179321289	39.0715446472168	59.592349318196334	3462195	2918392	30685	29088	2025-10-08 20:27:54.218142
1346	21.5	2	0.1650390625	0.22705078125	0.29736328125	7.751792907714844	5.374626159667969	2.0323257446289062	73.8	96.73210144042969	57.64447784423828	39.071998596191406	59.59188003347301	3471671	2926266	30764	29162	2025-10-08 20:28:25.260699
1347	24.9	2	0.09912109375	0.20361328125	0.28564453125	7.751792907714844	5.371295928955078	2.0356216430664062	73.7	96.73210144042969	57.64482879638672	39.07164764404297	59.59224284183055	3481456	2934434	30850	29243	2025-10-08 20:28:56.294416
1348	22.6	2	0.12744140625	0.19970703125	0.27978515625	7.751792907714844	5.369678497314453	2.037189483642578	73.7	96.73210144042969	57.644474029541016	39.07200241088867	59.591876089903906	3491467	2942852	30940	29328	2025-10-08 20:29:27.343821
1349	23.6	2	0.076171875	0.17919921875	0.26904296875	7.751792907714844	5.379119873046875	2.0277023315429688	73.8	96.73210144042969	57.644596099853516	39.07188034057617	59.59200228411522	3501241	2951020	31026	29409	2025-10-08 20:29:58.385782
1350	27.6	2	0.119140625	0.177734375	0.26611328125	7.751792907714844	5.3837432861328125	2.023021697998047	73.9	96.73210144042969	57.64460754394531	39.071868896484375	59.59201411482253	3511209	2959396	31115	29493	2025-10-08 20:30:29.427703
1351	24.9	2	0.212890625	0.18994140625	0.26708984375	7.751792907714844	5.374382019042969	2.0323333740234375	73.8	96.73210144042969	57.6446647644043	39.07181167602539	59.592073268359094	3520967	2967564	31201	29574	2025-10-08 20:31:00.467345
1352	23	2	0.275390625	0.203125	0.26953125	7.751792907714844	5.376140594482422	2.030529022216797	73.8	96.73210144042969	57.64455795288086	39.07191848754883	59.59196284842419	3530988	2975982	31291	29659	2025-10-08 20:31:31.505791
1353	30.1	2	0.49267578125	0.263671875	0.28759765625	7.751792907714844	5.398014068603516	2.0086097717285156	74.1	96.73210144042969	57.64479446411133	39.07168197631836	59.592207349708616	3540997	2984400	31381	29744	2025-10-08 20:32:02.569173
1354	76.6	2	0.5390625	0.3017578125	0.29931640625	7.751792907714844	5.417938232421875	1.9886360168457031	74.3	96.73210144042969	57.6447639465332	39.071712493896484	59.592175801155776	3550559	2992358	31462	29820	2025-10-08 20:32:33.62629
1355	62.6	2	0.3251953125	0.271484375	0.28759765625	7.751792907714844	5.386848449707031	2.0196914672851562	73.9	96.73210144042969	57.64485549926758	39.07162094116211	59.59227044681427	3560577	3000776	31552	29905	2025-10-08 20:33:04.678906
1356	23.8	2	0.33984375	0.28662109375	0.29150390625	7.751792907714844	5.398765563964844	2.007720947265625	74.1	96.73210144042969	57.64472198486328	39.071754455566406	59.59213242189564	3570082	3008692	31632	29980	2025-10-08 20:33:35.719599
1357	22.1	2	0.20458984375	0.2578125	0.27978515625	7.751792907714844	5.39788818359375	2.0085678100585938	74.1	96.73210144042969	57.64503860473633	39.07143783569336	59.59245973813124	3579612	3016608	31712	30055	2025-10-08 20:34:06.769697
1358	35.4	2	0.228515625	0.2626953125	0.279296875	7.751792907714844	5.395652770996094	2.0107383728027344	74.1	96.73210144042969	57.644805908203125	39.07167053222656	59.59221918041592	3589162	3024524	31792	30130	2025-10-08 20:34:37.807431
1359	23.7	2	0.3779296875	0.2998046875	0.2900390625	7.751792907714844	5.398799896240234	2.007549285888672	74.1	96.73210144042969	57.64509582519531	39.071380615234375	59.59251889166779	3598703	3032440	31872	30205	2025-10-08 20:35:08.848078
1360	21.9	2	0.3388671875	0.3017578125	0.2900390625	7.751792907714844	5.396045684814453	2.01025390625	74.1	96.73210144042969	57.64482498168945	39.071651458740234	59.59223889826144	3608471	3040606	31956	30284	2025-10-08 20:35:39.89347
1361	29.3	2	0.41748046875	0.3291015625	0.29833984375	7.751792907714844	5.403224945068359	2.0030136108398438	74.2	96.73210144042969	57.645023345947266	39.07145309448242	59.59244396385483	3617943	3048480	32035	30358	2025-10-08 20:36:10.936517
1362	23.1	2	0.59130859375	0.376953125	0.31396484375	7.751792907714844	5.419620513916016	1.9861717224121094	74.4	96.73210144042969	57.64525604248047	39.07122039794922	59.592684521570135	3627464	3056774	32115	30442	2025-10-08 20:36:41.977688
1363	23.5	2	0.73681640625	0.44775390625	0.3408203125	7.751792907714844	5.445415496826172	1.9603157043457031	74.7	96.73210144042969	57.64549255371094	39.07098388671875	59.592929022854555	3636994	3064690	32195	30517	2025-10-08 20:37:13.023507
1364	27.5	2	0.73291015625	0.46923828125	0.35205078125	7.751792907714844	5.4458160400390625	1.9598579406738281	74.7	96.73210144042969	57.645599365234375	39.07087707519531	59.59303944278946	3646502	3072606	32275	30592	2025-10-08 20:37:44.0652
1365	28	2	0.5107421875	0.439453125	0.34619140625	7.751792907714844	5.4510498046875	1.9545745849609375	74.8	96.73210144042969	57.64569854736328	39.070777893066406	59.59314197558615	3656287	3080772	32359	30671	2025-10-08 20:38:15.102761
1366	20.3	2	0.73876953125	0.4892578125	0.36572265625	7.751792907714844	5.449047088623047	1.9565353393554688	74.8	96.73210144042969	57.64529037475586	39.07118606567383	59.592720013692066	3666011	3088896	32442	30749	2025-10-08 20:38:46.154983
1367	26	2	0.5146484375	0.45751953125	0.359375	7.751792907714844	5.449680328369141	1.9558448791503906	74.8	96.73210144042969	57.645347595214844	39.071128845214844	59.59277916722863	3675478	3096770	32521	30823	2025-10-08 20:39:17.191621
1368	22.5	2	0.310546875	0.412109375	0.34765625	7.751792907714844	5.445003509521484	1.9604721069335938	74.7	96.73210144042969	57.64530944824219	39.0711669921875	59.59273973153759	3684965	3104644	32600	30897	2025-10-08 20:39:48.240115
1369	22.5	2	0.341796875	0.40478515625	0.34765625	7.751792907714844	5.449985504150391	1.9554367065429688	74.8	96.73210144042969	57.64559555053711	39.07088088989258	59.593035499220356	3694435	3112518	32679	30971	2025-10-08 20:40:19.306074
1370	33.3	2	0.27392578125	0.380859375	0.341796875	7.751792907714844	5.433082580566406	1.9722900390625	74.6	96.73210144042969	57.64570236206055	39.07077407836914	59.593145919155255	3703891	3120392	32758	31045	2025-10-08 20:40:50.359789
1371	24.5	2	0.30615234375	0.37109375	0.33984375	7.751792907714844	5.434627532958984	1.9706497192382812	74.6	96.73210144042969	57.64592742919922	39.07054901123047	59.59337858973237	3713362	3128266	32837	31119	2025-10-08 20:41:21.414275
1372	21.6	2	0.65478515625	0.447265625	0.36669921875	7.751792907714844	5.432308197021484	1.972869873046875	74.5	96.73210144042969	57.64582443237305	39.07065200805664	59.59327211336657	3723096	3136432	32920	31198	2025-10-08 20:41:52.450629
1373	80.4	2	0.73486328125	0.48388671875	0.38037109375	7.751792907714844	5.446632385253906	1.9584846496582031	74.7	96.73210144042969	57.646183013916016	39.07029342651367	59.5936428088623	3732559	3144306	32999	31272	2025-10-08 20:42:23.501437
1374	81.4	2	0.52490234375	0.453125	0.37158203125	7.751792907714844	5.457508087158203	1.94757080078125	74.9	96.73210144042969	57.64593505859375	39.07054138183594	59.59338647687057	3742906	3153101	33079	31347	2025-10-08 20:42:54.567238
1375	34.3	2	0.8974609375	0.53955078125	0.4013671875	7.751792907714844	5.442230224609375	1.9628181457519531	74.7	96.73210144042969	57.64607620239258	39.07040023803711	59.59353238892741	3753282	3161896	33159	31422	2025-10-08 20:43:25.608105
1376	25.8	2	0.57958984375	0.4951171875	0.39013671875	7.751792907714844	5.423137664794922	1.9818687438964844	74.4	96.73210144042969	57.6458625793457	39.070613861083984	59.5933115490576	3762759	3169770	33238	31496	2025-10-08 20:43:56.651916
1377	28.6	2	0.40283203125	0.46240234375	0.38134765625	7.751792907714844	5.427928924560547	1.9770240783691406	74.5	96.73210144042969	57.6462287902832	39.070247650146484	59.593690131691545	3772474	3177894	33321	31574	2025-10-08 20:44:27.704286
1378	22.7	2	0.31103515625	0.43359375	0.37255859375	7.751792907714844	5.422237396240234	1.9826774597167969	74.4	96.73210144042969	57.64585494995117	39.070621490478516	59.59330366191939	3781978	3185768	33400	31648	2025-10-08 20:44:58.763256
1379	23.1	2	0.2451171875	0.40673828125	0.36376953125	7.751792907714844	5.425056457519531	1.9798202514648438	74.5	96.73210144042969	57.65373992919922	39.06273651123047	59.60145501925644	3791704	3193892	33483	31726	2025-10-08 20:45:29.801191
1380	24.1	2	0.48681640625	0.447265625	0.3779296875	7.751792907714844	5.500720977783203	1.9041061401367188	75.4	96.73210144042969	57.65386962890625	39.06260681152344	59.60158910060597	3801170	3201766	33562	31800	2025-10-08 20:46:00.839429
1381	30	2	0.6396484375	0.49169921875	0.39404296875	7.751792907714844	5.501152038574219	1.9036216735839844	75.4	96.73210144042969	57.65412521362305	39.06235122680664	59.60185331973591	3810656	3209640	33641	31874	2025-10-08 20:46:31.880043
1382	31.8	2	0.38671875	0.443359375	0.37939453125	7.751792907714844	5.494190216064453	1.9105186462402344	75.4	96.73210144042969	57.65421676635742	39.062259674072266	59.601947965394395	3820372	3217764	33724	31952	2025-10-08 20:47:02.939662
1383	23.1	2	0.4541015625	0.44873046875	0.38134765625	7.751792907714844	5.510372161865234	1.8943138122558594	75.6	96.73210144042969	57.65463638305664	39.06184005737305	59.60238175799578	3829848	3225638	33803	32026	2025-10-08 20:47:33.976205
1384	22.7	2	0.6376953125	0.4873046875	0.39453125	7.751792907714844	5.510097503662109	1.89453125	75.6	96.73210144042969	57.654632568359375	39.06184387207031	59.602377814426674	3839361	3233512	33882	32100	2025-10-08 20:48:05.041005
1385	33.2	2	0.9169921875	0.56201171875	0.421875	7.751792907714844	5.513393402099609	1.8911705017089844	75.6	96.73210144042969	57.65484619140625	39.06163024902344	59.60259865429648	3848840	3241386	33961	32174	2025-10-08 20:48:36.104455
1386	31.2	2	0.62255859375	0.52294921875	0.4130859375	7.751792907714844	5.5313873291015625	1.8730812072753906	75.8	96.73210144042969	57.655147552490234	39.06132888793945	59.602910196255664	3858367	3249302	34041	32249	2025-10-08 20:49:07.151276
1387	81.6	2	0.3759765625	0.4716796875	0.3984375	7.751792907714844	5.489768981933594	1.9146957397460938	75.3	96.73210144042969	57.655235290527344	39.061241149902344	59.60300089834504	3867750	3257598	34123	32340	2025-10-08 20:49:38.200185
1388	35.7	2	0.494140625	0.49072265625	0.40673828125	7.751792907714844	5.498931884765625	1.9041213989257812	75.4	96.73210144042969	57.65516662597656	39.061309814453125	59.602929914101175	3878984	3267540	34203	32421	2025-10-08 20:50:09.254324
1389	37.5	2	0.5390625	0.49267578125	0.40869140625	7.751792907714844	5.512306213378906	1.8906173706054688	75.6	96.73210144042969	57.65532302856445	39.061153411865234	59.603091600434425	3888661	3276044	34287	32510	2025-10-08 20:50:40.314996
1390	30.3	2	0.298828125	0.4365234375	0.3916015625	7.751792907714844	5.514720916748047	1.888153076171875	75.6	96.73210144042969	57.65532684326172	39.06114959716797	59.60309554400352	3898168	3283960	34367	32585	2025-10-08 20:51:11.362403
1391	47.2	2	0.4326171875	0.45751953125	0.3994140625	7.751792907714844	5.5190277099609375	1.8837814331054688	75.7	96.73210144042969	57.65555191040039	39.0609245300293	59.60332821458064	3907887	3292044	34451	32664	2025-10-08 20:51:42.418259
1392	74	2	0.60595703125	0.50634765625	0.41796875	7.751792907714844	5.521759033203125	1.8810195922851562	75.7	96.73210144042969	57.65578079223633	39.06069564819336	59.60356482872685	3917388	3299918	34530	32738	2025-10-08 20:52:13.476708
1393	30.6	2	0.36572265625	0.45654296875	0.4033203125	7.751792907714844	5.522914886474609	1.8797988891601562	75.8	96.73210144042969	57.65607452392578	39.060401916503906	59.60386848354783	3927366	3308294	34619	32822	2025-10-08 20:52:44.507875
1394	21.1	2	0.61328125	0.50830078125	0.421875	7.751792907714844	5.231029510498047	2.172576904296875	72	96.73210144042969	57.65612030029297	39.06035614013672	59.60391580637706	3937080	3316649	34701	32908	2025-10-08 20:53:15.5599
1395	24.2	2	0.46044921875	0.48291015625	0.41650390625	7.751792907714844	5.49462890625	1.9079856872558594	75.4	96.73210144042969	57.656410217285156	39.06006622314453	59.60421551762893	3948061	3325892	34793	32993	2025-10-08 20:53:46.605171
1396	24	2	0.388671875	0.466796875	0.41357421875	7.751792907714844	5.501678466796875	1.9008903503417969	75.5	96.73210144042969	57.65633010864258	39.06014633178711	59.60413270267776	3957673	3333892	34875	33070	2025-10-08 20:54:17.64266
1397	21.1	2	0.41748046875	0.46875	0.416015625	7.751792907714844	5.485363006591797	1.9171409606933594	75.3	96.73210144042969	57.65666961669922	39.05980682373047	59.60448368032798	3967398	3342018	34960	33150	2025-10-08 20:54:48.696551
1398	46.2	2	0.51513671875	0.48828125	0.42431640625	7.751792907714844	5.422130584716797	1.9803047180175781	74.5	96.73210144042969	57.656768798828125	39.05970764160156	59.60458621312467	3977121	3350144	35045	33230	2025-10-08 20:55:19.745618
1399	29	2	0.642578125	0.52197265625	0.4384765625	7.751792907714844	5.436344146728516	1.966064453125	74.6	96.73210144042969	57.6568717956543	39.05960464477539	59.60469268949047	3986838	3358270	35130	33310	2025-10-08 20:55:50.792868
\.


--
-- Name: alerts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.alerts_id_seq', 13, true);


--
-- Name: service_health_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_health_id_seq', 8394, true);


--
-- Name: system_metrics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.system_metrics_id_seq', 1399, true);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: service_health service_health_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_health
    ADD CONSTRAINT service_health_pkey PRIMARY KEY (id);


--
-- Name: system_metrics system_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_metrics
    ADD CONSTRAINT system_metrics_pkey PRIMARY KEY (id);


--
-- Name: ix_alerts_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_alerts_id ON public.alerts USING btree (id);


--
-- Name: ix_alerts_triggered_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_alerts_triggered_at ON public.alerts USING btree (triggered_at);


--
-- Name: ix_service_health_checked_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_service_health_checked_at ON public.service_health USING btree (checked_at);


--
-- Name: ix_service_health_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_service_health_id ON public.service_health USING btree (id);


--
-- Name: ix_service_health_service_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_service_health_service_name ON public.service_health USING btree (service_name);


--
-- Name: ix_system_metrics_collected_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_system_metrics_collected_at ON public.system_metrics USING btree (collected_at);


--
-- Name: ix_system_metrics_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_system_metrics_id ON public.system_metrics USING btree (id);


--
-- PostgreSQL database dump complete
--

