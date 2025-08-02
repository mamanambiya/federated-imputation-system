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
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Accordion,
  AccordionSummary,
  AccordionDetails,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import {
  Rocket,
  ArrowBack,
  Book,
  Code,
  Api,
  Description,
  School,
  ExpandMore,
  Launch,
  BugReport,
  IntegrationInstructions,
} from '@mui/icons-material';

const Documentation: React.FC = () => {
  const navigate = useNavigate();

  const documentationSections = [
    {
      title: 'Getting Started',
      icon: <School />,
      description: 'Learn the basics of using the platform',
      items: [
        'Platform Overview',
        'Account Setup',
        'First Job Submission',
        'Understanding Results'
      ]
    },
    {
      title: 'API Documentation',
      icon: <Api />,
      description: 'Technical API reference and integration guides',
      items: [
        'Authentication & Authorization',
        'Service Endpoints',
        'Job Management API',
        'File Upload/Download',
        'Webhook Integration'
      ]
    },
    {
      title: 'Service Integration',
      icon: <IntegrationInstructions />,
      description: 'Learn how different imputation services work',
      items: [
        'GA4GH WES API Integration',
        'Michigan Imputation Server',
        'DNASTACK Omics API',
        'Custom Service Setup'
      ]
    },
    {
      title: 'Best Practices',
      icon: <Description />,
      description: 'Guidelines for optimal platform usage',
      items: [
        'Data Preparation Guidelines',
        'Quality Control Procedures',
        'Performance Optimization',
        'Error Handling'
      ]
    }
  ];

  const quickLinks = [
    { name: 'Platform API Reference', url: '/api/docs/', icon: <Api /> },
    { name: 'GitHub Repository', url: 'https://github.com/mamanambiya/federated-imputation-system', icon: <Code /> },
    { name: 'Report Issues', url: 'https://github.com/mamanambiya/federated-imputation-system/issues', icon: <BugReport /> },
    { name: 'Contact Support', url: '/contact', icon: <Description /> },
  ];

  const faqs = [
    {
      question: 'What file formats are supported?',
      answer: 'The platform supports VCF (.vcf), compressed VCF (.vcf.gz), and PLINK format files. Each service may have specific requirements for file formatting.'
    },
    {
      question: 'How long does an imputation job take?',
      answer: 'Job duration varies based on file size, reference panel, and service load. Typical jobs range from 30 minutes to several hours.'
    },
    {
      question: 'Can I use my own reference panels?',
      answer: 'Currently, the platform uses pre-configured reference panels from each service. Custom panel support is planned for future releases.'
    },
    {
      question: 'Is my data secure?',
      answer: 'Yes, all data transmission uses HTTPS encryption, and data is processed according to each service\'s security protocols. Data is not stored permanently on our platform.'
    },
    {
      question: 'How do I get API access?',
      answer: 'API access is available to registered users. Contact administrators for API keys and documentation specific to your use case.'
    }
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
            <Button color="inherit" onClick={() => navigate('/get-started')}>Get Started</Button>
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
            Documentation
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
            Comprehensive guides, API references, and technical documentation
          </Typography>
        </Box>

        {/* Quick Links */}
        <Card sx={{ mb: 8, background: 'linear-gradient(135deg, #f8fafc, #e2e8f0)' }}>
          <CardContent sx={{ p: 4 }}>
            <Typography variant="h4" component="h2" gutterBottom sx={{ color: '#1e40af', fontWeight: 'bold' }}>
              Quick Links
            </Typography>
            <Grid container spacing={3}>
              {quickLinks.map((link, index) => (
                <Grid item xs={12} sm={6} md={3} key={index}>
                  <Button
                    variant="outlined"
                    fullWidth
                    startIcon={link.icon}
                    endIcon={link.url.startsWith('http') ? <Launch /> : null}
                    onClick={() => {
                      if (link.url.startsWith('http')) {
                        window.open(link.url, '_blank');
                      } else {
                        navigate(link.url);
                      }
                    }}
                    sx={{ 
                      justifyContent: 'flex-start',
                      p: 2,
                      textAlign: 'left'
                    }}
                  >
                    {link.name}
                  </Button>
                </Grid>
              ))}
            </Grid>
          </CardContent>
        </Card>

        {/* Documentation Sections */}
        <Typography variant="h4" component="h2" gutterBottom sx={{ textAlign: 'center', mb: 6, color: '#1e40af' }}>
          Documentation Sections
        </Typography>
        
        <Grid container spacing={4} sx={{ mb: 8 }}>
          {documentationSections.map((section, index) => (
            <Grid item xs={12} md={6} key={index}>
              <Card 
                sx={{ 
                  height: '100%',
                  transition: 'transform 0.3s ease, box-shadow 0.3s ease',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: '0 8px 24px rgba(0,0,0,0.12)'
                  }
                }}
              >
                <CardContent sx={{ p: 4 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                    <Box sx={{ mr: 2, color: '#1e40af' }}>
                      {section.icon}
                    </Box>
                    <Typography variant="h5" component="h3" sx={{ fontWeight: 'bold' }}>
                      {section.title}
                    </Typography>
                  </Box>
                  
                  <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
                    {section.description}
                  </Typography>
                  
                  <List sx={{ pl: 0 }}>
                    {section.items.map((item, itemIndex) => (
                      <ListItem key={itemIndex} sx={{ pl: 0, py: 0.5 }}>
                        <ListItemIcon sx={{ minWidth: 32 }}>
                          <Book sx={{ fontSize: 16, color: '#059669' }} />
                        </ListItemIcon>
                        <ListItemText 
                          primary={item}
                          primaryTypographyProps={{
                            variant: 'body2'
                          }}
                        />
                      </ListItem>
                    ))}
                  </List>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>

        {/* FAQ Section */}
        <Typography variant="h4" component="h2" gutterBottom sx={{ textAlign: 'center', mb: 6, color: '#1e40af' }}>
          Frequently Asked Questions
        </Typography>
        
        <Box sx={{ mb: 8 }}>
          {faqs.map((faq, index) => (
            <Accordion key={index} sx={{ mb: 1 }}>
              <AccordionSummary expandIcon={<ExpandMore />}>
                <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                  {faq.question}
                </Typography>
              </AccordionSummary>
              <AccordionDetails>
                <Typography variant="body1" color="text.secondary">
                  {faq.answer}
                </Typography>
              </AccordionDetails>
            </Accordion>
          ))}
        </Box>

        {/* Technical Specifications */}
        <Grid container spacing={4}>
          <Grid item xs={12} md={6}>
            <Card sx={{ height: '100%', p: 3 }}>
              <CardContent>
                <Typography variant="h5" component="h3" gutterBottom sx={{ color: '#1e40af', fontWeight: 'bold' }}>
                  Technical Specifications
                </Typography>
                <List>
                  <ListItem sx={{ pl: 0 }}>
                    <ListItemText 
                      primary="Supported File Formats"
                      secondary="VCF, VCF.gz, PLINK (BED/BIM/FAM)"
                    />
                  </ListItem>
                  <ListItem sx={{ pl: 0 }}>
                    <ListItemText 
                      primary="Maximum File Size"
                      secondary="Varies by service: 500MB - 1GB"
                    />
                  </ListItem>
                  <ListItem sx={{ pl: 0 }}>
                    <ListItemText 
                      primary="API Standards"
                      secondary="GA4GH WES, REST API, OpenAPI 3.0"
                    />
                  </ListItem>
                  <ListItem sx={{ pl: 0 }}>
                    <ListItemText 
                      primary="Authentication"
                      secondary="Session-based, API tokens available"
                    />
                  </ListItem>
                </List>
              </CardContent>
            </Card>
          </Grid>
          
          <Grid item xs={12} md={6}>
            <Card sx={{ height: '100%', p: 3 }}>
              <CardContent>
                <Typography variant="h5" component="h3" gutterBottom sx={{ color: '#1e40af', fontWeight: 'bold' }}>
                  Platform Architecture
                </Typography>
                <List>
                  <ListItem sx={{ pl: 0 }}>
                    <ListItemText 
                      primary="Frontend"
                      secondary="React with TypeScript, Material-UI"
                    />
                  </ListItem>
                  <ListItem sx={{ pl: 0 }}>
                    <ListItemText 
                      primary="Backend"
                      secondary="Django REST Framework, PostgreSQL"
                    />
                  </ListItem>
                  <ListItem sx={{ pl: 0 }}>
                    <ListItemText 
                      primary="Task Processing"
                      secondary="Celery with Redis message broker"
                    />
                  </ListItem>
                  <ListItem sx={{ pl: 0 }}>
                    <ListItemText 
                      primary="Deployment"
                      secondary="Docker containers, production-ready"
                    />
                  </ListItem>
                </List>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
};

export default Documentation; 