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
  location?: string; // Legacy field (backward compatibility)
  continent?: string;
  // New location fields from microservices
  location_country?: string;
  location_city?: string;
  location_datacenter?: string;
  location_coordinates?: { lat: number; lon: number };
  // Resource fields
  cpu_available?: number | null;
  cpu_total?: number | null;
  memory_available_gb?: number | null;
  memory_total_gb?: number | null;
  storage_available_gb?: number | null;
  storage_total_gb?: number | null;
  queue_capacity?: number | null;
  queue_current?: number;
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
  service_id: number;
  name: string;
  slug?: string;
  display_name?: string;
  panel_id?: string; // Legacy field for backward compatibility
  description: string;
  population: string;
  build: string;
  samples_count: number;
  variants_count: number;
  is_available?: boolean;
  is_public?: boolean;
  requires_permission?: boolean;
  is_active?: boolean; // Legacy field
  service?: number; // Legacy field
  service_name?: string;
  service_type?: string;
  created_at: string;
  updated_at: string;
}

export interface ImputationJob {
  id: string;
  user_id: number;
  name: string;
  description: string;
  service_id: number;
  reference_panel_id: number;
  input_format: string;
  build: string;
  phasing: boolean;
  population: string;
  status: 'pending' | 'queued' | 'running' | 'completed' | 'failed' | 'cancelled';
  progress_percentage: number;
  external_job_id: string;
  input_file_name?: string;
  input_file_size?: number;
  created_at: string;
  updated_at: string;
  started_at?: string;
  completed_at?: string;
  execution_time_seconds?: number;
  error_message?: string;
  service_response?: any;
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
  name: string;
  size: number;
  type: 'input' | 'result';
  created_at: string;
}

export interface JobLog {
  id: number;
  job_id: string;
  step_name: string;
  step_index: number;
  log_type: 'error' | 'warning' | 'info' | 'success';
  message: string;
  timestamp: string;
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
  discoverServices: (params?: {
    latitude?: number;
    longitude?: number;
    max_distance_km?: number;
    min_cpu?: number;
    min_memory_gb?: number;
    min_storage_gb?: number;
    service_type?: string;
    api_type?: string;
    only_active?: boolean;
    only_healthy?: boolean;
    limit?: number;
  }) => Promise<ImputationService[]>;
  getService: (id: number) => Promise<ImputationService>;
  createService: (data: any) => Promise<ImputationService>;
  updateService: (id: number, data: any) => Promise<ImputationService>;
  deleteService: (id: number) => Promise<void>;
  syncReferencePanels: (serviceId: number) => Promise<{ message: string; task_id: string }>;

  // Reference Panels
  getReferencePanels: (serviceId?: number, population?: string, build?: string) => Promise<ReferencePanel[]>;
  getServiceReferencePanels: (serviceId: number) => Promise<ReferencePanel[]>;
  createReferencePanel: (panel: Omit<ReferencePanel, 'id' | 'created_at' | 'updated_at' | 'slug'>) => Promise<ReferencePanel>;

  // Jobs
  getJobs: (status?: string, serviceId?: number, search?: string) => Promise<ImputationJob[]>;
  getJob: (id: string) => Promise<ImputationJob>;
  createJob: (data: FormData) => Promise<ImputationJob>;
  cancelJob: (id: string) => Promise<{ message: string; task_id: string }>;
  retryJob: (id: string) => Promise<{ message: string; task_id: string }>;
  getJobStatusUpdates: (id: string) => Promise<JobStatusUpdate[]>;
  getJobFiles: (id: string) => Promise<ResultFile[]>;
  getJobLogs: (id: string) => Promise<JobLog[]>;
  downloadFile: (jobId: string, fileId: number) => Promise<{ download_url: string; filename: string; file_size: number }>;

  // Dashboard
  getDashboardStats: () => Promise<DashboardStats>;
  getServicesOverview: () => Promise<any[]>;

  // Helper functions
  formatDuration: (executionTimeSeconds?: number) => string;
  formatFileSize: (bytes?: number) => string;
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

// Create axios instance for service registry microservice
const createServiceRegistryApi = (): AxiosInstance => {
  // Use service registry direct port (8002) since it's not routed through gateway yet
  const baseURL = process.env.REACT_APP_SERVICE_REGISTRY_URL || 'http://154.114.10.123:8002';

  const instance = axios.create({
    baseURL,
    headers: {
      'Content-Type': 'application/json',
    },
    timeout: 30000,
  });

  // Add token if available
  instance.interceptors.request.use(
    (config) => {
      const token = localStorage.getItem('access_token');
      if (token) {
        config.headers['Authorization'] = `Bearer ${token}`;
      }
      return config;
    },
    (error) => Promise.reject(error)
  );

  return instance;
};

export const ApiProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const api = createApiInstance();
  const serviceRegistryApi = createServiceRegistryApi();

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

