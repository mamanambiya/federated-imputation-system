import React from 'react';
import {
  Box,
  Container,
  Typography,
  Grid,
  Link,
  IconButton,
  Divider,
} from '@mui/material';
import {
  GitHub,
  LinkedIn,
  Twitter,
  Email,
} from '@mui/icons-material';

const Footer: React.FC = () => {
  const currentYear = new Date().getFullYear();

  return (
    <Box 
      component="footer" 
      sx={{ 
        backgroundColor: '#1e293b',
        color: 'white',
        py: 4,
        mt: 'auto'
      }}
    >
      <Container maxWidth="lg">
        <Grid container spacing={4}>
          {/* Brand Section */}
          <Grid item xs={12} md={6}>
            <Box sx={{ mb: 3 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <img 
                  src="/afrigen-d-logo.png" 
                  alt="AfriGen-D" 
                  style={{ 
                    height: 32, 
                    marginRight: 12,
                    filter: 'brightness(0) invert(1)'
                  }} 
                />
                <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                  Federated Genomic Imputation Platform
                </Typography>
              </Box>
              <Typography variant="body2" sx={{ color: 'rgba(255,255,255,0.8)', mb: 3 }}>
                Empowering genomic research across Africa through federated imputation services.
              </Typography>
            </Box>
          </Grid>

          {/* Links Section */}
          <Grid item xs={12} md={6}>
            <Grid container spacing={3}>
              <Grid item xs={6}>
                <Typography variant="h6" gutterBottom sx={{ fontWeight: 'bold', mb: 2 }}>
                  Platform
                </Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                  <Link href="/about" sx={{ color: 'rgba(255,255,255,0.8)', textDecoration: 'none', '&:hover': { color: 'white' } }}>
                    About
                  </Link>
                  <Link href="/services-info" sx={{ color: 'rgba(255,255,255,0.8)', textDecoration: 'none', '&:hover': { color: 'white' } }}>
                    Services
                  </Link>
                  <Link href="/get-started" sx={{ color: 'rgba(255,255,255,0.8)', textDecoration: 'none', '&:hover': { color: 'white' } }}>
                    Get Started
                  </Link>
                  <Link href="/documentation" sx={{ color: 'rgba(255,255,255,0.8)', textDecoration: 'none', '&:hover': { color: 'white' } }}>
                    Documentation
                  </Link>
                </Box>
              </Grid>
              <Grid item xs={6}>
                <Typography variant="h6" gutterBottom sx={{ fontWeight: 'bold', mb: 2 }}>
                  Resources
                </Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                  <Link href="/contact" sx={{ color: 'rgba(255,255,255,0.8)', textDecoration: 'none', '&:hover': { color: 'white' } }}>
                    Support
                  </Link>
                  <Link href="https://github.com/mamanambiya/federated-imputation-system" target="_blank" sx={{ color: 'rgba(255,255,255,0.8)', textDecoration: 'none', '&:hover': { color: 'white' } }}>
                    GitHub
                  </Link>
                  <Link href="/api/docs/" sx={{ color: 'rgba(255,255,255,0.8)', textDecoration: 'none', '&:hover': { color: 'white' } }}>
                    API Docs
                  </Link>
                </Box>
              </Grid>
            </Grid>
          </Grid>
        </Grid>

        <Divider sx={{ my: 3, borderColor: 'rgba(255,255,255,0.2)' }} />

        {/* Bottom Section */}
        <Grid container justifyContent="space-between" alignItems="center">
          <Grid item xs={12} md={8}>
            <Typography variant="body2" sx={{ color: 'rgba(255,255,255,0.6)' }}>
              © {currentYear} AfriGen-D Initiative. All rights reserved.
            </Typography>
          </Grid>
          <Grid item xs={12} md={4}>
            <Box sx={{ display: 'flex', justifyContent: { xs: 'flex-start', md: 'flex-end' }, gap: 1, mt: { xs: 2, md: 0 } }}>
              <IconButton
                href="https://github.com/mamanambiya/federated-imputation-system"
                target="_blank"
                sx={{ color: 'rgba(255,255,255,0.8)', '&:hover': { color: 'white' } }}
              >
                <GitHub />
              </IconButton>
              <IconButton
                href="https://linkedin.com/company/afrigen-d"
                target="_blank"
                sx={{ color: 'rgba(255,255,255,0.8)', '&:hover': { color: 'white' } }}
              >
                <LinkedIn />
              </IconButton>
              <IconButton
                href="https://twitter.com/afrigenomics"
                target="_blank"
                sx={{ color: 'rgba(255,255,255,0.8)', '&:hover': { color: 'white' } }}
              >
                <Twitter />
              </IconButton>
              <IconButton
                href="mailto:support@afrigen-d.org"
                sx={{ color: 'rgba(255,255,255,0.8)', '&:hover': { color: 'white' } }}
              >
                <Email />
              </IconButton>
            </Box>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
};

export default Footer; 