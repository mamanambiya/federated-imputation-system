import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Grid,
  Skeleton,
  Stack,
  Typography,
  CircularProgress,
  LinearProgress,
  Backdrop,
  Fade,
} from '@mui/material';

// Generic Loading Spinner
interface LoadingSpinnerProps {
  size?: number;
  message?: string;
  fullScreen?: boolean;
  color?: 'primary' | 'secondary' | 'inherit';
}

export const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({
  size = 40,
  message,
  fullScreen = false,
  color = 'primary',
}) => {
  const content = (
    <Box
      display="flex"
      flexDirection="column"
      alignItems="center"
      justifyContent="center"
      gap={2}
      sx={{
        minHeight: fullScreen ? '100vh' : '200px',
        width: '100%',
      }}
      role="status"
      aria-label={message || 'Loading'}
    >
      <CircularProgress size={size} color={color} />
      {message && (
        <Typography variant="body2" color="text.secondary" align="center">
          {message}
        </Typography>
      )}
    </Box>
  );

  if (fullScreen) {
    return (
      <Backdrop open={true} sx={{ color: '#fff', zIndex: (theme) => theme.zIndex.modal + 1 }}>
        {content}
      </Backdrop>
    );
  }

  return content;
};

// Dashboard Statistics Skeleton
export const DashboardStatsSkeleton: React.FC = () => (
  <Grid container spacing={3}>
    {[1, 2, 3, 4].map((index) => (
      <Grid item xs={12} sm={6} md={3} key={index}>
        <Card>
          <CardContent>
            <Box display="flex" alignItems="center">
              <Skeleton variant="circular" width={40} height={40} sx={{ mr: 2 }} />
              <Box sx={{ flexGrow: 1 }}>
                <Skeleton variant="text" width="60%" height={32} />
                <Skeleton variant="text" width="80%" height={20} />
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
    ))}
  </Grid>
);

// Chart Skeleton
export const ChartSkeleton: React.FC<{ height?: number }> = ({ height = 300 }) => (
  <Card>
    <CardContent>
      <Skeleton variant="text" width="40%" height={24} sx={{ mb: 2 }} />
      <Skeleton variant="rectangular" width="100%" height={height} />
    </CardContent>
  </Card>
);

// Table Skeleton
interface TableSkeletonProps {
  rows?: number;
  columns?: number;
}

export const TableSkeleton: React.FC<TableSkeletonProps> = ({ rows = 5, columns = 4 }) => (
  <Card>
    <CardContent>
      <Skeleton variant="text" width="30%" height={24} sx={{ mb: 2 }} />
      <Stack spacing={1}>
        {Array.from({ length: rows }).map((_, rowIndex) => (
          <Box key={rowIndex} display="flex" gap={2}>
            {Array.from({ length: columns }).map((_, colIndex) => (
              <Skeleton
                key={colIndex}
                variant="text"
                width={`${100 / columns}%`}
                height={20}
              />
            ))}
          </Box>
        ))}
      </Stack>
    </CardContent>
  </Card>
);

// Service Card Skeleton
export const ServiceCardSkeleton: React.FC = () => (
  <Card>
    <CardContent>
      <Box display="flex" alignItems="center" mb={2}>
        <Skeleton variant="circular" width={48} height={48} sx={{ mr: 2 }} />
        <Box sx={{ flexGrow: 1 }}>
          <Skeleton variant="text" width="70%" height={24} />
          <Skeleton variant="text" width="50%" height={20} />
        </Box>
      </Box>
      <Skeleton variant="text" width="100%" height={20} sx={{ mb: 1 }} />
      <Skeleton variant="text" width="80%" height={20} sx={{ mb: 2 }} />
      <Box display="flex" gap={1} mb={2}>
        <Skeleton variant="rounded" width={60} height={24} />
        <Skeleton variant="rounded" width={80} height={24} />
        <Skeleton variant="rounded" width={70} height={24} />
      </Box>
      <Skeleton variant="rectangular" width="100%" height={36} />
    </CardContent>
  </Card>
);

