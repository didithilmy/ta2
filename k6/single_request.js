import http from "k6/http";
import {
  uuidv4,
  randomIntBetween,
} from "https://jslib.k6.io/k6-utils/1.0.0/index.js";
import { sleep } from "k6";
import { Trend } from "k6/metrics";
import { decode } from "./jwt.js";

const ENDPOINT = "http://localhost:9000/test-post.php";

const noOfLoadsTrend = new Trend("no_of_loads");
const completionTime = new Trend("completion_time", true);
const issuedQueueNo = new Trend("issued_queue_no");
const calculatedResponseTime = new Trend("calculated_response_time", true);

export let options = {
  discardResponseBodies: true,
  scenarios: {
    contacts: {
      executor: "per-vu-iterations",
      vus: 100,
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

function recordMetrics(response) {
  const responseTimeMicrosec =
    response.headers["X-Response-Time-Microsec"] / 1000;

  if (responseTimeMicrosec)
    calculatedResponseTime.add(responseTimeMicrosec, { status: response.status, vu: __VU });

  if (response.cookies.webqueue_ticket) {
    const token = response.cookies.webqueue_ticket[0].value;
    const { typ, qno } = decode(token);
    if (typ === "q") {
      issuedQueueNo.add(qno, { vu: __VU });
    }
  }
}

export default function (data) {
  sleep(randomIntBetween(1, 4));

  const start = new Date().getTime();
  let startSuccess = new Date().getTime();

  let response = http.post(ENDPOINT, { entry: uuidv4() });
  recordMetrics(response);

  let i = 1;
  while (response.status !== 201) {
    // console.log(__VU, "Status", status, "- retrying in 5s..");
    sleep(5);
    startSuccess = new Date().getTime();
    response = http.post(ENDPOINT, { entry: uuidv4() });
    recordMetrics(response);
    i++;
  }
  const end = new Date().getTime();

  // const responseTimeMicrosec = response.headers["X-Response-Time-Microsec"];
  // console.log(
  //   __VU,
  //   "Successful request after",
  //   i,
  //   "loads, response time in microsec:",
  //   responseTimeMicrosec
  // );

  noOfLoadsTrend.add(i, { vu: __VU });
  completionTime.add(end - start, { start, startSuccess, end, vu: __VU });
}
