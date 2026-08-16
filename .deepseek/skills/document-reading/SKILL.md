# Document Reading

Use this skill when the user asks the agent to inspect, summarize, compare, or extract information from PDF, Excel, or CSV files.

## Standard Input Folder

Look for local document inputs in:

```text
docs-input/
```

This folder is intentionally ignored by git except for `.gitkeep`, because PDF and spreadsheet files may contain sensitive data. Do not commit documents from this folder.

## Dependency Check

Before reading documents, check whether the required Python packages are available:

```bash
python -c "import pandas, openpyxl, pdfplumber; print('document dependencies available')"
```

On Windows, `py` may be available instead of `python`:

```powershell
py -c "import pandas, openpyxl, pdfplumber; print('document dependencies available')"
```

If a package is missing, do not auto-install silently. Tell the user what is missing and ask them to run one of these commands:

```bash
python -m pip install pandas openpyxl pdfplumber
```

```powershell
py -m pip install pandas openpyxl pdfplumber
```

For OCR on scanned PDFs, additional system tools are commonly needed:

- Tesseract OCR.
- Poppler utilities.
- Python packages such as `pytesseract` and `pdf2image`.

Do not assume OCR is available. Explain the requirement when a PDF appears to be image-only.

## Excel and CSV Reading

For `.xlsx` files:

- Use `pandas` with `openpyxl`.
- Read all sheets, not just the first sheet.
- Preserve sheet names in the summary.
- Inspect column names, row counts, empty rows, data types, and representative sample rows.
- If formulas matter, use `openpyxl` directly:
  - Load with `data_only=False` to inspect formulas.
  - Load with `data_only=True` to inspect cached formula results.
  - Make clear that Python libraries do not recalculate Excel formulas by themselves.

Suggested inspection snippet:

```python
from pathlib import Path
import pandas as pd
from openpyxl import load_workbook

path = Path("docs-input/example.xlsx")

workbook = load_workbook(path, data_only=False, read_only=False)
for sheet in workbook.sheetnames:
    ws = workbook[sheet]
    formulas = []
    for row in ws.iter_rows():
        for cell in row:
            if isinstance(cell.value, str) and cell.value.startswith("="):
                formulas.append((cell.coordinate, cell.value))
    print(sheet, "formulas:", formulas[:20])

sheets = pd.read_excel(path, sheet_name=None, engine="openpyxl")
for sheet_name, df in sheets.items():
    print(f"\n## {sheet_name}")
    print("rows:", len(df), "columns:", list(df.columns))
    print(df.head(10).to_string(index=False))
```

For `.csv` files:

- Use `pandas.read_csv`.
- Detect delimiter and encoding issues when parsing fails.
- Report row count, columns, inferred types, missing values, and sample rows.

Suggested CSV snippet:

```python
from pathlib import Path
import pandas as pd

path = Path("docs-input/example.csv")
df = pd.read_csv(path)
print("rows:", len(df), "columns:", list(df.columns))
print(df.dtypes)
print(df.head(20).to_string(index=False))
```

## PDF Reading

For text-based PDFs:

- Use `pdfplumber`.
- Extract text page by page.
- Extract tables separately instead of relying only on raw text.
- Preserve page numbers in notes and summaries.

Suggested PDF snippet:

```python
from pathlib import Path
import pdfplumber

path = Path("docs-input/example.pdf")

with pdfplumber.open(path) as pdf:
    for page_number, page in enumerate(pdf.pages, start=1):
        text = page.extract_text() or ""
        tables = page.extract_tables() or []
        print(f"\n## Page {page_number}")
        print(text[:4000])
        for table_index, table in enumerate(tables, start=1):
            print(f"\nTable {table_index}")
            for row in table[:20]:
                print(row)
```

## Scanned PDFs and OCR

If `pdfplumber` extracts little or no text from multiple pages, treat the file as likely scanned or image-only.

Recommended response:

- Tell the user the PDF appears to need OCR.
- Ask whether OCR tools are installed.
- If they want local OCR, suggest installing Tesseract, Poppler, `pytesseract`, and `pdf2image`.
- Avoid uploading sensitive PDFs to external services unless the user explicitly approves.

Example OCR dependency command after system tools are installed:

```bash
python -m pip install pytesseract pdf2image
```

## Output Expectations

When reporting findings:

- Cite the source filename and sheet/page number.
- Distinguish extracted facts from interpretation.
- Mention parsing limitations, missing dependencies, unreadable pages, or formula recalculation limitations.
- Do not commit extracted sensitive data into the repository.
