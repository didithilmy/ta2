<?php
include("session.php");
include("db.php");
header("Content-Type: application/json");

if (!$_SESSION['login']) {
    header("Location: login.php");
    die();
}

$kode_mk = $_POST['kode_mk'];
$user = $_SESSION['username'];

if (!$kode_mk) {
    die();
}

$q = "INSERT INTO pengambilan_mk (`kode_mk`, `user`) VALUES ('" . mysqli_real_escape_string($conn, $kode_mk) . "', '" . mysqli_real_escape_string($conn, $user) . "')";
$res = mysqli_query($conn, $q);

echo json_encode(["success" => true]);
