#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'TEST_MYSQL disables this test' if $ENV{TEST_MYSQL};

plan tests => 11;

use lib 't/lib';

use TestDB;

use_ok('ObjectDB::SchemaDiscoverer');

my $dbh = TestDB->conn->dbh;

my $d;

$d =
  ObjectDB::SchemaDiscoverer->build(driver => 'SQLite', table => 'authors');
ok($d);

$d->discover($dbh);

is($d->table,          'authors');
is($d->auto_increment, 'id');
is_deeply($d->columns,      [qw/id name password/]);
is_deeply($d->primary_keys, [qw/id/]);
is_deeply($d->unique_keys,  [qw/name/]);

$d = ObjectDB::SchemaDiscoverer->build(
    driver => 'SQLite',
    table  => 'article_tag_maps'
);
ok($d);

$d->discover($dbh);

is($d->table, 'article_tag_maps');
is_deeply($d->columns,      [qw/article_id tag_id/]);
is_deeply($d->primary_keys, [qw/article_id tag_id/]);
