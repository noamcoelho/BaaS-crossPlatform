import { QRCodeSVG } from 'qrcode.react';
import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { obterEstande } from '../data/estandes';
import type { Estande } from '../domain/estande';
import { qrPayload } from '../domain/qr';

export function QrPage() {
  const { id = '' } = useParams();
  const [estande, setEstande] = useState<Estande | null | undefined>(undefined);

  useEffect(() => {
    obterEstande(id)
      .then(setEstande)
      .catch(() => setEstande(null));
  }, [id]);

  if (estande === undefined) return <p className="centro">Carregando…</p>;
  if (estande === null) return <p className="centro erro">Estande não encontrado.</p>;

  return (
    <main className="qr-pagina">
      <h1>{estande.nome}</h1>
      <p className="qr-local">{estande.localizacao}</p>
      <QRCodeSVG value={qrPayload(estande.id)} size={320} level="M" marginSize={2} />
      <p className="qr-instrucao">Abra o app Circuito de Descobertas e leia este QR para registrar sua visita</p>
      <p className="id">ID: {estande.id}</p>
      {!estande.ativo && <p className="erro nao-imprimir">Atenção: este estande está inativo.</p>}
      <button className="nao-imprimir" onClick={() => window.print()}>
        Imprimir
      </button>
    </main>
  );
}
