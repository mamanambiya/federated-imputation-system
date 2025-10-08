import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Chip,
  LinearProgress,
  Alert,
  Grid,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  CircularProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Avatar,
  Stack,
} from '@mui/material';
import {
  Add,
  Refresh,
  Visibility,
  Cancel,
  Replay,
  FilterList,
  Search,
  Storage,
  Group,
  Speed,
  AccessTime,
  Person,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { useApi, ImputationJob, ImputationService } from '../contexts/ApiContext';

const Jobs: React.FC = () => {
  const navigate = useNavigate();
  const { getJobs, getServices, cancelJob, retryJob, formatDuration } = useApi();
  
  const [jobs, setJobs] = useState<ImputationJob[]>([]);
  const [services, setServices] = useState<ImputationService[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  
  // Filters
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [serviceFilter, setServiceFilter] = useState('');
  const [showFilters, setShowFilters] = useState(false);

  // Action dialog
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    job: ImputationJob | null;
    action: 'cancel' | 'retry' | null;
  }>({ open: false, job: null, action: null });

  useEffect(() => {
    loadData();
  }, []);

  useEffect(() => {
    loadJobs();
  }, [searchTerm, statusFilter, serviceFilter]);

  const loadData = async () => {
    try {
      setLoading(true);
      const [jobsData, servicesData] = await Promise.all([
        getJobs(),
        getServices()
      ]);
      setJobs(jobsData);
      setServices(servicesData);
    } catch (err) {
      setError('Failed to load jobs');
      console.error('Error loading jobs:', err);
    } finally {
      setLoading(false);
    }
  };

  const loadJobs = async () => {
    try {
      const data = await getJobs(
        statusFilter || undefined,
        serviceFilter ? parseInt(serviceFilter) : undefined,
        searchTerm || undefined
      );
      setJobs(data);
    } catch (err) {
      console.error('Error loading jobs:', err);
    }
  };

  const handleAction = async (action: 'cancel' | 'retry', jobId: string) => {
    try {
      setActionLoading(jobId);
      
      if (action === 'cancel') {
        await cancelJob(jobId);
      } else if (action === 'retry') {
        await retryJob(jobId);
      }
      
      // Refresh jobs list
      await loadJobs();
      setActionDialog({ open: false, job: null, action: null });
    } catch (err) {
      console.error(`Error ${action}ing job:`, err);
    } finally {
      setActionLoading(null);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'success';
      case 'failed':
        return 'error';
      case 'cancelled':
        return 'default';
      case 'running':
        return 'info';
      case 'queued':
        return 'warning';
      default:
        return 'default';
    }
  };

  const getServiceIcon = (serviceType: string) => {
    switch (serviceType) {
      case 'h3africa':
        return <Group color="primary" />;
      case 'michigan':
        return <Speed color="secondary" />;
      default:
        return <Storage />;
    }
  };

  const formatDate = (dateString: string) => {
    return format(new Date(dateString), 'MMM dd, yyyy HH:mm');
  };

  const canCancel = (job: ImputationJob) => {
    return ['pending', 'queued', 'running'].includes(job.status);
  };

  const canRetry = (job: ImputationJob) => {
    return ['failed', 'cancelled'].includes(job.status);
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">
          Imputation Jobs
        </Typography>
        <Stack direction="row" spacing={2}>
          <Button
            variant="outlined"
            startIcon={<FilterList />}
            onClick={() => setShowFilters(!showFilters)}
          >
            {showFilters ? 'Hide' : 'Show'} Filters
          </Button>
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={loadJobs}
          >
            Refresh
          </Button>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => navigate('/jobs/new')}
          >
            New Job
          </Button>
        </Stack>
      </Box>

      {/* Filters */}
      {showFilters && (
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Grid container spacing={2}>
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  label="Search"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  InputProps={{
                    startAdornment: <Search sx={{ mr: 1, color: 'text.secondary' }} />,
                  }}
                />
              </Grid>
              <Grid item xs={12} md={4}>
                <FormControl fullWidth>
                  <InputLabel>Status</InputLabel>
                  <Select
                    value={statusFilter}
                    label="Status"
                    onChange={(e) => setStatusFilter(e.target.value)}
                  >
                    <MenuItem value="">All Statuses</MenuItem>
                    <MenuItem value="pending">Pending</MenuItem>
                    <MenuItem value="queued">Queued</MenuItem>
                    <MenuItem value="running">Running</MenuItem>
                    <MenuItem value="completed">Completed</MenuItem>
                    <MenuItem value="failed">Failed</MenuItem>
                    <MenuItem value="cancelled">Cancelled</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} md={4}>
                <FormControl fullWidth>
                  <InputLabel>Service</InputLabel>
                  <Select
                    value={serviceFilter}
                    label="Service"
                    onChange={(e) => setServiceFilter(e.target.value)}
                  >
                    <MenuItem value="">All Services</MenuItem>
                    {services.map((service) => (
                      <MenuItem key={service.id} value={service.id.toString()}>
                        {service.name}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      )}

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {/* Jobs Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Job Name</TableCell>
              <TableCell>Service</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Progress</TableCell>
              <TableCell>Created</TableCell>
              <TableCell>Duration</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {jobs.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                  <Typography variant="body1" color="text.secondary">
                    No jobs found. Create your first imputation job!
                  </Typography>
                  <Button
                    variant="contained"
                    startIcon={<Add />}
                    onClick={() => navigate('/jobs/new')}
                    sx={{ mt: 2 }}
                  >
                    New Job
                  </Button>
                </TableCell>
              </TableRow>
            ) : (
              jobs.map((job) => {
                // Find the service for this job
                const service = services.find(s => s.id === job.service_id);

                return (
                <TableRow key={job.id} hover>
                  <TableCell>
                    <Box>
                      <Typography variant="body1" fontWeight="medium">
                        {job.name}
                      </Typography>
                      {job.description && (
                        <Typography variant="caption" color="text.secondary">
                          {job.description}
                        </Typography>
                      )}
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Box display="flex" alignItems="center">
                      {service ? getServiceIcon(service.service_type) : <Storage />}
                      <Box ml={1}>
                        <Typography variant="body2">
                          {service?.name || `Service #${job.service_id}`}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          Panel #{job.reference_panel_id}
                        </Typography>
                      </Box>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={job.status.toUpperCase()}
                      color={getStatusColor(job.status) as any}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    <Box sx={{ width: 100 }}>
                      <LinearProgress
                        variant="determinate"
                        value={job.progress_percentage}
                        color={getStatusColor(job.status) as any}
                      />
                      <Typography variant="caption" color="text.secondary">
                        {job.progress_percentage}%
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Box display="flex" alignItems="center">
                      <AccessTime sx={{ fontSize: 16, mr: 0.5, color: 'text.secondary' }} />
                      <Typography variant="caption">
                        {formatDate(job.created_at)}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="caption">
                      {formatDuration(job.execution_time_seconds)}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">
                    <Stack direction="row" spacing={1}>
                      <Tooltip title="View Details">
                        <IconButton
                          size="small"
                          onClick={() => navigate(`/jobs/${job.id}`)}
                        >
                          <Visibility />
                        </IconButton>
                      </Tooltip>
                      {canCancel(job) && (
                        <Tooltip title="Cancel Job">
                          <IconButton
                            size="small"
                            color="error"
                            disabled={actionLoading === job.id}
                            onClick={() => setActionDialog({ 
                              open: true, 
                              job, 
                              action: 'cancel' 
                            })}
                          >
                            {actionLoading === job.id ? 
                              <CircularProgress size={16} /> : 
                              <Cancel />
                            }
                          </IconButton>
                        </Tooltip>
                      )}
                      {canRetry(job) && (
                        <Tooltip title="Retry Job">
                          <IconButton
                            size="small"
                            color="primary"
                            disabled={actionLoading === job.id}
                            onClick={() => setActionDialog({ 
                              open: true, 
                              job, 
                              action: 'retry' 
                            })}
                          >
                            {actionLoading === job.id ? 
                              <CircularProgress size={16} /> : 
                              <Replay />
                            }
                          </IconButton>
                        </Tooltip>
                      )}
                    </Stack>
                  </TableCell>
                </TableRow>
                );
              })
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Action Confirmation Dialog */}
      <Dialog
        open={actionDialog.open}
        onClose={() => setActionDialog({ open: false, job: null, action: null })}
      >
        <DialogTitle>
          Confirm {actionDialog.action === 'cancel' ? 'Cancellation' : 'Retry'}
        </DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to {actionDialog.action} the job "{actionDialog.job?.name}"?
          </Typography>
          {actionDialog.action === 'cancel' && (
            <Alert severity="warning" sx={{ mt: 2 }}>
              This action cannot be undone. The job will be stopped and marked as cancelled.
            </Alert>
          )}
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => setActionDialog({ open: false, job: null, action: null })}
          >
            Cancel
          </Button>
          <Button
            onClick={() => actionDialog.job && actionDialog.action && 
              handleAction(actionDialog.action, actionDialog.job.id)
            }
            variant="contained"
            color={actionDialog.action === 'cancel' ? 'error' : 'primary'}
            disabled={actionLoading !== null}
          >
            {actionDialog.action === 'cancel' ? 'Cancel Job' : 'Retry Job'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Jobs; 