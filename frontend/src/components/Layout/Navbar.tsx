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
      
      {/* User Menu (positioned at top right, but keep it there for now) */}
      <Box sx={{
        position: 'fixed',
        top: 0,
        right: 0,
        height: '64px',
        display: 'flex',
        alignItems: 'center',
        zIndex: 9999
      }}>
        {user && (
          <>
            <Box sx={{ display: 'flex', alignItems: 'center', px: 2 }}>
              <Typography variant="body2" sx={{ mr: 2, color: 'white' }}>
                {user.first_name} {user.last_name}
              </Typography>
              <IconButton
                size="large"
                aria-label="account of current user"
                aria-controls="menu-appbar"
                aria-haspopup="true"
                onClick={handleMenu}
                sx={{ color: 'white' }}
              >
                <Avatar sx={{ width: 32, height: 32 }}>
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
            >
              <MenuItem onClick={handleProfile}>
                <AccountCircle sx={{ mr: 1 }} />
                Profile
              </MenuItem>
              <MenuItem onClick={handleSettings}>
                <Settings sx={{ mr: 1 }} />
                Settings
              </MenuItem>
              <Divider />
              <MenuItem onClick={handleLogout}>
                <Logout sx={{ mr: 1 }} />
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