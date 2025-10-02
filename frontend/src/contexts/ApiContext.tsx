import React, { createContext, useContext, ReactNode } from 'react';
import axios, { AxiosInstance, AxiosResponse } from 'axios';

// API Response Types
export interface ImputationService {
  id: number;
  name: string;
  service_type: 'h3africa' | 'michigan' | 'ga4gh' | 'dnastack' | 'custom';
  api_type?: 'michigan' | 'ga4gh' | 'dnastack' | 'custom';
  base_url?: string; // Microservices field
  api_url?: string; // Legacy Django field - for backward compatibility
  api_config?: any;
  description: string;
  version?: string;
  location?: string;
  continent?: string;
  is_active: boolean;
  is_available?: boolean;
  requires_auth?: boolean; // Microservices field
  api_key_required?: boolean; // Legacy Django field - for backward compatibility
  auth_type?: string;
  max_file_size_mb: number;
  supported_formats: string[];
  supported_builds?: string[]; // May not exist in legacy responses
  reference_panels_count?: number; // May not exist in microservices responses
  last_health_check?: string;
  health_status?: string;
  response_time_ms?: number;
  error_message?: string;
  created_at: string;
  updated_at: string;
}

export interface ReferencePanel {
  id: number;
  name: string;
  panel_id: string;
  description: string;
  population: string;
  build: string;
  samples_count: number;
  variants_count: number;
  is_active: boolean;
  service: number;
  service_name: string;
  service_type: string;
  created_at: string;
  updated_at: string;
}

export interface ImputationJob {
  id: string;
  name: string;
  description: string;
  user: {
    id: number;
    username: string;
    email: string;
    first_name: string;
    last_name: string;
  };
  service: ImputationService;
  reference_panel: ReferencePanel;
  input_format: string;
  build: string;
  phasing: boolean;
  population: string;
  status: 'pending' | 'queued' | 'running' | 'completed' | 'failed' | 'cancelled';
  progress_percentage: number;
  external_job_id: string;
  created_at: string;
  updated_at: string;
  started_at?: string;
  completed_at?: string;
  duration_display?: string;
  error_message?: string;
  input_file_size_display?: string;
  status_updates?: JobStatusUpdate[];
  files?: ResultFile[];
}

export interface JobStatusUpdate {
  id: number;
  status: string;
  progress_percentage: number;
  message: string;
  timestamp: string;
  external_data: any;
}

export interface ResultFile {
  id: number;
  file_type: 'imputed_data' | 'quality_report' | 'log_file' | 'summary' | 'metadata';
  filename: string;
  file_path: string;
  download_url: string;
  file_size: number;
  file_size_display: string;
  checksum: string;
  is_available: boolean;
  expires_at?: string;
  created_at: string;
}

export interface DashboardStats {
  job_stats: {
    total: number;
    completed: number;
    running: number;
    failed: number;
    success_rate: number;
  };
  service_stats: {
    available_services: number;
    accessible_services: number;
  };
  recent_jobs: ImputationJob[];
  status?: string;
  message?: string;
}

// API Context
interface ApiContextType {
  api: AxiosInstance;
  apiCall: (endpoint: string, options?: RequestInit) => Promise<any>;

  // Services
  getServices: () => Promise<ImputationService[]>;
  getService: (id: number) => Promise<ImputationService>;
  createService: (data: any) => Promise<ImputationService>;
  updateService: (id: number, data: any) => Promise<ImputationService>;
  deleteService: (id: number) => Promise<void>;
  syncReferencePanels: (serviceId: number) => Promise<{ message: string; task_id: string }>;

  // Reference Panels
  getReferencePanels: (serviceId?: number, population?: string, build?: string) => Promise<ReferencePanel[]>;
  getServiceReferencePanels: (serviceId: number) => Promise<ReferencePanel[]>;

