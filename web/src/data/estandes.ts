import {
  addDoc,
  collection,
  doc,
  getDoc,
  onSnapshot,
  serverTimestamp,
  setDoc,
  writeBatch,
  type Unsubscribe,
} from 'firebase/firestore';
import { contarCheckinsPorEstande } from '../domain/contagem';
import type { DadosEstande, Estande } from '../domain/estande';
import { db } from '../firebase';

const estandesCol = collection(db, 'estandes');
const checkinsCol = collection(db, 'checkins');

function paraEstande(id: string, d: Record<string, unknown>): Estande {
  return {
    id,
    nome: String(d.nome ?? ''),
    descricao: String(d.descricao ?? ''),
    localizacao: String(d.localizacao ?? ''),
    ativo: d.ativo === true,
  };
}

/** Escuta todos os estandes (admin), ordenados por nome. */
export function ouvirEstandes(
  cb: (estandes: Estande[]) => void,
  onErro: (e: Error) => void,
): Unsubscribe {
  return onSnapshot(
    estandesCol,
    (snap) => {
      const lista = snap.docs.map((d) => paraEstande(d.id, d.data()));
      lista.sort((a, b) => a.nome.localeCompare(b.nome, 'pt-BR'));
      cb(lista);
    },
    onErro,
  );
}

/** Escuta os check-ins e entrega o total por estande, recalculado a cada novo registro. */
export function ouvirTotais(
  cb: (totais: Record<string, number>) => void,
  onErro: (e: Error) => void,
): Unsubscribe {
  return onSnapshot(
    checkinsCol,
    (snap) =>
      cb(contarCheckinsPorEstande(snap.docs.map((d) => ({ estandeId: String(d.get('estandeId')) })))),
    onErro,
  );
}

/** Cria (sem id) ou atualiza (com id) um estande. */
export async function salvarEstande(dados: DadosEstande, id?: string): Promise<void> {
  const payload = { ...dados, atualizadoEm: serverTimestamp() };
  if (id) await setDoc(doc(estandesCol, id), payload);
  else await addDoc(estandesCol, payload);
}

export async function obterEstande(id: string): Promise<Estande | null> {
  const snap = await getDoc(doc(estandesCol, id));
  return snap.exists() ? paraEstande(snap.id, snap.data()) : null;
}

const EXEMPLOS: DadosEstande[] = [
  {
    nome: 'Robô Guia',
    descricao: 'Robô que conduz visitantes pelos corredores da feira.',
    localizacao: 'Corredor A, estande 3',
    ativo: true,
  },
  {
    nome: 'App de Libras',
    descricao: 'Tradutor de português para Libras com avatar 3D.',
    localizacao: 'Corredor C, estande 12',
    ativo: true,
  },
  {
    nome: 'Horta Inteligente',
    descricao: 'Sensores de umidade e irrigação automática para hortas urbanas.',
    localizacao: 'Corredor E, estande 21',
    ativo: true,
  },
];

/** Cria três estandes fictícios para a demonstração. */
export async function criarEstandesExemplo(): Promise<void> {
  const lote = writeBatch(db);
  for (const e of EXEMPLOS) lote.set(doc(estandesCol), { ...e, atualizadoEm: serverTimestamp() });
  await lote.commit();
}
