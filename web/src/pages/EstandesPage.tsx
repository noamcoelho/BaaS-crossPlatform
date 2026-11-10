import { useEffect, useState } from 'react';
import { useAuth } from '../auth/useAuth';
import { EstandeForm } from '../components/EstandeForm';
import { criarEstandesExemplo, ouvirEstandes, ouvirTotais, salvarEstande } from '../data/estandes';
import type { DadosEstande, Estande } from '../domain/estande';

type Edicao = { modo: 'novo' } | { modo: 'editar'; estande: Estande } | null;

export function EstandesPage() {
  const { user, logout } = useAuth();
  const [estandes, setEstandes] = useState<Estande[] | null>(null);
  const [totais, setTotais] = useState<Record<string, number>>({});
  const [edicao, setEdicao] = useState<Edicao>(null);
  const [erro, setErro] = useState<string | null>(null);
  const [criandoExemplos, setCriandoExemplos] = useState(false);

  useEffect(() => {
    const falha = () => setErro('Falha ao ler dados do Firestore. Verifique as regras e a conexão.');
    const pararEstandes = ouvirEstandes(setEstandes, falha);
    const pararTotais = ouvirTotais(setTotais, falha);
    return () => {
      pararEstandes();
      pararTotais();
    };
  }, []);

  async function salvar(dados: DadosEstande) {
    await salvarEstande(dados, edicao?.modo === 'editar' ? edicao.estande.id : undefined);
    setEdicao(null);
  }

  async function alternarAtivo(e: Estande) {
    try {
      const { id, ...dados } = e;
      await salvarEstande({ ...dados, ativo: !e.ativo }, id);
    } catch {
      setErro('Não foi possível alterar o estado do estande.');
    }
  }

  async function exemplos() {
    setCriandoExemplos(true);
    try {
      await criarEstandesExemplo();
    } catch {
      setErro('Não foi possível criar os estandes de exemplo.');
    } finally {
      setCriandoExemplos(false);
    }
  }

  const totalGeral = Object.values(totais).reduce((a, b) => a + b, 0);

  return (
    <div className="pagina">
      <header className="topo">
        <div>
          <h1>Circuito de Descobertas</h1>
          <p className="dica">Painel da organização · {user?.email}</p>
        </div>
        <button className="secundario" onClick={logout}>
          Sair
        </button>
      </header>

      {erro && (
        <p className="erro" role="alert">
          {erro} <button className="link" onClick={() => setErro(null)}>fechar</button>
        </p>
      )}

      {edicao && (
        <EstandeForm
          key={edicao.modo === 'editar' ? edicao.estande.id : 'novo'}
          inicial={edicao.modo === 'editar' ? edicao.estande : undefined}
          onSalvar={salvar}
          onCancelar={() => setEdicao(null)}
        />
      )}

      <section className="cartao">
        <div className="secao-topo">
          <h2>Estandes</h2>
          <span className="dica">{totalGeral} check-ins confirmados no total</span>
          <button onClick={() => setEdicao({ modo: 'novo' })}>+ Novo estande</button>
        </div>

        {estandes === null ? (
          <p>Carregando…</p>
        ) : estandes.length === 0 ? (
          <div className="vazio">
            <p>Nenhum estande cadastrado.</p>
            <button onClick={exemplos} disabled={criandoExemplos}>
              {criandoExemplos ? 'Criando…' : 'Criar estandes de exemplo'}
            </button>
          </div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Nome</th>
                <th>Localização</th>
                <th>Estado</th>
                <th className="num">Check-ins</th>
                <th>Ações</th>
              </tr>
            </thead>
            <tbody>
              {estandes.map((e) => (
                <tr key={e.id} className={e.ativo ? '' : 'inativo'}>
                  <td>
                    <strong>{e.nome}</strong>
                    <div className="dica">{e.descricao}</div>
                    <div className="id">ID: {e.id}</div>
                  </td>
                  <td>{e.localizacao}</td>
                  <td>
                    <span className={e.ativo ? 'selo ativo' : 'selo'}>{e.ativo ? 'Ativo' : 'Inativo'}</span>
                  </td>
                  <td className="num total">{totais[e.id] ?? 0}</td>
                  <td className="acoes">
                    <button className="secundario" onClick={() => setEdicao({ modo: 'editar', estande: e })}>
                      Editar
                    </button>
                    <button className="secundario" onClick={() => alternarAtivo(e)}>
                      {e.ativo ? 'Desativar' : 'Ativar'}
                    </button>
                    <a className="botao" href={`/qr/${e.id}`} target="_blank" rel="noreferrer">
                      Ver QR
                    </a>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}
