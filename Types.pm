use strict;

package WhileLoop;

sub new {
	my $class = shift;
	my $self = {
				id => shift,
				type => shift,
				port => shift,
				conditions => shift,
				inner_code => shift
	};
	bless $self, $class;
	return $self;
}

sub getId {
	my ($self) = @_;
	return $self->{id};
}

sub toCode {
	my ($self, $indents) = @_;
	
	my $cond = "";
	if ($self->{type} eq "StopNever") {
		$cond = "true";
	}
	elsif ($self->{type} eq "ColorCompare") {
		$self->{conditions} =~ /\[(\d)\]/;
		$cond = "colorSensor.read() != $1";
	}
	my $tabString = "";
	for (1 .. $indents) {
		$tabString .= "\t";
	}
	
	my $code = "${tabString}while ($cond) { \n$self->{inner_code}${tabString}}\n";
	return $code;
}


package Wire;

sub new {
	my $class = shift;
	my $self = {
				id => shift,
				input => shift,
				output => shift
	};
	bless $self, $class;
	return $self;
}
#add get methods

package TankMethodCall;

sub new {
	my $class = shift;
	my $self = {
				id => shift,
				speedA => shift,
				speedB => shift,
				rot => shift
	};
	bless $self, $class;
	return $self;
}

sub getId {
	my ($self) = @_;
	return $self->{id};
}

sub toCode {
	my ($self, $indents) = @_;
	my $a = $self->{speedA};
	my $b = $self->{speedB};
	my $rot = $self->{rot};
	
	my $tabString = "";
	for (1 .. $indents) {
		$tabString .= "\t";
	}
	
	my $code = "${tabString}moveTankRot($a, $b, $rot);\n";
	return $code;
}

package PairedStructure;

sub new {
	my $class = shift;
	my $self = {
				id => shift,
				pair => shift,
				compare => shift,
				port => shift,
				condition => shift
	};
	bless $self, $class;
	return $self;
}

sub getPair {
	my ($self) = @_;
	return $self->{pair};
}

sub getId {
	my ($self) = @_;
	return $self->{id};
}

sub toCode {
	my ($self, $indents) = @_;
	$self->{compare} =~ m/(\w+)\\\..*/;
	
	my $code = "$1($self->{condition})";
	return $code;
}

package CaseStatement;

sub new {
	my $class = shift;
	my $self = {
				id => shift,
				test => shift,
				trueCode => shift,
				falseCode => shift
	};
	bless $self, $class;
	return $self;
}

sub getId {
	my ($self) = @_;
	return $self->{id};
}

sub setTest {
	my ( $self, $test ) = @_;
    $self->{test} = $test if defined($test);
    return $self->{test}

}

sub toCode {
	my ($self, $indents) = @_;
	
	my $tabString = "";
	for (1 .. $indents) {
		$tabString .= "\t";
	}
	
	my $code = "${tabString}if ($self->{test}) { \n";
	$code .= "$self->{trueCode}\n";
	$code .= "${tabString}}\n";
	$code .= "${tabString}else { \n";
	$code .= "$self->{falseCode}\n";
	$code .= "${tabString}}\n";
	return $code;
}

package WaitBlock;

sub new {
	my $class = shift;
	my $self = {
				id => shift,
				time => shift
	};
	bless $self, $class;
	return $self;
}

sub getId {
	my ($self) = @_;
	return $self->{id};
}

sub toCode {
	my ($self, $indents) = @_;
	
	my $tabString = "";
	for (1 .. $indents) {
		$tabString .= "\t";
	}
	
	my $code = "${tabString}delay($self->{time}000);\n";
	return $code;
}

#end file
1;
