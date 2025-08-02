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

  useEffect(() => {
    loadServices();
  }, []);

  useEffect(() => {
    if (services.length > 0) {
      checkServicesHealth();
    }
  }, [services]);

  const checkServicesHealth = async () => {
    const healthStatus: Record<number, 'healthy' | 'unhealthy' | 'checking'> = {};
    
    // Set all services to checking status initially
    services.forEach(service => {
      healthStatus[service.id] = 'checking';
    });
    setServiceHealth(healthStatus);

    // Check each service health
    for (const service of services) {
      try {
        // Simple check - try to fetch service details
        const response = await fetch(`${process.env.REACT_APP_API_URL}/api/services/${service.id}/`, {
          credentials: 'include',
        });
        
        if (response.ok) {
          healthStatus[service.id] = 'healthy';
        } else {
          healthStatus[service.id] = 'unhealthy';
        }
      } catch (error) {
        console.error(`Health check failed for ${service.name}:`, error);
        healthStatus[service.id] = 'unhealthy';
      }
    }
    
    setServiceHealth({ ...healthStatus });
  };

  const loadServices = async () => {
    try {
      setLoading(true);
      const data = await getServices();
      setServices(data);
    } catch (err) {
      setError('Failed to load services');
      console.error('Error loading services:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleViewDetails = async (service: ImputationService) => {
    try {
      setSelectedService(service);
      setDialogOpen(true);
      const panels = await getServiceReferencePanels(service.id);
      setReferencePanels(panels);
    } catch (err) {
      console.error('Error loading reference panels:', err);
    }
  };

  const handleSyncPanels = async (serviceId: number) => {
    try {
      setSyncing(serviceId);
      await syncReferencePanels(serviceId);
      // Refresh the service data
      await loadServices();
      if (selectedService && selectedService.id === serviceId) {
        const panels = await getServiceReferencePanels(serviceId);
        setReferencePanels(panels);
      }
    } catch (err) {
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

      <Grid container spacing={3}>
        {services.map((service) => (
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
                  <Box display="flex" alignItems="center" mb={2}>
                    <LocationOn sx={{ fontSize: 16, mr: 1, color: 'text.secondary' }} />
                    <Typography variant="body2" color="text.secondary">
                      {service.location}
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
    </Box>
  );
};

export default Services; 