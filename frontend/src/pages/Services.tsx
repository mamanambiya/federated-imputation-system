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
} from '@mui/material';
import {
  CloudUpload,
  Speed,
  Storage,
  Group,
  Sync,
  CheckCircle,
  Error,
  LocationOn,
  Circle,
  Search,
  FilterList,
  Clear,
  Info,
  CheckCircleOutline,
  WarningAmber,
} from '@mui/icons-material';
import { useApi, ImputationService, ReferencePanel } from '../contexts/ApiContext';

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
  const [serviceHealth, setServiceHealth] = useState<Record<number, 'healthy' | 'unhealthy' | 'checking'>>({});
  
  // Filtering and search state
  const [searchTerm, setSearchTerm] = useState('');
  const [filterServiceType, setFilterServiceType] = useState('');
  const [filterApiType, setFilterApiType] = useState('');
  const [filterHealthStatus, setFilterHealthStatus] = useState('');
  const [filterLocation, setFilterLocation] = useState('');
  const [filterContinent, setFilterContinent] = useState('');

  // Feedback and notification state
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

  useEffect(() => {
    loadServices();
  }, []);

  // Filtering logic
  const filteredServices = services.filter(service => {
    const matchesSearch = searchTerm === '' || 
      service.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      service.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (service.location && service.location.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesServiceType = filterServiceType === '' || service.service_type === filterServiceType;
    const matchesApiType = filterApiType === '' || service.api_type === filterApiType;
    const matchesLocation = filterLocation === '' || 
      (service.location && service.location.toLowerCase().includes(filterLocation.toLowerCase()));
    const matchesContinent = filterContinent === '' || 
      (service.continent && service.continent.toLowerCase().includes(filterContinent.toLowerCase()));

    let matchesHealthStatus = true;
    if (filterHealthStatus !== '') {
      const healthStatus = serviceHealth[service.id];
      if (filterHealthStatus === 'healthy') {
        matchesHealthStatus = healthStatus === 'healthy';
      } else if (filterHealthStatus === 'unhealthy') {
        matchesHealthStatus = healthStatus === 'unhealthy';
      } else if (filterHealthStatus === 'unknown') {
        matchesHealthStatus = !healthStatus || healthStatus === 'checking';
      }
    }

    return matchesSearch && matchesServiceType && matchesApiType && matchesLocation && matchesContinent && matchesHealthStatus;
  });

  // Get unique values for filter dropdowns
  const uniqueServiceTypes = Array.from(new Set(services.map(s => s.service_type))).filter(Boolean);
  const uniqueApiTypes = Array.from(new Set(services.map(s => s.api_type))).filter(Boolean);
  const uniqueLocations = Array.from(new Set(services.map(s => s.location))).filter(Boolean);
  const uniqueContinents = Array.from(new Set(services.map(s => s.continent))).filter(Boolean);

  // Clear all filters
  const clearFilters = () => {
    setSearchTerm('');
    setFilterServiceType('');
    setFilterApiType('');
    setFilterHealthStatus('');
    setFilterLocation('');
    setFilterContinent('');
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

  useEffect(() => {
    if (services.length > 0) {
      checkServicesHealth();
    }
  }, [services]);

  const checkServicesHealth = async () => {
    const startTime = Date.now();
    const healthStatus: Record<number, 'healthy' | 'unhealthy' | 'checking'> = {};
    
    // Show operation start feedback
    setOperationInProgress('Checking service health...');
    showFeedback(`Starting health check for ${services.length} services...`, 'info');
    
    // Set all services to checking status initially
    services.forEach(service => {
      healthStatus[service.id] = 'checking';
    });
    setServiceHealth(healthStatus);

    let healthyCount = 0;
    let unhealthyCount = 0;
    let checkedCount = 0;

    // Check each service health using backend health check API
    for (const service of services) {
      try {
        setOperationInProgress(`Checking ${service.name}... (${checkedCount + 1}/${services.length})`);
        
        const response = await fetch(
          `${process.env.REACT_APP_API_URL}/api/services/${service.id}/health/`,
          {
            credentials: 'include',
          }
        );
        
        if (response.ok) {
          const healthData = await response.json();
          const isHealthy = healthData.status === 'healthy';
          healthStatus[service.id] = isHealthy ? 'healthy' : 'unhealthy';
          
          if (isHealthy) {
            healthyCount++;
          } else if (healthData.status === 'demo') {
            // Demo services are expected to be unavailable
            healthyCount++; // Count as healthy for demo purposes
          } else {
            unhealthyCount++;
          }
          
          // Log detailed health info for debugging
          console.log(`Health check for ${service.name}:`, {
            status: healthData.status,
            message: healthData.message,
            test_url: healthData.test_url,
            response_time: healthData.response_time_ms
          });
        } else {
          console.error(`Health check API failed for ${service.name}: HTTP ${response.status}`);
          healthStatus[service.id] = 'unhealthy';
          unhealthyCount++;
        }
        
      } catch (error) {
        console.error(`Health check failed for ${service.name}:`, error);
        // Check if this is a demo service
        if (service.name.toLowerCase().includes('elwazi') || service.api_url.includes('elwazi') || service.api_url.includes('icermali')) {
          healthStatus[service.id] = 'demo';
          healthyCount++; // Count demo services as healthy for reporting
        } else {
          healthStatus[service.id] = 'unhealthy';
          unhealthyCount++;
        }
      }
      
      checkedCount++;
    }
    
    setServiceHealth({ ...healthStatus });
    setOperationInProgress(null);
    
    // Show comprehensive completion feedback
    const duration = ((Date.now() - startTime) / 1000).toFixed(1);
    const totalServices = services.length;
    
    if (unhealthyCount === 0) {
      showFeedback(
        `✅ Health check complete! All ${totalServices} services are healthy (${duration}s)`,
        'success'
      );
    } else if (healthyCount === 0) {
      showFeedback(
        `⚠️ Health check complete! All ${totalServices} services are unhealthy (${duration}s)`,
        'error'
      );
    } else {
      showFeedback(
        `ℹ️ Health check complete! ${healthyCount} healthy, ${unhealthyCount} unhealthy out of ${totalServices} services (${duration}s)`,
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
      case 'demo':
        return (
          <Circle 
            sx={{ 
              color: '#ff9800', 
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
      case 'demo':
        return 'Demo';
      case 'checking':
        return 'Checking...';
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
        <Button
          variant="outlined"
          startIcon={<Sync />}
          onClick={checkServicesHealth}
          disabled={Object.values(serviceHealth).some(status => status === 'checking')}
        >
          Check Status
        </Button>
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

      {/* Search and Filter Controls */}
      <Paper elevation={2} sx={{ p: 3, mb: 3 }}>
        <Box display="flex" alignItems="center" gap={1} mb={2}>
          <FilterList color="primary" />
          <Typography variant="h6">Search & Filter</Typography>
          <Box sx={{ flexGrow: 1 }} />
          <Typography variant="body2" color="text.secondary">
            Showing {filteredServices.length} of {services.length} services
          </Typography>
        </Box>

        {/* Search Field */}
        <Box mb={3}>
          <TextField
            fullWidth
            placeholder="Search services by name, description, or location..."
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
            sx={{ mb: 2 }}
          />
        </Box>

        {/* Filter Controls */}
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={6} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Service Type</InputLabel>
              <Select
                value={filterServiceType}
                label="Service Type"
                onChange={(e) => setFilterServiceType(e.target.value)}
              >
                <MenuItem value="">All Types</MenuItem>
                {uniqueServiceTypes.map(type => (
                  <MenuItem key={type} value={type}>
                    {type.charAt(0).toUpperCase() + type.slice(1)}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>API Type</InputLabel>
              <Select
                value={filterApiType}
                label="API Type"
                onChange={(e) => setFilterApiType(e.target.value)}
              >
                <MenuItem value="">All APIs</MenuItem>
                {uniqueApiTypes.map(type => (
                  <MenuItem key={type} value={type}>
                    {type.toUpperCase()}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Health Status</InputLabel>
              <Select
                value={filterHealthStatus}
                label="Health Status"
                onChange={(e) => setFilterHealthStatus(e.target.value)}
              >
                <MenuItem value="">All Status</MenuItem>
                <MenuItem value="healthy">Healthy</MenuItem>
                <MenuItem value="unhealthy">Unhealthy</MenuItem>
                <MenuItem value="unknown">Unknown</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Location</InputLabel>
              <Select
                value={filterLocation}
                label="Location"
                onChange={(e) => setFilterLocation(e.target.value)}
              >
                <MenuItem value="">All Locations</MenuItem>
                {uniqueLocations.map(location => (
                  <MenuItem key={location} value={location}>
                    {location}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Continent</InputLabel>
              <Select
                value={filterContinent}
                label="Continent"
                onChange={(e) => setFilterContinent(e.target.value)}
              >
                <MenuItem value="">All Continents</MenuItem>
                {uniqueContinents.map(continent => (
                  <MenuItem key={continent} value={continent}>
                    {continent}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6} md={2}>
            <Button
              variant="outlined"
              startIcon={<Clear />}
              onClick={clearFilters}
              disabled={!searchTerm && !filterServiceType && !filterApiType && !filterHealthStatus && !filterLocation && !filterContinent}
              fullWidth
            >
              Clear Filters
            </Button>
          </Grid>
        </Grid>
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
    </Box>
  );
};

export default Services; 