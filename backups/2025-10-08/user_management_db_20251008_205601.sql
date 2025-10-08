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
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    user_id integer,
    action character varying(50) NOT NULL,
    resource_type character varying(50),
    resource_id character varying(100),
    details text,
    ip_address character varying(45),
    user_agent character varying(500),
    "timestamp" timestamp without time zone
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.audit_logs_id_seq OWNER TO postgres;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_profiles (
    id integer NOT NULL,
    user_id integer,
    institution character varying(200),
    department character varying(200),
    "position" character varying(100),
    research_interests text,
    phone_number character varying(20),
    country character varying(100),
    bio text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.user_profiles OWNER TO postgres;

--
-- Name: user_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_profiles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_profiles_id_seq OWNER TO postgres;

--
-- Name: user_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_profiles_id_seq OWNED BY public.user_profiles.id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_roles (
    id integer NOT NULL,
    user_id integer,
    role character varying(50) NOT NULL,
    service_id integer,
    granted_by_id integer,
    granted_at timestamp without time zone,
    expires_at timestamp without time zone,
    is_active boolean
);


ALTER TABLE public.user_roles OWNER TO postgres;

--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_roles_id_seq OWNER TO postgres;

--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_roles_id_seq OWNED BY public.user_roles.id;


--
-- Name: user_service_credentials; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_service_credentials (
    id integer NOT NULL,
    user_id integer NOT NULL,
    service_id integer NOT NULL,
    credential_type character varying(50),
    api_token text,
    oauth_token text,
    oauth_refresh_token text,
    username character varying(255),
    password text,
    label character varying(100),
    is_active boolean,
    is_verified boolean,
    last_verified_at timestamp without time zone,
    last_used_at timestamp without time zone,
    verification_error text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    expires_at timestamp without time zone
);


ALTER TABLE public.user_service_credentials OWNER TO postgres;

--
-- Name: user_service_credentials_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_service_credentials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_service_credentials_id_seq OWNER TO postgres;

--
-- Name: user_service_credentials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_service_credentials_id_seq OWNED BY public.user_service_credentials.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    uuid uuid,
    username character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    first_name character varying(150) NOT NULL,
    last_name character varying(150) NOT NULL,
    hashed_password character varying(128) NOT NULL,
    is_active boolean,
    is_staff boolean,
    is_superuser boolean,
    date_joined timestamp without time zone,
    last_login timestamp without time zone
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: user_profiles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_profiles ALTER COLUMN id SET DEFAULT nextval('public.user_profiles_id_seq'::regclass);


--
-- Name: user_roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN id SET DEFAULT nextval('public.user_roles_id_seq'::regclass);


--
-- Name: user_service_credentials id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_service_credentials ALTER COLUMN id SET DEFAULT nextval('public.user_service_credentials_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (id, user_id, action, resource_type, resource_id, details, ip_address, user_agent, "timestamp") FROM stdin;
1	1	user_registered	user	1	\N	172.19.0.1	curl/7.81.0	2025-10-08 15:46:05.631366
2	1	login_success	\N	\N	\N	172.19.0.1	curl/7.81.0	2025-10-08 16:09:19.504413
3	1	login_success	\N	\N	\N	172.19.0.1	curl/7.81.0	2025-10-08 16:11:30.128431
4	1	login_success	\N	\N	\N	172.19.0.10	curl/7.81.0	2025-10-08 16:16:50.210313
5	1	login_success	\N	\N	\N	172.19.0.10	curl/7.81.0	2025-10-08 16:17:55.978099
6	1	login_success	\N	\N	\N	172.19.0.7	curl/7.81.0	2025-10-08 17:02:23.293648
7	1	login_success	\N	\N	\N	172.19.0.7	curl/7.81.0	2025-10-08 17:03:18.554872
8	1	login_success	\N	\N	\N	172.19.0.7	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/140.0.0.0 Safari/537.36	2025-10-08 17:03:46.215957
9	1	login_success	\N	\N	\N	172.19.0.7	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.1 Safari/605.1.15	2025-10-08 17:14:25.128213
11	1	login_success	\N	\N	\N	172.19.0.10	curl/7.81.0	2025-10-08 17:21:22.682338
12	1	login_success	\N	\N	\N	172.19.0.10	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	2025-10-08 18:24:32.858855
13	\N	login_failed	\N	\N	Failed login attempt for username: admin	172.19.0.10	curl/7.81.0	2025-10-08 18:38:33.540188
14	1	login_success	\N	\N	\N	172.19.0.10	curl/7.81.0	2025-10-08 18:38:49.619537
15	1	login_success	\N	\N	\N	172.19.0.9	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.1 Safari/605.1.15	2025-10-08 19:14:55.773031
16	1	login_success	\N	\N	\N	172.19.0.9	curl/7.81.0	2025-10-08 19:16:10.997083
17	1	login_success	\N	\N	\N	172.19.0.9	curl/7.81.0	2025-10-08 19:16:47.842964
18	1	login_success	\N	\N	\N	172.19.0.9	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	2025-10-08 19:19:19.072092
19	1	login_success	\N	\N	\N	172.19.0.9	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	2025-10-08 19:37:41.533045
20	1	login_success	\N	\N	\N	172.19.0.9	curl/7.81.0	2025-10-08 19:42:47.372843
21	1	login_success	\N	\N	\N	172.19.0.9	curl/7.81.0	2025-10-08 19:44:27.337154
22	1	login_success	\N	\N	\N	172.19.0.9	curl/7.81.0	2025-10-08 19:46:01.780809
23	1	create_service_credential	service_credential	1	Service ID: 1	\N	\N	2025-10-08 20:41:30.284434
\.


--
-- Data for Name: user_profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_profiles (id, user_id, institution, department, "position", research_interests, phone_number, country, bio, created_at, updated_at) FROM stdin;
1	1	\N	\N	\N	\N	\N	\N	\N	2025-10-08 15:46:05.621119	2025-10-08 15:46:05.621121
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_roles (id, user_id, role, service_id, granted_by_id, granted_at, expires_at, is_active) FROM stdin;
\.


--
-- Data for Name: user_service_credentials; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_service_credentials (id, user_id, service_id, credential_type, api_token, oauth_token, oauth_refresh_token, username, password, label, is_active, is_verified, last_verified_at, last_used_at, verification_error, created_at, updated_at, expires_at) FROM stdin;
1	1	1	api_token	eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJtYW1hbmEiLCJtYWlsIjoibWFtYW5hLm1iaXlhdmFuZ2FAdWN0LmFjLnphIiwicm9sZXMiOltdLCJpc3MiOiJjbG91ZGdlbmUiLCJ0b2tlbl90eXBlIjoiQVBJX1RPS0VOIiwibmJmIjoxNzU5NzQxMzk4LCJhcGlfaGFzaCI6Im9ET1lsb3JzTmE5MDdJTFZDQmxtRnFwVUNzR3Q0aCIsIm5hbWUiOiJtYW1hbmEiLCJhcGkiOnRydWUsImV4cCI6MTc2MjMzMzM5OCwiaWF0IjoxNzU5NzQxMzk4LCJ1c2VybmFtZSI6Im1hbWFuYSJ9.3wdGNn-2m3q6RVPFwBwVpZasixoBjXqSGe4QLGWUEL0	\N	\N	\N	\N	\N	t	f	\N	2025-10-08 20:51:19.864634	\N	2025-10-08 20:41:30.267697	2025-10-08 20:51:19.864992	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, uuid, username, email, first_name, last_name, hashed_password, is_active, is_staff, is_superuser, date_joined, last_login) FROM stdin;
1	df175d1c-3161-49f3-8c5d-1931053775b6	admin	admin@example.com	Admin	User	$2b$12$FAWdgjY4H45YWmEaObTzOOK6NJoTUBgYyLIW8uCvkewrRj6grJa9u	t	f	f	2025-10-08 15:46:05.607238	2025-10-08 19:46:01.770647
\.


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 23, true);


