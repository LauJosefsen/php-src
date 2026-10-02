/*
   +----------------------------------------------------------------------+
   | Copyright (c) The PHP Group                                          |
   +----------------------------------------------------------------------+
   | This source file is subject to version 3.01 of the PHP license,       |
   | that is bundled with this package in the file LICENSE, and is        |
   | available through the world-wide-web at the following url:           |
   | https://www.php.net/license/3_01.txt                                  |
   +----------------------------------------------------------------------+
*/

#include "sapi/embed/php_embed.h"
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char **argv)
{
	php_embed_module.php_ini_ignore = 1;
	if (php_embed_init(argc, argv) == FAILURE) {
		return 1;
	}

	int status = 0;
	zend_first_try {
		if (zend_eval_string(
			"$rows = [];"
			"for ($i = 0; $i < 1000; $i++) { $rows[] = ['id' => $i, 'value' => $i * 3]; }"
			"$sum = array_sum(array_column($rows, 'value'));"
			"echo json_encode(['sum' => $sum, 'count' => count($rows)]), PHP_EOL;",
			NULL, "PGO smoke test") == FAILURE) {
			status = 1;
		}
	} zend_catch {
		status = 1;
	} zend_end_try();

	php_embed_shutdown();
	fflush(stdout);
	_Exit(status);
}
