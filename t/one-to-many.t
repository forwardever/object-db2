#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 23;

use lib 't/lib';

use TestDB;

use Author;
use Article;

my $conn = TestDB->conn;

my $author = Author->create(
    conn      => $conn,
    name     => 'foo',
    articles => [{title => 'bar'}, {title => 'baz'}]
);
is(@{$author->articles}, 2);
is($author->articles->[0]->column('title'), 'bar');
is($author->articles->[1]->column('title'), 'baz');

$author = Author->find(conn => $conn, id => $author->id);
my @articles = $author->articles;
is(@articles, 2);
is($articles[0]->column('title'), 'bar');
is($articles[1]->column('title'), 'baz');

$author = Author->find(conn => $conn, id => $author->id);
ok($author->delete_related('articles' => where => [title => 'bar']));
@articles = $author->articles;
is(@articles, 1);
is($articles[0]->column('title'), 'baz');

@articles = $author->create_related(articles => {title => 'bar'});
is(@articles, 1);
is($articles[0]->column('title'), 'bar');

$author = Author->find(conn => $conn, id => $author->id);
my $article = $author->find_related('articles' => where => [title => 'bar'])->next;
ok($article);
is($article->column('title'), 'bar');

$author->delete(conn => $conn);
ok(!Article->find(conn => $conn)->next);

$author = Author->create(
    conn     => $conn,
    name     => 'foo',
    articles => [
        {   title    => 'bar',
            comments => [{content => 'foo'}, {content => 'bar'}]
        },
        {title => 'baz', comments => {content => 'baz'}}
    ]
);

@articles = Author->find_related('articles', conn => $conn, ids => [$author->id]);
is(@articles, 2);

$author = Author->find(conn => $conn, id => $author->id, with => 'articles');
is(@{$author->articles}, 2);
is($author->articles->[0]->column('title'), 'bar');
is($author->articles->[1]->column('title'), 'baz');

$author = Author->find(
    conn => $conn,
    id   => $author->id,
    with => [qw/articles articles.comments/]
);
is(@{$author->articles}, 2);
is($author->articles->[0]->column('title'), 'bar');
is(@{$author->articles->[0]->comments}, 2);
is($author->articles->[1]->column('title'), 'baz');
is(@{$author->articles->[1]->comments}, 1);

$author->delete(conn => $conn);
