import os
import pandas as pd

def df_to_html(df, title):
    html = f"<h2>{title}</h2>"
    html += f"""
    <table id="{title}">
      <thead>
        <tr>""" + ''.join(f"<th>{col}</th>" for col in df.columns) + """</tr>
        <tr>""" + ''.join(f"<th><input class='filter-input' onkeyup='filterTable({i}, \"{title}\")' placeholder='Filter {col}'></th>" for i, col in enumerate(df.columns)) + """</tr>
      </thead>
      <tbody>
    """
    for _, row in df.iterrows():
        status = str(row.get("status", "")).lower()
        css_class = "failed" if "fail" in status else "success"
        html += f"<tr class='{css_class}'>" + "".join(f"<td>{val}</td>" for val in row) + "</tr>\n"
    html += "</tbody></table><br><hr><br>"
    return html

def section_not_found(title):
    return f"<h2>{title}</h2><p><i>{title.capitalize()} step skipped — no data file found.</i></p><hr><br>"

def main():
    html = """
    <html><head><meta charset="UTF-8"><title>Workspace Report</title>
    <style>
    body { font-family: Arial; padding: 20px; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ccc; padding: 8px; }
    th { background-color: #f2f2f2; }
    tr.failed { background-color: #ffd6d6; }
    tr.success { background-color: #d6ffd6; }
    input.filter-input { width: 100%; }
    </style>
    </head><body>
    <h1>Workspace Rebuild & Baseline Report</h1>
    """

    files = {
        "rebuild": "data/rebuild_status.csv",
        "baseline": "data/baseline_status.csv",
        "wait": "data/wait_status.csv"
    }

    for section, filepath in files.items():
        if os.path.exists(filepath):
            df = pd.read_csv(filepath)
            html += df_to_html(df, section)
        else:
            html += section_not_found(section)

    html += """
    <script>
    function filterTable(col, tableId) {
      const table = document.getElementById(tableId);
      const input = table.querySelectorAll("input.filter-input")[col];
      const filter = input.value.toLowerCase();
      const rows = table.tBodies[0].rows;
      for (let i = 0; i < rows.length; i++) {
        const cell = rows[i].cells[col];
        rows[i].style.display = cell.textContent.toLowerCase().includes(filter) ? "" : "none";
      }
    }
    </script>
    </body></html>
    """

    with open("workspace_report.html", "w") as f:
        f.write(html)
    print("Report generated: workspace_report.html")

if __name__ == "__main__":
    main()