--
-- Name: user_profiles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_profiles_id_seq', 1, false);


--
-- Name: user_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_roles_id_seq', 1, false);


--
-- Name: user_service_credentials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_service_credentials_id_seq', 1, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: user_service_credentials uq_user_service_credential; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_service_credentials
    ADD CONSTRAINT uq_user_service_credential UNIQUE (user_id, service_id);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);


--
-- Name: user_profiles user_profiles_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_user_id_key UNIQUE (user_id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_service_credentials user_service_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_service_credentials
    ADD CONSTRAINT user_service_credentials_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: ix_audit_logs_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_audit_logs_id ON public.audit_logs USING btree (id);


--
-- Name: ix_audit_logs_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_audit_logs_timestamp ON public.audit_logs USING btree ("timestamp");


--
-- Name: ix_user_profiles_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_user_profiles_id ON public.user_profiles USING btree (id);


--
-- Name: ix_user_roles_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_user_roles_id ON public.user_roles USING btree (id);


--
-- Name: ix_user_service_credentials_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_user_service_credentials_id ON public.user_service_credentials USING btree (id);


--
-- Name: ix_user_service_credentials_service_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_user_service_credentials_service_id ON public.user_service_credentials USING btree (service_id);


--
-- Name: ix_user_service_credentials_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_user_service_credentials_user_id ON public.user_service_credentials USING btree (user_id);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- Name: ix_users_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_users_username ON public.users USING btree (username);


--
-- Name: ix_users_uuid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_users_uuid ON public.users USING btree (uuid);


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_profiles user_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_roles user_roles_granted_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_granted_by_id_fkey FOREIGN KEY (granted_by_id) REFERENCES public.users(id);


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_service_credentials user_service_credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_service_credentials
    ADD CONSTRAINT user_service_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

