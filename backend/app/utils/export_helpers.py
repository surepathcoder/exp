import csv
import io
from datetime import datetime
from typing import List, Dict, Any
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from app.models import Expense

def generate_csv(expenses: List[Expense]) -> str:
    """Generate CSV string from list of expenses."""
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow([
        "Date", "User", "Category", "Amount", "Currency", 
        "Payment Method", "Location", "Self Receipt", "Note", "Receipt Uploaded"
    ])
    
    for exp in expenses:
        writer.writerow([
            exp.date.strftime("%Y-%m-%d %H:%M") if exp.date else "",
            exp.owner.name if exp.owner else "Unknown",
            exp.category or "",
            exp.amount,
            exp.currency.value if hasattr(exp.currency, 'value') else str(exp.currency),
            exp.payment_method or "",
            exp.location or "",
            "Yes" if exp.is_self_receipt else "No",
            exp.note or "",
            "Yes" if exp.photo_url else "No"
        ])
    return output.getvalue()

def generate_pdf(expenses: List[Expense], filters_desc: Dict[str, Any]) -> bytes:
    """Generate beautifully formatted PDF report for Awoken The Nations Ministries."""
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=letter,
        rightMargin=36,
        leftMargin=36,
        topMargin=36,
        bottomMargin=36
    )
    
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=18,
        leading=22,
        textColor=colors.HexColor('#1E3A8A')
    )
    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=colors.HexColor('#4B5563')
    )
    meta_style = ParagraphStyle(
        'MetaStyle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=12,
        textColor=colors.HexColor('#374151')
    )
    cell_style = ParagraphStyle(
        'CellText',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=11,
        textColor=colors.HexColor('#1F2937')
    )
    cell_header_style = ParagraphStyle(
        'CellHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=9,
        leading=11,
        textColor=colors.white
    )
    
    story = []
    
    # 1. Title/Header Section
    story.append(Paragraph("Awoken The Nations Ministries", title_style))
    story.append(Paragraph("Expense Report", subtitle_style))
    story.append(Spacer(1, 6))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor('#1E3A8A'), spaceBefore=2, spaceAfter=8))
    
    # 2. Metadata details
    filters_text = []
    if filters_desc.get("date_range"):
        filters_text.append(f"<b>Date Range:</b> {filters_desc['date_range']}")
    if filters_desc.get("category"):
        filters_text.append(f"<b>Category:</b> {filters_desc['category']}")
    if filters_desc.get("user"):
        filters_text.append(f"<b>User:</b> {filters_desc['user']}")
        
    meta_html = f"<b>Generated on:</b> {datetime.now().strftime('%Y-%m-%d %H:%M')}<br/>"
    if filters_text:
        meta_html += " | ".join(filters_text)
    else:
        meta_html += "<b>Filters:</b> All Expenses"
        
    story.append(Paragraph(meta_html, meta_style))
    story.append(Spacer(1, 10))
    
    # 3. Currency Summary Box
    totals = {}
    for exp in expenses:
        curr = exp.currency.value if hasattr(exp.currency, 'value') else str(exp.currency)
        totals[curr] = totals.get(curr, 0.0) + exp.amount
        
    summary_parts = []
    for curr, total in sorted(totals.items()):
        summary_parts.append(f"<b>{curr}:</b> {total:,.2f}")
    
    summary_text = "<b>Total Summaries:</b> " + (" &nbsp;&nbsp;|&nbsp;&nbsp; ".join(summary_parts) if summary_parts else "No expenses found")
    
    summary_table_data = [[Paragraph(summary_text, meta_style)]]
    summary_table = Table(summary_table_data, colWidths=[540])
    summary_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#EFF6FF')),
        ('BORDER', (0,0), (-1,-1), 1, colors.HexColor('#BFDBFE')),
        ('PADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(summary_table)
    story.append(Spacer(1, 12))
    
    # 4. Expenses Table
    table_data = [[
        Paragraph("Date", cell_header_style),
        Paragraph("User", cell_header_style),
        Paragraph("Category", cell_header_style),
        Paragraph("Amount", cell_header_style),
        Paragraph("Note / Details", cell_header_style),
        Paragraph("Receipt", cell_header_style)
    ]]
    
    for exp in expenses:
        date_str = exp.date.strftime("%Y-%m-%d") if exp.date else ""
        user_name = exp.owner.name if exp.owner else "Unknown"
        curr_str = exp.currency.value if hasattr(exp.currency, 'value') else str(exp.currency)
        amount_str = f"{exp.amount:,.2f} {curr_str}"
        note_str = exp.note or ""
        
        details = []
        if note_str:
            details.append(note_str)
        if exp.payment_method:
            details.append(f"Via: {exp.payment_method}")
        if exp.location:
            details.append(f"Loc: {exp.location}")
        details_str = " | ".join(details)
        
        receipt_status = "Self-Rec" if exp.is_self_receipt else ("Yes" if exp.photo_url else "No")
        
        table_data.append([
            Paragraph(date_str, cell_style),
            Paragraph(user_name, cell_style),
            Paragraph(exp.category or "", cell_style),
            Paragraph(amount_str, cell_style),
            Paragraph(details_str, cell_style),
            Paragraph(receipt_status, cell_style)
        ])
        
    col_widths = [65, 80, 85, 75, 175, 60]
    t = Table(table_data, colWidths=col_widths, repeatRows=1)
    
    t_style = [
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#1E3A8A')),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('BOTTOMPADDING', (0,0), (-1,0), 6),
        ('TOPPADDING', (0,0), (-1,0), 6),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#E5E7EB')),
    ]
    
    for i in range(1, len(table_data)):
        if i % 2 == 0:
            t_style.append(('BACKGROUND', (0,i), (-1,i), colors.HexColor('#F9FAFB')))
            
    t.setStyle(TableStyle(t_style))
    story.append(t)
    
    doc.build(story)
    pdf_bytes = buffer.getvalue()
    buffer.close()
    return pdf_bytes
