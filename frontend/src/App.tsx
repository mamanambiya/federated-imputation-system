import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline, Box, CircularProgress } from '@mui/material';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { ApiProvider } from './contexts/ApiContext';

// Import all components
import Navbar from './components/Layout/Navbar';
import Sidebar from './components/Layout/Sidebar';
import Dashboard from './pages/Dashboard';
import Services from './pages/Services';
import ServiceDetail from './pages/ServiceDetail';
import Jobs from './pages/Jobs';
import NewJob from './pages/NewJob';
import JobDetails from './pages/JobDetails';
import Results from './pages/Results';
import Profile from './pages/Profile';
import Settings from './pages/Settings';
import Login from './pages/Login';
import LandingPage from './pages/LandingPage';
import About from './pages/About';
import ServicesInfo from './pages/ServicesInfo';
import GetStarted from './pages/GetStarted';
import Documentation from './pages/Documentation';
import Contact from './pages/Contact';
import UserManagement from './pages/UserManagement';

const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
  typography: {
    h4: {
      fontWeight: 600,
    },
    h5: {
      fontWeight: 600,
    },
    h6: {
      fontWeight: 600,
    },
  },
});

// Authenticated App Content
const AuthenticatedApp: React.FC = () => {
  const [sidebarOpen, setSidebarOpen] = React.useState(true);

  return (
    <Box sx={{ display: 'flex' }}>
      <Navbar onMenuClick={() => setSidebarOpen(!sidebarOpen)} />
      <Sidebar open={sidebarOpen} />
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          padding: 0,
          marginTop: '64px',
          marginLeft: sidebarOpen ? '10px' : '0px',
          transition: 'margin-left 0.3s',
          backgroundColor: 'background.default'
        }}
      >
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/services" element={<Services />} />
          <Route path="/services/:id" element={<ServiceDetail />} />
          <Route path="/jobs" element={<Jobs />} />
          <Route path="/jobs/new" element={<NewJob />} />
          <Route path="/jobs/:id" element={<JobDetails />} />
          <Route path="/results" element={<Results />} />
          <Route path="/profile" element={<Profile />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="/user-management" element={<UserManagement />} />
          {/* Redirect authenticated users from landing page to dashboard */}
          <Route path="/landing" element={<Navigate to="/" replace />} />
        </Routes>
      </Box>
    </Box>
  );
};

// Component to handle redirects to login for protected routes
const RequireAuth: React.FC = () => {
  const location = useLocation();
  
  // Redirect to login with current location stored in state
  return <Navigate to="/login" state={{ from: location }} replace />;
};

// Unauthenticated App Content
const UnauthenticatedApp: React.FC = () => {
  return (
    <Routes>
      {/* React-based landing page at root */}
      <Route path="/" element={<LandingPage />} />
      {/* Alternative landing page route */}
      <Route path="/landing" element={<LandingPage />} />
      {/* Individual page routes */}
      <Route path="/about" element={<About />} />
      <Route path="/services-info" element={<ServicesInfo />} />
      <Route path="/get-started" element={<GetStarted />} />
      <Route path="/documentation" element={<Documentation />} />
      <Route path="/contact" element={<Contact />} />
      {/* Login page */}
      <Route path="/login" element={<Login />} />
      {/* Redirect protected routes to login with location state */}
      <Route path="*" element={<RequireAuth />} />
    </Routes>
  );
};

const AppContent: React.FC = () => {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return (
      <Box
        display="flex"
        justifyContent="center"
        alignItems="center"
        minHeight="100vh"
      >
        <CircularProgress />
      </Box>
    );
  }

  // Show different app structure based on authentication status
  return isAuthenticated ? <AuthenticatedApp /> : <UnauthenticatedApp />;
};

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AuthProvider>
        <ApiProvider>
          <Router>
            <AppContent />
          </Router>
        </ApiProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App; 