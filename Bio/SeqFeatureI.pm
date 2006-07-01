# $Id$
#
# BioPerl module for Bio::SeqFeatureI
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::SeqFeatureI - Abstract interface of a Sequence Feature

=head1 SYNOPSIS

    # get a seqfeature somehow, eg, from a Sequence with Features attached

    foreach $feat ( $seq->get_SeqFeatures() ) {
       print "Feature from ", $feat->start, "to ", 
	       $feat->end, " Primary tag  ", $feat->primary_tag, 
	          ", produced by ", $feat->source_tag(), "\n";

       if( $feat->strand == 0 ) {
		    print "Feature applicable to either strand\n";
       } else {
          print "Feature on strand ", $feat->strand,"\n"; # -1,1
       }

       print "feature location is ",$feat->start, "..",
          $feat->end, " on strand ", $feat->strand, "\n";
       print "easy utility to print locations in GenBank/EMBL way ",
          $feat->location->to_FTstring(), "\n";

       foreach $tag ( $feat->get_all_tags() ) {
		    print "Feature has tag ", $tag, " with values, ",
		      join(' ',$feat->get_tag_values($tag)), "\n";
       }
	    print "new feature\n" if $feat->has_tag('new');
	    # features can have sub features
	    my @subfeat = $feat->get_SeqFeatures();
	 }

=head1 DESCRIPTION

This interface is the functions one can expect for any Sequence
Feature, whatever its implementation or whether it is a more complex
type (eg, a Gene). This object does not actually provide any
implemention, it just provides the definitions of what methods one can
call. See Bio::SeqFeature::Generic for a good standard implementation
of this object

=head1 FEEDBACK

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.

  bioperl-l@bioperl.org - General discussion
  http://bioperl.org/wiki/Mailing_lists - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via the
web:

  http://bugzilla.bioperl.org/

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::SeqFeatureI;
use vars qw(@ISA $HasInMemory);
use strict;

BEGIN {
    eval { require Bio::DB::InMemoryCache };
    if( $@ ) { $HasInMemory = 0 }
    else { $HasInMemory = 1 }
}

use Bio::AnnotatableI;
use Bio::RangeI;
use Bio::Seq;

use Carp;

@ISA = qw(Bio::RangeI Bio::AnnotatableI);

=head1 Bio::SeqFeatureI specific methods

New method interfaces.

=cut

=head2 get_SeqFeatures

 Title   : get_SeqFeatures
 Usage   : @feats = $feat->get_SeqFeatures();
 Function: Returns an array of sub Sequence Features
 Returns : An array
 Args    : none

=cut

sub get_SeqFeatures{
   my ($self,@args) = @_;

   $self->throw_not_implemented();
}

=head2 display_name

 Title   : display_name
 Usage   : $name = $feat->display_name()
 Function: Returns the human-readable name of the feature for displays.
 Returns : a string
 Args    : none

=cut

sub display_name { 
    shift->throw_not_implemented();
}

=head2 primary_tag

 Title   : primary_tag
 Usage   : $tag = $feat->primary_tag()
 Function: Returns the primary tag for a feature,
           eg 'exon'
 Returns : a string 
 Args    : none


=cut

sub primary_tag{
   my ($self,@args) = @_;

   $self->throw_not_implemented();

}

=head2 source_tag

 Title   : source_tag
 Usage   : $tag = $feat->source_tag()
 Function: Returns the source tag for a feature,
           eg, 'genscan' 
 Returns : a string 
 Args    : none


=cut

sub source_tag{
   my ($self,@args) = @_;

   $self->throw_not_implemented();
}


