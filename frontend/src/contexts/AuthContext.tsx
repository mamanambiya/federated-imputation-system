import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import axios, { AxiosInstance } from 'axios';

interface User {
  id: number;
  username: string;
  email: string;
  first_name: string;
  last_name: string;
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  loading: boolean;
  login: (username: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  const isAuthenticated = user !== null;

  // Create dedicated axios instance for authentication (same config as ApiContext)
  const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';
  const authAxios = axios.create({
    baseURL: `${API_BASE_URL}/api`,
    withCredentials: true,
    headers: {
      'Content-Type': 'application/json',
    },
  });

  // Add request interceptor for JWT token authentication
  authAxios.interceptors.request.use(
    (config) => {
      // Add JWT token to Authorization header if available
      const token = localStorage.getItem('access_token');
      if (token) {
        config.headers['Authorization'] = `Bearer ${token}`;
      }

      // Add CSRF token if available
      const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.getAttribute('content');
      if (csrfToken) {
        config.headers['X-CSRFToken'] = csrfToken;
      }
      return config;
    },
    (error) => {
      return Promise.reject(error);
    }
  );

  // Check if user is logged in on app load
  useEffect(() => {
    checkAuthStatus();
  }, []);

  const checkAuthStatus = async (retryCount = 0) => {
    try {
      console.log('Checking authentication status...');
      const response = await authAxios.get('/auth/user/', {
        timeout: 10000, // 10 second timeout
      });
      console.log('Auth check successful:', response.data);
      // API returns user object directly, not wrapped
      setUser(response.data);
    } catch (error: any) {
      console.log('Auth check failed:', error.response?.status, error.message);

      // Retry once if it's a network error and we haven't retried yet
      if (retryCount === 0 && (error.code === 'NETWORK_ERROR' || error.response?.status >= 500)) {
        console.log('Retrying auth check...');
        setTimeout(() => checkAuthStatus(1), 1000);
        return;
      }

      // User is not authenticated or other error - clear token
      localStorage.removeItem('access_token');
      setUser(null);
    } finally {
      if (retryCount === 0) {
        setLoading(false);
      }
    }
  };

  const login = async (username: string, password: string): Promise<void> => {
    try {
      console.log('Attempting login for:', username);
      console.log('API Base URL:', API_BASE_URL);
      const response = await authAxios.post('/auth/login/',
        { username, password },
        {
          timeout: 30000, // 30 second timeout for login (increased for network reliability)
        }
      );
      console.log('Login response:', response.data);

      // Store JWT token in localStorage
      if (response.data.access_token) {
        localStorage.setItem('access_token', response.data.access_token);
        console.log('JWT token stored successfully');
      }

      // Set user data
      setUser(response.data.user);

      // Verify authentication by checking user info with the same axios instance
      try {
        await checkAuthStatus();
      } catch (verifyError) {
        console.warn('Login succeeded but auth verification failed:', verifyError);
        // Don't throw error here, the login was successful
      }
    } catch (error: any) {
      // Enhanced error logging for debugging
      console.error('=== LOGIN ERROR DETAILS ===');
      console.error('Error object:', error);
      console.error('Error code:', error.code);
      console.error('Error message:', error.message);
      console.error('Error response:', error.response);
      console.error('Error response data:', error.response?.data);
      console.error('Error response status:', error.response?.status);
      console.error('Error response headers:', error.response?.headers);
      console.error('Error config:', error.config);
      console.error('Is axios error:', error.isAxiosError);
      console.error('========================');

      let errorMessage = 'Login failed. Please try again.';

      if (error.response?.status === 401) {
        errorMessage = 'Invalid username or password.';
      } else if (error.response?.status >= 500) {
        errorMessage = 'Server error. Please try again in a moment.';
      } else if (error.code === 'NETWORK_ERROR' || error.code === 'ECONNABORTED' || error.message.includes('Network Error')) {
        // Provide more detailed network error message
        errorMessage = `Network connection error. Please check your internet connection. (Error: ${error.code || error.message})`;
        console.error('Network error details - This might be CORS, timeout, or DNS issue');
      } else if (error.response?.data?.error) {
        errorMessage = error.response.data.error;
      } else if (error.response?.data?.detail) {
        errorMessage = error.response.data.detail;
      }

      throw new Error(errorMessage);
    }
  };

  const logout = async (): Promise<void> => {
    try {
      console.log('Attempting logout...');
      await authAxios.post('/auth/logout/', {}, {
        timeout: 10000 // 10 second timeout
      });
      console.log('Logout successful');
    } catch (error) {
      console.warn('Logout request failed, but clearing local state:', error);
      // Even if logout fails on server, clear local state
    } finally {
      // Clear JWT token from localStorage
      localStorage.removeItem('access_token');
      setUser(null);
    }
  };

  const value: AuthContextType = {
    user,
    isAuthenticated,
    loading,
    login,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}; 