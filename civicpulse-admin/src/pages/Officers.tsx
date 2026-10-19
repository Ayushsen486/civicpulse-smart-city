import React, { useEffect, useState } from 'react';
import { usersApi } from '../api';
import { User } from '../types/auth';
import { Card, CardHeader, CardContent } from '../components/ui/Card';
import { LoadingSpinner } from '../components/ui/LoadingSpinner';
import { RoleBadge } from '../components/ui/Badge';
import { Users, Mail, Phone, Calendar } from 'lucide-react';
import { format } from 'date-fns';

export const Officers: React.FC = () => {
  const [officers, setOfficers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchOfficers = async () => {
      setIsLoading(true);
      try {
        const res = await usersApi.getOfficers(0, 50);
        setOfficers(res.content);
      } catch {
        setError('Failed to fetch officer queue from the backend.');
      } finally {
        setIsLoading(false);
      }
    };
    fetchOfficers();
  }, []);

  if (isLoading) {
    return <LoadingSpinner message="Loading field officers directory..." />;
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Field Officers Directory</h1>
        <p className="text-xs text-slate-500 mt-0.5">
          Authorized municipal personnel available for physical inspection and dispatch
        </p>
      </div>

      {error && (
        <div className="p-4 bg-red-50 text-red-700 text-xs rounded-xl border border-red-200">
          {error}
        </div>
      )}

      <Card>
        <CardHeader
          title={`Available Officers (${officers.length})`}
          subtitle="Real-time personnel queue from Spring Boot /users/officers"
        />
        {officers.length === 0 ? (
          <CardContent className="text-center py-12 text-slate-400 text-xs">
            <Users className="w-8 h-8 mx-auto mb-2 text-slate-300" />
            No field officers currently registered.
          </CardContent>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-slate-500 uppercase tracking-wider font-semibold border-b border-slate-200">
                <tr>
                  <th className="px-4 py-3">Officer Name</th>
                  <th className="px-4 py-3">Email Address</th>
                  <th className="px-4 py-3">Phone</th>
                  <th className="px-4 py-3">Role</th>
                  <th className="px-4 py-3">Status</th>
                  <th className="px-4 py-3">Registered</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {officers.map((off) => (
                  <tr key={off.id} className="hover:bg-slate-50/75 transition-colors">
                    <td className="px-4 py-3 font-semibold text-slate-900">
                      {off.firstName} {off.lastName}
                    </td>
                    <td className="px-4 py-3 text-slate-600">
                      <div className="flex items-center gap-1.5">
                        <Mail className="w-3.5 h-3.5 text-slate-400" />
                        {off.email}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-slate-600">
                      {off.phone ? (
                        <div className="flex items-center gap-1.5">
                          <Phone className="w-3.5 h-3.5 text-slate-400" />
                          {off.phone}
                        </div>
                      ) : (
                        <span className="text-slate-400">-</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <RoleBadge role={off.role} />
                    </td>
                    <td className="px-4 py-3">
                      <span className="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-medium bg-emerald-100 text-emerald-800">
                        Active for Dispatch
                      </span>
                    </td>
                    <td className="px-4 py-3 text-slate-500">
                      {off.createdAt ? (
                        <div className="flex items-center gap-1">
                          <Calendar className="w-3 h-3 text-slate-400" />
                          {format(new Date(off.createdAt), 'dd MMM yyyy')}
                        </div>
                      ) : (
                        '-'
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
};
