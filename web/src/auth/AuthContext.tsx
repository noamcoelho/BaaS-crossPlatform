import { onAuthStateChanged, signOut, type User } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { useEffect, useState, type ReactNode } from 'react';
import { auth, db } from '../firebase';
import { AuthContext, type AuthState } from './useAuth';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(
    () =>
      onAuthStateChanged(auth, async (u) => {
        setLoading(true);
        let admin = false;
        if (u && !u.isAnonymous) {
          try {
            admin = (await getDoc(doc(db, 'admins', u.uid))).exists();
          } catch {
            admin = false;
          }
        }
        setUser(u);
        setIsAdmin(admin);
        setLoading(false);
      }),
    [],
  );

  const value: AuthState = { user, isAdmin, loading, logout: () => signOut(auth) };
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
