# Frontend Integration Guide - Results Link Display

**Date:** October 8, 2025
**Feature:** Display external result file links from H3Africa Imputation Server

## Overview

The backend now stores result file links instead of downloading files. The frontend needs to fetch and display these links so users can download results directly from the H3Africa server.

## Backend Implementation Status

✅ **Complete** - All backend components working:

1. **Results Link Extraction** - Celery worker extracts file metadata from Michigan API
2. **Link Storage** - File-manager stores URLs in database with `processing_status='external'`
3. **API Endpoint** - `/api/files/?job_id={id}&file_type=output` returns result files
4. **Response Model** - `FileInfoResponse` includes `file_path` field with external URLs

## API Endpoint Details

### Fetch Result Files for a Job

**Endpoint:** `GET /api/files/`

**Query Parameters:**
- `job_id` (required) - Job UUID
- `file_type` (optional) - Filter by type, use `"output"` for results
- `limit` (optional) - Max results, default 100

**Headers:**
- `Authorization: Bearer {JWT_TOKEN}` (required)

**Example Request:**
```javascript
const response = await fetch(
  `/api/files/?job_id=${jobId}&file_type=output`,
  {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  }
);
const resultFiles = await response.json();
```

### Response Format

```json
[
  {
    "id": 15,
    "uuid": "abc-123-def",
    "filename": "chr_20.zip",
    "original_filename": "chr_20.zip",
    "file_path": "https://impute.afrigen-d.org/results/job-20251008-231358-409/job-20251008-231358-409/output/chr_20.zip",
    "file_size": 53477376,
    "file_type": "output",
    "mime_type": "application/octet-stream",
    "user_id": 1,
    "job_id": "1fcdeadb-0600-4c34-9390-07e10d43684b",
    "is_public": false,
    "is_available": true,
    "is_processed": true,
    "processing_status": "external",
    "expires_at": null,
    "created_at": "2025-10-08T23:19:31.510193",
    "updated_at": "2025-10-08T23:19:31.510195",
    "accessed_at": null
  },
  {
    "filename": "qc_report.txt",
    "file_path": "https://impute.afrigen-d.org/results/job-20251008-231358-409/job-20251008-231358-409/output/qc_report.txt",
    "file_size": 753,
    "processing_status": "external",
    ...
  }
]
```

### Key Fields

- **`filename`** - Display name for the file
- **`file_path`** - Full external download URL (use this as href)
- **`file_size`** - Size in bytes (format for display)
- **`processing_status`** - Will be `"external"` for result files
- **`file_type`** - Will be `"output"` for results, `"input"` for uploaded files

## Frontend Implementation Steps

### 1. Add Result Files State

In your Job Details component:

```typescript
const [resultFiles, setResultFiles] = useState<ResultFile[]>([]);
const [loadingResults, setLoadingResults] = useState(false);

interface ResultFile {
  id: number;
  filename: string;
  file_path: string;  // External URL
  file_size: number;
  processing_status: string;
  created_at: string;
}
```

### 2. Fetch Result Files

Add function to fetch result files:

```typescript
const loadResultFiles = async (jobId: string) => {
  if (!jobId) return;

  setLoadingResults(true);
  try {
    const response = await fetch(
      `/api/files/?job_id=${jobId}&file_type=output`,
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      }
    );

    if (response.ok) {
      const files = await response.json();
      // Filter for external files only
      const externalFiles = files.filter(
        f => f.processing_status === 'external'
      );
      setResultFiles(externalFiles);
    }
  } catch (error) {
    console.error('Failed to load result files:', error);
  } finally {
    setLoadingResults(false);
  }
};
```

### 3. Call on Job Completion

Add to your `useEffect` that watches job status:

```typescript
useEffect(() => {
  if (job && job.status === 'completed') {
    loadResultFiles(job.id);
  }
}, [job?.status, job?.id]);
```

### 4. Display Results Section

Add to your Job Details UI:

```tsx
{job.status === 'completed' && (
  <Box mt={4}>
    <Typography variant="h6" gutterBottom>
      Result Files
    </Typography>

    {loadingResults ? (
      <CircularProgress size={24} />
    ) : resultFiles.length > 0 ? (
      <List>
        {resultFiles.map((file) => (
          <ListItem key={file.id}>
            <ListItemIcon>
              <DescriptionIcon />
            </ListItemIcon>
            <ListItemText
              primary={file.filename}
              secondary={`${formatFileSize(file.file_size)} • ${new Date(file.created_at).toLocaleString()}`}
            />
            <ListItemSecondaryAction>
              <IconButton
                edge="end"
                component="a"
                href={file.file_path}
                download={file.filename}
                target="_blank"
                rel="noopener noreferrer"
              >
                <DownloadIcon />
              </IconButton>
            </ListItemSecondaryAction>
          </ListItem>
        ))}
      </List>
    ) : (
      <Typography color="textSecondary">
        No result files available
      </Typography>
    )}
  </Box>
)}
```

### 5. Helper Function for File Size

```typescript
const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
};
```

## Test Data

**Test Job ID:** `1fcdeadb-0600-4c34-9390-07e10d43684b`

This job has 9 result files stored as external links:
1. chr_20.zip (51 MB)
2. qc_report.txt (753 bytes)
3. quality-control.html (1 MB)
4. statistics/lift-over.txt (0 bytes)
5. statistics/snps-typed-only.txt (251 bytes)
6. step1-nextflow.log (25 KB)
7. step1-report.html (2 MB)
8. step1-timeline.html (247 KB)
9. step1-trace.csv (1 KB)

## Testing Checklist

- [ ] Fetch result files when job status is 'completed'
- [ ] Display list of result files with names and sizes
- [ ] Each file has download link that opens in new tab
- [ ] Files download correctly from H3Africa server
- [ ] Loading state shown while fetching files
- [ ] Empty state shown if no result files
- [ ] Error handling for failed API calls

## Important Notes

1. **External Downloads** - Files are NOT stored on our server. Users download directly from H3Africa at the provided URL.

2. **Link Expiration** - H3Africa links may expire. If users report broken links, the job may need to be re-run.

3. **Authentication** - The external URLs from H3Africa may require authentication. Users should already be logged into H3Africa or the links may include temporary tokens.

4. **File Types** - Always filter for `file_type='output'` to get only result files (not input files).

5. **Status Check** - Only show results section when `job.status === 'completed'`.

## Example API Response

```bash
curl -X GET "http://localhost:8000/api/files/?job_id=1fcdeadb-0600-4c34-9390-07e10d43684b&file_type=output" \
  -H "Authorization: Bearer {TOKEN}"
```

Returns 9 files with external URLs ready for display.

## Support

If you encounter issues:
1. Check browser console for API errors
2. Verify JWT token is valid
3. Confirm job status is 'completed'
4. Check that file_type parameter is 'output'
5. Verify file-manager service is running

---

**Status:** Backend Ready ✅
**Next Step:** Implement frontend UI to display result files
