# Common UI Component Library

A collection of reusable, accessible, and well-tested React components for the Federated Genomic Imputation Platform.

## Components Overview

### Loading Components

Comprehensive loading states for different UI scenarios.

#### LoadingSpinner
General-purpose loading spinner with optional full-screen backdrop.

```tsx
import { LoadingSpinner } from './Common/LoadingComponents';

// Basic usage
<LoadingSpinner />

// With message
<LoadingSpinner message="Loading data..." />

// Full screen
<LoadingSpinner fullScreen message="Processing..." />

// Custom size and color
<LoadingSpinner size={60} color="secondary" />
```

**Props:**
- `size?: number` - Spinner size in pixels (default: 40)
- `message?: string` - Optional loading message
- `fullScreen?: boolean` - Display as fullscreen overlay (default: false)
- `color?: 'primary' | 'secondary' | 'inherit'` - Color theme

**Accessibility:** Includes `role="status"` and `aria-label` for screen readers.

#### ProgressLoading
Progress indicator with percentage display.

```tsx
import { ProgressLoading } from './Common/LoadingComponents';

// Determinate progress
<ProgressLoading progress={75} message="Processing files..." />

// Indeterminate progress
<ProgressLoading indeterminate message="Loading..." />
```

**Props:**
- `progress?: number` - Progress value 0-100
- `message?: string` - Status message
- `indeterminate?: boolean` - Show indeterminate animation

#### Skeleton Components
Content placeholders for loading states.

```tsx
import {
  DashboardStatsSkeleton,
  ChartSkeleton,
  TableSkeleton,
  ServiceCardSkeleton,
  JobListSkeleton,
} from './Common/LoadingComponents';

// Dashboard statistics
<DashboardStatsSkeleton />

// Charts with custom height
<ChartSkeleton height={400} />

// Tables with custom dimensions
<TableSkeleton rows={10} columns={5} />

// Service cards
<ServiceCardSkeleton />

// Job listings
<JobListSkeleton count={5} />
```

#### FadeLoading
Wrapper that transitions between loading and loaded states.

```tsx
import { FadeLoading } from './Common/LoadingComponents';

<FadeLoading
  loading={isLoading}
  skeleton={<JobListSkeleton />}
  minHeight={300}
>
  <JobList data={jobs} />
</FadeLoading>
```

**Props:**
- `loading: boolean` - Loading state
- `children: ReactNode` - Content to show when loaded
- `skeleton?: ReactNode` - Custom skeleton (optional)
- `minHeight?: number` - Minimum height in pixels

#### SkeletonGrid
Flexible grid of skeleton items.

```tsx
import { SkeletonGrid, ServiceCardSkeleton } from './Common/LoadingComponents';

<SkeletonGrid
  count={6}
  columns={{ xs: 1, sm: 2, md: 3, lg: 4 }}
  renderSkeleton={() => <ServiceCardSkeleton />}
/>
```

**Props:**
- `count?: number` - Number of skeleton items (default: 6)
- `columns?: object` - Responsive column configuration
- `renderSkeleton: () => ReactNode` - Function to render each skeleton

### Hooks

#### useLoadingState
Comprehensive loading state management hook.

```tsx
import { useLoadingState } from './Common/LoadingComponents';

const { loading, error, startLoading, stopLoading, setLoadingError, reset } = useLoadingState();

// Start an async operation
startLoading();
try {
  await fetchData();
  stopLoading();
} catch (err) {
  setLoadingError('Failed to load data');
}

// Reset all state
reset();
```

**Returns:**
- `loading: boolean` - Current loading state
- `error: string | null` - Error message if any
- `startLoading: () => void` - Start loading and clear errors
- `stopLoading: () => void` - Stop loading
- `setLoadingError: (message: string) => void` - Set error and stop loading
- `reset: () => void` - Reset to initial state

### Notification System

Global notification/toast system with context-based state management.

#### Setup
Wrap your app with the NotificationProvider:

```tsx
import { NotificationProvider } from './Common/NotificationSystem';

<NotificationProvider maxNotifications={5}>
  <App />
</NotificationProvider>
```

#### Basic Usage

```tsx
import { useNotifications } from './Common/NotificationSystem';

const MyComponent = () => {
  const { showSuccess, showError, showWarning, showInfo } = useNotifications();

  const handleSave = async () => {
    try {
      await saveData();
      showSuccess('Data saved successfully');
    } catch (err) {
      showError('Failed to save data', 'Error');
    }
  };

  return <button onClick={handleSave}>Save</button>;
};
```

#### Notification Methods

```tsx
// Success notification (auto-dismisses after 6s)
showSuccess('Operation completed', 'Success Title');

// Error notification (persistent by default)
showError('Something went wrong', 'Error Title');

// Warning notification (8s duration)
showWarning('Please review your input', 'Warning');

// Info notification (6s duration)
showInfo('New feature available', 'Info');

// Custom notification
showNotification({
  type: 'success',
  title: 'Custom Title',
  message: 'Custom message',
  duration: 10000,
  persistent: false,
  action: {
    label: 'Undo',
    onClick: () => console.log('Undo clicked'),
  },
});
```