=head2 attach_seq

 Title   : attach_seq
 Usage   : $sf->attach_seq($seq)
 Function: Attaches a Bio::Seq object to this feature. This
           Bio::Seq object is for the *entire* sequence: ie
           from 1 to 10000

           Note that it is not guaranteed that if you obtain a feature from
           an object in bioperl, it will have a sequence attached. Also,
           implementors of this interface can choose to provide an empty
           implementation of this method. I.e., there is also no guarantee 
           that if you do attach a sequence, seq() or entire_seq() will not
           return undef.

           The reason that this method is here on the interface is to enable
           you to call it on every SeqFeatureI compliant object, and
           that it will be implemented in a useful way and set to a useful 
           value for the great majority of use cases. Implementors who choose
           to ignore the call are encouraged to specifically state this in
           their documentation.

 Example :
 Returns : TRUE on success
 Args    : a Bio::PrimarySeqI compliant object


=cut

sub attach_seq {
    shift->throw_not_implemented();
}

=head2 seq

 Title   : seq
 Usage   : $tseq = $sf->seq()
 Function: returns the truncated sequence (if there is a sequence attached) 
           for this feature
 Example :
 Returns : sub seq (a Bio::PrimarySeqI compliant object) on attached sequence
           bounded by start & end, or undef if there is no sequence attached
 Args    : none


=cut

sub seq {
    shift->throw_not_implemented();
}

=head2 entire_seq

 Title   : entire_seq
 Usage   : $whole_seq = $sf->entire_seq()
 Function: gives the entire sequence that this seqfeature is attached to
 Example :
 Returns : a Bio::PrimarySeqI compliant object, or undef if there is no
           sequence attached
 Args    : none


=cut

sub entire_seq {
    shift->throw_not_implemented();
}


=head2 seq_id

 Title   : seq_id
 Usage   : $obj->seq_id($newval)
 Function: There are many cases when you make a feature that you
           do know the sequence name, but do not know its actual
           sequence. This is an attribute such that you can store
           the ID (e.g., display_id) of the sequence.

           This attribute should *not* be used in GFF dumping, as
           that should come from the collection in which the seq
           feature was found.
 Returns : value of seq_id
 Args    : newvalue (optional)


=cut

sub seq_id {
    shift->throw_not_implemented();
}

=head2 gff_string

 Title   : gff_string
 Usage   : $str = $feat->gff_string;
           $str = $feat->gff_string($gff_formatter);
 Function: Provides the feature information in GFF format.

           The implementation provided here returns GFF2 by default. If you
           want a different version, supply an object implementing a method
           gff_string() accepting a SeqFeatureI object as argument. E.g., to
           obtain GFF1 format, do the following:

                my $gffio = Bio::Tools::GFF->new(-gff_version => 1);
                $gff1str = $feat->gff_string($gff1io);

 Returns : A string
 Args    : Optionally, an object implementing gff_string().


=cut

sub gff_string{
   my ($self,$formatter) = @_;

   $formatter = $self->_static_gff_formatter unless $formatter;
   return $formatter->gff_string($self);
}

my $static_gff_formatter = undef;

=head2 _static_gff_formatter

 Title   : _static_gff_formatter
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub _static_gff_formatter{
   my ($self,@args) = @_;

   if( !defined $static_gff_formatter ) {
       $static_gff_formatter = Bio::Tools::GFF->new('-gff_version' => 2);
   }
   return $static_gff_formatter;
}


=head1 Decorating methods

These methods have an implementation provided by Bio::SeqFeatureI,
but can be validly overwritten by subclasses

=head2 spliced_seq

  Title   : spliced_seq

  Usage   : $seq = $feature->spliced_seq()
            $seq = $feature_with_remote_locations->spliced_seq($db_for_seqs)

  Function: Provides a sequence of the feature which is the most
            semantically "relevant" feature for this sequence. A default
            implementation is provided which for simple cases returns just
            the sequence, but for split cases, loops over the split location
            to return the sequence. In the case of split locations with
            remote locations, eg

            join(AB000123:5567-5589,80..1144)

            in the case when a database object is passed in, it will attempt
            to retrieve the sequence from the database object, and "Do the right thing",
            however if no database object is provided, it will generate the correct
            number of N's (DNA) or X's (protein, though this is unlikely).

            This function is deliberately "magical" attempting to second guess
            what a user wants as "the" sequence for this feature.

            Implementing classes are free to override this method with their
            own magic if they have a better idea what the user wants.

  Args    : [optional] A L<Bio::DB::RandomAccessI> compliant object if 
                       one needs to retrieve remote seqs. 
            [optional] boolean if the locations should not be sorted 
                       by start location.
  Returns : A L<Bio::PrimarySeqI> object

