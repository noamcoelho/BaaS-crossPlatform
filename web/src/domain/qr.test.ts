import { describe, expect, it } from 'vitest';
import { parseQr, qrPayload } from './qr';

describe('qrPayload', () => {
  it('monta o conteúdo do QR a partir do id do estande', () => {
    expect(qrPayload('abc')).toBe('circuito://estande/abc');
  });
});

describe('parseQr', () => {
  it('extrai o id de um QR válido', () => {
    expect(parseQr('circuito://estande/abc')).toBe('abc');
  });

  it('ignora espaços e quebras de linha nas pontas', () => {
    expect(parseQr('  circuito://estande/abc\n')).toBe('abc');
  });

  it('rejeita id vazio', () => {
    expect(parseQr('circuito://estande/')).toBeNull();
  });

  it('rejeita id com barra', () => {
    expect(parseQr('circuito://estande/a/b')).toBeNull();
  });

  it('rejeita conteúdo de outro formato', () => {
    expect(parseQr('https://x.com')).toBeNull();
  });

  it('é o inverso de qrPayload', () => {
    expect(parseQr(qrPayload('Xy9_k-2'))).toBe('Xy9_k-2');
  });
});
