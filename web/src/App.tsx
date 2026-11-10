import type { ReactNode } from 'react';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider } from './auth/AuthContext';
import { useAuth } from './auth/useAuth';
import { firebaseConfigurado } from './firebase';
import { EstandesPage } from './pages/EstandesPage';
import { LoginPage } from './pages/LoginPage';
import { QrPage } from './pages/QrPage';

function SomenteAdmin({ children }: { children: ReactNode }) {
  const { user, isAdmin, loading } = useAuth();
  if (loading) return <p className="centro">Carregando…</p>;
  if (!user || !isAdmin) return <Navigate to="/login" replace />;
  return children;
}

function FaltaConfig() {
  return (
    <main className="cartao login">
      <h1>Firebase não configurado</h1>
      <p>
        Copie <code>web/.env.example</code> para <code>web/.env</code>, preencha com a configuração
        do app web do projeto Firebase e reinicie <code>npm run dev</code>.
      </p>
    </main>
  );
}

export default function App() {
  if (!firebaseConfigurado) return <FaltaConfig />;
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route
            path="/"
            element={
              <SomenteAdmin>
                <EstandesPage />
              </SomenteAdmin>
            }
          />
          <Route
            path="/qr/:id"
            element={
              <SomenteAdmin>
                <QrPage />
              </SomenteAdmin>
            }
          />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
