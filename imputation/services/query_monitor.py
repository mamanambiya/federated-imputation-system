"""
Database Query Performance Monitoring

Tracks and logs slow queries, provides performance insights, and helps identify optimization opportunities.
"""
import time
import logging
import functools
from typing import Callable, Any, Dict, List, Optional
from django.db import connection, reset_queries
from django.conf import settings
from datetime import datetime
from collections import defaultdict

logger = logging.getLogger(__name__)


class QueryPerformanceMonitor:
    """
    Monitor and analyze database query performance.

    Features:
    - Track query execution time
    - Identify N+1 query problems
    - Log slow queries
    - Collect performance statistics
    """

    # Thresholds
    SLOW_QUERY_THRESHOLD = 0.1  # 100ms
    WARNING_QUERY_THRESHOLD = 0.5  # 500ms
    CRITICAL_QUERY_THRESHOLD = 1.0  # 1 second

    def __init__(self):
        self.enabled = getattr(settings, 'QUERY_MONITORING_ENABLED', settings.DEBUG)
        self.slow_query_threshold = getattr(settings, 'SLOW_QUERY_THRESHOLD', self.SLOW_QUERY_THRESHOLD)
        self.stats = defaultdict(lambda: {'count': 0, 'total_time': 0, 'queries': []})

    def monitor_queries(self, func_name: str = None):
        """
        Decorator to monitor queries executed during function execution.

        Usage:
            @query_monitor.monitor_queries("get_user_jobs")
            def get_user_jobs(user_id):
                return Job.objects.filter(user_id=user_id)
        """
        def decorator(func: Callable) -> Callable:
            @functools.wraps(func)
            def wrapper(*args, **kwargs):
                if not self.enabled or not settings.DEBUG:
                    return func(*args, **kwargs)

                # Reset query log
                reset_queries()
                start_time = time.time()
                initial_query_count = len(connection.queries)

                try:
                    # Execute function
                    result = func(*args, **kwargs)
                    return result

                finally:
                    # Calculate metrics
                    end_time = time.time()
                    execution_time = end_time - start_time
                    query_count = len(connection.queries) - initial_query_count
                    queries = connection.queries[initial_query_count:]

                    # Analyze queries
                    analysis = self._analyze_queries(queries, execution_time)

                    # Log if slow or many queries
                    if execution_time > self.slow_query_threshold or query_count > 10:
                        self._log_performance(
                            func.__name__ if not func_name else func_name,
                            execution_time,
                            query_count,
                            analysis
                        )

                    # Store stats
                    self._update_stats(
                        func.__name__ if not func_name else func_name,
                        execution_time,
                        query_count,
                        analysis
                    )

            return wrapper
        return decorator

    def _analyze_queries(self, queries: List[Dict[str, Any]], total_time: float) -> Dict[str, Any]:
        """Analyze query performance and identify issues."""
        if not queries:
            return {
                'total_queries': 0,
                'total_time': 0,
                'avg_time': 0,
                'slow_queries': [],
                'duplicate_queries': [],
                'n_plus_one_suspected': False
            }

        # Calculate query times
        query_times = [float(q['time']) for q in queries]
        total_query_time = sum(query_times)
        avg_query_time = total_query_time / len(queries) if queries else 0

        # Identify slow queries
        slow_queries = [
            {
                'sql': q['sql'][:200],  # Truncate for logging
                'time': float(q['time']),
                'severity': self._get_severity(float(q['time']))
            }
            for q in queries
            if float(q['time']) > self.SLOW_QUERY_THRESHOLD
        ]

        # Detect duplicate queries (potential N+1 problem)
        query_signatures = defaultdict(list)
        for i, q in enumerate(queries):
            # Normalize SQL to detect similar queries
            normalized = self._normalize_sql(q['sql'])
            query_signatures[normalized].append((i, float(q['time'])))

        duplicate_queries = [
            {
                'sql': sql[:200],
                'count': len(occurrences),
                'total_time': sum(t for _, t in occurrences)
            }
            for sql, occurrences in query_signatures.items()
            if len(occurrences) > 1
        ]

        # Detect N+1 query pattern
        n_plus_one_suspected = len(duplicate_queries) > 0 and len(queries) > 10

        return {
            'total_queries': len(queries),
            'total_query_time': total_query_time,
            'total_execution_time': total_time,
            'avg_query_time': avg_query_time,
            'slow_queries': slow_queries,
            'duplicate_queries': duplicate_queries,
            'n_plus_one_suspected': n_plus_one_suspected,
            'query_overhead_percent': (total_query_time / total_time * 100) if total_time > 0 else 0
        }

    def _normalize_sql(self, sql: str) -> str:
        """Normalize SQL to detect similar queries."""
        # Remove specific IDs and values to find query patterns
        import re
        normalized = re.sub(r'\b\d+\b', 'N', sql)  # Replace numbers
        normalized = re.sub(r"'[^']*'", 'S', normalized)  # Replace strings
        return normalized

    def _get_severity(self, query_time: float) -> str:
        """Get severity level for query time."""
        if query_time >= self.CRITICAL_QUERY_THRESHOLD:
            return 'CRITICAL'
        elif query_time >= self.WARNING_QUERY_THRESHOLD:
            return 'WARNING'
        elif query_time >= self.SLOW_QUERY_THRESHOLD:
            return 'SLOW'
        return 'OK'

    def _log_performance(self, func_name: str, execution_time: float,
                        query_count: int, analysis: Dict[str, Any]) -> None:
        """Log performance information."""
        log_level = logging.WARNING if execution_time > self.WARNING_QUERY_THRESHOLD else logging.INFO

        log_message = (
            f"Query Performance Report: {func_name}\n"
            f"  Execution Time: {execution_time:.3f}s\n"
            f"  Query Count: {query_count}\n"
            f"  Total Query Time: {analysis['total_query_time']:.3f}s\n"
            f"  Query Overhead: {analysis['query_overhead_percent']:.1f}%\n"
        )

        if analysis['slow_queries']:
            log_message += f"  Slow Queries: {len(analysis['slow_queries'])}\n"
            for sq in analysis['slow_queries'][:3]:  # Show top 3
                log_message += f"    [{sq['severity']}] {sq['time']:.3f}s - {sq['sql']}\n"

        if analysis['duplicate_queries']:
            log_message += f"  Duplicate Queries: {len(analysis['duplicate_queries'])}\n"
            for dq in analysis['duplicate_queries'][:3]:  # Show top 3
                log_message += f"    {dq['count']}x - {dq['total_time']:.3f}s total\n"

        if analysis['n_plus_one_suspected']:
            log_message += "  ⚠️  N+1 Query Problem Suspected - Consider using select_related/prefetch_related\n"

        logger.log(log_level, log_message)

    def _update_stats(self, func_name: str, execution_time: float,
                     query_count: int, analysis: Dict[str, Any]) -> None:
        """Update performance statistics."""
        stats = self.stats[func_name]
        stats['count'] += 1
        stats['total_time'] += execution_time
        stats['avg_time'] = stats['total_time'] / stats['count']
        stats['last_execution'] = datetime.now()
        stats['last_query_count'] = query_count
        stats['last_analysis'] = analysis

    def get_stats(self) -> Dict[str, Any]:
        """Get performance statistics for all monitored functions."""
        return dict(self.stats)

    def reset_stats(self) -> None:
        """Reset performance statistics."""
        self.stats.clear()
        logger.info("Query performance stats reset")

    def get_recommendations(self) -> List[str]:
        """Get optimization recommendations based on collected stats."""
        recommendations = []

        for func_name, stats in self.stats.items():
            last_analysis = stats.get('last_analysis', {})

            # Check for N+1 problems
            if last_analysis.get('n_plus_one_suspected'):
                recommendations.append(
                    f"{func_name}: Consider using select_related() or prefetch_related() "
                    f"to reduce {len(last_analysis.get('duplicate_queries', []))} duplicate queries"
                )

            # Check for slow queries
            slow_queries = last_analysis.get('slow_queries', [])
            if slow_queries:
                recommendations.append(
                    f"{func_name}: {len(slow_queries)} slow queries detected - "
                    f"add database indexes or optimize SQL"
                )

            # Check for high query count
            if stats.get('last_query_count', 0) > 20:
                recommendations.append(
                    f"{func_name}: High query count ({stats['last_query_count']}) - "
                    f"consider caching or query optimization"
                )

            # Check for high query overhead
            overhead = last_analysis.get('query_overhead_percent', 0)
            if overhead > 80:
                recommendations.append(
                    f"{func_name}: Database queries account for {overhead:.0f}% of execution time - "
                    f"consider caching frequently accessed data"
                )

        return recommendations