#### Notification Helpers

```tsx
import { useNotificationHelpers } from './Common/NotificationSystem';

const {
  notifyApiError,
  notifyLoadingError,
  notifyActionSuccess,
  notifyValidationError,
} = useNotificationHelpers();

// API error handling
try {
  await api.getData();
} catch (error) {
  notifyApiError(error); // Extracts error.response.data.message
}

// Loading error
notifyLoadingError('users'); // "Failed to load users..."

// Action success
notifyActionSuccess('Created', 'user'); // "Created user successfully"

// Validation error
notifyValidationError('Email is required');
```

#### Managing Notifications

```tsx
const { notifications, hideNotification, clearAll } = useNotifications();

// Manually dismiss a notification
hideNotification(notificationId);

// Clear all notifications
clearAll();

// Get current notifications
console.log(notifications); // Array of active notifications
```

#### Notification Configuration

```tsx
interface Notification {
  id: string;                    // Auto-generated
  type: 'success' | 'error' | 'warning' | 'info';
  title?: string;                // Optional title
  message: string;               // Required message
  duration?: number;             // Auto-dismiss duration (ms)
  persistent?: boolean;          // Prevent auto-dismiss
  action?: {                     // Optional action button
    label: string;
    onClick: () => void;
  };
}
```

**Default Durations:**
- Success: 6000ms (6 seconds)
- Error: Persistent (must be manually dismissed)
- Warning: 8000ms (8 seconds)
- Info: 6000ms (6 seconds)

**Accessibility Features:**
- ARIA live region (`aria-live="polite"`)
- Proper role attributes
- Keyboard accessible close buttons
- Screen reader announcements

### Accessibility Helpers

Comprehensive accessibility utilities and components.

```tsx
import {
  SkipLink,
  ScreenReaderOnly,
  FocusTrap,
  KeyboardNavigable,
  useA11yAnnouncement,
  useFocusManagement,
  useKeyboardShortcut,
} from './Common/AccessibilityHelpers';
```

*(See AccessibilityHelpers.tsx for detailed documentation)*

## Testing

All components include comprehensive unit and integration tests.

### Running Tests

```bash
# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Run specific test file
npm test -- LoadingComponents.test

# Watch mode
npm test -- --watch
```

### Test Coverage Goals

- **Statements:** > 90%
- **Branches:** > 85%
- **Functions:** > 90%
- **Lines:** > 90%

### Writing Tests

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { LoadingSpinner } from '../LoadingComponents';

it('renders with custom message', () => {
  render(<LoadingSpinner message="Loading..." />);
  expect(screen.getByText('Loading...')).toBeInTheDocument();
});
```

## Best Practices

### 1. Consistent Loading States
Use appropriate loading components for each context:
- **Data tables:** `TableSkeleton`
- **Cards:** `ServiceCardSkeleton` or `JobListSkeleton`
- **Charts:** `ChartSkeleton`
- **Full page:** `LoadingSpinner fullScreen`

### 2. Error Handling
Always provide clear error messages to users:
```tsx
const { startLoading, stopLoading, setLoadingError } = useLoadingState();
const { notifyError } = useNotificationHelpers();

try {
  startLoading();
  await fetchData();
  stopLoading();
} catch (error) {
  setLoadingError('Failed to load');
  notifyError('Please try again or contact support', 'Error');
}
```

### 3. Accessibility
- Always include ARIA labels for loading states
- Use semantic HTML elements
- Ensure keyboard navigation works
- Test with screen readers

### 4. Performance
- Use `React.memo()` for expensive components
- Implement proper key props in lists
- Avoid unnecessary re-renders

### 5. Consistent Notifications
- Success: For completed actions
- Error: For failures requiring attention
- Warning: For potential issues
- Info: For neutral information

## Contributing

### Adding New Components

1. Create component file in `src/components/Common/`
2. Add comprehensive tests in `src/__tests__/components/`
3. Update this README with documentation
4. Ensure >90% test coverage
5. Include accessibility features
6. Add TypeScript types

### Component Checklist

- [ ] TypeScript types defined
- [ ] Props documented with JSDoc
- [ ] Accessibility attributes included
- [ ] Responsive design implemented
- [ ] Tests written (>90% coverage)
- [ ] README documentation added
- [ ] Examples provided

## Component Roadmap

### Planned Components

- **DataTable**: Sortable, filterable data table with pagination
- **Modal**: Accessible modal dialog system
- **Form Controls**: Validated form inputs with error handling
- **FileUpload**: Drag-and-drop file upload component
- **SearchBar**: Debounced search with suggestions
- **Tabs**: Accessible tab navigation
- **Tooltip**: Context-sensitive help tooltips
- **Breadcrumbs**: Navigation breadcrumb trail

## Support

For issues or questions:
- Check existing tests for usage examples
- Review component props and types
- Consult accessibility documentation
- Open an issue on the project repository
