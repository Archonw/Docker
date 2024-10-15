Diese Zeilen in der config.php der Nextcloud am Ende einfügen.

  'default_phone_region' => 'DE',
  'maintenance_window_start' => 1,
  'memcache.local' => '\OC\Memcache\APCu', 
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' => array(
     'host' => 'localhost',
     'port' => 6379,
     'timeout' => 0.0,
     'password' => '', // Optional, if not defined no password will be used.
      ),
