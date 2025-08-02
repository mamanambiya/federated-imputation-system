import React, { useState } from 'react';
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
  TextField,
  Alert,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import {
  Rocket,
  ArrowBack,
  Email,
  Phone,
  LocationOn,
  GitHub,
  LinkedIn,
  Twitter,
  Send,
  Support,
  Business,
} from '@mui/icons-material';

const Contact: React.FC = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    subject: '',
    message: ''
  });
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Simulate form submission
    setSubmitted(true);
    setTimeout(() => setSubmitted(false), 5000);
    setFormData({ name: '', email: '', subject: '', message: '' });
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData(prev => ({
      ...prev,
      [e.target.name]: e.target.value
    }));
  };

  const contactInfo = [
    {
      icon: <Email sx={{ fontSize: 40, color: '#1e40af' }} />,
      title: 'Email Support',
      details: ['support@afrigen-d.org', 'admin@federated-imputation.org'],
      description: 'For technical support and general inquiries'
    },
    {
      icon: <Business sx={{ fontSize: 40, color: '#059669' }} />,
      title: 'Organization',
      details: ['AfriGen-D Initiative', 'Genomics Research Consortium'],
      description: 'Leading genomic research across Africa'
    },
    {
      icon: <LocationOn sx={{ fontSize: 40, color: '#dc2626' }} />,
      title: 'Location',
      details: ['Cape Town, South Africa', 'Pan-African Network'],
      description: 'Federated platform serving the continent'
    }
  ];

  const socialLinks = [
    { name: 'GitHub', icon: <GitHub />, url: 'https://github.com/mamanambiya/federated-imputation-system' },
    { name: 'LinkedIn', icon: <LinkedIn />, url: 'https://linkedin.com/company/afrigen-d' },
    { name: 'Twitter', icon: <Twitter />, url: 'https://twitter.com/afrigenomics' },
  ];

  const supportOptions = [
    {
      title: 'Technical Support',
      description: 'Get help with platform issues, job submissions, and technical problems',
      action: 'Create Support Ticket',
      color: '#1e40af'
    },
    {
      title: 'Research Collaboration',
      description: 'Explore partnership opportunities and collaborative research projects',
      action: 'Contact Research Team',
      color: '#059669'
    },
    {
      title: 'Platform Integration',
      description: 'Discuss API access, custom integrations, and enterprise solutions',
      action: 'Schedule Consultation',
      color: '#dc2626'
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
            <Button color="inherit" onClick={() => navigate('/documentation')}>Documentation</Button>
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
            Contact Us
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
            Get in touch with our team for support, partnerships, and collaborations
          </Typography>
        </Box>

        {/* Contact Information */}
        <Grid container spacing={4} sx={{ mb: 8 }}>
          {contactInfo.map((info, index) => (
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
                  <Box sx={{ mb: 3 }}>
                    {info.icon}
                  </Box>
                  <Typography variant="h5" component="h3" gutterBottom sx={{ fontWeight: 'bold' }}>
                    {info.title}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    {info.description}
                  </Typography>
                  {info.details.map((detail, detailIndex) => (
                    <Typography key={detailIndex} variant="body1" sx={{ mb: 1 }}>
                      {detail}
                    </Typography>
                  ))}
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>

        {/* Support Options */}
        <Typography variant="h4" component="h2" gutterBottom sx={{ textAlign: 'center', mb: 6, color: '#1e40af' }}>
          How Can We Help?
        </Typography>
        
        <Grid container spacing={4} sx={{ mb: 8 }}>
          {supportOptions.map((option, index) => (
            <Grid item xs={12} md={4} key={index}>
              <Card sx={{ height: '100%', p: 3 }}>
                <CardContent>
                  <Typography variant="h6" component="h3" gutterBottom sx={{ fontWeight: 'bold', color: option.color }}>
                    {option.title}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                    {option.description}
                  </Typography>
                  <Button 
                    variant="outlined" 
                    fullWidth
                    sx={{ 
                      borderColor: option.color,
                      color: option.color,
                      '&:hover': {
                        borderColor: option.color,
                        backgroundColor: `${option.color}10`
                      }
                    }}
                  >
                    {option.action}
                  </Button>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>

        {/* Contact Form */}
        <Grid container spacing={4}>
          <Grid item xs={12} md={8}>
            <Card sx={{ p: 4 }}>
              <CardContent>
                <Typography variant="h4" component="h2" gutterBottom sx={{ color: '#1e40af', fontWeight: 'bold' }}>
                  Send us a Message
                </Typography>
                <Typography variant="body1" sx={{ mb: 4, color: 'text.secondary' }}>
                  Have a question or need support? Fill out the form below and we'll get back to you as soon as possible.
                </Typography>
                
                {submitted && (
                  <Alert severity="success" sx={{ mb: 3 }}>
                    Thank you for your message! We'll get back to you within 24 hours.
                  </Alert>
                )}
                
                <Box component="form" onSubmit={handleSubmit}>
                  <Grid container spacing={3}>
                    <Grid item xs={12} sm={6}>
                      <TextField
                        fullWidth
                        label="Full Name"
                        name="name"
                        value={formData.name}
                        onChange={handleInputChange}
                        required
                      />
                    </Grid>
                    <Grid item xs={12} sm={6}>
                      <TextField
                        fullWidth
                        label="Email Address"
                        name="email"
                        type="email"
                        value={formData.email}
                        onChange={handleInputChange}
                        required
                      />
                    </Grid>
                    <Grid item xs={12}>
                      <TextField
                        fullWidth
                        label="Subject"
                        name="subject"
                        value={formData.subject}
                        onChange={handleInputChange}
                        required
                      />
                    </Grid>
                    <Grid item xs={12}>
                      <TextField
                        fullWidth
                        label="Message"
                        name="message"
                        multiline
                        rows={6}
                        value={formData.message}
                        onChange={handleInputChange}
                        required
                      />
                    </Grid>
                    <Grid item xs={12}>
                      <Button 
                        type="submit"
                        variant="contained"
                        size="large"
                        startIcon={<Send />}
                        sx={{ 
                          background: 'linear-gradient(135deg, #1e40af, #0f766e)',
                          '&:hover': {
                            background: 'linear-gradient(135deg, #1e3a8a, #0d4f49)',
                          }
                        }}
                      >
                        Send Message
                      </Button>
                    </Grid>
                  </Grid>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          
          <Grid item xs={12} md={4}>
            <Card sx={{ p: 3, height: 'fit-content' }}>
              <CardContent>
                <Typography variant="h5" component="h3" gutterBottom sx={{ color: '#1e40af', fontWeight: 'bold' }}>
                  Connect With Us
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                  Follow our progress and stay updated on the latest developments in federated genomic imputation.
                </Typography>
                
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  {socialLinks.map((link, index) => (
                    <Button
                      key={index}
                      variant="outlined"
                      startIcon={link.icon}
                      fullWidth
                      onClick={() => window.open(link.url, '_blank')}
                      sx={{ justifyContent: 'flex-start' }}
                    >
                      {link.name}
                    </Button>
                  ))}
                </Box>
                
                <Box sx={{ mt: 4, p: 3, backgroundColor: '#f8fafc', borderRadius: 2 }}>
                  <Typography variant="h6" gutterBottom sx={{ fontWeight: 'bold' }}>
                    <Support sx={{ mr: 1, verticalAlign: 'middle' }} />
                    Quick Support
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    For urgent technical issues, please email us directly at support@afrigen-d.org with "URGENT" in the subject line.
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
};

export default Contact; 