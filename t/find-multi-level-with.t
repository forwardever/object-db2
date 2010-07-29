#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 74;

use lib 't/lib';

use DBI;
use TestDB;


my $conn = TestDB->conn;

use TestDB;
use Author;
use Article;
use MainCategory;
use Comment;
use SubComment;


# Create data
my $author = Author->create(
    conn     => $conn,
    name     => 'foo',
    articles => [
        {   title    => 'article title1',
            comments => [
                {content => 'comment content first'},
                {content => 'comment content second'}
            ]
        },
        {   title    => 'article title2'},
        {   title    => 'article title3',
            comments => [{content => 'comment content3'}]
        }
    ]
);

my $category_1 = MainCategory->create(conn=>$conn, title => 'main category 1');
my $category_2 = MainCategory->create(conn=>$conn, title => 'main category 2');
my $category_3 = MainCategory->create(conn=>$conn, title => 'main category 3');
my $category_4 = MainCategory->create(conn=>$conn, title => 'main category 4');
$author->articles->[0]->column( 'main_category_id' => $category_4->column('id') )->update;


$category_4->create_related('admin_histories',
  { admin_name=>'Andre1', from => '2010-01-01', till => '2010-02-01' } );
$category_4->create_related('admin_histories',
  { admin_name=>'Andre2', from => '2010-02-01', till => '2010-03-01' } );


my $comment_id;
ok($comment_id = $author->articles->[0]->comments->[0]->column('id') );


# First simple test
my @authors = Author->find(conn=>$conn, with => [qw/articles articles.comments/]);
is(@authors, 1);
is($authors[0]->articles->[0]->column('title'), 'article title1');
is($authors[0]->articles->[1]->column('title'), 'article title2');
is( $authors[0]->articles->[0]->comments->[0]->column('content'),
    'comment content first'
);


# Only data of deepest relationship should be loaded completely
@authors = Author->find(conn=>$conn, with => [qw/articles.comments/]);
is(@authors, 1);
ok( !defined $authors[0]->articles->[0]->column('title') );
ok( !defined $authors[0]->articles->[1]->column('title') );
is($authors[0]->articles->[0]->comments->[0]->column('content'),
    'comment content first'
);


# Mixing the order of relationship chains a bit
@authors = Author->find(conn=>$conn, with => [qw/articles.comments articles/]);
is(@authors,                                                1);
is($authors[0]->articles->[0]->column('title'), 'article title1');
is($authors[0]->articles->[1]->column('title'), 'article title2');
is($authors[0]->articles->[0]->comments->[0]->column('content'),
    'comment content first'
);


# Add another level to up the ante
SubComment->create(conn=>$conn, comment_id => $comment_id, content => 'sub comment 1');
SubComment->create(conn=>$conn, comment_id => $comment_id, content => 'sub comment 2');


# Find all authors with all articles with all comments with all subcomments
@authors =
  Author->find( conn=>$conn, 
    with => [qw/articles articles.comments articles.comments.sub_comments/]);
is( @authors, 1);
is( @{$authors[0]->articles}, 3);
is( $authors[0]->articles->[0]->column('title'), 'article title1');
is( $authors[0]->articles->[0]->comments->[0]->column('content'),
    'comment content first'
);
is( $authors[0]->articles->[0]->comments->[1]->column('content'),
    'comment content second'
);
is( $authors[0]->articles->[0]->comments->[0]->sub_comments->[0]
  ->column('content'), 'sub comment 1'
);
is( $authors[0]->articles->[0]->comments->[0]->sub_comments->[1]
  ->column('content'), 'sub comment 2'
);
is($authors[0]->articles->[2]->column('title'), 'article title3');
is( $authors[0]->articles->[2]->comments->[0]->column('content'),
    'comment content3'
);


# Only data of deepest relationship should be loaded completely
@authors =
  Author->find( conn=>$conn, 
    with => [qw/articles.comments.sub_comments/]);
is( @authors, 1);
is( @{$authors[0]->articles}, 3);
ok( not defined $authors[0]->articles->[0]->column('title') );
is( @{$authors[0]->articles->[0]->comments}, 2);
ok( not defined $authors[0]->articles->[0]->comments->[0]->column('content') );
ok( not defined $authors[0]->articles->[0]->comments->[1]->column('content') );
is( $authors[0]->articles->[0]->comments->[0]->sub_comments->[0]
  ->column('content'),
    'sub comment 1'
);
is( $authors[0]->articles->[0]->comments->[0]->sub_comments->[1]
  ->column('content'),
    'sub comment 2'
);
ok( defined $authors[0]->articles->[1]->comments );
is( @{$authors[0]->articles->[1]->comments}, 0);


