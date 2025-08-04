import React from 'react';
import {
  AppBar,
  Toolbar,
  Typography,
  Box,
  Button,
  IconButton,
} from '@mui/material';
import {
  ArrowBack,
  Menu as MenuIcon,
  Rocket,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

interface HeaderProps {
  variant?: 'authenticated' | 'public';
  showBackButton?: boolean;
  onMenuClick?: () => void;
  currentPage?: string;
}

const Header: React.FC<HeaderProps> = ({ 
  variant = 'public', 
  showBackButton = false, 
  onMenuClick,
  currentPage 
}) => {
  const navigate = useNavigate();

  const isAuthenticated = variant === 'authenticated';

  const headerStyles = isAuthenticated 
    ? {
        backgroundColor: 'primary.main',
        color: 'white',
        zIndex: (theme: any) => theme.zIndex.drawer + 1,
      }
    : {
        background: 'rgba(255, 255, 255, 0.95)',
        backdropFilter: 'blur(10px)',
        color: 'text.primary',
        boxShadow: '0 2px 10px rgba(0,0,0,0.1)',
      };

  const logoFilter = isAuthenticated ? 'brightness(0) invert(1)' : 'none';
  const titleColor = isAuthenticated ? 'white' : '#1e40af';

  return (
    <AppBar position="fixed" sx={headerStyles}>
      <Toolbar>
        {/* Left Side - Menu/Back Button */}
        {isAuthenticated && onMenuClick && (
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={onMenuClick}
            sx={{ mr: 2 }}
          >
            <MenuIcon />
          </IconButton>
        )}
        
        {!isAuthenticated && showBackButton && (
          <IconButton 
            edge="start" 
            color="inherit" 
            onClick={() => navigate('/')}
            sx={{ mr: 2 }}
          >
            <ArrowBack />
          </IconButton>
        )}

        {/* Center - Logo and Title */}
        <Box sx={{ display: 'flex', alignItems: 'center', flexGrow: 1 }}>
          <Box 
            component="a" 
            href="/"
            sx={{ 
              display: 'flex', 
              alignItems: 'center', 
              textDecoration: 'none',
              cursor: 'pointer',
              '&:hover': {
                opacity: 0.8
              }
            }}
          >
            <img 
              src="/afrigen-d-logo.png" 
              alt="AfriGen-D" 
              style={{ 
                height: 40, 
                marginRight: 12,
                filter: logoFilter
              }} 
            />
            <Typography 
              variant="h6" 
              component="div" 
              sx={{ 
                fontWeight: 'bold', 
                color: titleColor,
                flexGrow: isAuthenticated ? 1 : 0
              }}
            >
              Federated Genomic Imputation Platform
            </Typography>
          </Box>
        </Box>

        {/* Right Side - Navigation or User Menu */}
        {!isAuthenticated && (
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
            <Button 
              color="inherit" 
              onClick={() => navigate('/about')}
              sx={{ color: currentPage === 'about' ? '#1e40af' : 'inherit' }}
            >
              About
            </Button>
            <Button 
              color="inherit" 
              onClick={() => navigate('/services-info')}
              sx={{ color: currentPage === 'services' ? '#1e40af' : 'inherit' }}
            >
              Services
            </Button>
            <Button 
              color="inherit" 
              onClick={() => navigate('/get-started')}
              sx={{ color: currentPage === 'get-started' ? '#1e40af' : 'inherit' }}
            >
              Get Started
            </Button>
            <Button 
              color="inherit" 
              onClick={() => navigate('/documentation')}
              sx={{ color: currentPage === 'documentation' ? '#1e40af' : 'inherit' }}
            >
              Documentation
            </Button>
            <Button 
              color="inherit" 
              onClick={() => navigate('/contact')}
              sx={{ color: currentPage === 'contact' ? '#1e40af' : 'inherit' }}
            >
              Contact
            </Button>
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
  );
};

export default Header; 