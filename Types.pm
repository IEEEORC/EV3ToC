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

#end file
1;
