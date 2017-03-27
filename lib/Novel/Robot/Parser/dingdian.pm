# ABSTRACT: 顶点小说 http://www.23us.com
package Novel::Robot::Parser::dingdian;
use strict;
use warnings;
use utf8;
use base 'Novel::Robot::Parser';
use Web::Scraper;

our $BASE_URL = 'http://www.23us.com';

sub charset {
    'cp936';
}

sub parse_index {

    my ( $self, $hr ) = @_;

    my ($wn) = $$hr=~m#<meta name="og:novel:author" content="(.+?)"/>#s;
    my ($bn) = $$hr=~m#<meta name="og:novel:book_name" content="(.+?)"/>#s; 
    
    return {
        writer => $wn, 
        book => $bn, 
    };
} ## end sub parse_index

sub parse_chapter_list {
    my ( $self, $r, $html_ref ) = @_;

    my $parse_index = scraper {
        process '//table[@id="at"]//a',
          'chapter_list[]' => {
            'title' => 'TEXT',
            'url'   => '@href'
          };
      };
    my $ref = $parse_index->scrape($html_ref);
    return $ref->{chapter_list};
}

sub parse_chapter {

    my ( $self, $html_ref ) = @_;

    my $parse_chapter = scraper {
        process_first '//dd[@id="contents"]',     'content' => 'HTML';
        process_first '//h1',                     'title'   => 'TEXT';
        process_first '//div[@id="amain"]//a[3]', 'book'    => 'TEXT';
    };
    my $ref = $parse_chapter->scrape($html_ref);

    return $ref;
} ## end sub parse_chapter

1;
