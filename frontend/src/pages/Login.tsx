import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  TextField,
  Button,
  Typography,
  Alert,
  Container,
  Grid,
  Snackbar,
  Alert as MuiAlert,
  Fade,
  CircularProgress,
  Backdrop,
} from '@mui/material';
import { AccountCircle, Lock, CheckCircleOutline, Info } from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate, useLocation } from 'react-router-dom';

const Login: React.FC = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  
  // Feedback and notification state
  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'error' | 'warning' | 'info';
  }>({
    open: false,
    message: '',
    severity: 'info'
  });
  const { login, isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

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

  // Redirect authenticated users away from login page
  useEffect(() => {
    if (isAuthenticated) {
      console.log('User is authenticated, redirecting from login page');
      // Get the intended destination from location state, or default to dashboard
      const from = location.state?.from?.pathname || '/';
      const destinationName = from === '/' ? 'dashboard' : from.replace('/', '');

      console.log('Redirecting to:', from);
      showFeedback(`✅ Login successful! Redirecting to ${destinationName}...`, 'success');

      // Immediate redirect - no delay
      navigate(from, { replace: true });
    }
  }, [isAuthenticated, navigate, location.state]);

  // If already authenticated, show loading state while redirecting
  if (isAuthenticated) {
    return (
      <Container maxWidth="sm">
        <Box
          sx={{
            marginTop: 8,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
          }}
        >
          <CircularProgress size={60} />
          <Typography variant="h6" align="center" sx={{ mt: 2 }}>
            Redirecting to dashboard...
          </Typography>
        </Box>
      </Container>
    );
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    // Input validation
    if (!username || !password) {
      showFeedback('Please enter both username and password', 'warning');
      setLoading(false);
      return;
    }

    showFeedback('Signing in...', 'info');

    try {
      await login(username, password);
      // Success feedback and redirect is now handled by useEffect when isAuthenticated changes
    } catch (err: any) {
      const errorMessage = err.message || 'Login failed. Please check your credentials and try again.';
      setError(errorMessage);
      showFeedback(errorMessage, 'error');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Container maxWidth="sm">
      <Box
        sx={{
          marginTop: 8,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        <Paper
          elevation={3}
          sx={{
            padding: 4,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            width: '100%',
          }}
        >
          <Box sx={{ mb: 3 }}>
            <img 
              src="/afrigen-d-logo.png" 
              alt="AfriGen-D" 
              style={{ 
                height: 80, 
                display: 'block',
                margin: '0 auto'
              }} 
            />
          </Box>
          <Typography component="h1" variant="h4" gutterBottom sx={{ textAlign: 'center' }}>
            Federated Genomic Imputation Platform
          </Typography>
          <Typography variant="h6" color="text.secondary" gutterBottom sx={{ textAlign: 'center' }}>
            Sign in to your account
          </Typography>

          {error && (
            <Alert severity="error" sx={{ width: '100%', mb: 2 }}>
              {error}
            </Alert>
          )}

          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 1, width: '100%' }}>
            <TextField
              margin="normal"
              required
              fullWidth
              id="username"
              label="Username"
              name="username"
              autoComplete="username"
              autoFocus
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              InputProps={{
                startAdornment: <AccountCircle sx={{ mr: 1, color: 'action.active' }} />,
              }}
            />
            <TextField
              margin="normal"
              required
              fullWidth
              name="password"
              label="Password"
              type="password"
              id="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              InputProps={{
                startAdornment: <Lock sx={{ mr: 1, color: 'action.active' }} />,
              }}
            />
            <Button
              type="submit"
              fullWidth
              variant="contained"
              sx={{ mt: 3, mb: 2 }}
              disabled={loading}
            >
              {loading ? 'Signing In...' : 'Sign In'}
            </Button>

            {/* Demo credentials removed for security */}
          </Box>
        </Paper>
      </Box>

      {/* Loading Backdrop */}
      {loading && (
        <Backdrop open={true} sx={{ color: '#fff', zIndex: (theme) => theme.zIndex.modal + 1 }}>
          <Box display="flex" flexDirection="column" alignItems="center" gap={2}>
            <CircularProgress size={60} />
            <Typography variant="h6" align="center">
              Signing you in...
            </Typography>
          </Box>
        </Backdrop>
      )}

      {/* Feedback Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={snackbar.severity === 'error' ? 6000 : 4000}
        onClose={closeFeedback}
        TransitionComponent={Fade}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <MuiAlert
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
          icon={
            snackbar.severity === 'success' ? <CheckCircleOutline /> :
            snackbar.severity === 'info' ? <Info /> : undefined
          }
        >
          {snackbar.message}
        </MuiAlert>
      </Snackbar>
    </Container>
  );
};

export default Login; 