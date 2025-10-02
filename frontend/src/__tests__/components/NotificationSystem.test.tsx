import React from 'react';
import { render, screen, waitFor, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import '@testing-library/jest-dom';
import {
  NotificationProvider,
  useNotifications,
  useNotificationHelpers,
} from '../../components/Common/NotificationSystem';

// Test component that uses the notification context
const TestComponent = () => {
  const {
    showSuccess,
    showError,
    showWarning,
    showInfo,
    clearAll,
    notifications,
  } = useNotifications();

  return (
    <div>
      <button onClick={() => showSuccess('Success message')}>
        Show Success
      </button>
      <button onClick={() => showError('Error message')}>
        Show Error
      </button>
      <button onClick={() => showWarning('Warning message')}>
        Show Warning
      </button>
      <button onClick={() => showInfo('Info message')}>
        Show Info
      </button>
      <button onClick={() => showSuccess('Custom', 'Custom Title', { persistent: true })}>
        Show Custom
      </button>
      <button onClick={clearAll}>Clear All</button>
      <div data-testid="notification-count">{notifications.length}</div>
    </div>
  );
};

// Test component for notification helpers
const TestHelpersComponent = () => {
  const {
    notifySuccess,
    notifyError,
    notifyApiError,
    notifyLoadingError,
    notifyActionSuccess,
    notifyValidationError,
  } = useNotificationHelpers();

  return (
    <div>
      <button onClick={() => notifySuccess('Success')}>Notify Success</button>
      <button onClick={() => notifyError('Error')}>Notify Error</button>
      <button onClick={() => notifyApiError({ message: 'API failed' })}>
        Notify API Error
      </button>
      <button onClick={() => notifyLoadingError('users')}>
        Notify Loading Error
      </button>
      <button onClick={() => notifyActionSuccess('Created', 'user')}>
        Notify Action Success
      </button>
      <button onClick={() => notifyValidationError('Invalid input')}>
        Notify Validation Error
      </button>
    </div>
  );
};

describe('NotificationSystem', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.runOnlyPendingTimers();
    jest.useRealTimers();
  });

  describe('NotificationProvider', () => {
    it('renders children', () => {
      render(
        <NotificationProvider>
          <div>Test Child</div>
        </NotificationProvider>
      );
      expect(screen.getByText('Test Child')).toBeInTheDocument();
    });

    it('throws error when useNotifications is used outside provider', () => {
      // Suppress console.error for this test
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

      const TestWithoutProvider = () => {
        useNotifications();
        return <div>Test</div>;
      };

      // The component will throw an error during render
      expect(() => render(<TestWithoutProvider />)).toThrow();

      consoleSpy.mockRestore();
    });
  });

  describe('Notification Display', () => {
    it('shows success notification', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Show Success'));

      expect(screen.getByText('Success message')).toBeInTheDocument();
      expect(screen.getByTestId('notification-count')).toHaveTextContent('1');
    });

    it('shows error notification', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Show Error'));

      expect(screen.getByText('Error message')).toBeInTheDocument();
    });

    it('shows warning notification', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Show Warning'));

      expect(screen.getByText('Warning message')).toBeInTheDocument();
    });

    it('shows info notification', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Show Info'));

      expect(screen.getByText('Info message')).toBeInTheDocument();
    });

    it('shows notification with custom title', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Show Custom'));

      expect(screen.getByText('Custom Title')).toBeInTheDocument();
      expect(screen.getByText('Custom')).toBeInTheDocument();
    });
  });

  describe('Notification Dismissal', () => {
    it('dismisses notification when close button is clicked', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Show Success'));
      expect(screen.getByText('Success message')).toBeInTheDocument();

      const closeButton = screen.getByLabelText('Close notification');
      await user.click(closeButton);

      await waitFor(() => {
        expect(screen.queryByText('Success message')).not.toBeInTheDocument();
      });
    });

    it('auto-dismisses non-persistent notifications', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Show Success'));
      expect(screen.getByText('Success message')).toBeInTheDocument();

      // Fast-forward time by 6 seconds (default duration)
      act(() => {
        jest.advanceTimersByTime(6000);
      });

      await waitFor(() => {
        expect(screen.queryByText('Success message')).not.toBeInTheDocument();
      });
    });

    it('does not auto-dismiss persistent notifications', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Show Custom')); // This creates a persistent notification

      // Fast-forward time well beyond default duration
      act(() => {
        jest.advanceTimersByTime(10000);
      });

      // Notification should still be visible
      expect(screen.getByText('Custom')).toBeInTheDocument();
    });

    it('clears all notifications', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Show Success'));
      await user.click(screen.getByText('Show Error'));
      await user.click(screen.getByText('Show Warning'));

      expect(screen.getByTestId('notification-count')).toHaveTextContent('3');

      await user.click(screen.getByText('Clear All'));

      expect(screen.getByTestId('notification-count')).toHaveTextContent('0');
    });
  });

  describe('Maximum Notifications', () => {
    it('limits number of notifications', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider maxNotifications={3}>
          <TestComponent />
        </NotificationProvider>
      );

      // Add more notifications than the limit
      await user.click(screen.getByText('Show Success'));
      await user.click(screen.getByText('Show Error'));
      await user.click(screen.getByText('Show Warning'));
      await user.click(screen.getByText('Show Info'));

      // Should only show 3 notifications (the limit)
      expect(screen.getByTestId('notification-count')).toHaveTextContent('3');
    });
  });

  describe('Notification Helpers', () => {
    it('notifySuccess works correctly', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestHelpersComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Notify Success'));
      expect(screen.getByText('Success')).toBeInTheDocument();
    });

    it('notifyApiError displays API error message', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestHelpersComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Notify API Error'));
      expect(screen.getByText('API Error')).toBeInTheDocument();
      expect(screen.getByText('API failed')).toBeInTheDocument();
    });

    it('notifyLoadingError displays resource-specific message', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestHelpersComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Notify Loading Error'));
      expect(screen.getByText('Loading Error')).toBeInTheDocument();
      expect(screen.getByText(/Failed to load users/)).toBeInTheDocument();
    });

    it('notifyActionSuccess displays success message', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestHelpersComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Notify Action Success'));
      expect(screen.getByText('Created user successfully')).toBeInTheDocument();
    });

    it('notifyValidationError displays validation warning', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestHelpersComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Notify Validation Error'));
      expect(screen.getByText('Validation Error')).toBeInTheDocument();
      expect(screen.getByText('Invalid input')).toBeInTheDocument();
    });
  });

  describe('Accessibility', () => {
    it('has proper ARIA attributes', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Show Success'));

      const notificationRegion = screen.getByRole('region', { name: 'Notifications' });
      expect(notificationRegion).toHaveAttribute('aria-live', 'polite');
    });

    it('close button has accessible label', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Show Success'));

      expect(screen.getByLabelText('Close notification')).toBeInTheDocument();
    });
  });

  describe('Error Notification Behavior', () => {
    it('error notifications are persistent by default', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Show Error'));

      // Fast-forward beyond normal auto-dismiss time
      act(() => {
        jest.advanceTimersByTime(10000);
      });

      // Error should still be visible
      expect(screen.getByText('Error message')).toBeInTheDocument();
    });
  });

  describe('Warning Notification Duration', () => {
    it('warnings have longer duration than default', async () => {
      const user = userEvent.setup({ delay: null });
      render(
        <NotificationProvider>
          <TestComponent />
        </NotificationProvider>
      );

      await user.click(screen.getByText('Show Warning'));

      // Default duration is 6000ms, warning is 8000ms
      act(() => {
        jest.advanceTimersByTime(6000);
      });

      // Should still be visible after default duration
      expect(screen.getByText('Warning message')).toBeInTheDocument();

      // Fast-forward remaining time
      act(() => {
        jest.advanceTimersByTime(2000);
      });

      // Should be gone after 8000ms
      await waitFor(() => {
        expect(screen.queryByText('Warning message')).not.toBeInTheDocument();
      });
    });
  });
});
