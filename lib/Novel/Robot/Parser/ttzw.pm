# ABSTRACT: 天天中文 http://www.ttzw.com
package Novel::Robot::Parser::ttzw;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Parser';
use Web::Scraper;

our $BASE_URL = 'http://www.ttzw.com';

sub charset {
    'cp936';
}

sub parse_index {

    my ( $self, $html_ref ) = @_;

    my $parse_index = scraper {
        process '//div[@id="chapter_list"]//a',
          'chapter_list[]' => {
            'title' => 'TEXT',
            'url'   => '@href'
          };
          process_first '//h1' , 'book' => 'TEXT';
          process_first '//div[@class="pl40"]//b' , 'writer' => 'TEXT';
    };

    my $ref = $parse_index->scrape($html_ref);

    $ref->{chapter_list} = [
        grep { $_->{url}  and $_->{url}!~/\/$/ } @{ $ref->{chapter_list} }
    ];

    return $ref;
} ## end sub parse_index

sub parse_chapter {

    my ( $self, $html_ref ) = @_;

    my $parse_chapter = scraper {
        process_first '//div[@id="text_area"]//script', 'content_url' => 'HTML';
        process_first '//div[@id="chapter_title"]', 'title'=> 'TEXT';
    };
    my $ref = $parse_chapter->scrape($html_ref);
    ($ref->{content_url}) = $$html_ref=~/<script language="javascript">outputTxt\(.*?(\/.*?)"/s;
   $ref->{content} = ''; 
    if($ref->{content_url}){
    $ref->{content_url}= "http://r.xsjob.net:88/novel$ref->{content_url}";
    my $c = $self->{browser}->request_url($ref->{content_url});
    $c=~s#^\s*document.write.*?'\s*##s;
    $c=~s#'\);\s*$##s;
    $ref->{content} = $c;
    }

    return $ref;
} ## end sub parse_chapter

1;