<!DOCTYPE html>
<html>
<head>
<title></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">

<link rel="shortcut icon" href="images/favicon.ico">
<link rel="icon" href="images/favicon.png">
</head>
<body>
<script>
	parent.document.getElementById("nkn_wallet_balance").innerHTML = "<% nvram_dump("nknbala.log", ""); %>";
	parent.document.getElementById("refresh_balance").disabled = false;
</script>
</body>
</html>
