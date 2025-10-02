import React, { createContext, useContext, useState, useCallback } from 'react';
import {
  Snackbar,
  Alert,
  AlertTitle,
  Slide,
  Stack,
  Portal,
  IconButton,
  Box,
  Typography,
} from '@mui/material';
import {
  Close,
  CheckCircle,
  Warning,
  Info,
  Notifications,
  ErrorOutline as ErrorIcon,
} from '@mui/icons-material';

export type NotificationType = 'success' | 'error' | 'warning' | 'info';

export interface Notification {
  id: string;
  type: NotificationType;
  title?: string;
  message: string;
  duration?: number;
  persistent?: boolean;
  action?: {
    label: string;
    onClick: () => void;
  };
}

interface NotificationContextType {
  notifications: Notification[];
  showNotification: (notification: Omit<Notification, 'id'>) => string;
  hideNotification: (id: string) => void;
  clearAll: () => void;
  showSuccess: (message: string, title?: string, options?: Partial<Notification>) => string;
  showError: (message: string, title?: string, options?: Partial<Notification>) => string;
  showWarning: (message: string, title?: string, options?: Partial<Notification>) => string;
  showInfo: (message: string, title?: string, options?: Partial<Notification>) => string;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

export const useNotifications = () => {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotifications must be used within a NotificationProvider');
  }
  return context;
};

interface NotificationProviderProps {
  children: React.ReactNode;
  maxNotifications?: number;
}

export const NotificationProvider: React.FC<NotificationProviderProps> = ({
  children,
  maxNotifications = 5,
}) => {
  const [notifications, setNotifications] = useState<Notification[]>([]);

  const generateId = useCallback(() => {
    return `notification-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }, []);

  const showNotification = useCallback((notification: Omit<Notification, 'id'>) => {
    const id = generateId();
    const newNotification: Notification = {
      id,
      duration: 6000,
      ...notification,
    };

    setNotifications(prev => {
      const updated = [newNotification, ...prev];
      // Limit the number of notifications
      return updated.slice(0, maxNotifications);
    });

    // Auto-hide non-persistent notifications
    if (!newNotification.persistent && newNotification.duration && newNotification.duration > 0) {
      setTimeout(() => {
        hideNotification(id);
      }, newNotification.duration);
    }

    return id;
  }, [generateId, maxNotifications]);

  const hideNotification = useCallback((id: string) => {
    setNotifications(prev => prev.filter(notification => notification.id !== id));
  }, []);

  const clearAll = useCallback(() => {
    setNotifications([]);
  }, []);

  const showSuccess = useCallback((message: string, title?: string, options?: Partial<Notification>) => {
    return showNotification({
      type: 'success',
      title,
      message,
      ...options,
    });
  }, [showNotification]);

  const showError = useCallback((message: string, title?: string, options?: Partial<Notification>) => {
    return showNotification({
      type: 'error',
      title,
      message,
      persistent: true, // Errors should be persistent by default
      ...options,
    });
  }, [showNotification]);

  const showWarning = useCallback((message: string, title?: string, options?: Partial<Notification>) => {
    return showNotification({
      type: 'warning',
      title,
      message,
      duration: 8000, // Warnings should stay longer
      ...options,
    });
  }, [showNotification]);

  const showInfo = useCallback((message: string, title?: string, options?: Partial<Notification>) => {
    return showNotification({
      type: 'info',
      title,
      message,
      ...options,
    });
  }, [showNotification]);

  const getIcon = (type: NotificationType) => {
    switch (type) {
      case 'success':
        return <CheckCircle />;
      case 'error':
        return <ErrorIcon />;
      case 'warning':
        return <Warning />;
      case 'info':
        return <Info />;
      default:
        return <Notifications />;
    }
  };

  const value: NotificationContextType = {
    notifications,
    showNotification,
    hideNotification,
    clearAll,
    showSuccess,
    showError,
    showWarning,
    showInfo,
  };

  return (
    <NotificationContext.Provider value={value}>
      {children}
      
      {/* Notification Container */}
      <Portal>
        <Box
          sx={{
            position: 'fixed',
            top: 80,
            right: 16,
            zIndex: (theme) => theme.zIndex.snackbar,
            maxWidth: 400,
            width: '100%',
          }}
          role="region"
          aria-label="Notifications"
          aria-live="polite"
        >
          <Stack spacing={1}>
            {notifications.map((notification) => (
              <Slide
                key={notification.id}
                direction="left"
                in={true}
                mountOnEnter
                unmountOnExit
              >
                <Alert
                  severity={notification.type}
                  icon={getIcon(notification.type)}
                  action={
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      {notification.action && (
                        <IconButton
                          size="small"
                          onClick={notification.action.onClick}
                          sx={{ color: 'inherit' }}
                          aria-label={notification.action.label}
                        >
                          <Typography variant="button" sx={{ fontSize: '0.75rem' }}>
                            {notification.action.label}
                          </Typography>
                        </IconButton>
                      )}
                      <IconButton
                        size="small"
                        onClick={() => hideNotification(notification.id)}
                        sx={{ color: 'inherit' }}
                        aria-label="Close notification"
                      >
                        <Close fontSize="small" />
                      </IconButton>
                    </Box>
                  }
                  sx={{
                    width: '100%',
                    boxShadow: 3,
                    '& .MuiAlert-message': {
                      width: '100%',
                    },
                  }}
                >
                  {notification.title && (
                    <AlertTitle>{notification.title}</AlertTitle>
                  )}
                  <Typography variant="body2" component="div">
                    {notification.message}
                  </Typography>
                </Alert>
              </Slide>
            ))}
          </Stack>
        </Box>
      </Portal>
    </NotificationContext.Provider>
  );
};

// Hook for easy access to common notification patterns
export const useNotificationHelpers = () => {
  const { showSuccess, showError, showWarning, showInfo } = useNotifications();

  return {
    notifySuccess: showSuccess,
    notifyError: showError,
    notifyWarning: showWarning,
    notifyInfo: showInfo,
    
    // Common patterns
    notifyApiError: (error: any, defaultMessage = 'An error occurred') => {
      const message = error?.response?.data?.message || error?.message || defaultMessage;
      return showError(message, 'API Error');
    },
    
    notifyLoadingError: (resource = 'data') => {
      return showError(
        `Failed to load ${resource}. Please try again or contact support if the problem persists.`,
        'Loading Error'
      );
    },
    
    notifyActionSuccess: (action: string, resource?: string) => {
      const message = resource ? `${action} ${resource} successfully` : `${action} completed successfully`;
      return showSuccess(message);
    },
    
    notifyValidationError: (message: string) => {
      return showWarning(message, 'Validation Error');
    },
  };
};
