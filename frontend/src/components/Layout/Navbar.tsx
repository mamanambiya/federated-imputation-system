import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  AppBar,
  Toolbar,
  Typography,
  Box,
  IconButton,
  Avatar,
  Menu,
  MenuItem,
  Divider,
  Snackbar,
  Alert,
  Fade,
} from '@mui/material';
import {
  AccountCircle,
  Logout,
  Settings,
  Menu as MenuIcon,
  Info,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import Header from './Header';

interface NavbarProps {
  onMenuClick?: () => void;
}

const Navbar: React.FC<NavbarProps> = ({ onMenuClick }) => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  
  // Feedback state
  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'error' | 'warning' | 'info';
  }>({
    open: false,
    message: '',
    severity: 'info'
  });

  // Feedback helper functions
  const showFeedback = (message: string, severity: 'success' | 'error' | 'warning' | 'info') => {
    setSnackbar({
      open: true,
      message,
      severity
    });
  };

  const closeFeedback = () => {
    setSnackbar(prev => ({ ...prev, open: false }));
  };

  const handleMenu = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleProfile = () => {
    handleClose();
    navigate('/profile');
  };

  const handleSettings = () => {
    handleClose();
    navigate('/settings');
  };

  const handleLogout = async () => {
    handleClose();
    showFeedback('Signing out...', 'info');
    
    try {
      await logout();
      showFeedback('✅ Successfully signed out. Redirecting to home page...', 'success');
      
      // Small delay to show the success message before redirect
      setTimeout(() => {
        navigate('/');
      }, 1500);
    } catch (error) {
      console.error('Logout error:', error);
      showFeedback('⚠️ Logout encountered an issue, but you have been signed out', 'warning');
      
      // Even if logout fails, redirect to landing page after showing message
      setTimeout(() => {
        navigate('/');
      }, 2000);
    }
  };

  return (
    <>
      <Header 
        variant="authenticated" 
        onMenuClick={onMenuClick}
      />
      
      {/* User Menu (vertically centered with responsive design) */}
      <Box sx={{
        position: 'fixed',
        top: 0,
        right: 0,
        height: '64px',
        display: 'flex',
        alignItems: 'center',
        zIndex: 9999,
        // Responsive padding
        px: { xs: 1, sm: 2, md: 3 }
      }}>
        {user && (
          <>
            <Box sx={{
              display: 'flex',
              alignItems: 'center',
              gap: { xs: 1, sm: 1.5 },
              borderRadius: '8px',
              px: { xs: 1, sm: 1.5 },
              py: 0.5,
              cursor: 'pointer',
              '&:hover': {
                backgroundColor: 'rgba(255, 255, 255, 0.1)',
              }
            }}
            onClick={handleMenu}
            role="button"
            tabIndex={0}
            onKeyPress={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                handleMenu(e as any);
              }
            }}
            >
              <Typography
                variant="body2"
                sx={{
                  color: 'white',
                  fontWeight: 500,
                  display: { xs: 'none', sm: 'block' },
                }}
              >
                {user.first_name} {user.last_name}
              </Typography>
              <IconButton
                size="large"
                aria-label="account of current user"
                aria-controls="menu-appbar"
                aria-haspopup="true"
                onClick={handleMenu}
                sx={{
                  color: 'white',
                  p: 0.5,
                }}
              >
                <Avatar sx={{
                  width: { xs: 32, sm: 36 },
                  height: { xs: 32, sm: 36 },
                  bgcolor: 'primary.dark',
                  fontWeight: 600,
                  fontSize: { xs: '0.9rem', sm: '1rem' },
                  border: '2px solid rgba(255, 255, 255, 0.3)',
                }}>
                  {user.first_name?.charAt(0) || user.username?.charAt(0)}
                </Avatar>
              </IconButton>
            </Box>
            <Menu
              id="menu-appbar"
              anchorEl={anchorEl}
              anchorOrigin={{
                vertical: 'bottom',
                horizontal: 'right',
              }}
              keepMounted
              transformOrigin={{
                vertical: 'top',
                horizontal: 'right',
              }}
              open={Boolean(anchorEl)}
              onClose={handleClose}
              TransitionComponent={Fade}
              slotProps={{
                paper: {
                  elevation: 8,
                  sx: {
                    mt: 1.5,
                    minWidth: 200,
                    borderRadius: 2,
                    overflow: 'visible',
                    filter: 'drop-shadow(0px 4px 12px rgba(0,0,0,0.15))',
                    '&:before': {
                      content: '""',
                      display: 'block',
                      position: 'absolute',
                      top: 0,
                      right: 14,
                      width: 10,
                      height: 10,
                      bgcolor: 'background.paper',
                      transform: 'translateY(-50%) rotate(45deg)',
                      zIndex: 0,
                    },
                  }
                }
              }}
            >
              <MenuItem
                onClick={handleProfile}
                sx={{ py: 1.5 }}
              >
                <AccountCircle sx={{ mr: 1.5 }} />
                Profile
              </MenuItem>
              <MenuItem
                onClick={handleSettings}
                sx={{ py: 1.5 }}
              >
                <Settings sx={{ mr: 1.5 }} />
                Settings
              </MenuItem>
              <Divider sx={{ my: 0.5 }} />
              <MenuItem
                onClick={handleLogout}
                sx={{
                  py: 1.5,
                  color: 'error.main',
                  '&:hover': {
                    backgroundColor: 'error.main',
                    color: 'white',
                  }
                }}
              >
                <Logout sx={{ mr: 1.5 }} />
                Logout
              </MenuItem>
            </Menu>
          </>
        )}
      </Box>

      {/* Feedback Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={snackbar.severity === 'success' ? 5000 : 4000}
        onClose={closeFeedback}
        TransitionComponent={Fade}
        anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
        sx={{ mt: 7 }} // Add margin to account for AppBar height
      >
        <Alert
          onClose={closeFeedback}
          severity={snackbar.severity}
          variant="filled"
          sx={{ 
            width: '100%',
            '& .MuiAlert-message': {
              fontSize: '0.95rem',
              fontWeight: 500
            }
          }}
          icon={snackbar.severity === 'info' ? <Info /> : undefined}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </>
  );
};

export default Navbar; 