import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { StatusBadge, PriorityBadge, RoleBadge } from '../components/ui/Badge';

describe('Badge Components', () => {
  it('renders StatusBadge with correct label for all statuses', () => {
    const { rerender } = render(<StatusBadge status="REPORTED" />);
    expect(screen.getByText('Reported')).toBeInTheDocument();

    rerender(<StatusBadge status="IN_PROGRESS" />);
    expect(screen.getByText('In Progress')).toBeInTheDocument();

    rerender(<StatusBadge status="RESOLVED" />);
    expect(screen.getByText('Resolved')).toBeInTheDocument();
  });

  it('renders PriorityBadge correctly', () => {
    const { rerender } = render(<PriorityBadge priority="CRITICAL" />);
    expect(screen.getByText('Critical')).toBeInTheDocument();

    rerender(<PriorityBadge priority="LOW" />);
    expect(screen.getByText('Low')).toBeInTheDocument();
  });

  it('renders RoleBadge with correct text', () => {
    const { rerender } = render(<RoleBadge role="ADMIN" />);
    expect(screen.getByText('Admin')).toBeInTheDocument();

    rerender(<RoleBadge role="OFFICER" />);
    expect(screen.getByText('Field Officer')).toBeInTheDocument();
  });
});
