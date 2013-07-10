#ABSTRACT: 豆豆小说阅读网 http://www.ddddbbb.net
=pod

=encoding utf8

=head1 FUNCTION

=head2 parse_chapter

=head2 parse_index

=head2 parse_writer

=head2 parse_query

=head1 支持查询类型 query type

  作品，作者，主角，系列

=cut
package Novel::Robot::Parser::Dddbbb;
use strict;
use warnings;
use utf8;

use Moo;
extends 'Novel::Robot::Parser::Base';

use Web::Scraper;
use Encode;

has '+base_url'  => ( default => sub {'http://www.dddbbb.net'} );
has '+site'    => ( default => sub {'Dddbbb'} );
has '+charset' => ( default => sub {'cp936'} );

sub parse_index {

    my ( $self, $html_ref ) = @_;

    my $parse_index = 
    
          $$html_ref =~ /<h2 id="lc">/  ? 
    scraper {
        process_first '#lc', 'book_info' => sub {
            my ( $writer, $book ) = ( $_[0]->look_down( '_tag', 'a' ) )[ 2, 3 ];
            return [
                $writer->as_trimmed_text, $self->{base_url} . $writer->attr('href'),
                $book->as_trimmed_text,   $self->{base_url} . $book->attr('href')
            ];
        };
        process_first '//table[@width="95%"]//td[2]', 'intro' => 'HTML';

    }
    :
    scraper {
        process_first '.cntPath', 'book_info' => sub {
            my ( $writer, $book ) = ( $_[0]->look_down( '_tag', 'a' ) )[ 3, 4 ];
            return [
                $writer->as_trimmed_text, $writer->attr('href'),
                $book->as_trimmed_text,   $book->attr('href')
            ];
        };
        process_first '.bookintro', 'intro' => 'HTML';
    };


    my $ref = $parse_index->scrape($html_ref);

    $ref->{intro} = $self->get_inner_html($ref->{intro});
    $ref->{intro}=~s#<script[^>]*?>.*?</script>##sig;

    @{$ref}{ 'writer', 'writer_url', 'book', 'index_url' } = @{ $ref->{book_info} };

    ( my $book_opf_url = $ref->{index_url} ) =~ s#index.html$#opf.html#;

    push @{$ref->{more_book_info}} , {
	url => $book_opf_url,
	function => sub { $self->parse_book_opf(@_) },
    };


    return $ref;
} ## end sub parse_index

sub parse_book_opf {
    my ( $self, $ref, $html_ref ) = @_;

    my $refine_engine = scraper {
        process '//div[@class="opf"]//a', 'chapter_info[]' => {
            title => 'TEXT', 
            url => '@href'
        }; 
    };
    
    my $r = $refine_engine->scrape($html_ref);
    $ref->{chapter_info} = $r->{chapter_info};

    return $ref;
} ## end sub parse_chapter_info

sub parse_chapter {

    my ( $self, $html_ref ) = @_;

    $$html_ref=~s#\<img[^>]+dou\.gif[^>]+\>#，#g;

    my $parse_chapter = scraper {
        process '//div[@id="toplink"]//a', 'book_info[]' => 'TEXT';
        process_first '.mytitle', 'title' => 'TEXT';
        process_first '#content', 'content' => 'HTML';
    };
    my $ref = $parse_chapter->scrape($html_ref);

    @{$ref}{ 'book', 'writer' } = @{ $ref->{book_info} }[3,4];
    for ($ref->{content}){
        s#<script[^>]+></script>##sg;
        s#<div[^>]+></div>##sg;
    }
    $ref->{title}=~s/^\s*//;

    return $ref;
} ## end sub parse_chapter

sub parse_writer {

    my ( $self, $html_ref ) = @_;

    my $parse_writer = scraper {
        process_first 'title', writer => 'TEXT';
        process '#border_1>ul', 'booklist[]' => scraper {
	    process_first '#idname>a' , url => '@href', book => 'TEXT';
	    process_first '#idzj', series => 'TEXT';
        };
    };

    my $ref = $parse_writer->scrape($html_ref);

    $ref->{writer}=~s/小说.*//;
    for my $r (@{$ref->{booklist}}){
	    $r->{series} =~ s/\s*(\S*)\s*.*$/$1/;
    }

    return $ref;
} ## end sub parse_writer

sub make_query_request {

    my ( $self, $type, $keyword ) = @_;

    my $url = $self->{base_url} . '/search.php';

    my %qt = ( '作品' => 'name', '作者' => 'author', '主角' => 'main', 
        '系列'=> 'series', 
    );

    return (
        $url,
        {   'keyword' => $keyword,
            'select'  => $qt{$type},
            'Submit'  => '搜索',
        },
    );

} ## end sub make_query_request

sub parse_query {
    my ( $self, $html_ref ) = @_;

    my $parse_query = scraper {
        process '//h3', 'books[]' => sub {
            my $book = $_[0]->look_down( '_tag', 'a' );
            return unless ( defined $book );
	
            my $writer = $_[0]->right->look_down( '_tag', 'a' );
            return { 
		    writer => $writer->as_trimmed_text,
		    book => $book->as_trimmed_text,
		    url => $book->attr('href') 
		};
        };
    };

    my $ref = $parse_query->scrape($html_ref);

    return $ref->{books};
} ## end sub parse_query

1;