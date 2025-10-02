import React, { useEffect, useRef } from 'react';
import { Box, Typography, Button, IconButton, Tooltip } from '@mui/material';
import { Keyboard, AccessibilityNew } from '@mui/icons-material';

// Skip to main content link
export const SkipToMainContent: React.FC = () => (
  <Box
    component="a"
    href="#main-content"
    sx={{
      position: 'absolute',
      top: -40,
      left: 8,
      zIndex: 9999,
      backgroundColor: 'primary.main',
      color: 'primary.contrastText',
      padding: '8px 16px',
      textDecoration: 'none',
      borderRadius: 1,
      '&:focus': {
        top: 8,
      },
    }}
    onFocus={(e) => {
      e.currentTarget.style.top = '8px';
    }}
    onBlur={(e) => {
      e.currentTarget.style.top = '-40px';
    }}
  >
    Skip to main content
  </Box>
);

// Focus management hook
export const useFocusManagement = () => {
  const focusRef = useRef<HTMLElement | null>(null);

  const setFocus = (element: HTMLElement | null) => {
    if (element) {
      element.focus();
      focusRef.current = element;
    }
  };

  const restoreFocus = () => {
    if (focusRef.current) {
      focusRef.current.focus();
    }
  };

  return { setFocus, restoreFocus };
};

// Keyboard navigation helper
interface KeyboardNavigationProps {
  children: React.ReactNode;
  onEnter?: () => void;
  onSpace?: () => void;
  onEscape?: () => void;
  onArrowUp?: () => void;
  onArrowDown?: () => void;
  onArrowLeft?: () => void;
  onArrowRight?: () => void;
}

export const KeyboardNavigation: React.FC<KeyboardNavigationProps> = ({
  children,
  onEnter,
  onSpace,
  onEscape,
  onArrowUp,
  onArrowDown,
  onArrowLeft,
  onArrowRight,
}) => {
  const handleKeyDown = (event: React.KeyboardEvent) => {
    switch (event.key) {
      case 'Enter':
        if (onEnter) {
          event.preventDefault();
          onEnter();
        }
        break;
      case ' ':
        if (onSpace) {
          event.preventDefault();
          onSpace();
        }
        break;
      case 'Escape':
        if (onEscape) {
          event.preventDefault();
          onEscape();
        }
        break;
      case 'ArrowUp':
        if (onArrowUp) {
          event.preventDefault();
          onArrowUp();
        }
        break;
      case 'ArrowDown':
        if (onArrowDown) {
          event.preventDefault();
          onArrowDown();
        }
        break;
      case 'ArrowLeft':
        if (onArrowLeft) {
          event.preventDefault();
          onArrowLeft();
        }
        break;
      case 'ArrowRight':
        if (onArrowRight) {
          event.preventDefault();
          onArrowRight();
        }
        break;
    }
  };

  return (
    <Box onKeyDown={handleKeyDown} tabIndex={0}>
      {children}
    </Box>
  );
};

// Screen reader only text
interface ScreenReaderOnlyProps {
  children: React.ReactNode;
}

export const ScreenReaderOnly: React.FC<ScreenReaderOnlyProps> = ({ children }) => (
  <Box
    component="span"
    sx={{
      position: 'absolute',
      width: 1,
      height: 1,
      padding: 0,
      margin: -1,
      overflow: 'hidden',
      clip: 'rect(0, 0, 0, 0)',
      whiteSpace: 'nowrap',
      border: 0,
    }}
  >
    {children}
  </Box>
);

// Accessible button with proper ARIA attributes
interface AccessibleButtonProps {
  children: React.ReactNode;
  onClick: () => void;
  ariaLabel?: string;
  ariaDescribedBy?: string;
  disabled?: boolean;
  variant?: 'text' | 'outlined' | 'contained';
  size?: 'small' | 'medium' | 'large';
  loading?: boolean;
  icon?: React.ReactNode;
}

export const AccessibleButton: React.FC<AccessibleButtonProps> = ({
  children,
  onClick,
  ariaLabel,
  ariaDescribedBy,
  disabled = false,
  variant = 'contained',
  size = 'medium',
  loading = false,
  icon,
}) => (
  <Button
    variant={variant}
    size={size}
    onClick={onClick}
    disabled={disabled || loading}
    aria-label={ariaLabel}
    aria-describedby={ariaDescribedBy}
    aria-busy={loading}
    startIcon={icon}
    sx={{
      '&:focus-visible': {
        outline: '2px solid',
        outlineColor: 'primary.main',
        outlineOffset: 2,
      },
    }}
  >
    {children}
    {loading && <ScreenReaderOnly>Loading...</ScreenReaderOnly>}
  </Button>
);

// Accessible icon button
interface AccessibleIconButtonProps {
  children: React.ReactNode;
  onClick: () => void;
  ariaLabel: string;
  tooltip?: string;
  disabled?: boolean;
  size?: 'small' | 'medium' | 'large';
}

export const AccessibleIconButton: React.FC<AccessibleIconButtonProps> = ({
  children,
  onClick,
  ariaLabel,
  tooltip,
  disabled = false,
  size = 'medium',
}) => {
  const button = (
    <IconButton
      onClick={onClick}
      disabled={disabled}
      size={size}
      aria-label={ariaLabel}
      sx={{
        '&:focus-visible': {
          outline: '2px solid',
          outlineColor: 'primary.main',
          outlineOffset: 2,
        },
      }}
    >
      {children}
    </IconButton>
  );

  if (tooltip) {
    return (
      <Tooltip title={tooltip} arrow>
        {button}
      </Tooltip>
    );
  }

  return button;
};

