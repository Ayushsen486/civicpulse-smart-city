import React, { useEffect, useRef, useState, useMemo, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import L from 'leaflet';
import {
  CheckCircle2,
  UserCheck,
  RefreshCw,
  Maximize2,
  Search,
  MapPin,
  Layers,
  Sparkles,
  ExternalLink,
  X,
  Compass,
} from 'lucide-react';
import { issuesApi, categoriesApi, wardsApi, usersApi } from '../api';
import { Issue, IssueStatus } from '../types/issue';
import { Category } from '../types/category';
import { Ward } from '../types/ward';
import { User as OfficerUser } from '../types/auth';

// Tile provider configurations
const TILE_LAYERS = {
  googleRoads: {
    name: 'Google Maps (Roads)',
    url: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
    subdomains: ['0', '1', '2', '3'],
    attribution: '&copy; Google Maps',
    maxZoom: 20,
  },
  googleHybrid: {
    name: 'Google Maps (Satellite Hybrid)',
    url: 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
    subdomains: ['0', '1', '2', '3'],
    attribution: '&copy; Google Maps Satellite',
    maxZoom: 20,
  },
  googleTerrain: {
    name: 'Google Maps (Terrain)',
    url: 'https://mt{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}',
    subdomains: ['0', '1', '2', '3'],
    attribution: '&copy; Google Maps Terrain',
    maxZoom: 20,
  },
  osm: {
    name: 'OpenStreetMap (Standard)',
    url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
    attribution: '&copy; OpenStreetMap contributors',
    maxZoom: 19,
  },
  esriSatellite: {
    name: 'Esri Satellite High-Res',
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    subdomains: [] as string[],
    attribution: 'Tiles &copy; Esri World Imagery',
    maxZoom: 19,
  },
};

// Stage configuration metadata
const STAGE_CONFIG: Record<
  IssueStatus,
  {
    label: string;
    bg: string;
    text: string;
    border: string;
    hex: string;
    symbol: string;
    pulse: boolean;
  }
> = {
  REPORTED: {
    label: 'Reported',
    bg: 'bg-red-50',
    text: 'text-red-700',
    border: 'border-red-500',
    hex: '#EF4444',
    symbol: '!',
    pulse: true,
  },
  ACKNOWLEDGED: {
    label: 'Acknowledged',
    bg: 'bg-amber-50',
    text: 'text-amber-700',
    border: 'border-amber-500',
    hex: '#F59E0B',
    symbol: '👁',
    pulse: false,
  },
  ASSIGNED: {
    label: 'Assigned',
    bg: 'bg-indigo-50',
    text: 'text-indigo-700',
    border: 'border-indigo-500',
    hex: '#6366F1',
    symbol: '👤',
    pulse: false,
  },
  IN_PROGRESS: {
    label: 'In Progress',
    bg: 'bg-blue-50',
    text: 'text-blue-700',
    border: 'border-blue-500',
    hex: '#3B82F6',
    symbol: '⚙',
    pulse: true,
  },
  RESOLVED: {
    label: 'Resolved',
    bg: 'bg-emerald-50',
    text: 'text-emerald-700',
    border: 'border-emerald-500',
    hex: '#10B981',
    symbol: '✓',
    pulse: false,
  },
  CLOSED: {
    label: 'Closed',
    bg: 'bg-slate-100',
    text: 'text-slate-700',
    border: 'border-slate-400',
    hex: '#64748B',
    symbol: '🔒',
    pulse: false,
  },
};

// Haversine distance calculator in meters
function getDistanceMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371e3; // Earth radius in meters
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

export const ComplaintsMap: React.FC = () => {
  const navigate = useNavigate();
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markersLayerRef = useRef<L.LayerGroup | null>(null);
  const activeTileLayerRef = useRef<L.TileLayer | null>(null);

  const [issues, setIssues] = useState<Issue[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [wards, setWards] = useState<Ward[]>([]);
  const [officers, setOfficers] = useState<OfficerUser[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);

  // Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [priorityFilter, setPriorityFilter] = useState<string>('ALL');
  const [categoryFilter, setCategoryFilter] = useState<string>('ALL');
  const [wardFilter, setWardFilter] = useState<string>('ALL');
  const [activeTileKey, setActiveTileKey] = useState<keyof typeof TILE_LAYERS>('googleRoads');

  // Selected complaint for drawer inspection
  const [selectedIssue, setSelectedIssue] = useState<Issue | null>(null);
  const [actionSuccessMessage, setActionSuccessMessage] = useState<string | null>(null);

  // Load complaints and metadata
  const fetchData = useCallback(async () => {
    setIsRefreshing(true);
    try {
      const [issuesRes, catRes, wardRes, officersRes] = await Promise.all([
        issuesApi.list({ size: 100 }),
        categoriesApi.list(),
        wardsApi.list(),
        usersApi.getOfficers(0, 50),
      ]);

      setIssues(issuesRes.content || []);
      setCategories(catRes || []);
      setWards(wardRes || []);
      setOfficers(officersRes.content || []);
    } catch (err) {
      console.error('Failed to load map data:', err);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Filtered issues
  const filteredIssues = useMemo(() => {
    return issues.filter((issue) => {
      // Must have valid coordinates
      if (typeof issue.latitude !== 'number' || typeof issue.longitude !== 'number') {
        return false;
      }
      if (isNaN(issue.latitude) || isNaN(issue.longitude)) return false;

      // Search match
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchesTitle = issue.title.toLowerCase().includes(q);
        const matchesRef = (issue.issueReference || '').toLowerCase().includes(q);
        const matchesAddress = (issue.address || '').toLowerCase().includes(q);
        const matchesWard = (issue.wardName || '').toLowerCase().includes(q);
        const matchesCat = (issue.categoryName || '').toLowerCase().includes(q);
        if (!matchesTitle && !matchesRef && !matchesAddress && !matchesWard && !matchesCat) {
          return false;
        }
      }

      // Status filter
      if (statusFilter !== 'ALL' && issue.status !== statusFilter) return false;

      // Priority filter
      if (priorityFilter !== 'ALL' && issue.priority !== priorityFilter) return false;

      // Category filter
      if (categoryFilter !== 'ALL' && issue.categoryId !== categoryFilter) return false;

      // Ward filter
      if (wardFilter !== 'ALL' && issue.wardId !== wardFilter) return false;

      return true;
    });
  }, [issues, searchQuery, statusFilter, priorityFilter, categoryFilter, wardFilter]);

  // Stage counts for HUD
  const stageCounts = useMemo(() => {
    const counts: Record<string, number> = {
      ALL: issues.length,
      REPORTED: 0,
      ASSIGNED: 0,
      IN_PROGRESS: 0,
      RESOLVED: 0,
    };
    for (const i of issues) {
      if (counts[i.status] !== undefined) {
        counts[i.status]++;
      }
    }
    return counts;
  }, [issues]);

  // Compute nearby complaints for selected issue (Area Suggestion)
  const nearbyComplaints = useMemo(() => {
    if (!selectedIssue) return [];
    return issues
      .filter((i) => i.id !== selectedIssue.id && typeof i.latitude === 'number' && typeof i.longitude === 'number')
      .map((i) => ({
        issue: i,
        distanceMeters: Math.round(
          getDistanceMeters(selectedIssue.latitude, selectedIssue.longitude, i.latitude, i.longitude)
        ),
      }))
      .filter((item) => item.distanceMeters <= 1500) // Within 1.5 km
      .sort((a, b) => a.distanceMeters - b.distanceMeters);
  }, [selectedIssue, issues]);

  // Initialize Leaflet Map
  useEffect(() => {
    if (!mapContainerRef.current) return;
    if (mapInstanceRef.current) return;

    // Default center at Delhi / central India
    const map = L.map(mapContainerRef.current, {
      center: [28.6139, 77.209],
      zoom: 12,
      zoomControl: false,
      attributionControl: true,
    });

    // Custom zoom control in bottom-left
    L.control.zoom({ position: 'bottomleft' }).addTo(map);

    // Initial tile layer: Google Maps Roads
    const initialTile = L.tileLayer(TILE_LAYERS.googleRoads.url, {
      attribution: TILE_LAYERS.googleRoads.attribution,
      subdomains: TILE_LAYERS.googleRoads.subdomains,
      maxZoom: TILE_LAYERS.googleRoads.maxZoom,
    }).addTo(map);

    activeTileLayerRef.current = initialTile;

    // Layer group for markers
    const markersLayer = L.layerGroup().addTo(map);
    markersLayerRef.current = markersLayer;

    mapInstanceRef.current = map;

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, []);

  // Update Tile Layer when tileKey changes
  useEffect(() => {
    if (!mapInstanceRef.current) return;
    if (activeTileLayerRef.current) {
      mapInstanceRef.current.removeLayer(activeTileLayerRef.current);
    }
    const tileConfig = TILE_LAYERS[activeTileKey];
    const newTileLayer = L.tileLayer(tileConfig.url, {
      attribution: tileConfig.attribution,
      subdomains: tileConfig.subdomains,
      maxZoom: tileConfig.maxZoom,
    }).addTo(mapInstanceRef.current);

    activeTileLayerRef.current = newTileLayer;
  }, [activeTileKey]);

  // Create Custom HTML Marker Icon
  const createMarkerIcon = (issue: Issue, isSelected: boolean) => {
    const config = STAGE_CONFIG[issue.status] || STAGE_CONFIG.REPORTED;
    const isCritical = issue.priority === 'CRITICAL';
    const markerColor = config.hex;

    const html = `
      <div class="relative group cursor-pointer" style="transform: translate(-50%, -100%);">
        ${
          config.pulse || isCritical
            ? `<div class="absolute -inset-2 rounded-full opacity-75 animate-ping" style="background-color: ${markerColor};"></div>`
            : ''
        }
        <div class="relative flex items-center justify-center w-10 h-10 rounded-full shadow-lg border-2 transition-all duration-200 ${
          isSelected
            ? 'scale-125 ring-4 ring-blue-400 border-white'
            : 'hover:scale-115 border-white group-hover:shadow-2xl'
        }" style="background-color: ${markerColor};">
          <span class="text-white font-black text-sm tracking-tight leading-none">${config.symbol}</span>
          ${
            isCritical
              ? `<span class="absolute -top-1 -right-1 w-3.5 h-3.5 bg-red-600 border border-white rounded-full flex items-center justify-center text-[8px] text-white font-bold">!</span>`
              : ''
          }
        </div>
        <div class="w-0 h-0 mx-auto border-l-4 border-r-4 border-t-6 border-l-transparent border-r-transparent shadow-sm" style="border-t-color: ${markerColor};"></div>
      </div>
    `;

    return L.divIcon({
      html,
      className: 'custom-leaflet-marker',
      iconSize: [40, 48],
      iconAnchor: [20, 48],
    });
  };

  // Render markers onto the map
  useEffect(() => {
    const map = mapInstanceRef.current;
    const markersLayer = markersLayerRef.current;
    if (!map || !markersLayer) return;

    markersLayer.clearLayers();

    const bounds = L.latLngBounds([]);

    filteredIssues.forEach((issue) => {
      const lat = issue.latitude;
      const lng = issue.longitude;
      const isSelected = selectedIssue?.id === issue.id;

      const marker = L.marker([lat, lng], {
        icon: createMarkerIcon(issue, isSelected),
        zIndexOffset: isSelected ? 1000 : issue.priority === 'CRITICAL' ? 500 : 100,
      });

      // Tooltip on hover
      marker.bindTooltip(
        `
        <div class="px-2 py-1 font-sans text-xs">
          <div class="font-bold text-slate-800">${issue.title}</div>
          <div class="text-[10px] text-slate-500 font-medium">${issue.categoryName} • ${issue.status}</div>
        </div>
      `,
        { direction: 'top', offset: [0, -42], opacity: 0.95 }
      );

      marker.on('click', () => {
        setSelectedIssue(issue);
        map.setView([lat, lng], Math.max(map.getZoom(), 15), { animate: true });
      });

      markersLayer.addLayer(marker);
      bounds.extend([lat, lng]);
    });

    // Auto-fit bounds if we have points and no specific issue is actively selected
    if (!selectedIssue && filteredIssues.length > 0 && bounds.isValid()) {
      map.fitBounds(bounds, { padding: [60, 60], maxZoom: 16 });
    }
  }, [filteredIssues, selectedIssue]);

  // Fit bounds helper
  const handleFitAll = () => {
    const map = mapInstanceRef.current;
    if (!map || filteredIssues.length === 0) return;
    const bounds = L.latLngBounds(filteredIssues.map((i) => [i.latitude, i.longitude]));
    if (bounds.isValid()) {
      map.fitBounds(bounds, { padding: [60, 60], maxZoom: 16 });
    }
  };

  // Quick Status Transition directly from Map
  const handleQuickStatusChange = async (newStatus: IssueStatus) => {
    if (!selectedIssue) return;
    try {
      const updated = await issuesApi.updateStatus(selectedIssue.id, newStatus, `Updated via Map Command Center`);
      setIssues((prev) => prev.map((i) => (i.id === updated.id ? updated : i)));
      setSelectedIssue(updated);
      setActionSuccessMessage(`Status updated to ${newStatus}`);
      setTimeout(() => setActionSuccessMessage(null), 3000);
    } catch (err) {
      console.error('Failed to update status:', err);
    }
  };

  // Quick Officer Assignment directly from Map
  const handleQuickAssign = async (officerId: string) => {
    if (!selectedIssue) return;
    try {
      const updated = await issuesApi.assignOfficer(selectedIssue.id, officerId);
      setIssues((prev) => prev.map((i) => (i.id === updated.id ? updated : i)));
      setSelectedIssue(updated);
      setActionSuccessMessage('Assigned officer updated');
      setTimeout(() => setActionSuccessMessage(null), 3000);
    } catch (err) {
      console.error('Failed to assign officer:', err);
    }
  };

  return (
    <div className="relative w-full h-[calc(100vh-4.25rem)] flex flex-col overflow-hidden bg-slate-900">
      {/* Top Floating Control Bar */}
      <div className="absolute top-4 left-4 right-4 z-[500] flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3 bg-white/95 backdrop-blur-md px-4 py-3 rounded-2xl shadow-xl border border-slate-200">
        {/* Title & Search */}
        <div className="flex items-center space-x-3 flex-1 min-w-[280px]">
          <div className="flex items-center space-x-2 text-blue-600 font-bold text-base whitespace-nowrap">
            <Compass className="w-5 h-5 text-blue-600 animate-pulse" />
            <span>Complaints Command Map</span>
          </div>
          <div className="relative flex-1 max-w-md">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Filter by title, reference #, ward..."
              className="w-full pl-9 pr-3 py-1.5 bg-slate-100 hover:bg-slate-200/80 focus:bg-white text-xs rounded-xl border border-slate-300/80 focus:ring-2 focus:ring-blue-500 focus:outline-none transition-all"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        </div>

        {/* Stage Filter Chips */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 md:pb-0 scrollbar-none">
          <button
            onClick={() => setStatusFilter('ALL')}
            className={`px-3 py-1 text-xs font-semibold rounded-lg transition-all ${
              statusFilter === 'ALL'
                ? 'bg-slate-900 text-white shadow-sm'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            All ({stageCounts.ALL})
          </button>
          <button
            onClick={() => setStatusFilter('REPORTED')}
            className={`px-2.5 py-1 text-xs font-semibold rounded-lg flex items-center space-x-1 transition-all ${
              statusFilter === 'REPORTED'
                ? 'bg-red-600 text-white shadow-sm'
                : 'bg-red-50 text-red-700 hover:bg-red-100'
            }`}
          >
            <span className="w-2 h-2 rounded-full bg-red-500 animate-ping mr-1" />
            <span>Reported ({stageCounts.REPORTED})</span>
          </button>
          <button
            onClick={() => setStatusFilter('ASSIGNED')}
            className={`px-2.5 py-1 text-xs font-semibold rounded-lg transition-all ${
              statusFilter === 'ASSIGNED'
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'bg-indigo-50 text-indigo-700 hover:bg-indigo-100'
            }`}
          >
            Assigned ({stageCounts.ASSIGNED})
          </button>
          <button
            onClick={() => setStatusFilter('IN_PROGRESS')}
            className={`px-2.5 py-1 text-xs font-semibold rounded-lg transition-all ${
              statusFilter === 'IN_PROGRESS'
                ? 'bg-blue-600 text-white shadow-sm'
                : 'bg-blue-50 text-blue-700 hover:bg-blue-100'
            }`}
          >
            In Progress ({stageCounts.IN_PROGRESS})
          </button>
          <button
            onClick={() => setStatusFilter('RESOLVED')}
            className={`px-2.5 py-1 text-xs font-semibold rounded-lg transition-all ${
              statusFilter === 'RESOLVED'
                ? 'bg-emerald-600 text-white shadow-sm'
                : 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100'
            }`}
          >
            Resolved ({stageCounts.RESOLVED})
          </button>
        </div>

        {/* Dropdowns & Actions */}
        <div className="flex items-center space-x-2">
          {/* Category Filter */}
          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="px-2.5 py-1.5 bg-slate-100 text-xs font-medium text-slate-700 rounded-lg border border-slate-300 focus:outline-none max-w-[130px] truncate"
          >
            <option value="ALL">All Categories</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>

          {/* Ward Filter */}
          <select
            value={wardFilter}
            onChange={(e) => setWardFilter(e.target.value)}
            className="px-2.5 py-1.5 bg-slate-100 text-xs font-medium text-slate-700 rounded-lg border border-slate-300 focus:outline-none max-w-[130px] truncate"
          >
            <option value="ALL">All Wards</option>
            {wards.map((w) => (
              <option key={w.id} value={w.id}>
                {w.name}
              </option>
            ))}
          </select>

          {/* Priority Filter */}
          <select
            value={priorityFilter}
            onChange={(e) => setPriorityFilter(e.target.value)}
            className="px-2.5 py-1.5 bg-slate-100 text-xs font-medium text-slate-700 rounded-lg border border-slate-300 focus:outline-none"
          >
            <option value="ALL">All Priorities</option>
            <option value="CRITICAL">🔴 Critical</option>
            <option value="HIGH">🟠 High</option>
            <option value="MEDIUM">🟡 Medium</option>
            <option value="LOW">🟢 Low</option>
          </select>

          {/* Map Layer Switcher */}
          <select
            value={activeTileKey}
            onChange={(e) => setActiveTileKey(e.target.value as keyof typeof TILE_LAYERS)}
            className="px-2.5 py-1.5 bg-slate-100 text-xs font-medium text-slate-700 rounded-lg border border-slate-300 focus:outline-none"
          >
            {Object.entries(TILE_LAYERS).map(([key, cfg]) => (
              <option key={key} value={key}>
                🗺️ {cfg.name}
              </option>
            ))}
          </select>

          {/* Fit Bounds */}
          <button
            onClick={handleFitAll}
            title="Fit all markers in view"
            className="p-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg border border-slate-300 transition-colors"
          >
            <Maximize2 className="w-4 h-4" />
          </button>

          {/* Refresh */}
          <button
            onClick={fetchData}
            title="Refresh complaint data"
            disabled={isRefreshing}
            className="p-1.5 bg-blue-50 hover:bg-blue-100 text-blue-600 rounded-lg border border-blue-200 transition-colors"
          >
            <RefreshCw className={`w-4 h-4 ${isRefreshing ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Loading Overlay */}
      {isLoading && (
        <div className="absolute inset-0 z-[600] bg-slate-900/60 backdrop-blur-sm flex flex-col items-center justify-center text-white">
          <RefreshCw className="w-8 h-8 text-blue-400 animate-spin mb-2" />
          <p className="text-sm font-semibold">Loading geospatial complaints...</p>
        </div>
      )}

      {/* Main Leaflet Map View */}
      <div ref={mapContainerRef} className="w-full h-full z-0" />

      {/* Floating Legend in Bottom-Right */}
      <div className="absolute bottom-5 right-5 z-[500] bg-white/95 backdrop-blur-md p-3 rounded-2xl shadow-xl border border-slate-200 max-w-xs text-xs">
        <div className="flex items-center justify-between pb-1.5 mb-1.5 border-b border-slate-200 font-bold text-slate-800">
          <span className="flex items-center gap-1.5">
            <Layers className="w-3.5 h-3.5 text-blue-600" /> Stage Symbols
          </span>
          <span className="text-[10px] text-slate-500 font-normal">{filteredIssues.length} visible</span>
        </div>
        <div className="grid grid-cols-2 gap-x-3 gap-y-1.5">
          {Object.entries(STAGE_CONFIG).map(([st, cfg]) => (
            <div key={st} className="flex items-center space-x-1.5">
              <span
                className="w-4 h-4 rounded-full flex items-center justify-center text-[10px] text-white font-bold"
                style={{ backgroundColor: cfg.hex }}
              >
                {cfg.symbol}
              </span>
              <span className="text-[11px] text-slate-700 font-medium truncate">{cfg.label}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Slide-in Complaint Area Intelligence Drawer */}
      {selectedIssue && (
        <div className="absolute top-20 right-4 bottom-5 w-full max-w-md z-[550] bg-white rounded-2xl shadow-2xl border border-slate-200 flex flex-col overflow-hidden animate-in slide-in-from-right duration-200">
          {/* Drawer Header */}
          <div className="p-4 bg-slate-900 text-white flex items-start justify-between">
            <div>
              <div className="flex items-center space-x-2">
                <span className="text-xs font-mono text-blue-300">
                  {selectedIssue.issueReference || `#${selectedIssue.issueNumber}`}
                </span>
                <span
                  className="px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider"
                  style={{
                    backgroundColor: `${STAGE_CONFIG[selectedIssue.status]?.hex}33`,
                    color: STAGE_CONFIG[selectedIssue.status]?.hex,
                    border: `1px solid ${STAGE_CONFIG[selectedIssue.status]?.hex}66`,
                  }}
                >
                  {STAGE_CONFIG[selectedIssue.status]?.symbol} {STAGE_CONFIG[selectedIssue.status]?.label}
                </span>
                <span
                  className={`px-1.5 py-0.5 rounded text-[10px] font-bold ${
                    selectedIssue.priority === 'CRITICAL'
                      ? 'bg-red-500/20 text-red-300 border border-red-500/40'
                      : selectedIssue.priority === 'HIGH'
                      ? 'bg-orange-500/20 text-orange-300 border border-orange-500/40'
                      : 'bg-slate-700 text-slate-300'
                  }`}
                >
                  {selectedIssue.priority}
                </span>
              </div>
              <h3 className="text-base font-bold text-white mt-1 leading-snug">{selectedIssue.title}</h3>
            </div>
            <button
              onClick={() => setSelectedIssue(null)}
              className="p-1 hover:bg-slate-800 text-slate-400 hover:text-white rounded-lg transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Action Notification Toast */}
          {actionSuccessMessage && (
            <div className="px-4 py-2 bg-emerald-50 text-emerald-800 border-b border-emerald-200 text-xs font-semibold flex items-center gap-1.5 animate-fadeIn">
              <CheckCircle2 className="w-4 h-4 text-emerald-600" />
              <span>{actionSuccessMessage}</span>
            </div>
          )}

          {/* Drawer Content */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {/* Description */}
            {selectedIssue.description && (
              <p className="text-xs text-slate-600 leading-relaxed bg-slate-50 p-2.5 rounded-xl border border-slate-200">
                {selectedIssue.description}
              </p>
            )}

            {/* Area Suggestion & Cluster Intelligence Box */}
            <div className="p-3 bg-gradient-to-br from-blue-50 to-indigo-50/60 rounded-xl border border-blue-200/80 space-y-2">
              <div className="flex items-center space-x-1.5 text-blue-900 font-bold text-xs">
                <Sparkles className="w-4 h-4 text-blue-600" />
                <span>Area Intelligence & Proximity Insights</span>
              </div>
              <p className="text-[11px] text-blue-950/80 leading-relaxed">
                {nearbyComplaints.length > 0 ? (
                  <>
                    <strong className="text-blue-900 font-semibold">{nearbyComplaints.length} other complaint(s)</strong>{' '}
                    recorded within 1.5 km of this location. Closest issue is{' '}
                    <span className="font-semibold">{nearbyComplaints[0].distanceMeters}m</span> away (
                    <em>{nearbyComplaints[0].issue.categoryName}</em>).
                  </>
                ) : (
                  <>
                    Isolated issue location. No other recent complaints recorded within 1.5 km of this coordinate.
                  </>
                )}
              </p>

              {/* Exact Coordinates */}
              <div className="flex items-center justify-between text-[11px] font-mono bg-white/80 p-2 rounded-lg border border-blue-200 text-slate-700">
                <span className="flex items-center gap-1 text-slate-500">
                  <MapPin className="w-3.5 h-3.5 text-blue-600" /> Coordinates:
                </span>
                <span className="font-semibold">
                  {selectedIssue.latitude.toFixed(6)}, {selectedIssue.longitude.toFixed(6)}
                </span>
              </div>
            </div>

            {/* Category, Ward, Reporter Details */}
            <div className="grid grid-cols-2 gap-2 text-xs">
              <div className="p-2.5 bg-slate-50 rounded-xl border border-slate-200">
                <div className="text-[10px] text-slate-400 font-medium uppercase">Category</div>
                <div className="font-semibold text-slate-800 truncate mt-0.5">{selectedIssue.categoryName}</div>
              </div>
              <div className="p-2.5 bg-slate-50 rounded-xl border border-slate-200">
                <div className="text-[10px] text-slate-400 font-medium uppercase">Ward & Zone</div>
                <div className="font-semibold text-slate-800 truncate mt-0.5">
                  {selectedIssue.wardName || 'Unassigned Ward'}
                </div>
              </div>
              <div className="p-2.5 bg-slate-50 rounded-xl border border-slate-200">
                <div className="text-[10px] text-slate-400 font-medium uppercase">Reporter</div>
                <div className="font-semibold text-slate-800 truncate mt-0.5">
                  {selectedIssue.reporterName || 'Citizen User'}
                </div>
              </div>
              <div className="p-2.5 bg-slate-50 rounded-xl border border-slate-200">
                <div className="text-[10px] text-slate-400 font-medium uppercase">Reported Date</div>
                <div className="font-semibold text-slate-800 truncate mt-0.5">
                  {new Date(selectedIssue.createdAt).toLocaleDateString(undefined, {
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </div>
              </div>
            </div>

            {/* Assigned Field Officer Section */}
            <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 space-y-2">
              <label className="text-[11px] font-bold text-slate-700 flex items-center justify-between">
                <span className="flex items-center gap-1.5">
                  <UserCheck className="w-3.5 h-3.5 text-indigo-600" /> Allocate Field Officer:
                </span>
                <span className="text-[10px] text-slate-400 font-normal">
                  {selectedIssue.assignedOfficerName ? 'Currently Assigned' : 'Unallocated'}
                </span>
              </label>
              <select
                value={selectedIssue.assignedOfficerId || ''}
                onChange={(e) => handleQuickAssign(e.target.value)}
                className="w-full px-3 py-1.5 bg-white text-xs font-medium text-slate-800 rounded-lg border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="">-- Select Field Officer to Dispatch --</option>
                {officers.map((off) => (
                  <option key={off.id} value={off.id}>
                    {off.firstName} {off.lastName} ({off.email})
                  </option>
                ))}
              </select>
            </div>

            {/* Quick Status Stage Transition */}
            <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 space-y-2">
              <label className="text-[11px] font-bold text-slate-700 flex items-center gap-1.5">
                <RefreshCw className="w-3.5 h-3.5 text-blue-600" /> Update Lifecycle Stage:
              </label>
              <div className="grid grid-cols-2 gap-1.5">
                {(['REPORTED', 'ACKNOWLEDGED', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'] as IssueStatus[]).map(
                  (st) => {
                    const active = selectedIssue.status === st;
                    const cfg = STAGE_CONFIG[st];
                    return (
                      <button
                        key={st}
                        onClick={() => handleQuickStatusChange(st)}
                        className={`px-2.5 py-1.5 text-xs font-semibold rounded-lg border text-left flex items-center justify-between transition-all ${
                          active
                            ? 'bg-slate-900 text-white border-slate-900 shadow-sm'
                            : 'bg-white hover:bg-slate-100 text-slate-700 border-slate-200'
                        }`}
                      >
                        <span className="truncate">{cfg.label}</span>
                        <span
                          className="w-3.5 h-3.5 rounded-full flex items-center justify-center text-[9px] text-white"
                          style={{ backgroundColor: cfg.hex }}
                        >
                          {cfg.symbol}
                        </span>
                      </button>
                    );
                  }
                )}
              </div>
            </div>

            {/* Nearby Cluster Complaints List */}
            {nearbyComplaints.length > 0 && (
              <div className="space-y-2">
                <div className="text-[11px] font-bold text-slate-700">Nearby Complaints in Sector:</div>
                <div className="space-y-1.5 max-h-40 overflow-y-auto pr-1">
                  {nearbyComplaints.map(({ issue: nb, distanceMeters }) => (
                    <div
                      key={nb.id}
                      onClick={() => {
                        setSelectedIssue(nb);
                        mapInstanceRef.current?.setView([nb.latitude, nb.longitude], 16, { animate: true });
                      }}
                      className="p-2 bg-white hover:bg-blue-50/70 border border-slate-200 rounded-lg flex items-center justify-between cursor-pointer transition-colors text-xs"
                    >
                      <div className="truncate pr-2">
                        <div className="font-semibold text-slate-800 truncate">{nb.title}</div>
                        <div className="text-[10px] text-slate-400 font-medium">
                          {nb.categoryName} • {STAGE_CONFIG[nb.status]?.label}
                        </div>
                      </div>
                      <span className="text-[10px] font-bold text-blue-600 bg-blue-50 px-2 py-0.5 rounded-full whitespace-nowrap">
                        {distanceMeters}m away
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Drawer Footer / Link to Workspace */}
          <div className="p-3 bg-slate-50 border-t border-slate-200 flex items-center justify-between">
            <button
              onClick={() => navigate(`/issues/${selectedIssue.id}`)}
              className="w-full py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-xl flex items-center justify-center space-x-2 shadow-sm transition-all"
            >
              <span>Open Detailed Complaint Workspace</span>
              <ExternalLink className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
