import { FirebaseError } from 'firebase/app';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { useState, type FormEvent } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../auth/useAuth';
import { auth } from '../firebase';

function mensagemDeErro(e: unknown): string {
  if (e instanceof FirebaseError) {
    switch (e.code) {
      case 'auth/invalid-credential':
      case 'auth/wrong-password':
      case 'auth/user-not-found':
      case 'auth/invalid-email':
        return 'E-mail ou senha inválidos.';
      case 'auth/too-many-requests':
        return 'Muitas tentativas. Aguarde um pouco e tente novamente.';
      case 'auth/network-request-failed':
        return 'Sem conexão com o Firebase. Verifique a internet.';
    }
  }
  return 'Não foi possível entrar. Tente novamente.';
}

export function LoginPage() {
  const { user, isAdmin, loading, logout } = useAuth();
  const [email, setEmail] = useState('');
  const [senha, setSenha] = useState('');
  const [erro, setErro] = useState<string | null>(null);
  const [enviando, setEnviando] = useState(false);

  if (loading) return <p className="centro">Carregando…</p>;
  if (user && isAdmin) return <Navigate to="/" replace />;

  if (user && !isAdmin) {
    return (
      <main className="cartao login">
        <h1>Circuito de Descobertas</h1>
        <p className="erro">Usuário sem permissão de administrador.</p>
        <p className="dica">
          Conectado como <strong>{user.email}</strong>. Peça para incluir seu UID ({user.uid}) na
          coleção <code>admins</code>.
        </p>
        <button onClick={logout}>Sair</button>
      </main>
    );
  }

  async function entrar(ev: FormEvent) {
    ev.preventDefault();
    setErro(null);
    setEnviando(true);
    try {
      await signInWithEmailAndPassword(auth, email.trim(), senha);
    } catch (e) {
      setErro(mensagemDeErro(e));
    } finally {
      setEnviando(false);
    }
  }

  return (
    <main className="cartao login">
      <h1>Circuito de Descobertas</h1>
      <p className="dica">Painel da organização</p>
      <form onSubmit={entrar}>
        <label>
          E-mail
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        </label>
        <label>
          Senha
          <input type="password" value={senha} onChange={(e) => setSenha(e.target.value)} required />
        </label>
        {erro && <p className="erro">{erro}</p>}
        <button type="submit" disabled={enviando}>
          {enviando ? 'Entrando…' : 'Entrar'}
        </button>
      </form>
    </main>
  );
}
