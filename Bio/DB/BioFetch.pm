# $Id$
#
# BioPerl module for Bio::DB::BioFetch
#
# Cared for by Lincoln Stein <lstein@cshl.org>
#
# Copyright Lincoln Stein
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code
#

package Bio::DB::BioFetch;
use strict;
use Bio::DB::WebDBSeqI;
use HTTP::Request::Common 'POST';

=head1 NAME

Bio::DB::BioFetch - Database object interface to BioFetch retrieval

=head1 SYNOPSIS

  use Bio::DB::BioFetch;

  $bf = new Bio::DB::BioFetch;

  $seq = $sp->get_Seq_by_id('BUM');  # EMBL or SWALL ID

  # change formats, storage procedures
  $bf = new Bio::DB::BioFetch(-format        => 'fasta',
  			      -retrievaltype => 'tempfile',
  			      -db            => 'EMBL');

  $stream = $bf->get_Stream_by_id(['BUM','J00231']);
  while (my $s = $stream->next_seq) {
     print $s->seq,"\n";
  }
  # get a RefSeq entry
  $bf->db('refseq');
  eval {
      $seq = $bf->get_Seq_by_version('NM_006732.1'); # RefSeq VERSION
  };
  print "accession is ", $seq->accession_number, "\n" unless $@;


=head1 DESCRIPTION

