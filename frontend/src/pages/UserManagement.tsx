import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Checkbox,
  FormControlLabel,
  Snackbar,
  Alert,
  IconButton,
  Tooltip,
  Tabs,
  Tab,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  ListItemSecondaryAction,
  Switch,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Backdrop,
  CircularProgress,
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  Person,
  Group,
  Security,
  Visibility,
  ExpandMore,
  Refresh,
  AdminPanelSettings,
  SupervisedUserCircle,
  Assignment,
  Lock,
  LockOpen,
  History,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { useApi } from '../contexts/ApiContext';

// Type definitions
interface UserRole {
  id: number;
  name: string;
  description: string;
  permissions: string[];
}

interface User {
  id: number;
  username: string;
  email: string;
  first_name: string;
  last_name: string;
  is_active: boolean;
  is_staff: boolean;
  is_superuser: boolean;
  date_joined: string;
  last_login: string | null;
}

interface UserProfile {
  id: number;
  user: User;
  role: UserRole;
  bio: string;
  phone_number: string;
  organization: string;
  created_at: string;
  updated_at: string;
}

interface AuditLog {
  id: number;
  user: User;
  action: string;
  resource_type: string;
  resource_id: string;
  details: Record<string, any>;
  timestamp: string;
  ip_address: string;
  user_agent: string;
}

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`user-mgmt-tabpanel-${index}`}
      aria-labelledby={`user-mgmt-tab-${index}`}
      {...other}
    >
      {value === index && (
        <Box sx={{ p: 3 }}>
          {children}
        </Box>
      )}
    </div>
  );
}

