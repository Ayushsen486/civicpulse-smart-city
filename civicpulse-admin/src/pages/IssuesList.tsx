import React, { useEffect, useState, useCallback } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { issuesApi, categoriesApi, wardsApi, usersApi } from '../api';
import { Issue, IssueStatus, Priority } from '../types/issue';
import { Category } from '../types/category';
import { Ward } from '../types/ward';
import { User } from '../types/auth';
import { Card } from '../components/ui/Card';
import { StatusBadge, PriorityBadge } from '../components/ui/Badge';
import { LoadingSpinner } from '../components/ui/LoadingSpinner';
import { Button } from '../components/ui/Button';
import { Modal } from '../components/ui/Modal';
import {
  Search,
  Filter,
  UserCheck,
  ChevronLeft,
  ChevronRight,
  Eye,
  CheckCircle,
  MapPin,
} from 'lucide-react';
import { format } from 'date-fns';
import { useAuthStore } from '../store/authStore';

export const IssuesList: React.FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const { user } = useAuthStore();
  const isSupervisorOrAdmin = user?.role === 'SUPERVISOR' || user?.role === 'ADMIN';

  const [issues, setIssues] = useState<Issue[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [wards, setWards] = useState<Ward[]>([]);
  const [officers, setOfficers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [page, setPage] = useState<number>(0);
  const [totalPages, setTotalPages] = useState<number>(1);
  const [totalElements, setTotalElements] = useState<number>(0);

  // Filters state from query parameters or default
  const statusFilter = (searchParams.get('status') as IssueStatus) || undefined;
  const priorityFilter = (searchParams.get('priority') as Priority) || undefined;
  const categoryFilter = searchParams.get('categoryId') || undefined;
  const wardFilter = searchParams.get('wardId') || undefined;
  const officerFilter = searchParams.get('officerId') || undefined;
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Quick action modals
  const [selectedIssue, setSelectedIssue] = useState<Issue | null>(null);
  const [isAssignModalOpen, setIsAssignModalOpen] = useState<boolean>(false);
  const [selectedOfficerId, setSelectedOfficerId] = useState<string>('');
  const [assignRemarks, setAssignRemarks] = useState<string>('');
  const [isAssigning, setIsAssigning] = useState<boolean>(false);

  const [isStatusModalOpen, setIsStatusModalOpen] = useState<boolean>(false);
  const [nextStatus, setNextStatus] = useState<IssueStatus>('ACKNOWLEDGED');
  const [statusRemarks, setStatusRemarks] = useState<string>('');
  const [isUpdatingStatus, setIsUpdatingStatus] = useState<boolean>(false);
  const [actionError, setActionError] = useState<string | null>(null);

  const fetchIssues = useCallback(async () => {
    setIsLoading(true);
    try {
      const res = await issuesApi.list({
        page,
        size: 15,
        status: statusFilter,
        priority: priorityFilter,
        categoryId: categoryFilter,
        wardId: wardFilter,
        officerId: officerFilter,
      });
      setIssues(res.content);
      if (res.meta) {
        setTotalPages(res.meta.totalPages);
        setTotalElements(res.meta.totalElements);
      }
    } catch {
      // Handled with error state
    } finally {
      setIsLoading(false);
    }
  }, [page, statusFilter, priorityFilter, categoryFilter, wardFilter, officerFilter]);

  useEffect(() => {
    fetchIssues();
  }, [fetchIssues]);

  useEffect(() => {
    const fetchMetadata = async () => {
      try {
        const [cats, wrds] = await Promise.all([categoriesApi.list(), wardsApi.list()]);
        setCategories(cats);
        setWards(wrds);
        if (isSupervisorOrAdmin) {
          const offRes = await usersApi.getOfficers(0, 50);
          setOfficers(offRes.content);
        }
      } catch {
        // Fallback
      }
    };
    fetchMetadata();
  }, [isSupervisorOrAdmin]);

  const updateFilter = (key: string, value: string) => {
    const newParams = new URLSearchParams(searchParams);
    if (!value) {
      newParams.delete(key);
    } else {
      newParams.set(key, value);
    }
    setSearchParams(newParams);
    setPage(0);
  };

  const handleAssignSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedIssue || !selectedOfficerId) return;
    setIsAssigning(true);
    setActionError(null);
    try {
      await issuesApi.assignOfficer(selectedIssue.id, selectedOfficerId, assignRemarks);
      setIsAssignModalOpen(false);
      setSelectedIssue(null);
      setSelectedOfficerId('');
      setAssignRemarks('');
      await fetchIssues();
    } catch (err: unknown) {
      setActionError(
        (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail ||
          'Failed to assign officer. Please try again.'
      );
    } finally {
      setIsAssigning(false);
    }
  };

  const handleStatusSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedIssue) return;
    setIsUpdatingStatus(true);
    setActionError(null);
    try {
      await issuesApi.updateStatus(selectedIssue.id, nextStatus, statusRemarks);
      setIsStatusModalOpen(false);
      setSelectedIssue(null);
      setStatusRemarks('');
      await fetchIssues();
    } catch (err: unknown) {
      setActionError(
        (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail ||
          'Invalid state transition. Please verify lifecycle requirements.'
      );
    } finally {
      setIsUpdatingStatus(false);
    }
  };

  const filteredIssues = issues.filter((issue) => {
    if (!searchQuery) return true;
    const q = searchQuery.toLowerCase();
    return (
      issue.title.toLowerCase().includes(q) ||
      (issue.issueReference && issue.issueReference.toLowerCase().includes(q)) ||
      issue.description?.toLowerCase().includes(q) ||
      issue.categoryName.toLowerCase().includes(q)
    );
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Issues & Complaints</h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Total {totalElements} complaints recorded across municipal wards
          </p>
        </div>
        <div className="flex items-center space-x-2">
          <Link
            to="/map"
            className="inline-flex items-center space-x-1.5 px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-xl shadow-sm hover:shadow transition-all"
          >
            <MapPin className="w-3.5 h-3.5" />
            <span>Interactive Map View</span>
          </Link>
        </div>
      </div>

      {/* Filter Bar */}
      <Card className="p-4 bg-white">
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
          {/* Search box */}
          <div className="relative lg:col-span-2">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
            <input
              type="text"
              placeholder="Search reference or keywords..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-9 pr-3 py-2 text-xs border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none"
            />
          </div>

          {/* Status filter */}
          <div>
            <select
              value={statusFilter || ''}
              onChange={(e) => updateFilter('status', e.target.value)}
              className="w-full px-3 py-2 text-xs border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none bg-white"
            >
              <option value="">All Statuses</option>
              <option value="REPORTED">Reported</option>
              <option value="ACKNOWLEDGED">Acknowledged</option>
              <option value="ASSIGNED">Assigned</option>
              <option value="IN_PROGRESS">In Progress</option>
              <option value="RESOLVED">Resolved</option>
              <option value="CLOSED">Closed</option>
            </select>
          </div>

          {/* Priority filter */}
          <div>
            <select
              value={priorityFilter || ''}
              onChange={(e) => updateFilter('priority', e.target.value)}
              className="w-full px-3 py-2 text-xs border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none bg-white"
            >
              <option value="">All Priorities</option>
              <option value="LOW">Low</option>
              <option value="MEDIUM">Medium</option>
              <option value="HIGH">High</option>
              <option value="CRITICAL">Critical</option>
            </select>
          </div>

          {/* Category filter */}
          <div>
            <select
              value={categoryFilter || ''}
              onChange={(e) => updateFilter('categoryId', e.target.value)}
              className="w-full px-3 py-2 text-xs border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none bg-white"
            >
              <option value="">All Categories</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>

          {/* Ward filter */}
          <div>
            <select
              value={wardFilter || ''}
              onChange={(e) => updateFilter('wardId', e.target.value)}
              className="w-full px-3 py-2 text-xs border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none bg-white"
            >
              <option value="">All Wards</option>
              {wards.map((w) => (
                <option key={w.id} value={w.id}>
                  {w.name} ({w.code})
                </option>
              ))}
            </select>
          </div>
        </div>
      </Card>

      {/* Issues Table */}
      <Card>
        {isLoading ? (
          <LoadingSpinner message="Filtering and loading complaints..." />
        ) : filteredIssues.length === 0 ? (
          <div className="py-12 text-center text-slate-500 text-sm">
            <Filter className="w-8 h-8 text-slate-300 mx-auto mb-2" />
            <p className="font-semibold text-slate-700">No issues matching criteria</p>
            <p className="text-xs text-slate-400 mt-1">Try resetting filters or changing your search terms.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-slate-500 uppercase tracking-wider font-semibold border-b border-slate-200">
                <tr>
                  <th className="px-4 py-3">Reference / Title</th>
                  <th className="px-4 py-3">Category</th>
                  <th className="px-4 py-3">Ward</th>
                  <th className="px-4 py-3">Priority</th>
                  <th className="px-4 py-3">Status</th>
                  <th className="px-4 py-3">Assigned Officer</th>
                  <th className="px-4 py-3">Date</th>
                  <th className="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredIssues.map((issue) => (
                  <tr key={issue.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="px-4 py-3">
                      <Link
                        to={`/issues/${issue.id}`}
                        className="text-blue-600 hover:text-blue-800 font-semibold block"
                      >
                        {issue.issueReference || `#${issue.issueNumber}`}
                      </Link>
                      <span className="text-slate-800 truncate block max-w-xs font-medium">
                        {issue.title}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-slate-600">{issue.categoryName}</td>
                    <td className="px-4 py-3 text-slate-600 font-medium">
                      {issue.wardName || 'Unassigned'}
                    </td>
                    <td className="px-4 py-3">
                      <PriorityBadge priority={issue.priority} />
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge status={issue.status} />
                    </td>
                    <td className="px-4 py-3 text-slate-600">
                      {issue.assignedOfficerName ? (
                        <span className="inline-flex items-center gap-1 font-medium text-slate-800">
                          <UserCheck className="w-3.5 h-3.5 text-teal-600" />
                          {issue.assignedOfficerName}
                        </span>
                      ) : (
                        <span className="text-slate-400 italic">Unassigned</span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-slate-500 whitespace-nowrap">
                      {issue.createdAt ? format(new Date(issue.createdAt), 'dd MMM yyyy') : '-'}
                    </td>
                    <td className="px-4 py-3 text-right space-x-1 whitespace-nowrap">
                      <Link to={`/issues/${issue.id}`}>
                        <Button size="sm" variant="ghost" title="View details">
                          <Eye className="w-3.5 h-3.5" />
                        </Button>
                      </Link>

                      {isSupervisorOrAdmin && (
                        <Button
                          size="sm"
                          variant="outline"
                          title="Assign Officer"
                          onClick={() => {
                            setSelectedIssue(issue);
                            setSelectedOfficerId(issue.assignedOfficerId || '');
                            setIsAssignModalOpen(true);
                          }}
                        >
                          <UserCheck className="w-3.5 h-3.5" />
                        </Button>
                      )}

                      <Button
                        size="sm"
                        variant="outline"
                        title="Change Status"
                        onClick={() => {
                          setSelectedIssue(issue);
                          setNextStatus(issue.status);
                          setIsStatusModalOpen(true);
                        }}
                      >
                        <CheckCircle className="w-3.5 h-3.5" />
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination Bar */}
        <div className="p-4 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
          <div>
            Showing Page <strong>{page + 1}</strong> of <strong>{totalPages || 1}</strong> ({totalElements} items)
          </div>
          <div className="flex items-center space-x-2">
            <Button
              size="sm"
              variant="outline"
              disabled={page === 0 || isLoading}
              onClick={() => setPage((p) => Math.max(p - 1, 0))}
            >
              <ChevronLeft className="w-4 h-4 mr-1" /> Prev
            </Button>
            <Button
              size="sm"
              variant="outline"
              disabled={page >= totalPages - 1 || isLoading}
              onClick={() => setPage((p) => p + 1)}
            >
              Next <ChevronRight className="w-4 h-4 ml-1" />
            </Button>
          </div>
        </div>
      </Card>

      {/* Assign Officer Modal */}
      <Modal
        isOpen={isAssignModalOpen}
        onClose={() => {
          setIsAssignModalOpen(false);
          setSelectedIssue(null);
          setActionError(null);
        }}
        title={`Dispatch Officer — ${selectedIssue?.issueReference || selectedIssue?.title}`}
        description="Assign a field officer responsible for addressing and resolving this civic complaint."
      >
        <form onSubmit={handleAssignSubmit} className="space-y-4 text-xs">
          {actionError && (
            <div className="p-3 bg-red-50 text-red-700 rounded-lg border border-red-200">
              {actionError}
            </div>
          )}

          <div>
            <label className="block font-semibold text-slate-700 mb-1">
              Select Field Officer *
            </label>
            <select
              value={selectedOfficerId}
              onChange={(e) => setSelectedOfficerId(e.target.value)}
              required
              className="w-full px-3 py-2 border border-slate-300 rounded-lg text-xs focus:ring-2 focus:ring-blue-500 focus:outline-none bg-white"
            >
              <option value="">-- Choose an authorized officer --</option>
              {officers.map((off) => (
                <option key={off.id} value={off.id}>
                  {off.firstName} {off.lastName} ({off.email})
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block font-semibold text-slate-700 mb-1">
              Dispatch Instructions / Remarks
            </label>
            <textarea
              rows={3}
              value={assignRemarks}
              onChange={(e) => setAssignRemarks(e.target.value)}
              placeholder="Provide priority instructions, safety advisories, or repair notes..."
              className="w-full px-3 py-2 border border-slate-300 rounded-lg text-xs focus:ring-2 focus:ring-blue-500 focus:outline-none"
            />
          </div>

          <div className="flex justify-end space-x-2 pt-2 border-t border-slate-100">
            <Button
              type="button"
              variant="outline"
              onClick={() => setIsAssignModalOpen(false)}
            >
              Cancel
            </Button>
            <Button type="submit" variant="primary" isLoading={isAssigning}>
              Confirm Dispatch
            </Button>
          </div>
        </form>
      </Modal>

      {/* Update Status Modal */}
      <Modal
        isOpen={isStatusModalOpen}
        onClose={() => {
          setIsStatusModalOpen(false);
          setSelectedIssue(null);
          setActionError(null);
        }}
        title={`Update Status — ${selectedIssue?.issueReference || selectedIssue?.title}`}
        description="Transition issue through official lifecycle state machine."
      >
        <form onSubmit={handleStatusSubmit} className="space-y-4 text-xs">
          {actionError && (
            <div className="p-3 bg-red-50 text-red-700 rounded-lg border border-red-200">
              {actionError}
            </div>
          )}

          <div>
            <label className="block font-semibold text-slate-700 mb-1">
              Target Lifecycle Status *
            </label>
            <select
              value={nextStatus}
              onChange={(e) => setNextStatus(e.target.value as IssueStatus)}
              className="w-full px-3 py-2 border border-slate-300 rounded-lg text-xs focus:ring-2 focus:ring-blue-500 focus:outline-none bg-white"
            >
              <option value="ACKNOWLEDGED">ACKNOWLEDGED — Complaint vetted and logged</option>
              <option value="IN_PROGRESS">IN_PROGRESS — Field crew actively remediating</option>
              <option value="RESOLVED">RESOLVED — Repair complete, pending verification</option>
              <option value="CLOSED">CLOSED — Complaint concluded and verified</option>
            </select>
          </div>

          <div>
            <label className="block font-semibold text-slate-700 mb-1">
              Resolution Remarks / Audit Notes
            </label>
            <textarea
              rows={3}
              value={statusRemarks}
              onChange={(e) => setStatusRemarks(e.target.value)}
              placeholder="State what work was performed, why status changed, or closure remarks..."
              className="w-full px-3 py-2 border border-slate-300 rounded-lg text-xs focus:ring-2 focus:ring-blue-500 focus:outline-none"
            />
          </div>

          <div className="flex justify-end space-x-2 pt-2 border-t border-slate-100">
            <Button
              type="button"
              variant="outline"
              onClick={() => setIsStatusModalOpen(false)}
            >
              Cancel
            </Button>
            <Button type="submit" variant="primary" isLoading={isUpdatingStatus}>
              Save Status Transition
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
