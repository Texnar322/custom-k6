import { Writer } from "k6/x/kafka";

// Set KAFKA_BROKERS, KAFKA_TOPIC and certificate path for your environment.
// The CA certificate validates the broker. This is TLS server authentication;
// it does not configure mTLS client certificate authentication.
const brokers = (__ENV.KAFKA_BROKERS || "localhost:9093").split(",");
const topic = __ENV.KAFKA_TOPIC || "load-test-topic";
const caPath = __ENV.KAFKA_CA_FILE || "./certs/kafka_ca.crt";

const writer = new Writer({
  brokers,
  topic,
  tls: {
    enableTls: true,
    serverCaPem: open(caPath),
    insecureSkipTlsVerify: false,
  },
});

export const options = {
  vus: 1,
  duration: "30s",
  thresholds: {
    kafka_writer_error_count: ["count==0"],
  },
};

export default function () {
  writer.produce({
    messages: [{
      key: `${__VU}-${__ITER}`,
      value: JSON.stringify({
        vu: __VU,
        iteration: __ITER,
        timestamp: new Date().toISOString(),
        message: "hello from custom-k6",
      }),
    }],
  });
}

export function teardown() {
  writer.close();
}
