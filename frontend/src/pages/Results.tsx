import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Chip,
  Alert,
  Grid,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  Tooltip,
  CircularProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Stack,
} from '@mui/material';
import {
  Download,
  FilterList,
  Search,
  Storage,
  Info,
  Error,
  FileDownload,
  Refresh,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { useApi, ResultFile } from '../contexts/ApiContext';

const Results: React.FC = () => {
  const { api, formatFileSize } = useApi();
  
  const [files, setFiles] = useState<ResultFile[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // Filters
  const [searchTerm, setSearchTerm] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [showFilters, setShowFilters] = useState(false);

  useEffect(() => {
    loadFiles();
  }, []);

  const loadFiles = async () => {
    try {
      setLoading(true);
      const response = await api.get('/result-files/');
      // Ensure response.data is an array
      const filesData = Array.isArray(response.data) ? response.data : [];
      setFiles(filesData);
    } catch (err) {
      setError('Failed to load result files');
      console.error('Error loading files:', err);
      setFiles([]); // Set empty array on error
    } finally {
      setLoading(false);
    }
  };

  const handleDownload = async (file: ResultFile) => {
    try {
      const response = await api.get(`/result-files/${file.id}/download/`);
      
      if (response.data.download_url) {
        // Open external download URL
        window.open(response.data.download_url, '_blank');
      }
    } catch (err) {
      console.error('Error downloading file:', err);
    }
  };

  const getFileTypeIcon = (fileType: string) => {
    switch (fileType) {
      case 'input':
        return <FileDownload color="action" />;
      case 'result':
        return <Storage color="primary" />;
      default:
        return <FileDownload />;
    }
  };

  const getFileTypeColor = (fileType: string) => {
    switch (fileType) {
      case 'input':
        return 'default';
      case 'result':
        return 'primary';
      default:
        return 'default';
    }
  };

  // Filter files based on search and type
  const filteredFiles = files && Array.isArray(files) ? files.filter(file => {
    const matchesSearch = !searchTerm ||
      file.name.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesType = !typeFilter || file.type === typeFilter;

    return matchesSearch && matchesType;
  }) : [];

  const fileTypes = files && Array.isArray(files) ? [...new Set(files.map(file => file.type))] : [];

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">
          Result Files
        </Typography>
        <Stack direction="row" spacing={2}>
          <Button
            variant="outlined"
            startIcon={<FilterList />}
            onClick={() => setShowFilters(!showFilters)}
          >
            {showFilters ? 'Hide' : 'Show'} Filters
          </Button>
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={loadFiles}
          >
            Refresh
          </Button>
        </Stack>
      </Box>

      {/* Filters */}
      {showFilters && (
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Search files"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  InputProps={{
                    startAdornment: <Search sx={{ mr: 1, color: 'text.secondary' }} />,
                  }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>File Type</InputLabel>
                  <Select
                    value={typeFilter}
                    label="File Type"
                    onChange={(e) => setTypeFilter(e.target.value)}
                  >
                    <MenuItem value="">All Types</MenuItem>
                    {fileTypes.map((type) => (
                      <MenuItem key={type} value={type}>
                        {type.replace('_', ' ').toUpperCase()}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      )}

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {/* Results Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>File Name</TableCell>
              <TableCell>Job</TableCell>
              <TableCell>Type</TableCell>
              <TableCell>Size</TableCell>
              <TableCell>Created</TableCell>
              <TableCell>Status</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredFiles.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                  <Typography variant="body1" color="text.secondary">
                    {files.length === 0 ? 
                      'No result files found. Complete some jobs to see results here.' :
                      'No files match your search criteria.'
                    }
                  </Typography>
                </TableCell>
              </TableRow>
            ) : (
              filteredFiles.map((file) => (
                <TableRow key={file.id} hover>
                  <TableCell>
                    <Box display="flex" alignItems="center">
                      {getFileTypeIcon(file.type)}
                      <Typography variant="body2" ml={1}>
                        {file.name}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      File #{file.id}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={file.type.toUpperCase()}
                      size="small"
                      color={getFileTypeColor(file.type) as any}
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {formatFileSize(file.size)}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="caption">
                      {format(new Date(file.created_at), 'MMM dd, yyyy HH:mm')}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={file.type === 'result' ? 'Available' : 'Input File'}
                      size="small"
                      color={file.type === 'result' ? 'success' : 'default'}
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell align="right">
                    <Tooltip title="Download">
                      <IconButton
                        size="small"
                        onClick={() => handleDownload(file)}
                        disabled={file.type === 'input'}
                      >
                        <Download />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Summary */}
      {files.length > 0 && (
        <Card sx={{ mt: 3 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Summary
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6} md={3}>
                <Paper sx={{ p: 2, textAlign: 'center' }}>
                  <Typography variant="h6">
                    {files && Array.isArray(files) ? files.length : 0}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Files
                  </Typography>
                </Paper>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Paper sx={{ p: 2, textAlign: 'center' }}>
                  <Typography variant="h6">
                    {files && Array.isArray(files) ? files.filter(f => f.type === 'result').length : 0}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Result Files
                  </Typography>
                </Paper>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Paper sx={{ p: 2, textAlign: 'center' }}>
                  <Typography variant="h6">
                    {files && Array.isArray(files) ? files.filter(f => f.type === 'input').length : 0}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Input Files
                  </Typography>
                </Paper>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Paper sx={{ p: 2, textAlign: 'center' }}>
                  <Typography variant="h6">
                    {files && Array.isArray(files) ? files.length : 0}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Quality Reports
                  </Typography>
                </Paper>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      )}
    </Box>
  );
};

export default Results; 