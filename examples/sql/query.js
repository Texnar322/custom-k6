// Example skeleton. Provide a real DSN and import the driver you embedded.
// See https://github.com/grafana/xk6-sql for the current API and driver setup.
import sql from "k6/x/sql";
import "k6/x/sql/driver/postgres";

const db = sql.open("postgres", __ENV.SQL_DSN || "postgres://user:password@localhost:5432/app?sslmode=disable");

export default function () {
  const result = db.query("SELECT 1");
  if (!result) throw new Error("SQL query returned no result");
}

export function teardown() {
  db.close();
}
