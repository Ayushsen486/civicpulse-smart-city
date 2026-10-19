import React, { useEffect, useState, useCallback } from 'react';
import { useParams, Link } from 'react-router-dom';
import {
  issuesApi,
  intelligenceApi,
  usersApi,
  categoriesApi,
} from '../api';
import { Issue, IssueStatus, Priority, TimelineEvent, Comment } from '../types/issue';
import { Recommendation, ReviewAction } from '../types/intelligence';
import { User } from '../types/auth';
import { Category } from '../types/category';
import { Card, CardHeader, CardContent } from '../components/ui/Card';
import { StatusBadge, PriorityBadge } from '../components/ui/Badge';
import { LocationCard } from '../components/ui/LocationCard';
import { LoadingSpinner } from '../components/ui/LoadingSpinner';
import { Button } from '../components/ui/Button';
import { Modal } from '../components/ui/Modal';
import {
  ArrowLeft,
  Sparkles,
  CheckCircle,
  XCircle,
  RotateCcw,
  History,
  UserCheck,
  Send,
  Lock,
  AlertTriangle,
  FileText,
} from 'lucide-react';
import { format } from 'date-fns';
import { useAuthStore } from '../store/authStore';

export const IssueDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const { user } = useAuthStore();
  const isSupervisorOrAdmin = user?.role === 'SUPERVISOR' || user?.role === 'ADMIN';

  const [issue, setIssue] = useState<Issue | null>(null);
  const [timeline, setTimeline] = useState<TimelineEvent[]>([]);
  const [comments, setComments] = useState<Comment[]>([]);
  const [recommendation, setRecommendation] = useState<Recommendation | null>(null);
  const [recHistory, setRecHistory] = useState<Recommendation[]>([]);
  const [officers, setOfficers] = useState<User[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Status transition state
  const [newStatus, setNewStatus] = useState<IssueStatus>('IN_PROGRESS');
  const [statusRemarks, setStatusRemarks] = useState<string>('');
  const [isUpdatingStatus, setIsUpdatingStatus] = useState<boolean>(false);

  // Assignment state
  const [selectedOfficerId, setSelectedOfficerId] = useState<string>('');
  const [assignRemarks, setAssignRemarks] = useState<string>('');
  const [isAssigning, setIsAssigning] = useState<boolean>(false);

  // Comments state
  const [commentText, setCommentText] = useState<string>('');
  const [isInternalComment, setIsInternalComment] = useState<boolean>(false);
  const [isPostingComment, setIsPostingComment] = useState<boolean>(false);

  // AI Review state
  const [isReviewingRec, setIsReviewingRec] = useState<boolean>(false);
  const [isHistoryModalOpen, setIsHistoryModalOpen] = useState<boolean>(false);
  const [isOverrideModalOpen, setIsOverrideModalOpen] = useState<boolean>(false);
  const [overrideCategoryId, setOverrideCategoryId] = useState<string>('');
  const [overridePriority, setOverridePriority] = useState<Priority>('HIGH');
  const [overrideDepartment, setOverrideDepartment] = useState<string>('');
  const [overrideNotes, setOverrideNotes] = useState<string>('');

  const [actionMessage, setActionMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const loadData = useCallback(async () => {
    if (!id) return;
    setIsLoading(true);
    setError(null);
    try {
      const [issueRes, timelineRes, commentsRes, catsRes] = await Promise.all([
        issuesApi.getById(id),
        issuesApi.getTimeline(id),
        issuesApi.getComments(id),
        categoriesApi.list(),
      ]);
      setIssue(issueRes);
      setTimeline(timelineRes);
      setComments(commentsRes);
      setCategories(catsRes);
      setNewStatus(issueRes.status);
      setSelectedOfficerId(issueRes.assignedOfficerId || '');

      // Load AI recommendation (non-blocking)
      try {
        const rec = await intelligenceApi.getLatest(id);
        setRecommendation(rec);
      } catch {
        // No recommendation yet or non-fatal
      }

      // Load officers if authorized
      if (isSupervisorOrAdmin) {
        try {
          const offRes = await usersApi.getOfficers(0, 50);
          setOfficers(offRes.content);
        } catch {
          // Fallback
        }
      }
    } catch {
      setError('Could not load issue information. The complaint may have been deleted or network failed.');
    } finally {
      setIsLoading(false);
    }
  }, [id, isSupervisorOrAdmin]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleStatusChange = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!id) return;
    setIsUpdatingStatus(true);
    setActionMessage(null);
    try {
      const updated = await issuesApi.updateStatus(id, newStatus, statusRemarks);
      setIssue(updated);
      setStatusRemarks('');
      setActionMessage({ type: 'success', text: `Status updated to ${newStatus}` });
      const tl = await issuesApi.getTimeline(id);
      setTimeline(tl);
    } catch (err: unknown) {
      const msg =
        (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail ||
        'Failed to transition status. Please check permitted transitions.';
      setActionMessage({ type: 'error', text: msg });
    } finally {
      setIsUpdatingStatus(false);
    }
  };

  const handleAssignOfficer = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!id || !selectedOfficerId) return;
    setIsAssigning(true);
    setActionMessage(null);
    try {
      const updated = await issuesApi.assignOfficer(id, selectedOfficerId, assignRemarks);
      setIssue(updated);
      setAssignRemarks('');
      setActionMessage({ type: 'success', text: 'Officer dispatched successfully.' });
      const tl = await issuesApi.getTimeline(id);
      setTimeline(tl);
    } catch (err: unknown) {
      const msg =
        (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail ||
        'Assignment failed. Check permissions.';
      setActionMessage({ type: 'error', text: msg });
    } finally {
      setIsAssigning(false);
    }
  };

  const handleAddComment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!id || !commentText.trim()) return;
    setIsPostingComment(true);
    try {
      await issuesApi.addComment(id, commentText.trim(), isInternalComment);
      setCommentText('');
      const updatedComments = await issuesApi.getComments(id);
      setComments(updatedComments);
    } catch {
      alert('Could not post comment.');
    } finally {
      setIsPostingComment(false);
    }
  };

  const handleReviewAI = async (action: ReviewAction) => {
    if (!id) return;
    setIsReviewingRec(true);
    setActionMessage(null);
    try {
      const updatedRec = await intelligenceApi.review(id, {
        action,
        overrideCategoryId: action === 'OVERRIDE' ? overrideCategoryId : undefined,
        overridePriority: action === 'OVERRIDE' ? overridePriority : undefined,
        overrideDepartment: action === 'OVERRIDE' ? overrideDepartment : undefined,
        notes: action === 'OVERRIDE' ? overrideNotes : undefined,
      });
      setRecommendation(updatedRec);
      setIsOverrideModalOpen(false);
      setActionMessage({
        type: 'success',
        text: `AI recommendation ${action}ed successfully. Issue taxonomy synchronized.`,
      });
      // Refresh issue and timeline
      const [updatedIssue, updatedTl] = await Promise.all([
        issuesApi.getById(id),
        issuesApi.getTimeline(id),
      ]);
      setIssue(updatedIssue);
      setTimeline(updatedTl);
    } catch (err: unknown) {
      const msg =
        (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail ||
        'AI review action failed.';
      setActionMessage({ type: 'error', text: msg });
    } finally {
      setIsReviewingRec(false);
    }
  };

  const handleOpenRecHistory = async () => {
    if (!id) return;
    try {
      const hist = await intelligenceApi.getHistory(id);
      setRecHistory(hist);
      setIsHistoryModalOpen(true);
    } catch {
      alert('Could not fetch recommendation history.');
    }
  };

  if (isLoading) {
    return <LoadingSpinner message="Loading complaint details & audit trail..." />;
  }

  if (error || !issue) {
    return (
      <div className="p-8 text-center bg-white rounded-xl border border-slate-200">
        <AlertTriangle className="w-8 h-8 text-red-500 mx-auto mb-2" />
        <h3 className="font-bold text-slate-800 text-lg">Error Loading Issue</h3>
        <p className="text-sm text-slate-500 mt-1">{error}</p>
        <Link to="/issues">
          <Button variant="outline" className="mt-4">
            <ArrowLeft className="w-4 h-4 mr-2" /> Back to Issues List
          </Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-12">
      {/* Top Breadcrumb & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center space-x-3">
          <Link to="/issues">
            <Button size="sm" variant="ghost">
              <ArrowLeft className="w-4 h-4 mr-1" /> Back
            </Button>
          </Link>
          <div>
            <div className="flex items-center gap-2">
              <span className="font-mono text-xs font-bold text-blue-600 bg-blue-50 px-2 py-0.5 rounded border border-blue-200">
                {issue.issueReference || `#${issue.issueNumber}`}
              </span>
              <StatusBadge status={issue.status} />
              <PriorityBadge priority={issue.priority} />
            </div>
            <h1 className="text-xl font-bold text-slate-900 mt-1">{issue.title}</h1>
          </div>
        </div>
      </div>

      {actionMessage && (
        <div
          className={`p-3 rounded-xl border text-xs flex items-center justify-between ${
            actionMessage.type === 'success'
              ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
              : 'bg-rose-50 text-rose-800 border-rose-200'
          }`}
        >
          <span>{actionMessage.text}</span>
          <button onClick={() => setActionMessage(null)} className="font-bold ml-2">
            ✕
          </button>
        </div>
      )}

      {/* Main 2-Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column (2 Cols): Details, AI Copilot, Timeline, Comments */}
        <div className="lg:col-span-2 space-y-6">
          {/* Issue Overview Card */}
          <Card>
            <CardHeader
              title="Complaint Overview"
              subtitle={`Reported on ${format(new Date(issue.createdAt), 'dd MMMM yyyy, HH:mm')}`}
            />
            <CardContent className="space-y-4 text-xs">
              <div>
                <span className="text-slate-500 font-medium block mb-1">Citizen Description</span>
                <p className="text-slate-800 text-sm whitespace-pre-wrap bg-slate-50 p-3 rounded-lg border border-slate-100">
                  {issue.description || 'No detailed description provided by the citizen.'}
                </p>
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 pt-2 border-t border-slate-100">
                <div>
                  <span className="text-slate-400 block">Category</span>
                  <span className="font-semibold text-slate-800">{issue.categoryName}</span>
                </div>
                <div>
                  <span className="text-slate-400 block">Ward</span>
                  <span className="font-semibold text-slate-800">{issue.wardName || 'Unassigned'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block">Reporter</span>
                  <span className="font-semibold text-slate-800">{issue.reporterName}</span>
                </div>
                <div>
                  <span className="text-slate-400 block">Assigned Officer</span>
                  <span className="font-semibold text-slate-800">
                    {issue.assignedOfficerName || 'Not assigned'}
                  </span>
                </div>
                <div>
                  <span className="text-slate-400 block">SLA Deadline</span>
                  <span
                    className={`font-semibold ${
                      issue.slaBreached ? 'text-red-600 font-bold' : 'text-slate-800'
                    }`}
                  >
                    {issue.slaDeadline ? format(new Date(issue.slaDeadline), 'dd MMM, HH:mm') : 'Standard'}
                    {issue.slaBreached && ' (BREACHED)'}
                  </span>
                </div>
                <div>
                  <span className="text-slate-400 block">Citizen Endorsements</span>
                  <span className="font-semibold text-slate-800">{issue.upvotesCount} upvotes</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Evidence Attachments */}
          {issue.attachments && issue.attachments.length > 0 && (
            <Card>
              <CardHeader
                title={`Evidentiary Media (${issue.attachments.length})`}
                subtitle="Photographs and documents submitted for verification"
              />
              <CardContent>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                  {issue.attachments.map((att) => (
                    <a
                      key={att.id}
                      href={att.fileUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="group block relative rounded-lg border border-slate-200 overflow-hidden bg-slate-100 hover:border-blue-500 transition-colors"
                    >
                      {att.fileType.startsWith('image/') ? (
                        <img
                          src={att.fileUrl}
                          alt={att.fileName}
                          className="w-full h-32 object-cover group-hover:scale-105 transition-transform"
                        />
                      ) : (
                        <div className="w-full h-32 flex flex-col items-center justify-center text-slate-500 p-2">
                          <FileText className="w-8 h-8 mb-1" />
                          <span className="text-[10px] text-center truncate w-full">{att.fileName}</span>
                        </div>
                      )}
                      <div className="p-1.5 bg-white text-[10px] font-medium text-slate-700 truncate">
                        {att.isBefore ? 'Before Repair' : 'After Repair'} • {att.fileName}
                      </div>
                    </a>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Phase 3 AI Intelligence Advisory Card */}
          <Card className="border-indigo-100 bg-gradient-to-br from-indigo-50/40 via-white to-purple-50/40 shadow-sm">
            <CardHeader
              title={
                <div className="flex items-center space-x-2 text-indigo-900">
                  <Sparkles className="w-5 h-5 text-indigo-600" />
                  <span>AI Issue Intelligence Copilot</span>
                </div>
              }
              subtitle="Automated category taxonomy, priority scoring & department recommendation"
              action={
                <Button
                  size="sm"
                  variant="outline"
                  onClick={handleOpenRecHistory}
                  className="flex items-center gap-1 text-xs"
                >
                  <History className="w-3.5 h-3.5" /> History
                </Button>
              }
            />
            <CardContent className="space-y-4 text-xs">
              {recommendation ? (
                <>
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    <div className="p-3 bg-white rounded-lg border border-indigo-100 shadow-2xs">
                      <span className="text-slate-500 block mb-0.5">Suggested Category</span>
                      <span className="font-bold text-indigo-950 text-sm">
                        {recommendation.suggestedCategoryName || 'General'}
                      </span>
                      <div className="text-[10px] text-slate-400 mt-1">
                        Confidence: {(recommendation.categoryConfidence * 100).toFixed(0)}%
                      </div>
                    </div>

                    <div className="p-3 bg-white rounded-lg border border-indigo-100 shadow-2xs">
                      <span className="text-slate-500 block mb-0.5">Assessed Priority</span>
                      <div className="flex items-center gap-1.5 mt-0.5">
                        <PriorityBadge priority={recommendation.suggestedPriority} />
                      </div>
                      <div className="text-[10px] text-slate-400 mt-1">
                        Confidence: {(recommendation.priorityConfidence * 100).toFixed(0)}%
                      </div>
                    </div>

                    <div className="p-3 bg-white rounded-lg border border-indigo-100 shadow-2xs">
                      <span className="text-slate-500 block mb-0.5">Target Department</span>
                      <span className="font-bold text-slate-900 truncate block">
                        {recommendation.recommendedDepartment}
                      </span>
                      <div className="text-[10px] text-indigo-600 font-semibold mt-1">
                        Overall {(recommendation.overallConfidence * 100).toFixed(0)}%
                      </div>
                    </div>
                  </div>

                  <div className="p-3 bg-white rounded-lg border border-indigo-100">
                    <span className="text-slate-500 font-semibold block mb-1">
                      Reasoning & Triage Explanation:
                    </span>
                    <p className="text-slate-700">{recommendation.explanation}</p>
                  </div>

                  {recommendation.needsHumanReview && (
                    <div className="p-2.5 bg-amber-50 border border-amber-200 rounded-lg flex items-center gap-2 text-amber-800">
                      <AlertTriangle className="w-4 h-4 text-amber-600 flex-shrink-0" />
                      <span>
                        <strong>Escalation Advisory:</strong> Safety keywords detected. Review by supervisor before dispatch.
                      </span>
                    </div>
                  )}

                  {/* Staff Review Buttons */}
                  <div className="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-indigo-100">
                    <div className="text-[11px] text-slate-500">
                      Status:{' '}
                      {recommendation.reviewed ? (
                        <span className="font-bold text-emerald-700">
                          Reviewed ({recommendation.reviewAction}) by {recommendation.reviewerName}
                        </span>
                      ) : (
                        <span className="font-semibold text-amber-600">Pending Staff Review</span>
                      )}
                    </div>

                    <div className="flex items-center space-x-2">
                      <Button
                        size="sm"
                        variant="success"
                        disabled={isReviewingRec}
                        onClick={() => handleReviewAI('ACCEPT')}
                        className="flex items-center gap-1"
                      >
                        <CheckCircle className="w-3.5 h-3.5" /> Accept Suggestion
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        disabled={isReviewingRec}
                        onClick={() => {
                          setOverrideCategoryId(recommendation.suggestedCategoryId || '');
                          setOverridePriority(recommendation.suggestedPriority);
                          setOverrideDepartment(recommendation.recommendedDepartment);
                          setIsOverrideModalOpen(true);
                        }}
                        className="flex items-center gap-1"
                      >
                        <RotateCcw className="w-3.5 h-3.5" /> Override...
                      </Button>
                      <Button
                        size="sm"
                        variant="destructive"
                        disabled={isReviewingRec}
                        onClick={() => handleReviewAI('REJECT')}
                        className="flex items-center gap-1"
                      >
                        <XCircle className="w-3.5 h-3.5" /> Reject
                      </Button>
                    </div>
                  </div>
                </>
              ) : (
                <div className="text-center py-4 text-slate-500">
                  <p>No intelligence recommendation found for this issue.</p>
                  <Button
                    size="sm"
                    variant="outline"
                    className="mt-2"
                    onClick={async () => {
                      if (!id) return;
                      setIsReviewingRec(true);
                      try {
                        const rec = await intelligenceApi.analyze(id);
                        setRecommendation(rec);
                      } finally {
                        setIsReviewingRec(false);
                      }
                    }}
                  >
                    Generate AI Recommendation
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Timeline Audit History */}
          <Card>
            <CardHeader
              title={`Audit Timeline (${timeline.length} events)`}
              subtitle="Immutable chronological ledger of status changes and assignments"
            />
            <CardContent>
              {timeline.length === 0 ? (
                <p className="text-xs text-slate-400">No events logged.</p>
              ) : (
                <div className="relative pl-6 space-y-6 before:absolute before:left-2 before:top-2 before:bottom-2 before:w-0.5 before:bg-slate-200 text-xs">
                  {timeline.map((ev) => (
                    <div key={ev.id} className="relative">
                      <div className="absolute -left-6 top-1 w-2.5 h-2.5 rounded-full bg-blue-600 ring-4 ring-white" />
                      <div className="flex items-center justify-between">
                        <span className="font-bold text-slate-800">
                          {ev.eventType.replace(/_/g, ' ')}
                        </span>
                        <span className="text-[11px] text-slate-400">
                          {format(new Date(ev.createdAt), 'dd MMM yyyy, HH:mm')}
                        </span>
                      </div>
                      <div className="text-slate-600 mt-0.5">
                        By <strong>{ev.actorName}</strong> ({ev.actorRole})
                      </div>
                      {ev.remarks && (
                        <div className="mt-1.5 p-2 bg-slate-50 rounded border border-slate-100 text-slate-700 italic">
                          "{ev.remarks}"
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Comments & Internal Staff Notes */}
          <Card>
            <CardHeader
              title={`Discussions & Notes (${comments.length})`}
              subtitle="Citizen communications and internal officer remarks"
            />
            <CardContent className="space-y-4 text-xs">
              <div className="space-y-3">
                {comments.length === 0 ? (
                  <p className="text-slate-400">No comments posted yet.</p>
                ) : (
                  comments.map((cm) => (
                    <div
                      key={cm.id}
                      className={`p-3 rounded-xl border ${
                        cm.isInternal
                          ? 'bg-amber-50/60 border-amber-200'
                          : 'bg-slate-50 border-slate-200'
                      }`}
                    >
                      <div className="flex items-center justify-between mb-1">
                        <div className="flex items-center gap-1.5">
                          <span className="font-bold text-slate-900">{cm.authorName}</span>
                          <span className="text-[10px] text-slate-500">({cm.authorRole})</span>
                          {cm.isInternal && (
                            <span className="inline-flex items-center gap-0.5 text-[10px] font-bold text-amber-700 bg-amber-100 px-1.5 py-0.5 rounded">
                              <Lock className="w-3 h-3" /> Internal Note
                            </span>
                          )}
                        </div>
                        <span className="text-[10px] text-slate-400">
                          {format(new Date(cm.createdAt), 'dd MMM, HH:mm')}
                        </span>
                      </div>
                      <p className="text-slate-800 whitespace-pre-wrap">{cm.content}</p>
                    </div>
                  ))
                )}
              </div>

              {/* Add Comment Form */}
              <form onSubmit={handleAddComment} className="pt-3 border-t border-slate-100 space-y-2">
                <textarea
                  rows={2}
                  value={commentText}
                  onChange={(e) => setCommentText(e.target.value)}
                  placeholder="Post comment or internal note..."
                  required
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none"
                />

                <div className="flex items-center justify-between">
                  <label className="flex items-center space-x-2 text-slate-600 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={isInternalComment}
                      onChange={(e) => setIsInternalComment(e.target.checked)}
                      className="rounded border-slate-300 text-amber-600 focus:ring-amber-500"
                    />
                    <span className="text-[11px] font-medium flex items-center gap-1">
                      <Lock className="w-3 h-3 text-amber-600" /> Internal Staff Note (hide from citizen)
                    </span>
                  </label>

                  <Button size="sm" type="submit" variant="primary" isLoading={isPostingComment}>
                    <Send className="w-3.5 h-3.5 mr-1" /> Post Note
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>

        {/* Right Column: Actions & Location Card */}
        <div className="space-y-6">
          {/* Status Update Card */}
          <Card>
            <CardHeader
              title="Lifecycle Transition"
              subtitle="Enforces Spring Boot state machine rules"
            />
            <CardContent>
              <form onSubmit={handleStatusChange} className="space-y-3 text-xs">
                <div>
                  <label className="block font-semibold text-slate-700 mb-1">Target Status</label>
                  <select
                    value={newStatus}
                    onChange={(e) => setNewStatus(e.target.value as IssueStatus)}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none bg-white"
                  >
                    <option value="ACKNOWLEDGED">ACKNOWLEDGED</option>
                    <option value="ASSIGNED">ASSIGNED</option>
                    <option value="IN_PROGRESS">IN_PROGRESS</option>
                    <option value="RESOLVED">RESOLVED</option>
                    <option value="CLOSED">CLOSED</option>
                  </select>
                </div>

                <div>
                  <label className="block font-semibold text-slate-700 mb-1">Audit Remarks</label>
                  <textarea
                    rows={2}
                    value={statusRemarks}
                    onChange={(e) => setStatusRemarks(e.target.value)}
                    placeholder="Enter reason or completion notes..."
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none"
                  />
                </div>

                <Button
                  type="submit"
                  size="sm"
                  variant="primary"
                  className="w-full"
                  isLoading={isUpdatingStatus}
                >
                  Apply Status Transition
                </Button>
              </form>
            </CardContent>
          </Card>

          {/* Dispatch Officer Card (Supervisor / Admin) */}
          {isSupervisorOrAdmin && (
            <Card>
              <CardHeader
                title="Dispatch & Assignment"
                subtitle="Assign authorized field officer"
              />
              <CardContent>
                <form onSubmit={handleAssignOfficer} className="space-y-3 text-xs">
                  <div>
                    <label className="block font-semibold text-slate-700 mb-1">Field Officer</label>
                    <select
                      value={selectedOfficerId}
                      onChange={(e) => setSelectedOfficerId(e.target.value)}
                      required
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none bg-white"
                    >
                      <option value="">-- Select Officer --</option>
                      {officers.map((off) => (
                        <option key={off.id} value={off.id}>
                          {off.firstName} {off.lastName}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block font-semibold text-slate-700 mb-1">Dispatch Remarks</label>
                    <textarea
                      rows={2}
                      value={assignRemarks}
                      onChange={(e) => setAssignRemarks(e.target.value)}
                      placeholder="Notes for officer..."
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none"
                    />
                  </div>

                  <Button
                    type="submit"
                    size="sm"
                    variant="secondary"
                    className="w-full flex items-center justify-center gap-1.5"
                    isLoading={isAssigning}
                  >
                    <UserCheck className="w-4 h-4" /> Dispatch Officer
                  </Button>
                </form>
              </CardContent>
            </Card>
          )}

          {/* Geographic Location Card with OpenStreetMap */}
          <LocationCard
            latitude={issue.latitude}
            longitude={issue.longitude}
            address={issue.address}
            landmark={issue.landmark}
            wardName={issue.wardName}
          />
        </div>
      </div>

      {/* Override AI Modal */}
      <Modal
        isOpen={isOverrideModalOpen}
        onClose={() => setIsOverrideModalOpen(false)}
        title="Override AI Intelligence Recommendation"
        description="Select custom category, priority, and department for this issue."
      >
        <div className="space-y-3 text-xs">
          <div>
            <label className="block font-semibold text-slate-700 mb-1">Category</label>
            <select
              value={overrideCategoryId}
              onChange={(e) => setOverrideCategoryId(e.target.value)}
              className="w-full px-3 py-2 border border-slate-300 rounded-lg bg-white"
            >
              <option value="">-- Keep or choose category --</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block font-semibold text-slate-700 mb-1">Priority</label>
            <select
              value={overridePriority}
              onChange={(e) => setOverridePriority(e.target.value as Priority)}
              className="w-full px-3 py-2 border border-slate-300 rounded-lg bg-white"
            >
              <option value="LOW">LOW</option>
              <option value="MEDIUM">MEDIUM</option>
              <option value="HIGH">HIGH</option>
              <option value="CRITICAL">CRITICAL</option>
            </select>
          </div>

          <div>
            <label className="block font-semibold text-slate-700 mb-1">Department</label>
            <input
              type="text"
              value={overrideDepartment}
              onChange={(e) => setOverrideDepartment(e.target.value)}
              placeholder="e.g. Road Maintenance & Infrastructure"
              className="w-full px-3 py-2 border border-slate-300 rounded-lg"
            />
          </div>

          <div>
            <label className="block font-semibold text-slate-700 mb-1">Override Reason / Notes</label>
            <textarea
              rows={2}
              value={overrideNotes}
              onChange={(e) => setOverrideNotes(e.target.value)}
              placeholder="Document reason for overriding AI recommendation..."
              className="w-full px-3 py-2 border border-slate-300 rounded-lg"
            />
          </div>

          <div className="flex justify-end space-x-2 pt-2 border-t border-slate-100">
            <Button variant="outline" onClick={() => setIsOverrideModalOpen(false)}>
              Cancel
            </Button>
            <Button
              variant="primary"
              onClick={() => handleReviewAI('OVERRIDE')}
              isLoading={isReviewingRec}
            >
              Confirm Override
            </Button>
          </div>
        </div>
      </Modal>

      {/* AI Recommendation History Modal */}
      <Modal
        isOpen={isHistoryModalOpen}
        onClose={() => setIsHistoryModalOpen(false)}
        title="AI Recommendation Audit History"
        description="Chronological log of all AI suggestions and supervisor reviews."
        maxWidth="lg"
      >
        <div className="space-y-3 text-xs max-h-96 overflow-y-auto">
          {recHistory.length === 0 ? (
            <p className="text-slate-400 py-4 text-center">No previous recommendations recorded.</p>
          ) : (
            recHistory.map((h) => (
              <div key={h.id} className="p-3 bg-slate-50 rounded-lg border border-slate-200 space-y-1">
                <div className="flex items-center justify-between">
                  <span className="font-bold text-slate-900">
                    {h.suggestedCategoryName} • {h.suggestedPriority}
                  </span>
                  <span className="text-[10px] text-slate-400">
                    {format(new Date(h.createdAt), 'dd MMM yyyy, HH:mm')}
                  </span>
                </div>
                <div className="text-slate-600">Department: {h.recommendedDepartment}</div>
                <p className="text-slate-500 italic">"{h.explanation}"</p>
                {h.reviewed && (
                  <div className="text-emerald-700 font-semibold pt-1 border-t border-slate-200">
                    Reviewed ({h.reviewAction}) by {h.reviewerName || 'Staff'} {h.overrideNotes && `• Notes: ${h.overrideNotes}`}
                  </div>
                )}
              </div>
            ))
          )}
        </div>
      </Modal>
    </div>
  );
};
