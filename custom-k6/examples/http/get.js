import http from "k6/http";
import { check } from "k6";

export const options = { vus: 1, duration: "30s" };

export default function () {
  const url = __ENV.TARGET_URL || "https://test.k6.io/";
  const response = http.get(url);
  check(response, { "HTTP status is 200": (r) => r.status === 200 });
}
