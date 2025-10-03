import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  CardActions,
  Button,
  Chip,
  Alert,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Divider,
  TextField,
  InputAdornment,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Paper,
  IconButton,
  Snackbar,
  Alert as MuiAlert,
  AlertProps,
  Fade,
  Backdrop,
  Autocomplete,
  Checkbox,
  ListItemButton,
  Collapse,
  FormGroup,
  FormControlLabel,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Tooltip,
  Badge,
} from '@mui/material';
import {
  CloudUpload,
  Speed,
  Refresh,
  CheckCircle,
  Error,
  Warning,
  Info,
  Timeline,
  Storage,
  Public,
  Security,
  Assessment,
  Group,
  Sync,
  LocationOn,
  Circle,
  Search,
  FilterList,
  Clear,
  CheckCircleOutline,
  WarningAmber,
  ExpandMore,
  Close,
  SelectAll,
  DeselectOutlined,
  Tune,
  Language,
  Business,
  Add,
  Edit as EditIcon,
} from '@mui/icons-material';
import { useApi, ImputationService, ReferencePanel } from '../contexts/ApiContext';
import ServiceManagement from '../components/ServiceManagement';

// Health check caching configuration
const HEALTH_CHECK_CACHE_KEY = 'serviceHealthCache';
const HEALTH_CHECK_CACHE_DURATION = 5 * 60 * 1000; // 5 minutes in milliseconds

interface HealthCheckCache {
  timestamp: number;
  healthStatus: Record<number, 'healthy' | 'unhealthy' | 'checking' | 'unknown'>;
}

// Helper functions for health check caching
const getHealthCheckCache = (): HealthCheckCache | null => {
  try {
    const cached = localStorage.getItem(HEALTH_CHECK_CACHE_KEY);
    if (!cached) return null;

    const cache: HealthCheckCache = JSON.parse(cached);
    const now = Date.now();

    // Check if cache is still valid
    if (now - cache.timestamp < HEALTH_CHECK_CACHE_DURATION) {
      return cache;
    }

    // Cache expired, remove it
    localStorage.removeItem(HEALTH_CHECK_CACHE_KEY);
    return null;
  } catch (error) {
    console.error('Error reading health check cache:', error);
    return null;
  }
};

const setHealthCheckCache = (healthStatus: Record<number, 'healthy' | 'unhealthy' | 'checking' | 'unknown'>) => {
  try {
    const cache: HealthCheckCache = {
      timestamp: Date.now(),
      healthStatus
    };
    localStorage.setItem(HEALTH_CHECK_CACHE_KEY, JSON.stringify(cache));
  } catch (error) {
    console.error('Error saving health check cache:', error);
  }
};

