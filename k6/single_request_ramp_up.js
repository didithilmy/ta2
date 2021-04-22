import http from "k6/http";
import { uuidv4 } from "https://jslib.k6.io/k6-utils/1.0.0/index.js";

const ENDPOINT = "http://localhost:9001/test-post.php";

export let options = {
  discardResponseBodies: true,
  stages: [
    { duration: "30s", target: 500 },
    { duration: "40s", target: 500 },
    { duration: "70s", target: 1000 },
  ],
};

export default function (data) {
  let response = http.post(ENDPOINT, { entry: uuidv4() });
}
