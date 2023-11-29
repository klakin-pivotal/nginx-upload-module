use strict;
use warnings;

use File::Basename qw(dirname);

use lib dirname(__FILE__) . "/lib";

use Test::Nginx::Socket tests => 2;
use Test::More;
use Test::Nginx::UploadModule;

no_long_string();
no_shuffle();
run_tests();

__DATA__
=== TEST 1: invalid content-range
--- config
location /upload/ {
    upload_pass @upstream;
    upload_resumable on;
    upload_set_form_field "upload_tmp_path" "$upload_tmp_path";
    upload_cleanup 400 404 499 500-505;
    upload_prohibit_simultaneous_with_same_filename on;
}
--- more_headers
X-Content-Range: bytes 0-3/4
X-Progress-ID: 0000000001
Session-ID: 0000000001
Content-Type: text/plain
Content-Disposition: form-data; name="file"; filename="test.txt"\r
--- request eval
qq{POST /upload/
testing}
--- error_code: 416
--- extra_tests eval
use Test::File qw(file_not_exists_ok);
sub {
    my $block = shift;
    file_not_exists_ok(
        "${ENV{TEST_NGINX_UPLOAD_PATH}}/store/1/0000000001", $block->name . '- tmp file deleted');
}
