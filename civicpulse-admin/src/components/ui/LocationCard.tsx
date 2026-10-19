import React from 'react';
import { MapPin, ExternalLink } from 'lucide-react';

interface LocationCardProps {
  latitude: number;
  longitude: number;
  address?: string;
  landmark?: string;
  wardName?: string;
}

export const LocationCard: React.FC<LocationCardProps> = ({
  latitude,
  longitude,
  address,
  landmark,
  wardName,
}) => {
  const mapUrl = `https://www.openstreetmap.org/export/embed.html?bbox=${longitude - 0.005}%2C${latitude - 0.005}%2C${longitude + 0.005}%2C${latitude + 0.005}&layer=mapnik&marker=${latitude}%2C${longitude}`;
  const externalMapLink = `https://www.google.com/maps?q=${latitude},${longitude}`;

  return (
    <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm">
      <div className="p-4 border-b border-slate-100 flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <MapPin className="w-5 h-5 text-blue-600" />
          <h4 className="font-semibold text-slate-900 text-sm">Geographic Location</h4>
        </div>
        <a
          href={externalMapLink}
          target="_blank"
          rel="noopener noreferrer"
          className="text-xs text-blue-600 hover:text-blue-800 flex items-center gap-1 font-medium"
        >
          Open Maps <ExternalLink className="w-3.5 h-3.5" />
        </a>
      </div>

      {/* Embedded Map */}
      <div className="relative w-full h-48 bg-slate-100">
        <iframe
          title="Issue location map"
          src={mapUrl}
          className="w-full h-full border-0"
          loading="lazy"
        />
      </div>

      <div className="p-4 space-y-2 text-xs">
        <div>
          <span className="text-slate-500 font-medium">GPS Coordinates: </span>
          <span className="font-mono text-slate-800">
            {latitude.toFixed(6)}, {longitude.toFixed(6)}
          </span>
        </div>
        {address && (
          <div>
            <span className="text-slate-500 font-medium">Address: </span>
            <span className="text-slate-800">{address}</span>
          </div>
        )}
        {landmark && (
          <div>
            <span className="text-slate-500 font-medium">Landmark: </span>
            <span className="text-slate-800">{landmark}</span>
          </div>
        )}
        {wardName && (
          <div>
            <span className="text-slate-500 font-medium">Ward: </span>
            <span className="text-slate-800 font-semibold">{wardName}</span>
          </div>
        )}
      </div>
    </div>
  );
};
