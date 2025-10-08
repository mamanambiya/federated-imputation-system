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
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Badge,
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
  LocationOn,
  Schedule,
  DataUsage,
  Memory,
  Backup,
  Api,
  Public,
  Computer,
  Timeline,
  AccessTime,
  Engineering,
  CloudDone,
  VerifiedUser,
  Psychology,
  Biotech,
  DeviceHub,
  LocalOffer,
  Edit as EditIcon,
} from '@mui/icons-material';
import { useApi, ImputationService, ReferencePanel } from '../contexts/ApiContext';
import ServiceManagement from '../components/ServiceManagement';

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
  // Additional GA4GH service info fields
  id?: string;
  name?: string;
  type?: {
    group: string;
    artifact: string;
    version: string;
  };
  description?: string;
  organization?: {
    name: string;
    url?: string;
  };
  contactUrl?: string;
  documentationUrl?: string;
  createdAt?: string;
  updatedAt?: string;
  environment?: string;
  version?: string;
  workflow_type_versions?: Record<string, any>;
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
  const [editDialogOpen, setEditDialogOpen] = useState(false);

  useEffect(() => {
    if (id) {
      loadServiceDetails();
    }
  }, [id]);

  const loadServiceDetails = async () => {
    console.log('[ServiceDetail] Starting to load service details for ID:', id);
    try {
      setLoading(true);
      setError(null);

      console.log('[ServiceDetail] Fetching service data...');
      const serviceData = await getService(Number(id));
      console.log('[ServiceDetail] Service data received:', serviceData.name);
      setService(serviceData);

      // Load panels (optional - may not exist in microservices architecture)
      try {
        console.log('[ServiceDetail] Fetching reference panels...');
        const panelsData = await getServiceReferencePanels(Number(id));
        console.log('[ServiceDetail] Reference panels received:', panelsData.length);
        setPanels(panelsData);
      } catch (panelError) {
        console.log('[ServiceDetail] Reference panels not available for this service (expected)');
        setPanels([]);
      }

      // If it's a GA4GH service, extract service info from api_config
      if (serviceData.api_type === 'ga4gh' && serviceData.api_config?._service_info?.data) {
        console.log('[ServiceDetail] Extracting GA4GH service info');
        setServiceInfo(serviceData.api_config._service_info.data);
      }

      console.log('[ServiceDetail] Service details loaded successfully');
    } catch (err) {
      console.error('[ServiceDetail] Error loading service:', err);
      setError('Failed to load service details');
    } finally {
      console.log('[ServiceDetail] Setting loading to false');
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

  const handleEditService = () => {
    setEditDialogOpen(true);
  };

  const handleEditClose = () => {
    setEditDialogOpen(false);
  };

  const handleServiceUpdated = async () => {
    setEditDialogOpen(false);
    await loadServiceDetails(); // Refresh service details after update
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

  const workflowParams = (serviceInfo?.default_workflow_engine_parameters && serviceInfo.default_workflow_engine_parameters.length > 0)
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
              label={service.is_active ? 'Online' : 'Offline'}
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
            variant="outlined"
            startIcon={<EditIcon />}
            onClick={handleEditService}
          >
            Edit Service
          </Button>
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
                {(service.api_url || service.base_url) && (
                  <ListItem>
                    <ListItemText
                      primary="API URL"
                      secondary={
                        <Box display="flex" alignItems="center" gap={1}>
                          <Typography variant="body2" component="span">
                            {service.api_url || service.base_url}
                          </Typography>
                          <IconButton
                            size="small"
                            component="a"
                            href={service.api_url || service.base_url}
                            target="_blank"
                            rel="noopener noreferrer"
                          >
                            <LinkIcon fontSize="small" />
                          </IconButton>
                        </Box>
                      }
                    />
                  </ListItem>
                )}
                {(service.location_city || service.location_country || service.location) && (
                  <ListItem>
                    <ListItemIcon>
                      <LocationOn />
                    </ListItemIcon>
                    <ListItemText
                      primary="Location"
                      secondary={
                        service.location_datacenter || service.location_city || service.location_country
                          ? `${service.location_datacenter ? service.location_datacenter + ', ' : ''}${service.location_city ? service.location_city + ', ' : ''}${service.location_country || ''}`
                          : service.location
                      }
                    />
                  </ListItem>
                )}
                <ListItem>
                  <ListItemText 
                    primary="Authentication Required"
                    secondary={service.api_key_required ? 'Yes' : 'No'}
                  />
                </ListItem>
                <ListItem>
                  <ListItemIcon>
                    <Schedule />
                  </ListItemIcon>
                  <ListItemText 
                    primary="Created"
                    secondary={new Date(service.created_at).toLocaleDateString()}
                  />
                </ListItem>
                <ListItem>
                  <ListItemIcon>
                    <AccessTime />
                  </ListItemIcon>
                  <ListItemText 
                    primary="Last Updated"
                    secondary={new Date(service.updated_at).toLocaleDateString()}
                  />
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* Service Configuration Card */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <Engineering sx={{ mr: 1 }} />
                <Typography variant="h6">Service Configuration</Typography>
              </Box>
              
              <List dense>
                <ListItem>
                  <ListItemIcon>
                    <Api />
                  </ListItemIcon>
                  <ListItemText 
                    primary="API Type"
                    secondary={
                      <Chip 
                        label={service.api_type?.toUpperCase() || 'UNKNOWN'} 
                        size="small"
                        color="primary"
                        variant="outlined"
                      />
                    }
                  />
                </ListItem>
                <ListItem>
                  <ListItemIcon>
                    <DataUsage />
                  </ListItemIcon>
                  <ListItemText 
                    primary="Max File Size"
                    secondary={`${service.max_file_size_mb} MB`}
                  />
                </ListItem>
                <ListItem>
                  <ListItemIcon>
                    <Description />
                  </ListItemIcon>
                  <ListItemText 
                    primary="Supported Formats"
                    secondary={
                      <Box display="flex" gap={0.5} flexWrap="wrap" mt={0.5}>
                        {(service.supported_formats || ['VCF', 'PLINK']).map(format => (
                          <Chip 
                            key={format} 
                            label={format.toUpperCase()} 
                            size="small" 
                            variant="outlined"
                          />
                        ))}
                      </Box>
                    }
                  />
                </ListItem>
                <ListItem>
                  <ListItemIcon>
                    {service.api_key_required ? <Security /> : <Public />}
                  </ListItemIcon>
                  <ListItemText 
                    primary="Authentication"
                    secondary={
                      <Chip 
                        label={service.api_key_required ? 'API Key Required' : 'Public Access'} 
                        size="small"
                        color={service.api_key_required ? 'warning' : 'success'}
                      />
                    }
                  />
                </ListItem>

                {/* Resource Information */}
                {(service.cpu_total || service.memory_total_gb) && (
                  <>
                    {service.cpu_total && (
                      <ListItem>
                        <ListItemIcon>
                          <Memory />
                        </ListItemIcon>
                        <ListItemText
                          primary="CPU Resources"
                          secondary={`${service.cpu_available || service.cpu_total} / ${service.cpu_total} cores available`}
                        />
                      </ListItem>
                    )}
                    {service.memory_total_gb && (
                      <ListItem>
                        <ListItemIcon>
                          <DataUsage />
                        </ListItemIcon>
                        <ListItemText
                          primary="Memory Resources"
                          secondary={`${service.memory_available_gb?.toFixed(1) || service.memory_total_gb} / ${service.memory_total_gb} GB available`}
                        />
                      </ListItem>
                    )}
                  </>
                )}

                {service.api_config && Object.keys(service.api_config).length > 0 && (
                  <ListItem>
                    <ListItemIcon>
                      <Settings />
                    </ListItemIcon>
                    <ListItemText
                      primary="Additional Configuration"
                      secondary={`${Object.keys(service.api_config).length} configuration items`}
                    />
                  </ListItem>
                )}
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* Service Metadata Card - Enhanced Information */}
        {serviceInfo && (
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center" mb={2}>
                  <Psychology sx={{ mr: 1 }} />
                  <Typography variant="h6">Service Metadata</Typography>
                </Box>
                
                <Grid container spacing={3}>
                  {/* Service Identity */}
                  <Grid item xs={12} md={6}>
                    <Typography variant="subtitle1" gutterBottom>
                      Service Identity
                    </Typography>
                    <TableContainer component={Paper} variant="outlined">
                      <Table size="small">
                        <TableBody>
                          {serviceInfo.id && (
                            <TableRow>
                              <TableCell><strong>Service ID</strong></TableCell>
                              <TableCell>
                                <Typography variant="body2" sx={{ fontFamily: 'monospace', bgcolor: 'grey.100', p: 0.5, borderRadius: 1 }}>
                                  {serviceInfo.id}
                                </Typography>
                              </TableCell>
                            </TableRow>
                          )}
                          {serviceInfo.name && (
                            <TableRow>
                              <TableCell><strong>Service Name</strong></TableCell>
                              <TableCell>{serviceInfo.name}</TableCell>
                            </TableRow>
                          )}
                          {serviceInfo.version && (
                            <TableRow>
                              <TableCell><strong>Version</strong></TableCell>
                              <TableCell>
                                <Chip label={serviceInfo.version} size="small" color="info" />
                              </TableCell>
                            </TableRow>
                          )}
                          {serviceInfo.environment && (
                            <TableRow>
                              <TableCell><strong>Environment</strong></TableCell>
                              <TableCell>
                                <Chip 
                                  label={serviceInfo.environment} 
                                  size="small" 
                                  color={serviceInfo.environment === 'production' ? 'success' : 'warning'}
                                />
                              </TableCell>
                            </TableRow>
                          )}
                          {serviceInfo.type && (
                            <TableRow>
                              <TableCell><strong>Service Type</strong></TableCell>
                              <TableCell>
                                <Box>
                                  <Typography variant="body2">
                                    {serviceInfo.type.group}/{serviceInfo.type.artifact}
                                  </Typography>
                                  <Typography variant="caption" color="text.secondary">
                                    v{serviceInfo.type.version}
                                  </Typography>
                                </Box>
                              </TableCell>
                            </TableRow>
                          )}
                        </TableBody>
                      </Table>
                    </TableContainer>
                  </Grid>

                  {/* Organization & Contact */}
                  <Grid item xs={12} md={6}>
                    <Typography variant="subtitle1" gutterBottom>
                      Organization & Contact
                    </Typography>
                    <TableContainer component={Paper} variant="outlined">
                      <Table size="small">
                        <TableBody>
                          {serviceInfo.organization && (
                            <TableRow>
                              <TableCell><strong>Organization</strong></TableCell>
                              <TableCell>
                                {serviceInfo.organization.url ? (
                                  <Button 
                                    variant="text" 
                                    size="small" 
                                    component="a"
                                    href={serviceInfo.organization.url}
                                    target="_blank"
                                    endIcon={<LinkIcon />}
                                  >
                                    {serviceInfo.organization.name}
                                  </Button>
                                ) : (
                                  serviceInfo.organization.name
                                )}
                              </TableCell>
                            </TableRow>
                          )}
                          {(serviceInfo.contactUrl || serviceInfo.contact_info_url) && (
                            <TableRow>
                              <TableCell><strong>Contact</strong></TableCell>
                              <TableCell>
                                <Button 
                                  variant="outlined" 
                                  size="small" 
                                  component="a"
                                  href={serviceInfo.contactUrl || serviceInfo.contact_info_url}
                                  target="_blank"
                                  startIcon={<Description />}
                                >
                                  Contact Info
                                </Button>
                              </TableCell>
                            </TableRow>
                          )}
                          {serviceInfo.documentationUrl && (
                            <TableRow>
                              <TableCell><strong>Documentation</strong></TableCell>
                              <TableCell>
                                <Button 
                                  variant="outlined" 
                                  size="small" 
                                  component="a"
                                  href={serviceInfo.documentationUrl}
                                  target="_blank"
                                  startIcon={<Description />}
                                >
                                  API Docs
                                </Button>
                              </TableCell>
                            </TableRow>
                          )}
                          {serviceInfo.auth_instructions_url && (
                            <TableRow>
                              <TableCell><strong>Auth Guide</strong></TableCell>
                              <TableCell>
                                <Button 
                                  variant="outlined" 
                                  size="small" 
                                  component="a"
                                  href={serviceInfo.auth_instructions_url}
                                  target="_blank"
                                  startIcon={<Security />}
                                >
                                  Auth Instructions
                                </Button>
                              </TableCell>
                            </TableRow>
                          )}
                        </TableBody>
                      </Table>
                    </TableContainer>
                  </Grid>

                  {/* Service Tags */}
                  {serviceInfo.tags && Object.keys(serviceInfo.tags).length > 0 && (
                    <Grid item xs={12}>
                      <Typography variant="subtitle1" gutterBottom>
                        Service Tags
                      </Typography>
                      <Box display="flex" gap={1} flexWrap="wrap">
                        {Object.entries(serviceInfo.tags).map(([key, value]) => (
                          <Chip
                            key={key}
                            label={`${key}: ${value}`}
                            variant="outlined"
                            size="small"
                            icon={<Info />}
                          />
                        ))}
                      </Box>
                    </Grid>
                  )}
                </Grid>
              </CardContent>
            </Card>
          </Grid>
        )}

        {/* API Configuration Details */}
        {service.api_config && Object.keys(service.api_config).length > 0 && (
          <Grid item xs={12}>
            <Accordion>
              <AccordionSummary expandIcon={<ExpandMore />}>
                <Box display="flex" alignItems="center">
                  <Computer sx={{ mr: 1 }} />
                  <Typography variant="h6">API Configuration Details</Typography>
                  <Chip 
                    label={`${Object.keys(service.api_config).length} items`}
                    size="small"
                    sx={{ ml: 2 }}
                  />
                </Box>
              </AccordionSummary>
              <AccordionDetails>
                <TableContainer component={Paper} variant="outlined">
                  <Table size="small">
                    <TableHead>
                      <TableRow>
                        <TableCell><strong>Configuration Key</strong></TableCell>
                        <TableCell><strong>Value</strong></TableCell>
                        <TableCell><strong>Type</strong></TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {Object.entries(service.api_config).map(([key, value]) => (
                        <TableRow key={key}>
                          <TableCell>
                            <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
                              {key}
                            </Typography>
                          </TableCell>
                          <TableCell>
                            <Typography variant="body2" sx={{ 
                              maxWidth: 300, 
                              overflow: 'hidden',
                              textOverflow: 'ellipsis',
                              fontFamily: typeof value === 'object' ? 'monospace' : 'inherit'
                            }}>
                              {typeof value === 'object' 
                                ? JSON.stringify(value, null, 2) 
                                : String(value)
                              }
                            </Typography>
                          </TableCell>
                          <TableCell>
                            <Chip 
                              label={typeof value} 
                              size="small" 
                              variant="outlined"
                              color={typeof value === 'object' ? 'primary' : 'default'}
                            />
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              </AccordionDetails>
            </Accordion>
          </Grid>
        )}

        {/* Service Statistics Card */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <CloudDone sx={{ mr: 1 }} />
                <Typography variant="h6">Service Statistics & Metrics</Typography>
              </Box>

              <Grid container spacing={2} mb={2}>
                <Grid item xs={6} sm={3}>
                  <Paper elevation={0} sx={{ p: 2, bgcolor: 'primary.light', color: 'primary.contrastText', textAlign: 'center' }}>
                    <Badge badgeContent={panels.filter(p => p.is_active).length} color="success">
                      <Storage sx={{ fontSize: 32, mb: 1 }} />
                    </Badge>
                    <Typography variant="h4" align="center">
                      {panels.length}
                    </Typography>
                    <Typography variant="body2" align="center">
                      Reference Panels
                    </Typography>
                  </Paper>
                </Grid>
                
                <Grid item xs={6} sm={3}>
                  <Paper elevation={0} sx={{ p: 2, bgcolor: 'info.light', color: 'info.contrastText', textAlign: 'center' }}>
                    <Memory sx={{ fontSize: 32, mb: 1 }} />
                    <Typography variant="h4" align="center">
                      {service.max_file_size_mb}
                    </Typography>
                    <Typography variant="body2" align="center">
                      Max Size (MB)
                    </Typography>
                  </Paper>
                </Grid>

                <Grid item xs={6} sm={3}>
                  <Paper elevation={0} sx={{ p: 2, bgcolor: 'success.light', color: 'success.contrastText', textAlign: 'center' }}>
                    <VerifiedUser sx={{ fontSize: 32, mb: 1 }} />
                    <Typography variant="h4" align="center">
                      {service.supported_formats?.length || 2}
                    </Typography>
                    <Typography variant="body2" align="center">
                      File Formats
                    </Typography>
                  </Paper>
                </Grid>

                {serviceInfo?.system_state_counts && (
                  <Grid item xs={6} sm={3}>
                    <Paper elevation={0} sx={{ p: 2, bgcolor: 'secondary.light', color: 'secondary.contrastText', textAlign: 'center' }}>
                      <Timeline sx={{ fontSize: 32, mb: 1 }} />
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

              {/* Additional Metrics */}
              <Box mb={2}>
                <Typography variant="subtitle2" gutterBottom>
                  Service Health Indicators
                </Typography>
                <Grid container spacing={1}>
                  <Grid item>
                    <Chip
                      icon={service.is_active ? <CheckCircle /> : <Error />}
                      label={service.is_active ? 'Service Online' : 'Service Offline'}
                      color={service.is_active ? 'success' : 'error'}
                      size="small"
                    />
                  </Grid>
                  <Grid item>
                    <Chip
                      icon={<Security />}
                      label={service.api_key_required ? 'Secured' : 'Public Access'}
                      color={service.api_key_required ? 'warning' : 'info'}
                      size="small"
                    />
                  </Grid>
                  {serviceInfo?.supported_wes_versions && (
                    <Grid item>
                      <Chip
                        icon={<Api />}
                        label={`WES v${serviceInfo.supported_wes_versions[0] || '1.0'}`}
                        color="primary"
                        size="small"
                      />
                    </Grid>
                  )}
                  {(service.location_city || service.location_country || service.location) && (
                    <Grid item>
                      <Chip
                        icon={<LocationOn />}
                        label={
                          service.location_city || service.location_country
                            ? `${service.location_city ? service.location_city + ', ' : ''}${service.location_country || ''}`
                            : service.location
                        }
                        variant="outlined"
                        size="small"
                      />
                    </Grid>
                  )}
                </Grid>
              </Box>

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

        {/* GA4GH WES Specific Information */}
        {service.api_type === 'ga4gh' && serviceInfo && (
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center" mb={2}>
                  <Biotech sx={{ mr: 1 }} />
                  <Typography variant="h6">GA4GH WES Service Details</Typography>
                </Box>
                
                <Grid container spacing={3}>
                  {/* WES Capabilities */}
                  <Grid item xs={12} md={6}>
                    <Paper elevation={1} sx={{ p: 2, height: '100%' }}>
                      <Typography variant="subtitle1" gutterBottom color="primary">
                        <Speed sx={{ mr: 1, verticalAlign: 'middle' }} />
                        WES Capabilities
                      </Typography>
                      
                      {serviceInfo.supported_wes_versions && (
                        <Box mb={2}>
                          <Typography variant="body2" color="text.secondary">
                            Supported WES Versions
                          </Typography>
                          <Box display="flex" gap={1} flexWrap="wrap" mt={1}>
                            {serviceInfo.supported_wes_versions.map((version, idx) => (
                              <Chip key={idx} label={`WES ${version}`} size="small" color="primary" />
                            ))}
                          </Box>
                        </Box>
                      )}
                      
                      {serviceInfo.supported_filesystem_protocols && (
                        <Box mb={2}>
                          <Typography variant="body2" color="text.secondary">
                            Filesystem Protocols
                          </Typography>
                          <Box display="flex" gap={1} flexWrap="wrap" mt={1}>
                            {serviceInfo.supported_filesystem_protocols.map((protocol, idx) => (
                              <Chip 
                                key={idx} 
                                label={protocol.toUpperCase()} 
                                size="small" 
                                variant="outlined"
                                color={protocol === 'S3' ? 'warning' : 'default'}
                              />
                            ))}
                          </Box>
                        </Box>
                      )}
                    </Paper>
                  </Grid>

                  {/* Workflow Engines */}
                  <Grid item xs={12} md={6}>
                    <Paper elevation={1} sx={{ p: 2, height: '100%' }}>
                      <Typography variant="subtitle1" gutterBottom color="primary">
                        <DeviceHub sx={{ mr: 1, verticalAlign: 'middle' }} />
                        Workflow Engines
                      </Typography>
                      
                      {serviceInfo.workflow_engine_versions && (
                        <Box mb={2}>
                          <Typography variant="body2" color="text.secondary" gutterBottom>
                            Available Engines
                          </Typography>
                          {Object.entries(serviceInfo.workflow_engine_versions).map(([engine, version]) => (
                            <Box key={engine} display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                              <Chip 
                                label={engine === 'NFL' ? 'Nextflow' : engine === 'SMK' ? 'Snakemake' : engine} 
                                color="secondary" 
                                size="small"
                              />
                              <Typography variant="body2" color="text.secondary">
                                v{version}
                              </Typography>
                            </Box>
                          ))}
                        </Box>
                      )}
                      
                      {serviceInfo.workflow_type_versions && (
                        <Box>
                          <Typography variant="body2" color="text.secondary" gutterBottom>
                            Workflow Type Support
                          </Typography>
                          {Object.entries(serviceInfo.workflow_type_versions).map(([type, info]) => (
                            <Box key={type} mb={1}>
                              <Typography variant="caption" display="block">
                                {type}: {(info as any).workflow_type_version?.join(', ') || 'Available'}
                              </Typography>
                            </Box>
                          ))}
                        </Box>
                      )}
                    </Paper>
                  </Grid>

                  {/* System Status */}
                  {serviceInfo.system_state_counts && (
                    <Grid item xs={12}>
                      <Paper elevation={1} sx={{ p: 2 }}>
                        <Typography variant="subtitle1" gutterBottom color="primary">
                          <Timeline sx={{ mr: 1, verticalAlign: 'middle' }} />
                          System Status & Job Statistics
                        </Typography>
                        
                        <Grid container spacing={2}>
                          {Object.entries(serviceInfo.system_state_counts).map(([state, count]) => (
                            <Grid item xs={6} sm={4} md={3} key={state}>
                              <Box 
                                sx={{ 
                                  p: 1.5, 
                                  border: 1, 
                                  borderColor: 'divider', 
                                  borderRadius: 1,
                                  textAlign: 'center',
                                  bgcolor: count > 0 ? 'action.hover' : 'background.paper'
                                }}
                              >
                                <Typography variant="h6" color={count > 0 ? 'primary' : 'text.secondary'}>
                                  {count}
                                </Typography>
                                <Typography variant="caption" display="block" color="text.secondary">
                                  {state.replace(/_/g, ' ')}
                                </Typography>
                              </Box>
                            </Grid>
                          ))}
                        </Grid>
                        
                        <Box mt={2}>
                          <Typography variant="body2" color="text.secondary">
                            Total Jobs: {Object.values(serviceInfo.system_state_counts).reduce((a: number, b: number) => a + b, 0)}
                          </Typography>
                        </Box>
                      </Paper>
                    </Grid>
                  )}

                  {/* Workflow Parameters */}
                  {serviceInfo?.default_workflow_engine_parameters && serviceInfo.default_workflow_engine_parameters.length > 0 && (
                    <Grid item xs={12}>
                      <Accordion>
                        <AccordionSummary expandIcon={<ExpandMore />}>
                          <Box display="flex" alignItems="center">
                            <Settings sx={{ mr: 1 }} />
                            <Typography variant="subtitle1">
                              Workflow Engine Parameters ({serviceInfo.default_workflow_engine_parameters.length})
                            </Typography>
                          </Box>
                        </AccordionSummary>
                        <AccordionDetails>
                          <TableContainer component={Paper} variant="outlined">
                            <Table size="small">
                              <TableHead>
                                <TableRow>
                                  <TableCell><strong>Engine</strong></TableCell>
                                  <TableCell><strong>Parameter</strong></TableCell>
                                  <TableCell><strong>Type</strong></TableCell>
                                  <TableCell><strong>Default</strong></TableCell>
                                </TableRow>
                              </TableHead>
                              <TableBody>
                                {serviceInfo.default_workflow_engine_parameters.map((param, idx) => {
                                  const [engine, version, paramName] = (param?.name || '').split('|');
                                  return (
                                    <TableRow key={idx} hover>
                                      <TableCell>
                                        <Chip 
                                          label={engine === 'NFL' ? 'Nextflow' : engine === 'SMK' ? 'Snakemake' : engine}
                                          size="small"
                                          color={engine === 'NFL' ? 'primary' : 'secondary'}
                                        />
                                      </TableCell>
                                      <TableCell>
                                        <Typography variant="body2" component="code">
                                          {paramName}
                                        </Typography>
                                      </TableCell>
                                      <TableCell>
                                        <Typography variant="caption" color="text.secondary">
                                          {param.type}
                                        </Typography>
                                      </TableCell>
                                      <TableCell>
                                        <Typography variant="body2">
                                          {param.default_value || 
                                            <em style={{ color: '#666' }}>null</em>
                                          }
                                        </Typography>
                                      </TableCell>
                                    </TableRow>
                                  );
                                })}
                              </TableBody>
                            </Table>
                          </TableContainer>
                          
                          <Box mt={2}>
                                                         <Typography variant="body2" color="text.secondary">
                               Engine Breakdown: {
                                 Object.entries(
                                   serviceInfo.default_workflow_engine_parameters.reduce((acc: Record<string, number>, param) => {
                                     const engine = param.name.split('|')[0];
                                     acc[engine] = (acc[engine] || 0) + 1;
                                     return acc;
                                   }, {})
                                 ).map(([engine, count]) => `${engine}: ${count} params`).join(', ')
                               }
                             </Typography>
                          </Box>
                        </AccordionDetails>
                      </Accordion>
                    </Grid>
                  )}

                  {/* Service Tags */}
                  {serviceInfo.tags && Object.keys(serviceInfo.tags).length > 0 && (
                    <Grid item xs={12}>
                      <Paper elevation={1} sx={{ p: 2 }}>
                        <Typography variant="subtitle1" gutterBottom color="primary">
                          <LocalOffer sx={{ mr: 1, verticalAlign: 'middle' }} />
                          Service Tags & Metadata
                        </Typography>
                        
                        <Box display="flex" gap={1} flexWrap="wrap">
                          {Object.entries(serviceInfo.tags).map(([key, value]) => (
                            <Tooltip key={key} title={`${key}: ${value}`}>
                              <Chip 
                                label={`${key}=${value}`}
                                variant="outlined"
                                size="small"
                                color="info"
                              />
                            </Tooltip>
                          ))}
                        </Box>
                      </Paper>
                    </Grid>
                  )}
                </Grid>
              </CardContent>
            </Card>
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
                  {panels.map((panel, index) => {
                    // Extract version from panel_id if it exists (e.g., "apps@h3africa-v6hc-s@1.0.0" -> "1.0.0")
                    const versionMatch = panel.panel_id?.match(/@([\d.]+)$/);
                    const version = versionMatch ? versionMatch[1] : null;

                    return (
                      <React.Fragment key={panel.id}>
                        <ListItem>
                          <ListItemIcon>
                            <CheckCircle color="success" />
                          </ListItemIcon>
                          <ListItemText
                            primary={
                              <Box display="flex" alignItems="center" gap={1} flexWrap="wrap">
                                <Typography variant="subtitle1">
                                  {panel.display_name || panel.name}
                                </Typography>
                                {panel.panel_id && (
                                  <Chip
                                    label={panel.panel_id}
                                    size="small"
                                    variant="outlined"
                                    color="primary"
                                    sx={{ fontFamily: 'monospace', fontSize: '0.75rem' }}
                                  />
                                )}
                                {version && (
                                  <Chip
                                    label={`v${version}`}
                                    size="small"
                                    color="info"
                                  />
                                )}
                                {panel.is_active !== undefined && (
                                  <Chip
                                    label={panel.is_active ? 'Active' : 'Inactive'}
                                    size="small"
                                    color={panel.is_active ? 'success' : 'default'}
                                  />
                                )}
                              </Box>
                            }
                            secondary={
                              <Box>
                                <Box display="flex" gap={2} mt={0.5} flexWrap="wrap">
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
                                  {panel.variants_count && (
                                    <Typography variant="body2" component="span">
                                      <strong>Variants:</strong> {panel.variants_count.toLocaleString()}
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
                    );
                  })}
                </List>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Service Management Dialog */}
      {service && (
        <ServiceManagement
          open={editDialogOpen}
          onClose={handleEditClose}
          onServiceUpdated={handleServiceUpdated}
          editService={service}
        />
      )}
    </Box>
  );
};

export default ServiceDetail; 