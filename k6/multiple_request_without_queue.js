import http from "k6/http";
import {
  uuidv4,
  randomIntBetween,
} from "https://jslib.k6.io/k6-utils/1.0.0/index.js";
import { sleep } from "k6";
import { Trend } from "k6/metrics";

const BASE_URL = "http://localhost:9001";

const noOfLoadsTrend = new Trend("no_of_loads");
const completionTime = new Trend("completion_time");

export let options = {
  discardResponseBodies: true,
  scenarios: {
    contacts: {
      executor: "per-vu-iterations",
      vus: 10,
      iterations: 1,
      maxDuration: "1h30m",
    },
  },
};

function requestUntilSuccessful(url, body) {
  let response = http.post(url, body);
  let i = 1;
  while (response.status !== 200) {
    sleep(5);
    response = http.post(url, body);
    i++;
  }
  return i;
}

export default function (data) {
  sleep(randomIntBetween(1, 4));

  const start = new Date().getTime();

  let i = requestUntilSuccessful(BASE_URL + "/login.php", {
    username: uuidv4(),
  });
  // console.log(__VU, "Logged in..");

  i += requestUntilSuccessful(BASE_URL + "/listMK.php");
  // console.log(__VU, "Listing MK...");

  i += requestUntilSuccessful(BASE_URL + "/takeMK.php", { kode_mk: "II3220" });
  // console.log(__VU, "Taking MK..");

  const end = new Date().getTime();

  console.log(
    __VU,
    "Successful request after",
    i,
    "loads and",
    end - start,
    "ms"
  );

  noOfLoadsTrend.add(i);
  completionTime.add(end - start, { start, end, vu: __VU });
}

export function teardown(data) {
  // 4. teardown code
}
