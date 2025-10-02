import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  Typography,
  Grid,
  FormControlLabel,
  Switch,
  Chip,
  IconButton,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
  Divider,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  OutlinedInput,
  InputAdornment,
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  Close,
  Save,
  CloudUpload,
} from '@mui/icons-material';
import { useApi, ImputationService } from '../contexts/ApiContext';

interface ServiceManagementProps {
  open: boolean;
  onClose: () => void;
  onServiceUpdated: () => void;
  editService?: ImputationService | null;
}

interface ServiceFormData {
  name: string;
  service_type: string;
  api_type: string;
  base_url: string;
  description: string;
  version: string;
  requires_auth: boolean;
  auth_type: string;
  max_file_size_mb: number;
  supported_formats: string[];
  supported_builds: string[];
  is_active: boolean;
}

const ServiceManagement: React.FC<ServiceManagementProps> = ({
  open,
  onClose,
  onServiceUpdated,
  editService,
}) => {
  const { createService, updateService, deleteService } = useApi();
  const [currentTab, setCurrentTab] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Form state
  const [formData, setFormData] = useState<ServiceFormData>({
    name: editService?.name || '',
    service_type: editService?.service_type || 'michigan',
    api_type: editService?.api_type || 'michigan',
    base_url: editService?.base_url || '',
    description: editService?.description || '',
    version: editService?.version || '1.0',
    requires_auth: editService?.requires_auth ?? false,
    auth_type: editService?.auth_type || 'token',
    max_file_size_mb: editService?.max_file_size_mb || 100,
    supported_formats: editService?.supported_formats || ['vcf', 'vcf.gz'],
    supported_builds: editService?.supported_builds || ['hg19', 'hg38'],
    is_active: editService?.is_active ?? true,
  });

  // Format tags input
  const [formatInput, setFormatInput] = useState('');
  const [buildInput, setBuildInput] = useState('');

  // Reset form when dialog opens/closes or edit service changes
  React.useEffect(() => {
    if (editService) {
      setFormData({
        name: editService.name,
        service_type: editService.service_type,
        api_type: editService.api_type || 'michigan',
        base_url: editService.base_url || editService.api_url || '',
        description: editService.description || '',
        version: editService.version || '1.0',
        requires_auth: editService.requires_auth ?? false,
        auth_type: editService.auth_type || 'token',
        max_file_size_mb: editService.max_file_size_mb || 100,
        supported_formats: editService.supported_formats || ['vcf', 'vcf.gz'],
        supported_builds: editService.supported_builds || ['hg19', 'hg38'],
        is_active: editService.is_active ?? true,
      });
    } else {
      setFormData({
        name: '',
        service_type: 'michigan',
        api_type: 'michigan',
        base_url: '',
        description: '',
        version: '1.0',
        requires_auth: false,
        auth_type: 'token',
        max_file_size_mb: 100,
        supported_formats: ['vcf', 'vcf.gz'],
        supported_builds: ['hg19', 'hg38'],
        is_active: true,
      });
    }
    setError(null);
    setSuccess(null);
  }, [editService, open]);

  const handleInputChange = (field: keyof ServiceFormData) => (
    event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const value = event.target.type === 'checkbox'
      ? (event.target as HTMLInputElement).checked
      : event.target.value;

    setFormData(prev => ({
      ...prev,
      [field]: field === 'max_file_size_mb' ? Number(value) : value,
    }));
  };

  const handleAddFormat = () => {
    if (formatInput.trim() && !formData.supported_formats.includes(formatInput.trim())) {
      setFormData(prev => ({
        ...prev,
        supported_formats: [...prev.supported_formats, formatInput.trim()],
      }));
      setFormatInput('');
    }
  };

  const handleRemoveFormat = (format: string) => {
    setFormData(prev => ({
      ...prev,
      supported_formats: prev.supported_formats.filter(f => f !== format),
    }));
  };

  const handleAddBuild = () => {
    if (buildInput.trim() && !formData.supported_builds.includes(buildInput.trim())) {
      setFormData(prev => ({
        ...prev,
        supported_builds: [...prev.supported_builds, buildInput.trim()],
      }));
      setBuildInput('');
    }
  };

  const handleRemoveBuild = (build: string) => {
    setFormData(prev => ({
      ...prev,
      supported_builds: prev.supported_builds.filter(b => b !== build),
    }));
  };

  const validateForm = (): boolean => {
    if (!formData.name.trim()) {
      setError('Service name is required');
      return false;
    }
    if (!formData.base_url.trim()) {
      setError('Base URL is required');
      return false;
    }
    try {
      new URL(formData.base_url);
    } catch {
      setError('Base URL must be a valid URL');
      return false;
    }
    if (formData.max_file_size_mb <= 0) {
      setError('Max file size must be greater than 0');
      return false;
    }
    if (formData.supported_formats.length === 0) {
      setError('At least one supported format is required');
      return false;
    }
    if (formData.supported_builds.length === 0) {
      setError('At least one supported build is required');
      return false;
    }
    return true;
  };

  const handleSubmit = async () => {
    setError(null);
    setSuccess(null);

    if (!validateForm()) {
      return;
    }

    try {
      setLoading(true);

      if (editService) {
        await updateService(editService.id, formData);
        setSuccess('Service updated successfully!');
      } else {
        await createService(formData);
        setSuccess('Service created successfully!');
      }

      setTimeout(() => {
        onServiceUpdated();
        onClose();
      }, 1500);
    } catch (err: any) {
      setError(err.message || 'Failed to save service');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!editService) return;

    if (!window.confirm(`Are you sure you want to delete "${editService.name}"? This action cannot be undone.`)) {
      return;
    }

    try {
      setLoading(true);
      await deleteService(editService.id);
      setSuccess('Service deleted successfully!');

      setTimeout(() => {
        onServiceUpdated();
        onClose();
      }, 1500);
    } catch (err: any) {
      setError(err.message || 'Failed to delete service');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <Box display="flex" justifyContent="space-between" alignItems="center">
          <Box display="flex" alignItems="center" gap={1}>
            <CloudUpload />
            <Typography variant="h6">
              {editService ? 'Edit Service' : 'Create New Service'}
            </Typography>
          </Box>
          <IconButton onClick={onClose} size="small">
            <Close />
          </IconButton>
        </Box>
      </DialogTitle>

      <DialogContent dividers>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
            {error}
          </Alert>
        )}

        {success && (
          <Alert severity="success" sx={{ mb: 2 }}>
            {success}
          </Alert>
        )}

        <Tabs value={currentTab} onChange={(_, newValue) => setCurrentTab(newValue)} sx={{ mb: 3 }}>
          <Tab label="Basic Info" />
          <Tab label="Configuration" />
          <Tab label="Capabilities" />
        </Tabs>

        {/* Tab 0: Basic Info */}
        {currentTab === 0 && (
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Service Name"
                value={formData.name}
                onChange={handleInputChange('name')}
                required
                placeholder="e.g., Michigan Imputation Server"
              />
            </Grid>

            <Grid item xs={12} md={6}>
              <FormControl fullWidth required>
                <InputLabel>Service Type</InputLabel>
                <Select
                  value={formData.service_type}
                  onChange={(e) => setFormData(prev => ({ ...prev, service_type: e.target.value }))}
                  label="Service Type"
                >
                  <MenuItem value="michigan">Michigan</MenuItem>
                  <MenuItem value="h3africa">H3Africa</MenuItem>
                  <MenuItem value="ga4gh">GA4GH</MenuItem>
                  <MenuItem value="dnastack">DNAstack</MenuItem>
                  <MenuItem value="custom">Custom</MenuItem>
                </Select>
              </FormControl>
            </Grid>

            <Grid item xs={12} md={6}>
              <FormControl fullWidth required>
                <InputLabel>API Type</InputLabel>
                <Select
                  value={formData.api_type}
                  onChange={(e) => setFormData(prev => ({ ...prev, api_type: e.target.value }))}
                  label="API Type"
                >
                  <MenuItem value="michigan">Michigan API</MenuItem>
                  <MenuItem value="ga4gh">GA4GH WES</MenuItem>
                  <MenuItem value="dnastack">DNAstack API</MenuItem>
                  <MenuItem value="custom">Custom API</MenuItem>
                </Select>
              </FormControl>
            </Grid>

            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Base URL"
                value={formData.base_url}
                onChange={handleInputChange('base_url')}
                required
                placeholder="https://imputationserver.sph.umich.edu"
                helperText="The base URL for the imputation service API"
              />
            </Grid>

            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                value={formData.description}
                onChange={handleInputChange('description')}
                multiline
                rows={3}
                placeholder="Describe this imputation service..."
              />
            </Grid>

            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Version"
                value={formData.version}
                onChange={handleInputChange('version')}
                placeholder="1.0"
              />
            </Grid>

            <Grid item xs={12} md={6}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.is_active}
                    onChange={handleInputChange('is_active')}
                  />
                }
                label="Service Active"
              />
            </Grid>
          </Grid>
        )}

        {/* Tab 1: Configuration */}
        {currentTab === 1 && (
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.requires_auth}
                    onChange={handleInputChange('requires_auth')}
                  />
                }
                label="Requires Authentication"
              />
            </Grid>

            {formData.requires_auth && (
              <Grid item xs={12}>
                <FormControl fullWidth>
                  <InputLabel>Authentication Type</InputLabel>
                  <Select
                    value={formData.auth_type}
                    onChange={(e) => setFormData(prev => ({ ...prev, auth_type: e.target.value }))}
                    label="Authentication Type"
                  >
                    <MenuItem value="token">API Token</MenuItem>
                    <MenuItem value="oauth2">OAuth 2.0</MenuItem>
                    <MenuItem value="api_key">API Key</MenuItem>
                    <MenuItem value="basic">Basic Auth</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
            )}

            <Grid item xs={12}>
              <TextField
                fullWidth
                type="number"
                label="Maximum File Size (MB)"
                value={formData.max_file_size_mb}
                onChange={handleInputChange('max_file_size_mb')}
                required
                InputProps={{
                  endAdornment: <InputAdornment position="end">MB</InputAdornment>,
                }}
                inputProps={{ min: 1 }}
              />
            </Grid>
          </Grid>
        )}

        {/* Tab 2: Capabilities */}
        {currentTab === 2 && (
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Typography variant="subtitle1" gutterBottom>
                Supported File Formats
              </Typography>
              <Box display="flex" gap={1} mb={2} flexWrap="wrap">
                {formData.supported_formats.map((format) => (
                  <Chip
                    key={format}
                    label={format}
                    onDelete={() => handleRemoveFormat(format)}
                    color="primary"
                  />
                ))}
              </Box>
              <Box display="flex" gap={1}>
                <TextField
                  size="small"
                  placeholder="Add format (e.g., vcf, vcf.gz, plink)"
                  value={formatInput}
                  onChange={(e) => setFormatInput(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleAddFormat()}
                  fullWidth
                />
                <Button variant="outlined" onClick={handleAddFormat}>
                  Add
                </Button>
              </Box>
            </Grid>

            <Grid item xs={12}>
              <Divider />
            </Grid>

            <Grid item xs={12}>
              <Typography variant="subtitle1" gutterBottom>
                Supported Genome Builds
              </Typography>
              <Box display="flex" gap={1} mb={2} flexWrap="wrap">
                {formData.supported_builds.map((build) => (
                  <Chip
                    key={build}
                    label={build}
                    onDelete={() => handleRemoveBuild(build)}
                    color="secondary"
                  />
                ))}
              </Box>
              <Box display="flex" gap={1}>
                <TextField
                  size="small"
                  placeholder="Add build (e.g., hg19, hg38, GRCh37)"
                  value={buildInput}
                  onChange={(e) => setBuildInput(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleAddBuild()}
                  fullWidth
                />
                <Button variant="outlined" onClick={handleAddBuild}>
                  Add
                </Button>
              </Box>
            </Grid>
          </Grid>
        )}
      </DialogContent>

      <DialogActions>
        {editService && (
          <Button
            onClick={handleDelete}
            color="error"
            startIcon={<Delete />}
            disabled={loading}
            sx={{ mr: 'auto' }}
          >
            Delete Service
          </Button>
        )}
        <Button onClick={onClose} disabled={loading}>
          Cancel
        </Button>
        <Button
          onClick={handleSubmit}
          variant="contained"
          startIcon={loading ? <CircularProgress size={16} /> : <Save />}
          disabled={loading}
        >
          {loading ? 'Saving...' : editService ? 'Update' : 'Create'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ServiceManagement;
