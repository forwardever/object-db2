#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;

use ObjectDB;

is_deeply(ObjectDB->_normalize_with([qw/foo/]), [foo => {}]);
is_deeply(ObjectDB->_normalize_with([foo => {a => 'b'}]),
    [foo => {a => 'b'}]);
is_deeply(ObjectDB->_normalize_with([qw/foo foo.bar/]),
    [foo => {nested => [bar => {}]}]);
is_deeply(
    ObjectDB->_normalize_with([qw/foo.bar/]),
    [foo => {no_cols => 1, nested => [bar => {}]}]
);
is_deeply(
    ObjectDB->_normalize_with([qw/hello foo.bar/]),
    [foo => {no_cols => 1, nested => [bar => {}]}, hello => {}]
);
is_deeply(
    ObjectDB->_normalize_with([hello => {a => 'b'}, qw/foo.bar.baz/]),
    [   foo => {
            no_cols   => 1,
            nested => [bar => {no_cols => 1, nested => [baz => {}]}]
        },
        hello => {a => 'b'}
    ]
);

is_deeply(
    ObjectDB->_normalize_with(
        [qw/articles.comments.sub_comments articles.main_category/]
    ),
    [   'articles',
        {   'no_cols'   => 1,
            'nested' => [
                'comments',
                {   'no_cols'   => 1,
                    'nested' => ['sub_comments', {}]
                },
                'main_category',
                {}
            ]
        }
    ]
);
