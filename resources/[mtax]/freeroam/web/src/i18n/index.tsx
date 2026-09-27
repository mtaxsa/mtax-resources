import React, { createContext, useCallback, useContext, useMemo, useState } from 'react';
import enUS from './locales/en-US.json';
import esES from './locales/es-ES.json';
import ptBR from './locales/pt-BR.json';

interface Locale {
  meta: { code: string; name: string };
  strings: Record<string, string>;
}

export type Vars = Record<string, string | number>;
export type Translate = (key: string, vars?: Vars) => string;

export const LOCALES: Locale[] = [enUS, ptBR, esES];

const FALLBACK = 'en-US';
const STORAGE_KEY = 'mtax-freeroam-language';

const byCode = (code: string | null | undefined) => LOCALES.find((locale) => locale.meta.code === code);

const readStored = () => {
  try {
    return localStorage.getItem(STORAGE_KEY);
  } catch {
    return null;
  }
};

const interpolate = (text: string, vars?: Vars) =>
  vars ? text.replace(/\{(\w+)\}/g, (match, name) => (vars[name] === undefined ? match : String(vars[name]))) : text;

interface I18n {
  language: Locale;
  t: Translate;
  loc: (value: string | undefined) => string;
  setLanguage: (code: string) => void;
  cycleLanguage: () => void;
  setDefault: (code: string) => void;
}

const Context = createContext<I18n | null>(null);

export const I18nProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [code, setCode] = useState(() => readStored() ?? FALLBACK);
  const language = byCode(code) ?? byCode(FALLBACK)!;

  const choose = useCallback((next: string) => {
    setCode(next);
    try {
      localStorage.setItem(STORAGE_KEY, next);
    } catch { }
  }, []);

  const t = useCallback<Translate>(
    (key, vars) => interpolate(language.strings[key] ?? byCode(FALLBACK)!.strings[key] ?? key, vars),
    [language]
  );

  // Strings prefixed with "@" are translation keys; everything else is shown as is.
  const loc = useCallback((value: string | undefined) => {
    const text = value ?? '';
    return text.startsWith('@') ? t(text.slice(1)) : text;
  }, [t]);

  const setLanguage = useCallback((next: string) => {
    if (byCode(next)) choose(next);
  }, [choose]);

  const cycleLanguage = useCallback(() => {
    const at = LOCALES.indexOf(language);
    choose(LOCALES[(at + 1) % LOCALES.length].meta.code);
  }, [language, choose]);

  // The server default only applies until the player picks a language themselves.
  const setDefault = useCallback((next: string) => {
    if (!readStored() && byCode(next)) setCode(next);
  }, []);

  const value = useMemo(
    () => ({ language, t, loc, setLanguage, cycleLanguage, setDefault }),
    [language, t, loc, setLanguage, cycleLanguage, setDefault]
  );

  return <Context.Provider value={value}>{children}</Context.Provider>;
};

export const useI18n = () => {
  const value = useContext(Context);
  if (!value) throw new Error('useI18n outside I18nProvider');
  return value;
};
