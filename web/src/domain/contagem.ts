/** Conta check-ins por estande a partir dos registros do Firestore. */
export function contarCheckinsPorEstande(
  checkins: ReadonlyArray<{ estandeId: string }>,
): Record<string, number> {
  const totais: Record<string, number> = {};
  for (const { estandeId } of checkins) {
    totais[estandeId] = (totais[estandeId] ?? 0) + 1;
  }
  return totais;
}
