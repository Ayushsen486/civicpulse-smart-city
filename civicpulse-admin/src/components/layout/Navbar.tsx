import React from 'react';
import { useAuthStore } from '../../store/authStore';
import { RoleBadge } from '../ui/Badge';
import { LogOut, User as UserIcon } from 'lucide-react';

export const Navbar: React.FC = () => {
  const { user, logout } = useAuthStore();

  return (
    <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between sticky top-0 z-30 shadow-sm">
      <div className="flex items-center space-x-3">
        <div className="w-9 h-9 rounded-lg bg-blue-600 flex items-center justify-center text-white font-bold text-lg shadow-sm">
          CP
        </div>
        <div>
          <h1 className="font-bold text-slate-900 text-base leading-tight">CivicPulse</h1>
          <p className="text-[10px] text-slate-500 font-medium uppercase tracking-wider">
            Operations & Triage Portal
          </p>
        </div>
      </div>

      <div className="flex items-center space-x-4">
        {user && (
          <div className="flex items-center space-x-3 pr-2">
            <div className="w-8 h-8 rounded-full bg-slate-100 border border-slate-300 flex items-center justify-center text-slate-600">
              <UserIcon className="w-4 h-4" />
            </div>
            <div className="text-left hidden sm:block">
              <div className="text-xs font-semibold text-slate-800">
                {user.firstName} {user.lastName}
              </div>
              <div className="text-[11px] text-slate-500">{user.email}</div>
            </div>
            <RoleBadge role={user.role} />
          </div>
        )}

        <button
          onClick={() => logout()}
          className="flex items-center space-x-1.5 px-3 py-1.5 rounded-lg text-xs font-medium text-slate-600 hover:text-red-600 hover:bg-red-50 border border-transparent hover:border-red-200 transition-colors"
          title="Sign out"
        >
          <LogOut className="w-4 h-4" />
          <span className="hidden sm:inline">Sign Out</span>
        </button>
      </div>
    </header>
  );
};
