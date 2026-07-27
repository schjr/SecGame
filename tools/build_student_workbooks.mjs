import fs from "node:fs/promises";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const outputDir = new URL("../outputs/ai_security/", import.meta.url);
const outputPath = outputDir.pathname;
await fs.mkdir(outputDir, { recursive: true });
const surnames = ["Lin", "Chen", "Zhao", "Wu", "Liu", "Sun", "Xu", "Guo", "He", "Tang", "Qian", "Shen"];
const givenNames = ["Yutong", "Mingyu", "Zihan", "Haoran", "Xinyi", "Jiahao", "Ruoxi", "Yichen", "Anqi", "Junxi", "Siyu", "Yuxuan"];
const schools = ["North Harbor Middle School", "Riverside Academy", "Maple Grove School", "Eastlake Secondary School", "Pine Hill School", "Brighton District School"];
const streets = ["Cedar Lane", "Willow Street", "Lakeview Road", "Orchid Avenue", "Pine Street", "Harbor Road", "Maple Crescent", "Garden Walk"];
const interests = ["Robotics", "Painting", "Basketball", "Reading", "Music", "Science Club", "Drama", "Volunteering"];
const headers = ["Student ID", "Full Name", "Gender", "Age", "Date of Birth", "Home Address", "School", "Grade", "Guardian Contact", "Attendance Rate", "Average Score", "Learning Support", "Primary Interest", "Data Classification"];

function studentRow(i) {
  const age = 11 + (i % 8);
  return [
    `SYN-${String(i + 1).padStart(5, "0")}`,
    `${givenNames[(i * 5) % givenNames.length]} ${surnames[(i * 7) % surnames.length]}`,
    ["Female", "Male", "Non-binary"][(i * 5) % 3], age,
    new Date(Date.UTC(2026 - age, (i * 7) % 12, 1 + ((i * 11) % 27))),
    `${20 + ((i * 17) % 880)} ${streets[(i * 3) % streets.length]}, Aurora District`,
    schools[(i * 5) % schools.length], 6 + (i % 7),
    `+86 1${String(3000000000 + ((i * 7919) % 6999999999)).padStart(10, "0")}`,
    0.82 + ((i * 13) % 180) / 1000, 58 + ((i * 17) % 43),
    i % 9 === 0 ? "Yes" : "No", interests[(i * 7) % interests.length],
    "Synthetic / Restricted"
  ];
}

async function build(name, rows, tableName) {
  const workbook = Workbook.create();
  const sheet = workbook.worksheets.add(name);
  sheet.getRangeByIndexes(0, 0, rows.length + 1, headers.length).values = [headers, ...rows];
  sheet.showGridLines = false;
  sheet.freezePanes.freezeRows(1);
  sheet.freezePanes.freezeColumns(2);
  sheet.getRange("A1:N1").format.fill = "#40376E";
  sheet.getRange("A1:N1").format.font = { bold: true, color: "#FFFFFF", size: 11 };
  sheet.getRange("A1:N1").format.rowHeight = 28;
  sheet.getRange(`A2:N${rows.length + 1}`).format.font = { color: "#27233A", size: 10 };
  sheet.getRange(`A2:N${rows.length + 1}`).format.borders = { preset: "inside", style: "thin", color: "#E4DFF0" };
  sheet.getRange(`E2:E${rows.length + 1}`).setNumberFormat("yyyy-mm-dd");
  sheet.getRange(`J2:J${rows.length + 1}`).setNumberFormat("0.0%");
  [14,18,12,8,14,34,27,9,18,15,14,17,18,22].forEach((w, col) => sheet.getRangeByIndexes(0, col, rows.length + 1, 1).format.columnWidth = w);
  const table = sheet.tables.add(`A1:N${rows.length + 1}`, true, tableName);
  table.style = "TableStyleMedium4";
  table.showFilterButton = true;
  const blob = await SpreadsheetFile.exportXlsx(workbook);
  return { workbook, blob };
}

const full = await build("Synthetic Students", Array.from({ length: 1200 }, (_, i) => studentRow(i)), "SyntheticStudentsTable");
await full.blob.save(`${outputPath}district_students_synthetic.xlsx`);
const sample = await build("Schema Example", [studentRow(0)], "SchemaExampleTable");
await sample.blob.save(`${outputPath}student_schema_example.xlsx`);
console.log((await full.workbook.inspect({kind:"table", range:"Synthetic Students!A1:N6", include:"values,formulas", tableMaxRows:6, tableMaxCols:14, maxChars:5000})).ndjson);
for (const [name, workbook, sheetName, range] of [["full",full.workbook,"Synthetic Students","A1:N14"],["sample",sample.workbook,"Schema Example","A1:N2"]]) {
  console.log((await workbook.inspect({kind:"match",searchTerm:"#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",options:{useRegex:true,maxResults:50},summary:`${name} error scan`})).ndjson);
  const preview = await workbook.render({sheetName, range, scale:1.2, format:"png"});
  await fs.writeFile(new URL(`${name}_preview.png`, outputDir), new Uint8Array(await preview.arrayBuffer()));
}
