import React, { useState, useEffect } from 'react';
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
  Chip,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import {
  Rocket,
  ArrowBack,
  CheckCircle,
  Storage,
  Public,
  Speed,
  Science,
} from '@mui/icons-material';
import { useApi } from '../contexts/ApiContext';

const ServicesInfo: React.FC = () => {
  const navigate = useNavigate();
  const { getServices } = useApi();
  const [services, setServices] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchServices = async () => {
      try {
        const servicesData = await getServices();
        setServices(servicesData);
      } catch (error) {
        console.log('Using demo services data');
        // Demo data for when API is not accessible
        setServices([
          {
            id: 1,
            name: 'H3Africa Imputation Service',
            api_type: 'ga4gh',
            description: 'African population-focused imputation service using GA4GH WES API',
            location: 'Cape Town, South Africa',
            is_active: true,
            supported_formats: ['vcf', 'vcf.gz', 'plink'],
            max_file_size_mb: 500,
            reference_panels_count: 3
          },
          {
            id: 2,
            name: 'Michigan Imputation Server',
            api_type: 'michigan',
            description: 'Global imputation service with extensive reference panels',
            location: 'Michigan, USA',
            is_active: true,
            supported_formats: ['vcf', 'vcf.gz'],
            max_file_size_mb: 1000,
            reference_panels_count: 5
          }
        ]);
      } finally {
        setLoading(false);
      }
    };

    fetchServices();
  }, [getServices]);

  const getApiTypeColor = (apiType: string) => {
    switch (apiType) {
      case 'ga4gh': return 'primary';
      case 'michigan': return 'secondary';
      case 'dnastack': return 'success';
      default: return 'default';
    }
  };

  const getApiTypeIcon = (apiType: string) => {
    switch (apiType) {
      case 'ga4gh': return <Science />;
      case 'michigan': return <Public />;
      case 'dnastack': return <Storage />;
      default: return <Speed />;
    }
  };

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
            <Button color="inherit" onClick={() => navigate('/get-started')}>Get Started</Button>
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
            Available Services
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
            Connect to multiple imputation services through our unified platform
          </Typography>
        </Box>

        {/* Services Grid */}
        <Grid container spacing={4} sx={{ mb: 8 }}>
          {services.map((service) => (
            <Grid item xs={12} md={6} key={service.id}>
              <Card 
                sx={{ 
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  transition: 'transform 0.3s ease, box-shadow 0.3s ease',
                  '&:hover': {
                    transform: 'translateY(-8px)',
                    boxShadow: '0 12px 24px rgba(0,0,0,0.15)'
                  }
                }}
              >
                <CardContent sx={{ flexGrow: 1, p: 3 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                    <Box sx={{ mr: 2 }}>
                      {getApiTypeIcon(service.api_type)}
                    </Box>
                    <Typography variant="h5" component="h3" sx={{ fontWeight: 'bold', flexGrow: 1 }}>
                      {service.name}
                    </Typography>
                    <Chip 
                      label={service.api_type?.toUpperCase()} 
                      color={getApiTypeColor(service.api_type)}
                      size="small"
                    />
                  </Box>
                  
                  <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
                    {service.description}
                  </Typography>

                  <Grid container spacing={2} sx={{ mb: 3 }}>
                    <Grid item xs={6}>
                      <Typography variant="body2" color="text.secondary">
                        <strong>Location:</strong>
                      </Typography>
                      <Typography variant="body2">
                        {service.location || 'Global'}
                      </Typography>
                    </Grid>
                    <Grid item xs={6}>
                      <Typography variant="body2" color="text.secondary">
                        <strong>Reference Panels:</strong>
                      </Typography>
                      <Typography variant="body2">
                        {service.reference_panels_count || 0} available
                      </Typography>
                    </Grid>
                    <Grid item xs={6}>
                      <Typography variant="body2" color="text.secondary">
                        <strong>Max File Size:</strong>
                      </Typography>
                      <Typography variant="body2">
                        {service.max_file_size_mb || 'N/A'} MB
                      </Typography>
                    </Grid>
                    <Grid item xs={6}>
                      <Typography variant="body2" color="text.secondary">
                        <strong>Status:</strong>
                      </Typography>
                      <Chip 
                        label={service.is_active ? 'Active' : 'Inactive'}
                        color={service.is_active ? 'success' : 'error'}
                        size="small"
                      />
                    </Grid>
                  </Grid>

                  {service.supported_formats && (
                    <Box sx={{ mb: 2 }}>
                      <Typography variant="body2" color="text.secondary" gutterBottom>
                        <strong>Supported Formats:</strong>
                      </Typography>
                      <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                        {service.supported_formats.map((format: string, index: number) => (
                          <Chip key={index} label={format} size="small" variant="outlined" />
                        ))}
                      </Box>
                    </Box>
                  )}

                  <Button
                    variant="outlined"
                    fullWidth
                    onClick={() => navigate(`/services/${service.id}`)}
                    sx={{ mt: 'auto' }}
                  >
                    View Details
                  </Button>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>

        {/* Service Features */}
        <Box sx={{ mb: 8 }}>
          <Typography variant="h4" component="h2" gutterBottom sx={{ textAlign: 'center', mb: 6, color: '#1e40af' }}>
            Service Features
          </Typography>
          <Grid container spacing={4}>
            <Grid item xs={12} md={4}>
              <Card sx={{ p: 3, textAlign: 'center', height: '100%' }}>
                <CardContent>
                  <Science sx={{ fontSize: 48, color: '#1e40af', mb: 2 }} />
                  <Typography variant="h6" gutterBottom>
                    Multiple API Support
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Support for GA4GH WES, Michigan Server, and DNASTACK APIs
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} md={4}>
              <Card sx={{ p: 3, textAlign: 'center', height: '100%' }}>
                <CardContent>
                  <Storage sx={{ fontSize: 48, color: '#059669', mb: 2 }} />
                  <Typography variant="h6" gutterBottom>
                    Comprehensive Panels
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Access to diverse reference panels optimized for different populations
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} md={4}>
              <Card sx={{ p: 3, textAlign: 'center', height: '100%' }}>
                <CardContent>
                  <Speed sx={{ fontSize: 48, color: '#dc2626', mb: 2 }} />
                  <Typography variant="h6" gutterBottom>
                    High Performance
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Optimized workflows for fast and accurate imputation results
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </Box>

        {/* Getting Started CTA */}
        <Box sx={{ textAlign: 'center' }}>
          <Card sx={{ p: 4, background: 'linear-gradient(135deg, #1e40af, #0f766e)' }}>
            <CardContent>
              <Typography variant="h4" component="h2" gutterBottom sx={{ color: 'white', fontWeight: 'bold' }}>
                Ready to Get Started?
              </Typography>
              <Typography variant="body1" sx={{ fontSize: '1.2rem', color: 'rgba(255,255,255,0.9)', mb: 3 }}>
                Access our platform to submit imputation jobs and connect to these services
              </Typography>
              <Button 
                variant="contained" 
                size="large"
                onClick={() => navigate('/login')}
                sx={{ 
                  background: 'rgba(255,255,255,0.2)',
                  color: 'white',
                  '&:hover': {
                    background: 'rgba(255,255,255,0.3)',
                  }
                }}
              >
                <Rocket sx={{ mr: 1 }} />
                Access Platform
              </Button>
            </CardContent>
          </Card>
        </Box>
      </Container>
    </Box>
  );
};

export default ServicesInfo; 