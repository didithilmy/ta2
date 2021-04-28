<?php
include("session.php");
header("Content-Type: application/json");

$_SESSION['login'] = true;
$_SESSION['username'] = $_POST['username'];

echo json_encode(["success" => true]);
