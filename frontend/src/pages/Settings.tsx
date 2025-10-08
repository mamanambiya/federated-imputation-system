import React, { useState, useEffect } from 'react';
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
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Chip,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
} from '@mui/material';
import {
  Notifications,
  Security,
  Language,
  DarkMode,
  Save,
  VpnKey,
  Delete,
  Warning,
  CheckCircle,
} from '@mui/icons-material';
import {
  isTokenStorageEnabled,
  setTokenStorageEnabled,
  getAllStoredTokens,
  removeServiceToken,
  clearAllTokens,
  getDaysUntilExpiration,
} from '../utils/tokenStorage';
import ServiceCredentials from '../components/ServiceCredentials';

const Settings: React.FC = () => {
  const [emailNotifications, setEmailNotifications] = useState(true);
  const [darkMode, setDarkMode] = useState(false);
  const [language, setLanguage] = useState('en');
  const [saved, setSaved] = useState(false);

  // Token storage settings
  const [tokenStorageEnabled, setTokenStorageEnabledState] = useState(false);
  const [storedTokens, setStoredTokens] = useState<Array<any>>([]);
  const [confirmDialog, setConfirmDialog] = useState<{
    open: boolean;
    action: 'disable' | 'delete' | 'clearAll' | null;
    serviceId?: number;
    serviceName?: string;
  }>({ open: false, action: null });

  // Load settings on mount
  useEffect(() => {
    setTokenStorageEnabledState(isTokenStorageEnabled());
    loadStoredTokens();
  }, []);

  const loadStoredTokens = () => {
    const tokens = getAllStoredTokens();
    setStoredTokens(tokens);
  };

  const handleTokenStorageToggle = (enabled: boolean) => {
    if (!enabled) {
      // Show confirmation dialog before disabling
      setConfirmDialog({
        open: true,
        action: 'disable'
      });
    } else {
      setTokenStorageEnabled(enabled);
      setTokenStorageEnabledState(enabled);
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    }
  };

  const handleDeleteToken = (serviceId: number, serviceName: string) => {
    setConfirmDialog({
      open: true,
      action: 'delete',
      serviceId,
      serviceName
    });
  };

  const handleClearAllTokens = () => {
    setConfirmDialog({
      open: true,
      action: 'clearAll'
    });
  };

  const handleConfirmAction = () => {
    const { action, serviceId } = confirmDialog;

    if (action === 'disable') {
      setTokenStorageEnabled(false);
      setTokenStorageEnabledState(false);
      setStoredTokens([]);
    } else if (action === 'delete' && serviceId !== undefined) {
      removeServiceToken(serviceId);
      loadStoredTokens();
    } else if (action === 'clearAll') {
      clearAllTokens();
      setStoredTokens([]);
    }

    setConfirmDialog({ open: false, action: null });
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  const handleCancelAction = () => {
    setConfirmDialog({ open: false, action: null });
  };

  const handleSave = () => {
    // TODO: Implement save functionality for other settings
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
                  primary="Remember Service Tokens"
                  secondary="Automatically save and reuse service authentication tokens for 30 days"
                />
                <ListItemSecondaryAction>
                  <Tooltip title={tokenStorageEnabled ? "Tokens will be saved" : "Tokens will not be saved"}>
                    <Switch
                      checked={tokenStorageEnabled}
                      onChange={(e) => handleTokenStorageToggle(e.target.checked)}
                      color="primary"
                    />
                  </Tooltip>
                </ListItemSecondaryAction>
              </ListItem>
              <Divider />
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

        {/* Saved Service Tokens */}
        {tokenStorageEnabled && storedTokens.length > 0 && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
                <Box display="flex" alignItems="center">
                  <VpnKey sx={{ mr: 1 }} />
                  <Typography variant="h6">Saved Service Tokens</Typography>
                </Box>
                <Button
                  variant="outlined"
                  color="error"
                  size="small"
                  startIcon={<Delete />}
                  onClick={handleClearAllTokens}
                >
                  Clear All
                </Button>
              </Box>
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Service</TableCell>
                      <TableCell>Saved Date</TableCell>
                      <TableCell>Expires In</TableCell>
                      <TableCell>Status</TableCell>
                      <TableCell align="right">Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {storedTokens.map((token) => {
                      const daysRemaining = getDaysUntilExpiration(token.serviceId);
                      const isExpiringSoon = daysRemaining !== null && daysRemaining <= 7;

                      return (
                        <TableRow key={token.serviceId}>
                          <TableCell>
                            <Typography variant="body2" fontWeight={500}>
                              {token.serviceName}
                            </Typography>
                          </TableCell>
                          <TableCell>
                            {new Date(token.storedAt).toLocaleDateString()}
                          </TableCell>
                          <TableCell>
                            {daysRemaining !== null ? `${daysRemaining} days` : 'N/A'}
                          </TableCell>
                          <TableCell>
                            {isExpiringSoon ? (
                              <Chip
                                label="Expiring Soon"
                                color="warning"
                                size="small"
                                icon={<Warning />}
                              />
                            ) : (
                              <Chip
                                label="Active"
                                color="success"
                                size="small"
                                icon={<CheckCircle />}
                              />
                            )}
                          </TableCell>
                          <TableCell align="right">
                            <Tooltip title="Delete this token">
                              <IconButton
                                size="small"
                                color="error"
                                onClick={() => handleDeleteToken(token.serviceId, token.serviceName)}
                              >
                                <Delete />
                              </IconButton>
                            </Tooltip>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              </TableContainer>
            </Paper>
          </Grid>
        )}

        {/* Service Credentials - Permanent Backend Storage */}
        <Grid item xs={12}>
          <ServiceCredentials />
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

      {/* Confirmation Dialog */}
      <Dialog
        open={confirmDialog.open}
        onClose={handleCancelAction}
      >
        <DialogTitle>
          {confirmDialog.action === 'disable' && 'Disable Token Storage?'}
          {confirmDialog.action === 'delete' && 'Delete Saved Token?'}
          {confirmDialog.action === 'clearAll' && 'Clear All Saved Tokens?'}
        </DialogTitle>
        <DialogContent>
          <DialogContentText>
            {confirmDialog.action === 'disable' && (
              'Disabling token storage will delete all currently saved service tokens. You will need to re-enter tokens when submitting jobs. Are you sure?'
            )}
            {confirmDialog.action === 'delete' && (
              `Are you sure you want to delete the saved token for "${confirmDialog.serviceName}"? You will need to re-enter it when submitting jobs for this service.`
            )}
            {confirmDialog.action === 'clearAll' && (
              'This will delete all saved service tokens. You will need to re-enter tokens when submitting jobs. Are you sure?'
            )}
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCancelAction} color="primary">
            Cancel
          </Button>
          <Button onClick={handleConfirmAction} color="error" variant="contained">
            {confirmDialog.action === 'disable' ? 'Disable & Delete' : 'Delete'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Settings; 