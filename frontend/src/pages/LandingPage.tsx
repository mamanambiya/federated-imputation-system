import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  Button,
  Grid,
  Card,
  CardContent,
  AppBar,
  Toolbar,
  IconButton,
  Menu,
  MenuItem,
  Chip,
  Paper,
  useTheme,
  useMediaQuery,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  CircularProgress,
  Alert,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Rocket,
  Info,
  Shield,
  Speed,
  Analytics,
  Storage,
  ExpandMore,
  GitHub,
  Twitter,
  LinkedIn,
  Email,
  People,
  Book,
  Code,
  Help,
  Public,
  PublicOutlined,
  Biotech,
  CheckCircle,
  OpenInNew,
  DeviceHub,
  Memory,
  Science,
  AccountTree,
  DataArray,
  Support,
  GetApp,
  Timeline,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { useApi } from '../contexts/ApiContext';

interface ServiceStats {
  total_services: number;
  total_panels: number;
  services_by_type: Record<string, number>;
}

const LandingPage: React.FC = () => {
  const navigate = useNavigate();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const [mobileMenuAnchor, setMobileMenuAnchor] = useState<null | HTMLElement>(null);
  const [stats, setStats] = useState<ServiceStats>({
    total_services: 5,
    total_panels: 14,
    services_by_type: { michigan: 2, ga4gh: 2, dnastack: 1 }
  });
  const { api } = useApi();

  useEffect(() => {
    // Fetch live statistics from API
    const fetchStats = async () => {
      try {
        const servicesResponse = await api.get('/services/');
        const panelsResponse = await api.get('/reference-panels/');
        
        const services = servicesResponse.data;
        const panels = panelsResponse.data;
        
        const servicesByType = services.reduce((acc: Record<string, number>, service: any) => {
          acc[service.api_type] = (acc[service.api_type] || 0) + 1;
          return acc;
        }, {});

        setStats({
          total_services: services.length,
          total_panels: panels.length,
          services_by_type: servicesByType
        });
      } catch (error) {
        console.log('Using default stats - API not accessible');
      }
    };

    fetchStats();
  }, [api]);

  const handleMobileMenuClick = (event: React.MouseEvent<HTMLElement>) => {
    setMobileMenuAnchor(event.currentTarget);
  };

  const handleMobileMenuClose = () => {
    setMobileMenuAnchor(null);
  };

  const scrollToSection = (sectionId: string) => {
    document.getElementById(sectionId)?.scrollIntoView({ behavior: 'smooth' });
    handleMobileMenuClose();
  };

  const getApiTypeColor = (apiType: string) => {
    const colors = {
      michigan: '#fbbf24',
      ga4gh: '#3b82f6',
      dnastack: '#10b981',
      h3africa: '#ec4899'
    };
    return colors[apiType as keyof typeof colors] || '#6b7280';
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
              Federated Imputation System
            </Typography>
          </Box>
          
          {isMobile ? (
            <>
              <IconButton color="inherit" onClick={handleMobileMenuClick}>
                <MenuIcon />
              </IconButton>
              <Menu
                anchorEl={mobileMenuAnchor}
                open={Boolean(mobileMenuAnchor)}
                onClose={handleMobileMenuClose}
              >
                <MenuItem onClick={() => scrollToSection('about')}>About</MenuItem>
                <MenuItem onClick={() => scrollToSection('services')}>Services</MenuItem>
                <MenuItem onClick={() => scrollToSection('getting-started')}>Get Started</MenuItem>
                <MenuItem onClick={() => scrollToSection('documentation')}>Documentation</MenuItem>
                <MenuItem onClick={() => scrollToSection('contact')}>Contact</MenuItem>
                <MenuItem onClick={() => navigate('/login')}>Access Platform</MenuItem>
              </Menu>
            </>
          ) : (
            <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
              <Button color="inherit" onClick={() => scrollToSection('about')}>About</Button>
              <Button color="inherit" onClick={() => scrollToSection('services')}>Services</Button>
              <Button color="inherit" onClick={() => scrollToSection('getting-started')}>Get Started</Button>
              <Button color="inherit" onClick={() => scrollToSection('documentation')}>Documentation</Button>
              <Button color="inherit" onClick={() => scrollToSection('contact')}>Contact</Button>
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
          )}
        </Toolbar>
      </AppBar>

      {/* Hero Section */}
      <Box
        sx={{
          background: 'linear-gradient(135deg, #1e40af 0%, #0f766e 100%)',
          color: 'white',
          py: { xs: 12, md: 16 },
          mt: 8,
          position: 'relative',
          overflow: 'hidden',
          '&::before': {
            content: '""',
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: `url("data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><defs><pattern id='grid' width='10' height='10' patternUnits='userSpaceOnUse'><path d='M 10 0 L 0 0 0 10' fill='none' stroke='rgba(255,255,255,0.1)' stroke-width='0.5'/></pattern></defs><rect width='100' height='100' fill='url(%23grid)'/></svg>") repeat`,
            opacity: 0.3,
          }
        }}
      >
        <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 1 }}>
          <Grid container spacing={4} alignItems="center">
            <Grid item xs={12} lg={8}>
              <Box sx={{ mb: 3, textAlign: { xs: 'center', lg: 'left' } }}>
                <img 
                  src="/afrigen-d-logo.png" 
                  alt="AfriGen-D" 
                  style={{ 
                    height: 80,
                    filter: 'brightness(0) invert(1)', // Make logo white
                  }} 
                />
              </Box>
              <Typography 
                variant="h2" 
                component="h1" 
                gutterBottom 
                sx={{ 
                  fontWeight: 'bold',
                  fontSize: { xs: '2.5rem', md: '3.5rem' }
                }}
              >
                Federated Genomic Imputation Platform
              </Typography>
              <Typography 
                variant="h6" 
                paragraph 
                sx={{ 
                  mb: 4,
                  fontSize: { xs: '1.1rem', md: '1.25rem' },
                  lineHeight: 1.6
                }}
              >
                Access multiple genomic imputation services through a unified platform. 
                Connect to leading imputation servers including H3Africa, Michigan Imputation Server, 
                GA4GH WES services, and DNASTACK platforms with a single interface.
              </Typography>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2 }}>
                <Button
                  variant="contained"
                  size="large"
                  onClick={() => navigate('/login')}
                  sx={{ 
                    bgcolor: 'white',
                    color: '#1e40af',
                    '&:hover': { bgcolor: '#f8fafc' }
                  }}
                >
                  <Rocket sx={{ mr: 1 }} />
                  Start Imputing
                </Button>
                <Button
                  variant="outlined"
                  size="large"
                  onClick={() => scrollToSection('about')}
                  sx={{ 
                    borderColor: 'white',
                    color: 'white',
                    '&:hover': { 
                      borderColor: 'white',
                      bgcolor: 'rgba(255,255,255,0.1)'
                    }
                  }}
                >
                  <Info sx={{ mr: 1 }} />
                  Learn More
                </Button>
              </Box>
            </Grid>
            <Grid item xs={12} lg={4}>
              <Box sx={{ textAlign: 'center', position: 'relative' }}>
                <Box 
                  sx={{ 
                    fontSize: '12rem',
                    opacity: 0.3,
                    lineHeight: 1
                  }}
                >
                  🧬
                </Box>
                <Box 
                  sx={{ 
                    position: 'absolute',
                    top: '50%',
                    left: '50%',
                    transform: 'translate(-50%, -50%)',
                    fontSize: '4rem'
                  }}
                >
                  ⚙️
                </Box>
              </Box>
            </Grid>
          </Grid>
        </Container>
      </Box>

      {/* Statistics Section */}
      <Box sx={{ py: 8, bgcolor: '#f8fafc' }}>
        <Container maxWidth="lg">
          <Grid container spacing={4}>
            <Grid item xs={6} md={3}>
              <Box sx={{ textAlign: 'center', p: 2 }}>
                <Typography 
                  variant="h2" 
                  sx={{ 
                    fontWeight: 700,
                    color: '#1e40af',
                    fontSize: { xs: '2rem', md: '3rem' }
                  }}
                >
                  {stats.total_services}
                </Typography>
                <Typography variant="h6" gutterBottom>
                  Connected Services
                </Typography>
                <Typography color="text.secondary">
                  Imputation services integrated
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={6} md={3}>
              <Box sx={{ textAlign: 'center', p: 2 }}>
                <Typography 
                  variant="h2" 
                  sx={{ 
                    fontWeight: 700,
                    color: '#1e40af',
                    fontSize: { xs: '2rem', md: '3rem' }
                  }}
                >
                  {stats.total_panels}
                </Typography>
                <Typography variant="h6" gutterBottom>
                  Reference Panels
                </Typography>
                <Typography color="text.secondary">
                  Available population panels
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={6} md={3}>
              <Box sx={{ textAlign: 'center', p: 2 }}>
                <Typography 
                  variant="h2" 
                  sx={{ 
                    fontWeight: 700,
                    color: '#1e40af',
                    fontSize: { xs: '2rem', md: '3rem' }
                  }}
                >
                  3
                </Typography>
                <Typography variant="h6" gutterBottom>
                  API Standards
                </Typography>
                <Typography color="text.secondary">
                  Michigan, GA4GH, DNASTACK
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={6} md={3}>
              <Box sx={{ textAlign: 'center', p: 2 }}>
                <Typography 
                  variant="h2" 
                  sx={{ 
                    fontWeight: 700,
                    color: '#1e40af',
                    fontSize: { xs: '2rem', md: '3rem' }
                  }}
                >
                  24/7
                </Typography>
                <Typography variant="h6" gutterBottom>
                  Availability
                </Typography>
                <Typography color="text.secondary">
                  Continuous service access
                </Typography>
              </Box>
            </Grid>
          </Grid>
        </Container>
      </Box>

      {/* About Section */}
      <Box id="about" sx={{ py: 8 }}>
        <Container maxWidth="lg">
          <Box sx={{ textAlign: 'center', mb: 6 }}>
            <Typography 
              variant="h3" 
              component="h2" 
              gutterBottom 
              sx={{ fontWeight: 700, color: '#1e293b' }}
            >
              About eLwazi Federated Imputation
            </Typography>
            <Typography 
              variant="h6" 
              color="text.secondary" 
              sx={{ maxWidth: 800, mx: 'auto' }}
            >
              A unified platform that connects researchers to multiple genomic imputation services, 
              enabling seamless access to diverse population reference panels and computational resources.
            </Typography>
          </Box>

          <Grid container spacing={4}>
            {[
              {
                icon: <Public />,
                title: 'Federated Access',
                description: 'Connect to multiple imputation services through a single interface. Access H3Africa, Michigan, GA4GH, and DNASTACK services without managing separate accounts.'
              },
              {
                icon: <Shield />,
                title: 'Secure & Compliant',
                description: 'Built with security and privacy in mind. Your genomic data is processed securely with industry-standard encryption and compliance with genomic data protection standards.'
              },
              {
                icon: <Speed />,
                title: 'High Performance',
                description: 'Leverage distributed computing resources across multiple platforms. Choose the best service for your specific population and computational requirements.'
              },
              {
                icon: <Analytics />,
                title: 'Advanced Analytics',
                description: 'Monitor job progress, view detailed quality metrics, and access comprehensive reports. Compare results across different services and reference panels.'
              }
            ].map((feature, index) => (
              <Grid item xs={12} md={6} key={index}>
                <Card 
                  sx={{ 
                    height: '100%',
                    p: 3,
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      transform: 'translateY(-5px)',
                      boxShadow: '0 12px 25px rgba(0,0,0,0.1)'
                    }
                  }}
                >
                  <CardContent>
                    <Box 
                      sx={{ 
                        width: 60,
                        height: 60,
                        borderRadius: '50%',
                        background: 'linear-gradient(135deg, #059669, #0f766e)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: 'white',
                        mb: 2
                      }}
                    >
                      {feature.icon}
                    </Box>
                    <Typography variant="h5" gutterBottom sx={{ fontWeight: 600 }}>
                      {feature.title}
                    </Typography>
                    <Typography color="text.secondary">
                      {feature.description}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Container>
      </Box>

      {/* Services Section */}
      <Box id="services" sx={{ py: 8, bgcolor: '#f8fafc' }}>
        <Container maxWidth="lg">
          <Box sx={{ textAlign: 'center', mb: 6 }}>
            <Typography 
              variant="h3" 
              component="h2" 
              gutterBottom 
              sx={{ fontWeight: 700, color: '#1e293b' }}
            >
              Connected Services
            </Typography>
            <Typography 
              variant="h6" 
              color="text.secondary" 
              sx={{ maxWidth: 800, mx: 'auto' }}
            >
              Access leading genomic imputation services through standardized APIs
            </Typography>
          </Box>

          <Grid container spacing={4}>
            {[
              {
                icon: <Storage />,
                title: 'Michigan Imputation Server',
                badge: 'Michigan API',
                badgeColor: '#fbbf24',
                description: 'Access the widely-used Michigan Imputation Server with comprehensive reference panels including HRC, 1000G, CAAPA, and more.'
              },
              {
                icon: <PublicOutlined />,
                title: 'H3Africa Imputation Service',
                badge: 'H3Africa',
                badgeColor: '#ec4899',
                description: 'Specialized African population reference panels optimized for African and African diaspora genomic research.'
              },
              {
                icon: <Storage />,
                title: 'GA4GH WES Services',
                badge: 'GA4GH Standard',
                badgeColor: '#3b82f6',
                description: 'Connect to GA4GH Workflow Execution Service (WES) compliant platforms for standardized workflow execution and monitoring.'
              },
              {
                icon: <Storage />,
                title: 'DNASTACK Platforms',
                badge: 'DNASTACK API',
                badgeColor: '#10b981',
                description: 'Access DNASTACK\'s omics platforms with advanced data discovery and analysis capabilities for population genomics.'
              }
            ].map((service, index) => (
              <Grid item xs={12} lg={6} key={index}>
                <Card 
                  sx={{ 
                    height: '100%',
                    p: 3,
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      transform: 'translateY(-5px)',
                      boxShadow: '0 12px 25px rgba(0,0,0,0.1)'
                    }
                  }}
                >
                  <CardContent>
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <Box 
                        sx={{ 
                          width: 50,
                          height: 50,
                          borderRadius: '50%',
                          background: 'linear-gradient(135deg, #059669, #0f766e)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          color: 'white',
                          mr: 2
                        }}
                      >
                        {service.icon}
                      </Box>
                      <Box>
                        <Typography variant="h6" gutterBottom sx={{ fontWeight: 600, mb: 0.5 }}>
                          {service.title}
                        </Typography>
                        <Chip 
                          label={service.badge}
                          size="small"
                          sx={{ bgcolor: service.badgeColor, color: 'white' }}
                        />
                      </Box>
                    </Box>
                    <Typography color="text.secondary">
                      {service.description}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Container>
      </Box>

      {/* Getting Started Section */}
      <Box id="getting-started" sx={{ py: 8 }}>
        <Container maxWidth="lg">
          <Box sx={{ textAlign: 'center', mb: 6 }}>
            <Typography 
              variant="h3" 
              component="h2" 
              gutterBottom 
              sx={{ fontWeight: 700, color: '#1e293b' }}
            >
              Getting Started
            </Typography>
            <Typography 
              variant="h6" 
              color="text.secondary" 
              sx={{ maxWidth: 800, mx: 'auto' }}
            >
              Start using the eLwazi platform in just a few simple steps
            </Typography>
          </Box>

          <Grid container spacing={4}>
            {[
              { step: '1', title: 'Create Account', description: 'Register for a free account to access the platform and manage your imputation jobs.' },
              { step: '2', title: 'Upload Data', description: 'Upload your genomic data files (VCF, PLINK, BGEN formats supported).' },
              { step: '3', title: 'Select Service', description: 'Choose your preferred imputation service and reference panel for optimal results.' }
            ].map((item, index) => (
              <Grid item xs={12} md={4} key={index}>
                <Box sx={{ textAlign: 'center' }}>
                  <Box 
                    sx={{ 
                      width: 60,
                      height: 60,
                      borderRadius: '50%',
                      background: 'linear-gradient(135deg, #059669, #0f766e)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: 'white',
                      mx: 'auto',
                      mb: 2,
                      fontSize: '1.5rem',
                      fontWeight: 'bold'
                    }}
                  >
                    {item.step}
                  </Box>
                  <Typography variant="h5" gutterBottom sx={{ fontWeight: 600 }}>
                    {item.title}
                  </Typography>
                  <Typography color="text.secondary">
                    {item.description}
                  </Typography>
                </Box>
              </Grid>
            ))}
          </Grid>

          <Box sx={{ textAlign: 'center', mt: 6 }}>
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
              Get Started Now
            </Button>
          </Box>
        </Container>
      </Box>

      {/* Documentation Section */}
      <Box id="documentation" sx={{ py: 8, bgcolor: '#f8fafc' }}>
        <Container maxWidth="lg">
          <Box sx={{ textAlign: 'center', mb: 6 }}>
            <Typography 
              variant="h3" 
              component="h2" 
              gutterBottom 
              sx={{ fontWeight: 700, color: '#1e293b' }}
            >
              Documentation & Support
            </Typography>
            <Typography 
              variant="h6" 
              color="text.secondary" 
              sx={{ maxWidth: 800, mx: 'auto' }}
            >
              Everything you need to know to use the platform effectively
            </Typography>
          </Box>

          <Grid container spacing={4}>
            {[
              {
                icon: <Book />,
                title: 'User Guide',
                description: 'Step-by-step instructions for using all platform features.',
                action: 'Read Guide'
              },
              {
                icon: <Code />,
                title: 'API Documentation',
                description: 'Complete API reference for developers and advanced users.',
                action: 'View API'
              },
              {
                icon: <Help />,
                title: 'Help & Support',
                description: 'Get help with technical issues and platform usage.',
                action: 'Get Help'
              }
            ].map((doc, index) => (
              <Grid item xs={12} md={4} key={index}>
                <Card 
                  sx={{ 
                    height: '100%',
                    p: 3,
                    textAlign: 'center',
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      transform: 'translateY(-5px)',
                      boxShadow: '0 12px 25px rgba(0,0,0,0.1)'
                    }
                  }}
                >
                  <CardContent>
                    <Box 
                      sx={{ 
                        width: 60,
                        height: 60,
                        borderRadius: '50%',
                        background: 'linear-gradient(135deg, #059669, #0f766e)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: 'white',
                        mx: 'auto',
                        mb: 2
                      }}
                    >
                      {doc.icon}
                    </Box>
                    <Typography variant="h5" gutterBottom sx={{ fontWeight: 600 }}>
                      {doc.title}
                    </Typography>
                    <Typography color="text.secondary" paragraph>
                      {doc.description}
                    </Typography>
                    <Button
                      variant="outlined"
                      onClick={() => scrollToSection('contact')}
                      sx={{ 
                        borderColor: '#1e40af',
                        color: '#1e40af',
                        '&:hover': {
                          borderColor: '#1e3a8a',
                          bgcolor: '#f8fafc'
                        }
                      }}
                    >
                      {doc.action}
                    </Button>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Container>
      </Box>

      {/* Contact Section */}
      <Box id="contact" sx={{ py: 8 }}>
        <Container maxWidth="lg">
          <Box sx={{ textAlign: 'center', mb: 6 }}>
            <Typography 
              variant="h3" 
              component="h2" 
              gutterBottom 
              sx={{ fontWeight: 700, color: '#1e293b' }}
            >
              Contact & Support
            </Typography>
            <Typography 
              variant="h6" 
              color="text.secondary" 
              sx={{ maxWidth: 800, mx: 'auto' }}
            >
              Get in touch with our team for support, collaboration, or technical questions
            </Typography>
          </Box>

          <Grid container spacing={4}>
            <Grid item xs={12} md={6}>
              <Card 
                sx={{ 
                  height: '100%',
                  p: 3,
                  textAlign: 'center',
                  transition: 'all 0.3s ease',
                  '&:hover': {
                    transform: 'translateY(-5px)',
                    boxShadow: '0 12px 25px rgba(0,0,0,0.1)'
                  }
                }}
              >
                <CardContent>
                  <Box 
                    sx={{ 
                      width: 60,
                      height: 60,
                      borderRadius: '50%',
                      background: 'linear-gradient(135deg, #059669, #0f766e)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: 'white',
                      mx: 'auto',
                      mb: 2
                    }}
                  >
                    <Email />
                  </Box>
                  <Typography variant="h5" gutterBottom sx={{ fontWeight: 600 }}>
                    Technical Support
                  </Typography>
                  <Typography color="text.secondary" paragraph>
                    Get help with platform usage, data formats, and technical issues.
                  </Typography>
                  <Button
                    variant="outlined"
                    href="mailto:support@elwazi.org"
                    sx={{ 
                      borderColor: '#1e40af',
                      color: '#1e40af',
                      '&:hover': {
                        borderColor: '#1e3a8a',
                        bgcolor: '#f8fafc'
                      }
                    }}
                  >
                    Email Support
                  </Button>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} md={6}>
              <Card 
                sx={{ 
                  height: '100%',
                  p: 3,
                  textAlign: 'center',
                  transition: 'all 0.3s ease',
                  '&:hover': {
                    transform: 'translateY(-5px)',
                    boxShadow: '0 12px 25px rgba(0,0,0,0.1)'
                  }
                }}
              >
                <CardContent>
                  <Box 
                    sx={{ 
                      width: 60,
                      height: 60,
                      borderRadius: '50%',
                      background: 'linear-gradient(135deg, #059669, #0f766e)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: 'white',
                      mx: 'auto',
                      mb: 2
                    }}
                  >
                    <People />
                  </Box>
                  <Typography variant="h5" gutterBottom sx={{ fontWeight: 600 }}>
                    Collaboration
                  </Typography>
                  <Typography color="text.secondary" paragraph>
                    Interested in adding your service or collaborating with the platform?
                  </Typography>
                  <Button
                    variant="outlined"
                    href="mailto:partnerships@elwazi.org"
                    sx={{ 
                      borderColor: '#1e40af',
                      color: '#1e40af',
                      '&:hover': {
                        borderColor: '#1e3a8a',
                        bgcolor: '#f8fafc'
                      }
                    }}
                  >
                    Contact Us
                  </Button>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </Container>
      </Box>

      {/* Footer */}
      <Box sx={{ bgcolor: '#1e293b', color: 'white', py: 6 }}>
        <Container maxWidth="lg">
          <Grid container spacing={4}>
            <Grid item xs={12} md={4}>
              <Typography variant="h6" gutterBottom sx={{ fontWeight: 'bold' }}>
                eLwazi Platform
              </Typography>
              <Typography paragraph>
                Federated genomic imputation platform connecting researchers 
                to leading imputation services worldwide.
              </Typography>
              <Box sx={{ display: 'flex', gap: 1 }}>
                <IconButton sx={{ color: 'white' }}>
                  <GitHub />
                </IconButton>
                <IconButton sx={{ color: 'white' }}>
                  <Twitter />
                </IconButton>
                <IconButton sx={{ color: 'white' }}>
                  <LinkedIn />
                </IconButton>
              </Box>
            </Grid>
            <Grid item xs={6} md={2}>
              <Typography variant="h6" gutterBottom sx={{ fontWeight: 'bold' }}>
                Platform
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <Typography 
                  variant="body2" 
                  sx={{ color: '#94a3b8', cursor: 'pointer' }}
                  onClick={() => navigate('/login')}
                >
                  Access Platform
                </Typography>
                <Typography 
                  variant="body2" 
                  sx={{ color: '#94a3b8', cursor: 'pointer' }}
                  onClick={() => scrollToSection('services')}
                >
                  Services
                </Typography>
                <Typography 
                  variant="body2" 
                  sx={{ color: '#94a3b8', cursor: 'pointer' }}
                  onClick={() => scrollToSection('getting-started')}
                >
                  Get Started
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={6} md={2}>
              <Typography variant="h6" gutterBottom sx={{ fontWeight: 'bold' }}>
                Resources
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <Typography variant="body2" sx={{ color: '#94a3b8' }}>
                  Documentation
                </Typography>
                <Typography variant="body2" sx={{ color: '#94a3b8' }}>
                  API Reference
                </Typography>
                <Typography variant="body2" sx={{ color: '#94a3b8' }}>
                  Tutorials
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={6} md={2}>
              <Typography variant="h6" gutterBottom sx={{ fontWeight: 'bold' }}>
                Support
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <Typography 
                  variant="body2" 
                  sx={{ color: '#94a3b8', cursor: 'pointer' }}
                  onClick={() => scrollToSection('contact')}
                >
                  Contact
                </Typography>
                <Typography variant="body2" sx={{ color: '#94a3b8' }}>
                  Help Center
                </Typography>
                <Typography variant="body2" sx={{ color: '#94a3b8' }}>
                  Status
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={6} md={2}>
              <Typography variant="h6" gutterBottom sx={{ fontWeight: 'bold' }}>
                Legal
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <Typography variant="body2" sx={{ color: '#94a3b8' }}>
                  Privacy Policy
                </Typography>
                <Typography variant="body2" sx={{ color: '#94a3b8' }}>
                  Terms of Use
                </Typography>
                <Typography variant="body2" sx={{ color: '#94a3b8' }}>
                  Data Policy
                </Typography>
              </Box>
            </Grid>
          </Grid>
          
          <Box 
            sx={{ 
              borderTop: '1px solid #475569',
              mt: 4,
              pt: 4,
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              flexDirection: { xs: 'column', md: 'row' },
              gap: 2
            }}
          >
            <Typography variant="body2" sx={{ color: '#94a3b8' }}>
              © 2025 eLwazi Genomics Platform. All rights reserved.
            </Typography>
            <Typography variant="body2" sx={{ color: '#94a3b8' }}>
              Powered by <Box component="span" sx={{ color: 'white' }}>React</Box> & <Box component="span" sx={{ color: 'white' }}>Django</Box>
            </Typography>
          </Box>
        </Container>
      </Box>
    </Box>
  );
};

export default LandingPage; 