// Live region for dynamic content announcements
interface LiveRegionProps {
  children: React.ReactNode;
  politeness?: 'polite' | 'assertive' | 'off';
  atomic?: boolean;
}

export const LiveRegion: React.FC<LiveRegionProps> = ({
  children,
  politeness = 'polite',
  atomic = false,
}) => (
  <Box
    role="status"
    aria-live={politeness}
    aria-atomic={atomic}
    sx={{
      position: 'absolute',
      width: 1,
      height: 1,
      padding: 0,
      margin: -1,
      overflow: 'hidden',
      clip: 'rect(0, 0, 0, 0)',
      whiteSpace: 'nowrap',
      border: 0,
    }}
  >
    {children}
  </Box>
);

// Accessible form field wrapper
interface AccessibleFieldProps {
  children: React.ReactNode;
  label: string;
  error?: string;
  helperText?: string;
  required?: boolean;
  id: string;
}

export const AccessibleField: React.FC<AccessibleFieldProps> = ({
  children,
  label,
  error,
  helperText,
  required = false,
  id,
}) => {
  const errorId = error ? `${id}-error` : undefined;
  const helperId = helperText ? `${id}-helper` : undefined;
  const describedBy = [errorId, helperId].filter(Boolean).join(' ') || undefined;

  return (
    <Box sx={{ mb: 2 }}>
      <Typography
        component="label"
        htmlFor={id}
        variant="body2"
        sx={{ display: 'block', mb: 1, fontWeight: 500 }}
      >
        {label}
        {required && (
          <Box component="span" sx={{ color: 'error.main', ml: 0.5 }}>
            *
            <ScreenReaderOnly>required</ScreenReaderOnly>
          </Box>
        )}
      </Typography>
      
      {React.cloneElement(children as React.ReactElement, {
        id,
        'aria-describedby': describedBy,
        'aria-invalid': !!error,
        'aria-required': required,
      })}
      
      {helperText && (
        <Typography
          id={helperId}
          variant="caption"
          sx={{ display: 'block', mt: 0.5, color: 'text.secondary' }}
        >
          {helperText}
        </Typography>
      )}
      
      {error && (
        <Typography
          id={errorId}
          variant="caption"
          sx={{ display: 'block', mt: 0.5, color: 'error.main' }}
          role="alert"
        >
          {error}
        </Typography>
      )}
    </Box>
  );
};

// Focus trap for modals and dialogs
export const useFocusTrap = (isActive: boolean) => {
  const containerRef = useRef<HTMLElement>(null);

  useEffect(() => {
    if (!isActive || !containerRef.current) return;

    const container = containerRef.current;
    const focusableElements = container.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    
    const firstElement = focusableElements[0] as HTMLElement;
    const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement;

    const handleTabKey = (e: KeyboardEvent) => {
      if (e.key !== 'Tab') return;

      if (e.shiftKey) {
        if (document.activeElement === firstElement) {
          e.preventDefault();
          lastElement?.focus();
        }
      } else {
        if (document.activeElement === lastElement) {
          e.preventDefault();
          firstElement?.focus();
        }
      }
    };

    container.addEventListener('keydown', handleTabKey);
    firstElement?.focus();

    return () => {
      container.removeEventListener('keydown', handleTabKey);
    };
  }, [isActive]);

  return containerRef;
};

// Accessibility status indicator
export const AccessibilityStatus: React.FC = () => {
  const [highContrast, setHighContrast] = React.useState(false);
  const [reducedMotion, setReducedMotion] = React.useState(false);

  useEffect(() => {
    // Check for user preferences
    const highContrastQuery = window.matchMedia('(prefers-contrast: high)');
    const reducedMotionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');

    setHighContrast(highContrastQuery.matches);
    setReducedMotion(reducedMotionQuery.matches);

    const handleHighContrastChange = (e: MediaQueryListEvent) => setHighContrast(e.matches);
    const handleReducedMotionChange = (e: MediaQueryListEvent) => setReducedMotion(e.matches);

    highContrastQuery.addEventListener('change', handleHighContrastChange);
    reducedMotionQuery.addEventListener('change', handleReducedMotionChange);

    return () => {
      highContrastQuery.removeEventListener('change', handleHighContrastChange);
      reducedMotionQuery.removeEventListener('change', handleReducedMotionChange);
    };
  }, []);

  return (
    <Box
      sx={{
        position: 'fixed',
        bottom: 16,
        right: 16,
        zIndex: 1000,
        display: 'flex',
        gap: 1,
      }}
    >
      {highContrast && (
        <Tooltip title="High contrast mode detected">
          <Box
            sx={{
              p: 1,
              backgroundColor: 'background.paper',
              borderRadius: 1,
              border: 1,
              borderColor: 'divider',
            }}
          >
            <AccessibilityNew fontSize="small" />
          </Box>
        </Tooltip>
      )}
      {reducedMotion && (
        <Tooltip title="Reduced motion preference detected">
          <Box
            sx={{
              p: 1,
              backgroundColor: 'background.paper',
              borderRadius: 1,
              border: 1,
              borderColor: 'divider',
            }}
          >
            <Keyboard fontSize="small" />
          </Box>
        </Tooltip>
      )}
    </Box>
  );
};
