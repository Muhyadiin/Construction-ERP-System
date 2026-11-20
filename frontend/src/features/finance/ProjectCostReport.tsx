import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { apiGet } from '@/shared/lib/api';
import { useAuthStore } from '@/stores/useAuthStore';

const costFields = [
  'original_budget', 'budget_changes', 'current_budget', 'actual_cost', 'remaining_commitments',
  'cash_paid', 'uncommitted_forecast', 'forecast_final_cost', 'budget_variance',
] as const;
const contractFields = [
  'original_contract_value', 'contract_changes', 'current_contract_value', 'forecast_profit', 'forecast_margin_pct',
] as const;

type Amount = string | null;
type CurrencyRow = Record<typeof costFields[number], Amount> & {
  currency: string;
  forecast_status: 'ready' | 'missing_forecast' | 'unreconciled' | 'unknown_currency';
};
type Report = Record<typeof contractFields[number], Amount> & {
  currencies: CurrencyRow[];
  contract_currency: string | null;
  requires_subcontract_review: boolean;
  contract_status: 'available' | 'missing' | 'review_contracts';
};

function currencyName(code: string) {
  return code === 'SLS' ? 'SL SH' : code;
}

export function ProjectCostReport({ projectId }: { projectId: string }) {
  const userId = useAuthStore((s) => s.userId);
  const preferenceKey = 'kobci.costReport.language.' + (userId ?? 'local');
  const { i18n } = useTranslation();
  const [language, setLanguage] = useState(() => {
    let saved: string | null = null;
    try { saved = localStorage.getItem(preferenceKey); } catch { /* Storage is optional. */ }
    return saved === 'so' || (!saved && i18n.language?.startsWith('so')) ? 'so' : 'en';
  });
  const { t } = useTranslation('costReport', { lng: language });
  const { data, isError, refetch } = useQuery({
    queryKey: ['finance', 'project-cost-report', projectId],
    queryFn: () => apiGet<Report>(`/v1/finance/project-cost-report/?project_id=${encodeURIComponent(projectId)}`),
  });
  const formatter = new Intl.NumberFormat(language, { minimumFractionDigits: 2, maximumFractionDigits: 4 });
  function figure(key: string, value: Amount, unit = '') {
    // Modern Intl accepts decimal strings directly, preserving all digits.
    const formatted = value === null ? t('unavailable') : formatter.format(value as Intl.StringNumericLiteral) + unit;
    return <div key={key} className="flex justify-between gap-4 border-b border-border-light py-2">
      <dt className="text-content-secondary">{t(key)}</dt>
      <dd className="text-end font-medium tabular-nums">{formatted}</dd>
    </div>;
  }
  return <section lang={language} className="space-y-4 rounded-xl border border-border-light bg-surface-primary p-4">
    <header className="flex flex-wrap items-center justify-between gap-3">
      <h2 className="text-lg font-semibold">{t('title')}</h2>
      <label className="flex items-center gap-2 text-sm">{t('language')}
        <select value={language} className="rounded border border-border bg-surface-primary p-2"
          onChange={(e) => {
            const next = e.target.value;
            setLanguage(next);
            try { localStorage.setItem(preferenceKey, next); } catch { /* Preference lasts for this session. */ }
          }}>
          <option value="en" lang="en">English</option><option value="so" lang="so">Soomaali</option>
        </select>
      </label>
    </header>
    {isError ? <div role="alert">{t('error')} <button className="underline" onClick={() => void refetch()}>{t('retry')}</button></div>
      : !data ? <p role="status">{t('loading')}</p> : <>
        <p className="text-sm text-content-secondary">{t('basis')}</p>
        {data.currencies.length === 0 && <p>{t('empty')}</p>}
        {(data.currencies.length > 1 || data.currencies.some((r) => data.contract_currency && r.currency !== data.contract_currency)) && <p>{t('mixed')}</p>}
        <div className="grid gap-5 lg:grid-cols-2">{data.currencies.map((row) => (
          <section key={row.currency}>
            <h3 className="font-semibold">{currencyName(row.currency) || t('unknown_currency')}</h3>
            <dl className="text-sm">{costFields.map((key) => figure(key, row[key]))}</dl>
            {row.forecast_status !== 'ready' && <p className="mt-2 text-sm">{t(row.forecast_status)}</p>}
          </section>
        ))}</div>
        <h3 className="font-semibold">{t('contract')} {currencyName(data.contract_currency ?? '')}</h3>
        {data.requires_subcontract_review && <p>{t('subcontract_review')}</p>}
        {data.contract_status === 'available'
          ? <dl className="text-sm">{contractFields.map((key) => figure(key, data[key], key === 'forecast_margin_pct' ? '%' : ''))}</dl>
          : <p>{t(data.contract_status)}</p>}
      </>}
  </section>;
}
