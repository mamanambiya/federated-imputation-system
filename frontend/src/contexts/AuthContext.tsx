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

  // Add request interceptor for CSRF tokens (same as ApiContext)
  authAxios.interceptors.request.use(
    (config) => {
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
      setUser(response.data.user);
    } catch (error: any) {
      console.log('Auth check failed:', error.response?.status, error.message);
      
      // Retry once if it's a network error and we haven't retried yet
      if (retryCount === 0 && (error.code === 'NETWORK_ERROR' || error.response?.status >= 500)) {
        console.log('Retrying auth check...');
        setTimeout(() => checkAuthStatus(1), 1000);
        return;
      }
      
      // User is not authenticated or other error
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
      const response = await authAxios.post('/auth/login/', 
        { username, password },
        { 
          timeout: 15000, // 15 second timeout for login
        }
      );
      console.log('Login response:', response.data);
      setUser(response.data.user);
      
      // Verify authentication by checking user info with the same axios instance
      try {
        await checkAuthStatus();
      } catch (verifyError) {
        console.warn('Login succeeded but auth verification failed:', verifyError);
        // Don't throw error here, the login was successful
      }
    } catch (error: any) {
      console.error('Login error:', error);
      console.error('Login error response:', error.response?.data);
      console.error('Login error status:', error.response?.status);
      
      let errorMessage = 'Login failed. Please try again.';
      
      if (error.response?.status === 401) {
        errorMessage = 'Invalid username or password.';
      } else if (error.response?.status >= 500) {
        errorMessage = 'Server error. Please try again in a moment.';
      } else if (error.code === 'NETWORK_ERROR' || error.message.includes('Network Error')) {
        errorMessage = 'Network connection error. Please check your internet connection.';
      } else if (error.response?.data?.error) {
        errorMessage = error.response.data.error;
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