const Services: React.FC = () => {
  const navigate = useNavigate();
  const { getServices, getServiceReferencePanels, syncReferencePanels } = useApi();
  const [services, setServices] = useState<ImputationService[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedService, setSelectedService] = useState<ImputationService | null>(null);
  const [referencePanels, setReferencePanels] = useState<ReferencePanel[]>([]);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [syncing, setSyncing] = useState<number | null>(null);
  const [serviceHealth, setServiceHealth] = useState<Record<number, 'healthy' | 'unhealthy' | 'checking' | 'unknown'>>({});
  
  // Advanced filtering and search state
  const [searchTerm, setSearchTerm] = useState('');
  const [filterServiceType, setFilterServiceType] = useState<string[]>([]);
  const [filterApiType, setFilterApiType] = useState<string[]>([]);
  const [filterHealthStatus, setFilterHealthStatus] = useState<string[]>([]);
  const [filterCountry, setFilterCountry] = useState<string[]>([]);
  const [filterContinent, setFilterContinent] = useState<string[]>([]);
  const [filterInstitution, setFilterInstitution] = useState<string[]>([]);
  
  // UI state for advanced filters
  const [showAdvancedFilters, setShowAdvancedFilters] = useState(false);
  const [activeFilterCount, setActiveFilterCount] = useState(0);

  // Feedback and notification state
  const [snackbarOpen, setSnackbarOpen] = useState(false);
  const [snackbarMessage, setSnackbarMessage] = useState('');
  const [snackbarSeverity, setSnackbarSeverity] = useState<'success' | 'error' | 'warning' | 'info'>('info');

  // Real-time monitoring state
  const [lastHealthCheck, setLastHealthCheck] = useState<Date | null>(null);
  const [autoRefresh, setAutoRefresh] = useState(false);
  const [refreshInterval, setRefreshInterval] = useState<NodeJS.Timeout | null>(null);
  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'error' | 'warning' | 'info';
  }>({
    open: false,
    message: '',
    severity: 'info'
  });
  const [operationInProgress, setOperationInProgress] = useState<string | null>(null);

  // Service Management Dialog
  const [managementDialogOpen, setManagementDialogOpen] = useState(false);
  const [editingService, setEditingService] = useState<ImputationService | null>(null);

  useEffect(() => {
    loadServices();
  }, []);

  // Auto-refresh effect
  useEffect(() => {
    if (autoRefresh) {
      const interval = setInterval(() => {
        checkAllServicesHealth();
      }, 30000); // Check every 30 seconds
      setRefreshInterval(interval);
      return () => clearInterval(interval);
    } else if (refreshInterval) {
      clearInterval(refreshInterval);
      setRefreshInterval(null);
    }
  }, [autoRefresh]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (refreshInterval) {
        clearInterval(refreshInterval);
      }
    };
  }, []);

  // Helper function to extract location parts
  const parseLocation = (location: string) => {
    if (!location) return { institution: '', city: '', country: '' };
    const parts = location.split(',').map(part => part.trim());
    return {
      institution: parts[0] || '',
      city: parts[1] || '',
      country: parts[2] || parts[1] || ''
    };
  };

  // Enhanced filtering logic with multi-select support
  const filteredServices = services.filter(service => {
    // Text search across multiple fields
    const matchesSearch = searchTerm === '' || 
      service.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      service.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (service.location && service.location.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (service.continent && service.continent.toLowerCase().includes(searchTerm.toLowerCase()));

    // Multi-select service type filter
    const matchesServiceType = filterServiceType.length === 0 || 
      filterServiceType.includes(service.service_type);

    // Multi-select API type filter
    const matchesApiType = filterApiType.length === 0 || 
      (service.api_type && filterApiType.includes(service.api_type));

    // Multi-select health status filter
    let matchesHealthStatus = true;
    if (filterHealthStatus.length > 0) {
      const healthStatus = serviceHealth[service.id];
      if (filterHealthStatus.includes('healthy')) {
        matchesHealthStatus = healthStatus === 'healthy';
      } else if (filterHealthStatus.includes('unhealthy')) {
        matchesHealthStatus = healthStatus === 'unhealthy';
      } else if (filterHealthStatus.includes('unknown')) {
        matchesHealthStatus = !healthStatus || healthStatus === 'checking' || healthStatus === 'unknown';
      }
    }

    // Hierarchical location filtering
    const locationParts = parseLocation(service.location || '');
    
    const matchesCountry = filterCountry.length === 0 || 
      filterCountry.some(country => 
        locationParts.country.toLowerCase().includes(country.toLowerCase())
      );

    const matchesContinent = filterContinent.length === 0 || 
      (service.continent && filterContinent.includes(service.continent));

    const matchesInstitution = filterInstitution.length === 0 || 
      filterInstitution.some(institution => 
        locationParts.institution.toLowerCase().includes(institution.toLowerCase())
      );

    return matchesSearch && matchesServiceType && matchesApiType && 
           matchesHealthStatus && matchesCountry && matchesContinent && matchesInstitution;
  });

  // Helper function to get available options based on current filters
  const getAvailableOptions = () => {
    // Apply all filters except the one we're calculating options for
    const getFilteredServicesForOption = (excludeFilter: string) => {
      return services.filter(service => {
        // Text search
        const matchesSearch = searchTerm === '' || 
          service.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
          service.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
          (service.location && service.location.toLowerCase().includes(searchTerm.toLowerCase())) ||
          (service.continent && service.continent.toLowerCase().includes(searchTerm.toLowerCase()));

        // Apply all filters except the excluded one
        const matchesServiceType = excludeFilter === 'serviceType' || filterServiceType.length === 0 || 
          filterServiceType.includes(service.service_type);

        const matchesApiType = excludeFilter === 'apiType' || filterApiType.length === 0 || 
          (service.api_type && filterApiType.includes(service.api_type));

        let matchesHealthStatus = true;
        if (excludeFilter !== 'healthStatus' && filterHealthStatus.length > 0) {
          const healthStatus = serviceHealth[service.id];
          matchesHealthStatus = filterHealthStatus.some(status => {
            if (status === 'healthy') return healthStatus === 'healthy';
            if (status === 'unhealthy') return healthStatus === 'unhealthy';
            if (status === 'unknown') return !healthStatus || healthStatus === 'checking' || healthStatus === 'unknown';
            return false;
          });
        }

        const locationParts = parseLocation(service.location || '');
        
        const matchesCountry = excludeFilter === 'country' || filterCountry.length === 0 || 
          filterCountry.some(country => 
            locationParts.country.toLowerCase().includes(country.toLowerCase())
          );

        const matchesContinent = excludeFilter === 'continent' || filterContinent.length === 0 || 
          (service.continent && filterContinent.includes(service.continent));

        const matchesInstitution = excludeFilter === 'institution' || filterInstitution.length === 0 || 
          filterInstitution.some(institution => 
            locationParts.institution.toLowerCase().includes(institution.toLowerCase())
          );

        return matchesSearch && matchesServiceType && matchesApiType && 
               matchesHealthStatus && matchesCountry && matchesContinent && matchesInstitution;
      });
    };

    return {
      serviceTypes: Array.from(new Set(
        getFilteredServicesForOption('serviceType').map(s => s.service_type).filter(Boolean)
      )) as string[],
      
      apiTypes: Array.from(new Set(
        getFilteredServicesForOption('apiType').map(s => s.api_type).filter(Boolean)
      )) as string[],
      
      continents: Array.from(new Set(
        getFilteredServicesForOption('continent').map(s => s.continent).filter(Boolean)
      )) as string[],
      
      countries: Array.from(new Set(
        getFilteredServicesForOption('country')
          .map(s => parseLocation(s.location || '').country).filter(Boolean)
      )) as string[],
      
      institutions: Array.from(new Set(
        getFilteredServicesForOption('institution')
          .map(s => parseLocation(s.location || '').institution).filter(Boolean)
      )) as string[],
      
      healthStatuses: Array.from(new Set(
        getFilteredServicesForOption('healthStatus').map(s => {
          const healthStatus = serviceHealth[s.id];
          if (healthStatus === 'healthy') return 'healthy' as const;
          if (healthStatus === 'unhealthy') return 'unhealthy' as const;
          if (healthStatus === 'unknown') return 'unknown' as const;
          return 'unknown' as const;
        })
      )).filter(Boolean) as ('healthy' | 'unhealthy' | 'unknown')[]
    };
  };

  // Get dynamic filter options based on current state
  const availableOptions = getAvailableOptions();
  
  // Legacy variables for backward compatibility (now using dynamic options) - properly typed
  const uniqueServiceTypes: string[] = availableOptions.serviceTypes;
  const uniqueApiTypes: string[] = availableOptions.apiTypes;
  const uniqueContinents: string[] = availableOptions.continents;
  const uniqueCountries: string[] = availableOptions.countries;
  const uniqueInstitutions: string[] = availableOptions.institutions;

  // Dynamic health status options based on available statuses
  const allHealthStatusOptions = [
    { value: 'healthy' as const, label: 'Online', color: '#4caf50' },
    { value: 'unhealthy' as const, label: 'Offline', color: '#f44336' },
    { value: 'unknown' as const, label: 'Unknown', color: '#9e9e9e' }
  ];
  
  const healthStatusOptions = allHealthStatusOptions.filter(option => 
    availableOptions.healthStatuses.includes(option.value)
  );

  // Update active filter count
  useEffect(() => {
    const count = [
      searchTerm,
      ...filterServiceType,
      ...filterApiType,
      ...filterHealthStatus,
      ...filterCountry,
      ...filterContinent,
      ...filterInstitution
    ].filter(Boolean).length;
    setActiveFilterCount(count);
  }, [searchTerm, filterServiceType, filterApiType, filterHealthStatus, filterCountry, filterContinent, filterInstitution]);

  // Multi-select helper functions
  const handleMultiSelectAll = (currentValues: string[], allValues: string[], setter: (values: string[]) => void) => {
    if (currentValues.length === allValues.length) {
      setter([]);
    } else {
      setter(allValues.filter((v): v is string => Boolean(v)));
    }
  };

  const handleMultiSelectChange = (values: (string | undefined)[], setter: (values: string[]) => void) => {
    setter(values.filter((v): v is string => v !== undefined));
  };

  // Clear all filters
  const clearFilters = () => {
    setSearchTerm('');
    setFilterServiceType([]);
    setFilterApiType([]);
    setFilterHealthStatus([]);
    setFilterCountry([]);
    setFilterContinent([]);
    setFilterInstitution([]);
    showFeedback('All filters cleared', 'info');
  };

  // Feedback helper functions
  const showFeedback = (message: string, severity: 'success' | 'error' | 'warning' | 'info') => {
    setSnackbar({
      open: true,
      message,
      severity
    });
  };

  const closeFeedback = () => {
    setSnackbar(prev => ({ ...prev, open: false }));
  };

  // Service Management handlers
  const handleCreateService = () => {
    setEditingService(null);
    setManagementDialogOpen(true);
  };

  const handleEditService = (service: ImputationService, event: React.MouseEvent) => {
    event.stopPropagation();
    setEditingService(service);
    setManagementDialogOpen(true);
  };

  const handleManagementClose = () => {
    setManagementDialogOpen(false);
    setEditingService(null);
  };

  const handleServiceUpdated = () => {
    loadServices();
  };

  // Removed auto-health check on mount to prevent blocking UI
  // Users can manually trigger health checks using the "Check Status" button
  // useEffect(() => {
  //   if (services.length > 0) {
  //     checkServicesHealth();
  //   }
  // }, [services]);

  const checkServicesHealth = async (forceCheck: boolean = false) => {
    const startTime = Date.now();
    const healthStatus: Record<number, 'healthy' | 'unhealthy' | 'checking' | 'unknown'> = {};
    
    // Show operation start feedback
    setOperationInProgress('Checking service health...');
    const actionText = forceCheck ? 'force checking' : 'checking';
    showFeedback(`Starting ${actionText} for ${services.length} services...`, 'info');
    
    // Set all services to checking status initially
    services.forEach(service => {
      healthStatus[service.id] = 'checking';
    });
    setServiceHealth(healthStatus);

    let healthyCount = 0;
    let unhealthyCount = 0;
    let checkedCount = 0;
    let cachedCount = 0;
    let freshCount = 0;

    // Check each service health using backend health check API
    for (const service of services) {
      try {
        setOperationInProgress(`Checking ${service.name}... (${checkedCount + 1}/${services.length})`);
        
        const url = `${process.env.REACT_APP_API_URL}/api/services/${service.id}/health/${forceCheck ? '?force=true' : ''}`;
        const response = await fetch(url, {
          credentials: 'include',
        });
        
        if (response.ok) {
          const healthData = await response.json();
          const status = healthData.status;
          
          // Count cache vs fresh checks
          if (healthData.cache_info?.from_cache) {
            cachedCount++;
          } else {
            freshCount++;
          }
          
          // Update status
          // Note: 'timeout' status from service registry is treated as 'unhealthy'
          if (status === 'healthy') {
            healthStatus[service.id] = 'healthy';
            healthyCount++;
          } else if (status === 'unhealthy' || status === 'timeout') {
            healthStatus[service.id] = 'unhealthy';
            unhealthyCount++;
          } else {
            healthStatus[service.id] = 'unknown';
            unhealthyCount++;
          }
          
          // Log detailed health info with cache information
          console.log(`Health check for ${service.name}:`, {
            status: healthData.status,
            message: healthData.message,
            test_url: healthData.test_url,
            response_time: healthData.response_time_ms,
            cache_info: healthData.cache_info
          });
        } else {
          console.error(`Health check API failed for ${service.name}: HTTP ${response.status}`);
          healthStatus[service.id] = 'unhealthy';
          unhealthyCount++;
          freshCount++; // Failed checks are fresh attempts
        }
        
      } catch (error) {
        console.error(`Health check failed for ${service.name}:`, error);
        healthStatus[service.id] = 'unhealthy';
        unhealthyCount++;
        freshCount++; // Failed checks are fresh attempts
      }
      
      checkedCount++;
    }
    
    setServiceHealth({ ...healthStatus });

    // Save health check results to cache
    setHealthCheckCache(healthStatus);
    console.log('Health check results saved to cache (valid for 5 minutes)');

    setOperationInProgress(null);

    // Show comprehensive completion feedback with cache statistics
    const duration = ((Date.now() - startTime) / 1000).toFixed(1);
    const totalServices = services.length;
    const cacheInfo = cachedCount > 0 ? ` (${cachedCount} from cache, ${freshCount} fresh)` : ` (all fresh)`;
    
    if (unhealthyCount === 0) {
      showFeedback(
        `✅ Health check complete! All ${totalServices} services are healthy (${duration}s)${cacheInfo}`,
        'success'
      );
    } else if (healthyCount === 0) {
      showFeedback(
        `⚠️ Health check complete! All ${totalServices} services are unhealthy (${duration}s)${cacheInfo}`,
        'error'
      );
    } else {
      showFeedback(
        `ℹ️ Health check complete! ${healthyCount} healthy, ${unhealthyCount} unhealthy out of ${totalServices} services (${duration}s)${cacheInfo}`,
        'warning'
      );
    }
  };

  const loadServices = async () => {
    try {
      setLoading(true);
      setOperationInProgress('Loading imputation services...');
      const data = await getServices();
      setServices(data);
      setError(null);
      showFeedback(`Successfully loaded ${data.length} imputation services`, 'success');

      // Check if we have cached health status
      const cachedHealth = getHealthCheckCache();

      if (cachedHealth) {
        // Use cached health status
        console.log('Using cached health check results (valid for 5 minutes)');
        setServiceHealth(cachedHealth.healthStatus);
        showFeedback('Loaded services with cached health status', 'success');
      } else {
        // No cache or cache expired - initialize with checking status
        const healthStatus: Record<number, 'healthy' | 'unhealthy' | 'checking' | 'unknown'> = {};
        data.forEach(service => {
          healthStatus[service.id] = 'checking'; // Default to checking status
        });
        setServiceHealth(healthStatus);

        // Perform initial health check after a short delay
        console.log('No cached health status - performing health checks');
        setTimeout(() => checkServicesHealth(), 2000);
      }

    } catch (err) {
      const errorMessage = 'Failed to load imputation services. Please check your connection and try again.';
      setError(errorMessage);
      showFeedback(errorMessage, 'error');
      console.error('Error loading services:', err);
    } finally {
      setLoading(false);
      setOperationInProgress(null);
    }
  };

  // Health monitoring functions
  const checkServiceHealth = async (service: ImputationService): Promise<'healthy' | 'unhealthy' | 'unknown'> => {
    try {
      // Simple health check simulation (legacy function, not used anymore)
      // The actual health checks are now done by checkServicesHealth() using backend API
      const apiUrl = service.api_url || service.base_url;
      if (!apiUrl) {
        return 'unknown'; // No URL to check
      }

      // Simulate network check with timeout
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 5000);

      try {
        const response = await fetch(apiUrl, {
          method: 'HEAD',
          signal: controller.signal,
          mode: 'no-cors' // For CORS-restricted endpoints
        });
        clearTimeout(timeoutId);
        return 'healthy';
      } catch (fetchError) {
        clearTimeout(timeoutId);
        return 'unhealthy';
      }
    } catch (error) {
      console.warn(`Health check failed for ${service.name}:`, error);
      return 'unknown'; // Default to unknown on errors
    }
  };

  const checkAllServicesHealth = async () => {
    setLastHealthCheck(new Date());

    const healthPromises = services.map(async (service) => {
      setServiceHealth(prev => ({ ...prev, [service.id]: 'checking' }));
      const health = await checkServiceHealth(service);
      setServiceHealth(prev => ({ ...prev, [service.id]: health }));
      return { serviceId: service.id, health };
    });

    try {
      await Promise.all(healthPromises);
      showFeedback('Health check completed', 'success');
    } catch (error) {
      console.error('Health check error:', error);
      showFeedback('Health check completed with some errors', 'warning');
    }
  };

  const handleViewDetails = async (service: ImputationService) => {
    try {
      setSelectedService(service);
      setDialogOpen(true);
      setOperationInProgress(`Loading reference panels for ${service.name}...`);
      showFeedback(`Opening details for ${service.name}`, 'info');
      
      const panels = await getServiceReferencePanels(service.id);
      setReferencePanels(panels);
      setOperationInProgress(null);
      
      if (panels.length === 0) {
        showFeedback(`No reference panels found for ${service.name}`, 'warning');
      } else {
        showFeedback(`Loaded ${panels.length} reference panels for ${service.name}`, 'success');
      }
    } catch (err) {
      setOperationInProgress(null);
      const errorMessage = `Failed to load reference panels for ${service.name}`;
      showFeedback(errorMessage, 'error');
      console.error('Error loading reference panels:', err);
    }
  };

  const handleSyncPanels = async (serviceId: number) => {
    const service = services.find(s => s.id === serviceId);
    const serviceName = service?.name || `Service ${serviceId}`;
    
    try {
      setSyncing(serviceId);
      setOperationInProgress(`Syncing reference panels for ${serviceName}...`);
      showFeedback(`Starting sync for ${serviceName}`, 'info');
      
      await syncReferencePanels(serviceId);
      
      // Refresh the service data
      setOperationInProgress(`Refreshing service data...`);
      await loadServices();
      
      if (selectedService && selectedService.id === serviceId) {
        const panels = await getServiceReferencePanels(serviceId);
        setReferencePanels(panels);
      }
      
      setOperationInProgress(null);
      showFeedback(`✅ Sync completed successfully for ${serviceName}`, 'success');
      
    } catch (err) {
      setOperationInProgress(null);
      const errorMessage = `Failed to sync reference panels for ${serviceName}`;
      showFeedback(errorMessage, 'error');
      console.error('Error syncing panels:', err);
    } finally {
      setSyncing(null);
    }
  };

  const getServiceStatusIndicator = (serviceId: number) => {
    const status = serviceHealth[serviceId];
    
    switch (status) {
      case 'healthy':
        return (
          <Circle 
            sx={{ 
              color: '#4caf50', 
              fontSize: 12,
              mr: 1
            }} 
          />
        );
      case 'unhealthy':
        return (
          <Circle
            sx={{
              color: '#f44336',
              fontSize: 12,
              mr: 1
            }}
          />
        );
      case 'unknown':
        return (
          <Circle
            sx={{
              color: '#9e9e9e',
              fontSize: 12,
              mr: 1
            }}
          />
        );
      case 'checking':
        return (
          <CircularProgress 
            size={12}
            sx={{ 
              mr: 1,
              color: '#ff9800'
            }} 
          />
        );
      default:
        return (
          <Circle 
            sx={{ 
              color: '#9e9e9e', 
              fontSize: 12,
              mr: 1
            }} 
          />
        );
    }
  };

  const getServiceStatusText = (serviceId: number) => {
    const status = serviceHealth[serviceId];

    switch (status) {
      case 'healthy':
        return 'Online';
      case 'unhealthy':
        return 'Offline';
      case 'checking':
        return 'Checking...';
      case 'unknown':
        return 'Unknown';
      default:
        return 'Unknown';
    }
  };

  const getServiceIcon = (serviceType: string) => {
    switch (serviceType) {
      case 'h3africa':
        return <Group color="primary" fontSize="large" />;
      case 'michigan':
        return <Speed color="secondary" fontSize="large" />;
      default:
        return <CloudUpload fontSize="large" />;
    }
  };

  const getServiceDescription = (serviceType: string) => {
    switch (serviceType) {
      case 'h3africa':
        return 'African genomic reference panels specialized for African populations';
      case 'michigan':
        return 'High-performance imputation server with multiple reference panels';
      default:
        return 'External imputation service';
    }
  };

  const getApiTypeColor = (apiType?: string) => {
    switch (apiType) {
      case 'michigan':
        return {
          background: 'linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%)',
          borderColor: '#1976d2',
          chipColor: 'primary' as const,
        };
      case 'ga4gh':
        return {
          background: 'linear-gradient(135deg, #f3e5f5 0%, #e1bee7 100%)',
          borderColor: '#7b1fa2',
          chipColor: 'secondary' as const,
        };
      case 'dnastack':
        return {
          background: 'linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%)',
          borderColor: '#388e3c',
          chipColor: 'success' as const,
        };
      default:
        return {
          background: '#ffffff',
          borderColor: '#e0e0e0',
          chipColor: 'default' as const,
        };
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mb: 2 }}>
        {error}
      </Alert>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
        <Box>
          <Typography variant="h4" gutterBottom>
            Imputation Services
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Select an imputation service to view available reference panels and submit jobs.
          </Typography>
        </Box>
        <Box display="flex" gap={1}>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={handleCreateService}
            color="primary"
          >
            Create Service
          </Button>
          <Button
            variant="outlined"
            startIcon={<Sync />}
            onClick={() => checkServicesHealth(false)}
            disabled={Object.values(serviceHealth).some(status => status === 'checking')}
          >
            Check Status
          </Button>
          <Button
            variant="outlined"
            color="secondary"
            startIcon={<Sync />}
            onClick={() => checkServicesHealth(true)}
            disabled={Object.values(serviceHealth).some(status => status === 'checking')}
            title="Force fresh health check, bypassing cache"
          >
            Force Check
          </Button>
        </Box>
      </Box>

      {/* API Type Legend */}
      <Box display="flex" gap={2} mb={3} flexWrap="wrap">
        <Box display="flex" alignItems="center">
          <Box
            sx={{
              width: 20,
              height: 20,
              background: 'linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%)',
              border: '1px solid #1976d2',
              borderRadius: 1,
              mr: 1,
            }}
          />
          <Typography variant="body2" color="text.secondary">
            Michigan API
          </Typography>
        </Box>
        <Box display="flex" alignItems="center">
          <Box
            sx={{
              width: 20,
              height: 20,
              background: 'linear-gradient(135deg, #f3e5f5 0%, #e1bee7 100%)',
              border: '1px solid #7b1fa2',
              borderRadius: 1,
              mr: 1,
            }}
          />
          <Typography variant="body2" color="text.secondary">
            GA4GH WES API
          </Typography>
        </Box>
        <Box display="flex" alignItems="center">
          <Box
            sx={{
              width: 20,
              height: 20,
              background: 'linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%)',
              border: '1px solid #388e3c',
              borderRadius: 1,
              mr: 1,
            }}
          />
          <Typography variant="body2" color="text.secondary">
            DNASTACK API
          </Typography>
        </Box>
      </Box>

      {/* Enhanced Search and Filter Controls */}
      <Paper elevation={2} sx={{ p: 3, mb: 3 }}>
        <Box display="flex" alignItems="center" gap={1} mb={2}>
          <Badge badgeContent={activeFilterCount} color="primary">
            <FilterList color="primary" />
          </Badge>
          <Typography variant="h6">Search & Filter</Typography>
          <Box sx={{ flexGrow: 1 }} />
          <Tooltip title="Toggle Advanced Filters">
            <IconButton onClick={() => setShowAdvancedFilters(!showAdvancedFilters)}>
              <Tune color={showAdvancedFilters ? "primary" : "action"} />
            </IconButton>
          </Tooltip>
          <Typography variant="body2" color="text.secondary">
            Showing {filteredServices.length} of {services.length} services
          </Typography>
        </Box>

        {/* Search Field */}
        <TextField
          fullWidth
          placeholder="Search services by name, description, location, or continent..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <Search color="action" />
              </InputAdornment>
            ),
            endAdornment: searchTerm && (
              <InputAdornment position="end">
                <IconButton onClick={() => setSearchTerm('')} size="small">
                  <Clear />
                </IconButton>
              </InputAdornment>
            ),
          }}
          sx={{ mb: 3 }}
        />

        {/* Quick Filter Chips */}
        {activeFilterCount > 0 && (
          <Box mb={2}>
            <Typography variant="subtitle2" gutterBottom>Active Filters:</Typography>
            <Box display="flex" gap={1} flexWrap="wrap">
              {searchTerm && (
                <Chip
                  label={`Search: "${searchTerm}"`}
                  onDelete={() => setSearchTerm('')}
                  size="small"
                  color="primary"
                  variant="outlined"
                />
              )}
              {filterServiceType.map(type => (
                <Chip
                  key={type}
                  label={`Type: ${type}`}
                  onDelete={() => setFilterServiceType(filterServiceType.filter(t => t !== type))}
                  size="small"
                  color="primary"
                  variant="outlined"
                />
              ))}
              {filterApiType.map(type => (
                <Chip
                  key={type}
                  label={`API: ${type}`}
                  onDelete={() => setFilterApiType(filterApiType.filter(t => t !== type))}
                  size="small"
                  color="secondary"
                  variant="outlined"
                />
              ))}
              {filterHealthStatus.map(status => (
                <Chip
                  key={status}
                  label={`Status: ${healthStatusOptions.find(o => o.value === status)?.label}`}
                  onDelete={() => setFilterHealthStatus(filterHealthStatus.filter(s => s !== status))}
                  size="small"
                  color="info"
                  variant="outlined"
                />
              ))}
              {filterContinent.map(continent => (
                <Chip
                  key={continent}
                  label={`Continent: ${continent}`}
                  onDelete={() => setFilterContinent(filterContinent.filter(c => c !== continent))}
                  size="small"
                  color="success"
                  variant="outlined"
                />
              ))}
              {filterCountry.map(country => (
                <Chip
                  key={country}
                  label={`Country: ${country}`}
                  onDelete={() => setFilterCountry(filterCountry.filter(c => c !== country))}
                  size="small"
                  color="warning"
                  variant="outlined"
                />
              ))}
              {filterInstitution.map(institution => (
                <Chip
                  key={institution}
                  label={`Institution: ${institution}`}
                  onDelete={() => setFilterInstitution(filterInstitution.filter(i => i !== institution))}
                  size="small"
                  color="error"
                  variant="outlined"
                />
              ))}
              <Button
                variant="text"
                size="small"
                startIcon={<Clear />}
                onClick={clearFilters}
                sx={{ ml: 1 }}
              >
                Clear All
              </Button>
            </Box>
          </Box>
        )}

        {/* Advanced Filters */}
        <Collapse in={showAdvancedFilters}>
          <Divider sx={{ mb: 3 }} />
          
          <Grid container spacing={3}>
            {/* Service Type Filter */}
            <Grid item xs={12} md={6}>
              <Accordion defaultExpanded>
                <AccordionSummary expandIcon={<ExpandMore />}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <Business color={uniqueServiceTypes.length === 0 ? "disabled" : "primary"} />
                    <Typography variant="subtitle1" color={uniqueServiceTypes.length === 0 ? "text.disabled" : "inherit"}>
                      Service Type {uniqueServiceTypes.length === 0 && "(No options)"}
                    </Typography>
                    {filterServiceType.length > 0 && (
                      <Badge badgeContent={filterServiceType.length} color="primary" />
                    )}
                  </Box>
                </AccordionSummary>
                <AccordionDetails>
                  <FormControl fullWidth>
                    <Autocomplete
                      multiple
                      options={uniqueServiceTypes}
                      value={filterServiceType}
                      onChange={(_, newValue) => handleMultiSelectChange(newValue, setFilterServiceType)}
                      noOptionsText={uniqueServiceTypes.length === 0 ? "No service types available with current filters" : "No options"}
                      renderInput={(params) => (
                        <TextField
                          {...params}
                          placeholder={uniqueServiceTypes.length === 0 ? "No service types available" : "Select service types..."}
                          InputProps={{
                            ...params.InputProps,
                            startAdornment: (
                              <>
                                <InputAdornment position="start">
                                  <Business color={uniqueServiceTypes.length === 0 ? "disabled" : "action"} />
                                </InputAdornment>
                                {params.InputProps.startAdornment}
                              </>
                            ),
                          }}
                        />
                      )}
                      renderOption={(props, option, { selected }) => (
                        <li {...props}>
                          <Checkbox checked={selected} />
                          <ListItemText primary={option.charAt(0).toUpperCase() + option.slice(1)} />
                        </li>
                      )}
                    />
                    <Box mt={1}>
                      <Button
                        size="small"
                        startIcon={filterServiceType.length === uniqueServiceTypes.length ? <DeselectOutlined /> : <SelectAll />}
                        onClick={() => handleMultiSelectAll(filterServiceType, uniqueServiceTypes, setFilterServiceType)}
                        disabled={uniqueServiceTypes.length === 0}
                      >
                        {filterServiceType.length === uniqueServiceTypes.length ? 'Deselect All' : 'Select All'}
                        {uniqueServiceTypes.length > 0 && ` (${uniqueServiceTypes.length})`}
                      </Button>
                    </Box>
                  </FormControl>
                </AccordionDetails>
              </Accordion>
            </Grid>

            {/* API Type Filter */}
            <Grid item xs={12} md={6}>
              <Accordion defaultExpanded>
                <AccordionSummary expandIcon={<ExpandMore />}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <Language color={uniqueApiTypes.length === 0 ? "disabled" : "secondary"} />
                    <Typography variant="subtitle1" color={uniqueApiTypes.length === 0 ? "text.disabled" : "inherit"}>
                      API Type {uniqueApiTypes.length === 0 && "(No options)"}
                    </Typography>
                    {filterApiType.length > 0 && (
                      <Badge badgeContent={filterApiType.length} color="secondary" />
                    )}
                  </Box>
                </AccordionSummary>
                <AccordionDetails>
                  <FormControl fullWidth>
                    <Autocomplete
                      multiple
                      options={uniqueApiTypes}
                      value={filterApiType}
                      onChange={(_, newValue) => handleMultiSelectChange(newValue, setFilterApiType)}
                      noOptionsText={uniqueApiTypes.length === 0 ? "No API types available with current filters" : "No options"}
                      renderInput={(params) => (
                        <TextField
                          {...params}
                          placeholder={uniqueApiTypes.length === 0 ? "No API types available" : "Select API types..."}
                          InputProps={{
                            ...params.InputProps,
                            startAdornment: (
                              <>
                                <InputAdornment position="start">
                                  <Language color={uniqueApiTypes.length === 0 ? "disabled" : "action"} />
                                </InputAdornment>
                                {params.InputProps.startAdornment}
                              </>
                            ),
                          }}
                        />
                      )}
                      renderOption={(props, option, { selected }) => (
                        <li {...props}>
                          <Checkbox checked={selected} />
                          <ListItemText primary={option?.toUpperCase() || 'Unknown'} />
                        </li>
                      )}
                    />
                    <Box mt={1}>
                      <Button
                        size="small"
                        startIcon={filterApiType.length === uniqueApiTypes.length ? <DeselectOutlined /> : <SelectAll />}
                        onClick={() => handleMultiSelectAll(filterApiType, uniqueApiTypes, setFilterApiType)}
                        disabled={uniqueApiTypes.length === 0}
                      >
                        {filterApiType.length === uniqueApiTypes.length ? 'Deselect All' : 'Select All'}
                        {uniqueApiTypes.length > 0 && ` (${uniqueApiTypes.length})`}
                      </Button>
                    </Box>
                  </FormControl>
                </AccordionDetails>
              </Accordion>
            </Grid>

            {/* Health Status Filter */}
            <Grid item xs={12} md={6}>
              <Accordion>
                <AccordionSummary expandIcon={<ExpandMore />}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <CheckCircle color="success" />
                    <Typography variant="subtitle1">Health Status</Typography>
                    {filterHealthStatus.length > 0 && (
                      <Badge badgeContent={filterHealthStatus.length} color="success" />
                    )}
                  </Box>
                </AccordionSummary>
                <AccordionDetails>
                  <FormGroup>
                    {healthStatusOptions.map(option => (
                      <FormControlLabel
                        key={option.value}
                        control={
                          <Checkbox
                            checked={filterHealthStatus.includes(option.value)}
                            onChange={(e) => {
                              if (e.target.checked) {
                                setFilterHealthStatus([...filterHealthStatus, option.value]);
                              } else {
                                setFilterHealthStatus(filterHealthStatus.filter(s => s !== option.value));
                              }
                            }}
                          />
                        }
                        label={
                          <Box display="flex" alignItems="center" gap={1}>
                            <Circle sx={{ color: option.color, fontSize: 12 }} />
                            {option.label}
                          </Box>
                        }
                      />
                    ))}
                  </FormGroup>
                  <Box mt={1}>
                    <Button
                      size="small"
                      startIcon={filterHealthStatus.length === healthStatusOptions.length ? <DeselectOutlined /> : <SelectAll />}
                      onClick={() => handleMultiSelectAll(
                        filterHealthStatus, 
                        healthStatusOptions.map(o => o.value), 
                        setFilterHealthStatus
                      )}
                      disabled={healthStatusOptions.length === 0}
                    >
                      {filterHealthStatus.length === healthStatusOptions.length ? 'Deselect All' : 'Select All'}
                      {healthStatusOptions.length > 0 && ` (${healthStatusOptions.length})`}
                    </Button>
                  </Box>
                </AccordionDetails>
              </Accordion>
            </Grid>

            {/* Location Filters */}
            <Grid item xs={12} md={6}>
              <Accordion>
                <AccordionSummary expandIcon={<ExpandMore />}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <Public color="info" />
                    <Typography variant="subtitle1">Location</Typography>
                    {(filterContinent.length + filterCountry.length + filterInstitution.length) > 0 && (
                      <Badge badgeContent={filterContinent.length + filterCountry.length + filterInstitution.length} color="info" />
                    )}
                  </Box>
                </AccordionSummary>
                <AccordionDetails>
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="subtitle2" gutterBottom>Continent</Typography>
                    <Autocomplete
                      multiple
                      options={uniqueContinents}
                      value={filterContinent}
                      onChange={(_, newValue) => handleMultiSelectChange(newValue, setFilterContinent)}
                      renderInput={(params) => (
                        <TextField
                          {...params}
                          placeholder="Select continents..."
                          size="small"
                          InputProps={{
                            ...params.InputProps,
                            startAdornment: (
                              <>
                                <InputAdornment position="start">
                                  <Public color="action" />
                                </InputAdornment>
                                {params.InputProps.startAdornment}
                              </>
                            ),
                          }}
                        />
                      )}
                      renderOption={(props, option, { selected }) => (
                        <li {...props}>
                          <Checkbox checked={selected} />
                          <ListItemText primary={option} />
                        </li>
                      )}
                    />
                  </Box>

                  <Box sx={{ mb: 2 }}>
                    <Typography variant="subtitle2" gutterBottom>Country</Typography>
                    <Autocomplete
                      multiple
                      options={uniqueCountries}
                      value={filterCountry}
                      onChange={(_, newValue) => handleMultiSelectChange(newValue, setFilterCountry)}
                      renderInput={(params) => (
                        <TextField
                          {...params}
                          placeholder="Select countries..."
                          size="small"
                          InputProps={{
                            ...params.InputProps,
                            startAdornment: (
                              <>
                                <InputAdornment position="start">
                                  <LocationOn color="action" />
                                </InputAdornment>
                                {params.InputProps.startAdornment}
                              </>
                            ),
                          }}
                        />
                      )}
                      renderOption={(props, option, { selected }) => (
                        <li {...props}>
                          <Checkbox checked={selected} />
                          <ListItemText primary={option} />
                        </li>
                      )}
                    />
                  </Box>

                  <Box>
                    <Typography variant="subtitle2" gutterBottom>Institution</Typography>
                    <Autocomplete
                      multiple
                      options={uniqueInstitutions}
                      value={filterInstitution}
                      onChange={(_, newValue) => handleMultiSelectChange(newValue, setFilterInstitution)}
                      renderInput={(params) => (
                        <TextField
                          {...params}
                          placeholder="Select institutions..."
                          size="small"
                          InputProps={{
                            ...params.InputProps,
                            startAdornment: (
                              <>
                                <InputAdornment position="start">
                                  <Business color="action" />
                                </InputAdornment>
                                {params.InputProps.startAdornment}
                              </>
                            ),
                          }}
                        />
                      )}
                      renderOption={(props, option, { selected }) => (
                        <li {...props}>
                          <Checkbox checked={selected} />
                          <ListItemText primary={option} />
                        </li>
                      )}
                    />
                  </Box>
                </AccordionDetails>
              </Accordion>
            </Grid>
          </Grid>
        </Collapse>
      </Paper>

      <Grid container spacing={3}>
        {filteredServices.map((service) => (
          <Grid item xs={12} md={6} lg={4} key={service.id}>
            <Card 
              sx={{ 
                height: '100%', 
                display: 'flex', 
                flexDirection: 'column',
                cursor: 'pointer',
                background: getApiTypeColor(service.api_type).background,
                border: `1px solid ${getApiTypeColor(service.api_type).borderColor}`,
                '&:hover': {
                  boxShadow: 4,
                  transform: 'translateY(-2px)',
                  transition: 'all 0.2s ease-in-out',
                  borderColor: getApiTypeColor(service.api_type).borderColor,
                }
              }}
              onClick={() => navigate(`/services/${service.id}`)}
            >
              <CardContent sx={{ flexGrow: 1 }}>
                <Box display="flex" alignItems="center" mb={2}>
                  {getServiceIcon(service.service_type)}
                  <Box ml={2} sx={{ flexGrow: 1 }}>
                    <Box display="flex" alignItems="center" justifyContent="space-between">
                      <Typography variant="h6" component="h2">
                        {service.name}
                      </Typography>
                      <Box display="flex" alignItems="center">
                        {getServiceStatusIndicator(service.id)}
                        <Typography 
                          variant="caption" 
                          sx={{ 
                            color: serviceHealth[service.id] === 'healthy' ? '#4caf50' : 
                                   serviceHealth[service.id] === 'unhealthy' ? '#f44336' : '#ff9800',
                            fontWeight: 'medium'
                          }}
                        >
                          {getServiceStatusText(service.id)}
                        </Typography>
                      </Box>
                    </Box>
                    <Box mt={1}>
                      <Chip 
                        label={service.service_type.toUpperCase()} 
                        size="small" 
                        color={service.service_type === 'h3africa' ? 'primary' : 'secondary'}
                      />
                      {service.api_type && (
                        <Chip 
                          label={service.api_type.toUpperCase()} 
                          size="small" 
                          color={getApiTypeColor(service.api_type).chipColor}
                          variant="outlined"
                          sx={{ ml: 1 }}
                        />
                      )}
                    </Box>
                  </Box>
                </Box>

                <Typography variant="body2" color="text.secondary" paragraph>
                  {service.description || getServiceDescription(service.service_type)}
                </Typography>

                {service.location && (
                  <Box display="flex" alignItems="center" mb={1}>
                    <LocationOn sx={{ fontSize: 16, mr: 1, color: 'text.secondary' }} />
                    <Typography variant="body2" color="text.secondary">
                      {service.location}
                    </Typography>
                  </Box>
                )}
                
                {service.continent && (
                  <Box display="flex" alignItems="center" mb={2}>
                    <Box
                      sx={{
                        width: 12,
                        height: 12,
                        borderRadius: '50%',
                        backgroundColor: service.continent === 'Africa' ? '#4CAF50' : 
                                        service.continent === 'North America' ? '#2196F3' : '#FF9800',
                        mr: 1
                      }}
                    />
                    <Typography variant="body2" color="text.secondary">
                      {service.continent}
                    </Typography>
                  </Box>
                )}

                <Box display="flex" flexWrap="wrap" gap={1} mb={2}>
                  <Chip 
                    icon={<Storage />} 
                    label={`${service.reference_panels_count} panels`} 
                    size="small" 
                    variant="outlined"
                  />
                  <Chip 
                    icon={<CloudUpload />} 
                    label={`${service.max_file_size_mb}MB max`} 
                    size="small" 
                    variant="outlined"
                  />
                </Box>

                <Typography variant="caption" color="text.secondary">
                  Supported formats: {service.supported_formats.join(', ') || 'VCF, PLINK, BGEN'}
                </Typography>
              </CardContent>

              <CardActions onClick={(e) => e.stopPropagation()}>
                <Button
                  size="small"
                  onClick={() => navigate(`/services/${service.id}`)}
                  startIcon={<Storage />}
                >
                  View Details
                </Button>
                <Button
                  size="small"
                  onClick={(e) => handleEditService(service, e)}
                  startIcon={<EditIcon />}
                  color="primary"
                >
                  Edit
                </Button>
                <Button
                  size="small"
                  onClick={() => handleSyncPanels(service.id)}
                  disabled={syncing === service.id}
                  startIcon={syncing === service.id ? <CircularProgress size={16} /> : <Sync />}
                >
                  {syncing === service.id ? 'Syncing...' : 'Sync'}
                </Button>
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Service Details Dialog */}
      <Dialog 
        open={dialogOpen} 
        onClose={() => setDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        {selectedService && (
          <>
            <DialogTitle>
              <Box display="flex" alignItems="center">
                {getServiceIcon(selectedService.service_type)}
                <Typography variant="h6" ml={2}>
                  {selectedService.name} - Reference Panels
                </Typography>
              </Box>
            </DialogTitle>
            <DialogContent>
              <Typography variant="body2" color="text.secondary" paragraph>
                {selectedService.description || getServiceDescription(selectedService.service_type)}
              </Typography>

              <Typography variant="h6" gutterBottom>
                Available Reference Panels ({referencePanels.length})
              </Typography>

              {referencePanels.length === 0 ? (
                <Alert severity="info">
                  No reference panels found. Click "Sync Panels" to fetch the latest panels from this service.
                </Alert>
              ) : (
                <List>
                  {referencePanels.map((panel, index) => (
                    <React.Fragment key={panel.id}>
                      <ListItem>
                        <ListItemIcon>
                          {panel.is_active ? <CheckCircle color="success" /> : <Error color="error" />}
                        </ListItemIcon>
                        <ListItemText
                          primary={panel.name}
                          secondary={
                            <Box>
                              <Typography variant="body2" component="span">
                                Population: {panel.population || 'Mixed'} | 
                                Build: {panel.build || 'hg38'} | 
                                Samples: {panel.samples_count?.toLocaleString() || 'Unknown'}
                              </Typography>
                              {panel.description && (
                                <Typography variant="body2" color="text.secondary" mt={0.5}>
                                  {panel.description}
                                </Typography>
                              )}
                            </Box>
                          }
                        />
                      </ListItem>
                      {index < referencePanels.length - 1 && <Divider />}
                    </React.Fragment>
                  ))}
                </List>
              )}
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setDialogOpen(false)}>
                Close
              </Button>
              <Button 
                onClick={() => handleSyncPanels(selectedService.id)}
                disabled={syncing === selectedService.id}
                startIcon={syncing === selectedService.id ? <CircularProgress size={16} /> : <Sync />}
                variant="contained"
              >
                {syncing === selectedService.id ? 'Syncing...' : 'Sync Panels'}
              </Button>
            </DialogActions>
          </>
        )}
      </Dialog>

      {/* Operation Progress Backdrop */}
      {operationInProgress && (
        <Backdrop open={true} sx={{ color: '#fff', zIndex: (theme) => theme.zIndex.modal + 1 }}>
          <Box display="flex" flexDirection="column" alignItems="center" gap={2}>
            <CircularProgress size={60} />
            <Typography variant="h6" align="center">
              {operationInProgress}
            </Typography>
          </Box>
        </Backdrop>
      )}

      {/* Feedback Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={snackbar.severity === 'error' ? 8000 : 4000}
        onClose={closeFeedback}
        TransitionComponent={Fade}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <MuiAlert
          onClose={closeFeedback}
          severity={snackbar.severity}
          variant="filled"
          sx={{
            width: '100%',
            '& .MuiAlert-message': {
              fontSize: '0.95rem',
              fontWeight: 500
            }
          }}
          icon={
            snackbar.severity === 'success' ? <CheckCircleOutline /> :
            snackbar.severity === 'warning' ? <WarningAmber /> :
            snackbar.severity === 'info' ? <Info /> : undefined
          }
        >
          {snackbar.message}
        </MuiAlert>
      </Snackbar>

      {/* Service Management Dialog */}
      <ServiceManagement
        open={managementDialogOpen}
        onClose={handleManagementClose}
        onServiceUpdated={handleServiceUpdated}
        editService={editingService}
      />
    </Box>
  );
};

export default Services; 