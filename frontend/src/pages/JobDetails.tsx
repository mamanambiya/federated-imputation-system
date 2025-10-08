import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
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
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Divider,
  CircularProgress,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Tabs,
  Tab,
  Accordion,
  AccordionSummary,
  AccordionDetails,
} from '@mui/material';
import {
  ArrowBack,
  Download,
  Cancel,
  Replay,
  Info,
  Schedule,
  Storage,
  Person,
  Settings,
  FileDownload,
  CheckCircle,
  Error,
  Refresh,
  ExpandMore,
  Code,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { useApi, ImputationJob, JobStatusUpdate, ResultFile, JobLog } from '../contexts/ApiContext';

// TabPanel component for conditional rendering
interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

const TabPanel: React.FC<TabPanelProps> = ({ children, value, index }) => {
  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`job-tabpanel-${index}`}
      aria-labelledby={`job-tab-${index}`}
    >
      {value === index && <Box sx={{ py: 3 }}>{children}</Box>}
    </div>
  );
};

const JobDetails: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { getJob, getJobStatusUpdates, getJobFiles, getJobLogs, cancelJob, retryJob, downloadFile, getServices, getReferencePanels, formatDuration, formatFileSize } = useApi();

  const [job, setJob] = useState<ImputationJob | null>(null);
  const [statusUpdates, setStatusUpdates] = useState<JobStatusUpdate[]>([]);
  const [resultFiles, setResultFiles] = useState<ResultFile[]>([]);
  const [jobLogs, setJobLogs] = useState<JobLog[]>([]);
  const [services, setServices] = useState<any[]>([]);
  const [referencePanels, setReferencePanels] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const [activeTab, setActiveTab] = useState(0);

  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    action: 'cancel' | 'retry' | null;
  }>({ open: false, action: null });

  useEffect(() => {
    if (id) {
      loadJobDetails();
    }
  }, [id]);

  const loadJobDetails = async () => {
    if (!id) return;

    try {
      setLoading(true);
      setError(null);

      // Use Promise.allSettled for resilient loading
      // Even if status updates or files fail, we can still show the job details
      const results = await Promise.allSettled([
        getJob(id),
        getJobStatusUpdates(id),
        getJobFiles(id),
        getJobLogs(id),
        getServices(),
        getReferencePanels()
      ]);

      // Extract successful results
      const jobData = results[0].status === 'fulfilled' ? results[0].value : null;
      const statusData = results[1].status === 'fulfilled' ? results[1].value : [];
      const filesData = results[2].status === 'fulfilled' ? results[2].value : [];
      const logsData = results[3].status === 'fulfilled' ? results[3].value : [];
      const servicesData = results[4].status === 'fulfilled' ? results[4].value : [];
      const panelsData = results[5].status === 'fulfilled' ? results[5].value : [];

      if (!jobData) {
        setError('Failed to load job data');
        return;
      }

      setJob(jobData);
      setStatusUpdates(statusData);
      setResultFiles(filesData);
      setJobLogs(logsData);
      setServices(servicesData);
      setReferencePanels(panelsData);

      // Log any partial failures for debugging
      if (results[1].status === 'rejected') {
        console.warn('Status updates not available:', results[1].reason);
      }
      if (results[2].status === 'rejected') {
        console.warn('Files not available:', results[2].reason);
      }
    } catch (err) {
      setError('Failed to load job details');
      console.error('Error loading job details:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadJobDetails();
    setRefreshing(false);
  };

  const handleAction = async (action: 'cancel' | 'retry') => {
    if (!job) return;
    
    try {
      setActionLoading(true);
      
      if (action === 'cancel') {
        await cancelJob(job.id);
      } else if (action === 'retry') {
        await retryJob(job.id);
      }
      
      // Refresh job details
      await loadJobDetails();
      setActionDialog({ open: false, action: null });
    } catch (err) {
      console.error(`Error ${action}ing job:`, err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleDownload = async (file: ResultFile) => {
    if (!job) return;
    
    try {
      const result = await downloadFile(job.id, file.id);
      
      if (result.download_url) {
        // Open external download URL
        window.open(result.download_url, '_blank');
      }
    } catch (err) {
      console.error('Error downloading file:', err);
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

  const canCancel = (job: ImputationJob) => {
    return ['pending', 'queued', 'running'].includes(job.status);
  };

  const canRetry = (job: ImputationJob) => {
    return ['failed', 'cancelled'].includes(job.status);
  };

  const getFileTypeIcon = (fileType: string) => {
    switch (fileType) {
      case 'input':
        return <FileDownload color="action" />;
      case 'result':
        return <Storage color="primary" />;
      default:
        return <FileDownload />;
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  if (error || !job) {
    return (
      <Box>
        <Button
          startIcon={<ArrowBack />}
          onClick={() => navigate('/jobs')}
          sx={{ mb: 2 }}
        >
          Back to Jobs
        </Button>
        <Alert severity="error">
          {error || 'Job not found'}
        </Alert>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box display="flex" alignItems="center">
          <Button
            startIcon={<ArrowBack />}
            onClick={() => navigate('/jobs')}
            sx={{ mr: 2 }}
          >
            Back
          </Button>
          <Box>
            <Typography variant="h4" component="h1">
              {job.name}
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Job ID: {job.id}
            </Typography>
          </Box>
        </Box>

        <Box display="flex" gap={1}>
          <IconButton onClick={handleRefresh} disabled={refreshing}>
            <Refresh />
          </IconButton>
          {canCancel(job) && (
            <Button
              variant="outlined"
              color="error"
              startIcon={<Cancel />}
              disabled={actionLoading}
              onClick={() => setActionDialog({ open: true, action: 'cancel' })}
            >
              Cancel
            </Button>
          )}
          {canRetry(job) && (
            <Button
              variant="outlined"
              color="primary"
              startIcon={<Replay />}
              disabled={actionLoading}
              onClick={() => setActionDialog({ open: true, action: 'retry' })}
            >
              Retry
            </Button>
          )}
        </Box>
      </Box>

      {/* Tabs Navigation */}
      <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
        <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)} aria-label="job details tabs">
          <Tab label="Details" id="job-tab-0" aria-controls="job-tabpanel-0" />
          <Tab label="Results" id="job-tab-1" aria-controls="job-tabpanel-1" />
          <Tab label="Logs" id="job-tab-2" aria-controls="job-tabpanel-2" />
        </Tabs>
      </Box>

      {/* Details Tab */}
      <TabPanel value={activeTab} index={0}>
        {/* Input Validation Section */}
        <Paper sx={{ p: 3, mb: 3, borderLeft: 4, borderColor: 'success.main' }}>
          <Typography variant="h5" gutterBottom sx={{ fontWeight: 600 }}>
            Input Validation
          </Typography>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6} md={4}>
              <Typography variant="body2" color="text.secondary">
                Valid VCF file(s) found
              </Typography>
              <Typography variant="h6" sx={{ mt: 0.5 }}>
                1
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Typography variant="body2" color="text.secondary">
                Samples
              </Typography>
              <Typography variant="h6" sx={{ mt: 0.5 }}>
                N/A
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Typography variant="body2" color="text.secondary">
                Chromosomes
              </Typography>
              <Typography variant="h6" sx={{ mt: 0.5 }}>
                N/A
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Typography variant="body2" color="text.secondary">
                SNPs
              </Typography>
              <Typography variant="h6" sx={{ mt: 0.5 }}>
                N/A
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Typography variant="body2" color="text.secondary">
                Chunks
              </Typography>
              <Typography variant="h6" sx={{ mt: 0.5 }}>
                N/A
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Typography variant="body2" color="text.secondary">
                Datatype
              </Typography>
              <Typography variant="h6" sx={{ mt: 0.5 }}>
                {job.phasing ? 'phased' : 'unphased'}
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Typography variant="body2" color="text.secondary">
                Build
              </Typography>
              <Typography variant="h6" sx={{ mt: 0.5 }}>
                {job.build}
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Typography variant="body2" color="text.secondary">
                Reference Panel
              </Typography>
              <Typography variant="h6" sx={{ mt: 0.5 }}>
                {referencePanels.find(p => p.id === job.reference_panel_id)?.name || `Panel #${job.reference_panel_id}`}
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Typography variant="body2" color="text.secondary">
                Population
              </Typography>
              <Typography variant="h6" sx={{ mt: 0.5 }}>
                {job.population || 'mixed'}
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Typography variant="body2" color="text.secondary">
                Phasing
              </Typography>
              <Typography variant="h6" sx={{ mt: 0.5 }}>
                {job.phasing ? 'eagle' : 'none'}
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Typography variant="body2" color="text.secondary">
                Mode
              </Typography>
              <Typography variant="h6" sx={{ mt: 0.5 }}>
                imputation
              </Typography>
            </Grid>
          </Grid>
        </Paper>

        {/* Quality Control Section */}
        <Paper sx={{ p: 3, mb: 3, borderLeft: 4, borderColor: 'warning.main' }}>
          <Typography variant="h5" gutterBottom sx={{ fontWeight: 600 }}>
            Quality Control
          </Typography>

          {/* Build Check */}
          <Box sx={{ mb: 2 }}>
            <Typography variant="body1" sx={{ mb: 1 }}>
              Uploaded data is {job.build} and reference is {referencePanels.find(p => p.id === job.reference_panel_id)?.build || job.build}.
            </Typography>
          </Box>

          {/* Lift Over */}
          <Box sx={{ mb: 2, p: 2, bgcolor: 'success.50', borderRadius: 1, borderLeft: 3, borderColor: 'success.main' }}>
            <Typography variant="body1" sx={{ fontWeight: 500 }}>
              Lift Over
            </Typography>
          </Box>

          {/* QC Statistics */}
          <Box sx={{ mb: 2 }}>
            <Typography variant="body1" sx={{ mb: 1 }}>
              Calculating QC Statistics
            </Typography>
          </Box>

          <Box sx={{ p: 2, bgcolor: 'grey.50', borderRadius: 1 }}>
            <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 1 }}>
              Statistics:
            </Typography>
            <Typography variant="body2">
              Alternative allele frequency &gt; 0.5 sites: N/A
            </Typography>
            <Typography variant="body2">
              Reference Overlap: N/A
            </Typography>
          </Box>
        </Paper>

        {/* Job Information Grid */}
        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Status
                </Typography>
                <Box display="flex" alignItems="center" mt={2}>
                  <Chip
                    label={job.status.toUpperCase()}
                    color={getStatusColor(job.status) as any}
                    size="medium"
                    sx={{ mr: 2 }}
                  />
                  {['pending', 'queued', 'running'].includes(job.status) && (
                    <Box sx={{ flexGrow: 1 }}>
                      <LinearProgress
                        variant="determinate"
                        value={job.progress_percentage}
                        color={getStatusColor(job.status) as any}
                        sx={{ height: 8, borderRadius: 4 }}
                      />
                      <Typography variant="caption" color="text.secondary" mt={0.5}>
                        {job.progress_percentage}%
                      </Typography>
                    </Box>
                  )}
                </Box>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Service Information
                </Typography>
                <Box mt={2}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Service
                  </Typography>
                  <Typography variant="body1" mb={2}>
                    {services.find(s => s.id === job.service_id)?.name || `Service #${job.service_id}`}
                  </Typography>
                  <Typography variant="subtitle2" color="text.secondary">
                    Reference Panel
                  </Typography>
                  <Typography variant="body1">
                    {referencePanels.find(p => p.id === job.reference_panel_id)?.name || `Panel #${job.reference_panel_id}`}
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Timing
                </Typography>
                <Grid container spacing={2} mt={1}>
                  <Grid item xs={6}>
                    <Typography variant="subtitle2" color="text.secondary">
                      Created
                    </Typography>
                    <Typography variant="body1">
                      {format(new Date(job.created_at), 'MMM dd, yyyy HH:mm')}
                    </Typography>
                  </Grid>
                  <Grid item xs={6}>
                    <Typography variant="subtitle2" color="text.secondary">
                      Duration
                    </Typography>
                    <Typography variant="body1">
                      {formatDuration(job.execution_time_seconds)}
                    </Typography>
                  </Grid>
                </Grid>
              </CardContent>
            </Card>
          </Grid>

          {job.description && (
            <Grid item xs={12} md={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Description
                  </Typography>
                  <Typography variant="body1" mt={2}>
                    {job.description}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          )}
        </Grid>
      </TabPanel>

      {/* Results Tab */}
      <TabPanel value={activeTab} index={1}>
        {resultFiles.length > 0 ? (
          <Card>
            <CardContent>
              <Typography variant="h5" gutterBottom sx={{ fontWeight: 600 }}>
                Result Files
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Download the imputation results and associated files below
              </Typography>

              <TableContainer component={Paper} sx={{ mt: 2 }}>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>File</TableCell>
                      <TableCell>Type</TableCell>
                      <TableCell>Size</TableCell>
                      <TableCell>Created</TableCell>
                      <TableCell align="right">Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {resultFiles.map((file) => (
                      <TableRow key={file.id}>
                        <TableCell>
                          <Box display="flex" alignItems="center">
                            {getFileTypeIcon(file.type)}
                            <Typography variant="body2" ml={1}>
                              {file.name}
                            </Typography>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={file.type.toUpperCase()}
                            size="small"
                            variant="outlined"
                          />
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {formatFileSize(file.size)}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="caption">
                            {format(new Date(file.created_at), 'MMM dd, HH:mm')}
                          </Typography>
                        </TableCell>
                        <TableCell align="right">
                          <Tooltip title="Download">
                            <IconButton
                              size="small"
                              onClick={() => handleDownload(file)}
                              disabled={file.type === 'input'}
                            >
                              <Download />
                            </IconButton>
                          </Tooltip>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        ) : (
          <Alert severity="info">
            No files available for this job yet.
          </Alert>
        )}
      </TabPanel>

      {/* Logs Tab */}
      <TabPanel value={activeTab} index={2}>
        <Card>
          <CardContent>
            <Typography variant="h5" gutterBottom sx={{ fontWeight: 600 }}>
              Job Execution Logs
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              Step-by-step execution logs from the imputation service
            </Typography>

            {jobLogs.length > 0 ? (
              <Box>
                {/* Group logs by step */}
                {Object.entries(
                  jobLogs.reduce((acc, log) => {
                    if (!acc[log.step_index]) {
                      acc[log.step_index] = { step_name: log.step_name, logs: [] };
                    }
                    acc[log.step_index].logs.push(log);
                    return acc;
                  }, {} as Record<number, { step_name: string; logs: JobLog[] }>)
                )
                  .sort(([a], [b]) => Number(a) - Number(b))
                  .map(([stepIndex, { step_name, logs }]) => (
                    <Box key={stepIndex} sx={{ mb: 3 }}>
                      <Typography variant="h6" sx={{ mb: 1, display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Chip label={`Step ${Number(stepIndex) + 1}`} size="small" color="primary" />
                        {step_name}
                      </Typography>
                      <Paper variant="outlined" sx={{ p: 2, bgcolor: 'grey.50' }}>
                        {logs.map((log, idx) => (
                          <Box
                            key={log.id}
                            sx={{
                              mb: idx < logs.length - 1 ? 1 : 0,
                              display: 'flex',
                              alignItems: 'flex-start',
                              gap: 1
                            }}
                          >
                            {log.log_type === 'error' ? (
                              <Error color="error" fontSize="small" sx={{ mt: 0.3 }} />
                            ) : log.log_type === 'warning' ? (
                              <Error color="warning" fontSize="small" sx={{ mt: 0.3 }} />
                            ) : (
                              <CheckCircle color="success" fontSize="small" sx={{ mt: 0.3 }} />
                            )}
                            <Box sx={{ flex: 1 }}>
                              <Typography
                                variant="body2"
                                color={log.log_type === 'error' ? 'error' : 'text.primary'}
                                sx={{ fontFamily: 'monospace' }}
                              >
                                {log.message}
                              </Typography>
                              <Typography variant="caption" color="text.secondary">
                                {format(new Date(log.timestamp), 'HH:mm:ss')}
                              </Typography>
                            </Box>
                          </Box>
                        ))}
                      </Paper>
                    </Box>
                  ))}
              </Box>
            ) : (
              <Alert severity="info" sx={{ mt: 2 }}>
                No execution logs available yet. Logs will appear once the job starts processing on the imputation service.
              </Alert>
            )}

            {/* Show status updates in a collapsed section */}
            {statusUpdates.length > 0 && (
              <Box sx={{ mt: 4 }}>
                <Divider sx={{ mb: 2 }} />
                <Typography variant="h6" gutterBottom>
                  Status History
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  Internal job status transitions
                </Typography>
                <TableContainer>
                  <Table size="small">
                    <TableHead>
                      <TableRow>
                        <TableCell>Status</TableCell>
                        <TableCell>Progress</TableCell>
                        <TableCell>Message</TableCell>
                        <TableCell>Time</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {statusUpdates.map((update) => (
                        <TableRow key={update.id}>
                          <TableCell>
                            <Chip
                              label={update.status.toUpperCase()}
                              color={getStatusColor(update.status) as any}
                              size="small"
                            />
                          </TableCell>
                          <TableCell>{update.progress_percentage}%</TableCell>
                          <TableCell>{update.message || '-'}</TableCell>
                          <TableCell>
                            <Typography variant="caption">
                              {format(new Date(update.timestamp), 'MMM dd, HH:mm:ss')}
                            </Typography>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              </Box>
            )}

            {/* API Request & Response Accordion - Developer Details */}
            {job && ['queued', 'running', 'completed', 'failed'].includes(job.status) && (
              <Box sx={{ mt: 4 }}>
                <Accordion defaultExpanded={false} sx={{ border: '1px solid', borderColor: 'divider' }}>
                  <AccordionSummary
                    expandIcon={<ExpandMore />}
                    sx={{ bgcolor: 'grey.50' }}
                  >
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Code color="action" />
                      <Typography variant="h6" sx={{ fontWeight: 600 }}>
                        API Request & Response Details
                      </Typography>
                    </Box>
                  </AccordionSummary>
                  <AccordionDetails sx={{ p: 3 }}>
                    <Grid container spacing={3}>
                      {/* Raw API Request */}
                      <Grid item xs={12} md={6}>
                        <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 1.5, display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Info color="primary" fontSize="small" />
                          Raw API Request
                        </Typography>
                        <Paper
                          variant="outlined"
                          sx={{
                            bgcolor: '#1e1e1e',
                            color: '#d4d4d4',
                            p: 2,
                            borderRadius: 1,
                            maxHeight: '400px',
                            overflowY: 'auto'
                          }}
                        >
                          <pre style={{ margin: 0, fontFamily: 'monospace', fontSize: '0.875rem', whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
                            {JSON.stringify({
                              endpoint: `${services.find(s => s.id === job.service_id)?.base_url || 'https://impute.afrigen-d.org'}/api/v2/jobs`,
                              method: 'POST',
                              headers: {
                                'X-Auth-Token': '[REDACTED]',
                                'Content-Type': 'multipart/form-data'
                              },
                              body: {
                                refpanel: referencePanels.find(p => p.id === job.reference_panel_id)?.slug || job.reference_panel_id,
                                build: job.build,
                                phasing: job.phasing ? 'eagle' : 'no_phasing',
                                population: job.population || 'mixed',
                                mode: 'imputation',
                                files: job.input_file_name
                              }
                            }, null, 2)}
                          </pre>
                        </Paper>
                        {job.error_message && (
                          <Alert severity="error" sx={{ mt: 2 }}>
                            <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                              Submission Error
                            </Typography>
                            <Typography variant="body2">
                              {job.error_message}
                            </Typography>
                          </Alert>
                        )}
                      </Grid>

                      {/* Raw API Response */}
                      <Grid item xs={12} md={6}>
                        <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 1.5, display: 'flex', alignItems: 'center', gap: 1 }}>
                          <CheckCircle color="success" fontSize="small" />
                          Raw API Response
                        </Typography>
                        <Paper
                          variant="outlined"
                          sx={{
                            bgcolor: '#1e1e1e',
                            color: '#d4d4d4',
                            p: 2,
                            borderRadius: 1,
                            maxHeight: '400px',
                            overflowY: 'auto'
                          }}
                        >
                          <pre style={{ margin: 0, fontFamily: 'monospace', fontSize: '0.875rem', whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
                            {job.service_response && Object.keys(job.service_response).length > 0
                              ? JSON.stringify(job.service_response, null, 2)
                              : JSON.stringify({
                                  status: 'No response',
                                  message: 'Job failed before receiving API response',
                                  external_job_id: job.external_job_id || null
                                }, null, 2)
                            }
                          </pre>
                        </Paper>
                        {job.external_job_id && (
                          <Alert severity="success" sx={{ mt: 2 }}>
                            <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                              External Job ID
                            </Typography>
                            <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
                              {job.external_job_id}
                            </Typography>
                          </Alert>
                        )}
                      </Grid>
                    </Grid>
                  </AccordionDetails>
                </Accordion>
              </Box>
            )}
          </CardContent>
        </Card>
      </TabPanel>

      {/* Action Confirmation Dialog */}
      <Dialog
        open={actionDialog.open}
        onClose={() => setActionDialog({ open: false, action: null })}
      >
        <DialogTitle>
          Confirm {actionDialog.action === 'cancel' ? 'Cancellation' : 'Retry'}
        </DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to {actionDialog.action} the job "{job.name}"?
          </Typography>
          {actionDialog.action === 'cancel' && (
            <Alert severity="warning" sx={{ mt: 2 }}>
              This action cannot be undone. The job will be stopped and marked as cancelled.
            </Alert>
          )}
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => setActionDialog({ open: false, action: null })}
          >
            Cancel
          </Button>
          <Button
            onClick={() => actionDialog.action && handleAction(actionDialog.action)}
            variant="contained"
            color={actionDialog.action === 'cancel' ? 'error' : 'primary'}
            disabled={actionLoading}
          >
            {actionDialog.action === 'cancel' ? 'Cancel Job' : 'Retry Job'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default JobDetails; 