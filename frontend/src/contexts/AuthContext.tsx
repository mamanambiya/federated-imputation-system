import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import axios from 'axios';

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

  // Check if user is logged in on app load
  useEffect(() => {
    checkAuthStatus();
  }, []);

  const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

  const checkAuthStatus = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/auth/user/`, {
        withCredentials: true,
      });
      setUser(response.data.user);
    } catch (error) {
      // User is not authenticated
      setUser(null);
    } finally {
      setLoading(false);
    }
  };

  const login = async (username: string, password: string): Promise<void> => {
    try {
      console.log('Attempting login for:', username);
      const response = await axios.post(
        `${API_BASE_URL}/api/auth/login/`,
        { username, password },
        { withCredentials: true }
      );
      console.log('Login response:', response.data);
      setUser(response.data.user);
    } catch (error: any) {
      console.error('Login error:', error);
      console.error('Login error response:', error.response?.data);
      console.error('Login error status:', error.response?.status);
      throw new Error(error.response?.data?.error || error.message || 'Login failed');
    }
  };

  const logout = async (): Promise<void> => {
    try {
      await axios.post(
        `${API_BASE_URL}/api/auth/logout/`,
        {},
        { withCredentials: true }
      );
    } catch (error) {
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