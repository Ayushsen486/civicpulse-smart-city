import { Priority } from './issue';

export type ReviewAction = 'ACCEPT' | 'REJECT' | 'OVERRIDE';

export interface Recommendation {
  id: string;
  issueId: string;
  suggestedCategoryId?: string;
  suggestedCategoryName?: string;
  suggestedPriority: Priority;
  recommendedDepartment: string;
  categoryConfidence: number;
  priorityConfidence: number;
  overallConfidence: number;
  explanation: string;
  needsHumanReview: boolean;
  modelVersion: string;
  reviewed: boolean;
  reviewAction?: ReviewAction;
  reviewedBy?: string;
  reviewerName?: string;
  reviewedAt?: string;
  overrideNotes?: string;
  active: boolean;
  createdAt: string;
}

export interface ReviewRecommendationRequest {
  action: ReviewAction;
  overrideCategoryId?: string;
  overridePriority?: Priority;
  overrideDepartment?: string;
  notes?: string;
}
