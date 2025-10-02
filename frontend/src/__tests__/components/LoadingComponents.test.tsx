import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import {
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
} from '../../components/Common/LoadingComponents';
import { renderHook, act } from '@testing-library/react';

describe('LoadingComponents', () => {
  describe('LoadingSpinner', () => {
    it('renders with default props', () => {
      render(<LoadingSpinner />);
      const spinner = screen.getByRole('status');
      expect(spinner).toBeInTheDocument();
      expect(spinner).toHaveAttribute('aria-label', 'Loading');
    });

    it('renders with custom message', () => {
      render(<LoadingSpinner message="Loading data..." />);
      expect(screen.getByText('Loading data...')).toBeInTheDocument();
      expect(screen.getByRole('status')).toHaveAttribute('aria-label', 'Loading data...');
    });

    it('renders in fullScreen mode', () => {
      const { container } = render(<LoadingSpinner fullScreen />);
      // Backdrop component should be present in fullScreen mode
      expect(container.querySelector('.MuiBackdrop-root')).toBeInTheDocument();
    });

    it('applies custom size', () => {
      render(<LoadingSpinner size={60} />);
      const progress = screen.getByRole('progressbar');
      expect(progress).toBeInTheDocument();
    });
  });

  describe('DashboardStatsSkeleton', () => {
    it('renders 4 skeleton cards', () => {
      const { container } = render(<DashboardStatsSkeleton />);
      const skeletons = container.querySelectorAll('.MuiSkeleton-root');
      // Each card has 3 skeletons (circular + 2 text), so 4 cards = 12 skeletons
      expect(skeletons.length).toBeGreaterThan(0);
    });

    it('renders in a grid layout', () => {
      const { container } = render(<DashboardStatsSkeleton />);
      const grid = container.querySelector('.MuiGrid-container');
      expect(grid).toBeInTheDocument();
    });
  });

  describe('ChartSkeleton', () => {
    it('renders with default height', () => {
      const { container } = render(<ChartSkeleton />);
      const rectangularSkeleton = container.querySelector('.MuiSkeleton-rectangular');
      expect(rectangularSkeleton).toBeInTheDocument();
    });

    it('renders with custom height', () => {
      const { container } = render(<ChartSkeleton height={400} />);
      const rectangularSkeleton = container.querySelector('.MuiSkeleton-rectangular');
      expect(rectangularSkeleton).toBeInTheDocument();
    });
  });

  describe('TableSkeleton', () => {
    it('renders with default rows and columns', () => {
      const { container } = render(<TableSkeleton />);
      const skeletons = container.querySelectorAll('.MuiSkeleton-text');
      // Default is 5 rows × 4 columns = 20 skeletons, plus title skeleton
      expect(skeletons.length).toBeGreaterThanOrEqual(20);
    });

    it('renders with custom rows and columns', () => {
      const { container } = render(<TableSkeleton rows={3} columns={2} />);
      const skeletons = container.querySelectorAll('.MuiSkeleton-text');
      // 3 rows × 2 columns = 6 skeletons, plus title skeleton
      expect(skeletons.length).toBeGreaterThanOrEqual(6);
    });
  });

  describe('ServiceCardSkeleton', () => {
    it('renders all skeleton elements', () => {
      const { container } = render(<ServiceCardSkeleton />);
      const circularSkeleton = container.querySelector('.MuiSkeleton-circular');
      const textSkeletons = container.querySelectorAll('.MuiSkeleton-text');
      const rectangularSkeleton = container.querySelector('.MuiSkeleton-rectangular');

      expect(circularSkeleton).toBeInTheDocument();
      expect(textSkeletons.length).toBeGreaterThan(0);
      expect(rectangularSkeleton).toBeInTheDocument();
    });
  });

  describe('JobListSkeleton', () => {
    it('renders default number of job cards', () => {
      const { container } = render(<JobListSkeleton />);
      const cards = container.querySelectorAll('.MuiCard-root');
      expect(cards.length).toBe(3); // Default count
    });

    it('renders custom number of job cards', () => {
      const { container } = render(<JobListSkeleton count={5} />);
      const cards = container.querySelectorAll('.MuiCard-root');
      expect(cards.length).toBe(5);
    });
  });

  describe('ProgressLoading', () => {
    it('renders indeterminate progress', () => {
      render(<ProgressLoading indeterminate />);
      const progress = screen.getByRole('progressbar');
      expect(progress).toBeInTheDocument();
    });

    it('renders determinate progress with value', () => {
      render(<ProgressLoading progress={50} />);
      expect(screen.getByText('50%')).toBeInTheDocument();
    });

    it('renders with custom message', () => {
      render(<ProgressLoading message="Processing..." progress={75} />);
      expect(screen.getByText('Processing...')).toBeInTheDocument();
      expect(screen.getByText('75%')).toBeInTheDocument();
    });

    it('does not show percentage when indeterminate', () => {
      render(<ProgressLoading indeterminate message="Loading..." />);
      expect(screen.getByText('Loading...')).toBeInTheDocument();
      expect(screen.queryByText('%')).not.toBeInTheDocument();
    });
  });

  describe('FadeLoading', () => {
    it('shows children when not loading', () => {
      render(
        <FadeLoading loading={false}>
          <div>Content loaded</div>
        </FadeLoading>
      );
      expect(screen.getByText('Content loaded')).toBeInTheDocument();
    });

    it('shows skeleton when loading', () => {
      render(
        <FadeLoading
          loading={true}
          skeleton={<div>Custom skeleton</div>}
        >
          <div>Content loaded</div>
        </FadeLoading>
      );
      expect(screen.getByText('Custom skeleton')).toBeInTheDocument();
    });

    it('shows default loading spinner when no skeleton provided', () => {
      render(
        <FadeLoading loading={true}>
          <div>Content loaded</div>
        </FadeLoading>
      );
      expect(screen.getByRole('status')).toBeInTheDocument();
    });
  });

  describe('SkeletonGrid', () => {
    it('renders correct number of skeleton items', () => {
      const { container } = render(
        <SkeletonGrid
          count={4}
          renderSkeleton={() => <div className="test-skeleton">Skeleton</div>}
        />
      );
      const skeletons = container.querySelectorAll('.test-skeleton');
      expect(skeletons.length).toBe(4);
    });

    it('renders with custom columns', () => {
      const { container } = render(
        <SkeletonGrid
          count={6}
          columns={{ xs: 1, sm: 2, md: 3, lg: 4 }}
          renderSkeleton={() => <div>Skeleton</div>}
        />
      );
      const gridItems = container.querySelectorAll('.MuiGrid-item');
      expect(gridItems.length).toBe(6);
    });
  });

  describe('useLoadingState hook', () => {
    it('initializes with default state', () => {
      const { result } = renderHook(() => useLoadingState());
      expect(result.current.loading).toBe(false);
      expect(result.current.error).toBe(null);
    });

    it('initializes with custom initial state', () => {
      const { result } = renderHook(() => useLoadingState(true));
      expect(result.current.loading).toBe(true);
    });

    it('starts loading', () => {
      const { result } = renderHook(() => useLoadingState());
      act(() => {
        result.current.startLoading();
      });
      expect(result.current.loading).toBe(true);
      expect(result.current.error).toBe(null);
    });

    it('stops loading', () => {
      const { result } = renderHook(() => useLoadingState(true));
      act(() => {
        result.current.stopLoading();
      });
      expect(result.current.loading).toBe(false);
    });

    it('sets loading error', () => {
      const { result } = renderHook(() => useLoadingState(true));
      act(() => {
        result.current.setLoadingError('An error occurred');
      });
      expect(result.current.loading).toBe(false);
      expect(result.current.error).toBe('An error occurred');
    });

    it('resets state', () => {
      const { result } = renderHook(() => useLoadingState(true));
      act(() => {
        result.current.setLoadingError('An error occurred');
      });
      act(() => {
        result.current.reset();
      });
      expect(result.current.loading).toBe(false);
      expect(result.current.error).toBe(null);
    });

    it('clears error when starting loading', () => {
      const { result } = renderHook(() => useLoadingState());
      act(() => {
        result.current.setLoadingError('An error occurred');
      });
      expect(result.current.error).toBe('An error occurred');
      act(() => {
        result.current.startLoading();
      });
      expect(result.current.error).toBe(null);
      expect(result.current.loading).toBe(true);
    });
  });
});
