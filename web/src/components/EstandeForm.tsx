import { useState, type FormEvent } from 'react';
import type { DadosEstande, Estande } from '../domain/estande';

interface Props {
  inicial?: Estande;
  onSalvar(dados: DadosEstande): Promise<void>;
  onCancelar(): void;
}

export function EstandeForm({ inicial, onSalvar, onCancelar }: Props) {
  const [nome, setNome] = useState(inicial?.nome ?? '');
  const [descricao, setDescricao] = useState(inicial?.descricao ?? '');
  const [localizacao, setLocalizacao] = useState(inicial?.localizacao ?? '');
  const [ativo, setAtivo] = useState(inicial?.ativo ?? true);
  const [erro, setErro] = useState<string | null>(null);
  const [salvando, setSalvando] = useState(false);

  async function enviar(ev: FormEvent) {
    ev.preventDefault();
    const dados = {
      nome: nome.trim(),
      descricao: descricao.trim(),
      localizacao: localizacao.trim(),
      ativo,
    };
    if (!dados.nome || !dados.descricao || !dados.localizacao) {
      setErro('Preencha nome, descrição e localização.');
      return;
    }
    setErro(null);
    setSalvando(true);
    try {
      await onSalvar(dados);
    } catch {
      setErro('Não foi possível salvar. Verifique sua permissão e a conexão.');
      setSalvando(false);
    }
  }

  return (
    <form className="cartao formulario" onSubmit={enviar}>
      <h2>{inicial ? 'Editar estande' : 'Novo estande'}</h2>
      <label>
        Nome
        <input value={nome} onChange={(e) => setNome(e.target.value)} maxLength={80} required />
      </label>
      <label>
        Descrição breve
        <textarea
          value={descricao}
          onChange={(e) => setDescricao(e.target.value)}
          maxLength={280}
          rows={3}
          required
        />
      </label>
      <label>
        Localização
        <input
          value={localizacao}
          onChange={(e) => setLocalizacao(e.target.value)}
          maxLength={80}
          placeholder="Ex.: Corredor B, estande 7"
          required
        />
      </label>
      <label className="linha">
        <input type="checkbox" checked={ativo} onChange={(e) => setAtivo(e.target.checked)} />
        Estande ativo
      </label>
      {erro && <p className="erro">{erro}</p>}
      <div className="acoes">
        <button type="submit" disabled={salvando}>
          {salvando ? 'Salvando…' : 'Salvar'}
        </button>
        <button type="button" className="secundario" onClick={onCancelar}>
          Cancelar
        </button>
      </div>
    </form>
  );
}
