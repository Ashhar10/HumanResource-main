import { useState, useEffect, useCallback } from 'react';
import { supabase } from './supabase';

export interface CompanySettings {
  id: number;
  company_name: string;
  app_title: string;
  company_tagline: string;
  company_logo_url: string;
  company_email: string;
  company_phone: string;
  company_address: string;
  company_website: string;
  currency_symbol: string;
  fiscal_year_start?: string;
  office_working_days?: number;
  extra_data?: Record<string, any>;
  updated_at?: string;
}

export const DEFAULT_COMPANY_SETTINGS: CompanySettings = {
  id: 1,
  company_name: 'ELIPSE HR',
  app_title: 'Elipse HR Portal',
  company_tagline: 'Secure Attendance & HR Management Portal',
  company_logo_url: '/icons/logo.png',
  company_email: 'elipsestudiohr@gmail.com',
  company_phone: '',
  company_address: '',
  company_website: '',
  currency_symbol: 'Rs',
  fiscal_year_start: '01-01',
  office_working_days: 6,
  extra_data: {}
};

const STORAGE_KEY = 'elipse_company_settings_v1';
const EVENT_NAME = 'company_settings_updated';

/**
 * Get current company settings synchronously from localStorage cache
 */
export function getCachedCompanySettings(): CompanySettings {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      return { ...DEFAULT_COMPANY_SETTINGS, ...parsed };
    }
  } catch (e) {}
  return DEFAULT_COMPANY_SETTINGS;
}

/**
 * Fetch company settings from Supabase database with multi-layer fallback
 */
export async function fetchCompanySettings(): Promise<CompanySettings> {
  let result: Partial<CompanySettings> | null = null;

  // 1. Try fetching from dedicated `company_settings` table
  try {
    const { data, error } = await supabase
      .from('company_settings')
      .select('*')
      .eq('id', 1)
      .maybeSingle();

    if (!error && data) {
      result = data;
    }
  } catch (err) {}

  // 2. Fallback to `device_settings` table if `company_settings` is not created yet
  if (!result) {
    try {
      const { data, error } = await supabase
        .from('device_settings')
        .select('*')
        .eq('id', 1)
        .maybeSingle();

      if (!error && data) {
        if (data.company_profile && typeof data.company_profile === 'object') {
          result = data.company_profile;
        } else if (data.company_name) {
          result = {
            company_name: data.company_name,
            app_title: data.app_title || data.company_name,
            company_tagline: data.company_tagline || '',
            company_logo_url: data.company_logo_url || '/icons/logo.png',
            company_email: data.company_email || '',
            company_phone: data.company_phone || '',
            company_address: data.company_address || '',
            company_website: data.company_website || '',
            currency_symbol: data.currency_symbol || 'Rs'
          };
        }
      }
    } catch (err) {}
  }

  // Merge with defaults and local cache
  const cached = getCachedCompanySettings();
  const merged: CompanySettings = {
    ...DEFAULT_COMPANY_SETTINGS,
    ...cached,
    ...(result || {})
  };

  // Update local cache
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(merged));
  } catch (e) {}

  // Update browser document title
  if (merged.app_title || merged.company_name) {
    document.title = merged.app_title || `${merged.company_name} Portal`;
  }

  return merged;
}

/**
 * Save updated company settings to Supabase and broadcast to all platforms
 */
export async function saveCompanySettings(updates: Partial<CompanySettings>): Promise<CompanySettings> {
  const current = getCachedCompanySettings();
  const merged: CompanySettings = {
    ...current,
    ...updates,
    id: 1,
    updated_at: new Date().toISOString()
  };

  // 1. Immediately cache locally
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(merged));
  } catch (e) {}

  // Update page title
  if (merged.app_title || merged.company_name) {
    document.title = merged.app_title || `${merged.company_name} Portal`;
  }

  // Dispatch window event so all open views immediately re-render
  window.dispatchEvent(new CustomEvent(EVENT_NAME, { detail: merged }));

  // 2. Persist to Supabase `company_settings` table
  try {
    const { error } = await supabase
      .from('company_settings')
      .upsert([merged]);

    if (error) {
      console.warn('Could not save to company_settings table (table may not exist yet):', error.message);
    }
  } catch (err) {}

  // 3. Mirror to `device_settings` as fallback
  try {
    const deviceFallback: any = {
      id: 1,
      updated_at: new Date().toISOString()
    };
    if (merged.company_name) deviceFallback.company_name = merged.company_name;
    if (merged.company_logo_url) deviceFallback.company_logo_url = merged.company_logo_url;
    deviceFallback.company_profile = merged;

    await supabase.from('device_settings').upsert([deviceFallback]);
  } catch (err) {}

  // 4. Broadcast via Supabase Realtime channel so all other devices and tabs update
  try {
    const channel = supabase.channel('app-global-company-branding');
    await channel.send({
      type: 'broadcast',
      event: 'company_settings_changed',
      payload: merged
    });
  } catch (err) {}

  return merged;
}

/**
 * React Hook for consuming and updating company settings with live sync
 */
export function useCompanySettings() {
  const [settings, setSettings] = useState<CompanySettings>(getCachedCompanySettings);
  const [loading, setLoading] = useState(true);

  const reloadSettings = useCallback(async () => {
    try {
      const fresh = await fetchCompanySettings();
      setSettings(fresh);
    } catch (e) {
      setSettings(getCachedCompanySettings());
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    let isMounted = true;

    // Load initial from DB
    reloadSettings();

    // Listen to local window updates
    const handleLocalUpdate = (e: any) => {
      if (isMounted && e.detail) {
        setSettings(e.detail);
      }
    };
    window.addEventListener(EVENT_NAME, handleLocalUpdate);

    // Listen to Supabase Realtime updates
    const realtimeChannel = supabase
      .channel('app-global-company-branding')
      .on('broadcast', { event: 'company_settings_changed' }, (payload) => {
        if (isMounted && payload?.payload) {
          const updated = { ...getCachedCompanySettings(), ...payload.payload };
          setSettings(updated);
          localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
          if (updated.app_title || updated.company_name) {
            document.title = updated.app_title || updated.company_name;
          }
        }
      })
      .subscribe();

    return () => {
      isMounted = false;
      window.removeEventListener(EVENT_NAME, handleLocalUpdate);
      supabase.removeChannel(realtimeChannel);
    };
  }, [reloadSettings]);

  const updateSettings = async (newValues: Partial<CompanySettings>) => {
    const saved = await saveCompanySettings(newValues);
    setSettings(saved);
    return saved;
  };

  return {
    companySettings: settings,
    updateCompanySettings: updateSettings,
    loading
  };
}
