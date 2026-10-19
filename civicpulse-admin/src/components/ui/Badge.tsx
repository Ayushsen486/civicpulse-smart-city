import React from 'react';
import { IssueStatus, Priority } from '../../types/issue';
import { UserRole } from '../../types/auth';

interface StatusBadgeProps {
  status: IssueStatus;
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status }) => {
  const styles: Record<IssueStatus, { bg: string; text: string; label: string }> = {
    REPORTED: { bg: 'bg-slate-100 border-slate-300', text: 'text-slate-800', label: 'Reported' },
    ACKNOWLEDGED: { bg: 'bg-sky-100 border-sky-300', text: 'text-sky-800', label: 'Acknowledged' },
    ASSIGNED: { bg: 'bg-indigo-100 border-indigo-300', text: 'text-indigo-800', label: 'Assigned' },
    IN_PROGRESS: { bg: 'bg-amber-100 border-amber-300', text: 'text-amber-800', label: 'In Progress' },
    RESOLVED: { bg: 'bg-emerald-100 border-emerald-300', text: 'text-emerald-800', label: 'Resolved' },
    CLOSED: { bg: 'bg-zinc-200 border-zinc-400', text: 'text-zinc-800', label: 'Closed' },
  };

  const current = styles[status] || styles.REPORTED;

  return (
    <span
      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold border ${current.bg} ${current.text}`}
    >
      <span className="w-1.5 h-1.5 mr-1.5 rounded-full bg-current opacity-70"></span>
      {current.label}
    </span>
  );
};

interface PriorityBadgeProps {
  priority: Priority;
}

export const PriorityBadge: React.FC<PriorityBadgeProps> = ({ priority }) => {
  const styles: Record<Priority, { bg: string; text: string; label: string }> = {
    LOW: { bg: 'bg-blue-50 border-blue-200', text: 'text-blue-700', label: 'Low' },
    MEDIUM: { bg: 'bg-yellow-50 border-yellow-200', text: 'text-yellow-700', label: 'Medium' },
    HIGH: { bg: 'bg-orange-50 border-orange-200', text: 'text-orange-700', label: 'High' },
    CRITICAL: { bg: 'bg-rose-50 border-rose-300', text: 'text-rose-700 font-bold', label: 'Critical' },
  };

  const current = styles[priority] || styles.MEDIUM;

  return (
    <span
      className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium border ${current.bg} ${current.text}`}
    >
      {current.label}
    </span>
  );
};

interface RoleBadgeProps {
  role: UserRole;
}

export const RoleBadge: React.FC<RoleBadgeProps> = ({ role }) => {
  const styles: Record<UserRole, { bg: string; text: string }> = {
    ADMIN: { bg: 'bg-purple-100 text-purple-800 border-purple-200', text: 'Admin' },
    SUPERVISOR: { bg: 'bg-blue-100 text-blue-800 border-blue-200', text: 'Supervisor' },
    OFFICER: { bg: 'bg-teal-100 text-teal-800 border-teal-200', text: 'Field Officer' },
    CITIZEN: { bg: 'bg-gray-100 text-gray-800 border-gray-200', text: 'Citizen' },
  };

  const current = styles[role] || styles.CITIZEN;

  return (
    <span
      className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold border ${current.bg}`}
    >
      {current.text}
    </span>
  );
};