  // Jobs
  getJobs: (status?: string, serviceId?: number, search?: string) => Promise<ImputationJob[]>;
  getJob: (id: string) => Promise<ImputationJob>;
  createJob: (data: FormData) => Promise<ImputationJob>;
  cancelJob: (id: string) => Promise<{ message: string; task_id: string }>;
  retryJob: (id: string) => Promise<{ message: string; task_id: string }>;
  getJobStatusUpdates: (id: string) => Promise<JobStatusUpdate[]>;
  getJobFiles: (id: string) => Promise<ResultFile[]>;
  downloadFile: (jobId: string, fileId: number) => Promise<{ download_url: string; filename: string; file_size: number }>;

  // Dashboard
  getDashboardStats: () => Promise<DashboardStats>;
  getServicesOverview: () => Promise<any[]>;
}

const ApiContext = createContext<ApiContextType | undefined>(undefined);

// Create axios instance for microservices architecture
const createApiInstance = (): AxiosInstance => {
  // API Gateway URL - all requests go through the gateway
  const API_GATEWAY_URL = process.env.REACT_APP_API_BASE_URL || process.env.REACT_APP_API_URL || 'http://localhost:8000';

  const instance = axios.create({
    baseURL: `${API_GATEWAY_URL}/api`,
    withCredentials: true,
    headers: {
      'Content-Type': 'application/json',
      'X-Client-Type': 'web-frontend',
      'X-Client-Version': '1.0.0',
    },
    timeout: 30000, // 30 second timeout
  });

  // Add request interceptor for authentication
  instance.interceptors.request.use(
    (config) => {
      // Add JWT token to Authorization header if available
      const token = localStorage.getItem('access_token');
      if (token) {
        config.headers['Authorization'] = `Bearer ${token}`;
      }

      // Add CSRF token if available
      const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.getAttribute('content');
      if (csrfToken) {
        config.headers['X-CSRFToken'] = csrfToken;
      }
      return config;
    },
    (error) => {
      return Promise.reject(error);
    }
  );

  return instance;
};

