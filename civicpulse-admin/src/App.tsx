import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { IssuesList } from './pages/IssuesList';
import { IssueDetail } from './pages/IssueDetail';
import { ComplaintsMap } from './pages/ComplaintsMap';
import { Officers } from './pages/Officers';
import { Categories } from './pages/Categories';
import { Wards } from './pages/Wards';
import { DashboardLayout } from './components/layout/DashboardLayout';
import { ProtectedRoute } from './components/layout/ProtectedRoute';

export const App: React.FC = () => {
  return (
    <BrowserRouter>
      <Routes>
        {/* Public login route */}
        <Route path="/login" element={<Login />} />

        {/* Protected administrative routes */}
        <Route element={<ProtectedRoute allowedRoles={['OFFICER', 'SUPERVISOR', 'ADMIN']} />}>
          <Route element={<DashboardLayout />}>
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/map" element={<ComplaintsMap />} />
            <Route path="/issues" element={<IssuesList />} />
            <Route path="/issues/:id" element={<IssueDetail />} />

            {/* Supervisor & Admin only */}
            <Route element={<ProtectedRoute allowedRoles={['SUPERVISOR', 'ADMIN']} />}>
              <Route path="/officers" element={<Officers />} />
            </Route>

            {/* Admin only */}
            <Route element={<ProtectedRoute allowedRoles={['ADMIN']} />}>
              <Route path="/categories" element={<Categories />} />
              <Route path="/wards" element={<Wards />} />
            </Route>
          </Route>
        </Route>

        {/* Fallback route */}
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  );
};

export default App;