# Follow a second path (articles.comments articles.main_category)
@authors = Author->find( conn=>$conn,
    with => [
        qw/articles articles.comments articles.comments.sub_comments articles.main_category/
    ]
);
is( @authors, 1);
is( @{$authors[0]->articles}, 3);
is( $authors[0]->articles->[0]->column('title'), 'article title1');
is( $authors[0]->articles->[0]->comments->[0]->column('content'),
    'comment content first'
);
is( $authors[0]->articles->[0]->comments->[1]->column('content'),
    'comment content second'
);
is( $authors[0]->articles->[0]->comments->[0]->sub_comments->[0]
  ->column('content'), 'sub comment 1'
);
is( $authors[0]->articles->[0]->comments->[0]->sub_comments->[1]
  ->column('content'), 'sub comment 2'
);
is($authors[0]->articles->[2]->column('title'), 'article title3');
is( $authors[0]->articles->[2]->comments->[0]->column('content'),
    'comment content3'
);
is( $authors[0]->articles->[0]->main_category->column('title'), 'main category 4' );


# Similar test
@authors =
  Author->find( conn=>$conn, 
    with => [qw/articles.comments.sub_comments articles.main_category/]);
is( @authors, 1);
is( @{$authors[0]->articles}, 3);
ok( not defined $authors[0]->articles->[0]->column('title') );
is( @{$authors[0]->articles->[0]->comments}, 2);
ok( not defined $authors[0]->articles->[0]->comments->[0]->column('content') );
ok( not defined $authors[0]->articles->[0]->comments->[1]->column('content') );
is( $authors[0]->articles->[0]->comments->[0]->sub_comments->[0]
  ->column('content'),
    'sub comment 1'
);
is( $authors[0]->articles->[0]->comments->[0]->sub_comments->[1]
  ->column('content'),
    'sub comment 2'
);
is( @{$authors[0]->articles->[1]->comments}, 0);
is( $authors[0]->articles->[0]->main_category->column('title'), 'main category 4' );


# Similar test
@authors =
  Author->find( conn=>$conn, 
    with => [qw/articles.comments articles.main_category/]);
is( @authors, 1);
is( @{$authors[0]->articles}, 3);
ok( not defined $authors[0]->articles->[0]->column('title') );
is( @{$authors[0]->articles->[0]->comments}, 2);
is( $authors[0]->articles->[0]->comments->[0]->column('content'), 'comment content first');
is( $authors[0]->articles->[0]->comments->[1]->column('content'), 'comment content second');
is( @{$authors[0]->articles->[1]->comments}, 0);
is( $authors[0]->articles->[0]->main_category->column('title'), 'main category 4' );


# Similar test
@authors =
  Author->find( conn=>$conn, 
    with => [qw/articles.comments articles.main_category articles/]);
is( @authors, 1);
is( @{$authors[0]->articles}, 3);
is(  $authors[0]->articles->[0]->column('title'), 'article title1' );
is( @{$authors[0]->articles->[0]->comments}, 2);
is( $authors[0]->articles->[0]->comments->[0]->column('content'), 'comment content first');
is( $authors[0]->articles->[0]->comments->[1]->column('content'), 'comment content second');
is( @{$authors[0]->articles->[1]->comments}, 0);
is( $authors[0]->articles->[0]->main_category->column('title'), 'main category 4' );


# One to many relationship follows a one to one relationship
my @articles =
  Article->find( conn=>$conn, 
    with => [qw/main_category.admin_histories/]);

is( $articles[0]->main_category->admin_histories->[0]->column('admin_name'), 'Andre1');
ok ( not defined $articles[0]->main_category->column('title') );


# One to many relationship follows a one to one relationship
@articles =
  Article->find( conn=>$conn, 
    with => [qw/main_category main_category.admin_histories/]);


is( $articles[0]->main_category->admin_histories->[0]->column('admin_name'), 'Andre1');
is ( $articles[0]->main_category->column('title'), 'main category 4' );


# One to many relationship follows a one to one relationship
@authors =
  Author->find( conn=>$conn, 
    with => [qw/articles.main_category.admin_histories/]);

is( $authors[0]->articles->[0]->main_category->admin_histories->[0]->column('admin_name'), 'Andre1');
ok ( not defined $authors[0]->articles->[0]->main_category->column('title') );


# Cleanup
Author->delete(conn => $conn);
MainCategory->delete(conn => $conn);