export const ApiProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const api = createApiInstance();

  // Generic API call function
  const apiCall = async (endpoint: string, options?: RequestInit): Promise<any> => {
    const url = endpoint.startsWith('/api/') ? endpoint.substring(5) : endpoint;
    const config = {
      method: options?.method || 'GET',
      ...options,
    };

    if (config.method === 'GET') {
      const response = await api.get(url);
      return response.data;
    } else if (config.method === 'POST') {
      const response = await api.post(url, options?.body ? JSON.parse(options.body as string) : undefined);
      return response.data;
    } else if (config.method === 'PATCH') {
      const response = await api.patch(url, options?.body ? JSON.parse(options.body as string) : undefined);
      return response.data;
    } else if (config.method === 'DELETE') {
      const response = await api.delete(url);
      return response.data;
    }
  };

  // Services
  const getServices = async (): Promise<ImputationService[]> => {
    const response = await api.get('/services/');
    // Handle paginated response
    let services = response.data.results !== undefined ? response.data.results : response.data;

    // Add backward compatibility mapping
    services = services.map((service: ImputationService) => {
      if (service.base_url && !service.api_url) {
        service.api_url = service.base_url;
      }
      if (service.api_key_required === undefined && service.requires_auth !== undefined) {
        service.api_key_required = service.requires_auth;
      }
      if (service.reference_panels_count === undefined) {
        service.reference_panels_count = 0;
      }
      return service;
    });

    return services;
  };

  const getService = async (id: number): Promise<ImputationService> => {
    const response: AxiosResponse<ImputationService> = await api.get(`/services/${id}/`);
    // Add backward compatibility mapping
    const service = response.data;
    if (service.base_url && !service.api_url) {
      service.api_url = service.base_url;
    }
    if (service.api_key_required === undefined && service.requires_auth !== undefined) {
      service.api_key_required = service.requires_auth;
    }
    if (service.reference_panels_count === undefined) {
      service.reference_panels_count = 0;
    }
    return service;
  };

  const createService = async (data: any): Promise<ImputationService> => {
    const response: AxiosResponse<ImputationService> = await api.post('/services/', data);
    return response.data;
  };

  const updateService = async (id: number, data: any): Promise<ImputationService> => {
    const response: AxiosResponse<ImputationService> = await api.patch(`/services/${id}/`, data);
    return response.data;
  };

  const deleteService = async (id: number): Promise<void> => {
    await api.delete(`/services/${id}/`);
  };

  const syncReferencePanels = async (serviceId: number): Promise<{ message: string; task_id: string }> => {
    const response = await api.post(`/services/${serviceId}/sync_reference_panels/`);
    return response.data;
  };

  // Reference Panels
  const getReferencePanels = async (serviceId?: number, population?: string, build?: string): Promise<ReferencePanel[]> => {
    const params = new URLSearchParams();
    if (serviceId) params.append('service', serviceId.toString());
    if (population) params.append('population', population);
    if (build) params.append('build', build);

    const response = await api.get(`/reference-panels/?${params.toString()}`);
    // Handle paginated response
    if (response.data.results !== undefined) {
      return response.data.results;
    }
    return response.data;
  };

  const getServiceReferencePanels = async (serviceId: number): Promise<ReferencePanel[]> => {
    const response: AxiosResponse<ReferencePanel[]> = await api.get(`/services/${serviceId}/reference_panels/`);
    return response.data;
  };

  // Jobs
  const getJobs = async (status?: string, serviceId?: number, search?: string): Promise<ImputationJob[]> => {
    const params = new URLSearchParams();
    if (status) params.append('status', status);
    if (serviceId) params.append('service', serviceId.toString());
    if (search) params.append('search', search);

    const response = await api.get(`/jobs/?${params.toString()}`);
    // Handle paginated response
    if (response.data.results !== undefined) {
      return response.data.results;
    }
    return response.data;
  };

  const getJob = async (id: string): Promise<ImputationJob> => {
    const response: AxiosResponse<ImputationJob> = await api.get(`/jobs/${id}/`);
    return response.data;
  };

  const createJob = async (data: FormData): Promise<ImputationJob> => {
    const response: AxiosResponse<ImputationJob> = await api.post('/jobs/', data, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  };

  const cancelJob = async (id: string): Promise<{ message: string; task_id: string }> => {
    const response = await api.post(`/jobs/${id}/cancel/`);
    return response.data;
  };

  const retryJob = async (id: string): Promise<{ message: string; task_id: string }> => {
    const response = await api.post(`/jobs/${id}/retry/`);
    return response.data;
  };

  const getJobStatusUpdates = async (id: string): Promise<JobStatusUpdate[]> => {
    const response: AxiosResponse<JobStatusUpdate[]> = await api.get(`/jobs/${id}/status_updates/`);
    return response.data;
  };

  const getJobFiles = async (id: string): Promise<ResultFile[]> => {
    const response: AxiosResponse<ResultFile[]> = await api.get(`/jobs/${id}/files/`);
    return response.data;
  };

  const downloadFile = async (jobId: string, fileId: number): Promise<{ download_url: string; filename: string; file_size: number }> => {
    const response = await api.get(`/jobs/${jobId}/files/${fileId}/download/`);
    return response.data;
  };

  // Dashboard
  const getDashboardStats = async (): Promise<DashboardStats> => {
    const response: AxiosResponse<DashboardStats> = await api.get('/dashboard/stats/');
    return response.data;
  };

  const getServicesOverview = async (): Promise<any[]> => {
    const response = await api.get('/dashboard/services_overview/');
    return response.data;
  };

  const value: ApiContextType = {
    api,
    apiCall,
    getServices,
    getService,
    createService,
    updateService,
    deleteService,
    syncReferencePanels,
    getReferencePanels,
    getServiceReferencePanels,
    getJobs,
    getJob,
    createJob,
    cancelJob,
    retryJob,
    getJobStatusUpdates,
    getJobFiles,
    downloadFile,
    getDashboardStats,
    getServicesOverview,
  };

  return <ApiContext.Provider value={value}>{children}</ApiContext.Provider>;
};

export const useApi = (): ApiContextType => {
  const context = useContext(ApiContext);
  if (context === undefined) {
    throw new Error('useApi must be used within an ApiProvider');
  }
  return context;
}; 