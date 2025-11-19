import React from 'react';

export const LieuInput = ({ value, onChange }) => {
  return (
    <div className="space-y-4">
      <div>
        <label htmlFor="nom_lieu" className="block text-sm font-medium text-gray-700">
          Nom du lieu
        </label>
        <input
          type="text"
          id="nom_lieu"
          value={value.nom || ''}
          onChange={(e) => onChange({ ...value, nom: e.target.value })}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          required
        />
      </div>

      <div>
        <label htmlFor="adresse" className="block text-sm font-medium text-gray-700">
          Adresse
        </label>
        <input
          type="text"
          id="adresse"
          value={value.adresse || ''}
          onChange={(e) => onChange({ ...value, adresse: e.target.value })}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          required
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="ville" className="block text-sm font-medium text-gray-700">
            Ville
          </label>
          <input
            type="text"
            id="ville"
            value={value.ville || ''}
            onChange={(e) => onChange({ ...value, ville: e.target.value })}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            required
          />
        </div>
        <div>
          <label htmlFor="capacite" className="block text-sm font-medium text-gray-700">
            Capacité
          </label>
          <input
            type="number"
            id="capacite"
            value={value.capacite || ''}
            onChange={(e) => onChange({ ...value, capacite: e.target.value })}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            required
          />
        </div>

        
      </div>

    
    </div>
  );
};