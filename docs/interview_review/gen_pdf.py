from pathlib import Path
from fpdf import FPDF
import re, os

md_path  = Path('/Users/mac/Documents/flutter_core_project/docs/interview_review/REVIEW_PREP_COMPLETE.md')
pdf_path = Path('/Users/mac/Documents/flutter_core_project/docs/interview_review/INTERVIEW_PREP_COMPLETE.pdf')
font_regular = '/Users/mac/Documents/flutter_core_project/assets/fonts/BeVietnamPro-Regular.ttf'
font_bold    = '/Users/mac/Documents/flutter_core_project/assets/fonts/BeVietnamPro-Bold.ttf'

class PDF(FPDF):
    def footer(self):
        self.set_y(-12)
        self.set_font('BVP', size=8)
        self.set_text_color(150,150,150)
        self.cell(0, 6, f'Flutter Core Project - Interview Prep  |  Trang {self.page_no()}', align='C')
        self.set_text_color(0,0,0)

pdf = PDF(format='A4')
pdf.set_auto_page_break(auto=True, margin=18)
pdf.add_font('BVP',  '', font_regular)
pdf.add_font('BVP',  'B', font_bold)
pdf.add_page()
pdf.set_left_margin(15)
pdf.set_right_margin(15)

def clean(t):
    t = re.sub(r'\*\*(.+?)\*\*', r'\1', t)
    t = re.sub(r'`(.+?)`', r'\1', t)
    t = re.sub(r'\[(.+?)\]\(.+?\)', r'\1', t)
    return t

lines = md_path.read_text(encoding='utf-8').splitlines()
in_code = False

for raw in lines:
    line = raw

    if line.strip().startswith('```'):
        in_code = not in_code
        continue

    if in_code:
        pdf.set_font('BVP', '', 8)
        pdf.set_text_color(40,40,40)
        safe = line.replace('\t','    ')
        pdf.multi_cell(0, 4, safe)
        pdf.set_text_color(0,0,0)
        continue

    if not line.strip():
        pdf.ln(2)
        continue

    stripped = line.strip()

    if set(stripped) == {'-'} and len(stripped) >= 3:
        pdf.set_draw_color(200,200,200)
        pdf.line(15, pdf.get_y(), 195, pdf.get_y())
        pdf.ln(3)
        continue

    if line.startswith('# ') and not line.startswith('## '):
        pdf.set_font('BVP', 'B', 16)
        pdf.set_text_color(20,20,120)
        pdf.multi_cell(0, 9, clean(line[2:]))
        pdf.set_text_color(0,0,0)
        pdf.ln(2)
        continue

    if line.startswith('## ') and not line.startswith('### '):
        pdf.set_font('BVP', 'B', 13)
        pdf.set_text_color(20,80,160)
        pdf.ln(3)
        pdf.multi_cell(0, 7, clean(line[3:]))
        pdf.set_draw_color(20,80,160)
        pdf.line(15, pdf.get_y(), 195, pdf.get_y())
        pdf.ln(2)
        pdf.set_text_color(0,0,0)
        continue

    if line.startswith('### ') and not line.startswith('#### '):
        pdf.set_font('BVP', 'B', 11)
        pdf.set_text_color(40,100,180)
        pdf.ln(2)
        pdf.multi_cell(0, 6, clean(line[4:]))
        pdf.set_text_color(0,0,0)
        pdf.ln(1)
        continue

    if line.startswith('#### '):
        pdf.set_font('BVP', 'B', 10)
        pdf.set_text_color(60,60,60)
        pdf.multi_cell(0, 6, clean(line[5:]))
        pdf.set_text_color(0,0,0)
        continue

    if stripped.startswith('|'):
        cells = [c.strip() for c in stripped.strip('|').split('|')]
        if all(set(c.replace('-','').replace(':','').replace(' ','')) <= set() for c in cells):
            continue
        pdf.set_font('BVP', '', 7)
        ncols = max(len(cells), 1)
        col_w = 180 / ncols
        for c in cells:
            pdf.cell(col_w, 5, c[:40], border=1)
        pdf.ln()
        continue

    if stripped.startswith('- [ ]') or stripped.startswith('- [x]'):
        mark = '(x) ' if '[x]' in stripped else '( ) '
        text = re.sub(r'- \[.?\] ', '', stripped)
        pdf.set_font('BVP', '', 9)
        pdf.multi_cell(0, 5, '  ' + mark + clean(text))
        continue

    if stripped.startswith('- ') or stripped.startswith('* '):
        indent = len(line) - len(line.lstrip())
        text = stripped[2:]
        level = min(indent // 2, 3)
        prefix = '  ' * level + '• '
        pdf.set_font('BVP', '', 9)
        pdf.set_x(15)
        pdf.multi_cell(0, 5, prefix + clean(text))
        continue

    if re.match(r'^\s*\d+\. ', line):
        text = re.sub(r'^\s*\d+\. ', '', line)
        pdf.set_font('BVP', '', 9)
        pdf.set_x(15)
        pdf.multi_cell(0, 5, '  ' + clean(text))
        continue

    if stripped.startswith('>'):
        pdf.set_font('BVP', 'B', 9)
        pdf.set_text_color(80,80,80)
        pdf.set_x(15)
        pdf.multi_cell(0, 5, clean(stripped[1:].strip()))
        pdf.set_text_color(0,0,0)
        continue

    pdf.set_font('BVP', '', 9)
    pdf.multi_cell(0, 5, clean(stripped))

pdf.output(str(pdf_path))
size_kb = os.path.getsize(pdf_path) // 1024
print(f'[ok] PDF: {pdf_path}')
print(f'[ok] Size: {size_kb} KB, Pages: {pdf.page}')

