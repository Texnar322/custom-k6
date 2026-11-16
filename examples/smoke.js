// This test verifies that all extension modules are embedded and importable.
// It does not connect to Kafka, SQL, Redis, or MQTT services.
import * as kafka from "k6/x/kafka";
import * as sql from "k6/x/sql";
import * as mysql from "k6/x/sql/driver/mysql";
import * as postgres from "k6/x/sql/driver/postgres";
import * as redis from "k6/x/redis";
import * as mqtt from "k6/x/mqtt";
import * as faker from "k6/x/faker";

export default function () {
  const modules = { kafka, sql, mysql, postgres, redis, mqtt, faker };
  for (const name of Object.keys(modules)) {
    if (!modules[name]) {
      throw new Error(`Extension module ${name} is not loaded`);
    }
  }
  console.log(`custom-k6 extension smoke test passed: ${Object.keys(modules).join(", ")}`);
}
