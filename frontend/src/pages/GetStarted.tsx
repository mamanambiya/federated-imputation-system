import React from 'react';
import {
  Box,
  Container,
  Typography,
  Grid,
  Card,
  CardContent,
  AppBar,
  Toolbar,
  Button,
  IconButton,
  Stepper,
  Step,
  StepLabel,
  StepContent,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import {
  Rocket,
  ArrowBack,
  AccountCircle,
  CloudUpload,
  PlayArrow,
  Download,
  CheckCircle,
  GetApp,
  Settings,
} from '@mui/icons-material';

const GetStarted: React.FC = () => {
  const navigate = useNavigate();

  const steps = [
    {
      label: 'Create Account & Login',
      icon: <AccountCircle />,
      description: 'Register for an account or login with existing credentials',
      details: [
        'Click "Access Platform" to reach the login page',
        'Use demo credentials: test_user / test123',
        'Or contact administrators for full account access'
      ]
    },
    {
      label: 'Prepare Your Data',
      icon: <Settings />,
      description: 'Format your genomic data according to service requirements',
      details: [
        'Supported formats: VCF, VCF.gz, PLINK',
        'Maximum file size varies by service (500MB - 1GB)',
        'Ensure data follows standard genomic file formats'
      ]
    },
    {
      label: 'Submit Imputation Job',
      icon: <CloudUpload />,
      description: 'Upload your data and configure imputation parameters',
      details: [
        'Select target imputation service',
        'Choose appropriate reference panel',
        'Upload your genomic data file',
        'Configure job parameters and authentication'
      ]
    },
    {
      label: 'Monitor Progress',
      icon: <PlayArrow />,
      description: 'Track your job status in real-time',
      details: [
        'View job progress on the dashboard',
        'Receive status updates as job progresses',
        'Monitor queue position and estimated completion'
      ]
    },
    {
      label: 'Download Results',
      icon: <Download />,
      description: 'Access and download your imputation results',
      details: [
        'Download imputed genotype data',
        'Access quality reports and statistics',
        'Export metadata and analysis summaries'
      ]
    }
  ];

  const quickStart = [
    'Login with demo credentials (test_user / test123)',
    'Navigate to "Submit New Job" from the dashboard',
    'Select a service (H3Africa or Michigan)',
    'Choose a reference panel appropriate for your population',
    'Upload your VCF file (demo files available)',
    'Start the imputation job and monitor progress'
  ];

  return (
    <Box sx={{ minHeight: '100vh' }}>
      {/* Navigation */}
      <AppBar 
        position="fixed" 
        sx={{ 
          background: 'rgba(255, 255, 255, 0.95)',
          backdropFilter: 'blur(10px)',
          color: 'text.primary',
          boxShadow: '0 2px 10px rgba(0,0,0,0.1)'
        }}
      >
        <Toolbar>
          <IconButton 
            edge="start" 
            color="inherit" 
            onClick={() => navigate('/')}
            sx={{ mr: 2 }}
          >
            <ArrowBack />
          </IconButton>
          
          <Box sx={{ display: 'flex', alignItems: 'center', flexGrow: 1 }}>
            <img 
              src="/afrigen-d-logo.png" 
              alt="AfriGen-D" 
              style={{ 
                height: 40, 
                marginRight: 12
              }} 
            />
            <Typography variant="h6" component="div" sx={{ fontWeight: 'bold', color: '#1e40af' }}>
              Federated Genomic Imputation Platform
            </Typography>
          </Box>
          
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
            <Button color="inherit" onClick={() => navigate('/')}>Home</Button>
            <Button color="inherit" onClick={() => navigate('/about')}>About</Button>
            <Button color="inherit" onClick={() => navigate('/services-info')}>Services</Button>
            <Button color="inherit" onClick={() => navigate('/documentation')}>Documentation</Button>
            <Button color="inherit" onClick={() => navigate('/contact')}>Contact</Button>
            <Button 
              variant="contained" 
              onClick={() => navigate('/login')}
              sx={{ 
                background: 'linear-gradient(135deg, #1e40af, #0f766e)',
                '&:hover': {
                  background: 'linear-gradient(135deg, #1e3a8a, #0d4f49)',
                }
              }}
            >
              <Rocket sx={{ mr: 1 }} />
              Access Platform
            </Button>
          </Box>
        </Toolbar>
      </AppBar>

      {/* Main Content */}
      <Container maxWidth="lg" sx={{ mt: 12, py: 8 }}>
        {/* Page Header */}
        <Box sx={{ textAlign: 'center', mb: 8 }}>
          <Typography 
            variant="h2" 
            component="h1" 
            gutterBottom 
            sx={{ 
              fontWeight: 'bold',
              fontSize: { xs: '2.5rem', md: '3.5rem' },
              background: 'linear-gradient(135deg, #1e40af, #059669)',
              backgroundClip: 'text',
              WebkitBackgroundClip: 'text',
              color: 'transparent',
            }}
          >
            Get Started
          </Typography>
          <Typography 
            variant="h5" 
            component="p" 
            sx={{ 
              color: 'text.secondary',
              maxWidth: '800px',
              margin: '0 auto',
              mb: 4
            }}
          >
            Your step-by-step guide to genomic imputation
          </Typography>
        </Box>

        {/* Quick Start Card */}
        <Card sx={{ mb: 8, background: 'linear-gradient(135deg, #f8fafc, #e2e8f0)' }}>
          <CardContent sx={{ p: 4 }}>
            <Typography variant="h4" component="h2" gutterBottom sx={{ color: '#1e40af', fontWeight: 'bold' }}>
              Quick Start Guide
            </Typography>
            <Typography variant="body1" sx={{ mb: 3, color: 'text.secondary' }}>
              Follow these steps to submit your first imputation job:
            </Typography>
            <List>
              {quickStart.map((step, index) => (
                <ListItem key={index}>
                  <ListItemIcon>
                    <CheckCircle sx={{ color: '#059669' }} />
                  </ListItemIcon>
                  <ListItemText primary={`${index + 1}. ${step}`} />
                </ListItem>
              ))}
            </List>
            <Box sx={{ mt: 3 }}>
              <Button 
                variant="contained" 
                size="large"
                onClick={() => navigate('/login')}
                sx={{ 
                  background: 'linear-gradient(135deg, #1e40af, #0f766e)',
                  '&:hover': {
                    background: 'linear-gradient(135deg, #1e3a8a, #0d4f49)',
                  }
                }}
              >
                <Rocket sx={{ mr: 1 }} />
                Start Now
              </Button>
            </Box>
          </CardContent>
        </Card>

        {/* Detailed Steps */}
        <Typography variant="h4" component="h2" gutterBottom sx={{ textAlign: 'center', mb: 6, color: '#1e40af' }}>
          Detailed Workflow
        </Typography>
        
        <Grid container spacing={4} sx={{ mb: 8 }}>
          {steps.map((step, index) => (
            <Grid item xs={12} key={index}>
              <Card 
                sx={{ 
                  transition: 'transform 0.3s ease, box-shadow 0.3s ease',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: '0 8px 24px rgba(0,0,0,0.12)'
                  }
                }}
              >
                <CardContent sx={{ p: 4 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                    <Box 
                      sx={{ 
                        mr: 3,
                        p: 2,
                        borderRadius: '50%',
                        background: 'linear-gradient(135deg, #1e40af, #3b82f6)',
                        color: 'white',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center'
                      }}
                    >
                      {step.icon}
                    </Box>
                    <Box sx={{ flexGrow: 1 }}>
                      <Typography variant="h5" component="h3" sx={{ fontWeight: 'bold', mb: 1 }}>
                        Step {index + 1}: {step.label}
                      </Typography>
                      <Typography variant="body1" color="text.secondary">
                        {step.description}
                      </Typography>
                    </Box>
                  </Box>
                  
                  <List>
                    {step.details.map((detail, detailIndex) => (
                      <ListItem key={detailIndex} sx={{ pl: 0 }}>
                        <ListItemIcon>
                          <CheckCircle sx={{ color: '#059669', fontSize: 20 }} />
                        </ListItemIcon>
                        <ListItemText primary={detail} />
                      </ListItem>
                    ))}
                  </List>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>

        {/* Support Information */}
        <Grid container spacing={4}>
          <Grid item xs={12} md={6}>
            <Card sx={{ height: '100%', p: 3 }}>
              <CardContent>
                <Typography variant="h5" component="h3" gutterBottom sx={{ color: '#1e40af', fontWeight: 'bold' }}>
                  Need Help?
                </Typography>
                <Typography variant="body1" sx={{ mb: 3, color: 'text.secondary' }}>
                  Our support team is here to assist you with any questions about the platform.
                </Typography>
                <Button 
                  variant="outlined"
                  onClick={() => navigate('/contact')}
                  fullWidth
                >
                  Contact Support
                </Button>
              </CardContent>
            </Card>
          </Grid>
          
          <Grid item xs={12} md={6}>
            <Card sx={{ height: '100%', p: 3 }}>
              <CardContent>
                <Typography variant="h5" component="h3" gutterBottom sx={{ color: '#1e40af', fontWeight: 'bold' }}>
                  Documentation
                </Typography>
                <Typography variant="body1" sx={{ mb: 3, color: 'text.secondary' }}>
                  Explore comprehensive guides, API documentation, and best practices.
                </Typography>
                <Button 
                  variant="outlined"
                  onClick={() => navigate('/documentation')}
                  fullWidth
                >
                  View Documentation
                </Button>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
};

export default GetStarted; 