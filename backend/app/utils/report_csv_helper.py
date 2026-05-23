import csv
import io
from typing import List
from app.models import Expense, Income, Transfer

def generate_csv_report(
    report_type: str,
    expenses: List[Expense],
    incomes: List[Income],
    transfers: List[Transfer]
) -> str:
    """Generate CSV string from financial records based on report type."""
    output = io.StringIO()
    writer = csv.writer(output)
    
    if report_type == 'expenses':
        _write_expenses_csv(writer, expenses)
    elif report_type == 'incomes':
        _write_incomes_csv(writer, incomes)
    elif report_type == 'transfers':
        _write_transfers_csv(writer, transfers)
    else:
        # combined
        _write_combined_csv(writer, expenses, incomes, transfers)
        
    return output.getvalue()

def _write_expenses_csv(writer, expenses: List[Expense]):
    writer.writerow([
        "Date", "User", "Category", "Amount", "Currency", 
        "Project", "Payment Method", "Location", "Self Receipt", "Note", "Receipt Uploaded"
    ])
    for exp in expenses:
        writer.writerow([
            exp.date.strftime("%Y-%m-%d %H:%M") if exp.date else "",
            exp.owner.name if exp.owner else "Unknown",
            exp.category or "",
            exp.amount,
            exp.currency.value if hasattr(exp.currency, 'value') else str(exp.currency),
            exp.project or "",
            exp.payment_method or "",
            exp.location or "",
            "Yes" if exp.is_self_receipt else "No",
            exp.note or "",
            "Yes" if exp.photo_url else "No"
        ])

def _write_incomes_csv(writer, incomes: List[Income]):
    writer.writerow([
        "Date", "User", "Source", "Amount", "Currency", "Note"
    ])
    for inc in incomes:
        writer.writerow([
            inc.date.strftime("%Y-%m-%d %H:%M") if inc.date else "",
            inc.owner.name if inc.owner else "Unknown",
            inc.source or "",
            inc.amount,
            inc.currency.value if hasattr(inc.currency, 'value') else str(inc.currency),
            inc.note or ""
        ])

def _write_transfers_csv(writer, transfers: List[Transfer]):
    writer.writerow([
        "Date", "User", "Amount From", "Currency From", "Amount To", "Currency To", "Note"
    ])
    for tx in transfers:
        writer.writerow([
            tx.date.strftime("%Y-%m-%d %H:%M") if tx.date else "",
            tx.owner.name if tx.owner else "Unknown",
            tx.amount_from,
            tx.currency_from.value if hasattr(tx.currency_from, 'value') else str(tx.currency_from),
            tx.amount_to,
            tx.currency_to.value if hasattr(tx.currency_to, 'value') else str(tx.currency_to),
            tx.note or ""
        ])

def _write_combined_csv(writer, expenses: List[Expense], incomes: List[Income], transfers: List[Transfer]):
    writer.writerow([
        "Type", "Date", "User", "Category/Source", "Details/Project", 
        "Amount (Out)", "Currency (Out)", "Amount (In)", "Currency (In)", "Note"
    ])
    
    # We combine them and sort by date descending
    records = []
    for inc in incomes:
        records.append(('Income', inc.date, inc))
    for exp in expenses:
        records.append(('Expense', exp.date, exp))
    for tx in transfers:
        records.append(('Transfer', tx.date, tx))
        
    records.sort(key=lambda r: r[1] or datetime.min, reverse=True)
    
    for r_type, r_date, obj in records:
        date_str = r_date.strftime("%Y-%m-%d %H:%M") if r_date else ""
        user_name = obj.owner.name if obj.owner else "Unknown"
        
        if r_type == 'Income':
            curr = obj.currency.value if hasattr(obj.currency, 'value') else str(obj.currency)
            writer.writerow([
                "Income", date_str, user_name, obj.source or "", "", 
                "", "", obj.amount, curr, obj.note or ""
            ])
        elif r_type == 'Expense':
            curr = obj.currency.value if hasattr(obj.currency, 'value') else str(obj.currency)
            details = []
            if obj.project: details.append(f"Proj: {obj.project}")
            if obj.payment_method: details.append(f"Via: {obj.payment_method}")
            details_str = " | ".join(details)
            writer.writerow([
                "Expense", date_str, user_name, obj.category or "", details_str, 
                obj.amount, curr, "", "", obj.note or ""
            ])
        elif r_type == 'Transfer':
            curr_from = obj.currency_from.value if hasattr(obj.currency_from, 'value') else str(obj.currency_from)
            curr_to = obj.currency_to.value if hasattr(obj.currency_to, 'value') else str(obj.currency_to)
            writer.writerow([
                "Transfer", date_str, user_name, "Internal Transfer", "", 
                obj.amount_from, curr_from, obj.amount_to, curr_to, obj.note or ""
            ])
