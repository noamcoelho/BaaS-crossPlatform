import { describe, expect, it } from 'vitest';
import { contarCheckinsPorEstande } from './contagem';

describe('contarCheckinsPorEstande', () => {
  it('agrupa os check-ins por estande', () => {
    expect(
      contarCheckinsPorEstande([{ estandeId: 'a' }, { estandeId: 'a' }, { estandeId: 'b' }]),
    ).toEqual({ a: 2, b: 1 });
  });

  it('retorna objeto vazio sem check-ins', () => {
    expect(contarCheckinsPorEstande([])).toEqual({});
  });
});
