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
  useMediaQuery,
  useTheme,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import {
  Science,
  AccountTree,
  DataArray,
  Rocket,
  ArrowBack,
} from '@mui/icons-material';
import Footer from '../components/Layout/Footer';

const About: React.FC = () => {
  const navigate = useNavigate();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));

  const features = [
    {
      icon: <Science sx={{ fontSize: 40, color: '#1e40af' }} />,
      title: 'Multiple Service Integration',
      description: 'Connect to H3Africa, Michigan Imputation Server, GA4GH WES, and DNASTACK services through a unified interface.',
    },
    {
      icon: <AccountTree sx={{ fontSize: 40, color: '#059669' }} />,
      title: 'Federated Architecture',
      description: 'Distributed system that connects multiple imputation services while maintaining data sovereignty.',
    },
    {
      icon: <DataArray sx={{ fontSize: 40, color: '#dc2626' }} />,
      title: 'Comprehensive Analytics',
      description: 'Advanced analytics and reporting tools to monitor job progress and analyze imputation results.',
    },
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
            About Our Platform
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
            Empowering genomic research through federated imputation services across Africa and beyond
          </Typography>
        </Box>

        {/* Mission Statement */}
        <Box sx={{ mb: 8 }}>
          <Card sx={{ p: 4, background: 'linear-gradient(135deg, #f8fafc, #e2e8f0)' }}>
            <CardContent>
              <Typography variant="h4" component="h2" gutterBottom sx={{ color: '#1e40af', fontWeight: 'bold' }}>
                Our Mission
              </Typography>
              <Typography variant="body1" sx={{ fontSize: '1.2rem', lineHeight: 1.6, color: 'text.secondary' }}>
                To democratize access to genomic imputation services by providing a unified platform that connects 
                researchers to multiple imputation services worldwide. We bridge the gap between cutting-edge genomic 
                technologies and the African research community, enabling breakthrough discoveries in genomic medicine 
                and population genetics.
              </Typography>
            </CardContent>
          </Card>
        </Box>

        {/* Key Features */}
        <Box sx={{ mb: 8 }}>
          <Typography variant="h4" component="h2" gutterBottom sx={{ textAlign: 'center', mb: 6, color: '#1e40af' }}>
            Platform Features
          </Typography>
          <Grid container spacing={4}>
            {features.map((feature, index) => (
              <Grid item xs={12} md={4} key={index}>
                <Card 
                  sx={{ 
                    height: '100%',
                    textAlign: 'center',
                    p: 3,
                    transition: 'transform 0.3s ease, box-shadow 0.3s ease',
                    '&:hover': {
                      transform: 'translateY(-8px)',
                      boxShadow: '0 12px 24px rgba(0,0,0,0.15)'
                    }
                  }}
                >
                  <CardContent>
                    <Box sx={{ mb: 2 }}>
                      {feature.icon}
                    </Box>
                    <Typography variant="h6" component="h3" gutterBottom sx={{ fontWeight: 'bold' }}>
                      {feature.title}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {feature.description}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>

        {/* Platform Statistics */}
        <Box sx={{ mb: 8 }}>
          <Typography variant="h4" component="h2" gutterBottom sx={{ textAlign: 'center', mb: 6, color: '#1e40af' }}>
            Platform Impact
          </Typography>
          <Grid container spacing={4} sx={{ textAlign: 'center' }}>
            <Grid item xs={12} sm={6} md={3}>
              <Card sx={{ p: 3, background: 'linear-gradient(135deg, #1e40af, #3b82f6)' }}>
                <CardContent sx={{ color: 'white' }}>
                  <Typography variant="h3" component="div" sx={{ fontWeight: 'bold', mb: 1 }}>
                    5+
                  </Typography>
                  <Typography variant="body1">
                    Connected Services
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Card sx={{ p: 3, background: 'linear-gradient(135deg, #059669, #10b981)' }}>
                <CardContent sx={{ color: 'white' }}>
                  <Typography variant="h3" component="div" sx={{ fontWeight: 'bold', mb: 1 }}>
                    20M+
                  </Typography>
                  <Typography variant="body1">
                    Variants Available
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Card sx={{ p: 3, background: 'linear-gradient(135deg, #dc2626, #ef4444)' }}>
                <CardContent sx={{ color: 'white' }}>
                  <Typography variant="h3" component="div" sx={{ fontWeight: 'bold', mb: 1 }}>
                    15+
                  </Typography>
                  <Typography variant="body1">
                    Reference Panels
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Card sx={{ p: 3, background: 'linear-gradient(135deg, #7c3aed, #8b5cf6)' }}>
                <CardContent sx={{ color: 'white' }}>
                  <Typography variant="h3" component="div" sx={{ fontWeight: 'bold', mb: 1 }}>
                    3
                  </Typography>
                  <Typography variant="body1">
                    API Types Supported
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </Box>

        {/* Vision Statement */}
        <Box sx={{ textAlign: 'center' }}>
          <Card sx={{ p: 4, background: 'linear-gradient(135deg, #0f766e, #059669)' }}>
            <CardContent>
              <Typography variant="h4" component="h2" gutterBottom sx={{ color: 'white', fontWeight: 'bold' }}>
                Our Vision
              </Typography>
              <Typography variant="body1" sx={{ fontSize: '1.2rem', lineHeight: 1.6, color: 'rgba(255,255,255,0.9)' }}>
                To become the leading platform for federated genomic imputation in Africa, fostering collaborative 
                research that leads to better understanding of African genomic diversity and improved healthcare 
                outcomes across the continent.
              </Typography>
            </CardContent>
          </Card>
        </Box>
      </Container>
      
      {/* Footer */}
      <Footer />
    </Box>
  );
};

export default About; 