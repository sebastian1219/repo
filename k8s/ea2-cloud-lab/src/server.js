const express = require("express");
const mysql = require("mysql2/promise");

const port = Number(process.env.PORT || 8080);
const app = express();

async function pool() {
  return mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME || "labdb",
    waitForConnections: true,
    connectionLimit: 5,
  });
}

async function migrate(p) {
  await p.query(
    `CREATE TABLE IF NOT EXISTS lab_ping (
      id INT AUTO_INCREMENT PRIMARY KEY,
      note VARCHAR(255) NOT NULL DEFAULT '',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB`,
  );
  const [rows] = await p.query("SELECT COUNT(*) AS c FROM lab_ping");
  if (rows[0].c === 0) {
    await p.query("INSERT INTO lab_ping (note) VALUES (?)", ["bootstrap"]);
  }
}

async function main() {
  const p = await pool();
  await migrate(p);

  app.get("/health", (_req, res) => {
    res.json({ ok: true, service: "ea2-cloud-lab-api" });
  });

  app.get("/db-primary", async (_req, res) => {
    try {
      const [rows] = await p.query("SELECT COUNT(*) AS rows FROM lab_ping");
      res.json({ ok: true, backend: "primary-writer", rows: rows[0].rows });
    } catch (e) {
      res.status(500).json({ ok: false, error: String(e.message || e) });
    }
  });

  app.get("/db-replica", async (_req, res) => {
    let reader;
    try {
      reader = mysql.createPool({
        host: process.env.DB_REPLICA_HOST || process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME || "labdb",
        waitForConnections: true,
        connectionLimit: 3,
      });
      const [rows] = await reader.query("SELECT COUNT(*) AS rows FROM lab_ping");
      res.json({ ok: true, backend: "read-replica", rows: rows[0].rows });
    } catch (e) {
      res.status(500).json({ ok: false, error: String(e.message || e) });
    } finally {
      if (reader) await reader.end();
    }
  });

  app.listen(port, () => {
    console.log(`listening on ${port}`);
  });
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
