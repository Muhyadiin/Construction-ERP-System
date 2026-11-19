"""Project cost control in the original currencies of its commercial records."""

from decimal import ROUND_HALF_UP, Decimal
from typing import Literal
from uuid import UUID

from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.contracts.models import Contract
from app.modules.finance.cost_position import load_cost_position
from app.modules.finance.repository import BudgetRepository

ZERO = Decimal("0")


class CurrencyCostReport(BaseModel):
    currency: str
    original_budget: Decimal | None
    budget_changes: Decimal | None
    current_budget: Decimal | None
    actual_cost: Decimal
    remaining_commitments: Decimal
    cash_paid: Decimal
    forecast_status: Literal["ready", "missing_forecast", "unreconciled", "unknown_currency"]
    uncommitted_forecast: Decimal | None = None
    forecast_final_cost: Decimal | None = None
    budget_variance: Decimal | None = None


class ProjectCostReport(BaseModel):
    currencies: list[CurrencyCostReport]
    contract_status: Literal["available", "missing", "review_contracts"]
    contract_currency: str | None = None
    original_contract_value: Decimal | None = None
    contract_changes: Decimal | None = None
    current_contract_value: Decimal | None = None
    requires_subcontract_review: bool = False
    forecast_profit: Decimal | None = None
    forecast_margin_pct: Decimal | None = None


async def project_cost_report(session: AsyncSession, project_id: UUID) -> ProjectCostReport:
    """Read the same project and sources as Finance. Never add unlike currencies."""
    budgets = await BudgetRepository(session).aggregate_for_dashboard(project_id=project_id)
    position = await load_cost_position(session, project_id=project_id)
    # Include unlabelled legacy records so their presence also blocks project profit.
    codes = set(budgets["original_by_currency"]) | set(position.actual) | set(position.committed) | set(position.paid)
    rows = []
    for code in sorted(codes):
        original = budgets["original_by_currency"].get(code)
        revised = budgets["revised_by_currency"].get(code)
        actual = position.actual.get(code, ZERO)
        committed = position.committed.get(code, ZERO)
        row = CurrencyCostReport(
            currency=code,
            original_budget=original,
            current_budget=revised,
            budget_changes=revised - original if revised is not None and original is not None else None,
            actual_cost=actual,
            remaining_commitments=committed,
            cash_paid=position.paid.get(code, ZERO),
            forecast_status="missing_forecast",
        )
        if not code:
            row.forecast_status = "unknown_currency"
        elif budgets["missing_forecasts"].get(code) == 0:
            # Manually entered values and pending synchronization can leave
            # budget allocations out of step with the underlying documents.
            if (actual, committed) == (budgets["actual_by_currency"][code], budgets["committed_by_currency"][code]):
                row.forecast_status = "ready"
                row.uncommitted_forecast = budgets["uncommitted_by_currency"][code]
                row.forecast_final_cost = actual + committed + row.uncommitted_forecast
                row.budget_variance = revised - row.forecast_final_cost
            else:
                row.forecast_status = "unreconciled"
        rows.append(row)

    # Framework ceilings, parent/child contracts and terminated jobs require
    # commercial reconciliation. Limit the read to the two rows needed to
    # distinguish an unambiguous prime contract from multiple candidates.
    contracts = (
        (
            await session.execute(
                select(Contract)
                .where(
                    Contract.project_id == project_id,
                    Contract.counterparty_type == "client",
                    Contract.status != "draft",
                )
                .limit(2)
            )
        )
        .scalars()
        .all()
    )
    report = ProjectCostReport(currencies=rows, contract_status="missing")
    if not contracts:
        return report
    contract = contracts[0]
    if (
        len(contracts) != 1
        or contract.parent_contract_id
        or not contract.currency
        or not contract.signed_at
        or contract.status not in {"active", "suspended", "completed"}
        or contract.contract_type not in {"lump_sum", "design_build"}
        or contract.original_contract_value is None
    ):
        report.contract_status = "review_contracts"
        return report
    report.contract_status = "available"
    report.contract_currency = contract.currency
    report.original_contract_value = contract.original_contract_value
    report.current_contract_value = contract.total_value
    report.contract_changes = contract.total_value - contract.original_contract_value
    if len(rows) == 1 and rows[0].currency == contract.currency and rows[0].forecast_final_cost is not None:
        from app.modules.subcontractors.service import SubcontractorService

        if await SubcontractorService(session).find_unlinked_twins(project_id):
            report.requires_subcontract_review = True
            return report
        report.forecast_profit = contract.total_value - rows[0].forecast_final_cost
        if contract.total_value > ZERO:
            report.forecast_margin_pct = (100 * report.forecast_profit / contract.total_value).quantize(
                Decimal("0.01"), rounding=ROUND_HALF_UP
            )
    return report
