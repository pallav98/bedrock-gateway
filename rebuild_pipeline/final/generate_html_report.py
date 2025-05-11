import os
import pandas as pd

def df_to_html(df, title):
    html = f"<h2 style='font-family:Arial;'>{title}</h2>"
    html += """
    <table border="1" cellpadding="6" cellspacing="0" width="100%" style="border-collapse: collapse; font-family: Arial; font-size: 14px;">
      <thead>
        <tr style="background-color: #f2f2f2;">""" + ''.join(f"<th>{col}</th>" for col in df.columns) + """</tr>
      </thead>
      <tbody>
    """
    for _, row in df.iterrows():
        status = str(row.get("status", "")).lower()
        bg_color = "#ffd6d6" if "fail" in status else "#d6ffd6"
        html += f"<tr style='background-color: {bg_color};'>" + "".join(f"<td>{val}</td>" for val in row) + "</tr>\n"
    html += "</tbody></table><br><hr><br>"
    return html

def section_not_found(title):
    return f"<h2 style='font-family:Arial;'>{title}</h2><p style='font-family:Arial; color: orange;'><i>{title.capitalize()} not done — no data file found.</i></p><hr><br>"

def try_read_csv(path, title):
    if os.path.exists(path):
        return df_to_html(pd.read_csv(path), title)
    else:
        return section_not_found(title)

def main():
    html = """
    <html><head><meta charset="UTF-8"><title>Workspace Report</title></head><body style='font-family:Arial; padding: 20px;'>
    <h1>Workspace Rebuild & Baseline Report</h1>
    """

    html += try_read_csv("data/rebuild_status.csv", "Rebuild")
    html += try_read_csv("data/baseline_status.csv", "Baseline")
    html += try_read_csv("data/wait_status.csv", "Wait")

    html += "</body></html>"

    with open("workspace_report.html", "w") as f:
        f.write(html)
    print("Report generated: workspace_report.html")

if __name__ == "__main__":
    main()
