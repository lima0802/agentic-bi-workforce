---
name: wpp-report
description: WPP report wrapper over Fabric powerbi-report-authoring. Applies the client brand pack (Volvo Centum font, colors, frame geometry), non-destructive resource merge, and the validate→reload→screenshot loop. Foundation = pinned Fabric skill. Use for any WPP report build.
---

# wpp-report (wraps `powerbi-report-authoring`)

Foundational skill: **`powerbi-report-authoring`** — pinned; not edited.
Read `../../learnings.md` first — prior-workflow lessons override defaults.

## WPP brand application
- Read `clients/<client>/brand.json` for font (Volvo Centum), colors, frame, KPI styles.
- Build frame + pages from approved brief; substitute fontFamily = brand font (not Segoe).
- NON-DESTRUCTIVE: merge resources into report.json; never overwrite a populated report.

## Loop
Edit → `powerbi-report-author validate` (0/0) → reload → screenshot → eval.ps1.

## DDM overview layout (from golden `Homepage`)
- Page 1280×1300 ActualSize; navy header rect 0,0 1280×172 (logo + title); divider lines y≈332/492.
- **9 KPI cards, 3×3**, ~144×144: cols x=16/432/856, rows y=188/348/508 — Email Sends, Delivery rate, Click Rate, Unsub Rate, Scalability Index, Program share, Session duration, Web Bounce, Total Sessions.
- Charts between KPIs: columnChart, lineCharts, 100%-stacked col, 2 treemaps (y≈679), barCharts + pivotTable (y≈898); sections "Top 5 Emails", "Program performance", "Top & Bottom 5 Countries".
- Two slicer rows: Time grouping, email_send_number, email_name_cleansed, Date, **DateBM**, REGION_NAME_GROUP, **Region/Market BM** → needs ENABLE_BM=true.
- All fontFamily = Volvo Centum; bars #001C30/#66869E; gridlines #E0E5EA.
