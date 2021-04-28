<?php
include("session.php");
include("db.php");
header("Content-Type: application/json");

if (!$_SESSION['login']) {
    header("Location: login.php");
    die();
}

$q = "SELECT * FROM matakuliah";
$res = mysqli_query($conn, $q);

$arr = [];
while ($row = mysqli_fetch_assoc($res)) {
    $arr[] = $row;
}

echo json_encode($arr);
