// ~/utils/base64.ts
export const base64ToDataUrl = (base64: string | null | undefined): string | null => {
  if (!base64) return null;
  const clean = base64.replace(/\s/g, '');
  if (clean.length < 50) return null;

  let mimeType = "image/jpeg";
  if (clean.startsWith("iVBOR")) mimeType = "image/png";
  else if (clean.startsWith("R0lGOD")) mimeType = "image/gif";
  else if (clean.startsWith("/9j/")) mimeType = "image/jpeg";

  return `data:${mimeType};base64,${clean}`;
};