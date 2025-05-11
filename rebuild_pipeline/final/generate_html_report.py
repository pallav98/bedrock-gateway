import pandas as pd

def df_to_html(df, title):
    html = f"<h2>{title}</h2>"
    html += """
    <table id="{0}">
      <thead>
        <tr>""" + ''.join(f"<th>{col}</th>" for col in df.columns) + """</tr>
        <tr>""" + ''.join(f"<th><input class='filter-input' onkeyup='filterTable({i}, \"{0}\")' placeholder='Filter {col}'></th>" for i, col in enumerate(df.columns)) + """</tr>
      </thead>
      <tbody>
    """
    for _, row in df.iterrows():
        status = str(row.get("status", "")).lower()
        css_class = "failed" if "fail" in status else "success"
        html += f"<tr class='{css_class}'>" + "".join(f"<td>{val}</td>" for val in row) + "</tr>\n"
    html += "</tbody></table><br><hr><br>"
    return html

def main():
    rebuild_df = pd.read_csv("data/rebuild_status.csv")
    baseline_df = pd.read_csv("data/baseline_status.csv")

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
    html += df_to_html(rebuild_df, "rebuild")
    html += df_to_html(baseline_df, "baseline")
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