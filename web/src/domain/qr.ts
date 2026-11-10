const PREFIXO = 'circuito://estande/';

/** Conteúdo gravado no QR code de um estande. */
export function qrPayload(estandeId: string): string {
  return `${PREFIXO}${estandeId}`;
}

/** Extrai o id do estande do conteúdo lido, ou `null` se o QR não for do circuito. */
export function parseQr(raw: string): string | null {
  const texto = raw.trim();
  if (!texto.startsWith(PREFIXO)) return null;
  const id = texto.slice(PREFIXO.length);
  if (id.length === 0 || id.includes('/')) return null;
  return id;
}
