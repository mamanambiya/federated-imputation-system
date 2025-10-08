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
-- Name: email_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_templates (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    subject character varying(200) NOT NULL,
    html_content text NOT NULL,
    text_content text,
    variables json,
    is_active boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.email_templates OWNER TO postgres;

--
-- Name: email_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.email_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.email_templates_id_seq OWNER TO postgres;

--
-- Name: email_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.email_templates_id_seq OWNED BY public.email_templates.id;


--
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_preferences (
    id integer NOT NULL,
    user_id integer NOT NULL,
    email_enabled boolean,
    web_enabled boolean,
    sms_enabled boolean,
    job_status_updates boolean,
    system_alerts boolean,
    security_alerts boolean,
    maintenance_notices boolean,
    digest_frequency character varying(20),
    quiet_hours_start character varying(5),
    quiet_hours_end character varying(5),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.notification_preferences OWNER TO postgres;

--
-- Name: notification_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notification_preferences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notification_preferences_id_seq OWNER TO postgres;

--
-- Name: notification_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notification_preferences_id_seq OWNED BY public.notification_preferences.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    type character varying(50) NOT NULL,
    title character varying(200) NOT NULL,
    message text NOT NULL,
    data json,
    channels json,
    is_read boolean,
    is_sent boolean,
    sent_at timestamp without time zone,
    read_at timestamp without time zone,
    priority character varying(20),
    scheduled_for timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    expires_at timestamp without time zone
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_id_seq OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: email_templates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_templates ALTER COLUMN id SET DEFAULT nextval('public.email_templates_id_seq'::regclass);


--
-- Name: notification_preferences id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_preferences ALTER COLUMN id SET DEFAULT nextval('public.notification_preferences_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Data for Name: email_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.email_templates (id, name, subject, html_content, text_content, variables, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: notification_preferences; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification_preferences (id, user_id, email_enabled, web_enabled, sms_enabled, job_status_updates, system_alerts, security_alerts, maintenance_notices, digest_frequency, quiet_hours_start, quiet_hours_end, created_at, updated_at) FROM stdin;
1	1	t	t	f	t	t	t	t	immediate	\N	\N	2025-10-08 20:36:32.521093	2025-10-08 20:36:32.521096
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, user_id, type, title, message, data, channels, is_read, is_sent, sent_at, read_at, priority, scheduled_for, created_at, updated_at, expires_at) FROM stdin;
1	1	job_status_update	Job Queued	Your job 'Test Job - Jobs Page Fix Verification' is now JobStatus.QUEUED	{"job_id": "b973f274-60ce-4999-937b-4307d56f43a0", "job_name": "Test Job - Jobs Page Fix Verification", "status": "queued", "progress": 0}	["web", "email"]	f	t	2025-10-08 20:36:32.533471	\N	normal	\N	2025-10-08 20:36:32.467308	2025-10-08 20:36:32.534777	\N
2	1	job_status_update	Job Running	Your job 'Test Job - Jobs Page Fix Verification' is now running	{"job_id": "b973f274-60ce-4999-937b-4307d56f43a0", "job_name": "Test Job - Jobs Page Fix Verification", "status": "running", "progress": 0}	["web", "email"]	f	t	2025-10-08 20:36:32.713656	\N	normal	\N	2025-10-08 20:36:32.702129	2025-10-08 20:36:32.713952	\N
3	1	job_status_update	Job Failed	Your job 'Test Job - Jobs Page Fix Verification' is now failed	{"job_id": "b973f274-60ce-4999-937b-4307d56f43a0", "job_name": "Test Job - Jobs Page Fix Verification", "status": "failed", "progress": 0}	["web", "email"]	f	t	2025-10-08 20:36:33.087028	\N	normal	\N	2025-10-08 20:36:33.075349	2025-10-08 20:36:33.087292	\N
4	1	job_status_update	Job Queued	Your job 'H3Africa Test Job - With Valid Credentials' is now JobStatus.QUEUED	{"job_id": "078966cd-b24c-42c6-a564-3bb9ee9153a5", "job_name": "H3Africa Test Job - With Valid Credentials", "status": "queued", "progress": 0}	["web", "email"]	f	t	2025-10-08 20:41:30.580338	\N	normal	\N	2025-10-08 20:41:30.56897	2025-10-08 20:41:30.580636	\N
5	1	job_status_update	Job Running	Your job 'H3Africa Test Job - With Valid Credentials' is now running	{"job_id": "078966cd-b24c-42c6-a564-3bb9ee9153a5", "job_name": "H3Africa Test Job - With Valid Credentials", "status": "running", "progress": 0}	["web", "email"]	f	t	2025-10-08 20:41:30.657083	\N	normal	\N	2025-10-08 20:41:30.644165	2025-10-08 20:41:30.657363	\N
6	1	job_status_update	Job Running	Your job 'H3Africa Test Job - With Valid Credentials' is now running	{"job_id": "078966cd-b24c-42c6-a564-3bb9ee9153a5", "job_name": "H3Africa Test Job - With Valid Credentials", "status": "running", "progress": 10}	["web", "email"]	f	t	2025-10-08 20:41:31.76017	\N	normal	\N	2025-10-08 20:41:31.751568	2025-10-08 20:41:31.76049	\N
7	1	job_status_update	Job Failed	Your job 'H3Africa Test Job - With Valid Credentials' is now failed	{"job_id": "078966cd-b24c-42c6-a564-3bb9ee9153a5", "job_name": "H3Africa Test Job - With Valid Credentials", "status": "failed", "progress": 10}	["web", "email"]	f	t	2025-10-08 20:42:31.996532	\N	normal	\N	2025-10-08 20:42:31.985649	2025-10-08 20:42:31.996913	\N
8	1	job_status_update	Job Queued	Your job 'Event Loop Fix Test Job' is now JobStatus.QUEUED	{"job_id": "454251d5-f900-45fa-b973-98728d7bd9c3", "job_name": "Event Loop Fix Test Job", "status": "queued", "progress": 0}	["web", "email"]	f	t	2025-10-08 20:50:18.732106	\N	normal	\N	2025-10-08 20:50:18.719587	2025-10-08 20:50:18.732507	\N
9	1	job_status_update	Job Running	Your job 'Event Loop Fix Test Job' is now running	{"job_id": "454251d5-f900-45fa-b973-98728d7bd9c3", "job_name": "Event Loop Fix Test Job", "status": "running", "progress": 0}	["web", "email"]	f	t	2025-10-08 20:50:18.855247	\N	normal	\N	2025-10-08 20:50:18.846794	2025-10-08 20:50:18.855562	\N
10	1	job_status_update	Job Running	Your job 'Event Loop Fix Test Job' is now running	{"job_id": "454251d5-f900-45fa-b973-98728d7bd9c3", "job_name": "Event Loop Fix Test Job", "status": "running", "progress": 10}	["web", "email"]	f	t	2025-10-08 20:50:19.718113	\N	normal	\N	2025-10-08 20:50:19.709073	2025-10-08 20:50:19.718458	\N
11	1	job_status_update	Job Failed	Your job 'Event Loop Fix Test Job' is now failed	{"job_id": "454251d5-f900-45fa-b973-98728d7bd9c3", "job_name": "Event Loop Fix Test Job", "status": "failed", "progress": 10}	["web", "email"]	f	t	2025-10-08 20:51:20.002434	\N	normal	\N	2025-10-08 20:51:19.987933	2025-10-08 20:51:20.002798	\N
\.


--
-- Name: email_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.email_templates_id_seq', 1, false);


--
-- Name: notification_preferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notification_preferences_id_seq', 1, true);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_id_seq', 11, true);


--
-- Name: email_templates email_templates_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_name_key UNIQUE (name);


--
-- Name: email_templates email_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (id);


--
-- Name: notification_preferences notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: ix_email_templates_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_email_templates_id ON public.email_templates USING btree (id);


--
-- Name: ix_notification_preferences_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_notification_preferences_id ON public.notification_preferences USING btree (id);


--
-- Name: ix_notification_preferences_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_notification_preferences_user_id ON public.notification_preferences USING btree (user_id);


--
-- Name: ix_notifications_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_notifications_created_at ON public.notifications USING btree (created_at);


--
-- Name: ix_notifications_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_notifications_id ON public.notifications USING btree (id);


--
-- Name: ix_notifications_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_notifications_user_id ON public.notifications USING btree (user_id);


--
-- PostgreSQL database dump complete
--

