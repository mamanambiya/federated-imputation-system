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
} from '@mui/icons-material';
import { format } from 'date-fns';
import { useApi, ImputationJob, JobStatusUpdate, ResultFile } from '../contexts/ApiContext';

const JobDetails: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { getJob, getJobStatusUpdates, getJobFiles, cancelJob, retryJob, downloadFile } = useApi();
  
  const [job, setJob] = useState<ImputationJob | null>(null);
  const [statusUpdates, setStatusUpdates] = useState<JobStatusUpdate[]>([]);
  const [resultFiles, setResultFiles] = useState<ResultFile[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);

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
      const [jobData, statusData, filesData] = await Promise.all([
        getJob(id),
        getJobStatusUpdates(id),
        getJobFiles(id)
      ]);
      
      setJob(jobData);
      setStatusUpdates(statusData);
      setResultFiles(filesData);
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
      case 'imputed_data':
        return <Storage color="primary" />;
      case 'quality_report':
        return <Info color="info" />;
      case 'log_file':
        return <Error color="warning" />;
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

      <Grid container spacing={3}>
        {/* Job Overview */}
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Job Overview
              </Typography>
              
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <Box mb={2}>
                    <Typography variant="subtitle2" color="text.secondary">
                      Status
                    </Typography>
                    <Box display="flex" alignItems="center" mt={0.5}>
                      <Chip
                        label={job.status.toUpperCase()}
                        color={getStatusColor(job.status) as any}
                        size="small"
                        sx={{ mr: 1 }}
                      />
                      {['pending', 'queued', 'running'].includes(job.status) && (
                        <Box sx={{ width: 150 }}>
                          <LinearProgress
                            variant="determinate"
                            value={job.progress_percentage}
                            color={getStatusColor(job.status) as any}
                          />
                          <Typography variant="caption" color="text.secondary">
                            {job.progress_percentage}%
                          </Typography>
                        </Box>
                      )}
                    </Box>
                  </Box>
                </Grid>

                <Grid item xs={12} sm={6}>
                  <Box mb={2}>
                    <Typography variant="subtitle2" color="text.secondary">
                      Service & Panel
                    </Typography>
                    <Typography variant="body1">
                      {job.service.name}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {job.reference_panel.name}
                    </Typography>
                  </Box>
                </Grid>

                <Grid item xs={12} sm={6}>
                  <Box mb={2}>
                    <Typography variant="subtitle2" color="text.secondary">
                      Created
                    </Typography>
                    <Typography variant="body1">
                      {format(new Date(job.created_at), 'MMM dd, yyyy HH:mm')}
                    </Typography>
                  </Box>
                </Grid>

                <Grid item xs={12} sm={6}>
                  <Box mb={2}>
                    <Typography variant="subtitle2" color="text.secondary">
                      Duration
                    </Typography>
                    <Typography variant="body1">
                      {job.duration_display || 'N/A'}
                    </Typography>
                  </Box>
                </Grid>

                {job.description && (
                  <Grid item xs={12}>
                    <Box mb={2}>
                      <Typography variant="subtitle2" color="text.secondary">
                        Description
                      </Typography>
                      <Typography variant="body1">
                        {job.description}
                      </Typography>
                    </Box>
                  </Grid>
                )}
              </Grid>
            </CardContent>
          </Card>

          {/* Configuration Details */}
          <Card sx={{ mt: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Configuration
              </Typography>
              
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Input Format
                  </Typography>
                  <Typography variant="body1" mb={2}>
                    {job.input_format.toUpperCase()}
                  </Typography>
                </Grid>

                <Grid item xs={12} sm={6}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Genome Build
                  </Typography>
                  <Typography variant="body1" mb={2}>
                    {job.build}
                  </Typography>
                </Grid>

                <Grid item xs={12} sm={6}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Phasing
                  </Typography>
                  <Typography variant="body1" mb={2}>
                    {job.phasing ? 'Enabled' : 'Disabled'}
                  </Typography>
                </Grid>

                {job.population && (
                  <Grid item xs={12} sm={6}>
                    <Typography variant="subtitle2" color="text.secondary">
                      Population
                    </Typography>
                    <Typography variant="body1" mb={2}>
                      {job.population}
                    </Typography>
                  </Grid>
                )}

                {job.input_file_size_display && (
                  <Grid item xs={12} sm={6}>
                    <Typography variant="subtitle2" color="text.secondary">
                      Input File Size
                    </Typography>
                    <Typography variant="body1" mb={2}>
                      {job.input_file_size_display}
                    </Typography>
                  </Grid>
                )}
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Status Updates */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Status Updates
              </Typography>
              
              {statusUpdates.length > 0 ? (
                <List dense>
                  {statusUpdates.map((update, index) => (
                    <React.Fragment key={update.id}>
                      <ListItem>
                        <ListItemIcon>
                          {update.status === 'completed' ? (
                            <CheckCircle color="success" />
                          ) : update.status === 'failed' ? (
                            <Error color="error" />
                          ) : (
                            <Schedule color="primary" />
                          )}
                        </ListItemIcon>
                        <ListItemText
                          primary={update.status.toUpperCase()}
                          secondary={
                            <Box>
                              <Typography variant="caption" color="text.secondary">
                                {format(new Date(update.timestamp), 'MMM dd, HH:mm')}
                              </Typography>
                              {update.message && (
                                <Typography variant="body2" mt={0.5}>
                                  {update.message}
                                </Typography>
                              )}
                              {update.progress_percentage > 0 && (
                                <Typography variant="caption" color="text.secondary">
                                  Progress: {update.progress_percentage}%
                                </Typography>
                              )}
                            </Box>
                          }
                        />
                      </ListItem>
                      {index < statusUpdates.length - 1 && <Divider />}
                    </React.Fragment>
                  ))}
                </List>
              ) : (
                <Typography variant="body2" color="text.secondary">
                  No status updates available
                </Typography>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Result Files */}
        {resultFiles.length > 0 && (
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Result Files
                </Typography>
                
                <TableContainer component={Paper}>
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
                              {getFileTypeIcon(file.file_type)}
                              <Typography variant="body2" ml={1}>
                                {file.filename}
                              </Typography>
                            </Box>
                          </TableCell>
                          <TableCell>
                            <Chip
                              label={file.file_type.replace('_', ' ').toUpperCase()}
                              size="small"
                              variant="outlined"
                            />
                          </TableCell>
                          <TableCell>
                            <Typography variant="body2">
                              {file.file_size_display}
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
                                disabled={!file.is_available}
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
          </Grid>
        )}
      </Grid>

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