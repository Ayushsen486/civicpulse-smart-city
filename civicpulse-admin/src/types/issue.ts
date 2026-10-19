import { UserRole } from './auth';

export type IssueStatus =
  | 'REPORTED'
  | 'ACKNOWLEDGED'
  | 'ASSIGNED'
  | 'IN_PROGRESS'
  | 'RESOLVED'
  | 'CLOSED';

export type Priority = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';

export interface Attachment {
  id: string;
  fileUrl: string;
  fileName: string;
  fileType: string;
  fileSize: number;
  attachmentType: string;
  isBefore: boolean;
  createdAt: string;
}

export interface TimelineEvent {
  id: string;
  eventType: string;
  fromStatus?: IssueStatus;
  toStatus?: IssueStatus;
  actorId: string;
  actorName: string;
  actorRole: UserRole;
  remarks?: string;
  createdAt: string;
}

export interface Comment {
  id: string;
  content: string;
  isInternal: boolean;
  authorId: string;
  authorName: string;
  authorRole: UserRole;
  createdAt: string;
}

export interface Issue {
  id: string;
  issueNumber: number;
  issueReference?: string;
  title: string;
  description?: string;
  status: IssueStatus;
  priority: Priority;
  priorityScore: number;
  categoryId: string;
  categoryName: string;
  categoryColor?: string;
  reporterId: string;
  reporterName: string;
  assignedOfficerId?: string;
  assignedOfficerName?: string;
  wardId?: string;
  wardName?: string;
  latitude: number;
  longitude: number;
  address?: string;
  landmark?: string;
  upvotesCount: number;
  commentsCount: number;
  hasUpvoted?: boolean;
  slaDeadline?: string;
  slaBreached: boolean;
  createdAt: string;
  updatedAt?: string;
  attachments?: Attachment[];
}

export interface IssueFilters {
  status?: IssueStatus;
  priority?: Priority;
  categoryId?: string;
  wardId?: string;
  reporterId?: string;
  officerId?: string;
  page?: number;
  size?: number;
}

export interface OfficerWorkload {
  officerId: string;
  officerName: string;
  email: string;
  activeIssuesCount: number;
  resolvedIssuesCount: number;
}

export interface IssueStatistics {
  totalIssues: number;
  reportedCount: number;
  acknowledgedCount: number;
  assignedCount: number;
  inProgressCount: number;
  resolvedCount: number;
  closedCount: number;
  rejectedCount: number;
  slaBreachedCount: number;
  highPriorityCount: number;
  officerWorkloads: OfficerWorkload[];
}
