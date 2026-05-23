import io
from datetime import datetime
from typing import List, Dict, Any
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from app.models import Expense, Income, Transfer

PRIMARY_COLOR = colors.HexColor('#3D1B5B') # Deep Purple
SECONDARY_COLOR = colors.HexColor('#FF5200') # Flame Orange

def generate_pdf_report(
    report_type: str,
    expenses: List[Expense],
    incomes: List[Income],
    transfers: List[Transfer],
    filters_desc: Dict[str, Any]
) -> bytes:
    """Generate professional PDF report formatted with Deep Purple style."""
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer, pagesize=letter,
        rightMargin=36, leftMargin=36, topMargin=36, bottomMargin=36
    )
    
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        'DocTitle', parent=styles['Heading1'], fontName='Helvetica-Bold',
        fontSize=18, leading=22, textColor=PRIMARY_COLOR
    )
    subtitle_style = ParagraphStyle(
        'DocSubtitle', parent=styles['Normal'], fontName='Helvetica-Bold',
        fontSize=11, leading=15, textColor=colors.HexColor('#4B5563')
    )
    section_style = ParagraphStyle(
        'SecTitle', parent=styles['Heading2'], fontName='Helvetica-Bold',
        fontSize=12, leading=16, textColor=PRIMARY_COLOR, spaceBefore=10, spaceAfter=6
    )
    meta_style = ParagraphStyle(
        'MetaStyle', parent=styles['Normal'], fontName='Helvetica',
        fontSize=8, leading=11, textColor=colors.HexColor('#4B5563')
    )
    cell_style = ParagraphStyle(
        'CellText', parent=styles['Normal'], fontName='Helvetica',
        fontSize=8, leading=10, textColor=colors.HexColor('#1F2937')
    )
    cell_header_style = ParagraphStyle(
        'CellHeader', parent=styles['Normal'], fontName='Helvetica-Bold',
        fontSize=8, leading=10, textColor=colors.white
    )
    
    story = []
    
    # 1. Header Section
    story.append(Paragraph("Awoken The Nations Ministries", title_style))
    story.append(Paragraph(f"Financial Audit Report — {report_type.upper()}", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=PRIMARY_COLOR, spaceBefore=3, spaceAfter=6))
    
    # 2. Metadata details
    filters_text = []
    if filters_desc.get("date_range"):
        filters_text.append(f"<b>Date Range:</b> {filters_desc['date_range']}")
    if filters_desc.get("category"):
        filters_text.append(f"<b>Category:</b> {filters_desc['category']}")
    if filters_desc.get("project"):
        filters_text.append(f"<b>Project:</b> {filters_desc['project']}")
    if filters_desc.get("user"):
        filters_text.append(f"<b>User:</b> {filters_desc['user']}")
        
    meta_html = f"<b>Generated on:</b> {datetime.now().strftime('%Y-%m-%d %H:%M')}"
    if filters_text:
        meta_html += " | " + " | ".join(filters_text)
    else:
        meta_html += " | <b>Filters:</b> All Records"
    
    story.append(Paragraph(meta_html, meta_style))
    story.append(Spacer(1, 10))
    
    # 3. Summary Cash Flow
    _add_summary_section(story, report_type, expenses, incomes, transfers, meta_style)
    story.append(Spacer(1, 10))
    
    # 4. Data Tables
    if report_type in ['combined', 'incomes'] and incomes:
        story.append(Paragraph("INCOMES", section_style))
        story.append(_build_incomes_table(incomes, cell_style, cell_header_style))
        story.append(Spacer(1, 10))
        
    if report_type in ['combined', 'expenses'] and expenses:
        story.append(Paragraph("EXPENSES", section_style))
        story.append(_build_expenses_table(expenses, cell_style, cell_header_style))
        story.append(Spacer(1, 10))
        
    if report_type in ['combined', 'transfers'] and transfers:
        story.append(Paragraph("TRANSFERS", section_style))
        story.append(_build_transfers_table(transfers, cell_style, cell_header_style))
        story.append(Spacer(1, 10))
        
    doc.build(story)
    pdf_bytes = buffer.getvalue()
    buffer.close()
    return pdf_bytes

