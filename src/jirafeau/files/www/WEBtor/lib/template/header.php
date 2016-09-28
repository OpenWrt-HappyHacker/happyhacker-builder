<?php
header('Vary: Accept');

$content_type = 'text/html; charset=utf-8';

if (isset ($_SERVER['HTTP_ACCEPT']) &&
    stristr ($_SERVER['HTTP_ACCEPT'], 'application/xhtml+xml'))
{
    $content_type = 'application/xhtml+xml; charset=utf-8';
}

header('Content-Type: ' . $content_type);
header('x-ua-compatible: ie=edge');

$protocol = (bool)is_ssl() ? 'https' : 'http';

if ( !empty($cfg['web_root']) ) {
    $cfg['web_root'] = preg_replace('#https?://#', $protocol . '://', $cfg['web_root'], 1);
}

/* Avoids irritating errors with the installer (no conf file is present then). */
if (!isset ($cfg['web_root']))
    $web_root = $protocol+'://' . $_SERVER['HTTP_HOST'] . '/';
else
    $web_root = $cfg['web_root'];

if (!isset ($cfg['style']))
    $style = 'default';
else
    $style = $cfg['style'];

if (isset ($_SERVER['HTTP_ACCEPT']) &&
    stristr ($_SERVER['HTTP_ACCEPT'], 'application/xhtml+xml'))
{
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="fr" lang="fr">    
<?php
}
else
{
?>
<!DOCTYPE html>
<html>
<?php
}
?>
<head>
  <title><?php echo t('Jirafeau, your web file repository'); ?></title>
  <meta http-equiv="Content-Type" content="<?php echo $content_type; ?>" />
  <link href="<?php echo $web_root . 'media/' . $style . '/style.css.php'; ?>" rel="stylesheet" type="text/css" />
</head>
<body>
<script type="text/javascript" language="Javascript" src="lib/functions.js.php"></script>
<div id="content">
<h1><a href="<?php echo $web_root; ?>"><?php echo t('Jirafeau, your web file repository'); ?></a></h1>
