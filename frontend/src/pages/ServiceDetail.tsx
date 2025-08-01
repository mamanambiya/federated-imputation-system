import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Button,
  Chip,
  Alert,
  CircularProgress,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Divider,
  Paper,
  IconButton,
  Tooltip,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  LinearProgress,
} from '@mui/material';
import {
  ArrowBack,
  CloudUpload,
  Speed,
  Storage,
  Group,
  Sync,
  CheckCircle,
  Error,
  ExpandMore,
  Info,
  Settings,
  Code,
  Refresh,
  Link as LinkIcon,
  Security,
  Description,
} from '@mui/icons-material';
import { useApi, ImputationService, ReferencePanel } from '../contexts/ApiContext';

interface ServiceInfo {
  supported_wes_versions?: string[];
  workflow_engine_versions?: Record<string, string>;
  system_state_counts?: Record<string, number>;
  supported_filesystem_protocols?: string[];
  tags?: Record<string, string>;
  contact_info_url?: string;
  auth_instructions_url?: string;
  default_workflow_engine_parameters?: Array<{
    name: string;
    type: string;
    default_value?: any;
  }>;
}

const ServiceDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { getService, getServiceReferencePanels, syncReferencePanels } = useApi();
  
  const [service, setService] = useState<ImputationService | null>(null);
  const [panels, setPanels] = useState<ReferencePanel[]>([]);
  const [serviceInfo, setServiceInfo] = useState<ServiceInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (id) {
      loadServiceDetails();
    }
  }, [id]);

  const loadServiceDetails = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const serviceData = await getService(Number(id));
      setService(serviceData);
      
      // Load panels
      const panelsData = await getServiceReferencePanels(Number(id));
      setPanels(panelsData);
      
      // If it's a GA4GH service, extract service info from api_config
      if (serviceData.api_type === 'ga4gh' && serviceData.api_config?._service_info?.data) {
        setServiceInfo(serviceData.api_config._service_info.data);
      }
    } catch (err) {
      setError('Failed to load service details');
      console.error('Error loading service:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSync = async () => {
    try {
      setSyncing(true);
      await syncReferencePanels(Number(id));
      await loadServiceDetails(); // Reload to get updated data
    } catch (err) {
      console.error('Error syncing panels:', err);
    } finally {
      setSyncing(false);
    }
  };

  const handleRefresh = async () => {
    try {
      setRefreshing(true);
      await loadServiceDetails();
    } catch (err) {
      console.error('Error refreshing:', err);
    } finally {
      setRefreshing(false);
    }
  };

  const getServiceIcon = (serviceType: string) => {
    switch (serviceType) {
      case 'h3africa':
        return <Group sx={{ fontSize: 48 }} color="primary" />;
      case 'michigan':
        return <Speed sx={{ fontSize: 48 }} color="secondary" />;
      default:
        return <CloudUpload sx={{ fontSize: 48 }} />;
    }
  };

  const getJobStateColor = (state: string, count: number): string => {
    if (count === 0) return 'default';
    switch (state) {
      case 'RUNNING':
      case 'COMPLETE':
        return 'success';
      case 'QUEUED':
      case 'INITIALIZING':
        return 'info';
      case 'EXECUTOR_ERROR':
      case 'SYSTEM_ERROR':
        return 'error';
      case 'PAUSED':
      case 'CANCELED':
        return 'warning';
      default:
        return 'default';
    }
  };

  const calculateTotalJobs = (states: Record<string, number>): number => {
    return Object.values(states).reduce((sum, count) => sum + count, 0);
  };

  const extractWorkflowParams = (params: any[]): Record<string, any[]> => {
    const grouped: Record<string, any[]> = {};
    params.forEach(param => {
      const [engine] = param.name.split('|');
      if (!grouped[engine]) grouped[engine] = [];
      const paramName = param.name.split('|')[2] || param.name;
      grouped[engine].push({
        name: paramName,
        type: param.type,
        default: param.default_value,
      });
    });
    return grouped;
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  if (error || !service) {
    return (
      <Box>
        <Button startIcon={<ArrowBack />} onClick={() => navigate('/services')} sx={{ mb: 2 }}>
          Back to Services
        </Button>
        <Alert severity="error">
          {error || 'Service not found'}
        </Alert>
      </Box>
    );
  }

  const workflowParams = serviceInfo?.default_workflow_engine_parameters 
    ? extractWorkflowParams(serviceInfo.default_workflow_engine_parameters)
    : {};

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box display="flex" alignItems="center" mb={3}>
        <IconButton onClick={() => navigate('/services')} sx={{ mr: 2 }}>
          <ArrowBack />
        </IconButton>
        <Box flexGrow={1}>
          <Typography variant="h4" gutterBottom>
            {service.name}
          </Typography>
          <Box display="flex" gap={1} alignItems="center">
            <Chip 
              label={service.service_type.toUpperCase()} 
              color={service.service_type === 'h3africa' ? 'primary' : 'secondary'}
            />
            <Chip 
              label={service.api_type?.toUpperCase() || 'API'} 
              variant="outlined"
            />
            <Chip 
              label={service.is_active ? 'Active' : 'Inactive'} 
              color={service.is_active ? 'success' : 'default'}
              size="small"
            />
          </Box>
        </Box>
        <Box display="flex" gap={1}>
          <Tooltip title="Refresh">
            <IconButton onClick={handleRefresh} disabled={refreshing}>
              {refreshing ? <CircularProgress size={24} /> : <Refresh />}
            </IconButton>
          </Tooltip>
          <Button
            variant="contained"
            startIcon={syncing ? <CircularProgress size={20} /> : <Sync />}
            onClick={handleSync}
            disabled={syncing}
          >
            {syncing ? 'Syncing...' : 'Sync Panels'}
          </Button>
        </Box>
      </Box>

      <Grid container spacing={3}>
        {/* Basic Information Card */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <Info sx={{ mr: 1 }} />
                <Typography variant="h6">Basic Information</Typography>
              </Box>
              
              <Box display="flex" alignItems="center" mb={3}>
                {getServiceIcon(service.service_type)}
                <Box ml={2}>
                  <Typography variant="body2" color="text.secondary">
                    {service.description}
                  </Typography>
                </Box>
              </Box>

              <List dense>
                <ListItem>
                  <ListItemText 
                    primary="API URL"
                    secondary={
                      <Box display="flex" alignItems="center" gap={1}>
                        <Typography variant="body2" component="span">
                          {service.api_url}
                        </Typography>
                        <IconButton size="small" href={service.api_url} target="_blank">
                          <LinkIcon fontSize="small" />
                        </IconButton>
                      </Box>
                    }
                  />
                </ListItem>
                <ListItem>
                  <ListItemText 
                    primary="Max File Size"
                    secondary={`${service.max_file_size_mb} MB`}
                  />
                </ListItem>
                <ListItem>
                  <ListItemText 
                    primary="Supported Formats"
                    secondary={service.supported_formats?.join(', ') || 'VCF, PLINK'}
                  />
                </ListItem>
                <ListItem>
                  <ListItemText 
                    primary="Authentication Required"
                    secondary={service.api_key_required ? 'Yes' : 'No'}
                  />
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* Service Statistics Card */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <Settings sx={{ mr: 1 }} />
                <Typography variant="h6">Service Statistics</Typography>
              </Box>

              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <Paper elevation={0} sx={{ p: 2, bgcolor: 'primary.light', color: 'primary.contrastText' }}>
                    <Typography variant="h4" align="center">
                      {panels.length}
                    </Typography>
                    <Typography variant="body2" align="center">
                      Reference Panels
                    </Typography>
                  </Paper>
                </Grid>
                
                {serviceInfo?.system_state_counts && (
                  <Grid item xs={6}>
                    <Paper elevation={0} sx={{ p: 2, bgcolor: 'secondary.light', color: 'secondary.contrastText' }}>
                      <Typography variant="h4" align="center">
                        {calculateTotalJobs(serviceInfo.system_state_counts)}
                      </Typography>
                      <Typography variant="body2" align="center">
                        Total Jobs
                      </Typography>
                    </Paper>
                  </Grid>
                )}
              </Grid>

              {/* Job States for GA4GH */}
              {serviceInfo?.system_state_counts && (
                <Box mt={2}>
                  <Typography variant="subtitle2" gutterBottom>
                    Job States
                  </Typography>
                  <Box display="flex" flexWrap="wrap" gap={1}>
                    {Object.entries(serviceInfo.system_state_counts).map(([state, count]) => (
                      <Chip
                        key={state}
                        label={`${state}: ${count}`}
                        size="small"
                        color={getJobStateColor(state, count) as any}
                        variant={count > 0 ? 'filled' : 'outlined'}
                      />
                    ))}
                  </Box>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* GA4GH Specific Information */}
        {service.api_type === 'ga4gh' && serviceInfo && (
          <Grid item xs={12}>
            <Accordion defaultExpanded>
              <AccordionSummary expandIcon={<ExpandMore />}>
                <Box display="flex" alignItems="center">
                  <Code sx={{ mr: 1 }} />
                  <Typography variant="h6">GA4GH WES Information</Typography>
                </Box>
              </AccordionSummary>
              <AccordionDetails>
                <Grid container spacing={2}>
                  {/* Workflow Engines */}
                  {serviceInfo.workflow_engine_versions && (
                    <Grid item xs={12} md={6}>
                      <Typography variant="subtitle1" gutterBottom>
                        Workflow Engines
                      </Typography>
                      <List dense>
                        {Object.entries(serviceInfo.workflow_engine_versions).map(([engine, version]) => (
                          <ListItem key={engine}>
                            <ListItemIcon>
                              <Settings />
                            </ListItemIcon>
                            <ListItemText 
                              primary={engine}
                              secondary={`Version ${version}`}
                            />
                          </ListItem>
                        ))}
                      </List>
                    </Grid>
                  )}

                  {/* Storage Protocols */}
                  {serviceInfo.supported_filesystem_protocols && (
                    <Grid item xs={12} md={6}>
                      <Typography variant="subtitle1" gutterBottom>
                        Supported Storage
                      </Typography>
                      <Box display="flex" gap={1} flexWrap="wrap">
                        {serviceInfo.supported_filesystem_protocols.map(protocol => (
                          <Chip
                            key={protocol}
                            icon={<Storage />}
                            label={protocol.toUpperCase()}
                            variant="outlined"
                          />
                        ))}
                      </Box>
                    </Grid>
                  )}

                  {/* Contact & Auth */}
                  <Grid item xs={12}>
                    <Box display="flex" gap={2} flexWrap="wrap">
                      {serviceInfo.contact_info_url && (
                        <Button
                          size="small"
                          startIcon={<Description />}
                          href={serviceInfo.contact_info_url}
                          target="_blank"
                        >
                          Contact Support
                        </Button>
                      )}
                      {serviceInfo.auth_instructions_url && (
                        <Button
                          size="small"
                          startIcon={<Security />}
                          href={serviceInfo.auth_instructions_url}
                          target="_blank"
                        >
                          Auth Documentation
                        </Button>
                      )}
                    </Box>
                  </Grid>
                </Grid>
              </AccordionDetails>
            </Accordion>
          </Grid>
        )}

        {/* Workflow Parameters for GA4GH */}
        {Object.keys(workflowParams).length > 0 && (
          <Grid item xs={12}>
            <Accordion>
              <AccordionSummary expandIcon={<ExpandMore />}>
                <Box display="flex" alignItems="center">
                  <Settings sx={{ mr: 1 }} />
                  <Typography variant="h6">Workflow Parameters</Typography>
                </Box>
              </AccordionSummary>
              <AccordionDetails>
                <Grid container spacing={2}>
                  {Object.entries(workflowParams).map(([engine, params]) => (
                    <Grid item xs={12} md={6} key={engine}>
                      <Typography variant="subtitle1" gutterBottom>
                        {engine} Parameters ({params.length})
                      </Typography>
                      <Paper variant="outlined" sx={{ p: 2, maxHeight: 300, overflow: 'auto' }}>
                        <List dense>
                          {params.map((param: any, index: number) => (
                            <React.Fragment key={index}>
                              <ListItem>
                                <ListItemText
                                  primary={param.name}
                                  secondary={
                                    <Box>
                                      <Typography variant="caption" component="span" color="text.secondary">
                                        Type: {param.type}
                                      </Typography>
                                      {param.default !== undefined && param.default !== null && (
                                        <Typography variant="caption" component="span" color="success.main" sx={{ ml: 1 }}>
                                          Default: {String(param.default)}
                                        </Typography>
                                      )}
                                    </Box>
                                  }
                                />
                              </ListItem>
                              {index < params.length - 1 && <Divider />}
                            </React.Fragment>
                          ))}
                        </List>
                      </Paper>
                    </Grid>
                  ))}
                </Grid>
              </AccordionDetails>
            </Accordion>
          </Grid>
        )}

        {/* Reference Panels */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
                <Box display="flex" alignItems="center">
                  <Storage sx={{ mr: 1 }} />
                  <Typography variant="h6">
                    Reference Panels ({panels.length})
                  </Typography>
                </Box>
              </Box>

              {panels.length === 0 ? (
                <Alert severity="info">
                  No reference panels found. Click "Sync Panels" to fetch the latest panels from this service.
                </Alert>
              ) : (
                <List>
                  {panels.map((panel, index) => (
                    <React.Fragment key={panel.id}>
                      <ListItem>
                        <ListItemIcon>
                          {panel.is_active ? <CheckCircle color="success" /> : <Error color="error" />}
                        </ListItemIcon>
                        <ListItemText
                          primary={
                            <Box display="flex" alignItems="center" gap={1}>
                              <Typography variant="subtitle1">
                                {panel.name}
                              </Typography>
                              <Chip label={panel.panel_id} size="small" variant="outlined" />
                            </Box>
                          }
                          secondary={
                            <Box>
                              <Box display="flex" gap={2} mt={0.5}>
                                <Typography variant="body2" component="span">
                                  <strong>Population:</strong> {panel.population || 'Mixed'}
                                </Typography>
                                <Typography variant="body2" component="span">
                                  <strong>Build:</strong> {panel.build || 'hg38'}
                                </Typography>
                                {panel.samples_count && (
                                  <Typography variant="body2" component="span">
                                    <strong>Samples:</strong> {panel.samples_count.toLocaleString()}
                                  </Typography>
                                )}
                              </Box>
                              {panel.description && (
                                <Typography variant="body2" color="text.secondary" mt={0.5}>
                                  {panel.description}
                                </Typography>
                              )}
                            </Box>
                          }
                        />
                      </ListItem>
                      {index < panels.length - 1 && <Divider />}
                    </React.Fragment>
                  ))}
                </List>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default ServiceDetail; 