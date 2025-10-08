import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Alert,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Chip,
  Tooltip,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  InputAdornment,
  CircularProgress,
} from '@mui/material';
import {
  Add,
  Delete,
  Edit,
  Visibility,
  VisibilityOff,
  CheckCircle,
  Warning,
  VpnKey,
} from '@mui/icons-material';
import { useApi } from '../contexts/ApiContext';

interface ServiceCredential {
  id: number;
  service_id: number;
  credential_type: string;
  label?: string;
  is_active: boolean;
  is_verified: boolean;
  last_verified_at?: string;
  last_used_at?: string;
  created_at: string;
  updated_at: string;
  has_api_token: boolean;
  has_oauth_token: boolean;
  has_basic_auth: boolean;
}

interface Service {
  id: number;
  name: string;
  service_type: string;
  requires_auth: boolean;
}

const ServiceCredentials: React.FC = () => {
  const { api } = useApi();
  const [credentials, setCredentials] = useState<ServiceCredential[]>([]);
  const [services, setServices] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedCredential, setSelectedCredential] = useState<ServiceCredential | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Form state
  const [selectedService, setSelectedService] = useState<number | ''>('');
  const [apiToken, setApiToken] = useState('');
  const [showToken, setShowToken] = useState(false);
  const [label, setLabel] = useState('');

  useEffect(() => {
    loadCredentials();
    loadServices();
  }, []);

  const loadCredentials = async () => {
    try {
      const response = await api.get('/users/me/service-credentials');
      setCredentials(response.data);
    } catch (err: any) {
      console.error('Failed to load credentials:', err);
      setError('Failed to load service credentials');
    } finally {
      setLoading(false);
    }
  };

  const loadServices = async () => {
    try {
      const response = await api.get('/services');
      // Filter to show only services that require authentication
      setServices(response.data.filter((s: Service) => s.requires_auth));
    } catch (err: any) {
      console.error('Failed to load services:', err);
    }
  };

  const handleOpenDialog = (credential?: ServiceCredential) => {
    if (credential) {
      setSelectedCredential(credential);
      setSelectedService(credential.service_id);
      setLabel(credential.label || '');
      setApiToken(''); // Don't pre-fill for security
    } else {
      setSelectedCredential(null);
      setSelectedService('');
      setApiToken('');
      setLabel('');
    }
    setDialogOpen(true);
    setError(null);
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
    setSelectedCredential(null);
    setSelectedService('');
    setApiToken('');
    setLabel('');
    setShowToken(false);
  };

  const handleSave = async () => {
    if (!selectedService || !apiToken) {
      setError('Please select a service and enter an API token');
      return;
    }

    try {
      setLoading(true);
      setError(null);

      await api.post('/users/me/service-credentials', {
        service_id: selectedService,
        credential_type: 'api_token',
        api_token: apiToken,
        label: label || undefined,
      });

      setSuccess(selectedCredential ? 'Credential updated successfully' : 'Credential added successfully');
      setTimeout(() => setSuccess(null), 3000);

      handleCloseDialog();
      await loadCredentials();
    } catch (err: any) {
      console.error('Failed to save credential:', err);
      setError(err.response?.data?.detail || 'Failed to save credential');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (serviceId: number) => {
    try {
      setLoading(true);
      setError(null);

      await api.delete(`/users/me/service-credentials/${serviceId}`);

      setSuccess('Credential deleted successfully');
      setTimeout(() => setSuccess(null), 3000);

      setDeleteDialogOpen(false);
      setSelectedCredential(null);
      await loadCredentials();
    } catch (err: any) {
      console.error('Failed to delete credential:', err);
      setError(err.response?.data?.detail || 'Failed to delete credential');
    } finally {
      setLoading(false);
    }
  };

  const getServiceName = (serviceId: number): string => {
    const service = services.find(s => s.id === serviceId);
    return service?.name || `Service ${serviceId}`;
  };

  const getAvailableServices = () => {
    const credentialServiceIds = credentials.map(c => c.service_id);
    return services.filter(s => !credentialServiceIds.includes(s.id));
  };

  if (loading && credentials.length === 0) {
    return (
      <Box display="flex" justifyContent="center" p={3}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Paper sx={{ p: 3 }}>
      <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
        <Box display="flex" alignItems="center">
          <VpnKey sx={{ mr: 1 }} />
          <Typography variant="h6">Service Credentials</Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => handleOpenDialog()}
          disabled={getAvailableServices().length === 0}
        >
          Add Credential
        </Button>
      </Box>

      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
        Manage your personal API tokens for external imputation services. Each service requires its own authentication credentials.
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {success && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess(null)}>
          {success}
        </Alert>
      )}

      {credentials.length === 0 ? (
        <Alert severity="info">
          No service credentials configured. Add your API tokens to submit jobs to external imputation services.
        </Alert>
      ) : (
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Service</TableCell>
                <TableCell>Label</TableCell>
                <TableCell>Type</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Last Used</TableCell>
                <TableCell>Created</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {credentials.map((credential) => (
                <TableRow key={credential.id}>
                  <TableCell>
                    <Typography variant="body2" fontWeight={500}>
                      {getServiceName(credential.service_id)}
                    </Typography>
                  </TableCell>
                  <TableCell>{credential.label || '-'}</TableCell>
                  <TableCell>
                    {credential.has_api_token && 'API Token'}
                    {credential.has_oauth_token && 'OAuth'}
                    {credential.has_basic_auth && 'Basic Auth'}
                  </TableCell>
                  <TableCell>
                    {credential.is_verified ? (
                      <Chip
                        label="Verified"
                        color="success"
                        size="small"
                        icon={<CheckCircle />}
                      />
                    ) : (
                      <Chip
                        label="Not Verified"
                        color="warning"
                        size="small"
                        icon={<Warning />}
                      />
                    )}
                  </TableCell>
                  <TableCell>
                    {credential.last_used_at
                      ? new Date(credential.last_used_at).toLocaleDateString()
                      : 'Never'}
                  </TableCell>
                  <TableCell>
                    {new Date(credential.created_at).toLocaleDateString()}
                  </TableCell>
                  <TableCell align="right">
                    <Tooltip title="Update credential">
                      <IconButton
                        size="small"
                        onClick={() => handleOpenDialog(credential)}
                      >
                        <Edit />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Delete credential">
                      <IconButton
                        size="small"
                        color="error"
                        onClick={() => {
                          setSelectedCredential(credential);
                          setDeleteDialogOpen(true);
                        }}
                      >
                        <Delete />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Add/Edit Dialog */}
      <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>
          {selectedCredential ? 'Update Service Credential' : 'Add Service Credential'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 2 }}>
            <FormControl fullWidth sx={{ mb: 2 }}>
              <InputLabel>Service</InputLabel>
              <Select
                value={selectedService}
                onChange={(e) => setSelectedService(e.target.value as number)}
                label="Service"
                disabled={!!selectedCredential}
              >
                {selectedCredential ? (
                  <MenuItem value={selectedCredential.service_id}>
                    {getServiceName(selectedCredential.service_id)}
                  </MenuItem>
                ) : (
                  getAvailableServices().map((service) => (
                    <MenuItem key={service.id} value={service.id}>
                      {service.name}
                    </MenuItem>
                  ))
                )}
              </Select>
            </FormControl>

            <TextField
              fullWidth
              label="API Token"
              type={showToken ? 'text' : 'password'}
              value={apiToken}
              onChange={(e) => setApiToken(e.target.value)}
              placeholder="Enter your personal API token"
              sx={{ mb: 2 }}
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton
                      onClick={() => setShowToken(!showToken)}
                      edge="end"
                    >
                      {showToken ? <VisibilityOff /> : <Visibility />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />

            <TextField
              fullWidth
              label="Label (Optional)"
              value={label}
              onChange={(e) => setLabel(e.target.value)}
              placeholder="e.g., My H3Africa Token"
              helperText="A friendly name to help you identify this credential"
            />

            <Alert severity="info" sx={{ mt: 2 }}>
              <Typography variant="body2">
                <strong>How to get your API token:</strong>
                <br />
                1. Register/Login to the imputation service
                <br />
                2. Go to your account settings or API section
                <br />
                3. Generate or copy your personal API token
                <br />
                4. Paste it here
              </Typography>
            </Alert>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          <Button
            onClick={handleSave}
            variant="contained"
            disabled={!selectedService || !apiToken}
          >
            {selectedCredential ? 'Update' : 'Add'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Delete Service Credential?</DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete your credential for{' '}
            <strong>{selectedCredential && getServiceName(selectedCredential.service_id)}</strong>?
            <br />
            <br />
            You will need to re-enter it to submit jobs to this service.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={() => selectedCredential && handleDelete(selectedCredential.service_id)}
            color="error"
            variant="contained"
          >
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </Paper>
  );
};

export default ServiceCredentials;