def _add_summary_section(story: List[Any], report_type: str, expenses: List[Expense], incomes: List[Income], transfers: List[Transfer], style: ParagraphStyle):
    """Calculates sums per currency and adds a clean Summary Table."""
    currencies = ["USD", "TZS", "KES"]
    sums = {curr: {"in": 0.0, "out": 0.0, "net": 0.0} for curr in currencies}
    
    for inc in incomes:
        curr = inc.currency.value if hasattr(inc.currency, 'value') else str(inc.currency)
        if curr in sums:
            sums[curr]["in"] += inc.amount
            sums[curr]["net"] += inc.amount
            
    for exp in expenses:
        curr = exp.currency.value if hasattr(exp.currency, 'value') else str(exp.currency)
        if curr in sums:
            sums[curr]["out"] += exp.amount
            sums[curr]["net"] -= exp.amount
            
    # Format the cash flow text
    lines = []
    for curr in currencies:
        s = sums[curr]
        if s["in"] > 0 or s["out"] > 0:
            lines.append(f"<b>{curr}</b> &nbsp;—&nbsp; Inflow: {s['in']:,.2f} &nbsp;|&nbsp; Outflow: {s['out']:,.2f} &nbsp;|&nbsp; Net: {s['net']:,.2f}")
            
    summary_text = "<b>Cash Flow Summary:</b><br/>" + ("<br/>".join(lines) if lines else "No transaction data found for the selected filters.")
    
    summary_table_data = [[Paragraph(summary_text, style)]]
    summary_table = Table(summary_table_data, colWidths=[540])
    summary_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F5F3F7')),
        ('BORDER', (0,0), (-1,-1), 1, PRIMARY_COLOR),
        ('PADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(summary_table)

def _build_incomes_table(incomes: List[Income], cell_style: ParagraphStyle, header_style: ParagraphStyle) -> Table:
    data = [[
        Paragraph("Date", header_style),
        Paragraph("User", header_style),
        Paragraph("Source", header_style),
        Paragraph("Note", header_style),
        Paragraph("Amount", header_style)
    ]]
    
    for inc in incomes:
        date_str = inc.date.strftime("%Y-%m-%d") if inc.date else ""
        user_name = inc.owner.name if inc.owner else "Unknown"
        curr_str = inc.currency.value if hasattr(inc.currency, 'value') else str(inc.currency)
        amount_str = f"{inc.amount:,.2f} {curr_str}"
        
        data.append([
            Paragraph(date_str, cell_style),
            Paragraph(user_name, cell_style),
            Paragraph(inc.source or "", cell_style),
            Paragraph(inc.note or "", cell_style),
            Paragraph(amount_str, cell_style)
        ])
        
    t = Table(data, colWidths=[65, 95, 90, 205, 85], repeatRows=1)
    t.setStyle(_default_table_style(len(data)))
    return t

def _build_expenses_table(expenses: List[Expense], cell_style: ParagraphStyle, header_style: ParagraphStyle) -> Table:
    data = [[
        Paragraph("Date", header_style),
        Paragraph("User", header_style),
        Paragraph("Category", header_style),
        Paragraph("Amount", header_style),
        Paragraph("Note / Details", header_style),
        Paragraph("Receipt", header_style)
    ]]
    
    for exp in expenses:
        date_str = exp.date.strftime("%Y-%m-%d") if exp.date else ""
        user_name = exp.owner.name if exp.owner else "Unknown"
        curr_str = exp.currency.value if hasattr(exp.currency, 'value') else str(exp.currency)
        amount_str = f"{exp.amount:,.2f} {curr_str}"
        
        details = []
        if exp.note: details.append(exp.note)
        if exp.project: details.append(f"Proj: {exp.project}")
        if exp.payment_method: details.append(f"Via: {exp.payment_method}")
        details_str = " | ".join(details)
        
        receipt_status = "Self-Rec" if exp.is_self_receipt else ("Yes" if exp.photo_url else "No")
        
        data.append([
            Paragraph(date_str, cell_style),
            Paragraph(user_name, cell_style),
            Paragraph(exp.category or "", cell_style),
            Paragraph(amount_str, cell_style),
            Paragraph(details_str, cell_style),
            Paragraph(receipt_status, cell_style)
        ])
        
    t = Table(data, colWidths=[65, 80, 85, 75, 175, 60], repeatRows=1)
    t.setStyle(_default_table_style(len(data)))
    return t

def _build_transfers_table(transfers: List[Transfer], cell_style: ParagraphStyle, header_style: ParagraphStyle) -> Table:
    data = [[
        Paragraph("Date", header_style),
        Paragraph("User", header_style),
        Paragraph("From", header_style),
        Paragraph("To", header_style),
        Paragraph("Note", header_style)
    ]]
    
    for tx in transfers:
        date_str = tx.date.strftime("%Y-%m-%d") if tx.date else ""
        user_name = tx.owner.name if tx.owner else "Unknown"
        curr_from = tx.currency_from.value if hasattr(tx.currency_from, 'value') else str(tx.currency_from)
        curr_to = tx.currency_to.value if hasattr(tx.currency_to, 'value') else str(tx.currency_to)
        
        from_str = f"{tx.amount_from:,.2f} {curr_from}"
        to_str = f"{tx.amount_to:,.2f} {curr_to}"
        
        data.append([
            Paragraph(date_str, cell_style),
            Paragraph(user_name, cell_style),
            Paragraph(from_str, cell_style),
            Paragraph(to_str, cell_style),
            Paragraph(tx.note or "", cell_style)
        ])
        
    t = Table(data, colWidths=[65, 95, 95, 95, 190], repeatRows=1)
    t.setStyle(_default_table_style(len(data)))
    return t

def _default_table_style(rows_count: int) -> TableStyle:
    t_style = [
        ('BACKGROUND', (0,0), (-1,0), PRIMARY_COLOR),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('BOTTOMPADDING', (0,0), (-1,0), 4),
        ('TOPPADDING', (0,0), (-1,0), 4),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#E5E7EB')),
    ]
    for i in range(1, rows_count):
        if i % 2 == 0:
            t_style.append(('BACKGROUND', (0,i), (-1,i), colors.HexColor('#F3F4F6')))
    return TableStyle(t_style)
