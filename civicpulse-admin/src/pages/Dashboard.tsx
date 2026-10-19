import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { issuesApi, categoriesApi, wardsApi } from '../api';
import { Issue, IssueStatistics } from '../types/issue';
import { Category } from '../types/category';
import { Ward } from '../types/ward';
import { Card, CardHeader, CardContent } from '../components/ui/Card';
import { StatusBadge, PriorityBadge } from '../components/ui/Badge';
import { LoadingSpinner } from '../components/ui/LoadingSpinner';
import { Button } from '../components/ui/Button';
import {
  AlertTriangle,
  Clock,
  CheckCircle2,
  ListFilter,
  ArrowRight,
  TrendingUp,
  UserCheck,
} from 'lucide-react';
import { format } from 'date-fns';

export const Dashboard: React.FC = () => {
  const [issues, setIssues] = useState<Issue[]>([]);
  const [stats, setStats] = useState<IssueStatistics | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [wards, setWards] = useState<Ward[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      setIsLoading(true);
      setError(null);
      try {
        const [issuesRes, statsRes, catsRes, wardsRes] = await Promise.all([
          issuesApi.list({ size: 10 }),
          issuesApi.getStatistics().catch(() => null),
          categoriesApi.list(),
          wardsApi.list(),
        ]);
        setIssues(issuesRes.content);
        setStats(statsRes);
        setCategories(catsRes);
        setWards(wardsRes);
      } catch {
        setError('Failed to fetch operational data from the backend. Please check server connectivity.');
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  if (isLoading) {
    return <LoadingSpinner message="Loading operational dashboard..." />;
  }

  if (error) {
    return (
      <div className="p-6 bg-red-50 border border-red-200 rounded-xl text-red-700">
        <h3 className="font-semibold text-base mb-1">Operational Connection Error</h3>
        <p className="text-sm">{error}</p>
        <Button
          variant="outline"
          className="mt-4"
          onClick={() => window.location.reload()}
        >
          Retry Connection
        </Button>
      </div>
    );
  }

  // Derive counts from system statistics or fallback
  const totalElements = stats ? stats.totalIssues : issues.length;
  const criticalCount = stats ? stats.highPriorityCount : issues.filter((i) => i.priority === 'CRITICAL' || i.priority === 'HIGH').length;
  const inProgressCount = stats ? (stats.assignedCount + stats.inProgressCount) : issues.filter((i) => i.status === 'IN_PROGRESS' || i.status === 'ASSIGNED').length;
  const resolvedCount = stats ? (stats.resolvedCount + stats.closedCount) : issues.filter((i) => i.status === 'RESOLVED' || i.status === 'CLOSED').length;
  const slaBreachedCount = stats ? stats.slaBreachedCount : issues.filter((i) => i.slaBreached).length;

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Operations Overview</h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Real-time complaint triage and municipal service resolution metrics
          </p>
        </div>
        <div className="flex items-center space-x-3">
          <Link to="/issues">
            <Button variant="primary" size="sm" className="flex items-center gap-1.5">
              <ListFilter className="w-4 h-4" /> View All Issues
            </Button>
          </Link>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="flex items-center space-x-4">
            <div className="w-12 h-12 rounded-xl bg-blue-100 text-blue-700 flex items-center justify-center">
              <TrendingUp className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs font-medium text-slate-500">Total Registered</p>
              <h3 className="text-2xl font-bold text-slate-900">{totalElements}</h3>
              <p className="text-[11px] text-slate-400">across all city wards</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="flex items-center space-x-4">
            <div className="w-12 h-12 rounded-xl bg-amber-100 text-amber-700 flex items-center justify-center">
              <Clock className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs font-medium text-slate-500">Active / In-Flight</p>
              <h3 className="text-2xl font-bold text-slate-900">{inProgressCount}</h3>
              <p className="text-[11px] text-amber-600 font-medium">Assigned & In Progress</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="flex items-center space-x-4">
            <div className="w-12 h-12 rounded-xl bg-red-100 text-red-700 flex items-center justify-center">
              <AlertTriangle className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs font-medium text-slate-500">Urgent Hazards</p>
              <h3 className="text-2xl font-bold text-slate-900">{criticalCount}</h3>
              <p className="text-[11px] text-red-600 font-medium">High / Critical priority</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="flex items-center space-x-4">
            <div className="w-12 h-12 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center">
              <CheckCircle2 className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs font-medium text-slate-500">Resolved / Closed</p>
              <h3 className="text-2xl font-bold text-slate-900">{resolvedCount}</h3>
              <p className="text-[11px] text-emerald-600 font-medium">Completed complaints</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* SLA Alert banner if any breached */}
      {slaBreachedCount > 0 && (
        <div className="p-4 bg-rose-50 border border-rose-200 rounded-xl flex items-center justify-between text-rose-800 text-sm">
          <div className="flex items-center space-x-3">
            <AlertTriangle className="w-5 h-5 text-rose-600 flex-shrink-0" />
            <div>
              <span className="font-bold">{slaBreachedCount} issue(s) have breached SLA resolution targets!</span>
              <span className="text-xs ml-2 text-rose-700">Immediate supervisor attention required.</span>
            </div>
          </div>
          <Link to="/issues?priority=CRITICAL">
            <Button size="sm" variant="destructive">Inspect Breaches</Button>
          </Link>
        </div>
      )}

      {/* Main Grid: Recent Issues and Taxonomy summary */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Issues Table */}
        <div className="lg:col-span-2">
          <Card>
            <CardHeader
              title="Recent Complaints"
              subtitle="Latest citizen submissions requiring review or triage"
              action={
                <Link to="/issues" className="text-xs text-blue-600 hover:text-blue-800 flex items-center gap-1 font-medium">
                  View all <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              }
            />
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 text-slate-500 uppercase tracking-wider font-semibold border-b border-slate-200">
                  <tr>
                    <th className="px-4 py-3">Reference / Title</th>
                    <th className="px-4 py-3">Category</th>
                    <th className="px-4 py-3">Priority</th>
                    <th className="px-4 py-3">Status</th>
                    <th className="px-4 py-3">Reported</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {issues.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="text-center py-8 text-slate-400">
                        No issues reported yet.
                      </td>
                    </tr>
                  ) : (
                    issues.map((issue) => (
                      <tr key={issue.id} className="hover:bg-slate-50/75 transition-colors">
                        <td className="px-4 py-3 font-medium">
                          <Link
                            to={`/issues/${issue.id}`}
                            className="text-blue-600 hover:text-blue-800 font-semibold block"
                          >
                            {issue.issueReference || `#${issue.issueNumber}`}
                          </Link>
                          <span className="text-slate-800 truncate block max-w-xs">
                            {issue.title}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-slate-600">
                          {issue.categoryName}
                        </td>
                        <td className="px-4 py-3">
                          <PriorityBadge priority={issue.priority} />
                        </td>
                        <td className="px-4 py-3">
                          <StatusBadge status={issue.status} />
                        </td>
                        <td className="px-4 py-3 text-slate-500 whitespace-nowrap">
                          {issue.createdAt ? format(new Date(issue.createdAt), 'dd MMM yyyy') : '-'}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </Card>

          {/* Field Officer Workload & Dispatch Overview */}
          {stats && stats.officerWorkloads && stats.officerWorkloads.length > 0 && (
            <Card className="mt-6">
              <CardHeader
                title="Field Officer Dispatch & Workload"
                subtitle="Active complaint resolution load across assigned officers"
                action={
                  <div className="flex items-center gap-1.5 text-xs text-slate-500">
                    <UserCheck className="w-4 h-4 text-emerald-600" />
                    <span>{stats.officerWorkloads.length} Officers Registered</span>
                  </div>
                }
              />
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 text-slate-500 uppercase tracking-wider font-semibold border-b border-slate-200">
                    <tr>
                      <th className="px-4 py-3">Officer Name</th>
                      <th className="px-4 py-3">Email</th>
                      <th className="px-4 py-3 text-center">Active Issues</th>
                      <th className="px-4 py-3 text-center">Resolved Issues</th>
                      <th className="px-4 py-3 text-right">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {stats.officerWorkloads.map((officer) => (
                      <tr key={officer.officerId} className="hover:bg-slate-50">
                        <td className="px-4 py-3 font-semibold text-slate-900">
                          {officer.officerName}
                        </td>
                        <td className="px-4 py-3 text-slate-500 font-mono text-[11px]">
                          {officer.email}
                        </td>
                        <td className="px-4 py-3 text-center">
                          <span className={`inline-block px-2 py-0.5 rounded-full text-xs font-semibold ${
                            officer.activeIssuesCount > 5 
                              ? 'bg-rose-100 text-rose-700' 
                              : officer.activeIssuesCount > 0 
                                ? 'bg-amber-100 text-amber-700' 
                                : 'bg-slate-100 text-slate-600'
                          }`}>
                            {officer.activeIssuesCount} in-flight
                          </span>
                        </td>
                        <td className="px-4 py-3 text-center text-emerald-600 font-semibold">
                          {officer.resolvedIssuesCount}
                        </td>
                        <td className="px-4 py-3 text-right">
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-medium bg-emerald-50 text-emerald-700 border border-emerald-200">
                            Available
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </Card>
          )}
        </div>

        {/* Wards & Categories side breakdown */}
        <div className="space-y-6">
          <Card>
            <CardHeader
              title="Administrative Wards"
              subtitle={`${wards.length} municipal zones registered`}
            />
            <CardContent className="space-y-2">
              {wards.length === 0 ? (
                <p className="text-xs text-slate-400">No wards configured.</p>
              ) : (
                wards.slice(0, 6).map((ward) => (
                  <div
                    key={ward.id}
                    className="flex items-center justify-between p-2 rounded-lg bg-slate-50 border border-slate-100 text-xs"
                  >
                    <div>
                      <span className="font-semibold text-slate-800">{ward.name}</span>
                      <span className="text-slate-400 ml-1.5 font-mono">({ward.code})</span>
                    </div>
                    <span className="text-slate-500 text-[11px]">Ward #{ward.wardNumber}</span>
                  </div>
                ))
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader
              title="Taxonomy & Categories"
              subtitle={`${categories.length} civic domains active`}
            />
            <CardContent className="space-y-2">
              {categories.slice(0, 5).map((cat) => (
                <div
                  key={cat.id}
                  className="flex items-center justify-between p-2 rounded-lg bg-slate-50 border border-slate-100 text-xs"
                >
                  <span className="font-medium text-slate-800">{cat.name}</span>
                  <span className="text-[11px] text-slate-500 font-mono">
                    {cat.slaHoursOverride ? `${cat.slaHoursOverride}h SLA` : 'Standard SLA'}
                  </span>
                </div>
              ))}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
};