  // Discover services with intelligent ranking (online first, proximity-based)
  const discoverServices = async (params?: {
    latitude?: number;
    longitude?: number;
    max_distance_km?: number;
    min_cpu?: number;
    min_memory_gb?: number;
    min_storage_gb?: number;
    service_type?: string;
    api_type?: string;
    only_active?: boolean;
    only_healthy?: boolean;
    limit?: number;
  }): Promise<ImputationService[]> => {
    const queryParams = new URLSearchParams();

    // Add parameters if provided
    if (params?.latitude !== undefined) queryParams.append('latitude', params.latitude.toString());
    if (params?.longitude !== undefined) queryParams.append('longitude', params.longitude.toString());
    if (params?.max_distance_km) queryParams.append('max_distance_km', params.max_distance_km.toString());
    if (params?.min_cpu) queryParams.append('min_cpu', params.min_cpu.toString());
    if (params?.min_memory_gb) queryParams.append('min_memory_gb', params.min_memory_gb.toString());
    if (params?.min_storage_gb) queryParams.append('min_storage_gb', params.min_storage_gb.toString());
    if (params?.service_type) queryParams.append('service_type', params.service_type);
    if (params?.api_type) queryParams.append('api_type', params.api_type);
    if (params?.only_active !== undefined) queryParams.append('only_active', params.only_active.toString());
    if (params?.only_healthy !== undefined) queryParams.append('only_healthy', params.only_healthy.toString());
    if (params?.limit) queryParams.append('limit', params.limit.toString());

    const response = await api.get(`/services/discover?${queryParams.toString()}`);

    // Discovery endpoint returns ServiceDiscoveryResponse[] with { service, discovery_metadata }
    // Extract just the services
    const discoveryResults = response.data;
    let services = discoveryResults.map((result: any) => result.service);

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
    // Call service registry microservice directly for reference panels
    const response: AxiosResponse<ReferencePanel[]> = await serviceRegistryApi.get(`/reference-panels?service_id=${serviceId}`);
    return response.data;
  };

  const createReferencePanel = async (panel: Omit<ReferencePanel, 'id' | 'created_at' | 'updated_at' | 'slug'>): Promise<ReferencePanel> => {
    // Call service registry microservice to create a reference panel
    const response: AxiosResponse<ReferencePanel> = await serviceRegistryApi.post('/reference-panels', panel);
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
    try {
      // Backend uses hyphenated URL: /jobs/{id}/status-updates
      const response: AxiosResponse<JobStatusUpdate[]> = await api.get(`/jobs/${id}/status-updates/`);
      return response.data;
    } catch (error) {
      // Return empty array if no status updates exist yet (404 is expected for new jobs)
      console.warn('No status updates available for job:', id);
      return [];
    }
  };

  const getJobFiles = async (id: string): Promise<ResultFile[]> => {
    try {
      // Backend endpoint: /jobs/{id}/files
      const response: AxiosResponse<ResultFile[]> = await api.get(`/jobs/${id}/files/`);
      return response.data;
    } catch (error) {
      // Return empty array if no files exist yet (404 is expected for jobs without files)
      console.warn('No files available for job:', id);
      return [];
    }
  };

  const getJobLogs = async (id: string): Promise<JobLog[]> => {
    try {
      // Backend endpoint: /jobs/{id}/logs
      const response: AxiosResponse<JobLog[]> = await api.get(`/jobs/${id}/logs/`);
      return response.data;
    } catch (error) {
      // Return empty array if no logs exist yet (404 is expected for new/pending jobs)
      console.warn('No execution logs available for job:', id);
      return [];
    }
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

  // Helper functions for formatting display values
  const formatDuration = (executionTimeSeconds?: number): string => {
    if (!executionTimeSeconds) return 'N/A';

    const hours = Math.floor(executionTimeSeconds / 3600);
    const minutes = Math.floor((executionTimeSeconds % 3600) / 60);
    const seconds = executionTimeSeconds % 60;

    if (hours > 0) {
      return `${hours}h ${minutes}m ${seconds}s`;
    } else if (minutes > 0) {
      return `${minutes}m ${seconds}s`;
    } else {
      return `${seconds}s`;
    }
  };

  const formatFileSize = (bytes?: number): string => {
    if (!bytes || bytes === 0) return 'N/A';

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    let size = bytes;
    let unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return `${size.toFixed(2)} ${units[unitIndex]}`;
  };

  const value: ApiContextType = {
    api,
    apiCall,
    getServices,
    discoverServices,
    getService,
    createService,
    updateService,
    deleteService,
    syncReferencePanels,
    getReferencePanels,
    getServiceReferencePanels,
    createReferencePanel,
    getJobs,
    getJob,
    createJob,
    cancelJob,
    retryJob,
    getJobStatusUpdates,
    getJobFiles,
    getJobLogs,
    downloadFile,
    getDashboardStats,
    getServicesOverview,
    formatDuration,
    formatFileSize,
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