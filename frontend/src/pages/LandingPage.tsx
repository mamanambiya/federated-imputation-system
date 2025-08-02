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
              Federated Genomic Imputation Platform
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
                <MenuItem onClick={() => navigate('/about')}>About</MenuItem>
                <MenuItem onClick={() => navigate('/services-info')}>Services</MenuItem>
                <MenuItem onClick={() => navigate('/get-started')}>Get Started</MenuItem>
                <MenuItem onClick={() => navigate('/documentation')}>Documentation</MenuItem>
                <MenuItem onClick={() => navigate('/contact')}>Contact</MenuItem>
                <MenuItem onClick={() => navigate('/login')}>Access Platform</MenuItem>
              </Menu>
            </>
          ) : (
            <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
              <Button color="inherit" onClick={() => navigate('/about')}>About</Button>
              <Button color="inherit" onClick={() => navigate('/services-info')}>Services</Button>
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

      {/* Simple Footer */}
      <Box sx={{ py: 6, backgroundColor: '#f8fafc', textAlign: 'center' }}>
        <Container maxWidth="lg">
          <Grid container spacing={4} sx={{ mb: 4 }}>
            <Grid item xs={12} md={3}>
              <Card sx={{ p: 3, textAlign: 'center', height: '100%' }}>
                <CardContent>
                  <Button 
                    variant="text" 
                    color="primary" 
                    onClick={() => navigate('/about')}
                    sx={{ mb: 2 }}
                  >
                    <Info sx={{ mr: 1 }} />
                    Learn More
                  </Button>
                  <Typography variant="body2" color="text.secondary">
                    Discover our mission and platform features
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            
            <Grid item xs={12} md={3}>
              <Card sx={{ p: 3, textAlign: 'center', height: '100%' }}>
                <CardContent>
                  <Button 
                    variant="text" 
                    color="primary" 
                    onClick={() => navigate('/services-info')}
                    sx={{ mb: 2 }}
                  >
                    <Science sx={{ mr: 1 }} />
                    View Services
                  </Button>
                  <Typography variant="body2" color="text.secondary">
                    Explore available imputation services
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            
            <Grid item xs={12} md={3}>
              <Card sx={{ p: 3, textAlign: 'center', height: '100%' }}>
                <CardContent>
                  <Button 
                    variant="text" 
                    color="primary" 
                    onClick={() => navigate('/get-started')}
                    sx={{ mb: 2 }}
                  >
                    <Rocket sx={{ mr: 1 }} />
                    Quick Start
                  </Button>
                  <Typography variant="body2" color="text.secondary">
                    Step-by-step guide to get started
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            
            <Grid item xs={12} md={3}>
              <Card sx={{ p: 3, textAlign: 'center', height: '100%' }}>
                <CardContent>
                  <Button 
                    variant="text" 
                    color="primary" 
                    onClick={() => navigate('/documentation')}
                    sx={{ mb: 2 }}
                  >
                    <Book sx={{ mr: 1 }} />
                    Documentation
                  </Button>
                  <Typography variant="body2" color="text.secondary">
                    Technical guides and API docs
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
          
          <Typography 
            variant="body2" 
            sx={{ 
              color: 'text.secondary',
              mt: 4
            }}
          >
            © 2024 AfriGen-D Initiative. Advancing African genomics through federated technologies.
          </Typography>
        </Container>
      </Box>
    </Box>
  );
};

export default LandingPage; 