// Job List Skeleton
export const JobListSkeleton: React.FC<{ count?: number }> = ({ count = 3 }) => (
  <Stack spacing={2}>
    {Array.from({ length: count }).map((_, index) => (
      <Card key={index}>
        <CardContent>
          <Box display="flex" justifyContent="space-between" alignItems="start" mb={2}>
            <Box sx={{ flexGrow: 1 }}>
              <Skeleton variant="text" width="60%" height={24} />
              <Skeleton variant="text" width="40%" height={20} />
            </Box>
            <Skeleton variant="rounded" width={80} height={24} />
          </Box>
          <Box display="flex" alignItems="center" gap={2} mb={2}>
            <Skeleton variant="circular" width={24} height={24} />
            <Skeleton variant="text" width="30%" height={20} />
            <Skeleton variant="text" width="20%" height={20} />
          </Box>
          <Skeleton variant="rectangular" width="100%" height={8} sx={{ mb: 1 }} />
          <Box display="flex" justifyContent="space-between">
            <Skeleton variant="text" width="25%" height={16} />
            <Skeleton variant="text" width="15%" height={16} />
          </Box>
        </CardContent>
      </Card>
    ))}
  </Stack>
);

// Progress Loading Component
interface ProgressLoadingProps {
  progress?: number;
  message?: string;
  indeterminate?: boolean;
}

export const ProgressLoading: React.FC<ProgressLoadingProps> = ({
  progress,
  message,
  indeterminate = false,
}) => (
  <Box sx={{ width: '100%', p: 2 }}>
    <Box display="flex" alignItems="center" mb={1}>
      <Box sx={{ flexGrow: 1 }}>
        {message && (
          <Typography variant="body2" color="text.secondary">
            {message}
          </Typography>
        )}
      </Box>
      {!indeterminate && progress !== undefined && (
        <Typography variant="body2" color="text.secondary">
          {Math.round(progress)}%
        </Typography>
      )}
    </Box>
    <LinearProgress
      variant={indeterminate ? 'indeterminate' : 'determinate'}
      value={progress}
      sx={{ height: 8, borderRadius: 4 }}
    />
  </Box>
);

// Fade Loading Wrapper
interface FadeLoadingProps {
  loading: boolean;
  children: React.ReactNode;
  skeleton?: React.ReactNode;
  minHeight?: number;
}

export const FadeLoading: React.FC<FadeLoadingProps> = ({
  loading,
  children,
  skeleton,
  minHeight = 200,
}) => (
  <Box sx={{ position: 'relative', minHeight }}>
    <Fade in={!loading} timeout={300}>
      <Box sx={{ opacity: loading ? 0.3 : 1 }}>
        {children}
      </Box>
    </Fade>
    {loading && (
      <Fade in={loading} timeout={150}>
        <Box
          sx={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            zIndex: 1,
          }}
        >
          {skeleton || <LoadingSpinner message="Loading..." />}
        </Box>
      </Fade>
    )}
  </Box>
);

// Skeleton Grid for Services/Jobs
interface SkeletonGridProps {
  count?: number;
  columns?: { xs?: number; sm?: number; md?: number; lg?: number };
  renderSkeleton: () => React.ReactNode;
}

export const SkeletonGrid: React.FC<SkeletonGridProps> = ({
  count = 6,
  columns = { xs: 1, sm: 2, md: 3 },
  renderSkeleton,
}) => (
  <Grid container spacing={3}>
    {Array.from({ length: count }).map((_, index) => (
      <Grid item {...columns} key={index}>
        {renderSkeleton()}
      </Grid>
    ))}
  </Grid>
);

// Loading State Manager Hook
export const useLoadingState = (initialState = false) => {
  const [loading, setLoading] = React.useState(initialState);
  const [error, setError] = React.useState<string | null>(null);

  const startLoading = React.useCallback(() => {
    setLoading(true);
    setError(null);
  }, []);

  const stopLoading = React.useCallback(() => {
    setLoading(false);
  }, []);

  const setLoadingError = React.useCallback((errorMessage: string) => {
    setLoading(false);
    setError(errorMessage);
  }, []);

  const reset = React.useCallback(() => {
    setLoading(false);
    setError(null);
  }, []);

  return {
    loading,
    error,
    startLoading,
    stopLoading,
    setLoadingError,
    reset,
  };
};