# Global instance
query_monitor = QueryPerformanceMonitor()


def monitor_queries(func_name: Optional[str] = None):
    """
    Convenience decorator for query monitoring.

    Usage:
        @monitor_queries("get_dashboard_data")
        def get_dashboard_data(user_id):
            # ...
    """
    return query_monitor.monitor_queries(func_name)


# Context manager for manual query monitoring
class QueryMonitorContext:
    """
    Context manager for monitoring queries in a code block.

    Usage:
        with QueryMonitorContext("complex_operation") as qm:
            # ... perform database operations
            pass
        print(f"Executed {qm.query_count} queries in {qm.execution_time}s")
    """

    def __init__(self, operation_name: str):
        self.operation_name = operation_name
        self.start_time = None
        self.initial_query_count = 0
        self.query_count = 0
        self.execution_time = 0
        self.queries = []

    def __enter__(self):
        if settings.DEBUG:
            reset_queries()
            self.start_time = time.time()
            self.initial_query_count = len(connection.queries)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if settings.DEBUG and self.start_time:
            self.execution_time = time.time() - self.start_time
            self.queries = connection.queries[self.initial_query_count:]
            self.query_count = len(self.queries)

            analysis = query_monitor._analyze_queries(self.queries, self.execution_time)
            query_monitor._log_performance(
                self.operation_name,
                self.execution_time,
                self.query_count,
                analysis
            )
