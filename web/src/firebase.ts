import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const env = import.meta.env;

const firebaseConfig = {
  apiKey: env.VITE_FIREBASE_API_KEY,
  authDomain: env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: env.VITE_FIREBASE_APP_ID,
};

/** `false` enquanto o arquivo `.env` não tiver sido preenchido (ver docs/GUIA_FIREBASE.md). */
export const firebaseConfigurado = Boolean(firebaseConfig.apiKey && firebaseConfig.projectId);

const app = initializeApp(
  firebaseConfigurado ? firebaseConfig : { apiKey: 'placeholder', projectId: 'placeholder' },
);

export const auth = getAuth(app);
export const db = getFirestore(app);
