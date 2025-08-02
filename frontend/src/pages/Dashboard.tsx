import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Button,
  Chip,
  LinearProgress,
  Alert,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  CircularProgress,
  Paper,
} from '@mui/material';
import {
  Add,
  Assignment,
  CheckCircle,
  Error,
  Schedule,
  Pending,
  Storage,
  Group,
  Speed,
  TrendingUp,
} from '@mui/icons-material';
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { format } from 'date-fns';
import { useApi, DashboardStats, ImputationJob } from '../contexts/ApiContext';

const Dashboard: React.FC = () => {
  const navigate = useNavigate();
  const { getDashboardStats } = useApi();
  
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getDashboardStats();
      setStats(data);
    } catch (err) {
      console.error('Error loading dashboard:', err);
      setError('Failed to load dashboard data. Using default values.');
      // Set default stats if API fails
      setStats({
        job_stats: {
          total: 0,
          completed: 0,
          running: 0,
          failed: 0,
          success_rate: 0
        },
        service_stats: {
          available_services: 0,
          accessible_services: 0
        },
        recent_jobs: []
      });
    } finally {
      setLoading(false);
    }
  };

  const getServiceIcon = (serviceType: string) => {
    switch (serviceType) {
      case 'h3africa':
        return <Group color="primary" />;
      case 'michigan':
        return <Speed color="secondary" />;
      default:
        return <Storage />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return '#4caf50';
      case 'failed':
        return '#f44336';
      case 'running':
        return '#2196f3';
      case 'pending':
        return '#ff9800';
      default:
        return '#9e9e9e';
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mb: 2 }}>
        {error}
      </Alert>
    );
  }

  if (!stats) {
    return (
      <Alert severity="info">
        No dashboard data available.
      </Alert>
    );
  }

  // Prepare chart data
  const statusData = [
    { name: 'Completed', value: stats.job_stats.completed, color: '#4caf50' },
    { name: 'Running', value: stats.job_stats.running, color: '#2196f3' },
    { name: 'Failed', value: stats.job_stats.failed, color: '#f44336' },
  ];

  return (
    <Box sx={{ p: 3 }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
        <Box>
          <Typography variant="h4" gutterBottom>
            Dashboard
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Overview of your imputation jobs and available services
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => navigate('/jobs/new')}
          size="large"
        >
          New Job
        </Button>
      </Box>

      {/* Statistics Cards */}
      <Grid container spacing={3} mb={4}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <Assignment color="primary" sx={{ fontSize: 40, mr: 2 }} />
                <Box>
                  <Typography variant="h4" fontWeight="bold">
                    {stats.job_stats.total}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Jobs
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <CheckCircle color="success" sx={{ fontSize: 40, mr: 2 }} />
                <Box>
                  <Typography variant="h4" fontWeight="bold">
                    {stats.job_stats.completed}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Completed
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <Schedule color="info" sx={{ fontSize: 40, mr: 2 }} />
                <Box>
                  <Typography variant="h4" fontWeight="bold">
                    {stats.job_stats.running}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Running
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <TrendingUp color="success" sx={{ fontSize: 40, mr: 2 }} />
                <Box>
                  <Typography variant="h4" fontWeight="bold">
                    {stats.job_stats.success_rate.toFixed(1)}%
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Success Rate
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={3}>
        {/* Job Status Chart */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Job Status Distribution
              </Typography>
              {stats.job_stats.total > 0 ? (
                <Box height={300}>
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={statusData}
                        cx="50%"
                        cy="50%"
                        outerRadius={80}
                        fill="#8884d8"
                        dataKey="value"
                        label={({ name, value }) => `${name}: ${value}`}
                      >
                        {statusData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                      </Pie>
                      <Tooltip />
                    </PieChart>
                  </ResponsiveContainer>
                </Box>
              ) : (
                <Box display="flex" justifyContent="center" alignItems="center" height={300}>
                  <Typography variant="body2" color="text.secondary">
                    No jobs yet. Create your first job to see statistics.
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Recent Jobs */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Recent Jobs
              </Typography>
              {stats.recent_jobs.length > 0 ? (
                <List>
                  {stats.recent_jobs.map((job, index) => (
                    <ListItem
                      key={job.id}
                      button
                      onClick={() => navigate(`/jobs/${job.id}`)}
                      divider={index < stats.recent_jobs.length - 1}
                    >
                      <ListItemIcon>
                        {getServiceIcon(job.service.service_type)}
                      </ListItemIcon>
                      <ListItemText
                        primary={
                          <Box display="flex" alignItems="center" justifyContent="space-between">
                            <Typography variant="body1">
                              {job.name}
                            </Typography>
                            <Chip
                              label={job.status.toUpperCase()}
                              size="small"
                              sx={{
                                backgroundColor: getStatusColor(job.status),
                                color: 'white',
                              }}
                            />
                          </Box>
                        }
                        secondary={
                          <Box>
                            <Typography variant="caption" color="text.secondary">
                              {job.service.name} • {format(new Date(job.created_at), 'MMM dd, HH:mm')}
                            </Typography>
                            {['pending', 'queued', 'running'].includes(job.status) && (
                              <LinearProgress
                                variant="determinate"
                                value={job.progress_percentage}
                                sx={{ mt: 1 }}
                              />
                            )}
                          </Box>
                        }
                      />
                    </ListItem>
                  ))}
                </List>
              ) : (
                <Box display="flex" flexDirection="column" alignItems="center" py={4}>
                  <Typography variant="body2" color="text.secondary" mb={2}>
                    No recent jobs found
                  </Typography>
                  <Button
                    variant="outlined"
                    startIcon={<Add />}
                    onClick={() => navigate('/jobs/new')}
                  >
                    Create First Job
                  </Button>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Service Statistics */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Service Information
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <Paper sx={{ p: 2, textAlign: 'center' }}>
                    <Storage color="primary" sx={{ fontSize: 48, mb: 1 }} />
                    <Typography variant="h6">
                      {stats.service_stats.available_services}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Available Services
                    </Typography>
                  </Paper>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Paper sx={{ p: 2, textAlign: 'center' }}>
                    <CheckCircle color="success" sx={{ fontSize: 48, mb: 1 }} />
                    <Typography variant="h6">
                      {stats.service_stats.accessible_services}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Accessible Services
                    </Typography>
                  </Paper>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard; 