import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { IssueDetail } from '../pages/IssueDetail';
import { issuesApi, intelligenceApi, categoriesApi } from '../api';
import { Issue } from '../types/issue';
import { Recommendation } from '../types/intelligence';

vi.mock('../api', () => ({
  issuesApi: {
    getById: vi.fn(),
    getTimeline: vi.fn(),
    getComments: vi.fn(),
  },
  intelligenceApi: {
    getLatest: vi.fn(),
    review: vi.fn(),
    getHistory: vi.fn(),
  },
  categoriesApi: {
    list: vi.fn(),
  },
  usersApi: {
    getOfficers: vi.fn(),
  },
}));

const mockIssue: Issue = {
  id: 'issue-123',
  issueNumber: 42,
  issueReference: 'ISS-2026-42',
  title: 'Dangerous Open Wire',
  description: 'Exposed live wire hanging near public park',
  status: 'REPORTED',
  priority: 'CRITICAL',
  priorityScore: 0.98,
  categoryId: 'cat-elec',
  categoryName: 'Electrical & Power',
  reporterId: 'rep-1',
  reporterName: 'Priya Verma',
  latitude: 28.6139,
  longitude: 77.209,
  upvotesCount: 20,
  commentsCount: 2,
  slaBreached: false,
  createdAt: '2026-10-10T12:00:00Z',
};

const mockRecommendation: Recommendation = {
  id: 'rec-1',
  issueId: 'issue-123',
  suggestedCategoryId: 'cat-elec',
  suggestedCategoryName: 'Electrical & Power',
  suggestedPriority: 'CRITICAL',
  recommendedDepartment: 'Electrical & Power Distribution',
  categoryConfidence: 0.95,
  priorityConfidence: 0.92,
  overallConfidence: 0.94,
  explanation: 'High voltage electrocution hazard requiring emergency lineman dispatch.',
  needsHumanReview: true,
  modelVersion: 'CivicPulse-RuleEngine v1.0.0',
  reviewed: false,
  active: true,
  createdAt: '2026-10-10T12:05:00Z',
};

describe('IssueDetail Page', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(issuesApi.getById).mockResolvedValue(mockIssue);
    vi.mocked(issuesApi.getTimeline).mockResolvedValue([]);
    vi.mocked(issuesApi.getComments).mockResolvedValue([]);
    vi.mocked(intelligenceApi.getLatest).mockResolvedValue(mockRecommendation);
    vi.mocked(categoriesApi.list).mockResolvedValue([]);
  });

  it('renders issue details and AI intelligence recommendation', async () => {
    render(
      <MemoryRouter initialEntries={['/issues/issue-123']}>
        <Routes>
          <Route path="/issues/:id" element={<IssueDetail />} />
        </Routes>
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByText('Dangerous Open Wire')).toBeInTheDocument();
      expect(screen.getByText('Exposed live wire hanging near public park')).toBeInTheDocument();
      // Verify AI recommendation card elements
      expect(screen.getByText('AI Issue Intelligence Copilot')).toBeInTheDocument();
      expect(screen.getByText(/Electrical & Power Distribution/)).toBeInTheDocument();
      expect(screen.getByText(/High voltage electrocution hazard/)).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /Accept Suggestion/i })).toBeInTheDocument();
    });
  });
});