Bio::DB::BioFetch is a guaranteed best effort sequence entry fetching
method.  It goes to the Web-based dbfetch server located at the EBI
(http://www.ebi.ac.uk/cgi-bin/dbfetch) to retrieve sequences in the
EMBL or GenBank sequence repositories.

This module implements all the Bio::DB::RandomAccessI interface, plus
the get_Stream_by_id() and get_Stream_by_acc() methods that are found
in the Bio::DB::SwissProt interface.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.


  bioperl-l@bioperl.org                         - General discussion
  http://bio.perl.org/MailList.html             - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via email
or the web:

  bioperl-bugs@bio.perl.org
  http://bio.perl.org/bioperl-bugs/

=head1 AUTHOR - Lincoln Stein

Email Lincoln Stein  E<lt>lstein@cshl.orgE<lt>

Also thanks to Heikki Lehvaslaiho E<lt>heikki@ebi.ac.ukE<gt> for the
BioFetch server and interface specification.

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

# Let the code begin...
use vars qw(@ISA $VERSION %FORMATMAP );
@ISA = 'Bio::DB::WebDBSeqI';
$VERSION = '1.0';

# warning: names used here must map into Bio::SeqIO::* space
use constant DEFAULT_LOCATION => 'http://www.ebi.ac.uk/cgi-bin/dbfetch';

BEGIN {

    %FORMATMAP = ( 
		   'embl' => {
		       module => 'embl',  # SeqIO module name
		       default => 'embl', # default BioFetch format
		       embl => 1,         # alternative BioFetch format 
		       fasta => 1         # alternative BioFetch format 
		       },
		   'swall' => {
		       module => 'swiss',
		       default => 'swissprot',
		       swissprot => 1,
		       fasta => 1
		       },
		   'refseq' => {
		       module => 'genbank',
		       default => 'genbanknk',
		       genbank => 1,
		       fasta => 1
		       }
		   );
}

=head2 new

 Title   : new
 Usage   : $bf = Bio::DB::BioFetch->new(@args)
 Function: Construct a new Bio::DB::BioFetch object
 Returns : a Bio::DB::BioFetch object
 Args    : see below
 Throws  :

@args are standard -name=E<gt>value options as listed in the following
table. If you do not provide any options, the module assumes reasonable
defaults.

  Option         Value                            Default
  ------         -----                            -------

  -baseaddress   location of dbfetch server       http://www.ebi.ac.uk/cgi-bin/dbfetch
  -retrievaltype "tempfile" or "io_string"        io_string
  -format        "embl" or "fasta" or "swissprot" embl
  -db            "embl", "genbank" or "swall"     embl

=cut

#'
sub new {
  my ($class,@args) = @_;
  my $self = $class->SUPER::new(@args);
  my ($db) = $self->_rearrange([qw(DB)],@args);
  $db    ||= $self->default_db;
  $self->db($db);
  $self->url_base_address(DEFAULT_LOCATION) unless $self->url_base_address;
  $self;
}

=head2 new_from_registry

 Title   : new_from_registry
 Usage   : $biofetch = $db->new_from_registry(%config)
 Function: Creates a BioFetch object from the registry config hash
 Returns : itself
 Args    : A configuration hash (see Registry.pm)
 Throws  : 


=cut

sub new_from_registry {
    my ($class,%config)=@_;

    my $self = $class->SUPER::new(
				  -BASEADDRESS=>$config{'location'}
				  );
    $self->db($config{'biodbname'});
    return $self;
}
    
# from Bio::DB::RandomAccessI

=head2 get_Seq_by_id

 Title   : get_Seq_by_id
 Usage   : $seq = $db->get_Seq_by_id('ROA1_HUMAN')
 Function: Gets a Bio::Seq object by its name
 Returns : a Bio::Seq object
 Args    : the id (as a string) of a sequence
 Throws  : "id does not exist" exception


=cut

=head2 get_Seq_by_acc

 Title   : get_Seq_by_acc
 Usage   : $seq = $db->get_Seq_by_acc('X77802');
 Function: Gets a Bio::Seq object by accession number
 Returns : A Bio::Seq object
 Args    : accession number (as a string)
 Throws  : "acc does not exist" exception

=cut

=head2 get_Seq_by_gi

 Title   : get_Seq_by_gi
 Usage   : $seq = $db->get_Seq_by_gi('405830');
 Function: Gets a Bio::Seq object by gi number
 Returns : A Bio::Seq object
 Args    : gi number (as a string)
 Throws  : "gi does not exist" exception

=cut

=head2 get_Seq_by_version

 Title   : get_Seq_by_version
 Usage   : $seq = $db->get_Seq_by_version('X77802.1');
 Function: Gets a Bio::Seq object by sequence version
 Returns : A Bio::Seq object
 Args    : accession.version (as a string)
 Throws  : "acc.version does not exist" exception

=cut

sub get_Seq_by_version {
   my ($self,$seqid) = @_;
   return $self->get_Seq_by_acc($seqid);
}


=head2 get_Stream_by_id

  Title   : get_Stream_by_id
  Usage   : $stream = $db->get_Stream_by_id( [$uid1, $uid2] );
  Function: Gets a series of Seq objects by unique identifiers
  Returns : a Bio::SeqIO stream object
  Args    : $ref : a reference to an array of unique identifiers for
                   the desired sequence entries

=cut

=head2 get_Stream_by_acc

  Title   : get_Stream_by_acc
  Usage   : $seq = $db->get_Seq_by_acc([$acc1, $acc2]);
  Function: Gets a series of Seq objects by accession numbers
  Returns : a Bio::SeqIO stream object
  Args    : $ref : a reference to an array of accession numbers for
                   the desired sequence entries
  Note    : For GenBank, this just calls the same code for get_Stream_by_id()

=cut

=head2 get_Stream_by_gi

  Title   : get_Stream_by_gi
  Usage   : $seq = $db->get_Seq_by_gi([$gi1, $gi2]);
  Function: Gets a series of Seq objects by gi numbers
  Returns : a Bio::SeqIO stream object
  Args    : $ref : a reference to an array of gi numbers for
                   the desired sequence entries
  Note    : For GenBank, this just calls the same code for get_Stream_by_id()

=cut

=head2 get_Stream_by_batch

  Title   : get_Stream_by_batch
  Usage   : $seq = $db->get_Stream_by_batch($ref);
  Function: Get a series of Seq objects by their IDs
  Example :
  Returns : a Bio::SeqIO stream object
  Args    : $ref : an array reference containing a list of unique
            ids/accession numbers.

In some of the Bio::DB::* moduels, get_Stream_by_id() is called
get_Stream_by_batch().  Since there seems to be no consensus, this
is provided as an alias.

=cut

*get_Stream_by_batch = \&Bio::DB::WebDBSeqI::get_Stream_by_id;

=head1 The remainder of these methods are for internal use

=head2 get_request

 Title   : get_request
 Usage   : my $url = $self->get_request
 Function: returns a HTTP::Request object
 Returns : 
 Args    : %qualifiers = a hash of qualifiers (ids, format, etc)

=cut


sub get_request {
    my ($self, @qualifiers) = @_;
    my ($uids, $format) = $self->_rearrange([qw(UIDS FORMAT)],
					    @qualifiers);
    my $db     = $self->db;
    $self->throw("Must specify a value for UIDs to fetch")
	unless defined $uids;
    my $tmp;
    my $format_string = '';

    $format ||= $self->default_format;
    ($format, $tmp) = $self->request_format($format);

    my $base = $self->url_base_address;
    my $uid = join('+',ref $uids ? @$uids : $uids);
    $self->debug("\n$base$format_string&id=$uid\n");
    return POST($base,
		[ db     => $db,
		  id     => join('+',ref $uids ? @$uids : $uids),
		  format => $format,
		  style  => 'raw'
	     ]);
}

=head2 default_format

 Title   : default_format
 Usage   : $format = $self->default_format
 Function: return the default format
 Returns : a string
 Args    : 

=cut

sub default_format { 
    return 'default';
}

=head2 default_db

 Title   : default_db
 Usage   : $db = $self->default_db
 Function: return the default database
 Returns : a string
 Args    :

=cut

sub default_db     { 'embl' }

=head2 db

 Title   : db
 Usage   : $db = $self->db([$db])
 Function: get/set the database
 Returns : a string
 Args    : new database

=cut

sub db {
  my $self = shift;

  if (@_) {

      my $db = lc shift;
      $FORMATMAP{$db} or $self->throw("invalid db [$db], must be one of [".
				     join(' ',keys %FORMATMAP).  "]");
      $self->{_db} = $db;
  }
  return $self->{_db} || $self->default_db ;
}

=head2 postprocess_data

 Title   : postprocess_data
 Usage   : $self->postprocess_data ( 'type' => 'string',
				     'location' => \$datastr);
 Function: process downloaded data before loading into a Bio::SeqIO
 Returns : void
 Args    : hash with two keys - 'type' can be 'string' or 'file'
                              - 'location' either file location or string 
                                           reference containing data
=cut

sub postprocess_data {
  my ($self,%args) = @_;

  # check for errors in the stream
  if ($args{'type'} eq 'string') {
    my $stringref = $args{'location'};
    if ($$stringref =~ /^ERROR (\d+) (.+)/m) {
      $self->throw("BioFetch Error $1: $2");
    }
  }

  elsif ($args{'type'} eq 'file') {
    open (F,$args{'location'}) or $self->throw("Couldn't open $args{location}: $!");
    # this is dumb, but the error may be anywhere on the first three lines because the
    # CGI headers are sometimes printed out by the server...
    my @data = (scalar <F>,scalar <F>,scalar <F>);
    if (join('',@data) =~ /^ERROR (\d+) (.+)/m) {
      $self->throw("BioFetch Error $1: $2");
    }
    close F;
  }

  else {
    $self->throw("Don't know how to preprocess data of type $args{'type'}");
  }
}


=head2 request_format

 Title   : request_format
 Usage   : my ($req_format, $ioformat) = $self->request_format;
           $self->request_format("genbank");
           $self->request_format("fasta");
 Function: Get/Set sequence format retrieval. The get-form will normally not
           be used outside of this and derived modules.
 Returns : Array of two strings, the first representing the format for
           retrieval, and the second specifying the corresponding SeqIO format.
 Args    : $format = sequence format

=cut

sub request_format {
    my ($self, $value) = @_;
    if ( defined $value ) { 
	my $db = $self->db; 
	my $format = lc $value;
	#print "format:", $format, " module:", $FORMATMAP{$db}->{'module'}, " ($db)\n";	
	$self->throw("Invalid format [$format], must be one of [".
		     join(' ',keys %{$FORMATMAP{$db}}). "]")
	    unless  $format eq 'default' || $FORMATMAP{$db}->{$format};

	$self->{'_format'} = [ $format, $FORMATMAP{$db}->{'module'}];
    }
    return @{$self->{'_format'}};
}

1;
