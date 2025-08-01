import React, { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Stepper,
  Step,
  StepLabel,
  Card,
  CardContent,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormControlLabel,
  Switch,
  Button,
  Alert,
  Grid,
  Chip,
  Paper,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  CircularProgress,
  Divider,
  Checkbox,
  FormGroup,
  FormLabel,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  IconButton,
  Link,
  InputAdornment,
} from '@mui/material';
import {
  CloudUpload,
  Description,
  Settings,
  Send,
  CheckCircle,
  Storage,
  Group,
  Speed,
  Add,
  Delete,
  Info,
  Key,
} from '@mui/icons-material';
import { useDropzone } from 'react-dropzone';
import { useApi, ImputationService, ReferencePanel } from '../contexts/ApiContext';

const steps = ['Upload File', 'Select Service & Panel', 'Configure Job', 'Review & Submit'];

const NewJob: React.FC = () => {
  const navigate = useNavigate();
  const { getServices, getServiceReferencePanels, createJob } = useApi();
  
  // State
  const [activeStep, setActiveStep] = useState(0);
  const [services, setServices] = useState<ImputationService[]>([]);
  const [referencePanelsByService, setReferencePanelsByService] = useState<{ [serviceId: string]: ReferencePanel[] }>({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Form data
  interface SelectedService {
    serviceId: string;
    serviceName: string;
    panelId: string;
    panelName: string;
    termsAccepted: boolean;
    userToken?: string;
  }

  interface JobFormData {
    name: string;
    description: string;
    selectedServices: SelectedService[];
    input_format: string;
    build: string;
    phasing: boolean;
    population: string;
  }

  const [file, setFile] = useState<File | null>(null);
  const [jobData, setJobData] = useState<JobFormData>({
    name: '',
    description: '',
    selectedServices: [],
    input_format: 'vcf',
    build: 'hg38',
    phasing: true,
    population: '',
  });

  // Modal state
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedModalService, setSelectedModalService] = useState<string>('');
  const [selectedModalPanel, setSelectedModalPanel] = useState<string>('');
  const [termsAccepted, setTermsAccepted] = useState(false);
  const [duplicateError, setDuplicateError] = useState<string>('');
  const [userToken, setUserToken] = useState<string>('');

  useEffect(() => {
    loadServices();
  }, []);

  useEffect(() => {
    // Load reference panels when modal service is selected
    if (selectedModalService) {
      console.log('Modal service selected:', selectedModalService);
      loadReferencePanels(parseInt(selectedModalService));
    }
  }, [selectedModalService]);

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

  const loadReferencePanels = async (serviceId: number) => {
    try {
      console.log('Loading reference panels for service:', serviceId);
      const panels = await getServiceReferencePanels(serviceId);
      console.log('Loaded panels:', panels);
      setReferencePanelsByService(prev => ({
        ...prev,
        [serviceId.toString()]: panels
      }));
    } catch (err) {
      console.error('Error loading reference panels:', err);
    }
  };

  const handleOpenModal = () => {
    setModalOpen(true);
    setSelectedModalService('');
    setSelectedModalPanel('');
    setTermsAccepted(false);
    setDuplicateError('');
  };

  const handleCloseModal = () => {
    setModalOpen(false);
    setSelectedModalService('');
    setSelectedModalPanel('');
    setTermsAccepted(false);
    setDuplicateError('');
    setUserToken('');
  };

  const handleAddService = () => {
    if (selectedModalService && selectedModalPanel && termsAccepted) {
      const service = services.find(s => s.id.toString() === selectedModalService);
      const panels = referencePanelsByService[selectedModalService] || [];
      const panel = panels.find(p => p.id.toString() === selectedModalPanel);
      
      if (service && panel) {
        // Check if this service-panel combination already exists
        const isDuplicate = jobData.selectedServices.some(
          s => s.serviceId === selectedModalService && s.panelId === selectedModalPanel
        );
        
        if (isDuplicate) {
          setDuplicateError('This service and reference panel combination has already been selected.');
          return;
        }
        
        const newService: SelectedService = {
          serviceId: selectedModalService,
          serviceName: service.name,
          panelId: selectedModalPanel,
          panelName: panel.name,
          termsAccepted: true,
          userToken: userToken || undefined,
        };
        
        setJobData(prev => ({
          ...prev,
          selectedServices: [...prev.selectedServices, newService]
        }));
        
        handleCloseModal();
      }
    }
  };

  const handleRemoveService = (index: number) => {
    setJobData(prev => ({
      ...prev,
      selectedServices: prev.selectedServices.filter((_, i) => i !== index)
    }));
  };

  // Check if a panel is already selected for a service
  const isPanelAlreadySelected = (serviceId: string, panelId: string) => {
    return jobData.selectedServices.some(
      s => s.serviceId === serviceId && s.panelId === panelId
    );
  };

  // File upload with dropzone
  const onDrop = useCallback((acceptedFiles: File[]) => {
    if (acceptedFiles.length > 0) {
      setFile(acceptedFiles[0]);
      if (!jobData.name) {
        const fileName = acceptedFiles[0].name.replace(/\.[^/.]+$/, "");
        setJobData(prev => ({ ...prev, name: fileName }));
      }
    }
  }, [jobData.name]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'text/plain': ['.vcf'],
      'application/gzip': ['.vcf.gz'],
      'application/octet-stream': ['.bed', '.bim', '.fam', '.bgen'],
    },
    maxFiles: 1,
    maxSize: 100 * 1024 * 1024, // 100MB
  });

  const handleNext = () => {
    setActiveStep((prevActiveStep) => prevActiveStep + 1);
  };

  const handleBack = () => {
    setActiveStep((prevActiveStep) => prevActiveStep - 1);
  };

  const handleSubmit = async () => {
    if (!file) {
      setError('Please select a file to upload');
      return;
    }

    try {
      setSubmitting(true);
      setError(null);

      const formData = new FormData();
      // Submit a job for each selected service
      const jobPromises = jobData.selectedServices.map(async (selectedService) => {
        const formData = new FormData();
        formData.append('input_file', file);
        formData.append('name', `${jobData.name} - ${selectedService.serviceName}`);
        formData.append('description', jobData.description);
        formData.append('service', selectedService.serviceId);
        formData.append('reference_panel', selectedService.panelId);
        formData.append('input_format', jobData.input_format);
        formData.append('build', jobData.build);
        formData.append('phasing', jobData.phasing.toString());
        formData.append('population', jobData.population);
        
        // Include user token if provided
        if (selectedService.userToken) {
          formData.append('user_token', selectedService.userToken);
        }
        
        return createJob(formData);
      });

      const results = await Promise.all(jobPromises);
      
      // Navigate to the first job's detail page
      if (results.length > 0) {
        navigate(`/jobs/${results[0].id}`);
      }
    } catch (err) {
      setError('Failed to submit job. Please try again.');
      console.error('Error submitting job:', err);
    } finally {
      setSubmitting(false);
    }
  };

  const canProceed = (step: number) => {
    switch (step) {
      case 0:
        return file !== null;
      case 1:
        // Check that at least one service is selected
        return jobData.selectedServices.length > 0;
      case 2:
        return jobData.name.trim() !== '';
      default:
        return true;
    }
  };



  const renderStepContent = (step: number) => {
    switch (step) {
      case 0:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Upload Input File
              </Typography>
              <Paper
                {...getRootProps()}
                sx={{
                  p: 3,
                  border: '2px dashed',
                  borderColor: isDragActive ? 'primary.main' : 'grey.300',
                  backgroundColor: isDragActive ? 'action.hover' : 'background.paper',
                  cursor: 'pointer',
                  textAlign: 'center',
                  '&:hover': {
                    backgroundColor: 'action.hover',
                  },
                }}
              >
                <input {...getInputProps()} />
                <CloudUpload sx={{ fontSize: 48, color: 'text.secondary', mb: 2 }} />
                <Typography variant="h6" gutterBottom>
                  {isDragActive ? 'Drop the file here' : 'Drag & drop a file here, or click to select'}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Supported formats: VCF, VCF.GZ, PLINK (BED/BIM/FAM), BGEN
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Maximum file size: 100MB
                </Typography>
              </Paper>

              {file && (
                <Box mt={2}>
                  <Alert severity="success">
                    <Typography variant="body2">
                      <strong>File selected:</strong> {file.name} ({(file.size / 1024 / 1024).toFixed(2)} MB)
                    </Typography>
                  </Alert>
                </Box>
              )}
            </CardContent>
          </Card>
        );

      case 1:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Select Imputation Services
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Add one or more imputation services to run your analysis
              </Typography>

              <Box sx={{ mt: 3 }}>
                {jobData.selectedServices.length === 0 ? (
                  <Alert severity="info">
                    No services selected yet. Click the button below to add a service.
                  </Alert>
                ) : (
                  <Box>
                    <Typography variant="subtitle2" gutterBottom>
                      Selected Services ({jobData.selectedServices.length})
                    </Typography>
                    <List>
                      {jobData.selectedServices.map((service, index) => (
                        <ListItem
                          key={index}
                          sx={{ 
                            border: 1, 
                            borderColor: 'divider', 
                            borderRadius: 1, 
                            mb: 1,
                            bgcolor: 'background.paper'
                          }}
                          secondaryAction={
                            <IconButton 
                              edge="end" 
                              aria-label="delete"
                              onClick={() => handleRemoveService(index)}
                            >
                              <Delete />
                            </IconButton>
                          }
                        >
                          <ListItemIcon>
                            {services.find(s => s.id.toString() === service.serviceId)?.service_type === 'h3africa' ? 
                              <Group color="primary" /> : 
                              <Speed color="secondary" />
                            }
                          </ListItemIcon>
                          <ListItemText
                            primary={service.serviceName}
                            secondary={
                              <Box>
                                <Typography variant="caption" display="block">
                                  Panel: {service.panelName}
                                </Typography>
                                <Typography variant="caption" display="block" color="success.main">
                                  ✓ Terms & Conditions accepted
                                </Typography>
                                {service.userToken && (
                                  <Typography variant="caption" display="block" color="info.main">
                                    ✓ Authentication token provided
                                  </Typography>
                                )}
                              </Box>
                            }
                          />
                        </ListItem>
                      ))}
                    </List>
                  </Box>
                )}

                <Button
                  variant="contained"
                  startIcon={<Add />}
                  onClick={handleOpenModal}
                  sx={{ mt: 2 }}
                  fullWidth
                >
                  Add Service
                </Button>
              </Box>
            </CardContent>
          </Card>
        );

      case 2:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Configure Job Parameters
              </Typography>

              <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    label="Job Name"
                    value={jobData.name}
                    onChange={(e) => setJobData(prev => ({ ...prev, name: e.target.value }))}
                    required
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <FormControl fullWidth>
                    <InputLabel>Input Format</InputLabel>
                    <Select
                      value={jobData.input_format}
                      label="Input Format"
                      onChange={(e) => setJobData(prev => ({ ...prev, input_format: e.target.value }))}
                    >
                      <MenuItem value="vcf">VCF</MenuItem>
                      <MenuItem value="plink">PLINK</MenuItem>
                      <MenuItem value="bgen">BGEN</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Description"
                    multiline
                    rows={3}
                    value={jobData.description}
                    onChange={(e) => setJobData(prev => ({ ...prev, description: e.target.value }))}
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <FormControl fullWidth>
                    <InputLabel>Genome Build</InputLabel>
                    <Select
                      value={jobData.build}
                      label="Genome Build"
                      onChange={(e) => setJobData(prev => ({ ...prev, build: e.target.value }))}
                    >
                      <MenuItem value="hg19">hg19/GRCh37</MenuItem>
                      <MenuItem value="hg38">hg38/GRCh38</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>
                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    label="Population (optional)"
                    value={jobData.population}
                    onChange={(e) => setJobData(prev => ({ ...prev, population: e.target.value }))}
                    placeholder="e.g., AFR, EUR, ASN"
                  />
                </Grid>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={jobData.phasing}
                        onChange={(e) => setJobData(prev => ({ ...prev, phasing: e.target.checked }))}
                      />
                    }
                    label="Enable phasing (recommended)"
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        );

      case 3:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Review & Submit
              </Typography>

              <List>
                <ListItem>
                  <ListItemIcon>
                    <Description />
                  </ListItemIcon>
                  <ListItemText
                    primary="Input File"
                    secondary={file ? `${file.name} (${(file.size / 1024 / 1024).toFixed(2)} MB)` : 'No file selected'}
                  />
                </ListItem>
                <Divider />
                
                <ListItem>
                  <ListItemIcon>
                    <Storage />
                  </ListItemIcon>
                  <ListItemText
                    primary="Selected Services & Panels"
                    secondary={
                      jobData.selectedServices.length > 0 ? (
                        <Box>
                          {jobData.selectedServices.map((service, index) => (
                            <Typography key={index} variant="body2">
                              • {service.serviceName} - {service.panelName}
                            </Typography>
                          ))}
                        </Box>
                      ) : 'No services selected'
                    }
                  />
                </ListItem>
                <Divider />

                <ListItem>
                  <ListItemIcon>
                    <Settings />
                  </ListItemIcon>
                  <ListItemText
                    primary="Job Configuration"
                    secondary={
                      <Box>
                        <Typography variant="body2">Name: {jobData.name || 'Unnamed'}</Typography>
                        <Typography variant="body2">Format: {jobData.input_format.toUpperCase()}</Typography>
                        <Typography variant="body2">Build: {jobData.build}</Typography>
                        <Typography variant="body2">Phasing: {jobData.phasing ? 'Enabled' : 'Disabled'}</Typography>
                        {jobData.population && (
                          <Typography variant="body2">Population: {jobData.population}</Typography>
                        )}
                      </Box>
                    }
                  />
                </ListItem>
              </List>

              {error && (
                <Alert severity="error" sx={{ mt: 2 }}>
                  {error}
                </Alert>
              )}
            </CardContent>
          </Card>
        );

      default:
        return null;
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        Submit New Imputation Job
      </Typography>

      <Stepper activeStep={activeStep} sx={{ mb: 4 }}>
        {steps.map((label) => (
          <Step key={label}>
            <StepLabel>{label}</StepLabel>
          </Step>
        ))}
      </Stepper>

      {renderStepContent(activeStep)}

      <Box display="flex" justifyContent="space-between" mt={3}>
        <Button
          disabled={activeStep === 0}
          onClick={handleBack}
        >
          Back
        </Button>

        <Box>
          {activeStep === steps.length - 1 ? (
            <Button
              variant="contained"
              onClick={handleSubmit}
              disabled={submitting || !canProceed(activeStep)}
              startIcon={submitting ? <CircularProgress size={20} /> : <Send />}
            >
              {submitting ? 'Submitting...' : 'Submit Job'}
            </Button>
          ) : (
            <Button
              variant="contained"
              onClick={handleNext}
              disabled={!canProceed(activeStep)}
            >
              Next
            </Button>
          )}
        </Box>
      </Box>

      {/* Add Service Modal */}
      <Dialog 
        open={modalOpen} 
        onClose={handleCloseModal}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Add Imputation Service</DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 2 }}>
            {/* Service Selection */}
            <Typography variant="h6" gutterBottom>
              Select Service
            </Typography>
            <Grid container spacing={2} sx={{ mb: 3 }}>
              {services.map((service) => (
                <Grid item xs={12} md={6} key={service.id}>
                  <Card 
                    sx={{ 
                      cursor: 'pointer',
                      border: selectedModalService === service.id.toString() ? 2 : 1,
                      borderColor: selectedModalService === service.id.toString() ? 'primary.main' : 'divider',
                      '&:hover': {
                        boxShadow: 3,
                        borderColor: 'primary.main',
                      }
                    }}
                    onClick={() => {
                      setSelectedModalService(service.id.toString());
                      setSelectedModalPanel(''); // Clear panel selection
                      setDuplicateError(''); // Clear any error
                    }}
                  >
                    <CardContent>
                      <Box display="flex" alignItems="center" mb={1}>
                        {service.service_type === 'h3africa' ? 
                          <Group color="primary" sx={{ mr: 1 }} /> : 
                          <Speed color="secondary" sx={{ mr: 1 }} />
                        }
                        <Typography variant="h6" component="span">
                          {service.name}
                        </Typography>
                      </Box>
                      <Typography variant="body2" color="text.secondary" paragraph>
                        {service.description}
                      </Typography>
                      <Box display="flex" gap={1}>
                        <Chip 
                          size="small" 
                          label={`${service.reference_panels_count} panels`}
                          icon={<Storage />}
                        />
                        <Chip 
                          size="small" 
                          label={`Max ${service.max_file_size_mb}MB`}
                        />
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>

            {/* Reference Panel Selection */}
            {selectedModalService && (
              <>
                <Typography variant="h6" gutterBottom>
                  Select Reference Panel
                </Typography>
                <FormControl fullWidth sx={{ mb: 3 }}>
                  <InputLabel>Reference Panel</InputLabel>
                  <Select
                    value={selectedModalPanel}
                    label="Reference Panel"
                    onChange={(e) => {
                      setSelectedModalPanel(e.target.value);
                      setDuplicateError(''); // Clear error when user selects a different panel
                    }}
                  >
                    {(referencePanelsByService[selectedModalService] || []).map((panel) => {
                      const isAlreadySelected = isPanelAlreadySelected(selectedModalService, panel.id.toString());
                      return (
                        <MenuItem 
                          key={panel.id} 
                          value={panel.id.toString()}
                          disabled={isAlreadySelected}
                        >
                          <Box>
                            <Typography variant="body1">
                              {panel.name}
                              {isAlreadySelected && (
                                <Chip 
                                  label="Already selected" 
                                  size="small" 
                                  color="warning" 
                                  sx={{ ml: 1 }}
                                />
                              )}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              Population: {panel.population || 'Mixed'} | 
                              Build: {panel.build || 'hg38'} | 
                              Samples: {panel.samples_count?.toLocaleString() || 'Unknown'}
                            </Typography>
                          </Box>
                        </MenuItem>
                      );
                    })}
                  </Select>
                </FormControl>

                {/* User Authentication Token */}
                <TextField
                  fullWidth
                  label="User Authentication Token"
                  value={userToken}
                  onChange={(e) => setUserToken(e.target.value)}
                  placeholder="Enter your personal access token for this service"
                  helperText="This token will be used to authenticate your job submissions. It may be different from the admin token."
                  sx={{ mb: 3 }}
                  type="password"
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <Key />
                      </InputAdornment>
                    ),
                  }}
                />

                {/* Terms & Conditions */}
                <Box sx={{ mb: 2 }}>
                  <Typography variant="h6" gutterBottom>
                    Terms & Conditions
                  </Typography>
                  <Paper sx={{ p: 2, bgcolor: 'grey.50', mb: 2 }}>
                    <Typography variant="body2" paragraph>
                      <strong>
                        {services.find(s => s.id.toString() === selectedModalService)?.name} Terms of Service
                      </strong>
                    </Typography>
                    <Typography variant="body2" paragraph>
                      By using this service, you agree to:
                    </Typography>
                    <Typography variant="body2" component="ul" sx={{ pl: 2 }}>
                      <li>Use the service only for research purposes</li>
                      <li>Not share or redistribute the reference panel data</li>
                      <li>Acknowledge the service in any publications</li>
                      <li>Comply with all applicable data protection regulations</li>
                      <li>Accept that results are provided "as is" without warranty</li>
                    </Typography>
                    <Typography variant="body2" sx={{ mt: 2 }}>
                      <Info fontSize="small" sx={{ verticalAlign: 'middle', mr: 0.5 }} />
                      For full terms, visit the service provider's website.
                    </Typography>
                  </Paper>
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={termsAccepted}
                        onChange={(e) => setTermsAccepted(e.target.checked)}
                      />
                    }
                    label="I accept the terms and conditions"
                  />
                </Box>
              </>
            )}
            
            {/* Error message */}
            {duplicateError && (
              <Alert severity="error" sx={{ mt: 2 }}>
                {duplicateError}
              </Alert>
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseModal}>Cancel</Button>
          <Button 
            onClick={handleAddService}
            variant="contained"
            disabled={!selectedModalService || !selectedModalPanel || !termsAccepted}
          >
            Add Service
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default NewJob; 