<?php
include("db.php");
header("Content-Type: application/json");

if ($_POST['entry']) {
    $escaped = mysqli_real_escape_string($conn, $_POST['entry']);
    $q = "INSERT INTO test_entry (entry) VALUES ('$escaped')";
    mysqli_query($conn, $q);
    http_response_code(201);
}

$res = mysqli_query($conn, "SELECT * FROM test_entry LIMIT 10");
$arr = [];
while ($row = mysqli_fetch_assoc($res)) {
    $arr[] = $row;
}

echo json_encode($arr);
