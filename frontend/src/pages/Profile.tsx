import React from 'react';
import {
  Box,
  Paper,
  Typography,
  Grid,
  Avatar,
  List,
  ListItem,
  ListItemText,
  Divider,
  Button,
} from '@mui/material';
import { Edit, Email, Person, CalendarToday } from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';

const Profile: React.FC = () => {
  const { user } = useAuth();

  if (!user) {
    return (
      <Box sx={{ p: 3 }}>
        <Typography>Loading...</Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        My Profile
      </Typography>

      <Grid container spacing={3}>
        {/* Profile Overview */}
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 3, textAlign: 'center' }}>
            <Avatar
              sx={{
                width: 120,
                height: 120,
                margin: '0 auto',
                mb: 2,
                bgcolor: 'primary.main',
                fontSize: '3rem',
              }}
            >
              {user.first_name?.charAt(0) || user.username?.charAt(0)}
            </Avatar>
            <Typography variant="h5" gutterBottom>
              {user.first_name} {user.last_name}
            </Typography>
            <Typography variant="body2" color="text.secondary" gutterBottom>
              @{user.username}
            </Typography>
            <Button
              variant="outlined"
              startIcon={<Edit />}
              sx={{ mt: 2 }}
              disabled
            >
              Edit Profile
            </Button>
          </Paper>
        </Grid>

        {/* Account Information */}
        <Grid item xs={12} md={8}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Account Information
            </Typography>
            <List>
              <ListItem>
                <ListItemText
                  primary="Username"
                  secondary={user.username}
                />
              </ListItem>
              <Divider />
              <ListItem>
                <ListItemText
                  primary="Email"
                  secondary={user.email || 'Not provided'}
                />
              </ListItem>
              <Divider />
              <ListItem>
                <ListItemText
                  primary="First Name"
                  secondary={user.first_name || 'Not provided'}
                />
              </ListItem>
              <Divider />
              <ListItem>
                <ListItemText
                  primary="Last Name"
                  secondary={user.last_name || 'Not provided'}
                />
              </ListItem>
              <Divider />
              <ListItem>
                <ListItemText
                  primary="User ID"
                  secondary={user.id}
                />
              </ListItem>
            </List>
          </Paper>
        </Grid>

        {/* Activity Summary */}
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Activity Summary
            </Typography>
            <Grid container spacing={3}>
              <Grid item xs={12} sm={6} md={3}>
                <Box textAlign="center">
                  <Typography variant="h4" color="primary">
                    0
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Jobs Submitted
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box textAlign="center">
                  <Typography variant="h4" color="success.main">
                    0
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Completed Jobs
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box textAlign="center">
                  <Typography variant="h4" color="warning.main">
                    0
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Running Jobs
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box textAlign="center">
                  <Typography variant="h4" color="error.main">
                    0
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Failed Jobs
                  </Typography>
                </Box>
              </Grid>
            </Grid>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Profile; 