=cut

sub spliced_seq {
    my ($self,$db,$nosort) = @_;
   
    if( ! $self->location->isa("Bio::Location::SplitLocationI") ) {
	return $self->seq(); # nice and easy!
    }

    # redundant test, but the above ISA is probably not ideal.
    if( ! $self->location->isa("Bio::Location::SplitLocationI") ) {
	$self->throw("not atomic, not split, yikes, in trouble!");
    }

    my $seqstr = '';
    my $seqid = $self->entire_seq->display_id;
    # This is to deal with reverse strand features
    # so we are really sorting features 5' -> 3' on their strand
    # i.e. rev strand features will be sorted largest to smallest
    # as this how revcom CDSes seem to be annotated in genbank.
    # Might need to eventually allow this to be programable?    
    # (can I mention how much fun this is NOT! --jason)
    
    my ($mixed,$mixedloc, $fstrand) = (0);
    if( $db && ref($db) && ! $db->isa('Bio::DB::RandomAccessI') ) {
	$self->warn("Must pass in a valid Bio::DB::RandomAccessI object for access to remote locations for spliced_seq");
	$db = undef;
    } elsif( defined $db && $HasInMemory && 
	     ! $db->isa('Bio::DB::InMemoryCache') ) {
	$db = new Bio::DB::InMemoryCache(-seqdb => $db);
    }
    if( $self->isa('Bio::Das::SegmentI') &&
	! $self->absolute ) { 
	$self->warn("Calling spliced_seq with a Bio::Das::SegmentI which does have absolute set to 1 -- be warned you may not be getting things on the correct strand");
    }
    
    my @locset = $self->location->each_Location;
    my @locs;
    if( ! $nosort ) {
	@locs = map { $_->[0] }
	# sort so that most negative is first basically to order
	# the features on the opposite strand 5'->3' on their strand
	# rather than they way most are input which is on the fwd strand

	sort { $a->[1] <=> $b->[1] } # Yes Tim, Schwartzian transformation
	map { 
	    $fstrand = $_->strand unless defined $fstrand;
	    $mixed = 1 if defined $_->strand && $fstrand != $_->strand;
	    if( defined $_->seq_id ) {
		$mixedloc = 1 if( $_->seq_id ne $seqid );
	    }
	    [ $_, $_->start * ($_->strand || 1)];	    
	} @locset; 

	if ( $mixed ) { 
	    $self->warn("Mixed strand locations, spliced seq using the input order rather than trying to sort");    
	    @locs = @locset;
	}
    } else { 
	# use the original order instead of trying to sort
	@locs = @locset;
	$fstrand = $locs[0]->strand;
    } 

    foreach my $loc ( @locs ) {
	if( ! $loc->isa("Bio::Location::Atomic") ) {
	    $self->throw("Can only deal with one level deep locations");
	}
	my $called_seq;
	if( $fstrand != $loc->strand ) {
	    $self->warn("feature strand is different from location strand!");
	}
	# deal with remote sequences

	if( defined $loc->seq_id && 
	    $loc->seq_id ne $seqid ) {
	    if( defined $db ) {
		my $sid = $loc->seq_id;
		$sid =~ s/\.\d+$//g;
		eval {
		    $called_seq = $db->get_Seq_by_acc($sid);
		};
		if( $@ ) {
		    $self->warn("In attempting to join a remote location, sequence $sid was not in database. Will provide padding N's. Full exception \n\n$@");
		    $called_seq = undef;
		}
	    } else {
		$self->warn( "cannot get remote location for ".$loc->seq_id ." without a valid Bio::DB::RandomAccessI database handle (like Bio::DB::GenBank)");
		$called_seq = undef;
	    }
	    if( !defined $called_seq ) {
		$seqstr .= 'N' x $self->length;
		next;
	    }
	} else {
	    $called_seq = $self->entire_seq;
	}
	
	if( $self->isa('Bio::Das::SegmentI') ) {
	    my ($s,$e) = ($loc->start,$loc->end);	    
	    $seqstr .= $called_seq->subseq($s,$e)->seq();
	} else { 
	    # This is dumb, subseq should work on locations...
	    if( $loc->strand == 1 ) {
		$seqstr .= $called_seq->subseq($loc->start,$loc->end);
	    } else {
		if( $nosort ) {
		    $seqstr = $called_seq->trunc($loc->start,$loc->end)->revcom->seq() . $seqstr;
		} else {
		    $seqstr .= $called_seq->trunc($loc->start,$loc->end)->revcom->seq();
		}
	    }
	}
    }
    my $out = Bio::Seq->new( -id => $self->entire_seq->display_id 
			            . "_spliced_feat",
			     -seq => $seqstr);
    
    return $out;
}

