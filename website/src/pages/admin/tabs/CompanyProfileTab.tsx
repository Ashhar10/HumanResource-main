import React, { useState, useEffect } from 'react';
import { useCompanySettings, type CompanySettings } from '../../../lib/companySettings';

export const CompanyProfileTab: React.FC = () => {
  const { companySettings, updateCompanySettings } = useCompanySettings();

  const [formData, setFormData] = useState<CompanySettings>(companySettings);
  const [saving, setSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);

  useEffect(() => {
    setFormData(companySettings);
  }, [companySettings]);

  const handleChange = (field: keyof CompanySettings, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    setSaveSuccess(false);
    setSaveError(null);
  };

  // Convert uploaded logo file to Base64 data URL so it displays across all platforms
  const handleLogoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (file.size > 2 * 1024 * 1024) {
      alert('Logo file size should be less than 2 MB.');
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      if (typeof reader.result === 'string') {
        handleChange('company_logo_url', reader.result);
      }
    };
    reader.readAsDataURL(file);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setSaveError(null);
    setSaveSuccess(false);

    try {
      await updateCompanySettings(formData);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 4000);
    } catch (err: any) {
      setSaveError(err?.message || 'Failed to update company profile settings.');
    } finally {
      setSaving(false);
    }
  };

  const handleResetDefaultLogo = () => {
    handleChange('company_logo_url', '/icons/logo.png');
  };

  return (
    <div 
      className="glass-panel animate-fade-in" 
      style={{ padding: '28px', width: '100%', maxWidth: '850px', margin: '0 auto', boxSizing: 'border-box' }}
    >
      {/* Header Banner - Seamless Glassmorphic Theme */}
      <div style={{
        background: 'var(--bg-surface-hover)',
        border: '1px solid var(--border-color-glow)',
        borderRadius: 'var(--radius-md, 12px)',
        padding: '20px',
        marginBottom: '24px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: '16px'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div style={{
            width: '60px',
            height: '60px',
            borderRadius: 'var(--radius-sm, 10px)',
            background: 'var(--bg-primary)',
            border: '1px solid var(--border-color)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            overflow: 'hidden',
            padding: '6px',
            boxShadow: 'var(--shadow-sm)'
          }}>
            <img 
              src={formData.company_logo_url || '/icons/logo.png'} 
              alt="Logo" 
              style={{ width: '100%', height: '100%', objectFit: 'contain' }}
              onError={(e) => { (e.target as any).src = '/icons/logo.png'; }}
            />
          </div>
          <div>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 700, margin: '0 0 4px 0', color: 'var(--text-primary)' }}>
              {formData.company_name || 'Company Profile & Branding'}
            </h3>
            <p style={{ margin: 0, fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
              Customize app title, company name, logo, contact info, and branding across Web, Windows & Android.
            </p>
          </div>
        </div>

        {/* Live Topbar Preview Pill */}
        <div style={{
          background: 'var(--bg-primary)',
          padding: '8px 14px',
          borderRadius: 'var(--radius-sm, 8px)',
          border: '1px solid var(--border-color)',
          display: 'flex',
          alignItems: 'center',
          gap: '10px'
        }}>
          <span style={{ fontSize: '0.72rem', textTransform: 'uppercase', color: 'var(--text-muted)', letterSpacing: '0.05em', fontWeight: 600 }}>
            Live Preview:
          </span>
          <img 
            src={formData.company_logo_url || '/icons/logo.png'} 
            alt="Preview" 
            style={{ width: '26px', height: '26px', objectFit: 'contain' }}
            onError={(e) => { (e.target as any).src = '/icons/logo.png'; }}
          />
          <strong style={{ fontSize: '0.92rem', color: 'var(--text-primary)' }}>
            {formData.company_name || 'ELIPSE HR'}
          </strong>
        </div>
      </div>

      {saveSuccess && (
        <div style={{
          backgroundColor: 'rgba(16, 185, 129, 0.12)',
          color: 'var(--success, #10b981)',
          border: '1px solid rgba(16, 185, 129, 0.3)',
          padding: '12px 18px',
          borderRadius: 'var(--radius-sm, 8px)',
          marginBottom: '20px',
          display: 'flex',
          alignItems: 'center',
          gap: '10px',
          fontWeight: 600,
          fontSize: '0.88rem'
        }}>
          ✓ Company profile & branding saved successfully! Changes are updated in real-time across Web, Windows, and Android.
        </div>
      )}

      {saveError && (
        <div style={{
          backgroundColor: 'rgba(239, 68, 68, 0.12)',
          color: 'var(--danger, #ef4444)',
          border: '1px solid rgba(239, 68, 68, 0.3)',
          padding: '12px 18px',
          borderRadius: 'var(--radius-sm, 8px)',
          marginBottom: '20px',
          fontSize: '0.88rem'
        }}>
          ⚠️ {saveError}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '20px' }}>
          
          {/* Card 1: Core Branding */}
          <div style={{
            background: 'var(--bg-surface)',
            border: '1px solid var(--border-color)',
            borderRadius: 'var(--radius-md, 12px)',
            padding: '20px',
            display: 'flex',
            flexDirection: 'column',
            gap: '14px',
            boxShadow: 'var(--shadow-sm)'
          }}>
            <h4 style={{ fontSize: '1.02rem', fontWeight: 700, margin: 0, paddingBottom: '10px', borderBottom: '1px solid var(--border-color)', color: 'var(--text-primary)' }}>
              🏢 App & Company Identity
            </h4>

            <div>
              <label style={{ display: 'block', marginBottom: '6px', fontSize: '0.84rem', fontWeight: 600, color: 'var(--text-primary)' }}>
                Company Name <span style={{ color: 'var(--danger, #ef4444)' }}>*</span>
              </label>
              <input
                type="text"
                value={formData.company_name}
                onChange={e => handleChange('company_name', e.target.value)}
                placeholder="e.g. Acme Corporation"
                required
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  borderRadius: 'var(--radius-sm, 8px)',
                  border: '1px solid var(--border-color)',
                  background: 'var(--input-bg)',
                  color: 'var(--input-color)',
                  fontSize: '0.9rem'
                }}
              />
              <span style={{ display: 'block', fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '4px' }}>
                Displayed in the main top bar, employee dashboard, and letterheads.
              </span>
            </div>

            <div>
              <label style={{ display: 'block', marginBottom: '6px', fontSize: '0.84rem', fontWeight: 600, color: 'var(--text-primary)' }}>
                App / Portal Title
              </label>
              <input
                type="text"
                value={formData.app_title}
                onChange={e => handleChange('app_title', e.target.value)}
                placeholder="e.g. Acme HR Portal"
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  borderRadius: 'var(--radius-sm, 8px)',
                  border: '1px solid var(--border-color)',
                  background: 'var(--input-bg)',
                  color: 'var(--input-color)',
                  fontSize: '0.9rem'
                }}
              />
              <span style={{ display: 'block', fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '4px' }}>
                Displayed in browser tab titles and mobile app header.
              </span>
            </div>

            <div>
              <label style={{ display: 'block', marginBottom: '6px', fontSize: '0.84rem', fontWeight: 600, color: 'var(--text-primary)' }}>
                Tagline / Subtitle
              </label>
              <input
                type="text"
                value={formData.company_tagline}
                onChange={e => handleChange('company_tagline', e.target.value)}
                placeholder="e.g. Secure Attendance & HR Management Portal"
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  borderRadius: 'var(--radius-sm, 8px)',
                  border: '1px solid var(--border-color)',
                  background: 'var(--input-bg)',
                  color: 'var(--input-color)',
                  fontSize: '0.9rem'
                }}
              />
            </div>

            <div>
              <label style={{ display: 'block', marginBottom: '6px', fontSize: '0.84rem', fontWeight: 600, color: 'var(--text-primary)' }}>
                Default Currency Symbol
              </label>
              <input
                type="text"
                value={formData.currency_symbol}
                onChange={e => handleChange('currency_symbol', e.target.value)}
                placeholder="e.g. Rs, $, PKR, AED, EUR, £"
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  borderRadius: 'var(--radius-sm, 8px)',
                  border: '1px solid var(--border-color)',
                  background: 'var(--input-bg)',
                  color: 'var(--input-color)',
                  fontSize: '0.9rem'
                }}
              />
              <span style={{ display: 'block', fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '4px' }}>
                Used on payroll statements, salary calculations, and employee payslips.
              </span>
            </div>
          </div>

          {/* Card 2: Company Logo & Appearance */}
          <div style={{
            background: 'var(--bg-surface)',
            border: '1px solid var(--border-color)',
            borderRadius: 'var(--radius-md, 12px)',
            padding: '20px',
            display: 'flex',
            flexDirection: 'column',
            gap: '14px',
            boxShadow: 'var(--shadow-sm)'
          }}>
            <h4 style={{ fontSize: '1.02rem', fontWeight: 700, margin: 0, paddingBottom: '10px', borderBottom: '1px solid var(--border-color)', color: 'var(--text-primary)' }}>
              🎨 Company Logo & Icon
            </h4>

            <div style={{ display: 'flex', alignItems: 'center', gap: '18px', margin: '4px 0' }}>
              <div style={{
                width: '84px',
                height: '84px',
                borderRadius: 'var(--radius-sm, 10px)',
                border: '2px dashed var(--border-color-glow)',
                padding: '6px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                background: 'var(--bg-primary)',
                flexShrink: 0
              }}>
                <img 
                  src={formData.company_logo_url || '/icons/logo.png'} 
                  alt="Logo Preview" 
                  style={{ maxWidth: '100%', maxHeight: '100%', objectFit: 'contain' }}
                  onError={(e) => { (e.target as any).src = '/icons/logo.png'; }}
                />
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <label 
                  className="btn btn-secondary"
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '8px 16px',
                    borderRadius: 'var(--radius-sm, 8px)',
                    cursor: 'pointer',
                    fontSize: '0.85rem',
                    fontWeight: 600,
                    border: '1px solid var(--border-color)'
                  }}
                >
                  📁 Upload New Logo
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleLogoUpload}
                    style={{ display: 'none' }}
                  />
                </label>
                <div>
                  <button
                    type="button"
                    onClick={handleResetDefaultLogo}
                    style={{
                      background: 'none',
                      border: 'none',
                      color: 'var(--text-secondary)',
                      fontSize: '0.78rem',
                      cursor: 'pointer',
                      padding: 0,
                      textDecoration: 'underline'
                    }}
                  >
                    Reset to Default Logo
                  </button>
                </div>
              </div>
            </div>

            <div>
              <label style={{ display: 'block', marginBottom: '6px', fontSize: '0.84rem', fontWeight: 600, color: 'var(--text-primary)' }}>
                Or Custom Logo URL
              </label>
              <input
                type="text"
                value={formData.company_logo_url}
                onChange={e => handleChange('company_logo_url', e.target.value)}
                placeholder="https://yourdomain.com/logo.png"
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  borderRadius: 'var(--radius-sm, 8px)',
                  border: '1px solid var(--border-color)',
                  background: 'var(--input-bg)',
                  color: 'var(--input-color)',
                  fontSize: '0.9rem'
                }}
              />
              <span style={{ display: 'block', fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '4px' }}>
                PNG, JPG or SVG format supported.
              </span>
            </div>

            <div>
              <label style={{ display: 'block', marginBottom: '6px', fontSize: '0.84rem', fontWeight: 600, color: 'var(--text-primary)' }}>
                Standard Work Days Per Week
              </label>
              <select
                value={formData.office_working_days || 6}
                onChange={e => handleChange('office_working_days', parseInt(e.target.value, 10))}
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  borderRadius: 'var(--radius-sm, 8px)',
                  border: '1px solid var(--border-color)',
                  background: 'var(--input-bg)',
                  color: 'var(--input-color)',
                  fontSize: '0.9rem'
                }}
              >
                <option value={5}>5 Days (Mon - Fri)</option>
                <option value={6}>6 Days (Mon - Sat)</option>
                <option value={7}>7 Days (All Week)</option>
              </select>
            </div>
          </div>

          {/* Card 3: Contact & Headquarters */}
          <div style={{
            background: 'var(--bg-surface)',
            border: '1px solid var(--border-color)',
            borderRadius: 'var(--radius-md, 12px)',
            padding: '20px',
            gridColumn: '1 / -1',
            display: 'flex',
            flexDirection: 'column',
            gap: '14px',
            boxShadow: 'var(--shadow-sm)'
          }}>
            <h4 style={{ fontSize: '1.02rem', fontWeight: 700, margin: 0, paddingBottom: '10px', borderBottom: '1px solid var(--border-color)', color: 'var(--text-primary)' }}>
              📍 Company Contact & Headquarters Information
            </h4>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '14px' }}>
              <div>
                <label style={{ display: 'block', marginBottom: '6px', fontSize: '0.84rem', fontWeight: 600, color: 'var(--text-primary)' }}>
                  Official Email
                </label>
                <input
                  type="email"
                  value={formData.company_email}
                  onChange={e => handleChange('company_email', e.target.value)}
                  placeholder="hr@yourcompany.com"
                  style={{
                    width: '100%',
                    padding: '10px 14px',
                    borderRadius: 'var(--radius-sm, 8px)',
                    border: '1px solid var(--border-color)',
                    background: 'var(--input-bg)',
                    color: 'var(--input-color)',
                    fontSize: '0.9rem'
                  }}
                />
              </div>

              <div>
                <label style={{ display: 'block', marginBottom: '6px', fontSize: '0.84rem', fontWeight: 600, color: 'var(--text-primary)' }}>
                  Contact Phone Number
                </label>
                <input
                  type="tel"
                  value={formData.company_phone}
                  onChange={e => handleChange('company_phone', e.target.value)}
                  placeholder="+1 (555) 000-0000"
                  style={{
                    width: '100%',
                    padding: '10px 14px',
                    borderRadius: 'var(--radius-sm, 8px)',
                    border: '1px solid var(--border-color)',
                    background: 'var(--input-bg)',
                    color: 'var(--input-color)',
                    fontSize: '0.9rem'
                  }}
                />
              </div>

              <div>
                <label style={{ display: 'block', marginBottom: '6px', fontSize: '0.84rem', fontWeight: 600, color: 'var(--text-primary)' }}>
                  Company Website
                </label>
                <input
                  type="url"
                  value={formData.company_website}
                  onChange={e => handleChange('company_website', e.target.value)}
                  placeholder="https://yourcompany.com"
                  style={{
                    width: '100%',
                    padding: '10px 14px',
                    borderRadius: 'var(--radius-sm, 8px)',
                    border: '1px solid var(--border-color)',
                    background: 'var(--input-bg)',
                    color: 'var(--input-color)',
                    fontSize: '0.9rem'
                  }}
                />
              </div>
            </div>

            <div>
              <label style={{ display: 'block', marginBottom: '6px', fontSize: '0.84rem', fontWeight: 600, color: 'var(--text-primary)' }}>
                Office / Headquarters Address
              </label>
              <textarea
                rows={3}
                value={formData.company_address}
                onChange={e => handleChange('company_address', e.target.value)}
                placeholder="Building Name, Street, City, Country"
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  borderRadius: 'var(--radius-sm, 8px)',
                  border: '1px solid var(--border-color)',
                  background: 'var(--input-bg)',
                  color: 'var(--input-color)',
                  fontSize: '0.9rem'
                }}
              />
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div style={{ marginTop: '24px', display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
          <button
            type="submit"
            disabled={saving}
            className="btn btn-primary"
            style={{
              padding: '12px 28px',
              fontSize: '0.95rem',
              fontWeight: 700,
              borderRadius: 'var(--radius-sm, 8px)',
              cursor: saving ? 'wait' : 'pointer',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              boxShadow: 'var(--shadow-md)'
            }}
          >
            {saving ? 'Saving Changes...' : '💾 Save Company Profile & Branding'}
          </button>
        </div>
      </form>
    </div>
  );
};

export default CompanyProfileTab;
