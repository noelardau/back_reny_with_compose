import React from 'react';

const convertToBase64 = (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => resolve(reader.result.split(',')[1]);
    reader.onerror = error => reject(error);
  });
};

export const FileUpload = ({ onFileChange }) => {
  // single-file mode: keep one preview and call onFileChange with an array
  const [preview, setPreview] = React.useState(null); // {url, name} or null
  const [isLoading, setIsLoading] = React.useState(false);

  const handleFile = async (file) => {
    if (!file) return;
    setIsLoading(true);
    try {
      const base64 = await convertToBase64(file);
      const obj = {
        nom_fichier: file.name,
        type_mime: file.type,
        type_fichier: 'affiche',
        donnees_bytea: base64
      };

      // set preview URL
      const url = URL.createObjectURL(file);
      // revoke previous preview if any
      setPreview((prev) => {
        if (prev && prev.url) {
          try {
            URL.revokeObjectURL(prev.url);
          } catch {
            /* ignore revoke errors */
          }
        }
        return { url, name: file.name };
      });

      onFileChange && onFileChange([obj]);
    } catch (error) {
      console.error('Erreur lors du traitement du fichier:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleFileInput = (e) => {
    const f = e.target.files && e.target.files[0];
    handleFile(f);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    const f = e.dataTransfer?.files && e.dataTransfer.files[0];
    if (f) handleFile(f);
  };

  const removeFile = () => {
    if (preview && preview.url) {
      try {
        URL.revokeObjectURL(preview.url);
      } catch {
        /* ignore revoke errors */
      }
    }
    setPreview(null);
    onFileChange && onFileChange([]);
  };

  // no bulk cleanup needed: we revoke the previous URL whenever it's replaced/removed

  return (
    <div className="space-y-4">
      <div
        className="border-2 border-dashed border-gray-300 rounded-lg p-4"
        onDrop={handleDrop}
        onDragOver={(e) => e.preventDefault()}
      >
        <input
          type="file"
          onChange={handleFileInput}
          accept="image/*"
          className="hidden"
          id="file-upload"
        />
        <label htmlFor="file-upload" className="flex flex-col items-center justify-center cursor-pointer">
          <div className="flex flex-col items-center justify-center pt-5 pb-6">
            <svg
              className="w-8 h-8 mb-4 text-gray-500"
              aria-hidden="true"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 20 16"
            >
              <path
                stroke="currentColor"
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M13 13h3a3 3 0 0 0 0-6h-.025A5.56 5.56 0 0 0 16 6.5 5.5 5.5 0 0 0 5.207 5.021C5.137 5.017 5.071 5 5 5a4 4 0 0 0 0 8h2.167M10 15V6m0 0L8 8m2-2 2 2"
              />
            </svg>
            <p className="mb-2 text-sm text-gray-500">
              <span className="font-semibold">Cliquez pour uploader</span> ou glissez-déposez
            </p>
            <p className="text-xs text-gray-500">PNG, JPG (MAX. 5MB) — choisissez une image</p>
          </div>
        </label>
      </div>

      {isLoading && (
        <div className="flex justify-center">
          <div className="loading loading-spinner loading-md"></div>
        </div>
      )}
      {preview && (
        <div className="relative w-48">
          <img src={preview.url} alt={preview.name} className="w-full h-32 object-cover rounded" />
          <button
            onClick={removeFile}
            className="absolute top-1 right-1 bg-red-600 text-white rounded-full p-1"
            type="button"
            aria-label={`Supprimer ${preview.name}`}
          >
            ×
          </button>
          <div className="p-2 text-xs truncate">{preview.name}</div>
        </div>
      )}
    </div>
  );
};