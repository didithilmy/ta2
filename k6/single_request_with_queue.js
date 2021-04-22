import http from "k6/http";
import {
  uuidv4,
  randomIntBetween,
} from "https://jslib.k6.io/k6-utils/1.0.0/index.js";
import { sleep } from "k6";
import { Trend } from "k6/metrics";

const ENDPOINT = "http://localhost:9000/test-post.php";

const noOfLoadsTrend = new Trend("no_of_loads");

export let options = {
  discardResponseBodies: true,
  scenarios: {
    contacts: {
      executor: "per-vu-iterations",
      vus: 3000,
      iterations: 1,
      maxDuration: "1h30m",
    },
  },
};

export function setup() {
  const sessionId = uuidv4();

  let jar = http.cookieJar();
  jar.set(ENDPOINT, "khongguan", sessionId);
}

export default function (data) {
  sleep(randomIntBetween(1, 4));
  let response = http.post(ENDPOINT, { entry: uuidv4() });
  let i = 1;
  while (response.status !== 201) {
    // console.log(__VU, "Status", status, "- retrying in 5s..");
    sleep(5);
    response = http.post(ENDPOINT, { entry: uuidv4() });
    i++;
  }

  const responseTimeMicrosec = response.headers["X-Response-Time-Microsec"];
  console.log(
    __VU,
    "Successful request after",
    i,
    "loads, response time in microsec:",
    responseTimeMicrosec
  );

  noOfLoadsTrend.add(i);
}

export function teardown(data) {
  // 4. teardown code
}
