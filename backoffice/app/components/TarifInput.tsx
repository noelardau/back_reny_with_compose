import { Select } from '@mantine/core';
import React from 'react';

export const TarifInput = ({ value, onChange}) => {
const typesTarif = [
  {id:"211c482e-2197-467c-a4ea-f825611a58ea", type:"VIP"}, {id:"262a7176-e2f7-4d88-adb9-6591f0942734", type:"GOLD"}
]

  const handleChange = (index, field, newValue) => {
    const newTarifs = [...value];
    newTarifs[index] = {
      ...newTarifs[index],
      [field]: newValue
    };
    onChange(newTarifs);
  };

  const addTarif = () => {
    
    onChange([
      ...value,
      {
        type_place_id: '',
        prix: '',
        nombre_places: ''
      }
    ]);
  };

  const removeTarif = (index) => {
    const newTarifs = value.filter((_, idx) => idx !== index);
    onChange(newTarifs);
  };

  return (
    <div className="space-y-4">
      {value.map((tarif, index) => (
        <div key={index} className="p-4 border rounded-lg bg-gray-50 relative">
          <button
            type="button"
            onClick={() => removeTarif(index)}
            className="absolute top-2 right-2 text-red-600 hover:text-red-800"
          >
            <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
            </svg>
          </button>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Type de place
              </label>
                <select
                id="type_place"
                value={tarif.type_place_id}
               onChange={(e) => handleChange(index, 'type_place', e.target.value)}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                required
              >
                {typesTarif.map(tt => <option key={tt.id} value={tt.id}>{tt.type}</option>)}
              </select>
              <input
                type="text"
                value={tarif.type_place}
                onChange={(e) => handleChange(index, 'type_place', e.target.value)}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                placeholder="Ex: Standard, VIP, Early Bird"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">
                Prix (Ar)
              </label>
              <input
                type="number"
                value={tarif.prix}
                onChange={(e) => handleChange(index, 'prix', parseFloat(e.target.value))}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                min="0"
                required
              />
            </div>

            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-gray-700">
                Nombre de place
              </label>
              <input type='number'
                value={tarif.nombre_places}
                onChange={(e) => handleChange(index, 'nombre_places', e.target.value)}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
               
              />
            </div>
          </div>
        </div>
      ))}

      <button
        type="button"
        onClick={addTarif}
        className="mt-4 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
      >
        Ajouter un tarif
      </button>
    </div>
  );
};