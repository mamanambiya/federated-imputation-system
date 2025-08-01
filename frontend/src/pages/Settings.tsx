import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  Switch,
  Divider,
  Button,
  TextField,
  Grid,
  Alert,
} from '@mui/material';
import {
  Notifications,
  Security,
  Language,
  DarkMode,
  Save,
} from '@mui/icons-material';

const Settings: React.FC = () => {
  const [emailNotifications, setEmailNotifications] = useState(true);
  const [darkMode, setDarkMode] = useState(false);
  const [language, setLanguage] = useState('en');
  const [saved, setSaved] = useState(false);

  const handleSave = () => {
    // TODO: Implement save functionality
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        Settings
      </Typography>

      {saved && (
        <Alert severity="success" sx={{ mb: 3 }}>
          Settings saved successfully!
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Notifications */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Box display="flex" alignItems="center" mb={2}>
              <Notifications sx={{ mr: 1 }} />
              <Typography variant="h6">Notifications</Typography>
            </Box>
            <List>
              <ListItem>
                <ListItemText
                  primary="Email Notifications"
                  secondary="Receive email updates about your jobs"
                />
                <ListItemSecondaryAction>
                  <Switch
                    checked={emailNotifications}
                    onChange={(e) => setEmailNotifications(e.target.checked)}
                  />
                </ListItemSecondaryAction>
              </ListItem>
              <Divider />
              <ListItem>
                <ListItemText
                  primary="Job Completion Alerts"
                  secondary="Get notified when jobs complete"
                />
                <ListItemSecondaryAction>
                  <Switch defaultChecked />
                </ListItemSecondaryAction>
              </ListItem>
              <Divider />
              <ListItem>
                <ListItemText
                  primary="Job Failure Alerts"
                  secondary="Get notified when jobs fail"
                />
                <ListItemSecondaryAction>
                  <Switch defaultChecked />
                </ListItemSecondaryAction>
              </ListItem>
            </List>
          </Paper>
        </Grid>

        {/* Appearance */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Box display="flex" alignItems="center" mb={2}>
              <DarkMode sx={{ mr: 1 }} />
              <Typography variant="h6">Appearance</Typography>
            </Box>
            <List>
              <ListItem>
                <ListItemText
                  primary="Dark Mode"
                  secondary="Use dark theme (coming soon)"
                />
                <ListItemSecondaryAction>
                  <Switch
                    checked={darkMode}
                    onChange={(e) => setDarkMode(e.target.checked)}
                    disabled
                  />
                </ListItemSecondaryAction>
              </ListItem>
              <Divider />
              <ListItem>
                <ListItemText
                  primary="Compact View"
                  secondary="Show more items per page"
                />
                <ListItemSecondaryAction>
                  <Switch disabled />
                </ListItemSecondaryAction>
              </ListItem>
            </List>
          </Paper>
        </Grid>

        {/* Security */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Box display="flex" alignItems="center" mb={2}>
              <Security sx={{ mr: 1 }} />
              <Typography variant="h6">Security</Typography>
            </Box>
            <List>
              <ListItem>
                <ListItemText
                  primary="Two-Factor Authentication"
                  secondary="Add an extra layer of security (coming soon)"
                />
                <ListItemSecondaryAction>
                  <Switch disabled />
                </ListItemSecondaryAction>
              </ListItem>
              <Divider />
              <ListItem>
                <Button variant="outlined" fullWidth disabled>
                  Change Password
                </Button>
              </ListItem>
            </List>
          </Paper>
        </Grid>

        {/* Preferences */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Box display="flex" alignItems="center" mb={2}>
              <Language sx={{ mr: 1 }} />
              <Typography variant="h6">Preferences</Typography>
            </Box>
            <TextField
              fullWidth
              select
              label="Language"
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
              SelectProps={{
                native: true,
              }}
              sx={{ mb: 2 }}
            >
              <option value="en">English</option>
              <option value="fr">French (coming soon)</option>
              <option value="es">Spanish (coming soon)</option>
            </TextField>
            <TextField
              fullWidth
              select
              label="Timezone"
              defaultValue="UTC"
              SelectProps={{
                native: true,
              }}
              disabled
            >
              <option value="UTC">UTC</option>
            </TextField>
          </Paper>
        </Grid>

        {/* Save Button */}
        <Grid item xs={12}>
          <Box display="flex" justifyContent="flex-end">
            <Button
              variant="contained"
              startIcon={<Save />}
              onClick={handleSave}
              size="large"
            >
              Save Settings
            </Button>
          </Box>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Settings; 