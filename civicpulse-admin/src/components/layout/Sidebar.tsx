import React from 'react';
import { NavLink } from 'react-router-dom';
import { useAuthStore } from '../../store/authStore';
import {
  LayoutDashboard,
  AlertCircle,
  Users,
  Layers,
  Map,
  MapPin,
} from 'lucide-react';

export const Sidebar: React.FC = () => {
  const { user } = useAuthStore();
  const role = user?.role;

  const navItems = [
    {
      to: '/dashboard',
      label: 'Overview',
      icon: LayoutDashboard,
      roles: ['OFFICER', 'SUPERVISOR', 'ADMIN'],
    },
    {
      to: '/map',
      label: 'Complaints Map',
      icon: MapPin,
      roles: ['OFFICER', 'SUPERVISOR', 'ADMIN'],
    },
    {
      to: '/issues',
      label: 'Issues & Reports',
      icon: AlertCircle,
      roles: ['OFFICER', 'SUPERVISOR', 'ADMIN'],
    },
    {
      to: '/officers',
      label: 'Field Officers',
      icon: Users,
      roles: ['SUPERVISOR', 'ADMIN'],
    },
    {
      to: '/categories',
      label: 'Categories & SLAs',
      icon: Layers,
      roles: ['ADMIN'],
    },
    {
      to: '/wards',
      label: 'Wards & Boundaries',
      icon: Map,
      roles: ['ADMIN'],
    },
  ];

  const allowedNav = navItems.filter((item) => role && item.roles.includes(role));

  return (
    <aside className="w-64 bg-slate-900 text-slate-300 min-h-[calc(100vh-4rem)] flex flex-col justify-between py-6 px-4">
      <div className="space-y-1">
        <div className="px-3 pb-2 text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
          Management
        </div>
        {allowedNav.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `flex items-center space-x-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-blue-600 text-white shadow-sm'
                    : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                }`
              }
            >
              <Icon className="w-4 h-4" />
              <span>{item.label}</span>
            </NavLink>
          );
        })}
      </div>

      <div className="pt-4 border-t border-slate-800 px-3 text-[11px] text-slate-400">
        <div className="font-semibold text-slate-300">CivicPulse Smart City</div>
        <div>v1.0.0 • Connected to Spring Boot</div>
      </div>
    </aside>
  );
};
