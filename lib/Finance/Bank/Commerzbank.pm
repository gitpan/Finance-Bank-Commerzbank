package Finance::Bank::Commerzbank;
use strict;
use Carp;
our $VERSION = '0.21';

use WWW::Mechanize;
use WWW::Mechanize::FormFiller;
use URI::URL;
our $ua = WWW::Mechanize->new( autocheck => 1 );
our $formfiller = WWW::Mechanize::FormFiller->new();

sub check_balance {
  my ($class, %opts) = @_;
  my %HashOfAccounts;
  croak "Must provide a Teilnehmernummer" 
    unless exists $opts{Teilnehmernummer};
  croak "Must provide a PIN" 
    unless exists $opts{PIN};
  my $self = bless { %opts }, $class;
  
  $ua->env_proxy();
  
  $ua->get('https://portal01.commerzbanking.de/P-Portal/XML/IFILPortal/pgf.html?Tab=1');
  $ua->form(1) if $ua->forms and scalar @{$ua->forms};
  $ua->form_number(4);
  { local $^W; $ua->current_form->value('PltLogin_8_txtTeilnehmernummer', $opts{Teilnehmernummer}); };
  { local $^W; $ua->current_form->value('PltLogin_8_txtPIN', $opts{PIN}); };
  $ua->click('PltLogin_8_btnLogin');
  my @links=$ua->find_all_links();
  my $n; 
  for ($n=0;$n<$#links;$n++)
    {
      my ($url,$title)=@{$links[$n]};
      print "LINK------>".$n." - ".$title."\n";
      
    }

    if (0){

  $ua->follow_link(text=>"Kontoübersicht");
  my $Overview=$ua->content;
 my $Konto;
  while (index($Overview,"PltViewAccountOverview_8_STR_KontoNummer")>-1)
  
    {
      $Konto=substr ($Overview,index($Overview,"PltViewAccountOverview_8_STR_KontoNummer")+46,15);
      $Overview=substr ($Overview,index($Overview,"PltViewAccountOverview_8_STR_KontoNummer")+46);
      
      print $Konto."\n";
    }
    }

  

  $ua->follow_link(text => "Kontoumsätze");
  my @links=$ua->find_all_links();
  my $n; 
  for ($n=0;$n<$#links;$n++)
    {
      my ($url,$title)=@{$links[$n]};
      print "LINK------>".$n." - ".$title."\n";
      
    }
  { my $filename = q{/tmp/file-0};
    local *F;
    open F, "> $filename" or die "$filename: $!";
    binmode F;
    print F $ua->content,"\n";
    close F
  };
  if ( $ua->form_number(5))
    {
      { my $filename = q{/tmp/file-1};
	local *F;
	open F, "> $filename" or die "$filename: $!";
	binmode F;
	  print F $ua->content,"\n";
      close F
    };
	{ local $^W; $ua->current_form->value('PltViewAccountTransactions_8_STR_CodeZeitrahmen', '90 Tage'); };
	my $response= $ua->click('PltViewAccountTransactions_8_btnAnzeigen');
	
	{ my $filename = q{/tmp/Account};
	  local *F;
	  open F, "> $filename" or die "$filename: $!";
	  binmode F;
      print F $ua->content,"\n";
	  close F
	};
	$ua->form_number(4);
	$ua->click('PltHomeTeaser_3_btnLogout');
      }
  else
    {
      print "Could not log on - wait timeout detected..\n";
    }
  
  
  
  use HTML::TableContentParser;
  my $p = HTML::TableContentParser->new();

    open(IN,"</tmp/Account");
    my $Data;
    my $go;
    while (<IN>)
      {
	if (index($_,"Buchungstag")>-1)
	  {
	    $go=1;
	  }
	if($go){
	  $Data.=$_;
	}
      }
    
    my $tables = $p->parse($Data);
    my $t;
    my $r;
    my @accounts;
    for $t (@$tables) {
      my $j=0;
      for $r (@{$t->{rows}}) {
	my $i=0;
	my $IsOk=0;
	my $c;
	my @line;
	for $c (@{$r->{cells}}) {
	  #  print "CELL $i ";
	  my $Data;
	  if (($i == 1 ) || ($i == 5 )|| ($i == 7 ) ) {
	    
	    $Data=substr($c->{data},index($c->{data},"tablehead1")+12,1000);
	    $Data =~ s/<\/span><br>//g;
	    $Data =~s/<BR>/#/g;
	    if (($i ==1 ) && (index($Data,"2004")>-1)){
	      $IsOk=1;
              $j++;
	      print "Transaction - $j:";
	    }
	    if ($IsOk){
	      push @line,$Data;
	      print $Data.";";                          
	    }
	  }
	  if ($i == 10) {
	    #    print "[$c->{data}]";
	    if (index($c->{data},'"red">')> -1){
	      $Data=substr($c->{data},index($c->{data},"red")+5,1000);
	    }
	    if (index($c->{data},'"green">')> -1){
	      $Data=substr($c->{data},index($c->{data},"green")+7,1000);
	    }
	    $Data =~ s/<\/span><br>//g;
	    if ($IsOk){
	      $Data =~ s/\.//g;
	      push @line,$Data;

	      print $Data."\n";                          

        push @accounts, (bless {
            TradeDate           => $line[0],
            Description         => $line[1],
            ValueDate           => $line[2],
	    Amount              => $line[3],
            parent     => $self
        }, "Finance::Bank::Commerzbank::Account");


	    }
	  }
	  
	  $i++;
	}                         
	print "\n";                       
      }
    }
    
    
    
      return @accounts;
}



sub money_transfer {
  my ($class, %opts) = @_;
  croak "Must provide a Teilnehmernummer" 
    unless exists $opts{Teilnehmernummer};
  croak "Must provide a PIN" 
    unless exists $opts{PIN};
  croak "Must provide a TANPIN" 
    unless exists $opts{TANPIN};

  my $self = bless { %opts }, $class;
  
  $ua->env_proxy();
  
  $ua->get('https://portal01.commerzbanking.de/P-Portal/XML/IFILPortal/pgf.html?Tab=1');
  $ua->form(1) if $ua->forms and scalar @{$ua->forms};
  $ua->form_number(4);
  { local $^W; $ua->current_form->value('PltLogin_8_txtTeilnehmernummer', $opts{Teilnehmernummer}); };
  { local $^W; $ua->current_form->value('PltLogin_8_txtPIN', $opts{PIN}); };
  $ua->click('PltLogin_8_btnLogin');
  my @links=$ua->find_all_links();
  my $n; 
  for ($n=0;$n<$#links;$n++)
    {
      my ($url,$title)=@{$links[$n]};
    print "LINK------>".$n." - ".$title."\n";
      
    }
  $ua->follow_link(text => "Inlandsüberweisung");
  my @links=$ua->find_all_links();
  my $n; 
  for ($n=0;$n<$#links;$n++)
    {
      my ($url,$title)=@{$links[$n]};
    print "LINK------>".$n." - ".$title."\n";
      
    }
  { my $filename = q{/tmp/file-0};
    local *F;
      open F, "> $filename" or die "$filename: $!";
    binmode F;
    print F $ua->content,"\n";
    close F
  };
    if ( $ua->form_number(5))
      {
	{ my $filename = q{/tmp/file-1};
	  local *F;
	  open F, "> $filename" or die "$filename: $!";
	  binmode F;
	  print F $ua->content,"\n";
      close F
    };
	
	{ local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_EmpfaengerName', $opts{EmpfaengerName}); };
	{ local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_EmpfaengerKtoNr', $opts{EmpfaengerKtoNr}); };
	{ local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_EmpfaengerBLZ', $opts{EmpfaengerBLZ}); };
	{ local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_DBL_Betrag_Eingabe',$opts{Betrag_Eingabe}); };
	{ local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_Verwendungszweck1', $opts{Verwendungszweck1}); };
	{ local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_Verwendungszweck2', $opts{Verwendungszweck2}); };
	{ local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_Verwendungszweck3', $opts{Verwendungszweck3}); };
	{ local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_Verwendungszweck4', $opts{Verwendungszweck4}); };
	{ local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_CBO_Konten', $opts{Auftragskonto}); };



	print "Empfaenger       :".$opts{EmpfaengerName}."\n";
	print "Empfaenger Kto   :".$opts{EmpfaengerKtoNr}."\n";
	print "Empfaenger BLZ   :".$opts{EmpfaengerBLZ}."\n";
	print "Empfaenger Betrag:".$opts{Betrag_Eingabe}."\n";
	print "VZ 1             :".$opts{Verwendungszweck1}."\n";
	print "VZ 2             :".$opts{Verwendungszweck2}."\n";
	print "VZ 3             :".$opts{Verwendungszweck3}."\n";
	print "VZ 4             :".$opts{Verwendungszweck4}."\n";
       	my $response= $ua->click('PltManageDomesticTransfer_8_btnPruefenDomestic');
	#$ua->click('PltManageDomesticTransfer_8_btnPruefenDomestic');
	sleep(15);
	$ua->form_number(5);


	{ local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_txtTANPIN', $opts{TANPIN}); };
	$ua->click('PltManageDomesticTransfer_8_btnFreigebenDomestic');
	$ua->form_number(4);


	
	{ my $filename = q{/tmp/file-2};
	  local *F;
	  open F, "> $filename" or die "$filename: $!";
	  binmode F;
      print F $ua->content,"\n";
	  close F
	};
	$ua->form_number(4);
	$ua->click('PltHomeTeaser_3_btnLogout');
      }
  else
    {
      print "Could not log on - wait timeout detected..\n";
    }
  
  
  
}





package Finance::Bank::Commerzbank::Account;
# Basic OO smoke-and-mirrors Thingy
no strict;
sub AUTOLOAD { my $self=shift; $AUTOLOAD =~ s/.*:://; $self->{$AUTOLOAD} }



# This code stolen from Jonathan Stowe <gellyfish@gellyfish.com>
    
package TableThing;
use strict;
use vars qw(@ISA $infield $inrecord $intable);
@ISA = qw(HTML::Parser);
require HTML::Parser;

sub start()
{
   my($self,$tag,$attr,$attrseq,$orig) = @_;
   if ($tag eq 'table')
     {
      $self->{Table} = ();
      $intable++;
     }
   if ( $tag eq 'tr' )
     {
       $self->{Row} = ();
       $inrecord++ ;
     }
   if ( $tag eq 'td' )
     {
       $self->{Field} = '';
       $infield++;
     }
}



sub text()
{
   my ($self,$text) = @_;
   if ($intable && $inrecord && $infield )
     {
       $self->{Field} .= $text;
     }
}

sub end()
{
   my ($self,$tag) = @_;
   $intable-- if($tag eq 'table');
   if($tag eq 'td')
    {
     $infield--;
     push @{$self->{Row}},$self->{Field};
    }
   if($tag eq 'tr')
    {
     $infield--;
     push @{$self->{Table}},\@{$self->{Row}};
    }
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Finance::Bank::Commerzbank - Check your bank accounts from Perl

=head1 SYNOPSIS

  use Finance::Bank::Commerzbank;
  for (Finance::Bank::Commerzbank->check_balance(
        username  => $username,
        password  => $password
        memorable => $memorable_phrase )) {
	printf ("Transaction No: %d - TradeDate: %s - Description: %s  - ValueDate:%s - Amount: %s\n",
	            $i,
		    $_->TradeDate,
	            $_->Description,
	            $_->ValueDate,
	            $_->Amount);

  }

=head1 DESCRIPTION

This module provides a rudimentary interface to the Commerzbank online
banking system at C<https://portal01.commerzbanking.de/P-Portal/XML/IFILPortal/pgf.html?Tab=1/>. You will need
either C<Crypt::SSLeay> or C<IO::Socket::SSL> installed for HTTPS
support to work with LWP.

=head1 CLASS METHODS

    check_balance(Teilnehmernummer => $u,  PIN => $m)

Return a list of account objects, one for each of your bank accounts.

=head1 ACCOUNT OBJECT METHODS

    $ac->name
    $ac->sort_code
    $ac->account_no

Return the name of the account, the sort code formatted as the familiar
XX-YY-ZZ, and the account number.

    $ac->balance

Return the balance as a signed floating point value.

    $ac->statement

Return a mini-statement as a line-separated list of transactions.
Each transaction is a comma-separated list. B<WARNING>: this interface
is currently only useful for display, and hence may change in later
versions of this module.

=head1 WARNING

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 AUTHOR

Tobias Herbert<tobias.herbert@herbert-consult.de>

=cut