const UserManagement: React.FC = () => {
  const { apiCall } = useApi();
  
  // State for tabs
  const [tabValue, setTabValue] = useState(0);
  
  // State for data
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [roles, setRoles] = useState<UserRole[]>([]);
  const [auditLogs, setAuditLogs] = useState<AuditLog[]>([]);
  
  // State for loading and errors
  const [loading, setLoading] = useState(false);
  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'error' | 'warning' | 'info';
  }>({
    open: false,
    message: '',
    severity: 'info'
  });

  // State for dialogs
  const [userDialogOpen, setUserDialogOpen] = useState(false);
  const [roleDialogOpen, setRoleDialogOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null);
  const [selectedRole, setSelectedRole] = useState<UserRole | null>(null);
  
  // State for forms
  const [userForm, setUserForm] = useState({
    username: '',
    email: '',
    first_name: '',
    last_name: '',
    password: '',
    role_id: '',
    bio: '',
    phone_number: '',
    organization: '',
    is_active: true,
    is_staff: false,
    is_superuser: false
  });
  
  const [roleForm, setRoleForm] = useState({
    name: '',
    description: '',
    permissions: [] as string[]
  });

  // Available permissions (this should ideally come from the API)
  const availablePermissions = [
    'add_user', 'change_user', 'delete_user', 'view_user',
    'add_imputationservice', 'change_imputationservice', 'delete_imputationservice', 'view_imputationservice',
    'add_imputationjob', 'change_imputationjob', 'delete_imputationjob', 'view_imputationjob',
    'add_referencepanel', 'change_referencepanel', 'delete_referencepanel', 'view_referencepanel',
    'add_resultfile', 'change_resultfile', 'delete_resultfile', 'view_resultfile',
    'view_auditlog', 'add_servicepermission', 'change_servicepermission', 'delete_servicepermission', 'view_servicepermission'
  ];

  useEffect(() => {
    loadData();
  }, []);

  const showFeedback = (message: string, severity: 'success' | 'error' | 'warning' | 'info' = 'info') => {
    setSnackbar({ open: true, message, severity });
  };

  const loadData = async () => {
    setLoading(true);
    try {
      const [usersResponse, rolesResponse, auditResponse] = await Promise.all([
        apiCall('/api/profiles/'),
        apiCall('/api/roles/'),
        apiCall('/api/audit-logs/')
      ]);
      
      // Ensure we have arrays, handle paginated responses
      setUsers(Array.isArray(usersResponse) ? usersResponse : (usersResponse?.results || []));
      setRoles(Array.isArray(rolesResponse) ? rolesResponse : (rolesResponse?.results || []));
      setAuditLogs(Array.isArray(auditResponse) ? auditResponse : (auditResponse?.results || []));
      showFeedback('Data loaded successfully', 'success');
    } catch (error) {
      console.error('Error loading data:', error);
      // Set empty arrays on error to prevent map() errors
      setUsers([]);
      setRoles([]);
      setAuditLogs([]);
      showFeedback('Failed to load data. Please check your permissions.', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateUser = async () => {
    try {
      setLoading(true);
      const userData = {
        username: userForm.username,
        email: userForm.email,
        first_name: userForm.first_name,
        last_name: userForm.last_name,
        password: userForm.password,
        is_active: userForm.is_active,
        is_staff: userForm.is_staff,
        is_superuser: userForm.is_superuser
      };

      const user = await apiCall('/api/users/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(userData)
      });

      // Create profile
      const profileData = {
        user: user.id,
        role: parseInt(userForm.role_id),
        bio: userForm.bio,
        phone_number: userForm.phone_number,
        organization: userForm.organization
      };

      await apiCall('/api/profiles/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(profileData)
      });

      setUserDialogOpen(false);
      resetUserForm();
      loadData();
      showFeedback('User created successfully', 'success');
    } catch (error) {
      console.error('Error creating user:', error);
      showFeedback('Failed to create user', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateUser = async () => {
    if (!selectedUser) return;

    try {
      setLoading(true);
      const userData = {
        username: userForm.username,
        email: userForm.email,
        first_name: userForm.first_name,
        last_name: userForm.last_name,
        is_active: userForm.is_active,
        is_staff: userForm.is_staff,
        is_superuser: userForm.is_superuser
      };

      await apiCall(`/api/users/${selectedUser.user.id}/`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(userData)
      });

      // Update profile
      const profileData = {
        role: parseInt(userForm.role_id),
        bio: userForm.bio,
        phone_number: userForm.phone_number,
        organization: userForm.organization
      };

      await apiCall(`/api/profiles/${selectedUser.id}/`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(profileData)
      });

      setUserDialogOpen(false);
      setSelectedUser(null);
      resetUserForm();
      loadData();
      showFeedback('User updated successfully', 'success');
    } catch (error) {
      console.error('Error updating user:', error);
      showFeedback('Failed to update user', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteUser = async (userId: number) => {
    if (!window.confirm('Are you sure you want to delete this user?')) return;

    try {
      setLoading(true);
      await apiCall(`/api/users/${userId}/`, { method: 'DELETE' });
      loadData();
      showFeedback('User deleted successfully', 'success');
    } catch (error) {
      console.error('Error deleting user:', error);
      showFeedback('Failed to delete user', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleToggleUserActive = async (userId: number, isActive: boolean) => {
    try {
      await apiCall(`/api/users/${userId}/toggle_active/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ is_active: !isActive })
      });
      loadData();
      showFeedback(`User ${!isActive ? 'activated' : 'deactivated'} successfully`, 'success');
    } catch (error) {
      console.error('Error toggling user status:', error);
      showFeedback('Failed to update user status', 'error');
    }
  };

  const handleCreateRole = async () => {
    try {
      setLoading(true);
      await apiCall('/api/roles/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(roleForm)
      });

      setRoleDialogOpen(false);
      resetRoleForm();
      loadData();
      showFeedback('Role created successfully', 'success');
    } catch (error) {
      console.error('Error creating role:', error);
      showFeedback('Failed to create role', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateRole = async () => {
    if (!selectedRole) return;

    try {
      setLoading(true);
      await apiCall(`/api/roles/${selectedRole.id}/`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(roleForm)
      });

      setRoleDialogOpen(false);
      setSelectedRole(null);
      resetRoleForm();
      loadData();
      showFeedback('Role updated successfully', 'success');
    } catch (error) {
      console.error('Error updating role:', error);
      showFeedback('Failed to update role', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteRole = async (roleId: number) => {
    if (!window.confirm('Are you sure you want to delete this role?')) return;

    try {
      setLoading(true);
      await apiCall(`/api/roles/${roleId}/`, { method: 'DELETE' });
      loadData();
      showFeedback('Role deleted successfully', 'success');
    } catch (error) {
      console.error('Error deleting role:', error);
      showFeedback('Failed to delete role', 'error');
    } finally {
      setLoading(false);
    }
  };

  const resetUserForm = () => {
    setUserForm({
      username: '',
      email: '',
      first_name: '',
      last_name: '',
      password: '',
      role_id: '',
      bio: '',
      phone_number: '',
      organization: '',
      is_active: true,
      is_staff: false,
      is_superuser: false
    });
  };

  const resetRoleForm = () => {
    setRoleForm({
      name: '',
      description: '',
      permissions: []
    });
  };

  const openUserDialog = (user?: UserProfile) => {
    if (user) {
      setSelectedUser(user);
      setUserForm({
        username: user.user.username,
        email: user.user.email,
        first_name: user.user.first_name,
        last_name: user.user.last_name,
        password: '',
        role_id: user.role.id.toString(),
        bio: user.bio,
        phone_number: user.phone_number,
        organization: user.organization,
        is_active: user.user.is_active,
        is_staff: user.user.is_staff,
        is_superuser: user.user.is_superuser
      });
    } else {
      setSelectedUser(null);
      resetUserForm();
    }
    setUserDialogOpen(true);
  };

  const openRoleDialog = (role?: UserRole) => {
    if (role) {
      setSelectedRole(role);
      setRoleForm({
        name: role.name,
        description: role.description,
        permissions: role.permissions
      });
    } else {
      setSelectedRole(null);
      resetRoleForm();
    }
    setRoleDialogOpen(true);
  };

  const getRoleChipColor = (roleName: string) => {
    switch (roleName.toLowerCase()) {
      case 'admin': return 'error';
      case 'service_admin': return 'warning';
      case 'researcher': return 'primary';
      case 'service_user': return 'secondary';
      case 'viewer': return 'default';
      default: return 'default';
    }
  };

  const getActionIcon = (action: string) => {
    switch (action.toLowerCase()) {
      case 'create': return <Add />;
      case 'update': return <Edit />;
      case 'delete': return <Delete />;
      case 'login': return <Lock />;
      case 'logout': return <LockOpen />;
      default: return <Assignment />;
    }
  };

  return (
    <Box sx={{ flexGrow: 1, p: 3 }}>
      <Typography variant="h4" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
        <AdminPanelSettings color="primary" />
        User Management
        <Button
          variant="outlined"
          startIcon={<Refresh />}
          onClick={loadData}
          disabled={loading}
        >
          Refresh
        </Button>
      </Typography>

      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs value={tabValue} onChange={(_, newValue) => setTabValue(newValue)}>
          <Tab icon={<Person />} label="Users" />
          <Tab icon={<Group />} label="Roles" />
          <Tab icon={<History />} label="Audit Logs" />
        </Tabs>
      </Box>

      {/* Users Tab */}
      <TabPanel value={tabValue} index={0}>
        <Box sx={{ mb: 2, display: 'flex', justifyContent: 'space-between' }}>
          <Typography variant="h6" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <SupervisedUserCircle />
            Users ({users.length})
          </Typography>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => openUserDialog()}
          >
            Add User
          </Button>
        </Box>

        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Username</TableCell>
                <TableCell>Name</TableCell>
                <TableCell>Email</TableCell>
                <TableCell>Role</TableCell>
                <TableCell>Organization</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Last Login</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {users && users.length > 0 ? users.map((userProfile) => (
                <TableRow key={userProfile.id}>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      {userProfile.user.username}
                      {userProfile.user.is_superuser && (
                        <Chip label="Admin" size="small" color="error" />
                      )}
                      {userProfile.user.is_staff && (
                        <Chip label="Staff" size="small" color="warning" />
                      )}
                    </Box>
                  </TableCell>
                  <TableCell>
                    {userProfile.user.first_name} {userProfile.user.last_name}
                  </TableCell>
                  <TableCell>{userProfile.user.email}</TableCell>
                  <TableCell>
                    <Chip
                      label={userProfile.role.name}
                      color={getRoleChipColor(userProfile.role.name)}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>{userProfile.organization}</TableCell>
                  <TableCell>
                    <Switch
                      checked={userProfile.user.is_active}
                      onChange={() => handleToggleUserActive(userProfile.user.id, userProfile.user.is_active)}
                      color="primary"
                    />
                  </TableCell>
                  <TableCell>
                    {userProfile.user.last_login
                      ? format(new Date(userProfile.user.last_login), 'MMM dd, yyyy HH:mm')
                      : 'Never'
                    }
                  </TableCell>
                  <TableCell>
                    <Tooltip title="Edit User">
                      <IconButton onClick={() => openUserDialog(userProfile)}>
                        <Edit />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Delete User">
                      <IconButton
                        onClick={() => handleDeleteUser(userProfile.user.id)}
                        color="error"
                      >
                        <Delete />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              )) : (
                <TableRow>
                  <TableCell colSpan={8} align="center">
                    <Typography variant="body2" color="text.secondary">
                      No users found. {loading ? 'Loading...' : 'Please check your permissions or contact an administrator.'}
                    </Typography>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>
      </TabPanel>

      {/* Roles Tab */}
      <TabPanel value={tabValue} index={1}>
        <Box sx={{ mb: 2, display: 'flex', justifyContent: 'space-between' }}>
          <Typography variant="h6" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Security />
            Roles ({roles.length})
          </Typography>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => openRoleDialog()}
          >
            Add Role
          </Button>
        </Box>

        <Grid container spacing={3}>
          {roles && roles.length > 0 ? roles.map((role) => (
            <Grid item xs={12} md={6} lg={4} key={role.id}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    <Chip
                      label={role.name}
                      color={getRoleChipColor(role.name)}
                      sx={{ mr: 1 }}
                    />
                  </Typography>
                  <Typography variant="body2" color="text.secondary" gutterBottom>
                    {role.description}
                  </Typography>
                  <Typography variant="subtitle2" sx={{ mt: 2, mb: 1 }}>
                    Permissions ({role.permissions.length}):
                  </Typography>
                  <Box sx={{ maxHeight: 150, overflow: 'auto' }}>
                    {role.permissions.map((permission, index) => (
                      <Chip
                        key={index}
                        label={permission}
                        size="small"
                        variant="outlined"
                        sx={{ m: 0.5 }}
                      />
                    ))}
                  </Box>
                  <Box sx={{ mt: 2, display: 'flex', gap: 1 }}>
                    <Button
                      size="small"
                      startIcon={<Edit />}
                      onClick={() => openRoleDialog(role)}
                    >
                      Edit
                    </Button>
                    <Button
                      size="small"
                      startIcon={<Delete />}
                      color="error"
                      onClick={() => handleDeleteRole(role.id)}
                    >
                      Delete
                    </Button>
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          )) : (
            <Grid item xs={12}>
              <Card>
                <CardContent>
                  <Typography variant="body2" color="text.secondary" align="center">
                    No roles found. {loading ? 'Loading...' : 'Please check your permissions or contact an administrator.'}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          )}
        </Grid>
      </TabPanel>

      {/* Audit Logs Tab */}
      <TabPanel value={tabValue} index={2}>
        <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <History />
          Audit Logs ({auditLogs.length})
        </Typography>

        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Timestamp</TableCell>
                <TableCell>User</TableCell>
                <TableCell>Action</TableCell>
                <TableCell>Resource</TableCell>
                <TableCell>IP Address</TableCell>
                <TableCell>Details</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {auditLogs && auditLogs.length > 0 ? auditLogs.slice(0, 100).map((log) => (
                <TableRow key={log.id}>
                  <TableCell>
                    {format(new Date(log.timestamp), 'MMM dd, yyyy HH:mm:ss')}
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Person fontSize="small" />
                      {log.user.username}
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      {getActionIcon(log.action)}
                      {log.action}
                    </Box>
                  </TableCell>
                  <TableCell>
                    {log.resource_type} {log.resource_id && `#${log.resource_id}`}
                  </TableCell>
                  <TableCell>{log.ip_address}</TableCell>
                  <TableCell>
                    <Tooltip title={JSON.stringify(log.details, null, 2)}>
                      <IconButton size="small">
                        <Visibility />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              )) : (
                <TableRow>
                  <TableCell colSpan={6} align="center">
                    <Typography variant="body2" color="text.secondary">
                      No audit logs found. {loading ? 'Loading...' : 'Please check your permissions or contact an administrator.'}
                    </Typography>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>
      </TabPanel>

      {/* User Dialog */}
      <Dialog open={userDialogOpen} onClose={() => setUserDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          {selectedUser ? 'Edit User' : 'Create New User'}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Username"
                value={userForm.username}
                onChange={(e) => setUserForm({ ...userForm, username: e.target.value })}
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Email"
                type="email"
                value={userForm.email}
                onChange={(e) => setUserForm({ ...userForm, email: e.target.value })}
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="First Name"
                value={userForm.first_name}
                onChange={(e) => setUserForm({ ...userForm, first_name: e.target.value })}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Last Name"
                value={userForm.last_name}
                onChange={(e) => setUserForm({ ...userForm, last_name: e.target.value })}
              />
            </Grid>
            {!selectedUser && (
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Password"
                  type="password"
                  value={userForm.password}
                  onChange={(e) => setUserForm({ ...userForm, password: e.target.value })}
                  required
                />
              </Grid>
            )}
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Role</InputLabel>
                <Select
                  value={userForm.role_id}
                  label="Role"
                  onChange={(e) => setUserForm({ ...userForm, role_id: e.target.value })}
                >
                  {roles && roles.length > 0 ? roles.map((role) => (
                    <MenuItem key={role.id} value={role.id.toString()}>
                      {role.name}
                    </MenuItem>
                  )) : (
                    <MenuItem value="" disabled>
                      No roles available
                    </MenuItem>
                  )}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Organization"
                value={userForm.organization}
                onChange={(e) => setUserForm({ ...userForm, organization: e.target.value })}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Phone Number"
                value={userForm.phone_number}
                onChange={(e) => setUserForm({ ...userForm, phone_number: e.target.value })}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Bio"
                multiline
                rows={3}
                value={userForm.bio}
                onChange={(e) => setUserForm({ ...userForm, bio: e.target.value })}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Checkbox
                    checked={userForm.is_active}
                    onChange={(e) => setUserForm({ ...userForm, is_active: e.target.checked })}
                  />
                }
                label="Active"
              />
              <FormControlLabel
                control={
                  <Checkbox
                    checked={userForm.is_staff}
                    onChange={(e) => setUserForm({ ...userForm, is_staff: e.target.checked })}
                  />
                }
                label="Staff"
              />
              <FormControlLabel
                control={
                  <Checkbox
                    checked={userForm.is_superuser}
                    onChange={(e) => setUserForm({ ...userForm, is_superuser: e.target.checked })}
                  />
                }
                label="Superuser"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setUserDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={selectedUser ? handleUpdateUser : handleCreateUser}
            variant="contained"
            disabled={loading}
          >
            {selectedUser ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Role Dialog */}
      <Dialog open={roleDialogOpen} onClose={() => setRoleDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          {selectedRole ? 'Edit Role' : 'Create New Role'}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Name"
                value={roleForm.name}
                onChange={(e) => setRoleForm({ ...roleForm, name: e.target.value })}
                required
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                multiline
                rows={3}
                value={roleForm.description}
                onChange={(e) => setRoleForm({ ...roleForm, description: e.target.value })}
              />
            </Grid>
            <Grid item xs={12}>
              <Typography variant="subtitle1" gutterBottom>
                Permissions
              </Typography>
              <Accordion>
                <AccordionSummary expandIcon={<ExpandMore />}>
                  <Typography>Select Permissions ({roleForm.permissions.length} selected)</Typography>
                </AccordionSummary>
                <AccordionDetails>
                  <Grid container>
                    {availablePermissions.map((permission) => (
                      <Grid item xs={12} sm={6} md={4} key={permission}>
                        <FormControlLabel
                          control={
                            <Checkbox
                              checked={roleForm.permissions.includes(permission)}
                              onChange={(e) => {
                                if (e.target.checked) {
                                  setRoleForm({
                                    ...roleForm,
                                    permissions: [...roleForm.permissions, permission]
                                  });
                                } else {
                                  setRoleForm({
                                    ...roleForm,
                                    permissions: roleForm.permissions.filter(p => p !== permission)
                                  });
                                }
                              }}
                            />
                          }
                          label={permission}
                        />
                      </Grid>
                    ))}
                  </Grid>
                </AccordionDetails>
              </Accordion>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRoleDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={selectedRole ? handleUpdateRole : handleCreateRole}
            variant="contained"
            disabled={loading}
          >
            {selectedRole ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Loading Backdrop */}
      <Backdrop open={loading} sx={{ color: '#fff', zIndex: (theme) => theme.zIndex.drawer + 1 }}>
        <CircularProgress color="inherit" />
      </Backdrop>

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
      >
        <Alert
          onClose={() => setSnackbar({ ...snackbar, open: false })}
          severity={snackbar.severity}
          sx={{ width: '100%' }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default UserManagement;