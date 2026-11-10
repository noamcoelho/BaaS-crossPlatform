export interface Estande {
  id: string;
  nome: string;
  descricao: string;
  localizacao: string;
  ativo: boolean;
}

export type DadosEstande = Omit<Estande, 'id'>;
