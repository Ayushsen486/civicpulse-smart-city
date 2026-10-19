import React, { useEffect, useState } from 'react';
import { categoriesApi } from '../api';
import { Category } from '../types/category';
import { Priority } from '../types/issue';
import { Card, CardHeader, CardContent } from '../components/ui/Card';
import { LoadingSpinner } from '../components/ui/LoadingSpinner';
import { Button } from '../components/ui/Button';
import { Modal } from '../components/ui/Modal';
import { PriorityBadge } from '../components/ui/Badge';
import { Plus, Edit2, Trash2, Layers } from 'lucide-react';

export const Categories: React.FC = () => {
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);

  // Form state
  const [name, setName] = useState<string>('');
  const [slug, setSlug] = useState<string>('');
  const [description, setDescription] = useState<string>('');
  const [color, setColor] = useState<string>('#3B82F6');
  const [defaultPriority, setDefaultPriority] = useState<Priority>('MEDIUM');
  const [slaHoursOverride, setSlaHoursOverride] = useState<number | ''>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const fetchCategories = async () => {
    setIsLoading(true);
    try {
      const data = await categoriesApi.list(false, false);
      setCategories(data);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const openCreateModal = () => {
    setEditingCategory(null);
    setName('');
    setSlug('');
    setDescription('');
    setColor('#3B82F6');
    setDefaultPriority('MEDIUM');
    setSlaHoursOverride('');
    setErrorMessage(null);
    setIsModalOpen(true);
  };

  const openEditModal = (cat: Category) => {
    setEditingCategory(cat);
    setName(cat.name);
    setSlug(cat.slug);
    setDescription(cat.description || '');
    setColor(cat.color || '#3B82F6');
    setDefaultPriority(cat.defaultPriority);
    setSlaHoursOverride(cat.slaHoursOverride ?? '');
    setErrorMessage(null);
    setIsModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setErrorMessage(null);
    try {
      if (editingCategory) {
        await categoriesApi.update(editingCategory.id, {
          name,
          description,
          color,
          defaultPriority,
          slaHoursOverride: slaHoursOverride === '' ? undefined : Number(slaHoursOverride),
        });
      } else {
        await categoriesApi.create({
          name,
          slug: slug.trim().toLowerCase().replace(/\s+/g, '-'),
          description,
          color,
          defaultPriority,
          slaHoursOverride: slaHoursOverride === '' ? undefined : Number(slaHoursOverride),
        });
      }
      setIsModalOpen(false);
      await fetchCategories();
    } catch (err: unknown) {
      setErrorMessage(
        (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail ||
          'Failed to save category. Please check inputs.'
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Are you sure you want to delete this category?')) return;
    try {
      await categoriesApi.delete(id);
      await fetchCategories();
    } catch {
      alert('Could not delete category. It may have associated complaints.');
    }
  };

  if (isLoading) {
    return <LoadingSpinner message="Loading categories and SLA configurations..." />;
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Categories & SLAs</h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Configure municipal grievance taxonomy, default severity, and resolution SLA deadlines
          </p>
        </div>
        <Button onClick={openCreateModal} variant="primary" size="sm" className="flex items-center gap-1.5">
          <Plus className="w-4 h-4" /> Add Category
        </Button>
      </div>

      <Card>
        <CardHeader
          title={`Active Categories (${categories.length})`}
          subtitle="Governs complaint routing and SLA deadlines"
        />
        {categories.length === 0 ? (
          <CardContent className="text-center py-12 text-slate-400 text-xs">
            <Layers className="w-8 h-8 mx-auto mb-2 text-slate-300" />
            No categories defined yet.
          </CardContent>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-slate-500 uppercase tracking-wider font-semibold border-b border-slate-200">
                <tr>
                  <th className="px-4 py-3">Category Name</th>
                  <th className="px-4 py-3">Slug</th>
                  <th className="px-4 py-3">Default Priority</th>
                  <th className="px-4 py-3">Resolution SLA</th>
                  <th className="px-4 py-3">Color</th>
                  <th className="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {categories.map((cat) => (
                  <tr key={cat.id} className="hover:bg-slate-50/75 transition-colors">
                    <td className="px-4 py-3 font-semibold text-slate-900">
                      {cat.name}
                      {cat.description && (
                        <span className="block text-[11px] text-slate-400 font-normal">
                          {cat.description}
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3 font-mono text-slate-600">{cat.slug}</td>
                    <td className="px-4 py-3">
                      <PriorityBadge priority={cat.defaultPriority} />
                    </td>
                    <td className="px-4 py-3 font-medium text-slate-800">
                      {cat.slaHoursOverride ? `${cat.slaHoursOverride} hours` : 'Standard Platform SLA'}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1.5">
                        <span
                          className="w-3.5 h-3.5 rounded-full border border-slate-300"
                          style={{ backgroundColor: cat.color || '#3B82F6' }}
                        />
                        <span className="text-[11px] text-slate-500 font-mono">{cat.color || '#3B82F6'}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-right space-x-1 whitespace-nowrap">
                      <Button size="sm" variant="ghost" onClick={() => openEditModal(cat)}>
                        <Edit2 className="w-3.5 h-3.5" />
                      </Button>
                      <Button size="sm" variant="ghost" className="text-red-600 hover:text-red-800" onClick={() => handleDelete(cat.id)}>
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

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingCategory ? 'Edit Category' : 'Create New Category'}
        description="Configure taxonomy and resolution SLA deadline."
      >
        <form onSubmit={handleSubmit} className="space-y-3 text-xs">
          {errorMessage && (
            <div className="p-3 bg-red-50 text-red-700 rounded-lg border border-red-200">
              {errorMessage}
            </div>
          )}

          <div>
            <label className="block font-semibold text-slate-700 mb-1">Name *</label>
            <input
              type="text"
              required
              value={name}
              onChange={(e) => {
                setName(e.target.value);
                if (!editingCategory) {
                  setSlug(e.target.value.toLowerCase().replace(/\s+/g, '-'));
                }
              }}
              placeholder="e.g. Potholes & Road Damage"
              className="w-full px-3 py-2 border border-slate-300 rounded-lg"
            />
          </div>

          {!editingCategory && (
            <div>
              <label className="block font-semibold text-slate-700 mb-1">Slug *</label>
              <input
                type="text"
                required
                value={slug}
                onChange={(e) => setSlug(e.target.value)}
                placeholder="e.g. road-damage"
                className="w-full px-3 py-2 border border-slate-300 rounded-lg font-mono"
              />
            </div>
          )}

          <div>
            <label className="block font-semibold text-slate-700 mb-1">Description</label>
            <textarea
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Brief explanation for triage team..."
              className="w-full px-3 py-2 border border-slate-300 rounded-lg"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-semibold text-slate-700 mb-1">Default Priority</label>
              <select
                value={defaultPriority}
                onChange={(e) => setDefaultPriority(e.target.value as Priority)}
                className="w-full px-3 py-2 border border-slate-300 rounded-lg bg-white"
              >
                <option value="LOW">LOW</option>
                <option value="MEDIUM">MEDIUM</option>
                <option value="HIGH">HIGH</option>
                <option value="CRITICAL">CRITICAL</option>
              </select>
            </div>

            <div>
              <label className="block font-semibold text-slate-700 mb-1">SLA Hours</label>
              <input
                type="number"
                value={slaHoursOverride}
                onChange={(e) => setSlaHoursOverride(e.target.value === '' ? '' : Number(e.target.value))}
                placeholder="e.g. 48"
                className="w-full px-3 py-2 border border-slate-300 rounded-lg"
              />
            </div>
          </div>

          <div className="flex justify-end space-x-2 pt-3 border-t border-slate-100">
            <Button variant="outline" type="button" onClick={() => setIsModalOpen(false)}>
              Cancel
            </Button>
            <Button variant="primary" type="submit" isLoading={isSubmitting}>
              {editingCategory ? 'Save Changes' : 'Create Category'}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
