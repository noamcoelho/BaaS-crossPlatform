import type { User } from 'firebase/auth';
import { createContext, useContext } from 'react';

export interface AuthState {
  user: User | null;
  isAdmin: boolean;
  loading: boolean;
  logout(): Promise<void>;
}

export const AuthContext = createContext<AuthState | null>(null);

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth deve ser usado dentro de <AuthProvider>');
  return ctx;
}
