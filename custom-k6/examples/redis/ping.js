// Example skeleton; verify the current client API against xk6-redis docs.
import redis from "k6/x/redis";

const client = new redis.Client(__ENV.REDIS_URL || "redis://localhost:6379");

export default function () {
  const pong = client.ping();
  if (pong !== "PONG") throw new Error(`Unexpected Redis response: ${pong}`);
}

export function teardown() {
  client.close();
}
