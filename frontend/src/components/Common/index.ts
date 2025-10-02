/**
 * Common UI Component Library
 *
 * Centralized exports for all reusable components, hooks, and utilities.
 * Import from this file to access the component library:
 *
 * @example
 * import { LoadingSpinner, useNotifications, SkipLink } from 'components/Common';
 */

// Loading Components
export {
  LoadingSpinner,
  DashboardStatsSkeleton,
  ChartSkeleton,
  TableSkeleton,
  ServiceCardSkeleton,
  JobListSkeleton,
  ProgressLoading,
  FadeLoading,
  SkeletonGrid,
  useLoadingState,
} from './LoadingComponents';

// Notification System
export {
  NotificationProvider,
  useNotifications,
  useNotificationHelpers,
  type NotificationType,
  type Notification,
} from './NotificationSystem';

// Accessibility Helpers
export {
  SkipToMainContent,
  ScreenReaderOnly,
  KeyboardNavigation,
  AccessibleButton,
  AccessibleIconButton,
  LiveRegion,
  AccessibleField,
  useFocusTrap,
  useFocusManagement,
  AccessibilityStatus,
} from './AccessibilityHelpers';
