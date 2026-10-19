import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { IssuesList } from '../pages/IssuesList';
import { issuesApi, categoriesApi, wardsApi, usersApi } from '../api';
import { Issue } from '../types/issue';

vi.mock('../api', () => ({
  issuesApi: {
    list: vi.fn(),
  },
  categoriesApi: {
    list: vi.fn(),
  },
  wardsApi: {
    list: vi.fn(),
  },
  usersApi: {
    getOfficers: vi.fn(),
  },
}));

const mockIssues: Issue[] = [
  {
    id: 'issue-1',
    issueNumber: 101,
    issueReference: 'ISS-2026-101',
    title: 'Severe Pothole on MG Road',
    description: 'Road damage causing traffic delays',
    status: 'REPORTED',
    priority: 'HIGH',
    priorityScore: 0.85,
    categoryId: 'cat-1',
    categoryName: 'Roads',
    reporterId: 'rep-1',
    reporterName: 'Aarav Sharma',
    latitude: 28.6139,
    longitude: 77.209,
    upvotesCount: 15,
    commentsCount: 3,
    slaBreached: false,
    createdAt: '2026-10-10T10:00:00Z',
  },
];

describe('IssuesList Page', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(issuesApi.list).mockResolvedValue({
      content: mockIssues,
      meta: {
        page: 0,
        size: 15,
        totalElements: 1,
        totalPages: 1,
        hasNext: false,
        hasPrevious: false,
      },
    });
    vi.mocked(categoriesApi.list).mockResolvedValue([]);
    vi.mocked(wardsApi.list).mockResolvedValue([]);
    vi.mocked(usersApi.getOfficers).mockResolvedValue({ content: [] });
  });

  it('renders issues table with reference, title, priority, and status', async () => {
    render(
      <BrowserRouter>
        <IssuesList />
      </BrowserRouter>
    );

    await waitFor(() => {
      expect(screen.getByText('Severe Pothole on MG Road')).toBeInTheDocument();
      expect(screen.getByText('ISS-2026-101')).toBeInTheDocument();
      expect(screen.getAllByText('Reported').length).toBeGreaterThan(0);
      expect(screen.getAllByText('High').length).toBeGreaterThan(0);
    });
  });
});
