import { beforeEach, expect, it, vi } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import '@/app/i18n';
import { apiGet } from '@/shared/lib/api';
import { ProjectCostReport } from '../ProjectCostReport';

vi.unmock('react-i18next');
vi.mock('@/shared/lib/api', () => ({ apiGet: vi.fn() }));

function mount() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<QueryClientProvider client={client}><ProjectCostReport projectId="demo" /></QueryClientProvider>);
}

beforeEach(() => {
  vi.clearAllMocks();
  localStorage.clear();
});

it('keeps exact amounts, project and report selection when switching language', async () => {
  vi.mocked(apiGet).mockResolvedValue({
    currencies: [{
      currency: 'SLS', original_budget: '900719925474099.99', budget_changes: '0', current_budget: '750',
      actual_cost: '250', remaining_commitments: '100', cash_paid: '20', uncommitted_forecast: null,
      forecast_final_cost: null, budget_variance: null, forecast_status: 'missing_forecast',
    }], contract_status: 'missing', contract_currency: null,
  });
  const view = mount();
  expect(await screen.findByText('900,719,925,474,099.99')).toBeDefined();
  fireEvent.change(screen.getByLabelText('Report language'), { target: { value: 'so' } });
  expect(await screen.findByRole('heading', { name: 'Xakamaynta kharashaadka mashruuca' })).toBeDefined();
  expect(screen.getByText('Miisaaniyaddii asalka ahayd')).toBeDefined();
  expect(screen.getByText('SL SH')).toBeDefined();
  expect(screen.queryByText('Original budget')).toBeNull();
  expect(vi.mocked(apiGet)).toHaveBeenCalledTimes(1);
  view.unmount();
  mount();
  expect(await screen.findByLabelText('Luqadda warbixinta')).toHaveValue('so');
  expect(vi.mocked(apiGet)).toHaveBeenCalledWith('/v1/finance/project-cost-report/?project_id=demo');
});

it('distinguishes a failed request from a project with no costs', async () => {
  vi.mocked(apiGet).mockRejectedValueOnce(new Error('Offline')).mockResolvedValueOnce({
    currencies: [], contract_status: 'missing', contract_currency: null,
  });
  mount();
  expect(await screen.findByRole('alert')).toHaveTextContent('could not be loaded');
  fireEvent.click(screen.getByRole('button', { name: 'Retry' }));
  expect(await screen.findByText('No project costs or budgets have been recorded.')).toBeDefined();
});