=head2 location

 Title   : location
 Usage   : my $location = $seqfeature->location()
 Function: returns a location object suitable for identifying location 
	   of feature on sequence or parent feature  
 Returns : Bio::LocationI object
 Args    : none


=cut

sub location {
   my ($self) = @_;

   $self->throw_not_implemented();
}


=head2 primary_id

 Title   : primary_id
 Usage   : $obj->primary_id($newval)
 Function: 
 Example : 
 Returns : value of primary_id (a scalar)
 Args    : on set, new value (a scalar or undef, optional)

Primary ID is a synonym for the tag 'ID'

=cut

sub primary_id{
    my $self = shift;
    # note from cjm@fruitfly.org:
    # I have commented out the following 2 lines:

    #return $self->{'primary_id'} = shift if @_;
    #return $self->{'primary_id'};

    #... and replaced it with the following; see
    # http://bioperl.org/pipermail/bioperl-l/2003-December/014150.html
    # for the discussion that lead to this change

    if (@_) {
        if ($self->has_tag('ID')) {
            $self->remove_tag('ID');
        }
        $self->add_tag_value('ID', shift);
    }
    my ($id) = $self->get_tagset_values('ID');
    return $id;
}

sub generate_unique_persistent_id {
    # DEPRECATED - us IDHandler
    my $self = shift;
    require "Bio/SeqFeature/Tools/IDHandler.pm";
    Bio::SeqFeature::Tools::IDHandler->new->generate_unique_persistent_id($self);
}

=head1 Bio::RangeI methods

These methods are inherited from RangeI and can be used
directly from a SeqFeatureI interface. Remember that a 
SeqFeature is-a RangeI, and so wherever you see RangeI you
can use a feature ($r in the below documentation).

=cut

=head2 start()

 See L<Bio::RangeI>

=head2 end()

 See L<Bio::RangeI>

=head2 strand()

 See L<Bio::RangeI>

=head2 overlaps()

 See L<Bio::RangeI>

=head2 contains()

 See L<Bio::RangeI>

=head2 equals()

 See L<Bio::RangeI>

=head2 intersection()

 See L<Bio::RangeI>

=head2 union()

 See L<Bio::RangeI>

=head1 Bio::AnnotatableI methods

=cut

=head2 has_tag()

 B<Deprecated>.  See L<Bio::AnnotatableI>

=head2 remove_tag()

 B<Deprecated>.  See L<Bio::AnnotatableI>

=head2 add_tag_value()

 B<Deprecated>.  See L<Bio::AnnotatableI>

=head2 get_tag_values()

 B<Deprecated>.  See L<Bio::AnnotatableI>

=head2 get_tagset_values()

 B<Deprecated>.  See L<Bio::AnnotatableI>

=head2 get_all_tags()

 B<Deprecated>.  See L<Bio::AnnotatableI>

=cut

1;
