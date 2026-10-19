import React, { useEffect, useState } from 'react';
import { wardsApi } from '../api';
import { Ward } from '../types/ward';
import { Card, CardHeader, CardContent } from '../components/ui/Card';
import { LoadingSpinner } from '../components/ui/LoadingSpinner';
import { Button } from '../components/ui/Button';
import { Modal } from '../components/ui/Modal';
import { Plus, Edit2, Trash2, Map } from 'lucide-react';

export const Wards: React.FC = () => {
  const [wards, setWards] = useState<Ward[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [editingWard, setEditingWard] = useState<Ward | null>(null);

  // Form state
  const [name, setName] = useState<string>('');
  const [wardNumber, setWardNumber] = useState<number | ''>('');
  const [code, setCode] = useState<string>('');
  const [boundaryWkt, setBoundaryWkt] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const fetchWards = async () => {
    setIsLoading(true);
    try {
      const data = await wardsApi.list();
      setWards(data);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchWards();
  }, []);

  const openCreateModal = () => {
    setEditingWard(null);
    setName('');
    setWardNumber(wards.length + 1);
    setCode(`WRD-00${wards.length + 1}`);
    setBoundaryWkt('POLYGON((77.20 28.60, 77.25 28.60, 77.25 28.65, 77.20 28.65, 77.20 28.60))');
    setErrorMessage(null);
    setIsModalOpen(true);
  };

  const openEditModal = (ward: Ward) => {
    setEditingWard(ward);
    setName(ward.name);
    setWardNumber(ward.wardNumber);
    setCode(ward.code);
    setBoundaryWkt(ward.boundaryWkt || '');
    setErrorMessage(null);
    setIsModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setErrorMessage(null);
    try {
      if (editingWard) {
        await wardsApi.update(editingWard.id, {
          name,
          wardNumber: Number(wardNumber),
          code,
          boundaryWkt,
        });
      } else {
        await wardsApi.create({
          name,
          wardNumber: Number(wardNumber),
          code,
          boundaryWkt,
        });
      }
      setIsModalOpen(false);
      await fetchWards();
    } catch (err: unknown) {
      setErrorMessage(
        (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail ||
          'Failed to save ward. Please verify PostGIS WKT polygon format.'
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Are you sure you want to delete this municipal ward?')) return;
    try {
      await wardsApi.delete(id);
      await fetchWards();
    } catch {
      alert('Could not delete ward. Complaints may be associated with it.');
    }
  };

  if (isLoading) {
    return <LoadingSpinner message="Loading municipal wards & spatial boundaries..." />;
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Wards & Boundaries</h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Manage municipal administrative zones and PostGIS polygon boundaries
          </p>
        </div>
        <Button onClick={openCreateModal} variant="primary" size="sm" className="flex items-center gap-1.5">
          <Plus className="w-4 h-4" /> Add Municipal Ward
        </Button>
      </div>

      <Card>
        <CardHeader
          title={`Registered Administrative Wards (${wards.length})`}
          subtitle="Enables automated geospatial reverse-lookup on citizen issue geotags"
        />
        {wards.length === 0 ? (
          <CardContent className="text-center py-12 text-slate-400 text-xs">
            <Map className="w-8 h-8 mx-auto mb-2 text-slate-300" />
            No wards registered in the database.
          </CardContent>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-slate-500 uppercase tracking-wider font-semibold border-b border-slate-200">
                <tr>
                  <th className="px-4 py-3">Ward Name</th>
                  <th className="px-4 py-3">Ward #</th>
                  <th className="px-4 py-3">Administrative Code</th>
                  <th className="px-4 py-3">Spatial Polygon (WKT)</th>
                  <th className="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {wards.map((ward) => (
                  <tr key={ward.id} className="hover:bg-slate-50/75 transition-colors">
                    <td className="px-4 py-3 font-semibold text-slate-900">{ward.name}</td>
                    <td className="px-4 py-3 font-mono font-medium text-slate-700">
                      #{ward.wardNumber}
                    </td>
                    <td className="px-4 py-3 font-mono text-slate-600">{ward.code}</td>
                    <td className="px-4 py-3 font-mono text-[11px] text-slate-500 max-w-xs truncate">
                      {ward.boundaryWkt || 'Polygon boundary configured'}
                    </td>
                    <td className="px-4 py-3 text-right space-x-1 whitespace-nowrap">
                      <Button size="sm" variant="ghost" onClick={() => openEditModal(ward)}>
                        <Edit2 className="w-3.5 h-3.5" />
                      </Button>
                      <Button size="sm" variant="ghost" className="text-red-600 hover:text-red-800" onClick={() => handleDelete(ward.id)}>
                        <Trash2 className="w-3.5 h-3.5" />
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Ward Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingWard ? 'Edit Ward Boundary' : 'Register Municipal Ward'}
        description="Specify ward code and PostGIS WKT polygon boundary."
      >
        <form onSubmit={handleSubmit} className="space-y-3 text-xs">
          {errorMessage && (
            <div className="p-3 bg-red-50 text-red-700 rounded-lg border border-red-200">
              {errorMessage}
            </div>
          )}

          <div>
            <label className="block font-semibold text-slate-700 mb-1">Ward Name *</label>
            <input
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Ward 1 - Connaught Place"
              className="w-full px-3 py-2 border border-slate-300 rounded-lg"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-semibold text-slate-700 mb-1">Ward Number *</label>
              <input
                type="number"
                required
                value={wardNumber}
                onChange={(e) => setWardNumber(e.target.value === '' ? '' : Number(e.target.value))}
                placeholder="e.g. 1"
                className="w-full px-3 py-2 border border-slate-300 rounded-lg"
              />
            </div>
            <div>
              <label className="block font-semibold text-slate-700 mb-1">Ward Code *</label>
              <input
                type="text"
                required
                value={code}
                onChange={(e) => setCode(e.target.value)}
                placeholder="e.g. WRD-CP-01"
                className="w-full px-3 py-2 border border-slate-300 rounded-lg font-mono uppercase"
              />
            </div>
          </div>

          <div>
            <label className="block font-semibold text-slate-700 mb-1">
              PostGIS Boundary Polygon (WKT format) *
            </label>
            <textarea
              rows={3}
              required
              value={boundaryWkt}
              onChange={(e) => setBoundaryWkt(e.target.value)}
              placeholder="POLYGON((lng1 lat1, lng2 lat2, ...))"
              className="w-full px-3 py-2 border border-slate-300 rounded-lg font-mono text-[11px]"
            />
            <p className="text-[10px] text-slate-400 mt-1">
              Coordinate order: (longitude latitude). Used by PostGIS ST_Contains.
            </p>
          </div>

          <div className="flex justify-end space-x-2 pt-3 border-t border-slate-100">
            <Button variant="outline" type="button" onClick={() => setIsModalOpen(false)}>
              Cancel
            </Button>
            <Button variant="primary" type="submit" isLoading={isSubmitting}>
              {editingWard ? 'Save Changes' : 'Create Ward'}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
