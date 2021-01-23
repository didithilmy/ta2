import http from "k6/http";
import { sleep } from "k6";

export let options = {
  stages: [
    { duration: "0s", target: 0 },
    { duration: "30s", target: 2000 },
    { duration: "30s", target: 0 },
  ],
};

export default function () {
  const response = http.get("http://localhost:9000");
  const responseTimeMicrosec = response.headers["X-Response-Time-Microsec"];
  sleep(1);
}
