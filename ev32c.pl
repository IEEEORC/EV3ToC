use strict;
use XML::LibXML;
use Types;

my $parser = XML::LibXML->new();
my $xml_doc = $parser->parse_file("Program.ev3p");

my @block_diagram = $xml_doc->getElementsByTagName('BlockDiagram');
my $bd_node = $block_diagram[0];
my $indents = 0;
my $code = "void foo () {\n";
$code .= traverse($bd_node);
$code .= "}\n";

print $code;

sub traverse {
	$indents++;
	my $top = $_[0];
	my @children = $top->childNodes();
	my $start_id = "";
	my %blocks = ();
	my %wires = ();
	
	foreach (@children) {
		if ($_->nodeName eq "ConfigurableWhileLoop") {
			my $inner_code = traverse($_);
			#configurable while loop has info in its children
			#and possibly more blocks
			my $id = $_->getAttribute("Id");
			my @info = getWhileInfo($_);
			my $while = new WhileLoop($id, $info[0], $info[1], $info[2], $inner_code);
			#print "id: $id, while type: $info[0], port: $info[1], conditions: $info[2] \n";
			$blocks{$id} = $while if defined($id);
			
			
			
		}
		elsif ($_->nodeName eq "Wire") {
			#just add a wire to the wire hash. 
			my $id = $_->getAttribute("Id");
			my $connections = $_->getAttribute("Joints");
			$connections =~ /N\((\w+\d+):.*N\((\w+\d+).*/;
			$wires{$1} = $2 if defined($1);
			if ($1 eq "n0") {
				$start_id = "n0";
			}
		}
		elsif ($_->nodeName eq "ConfigurableMethodCall") {
			#Method calls just have info in their children
			my $id = $_->getAttribute("Id");
			my @info = getMethodInfo($_);
			
			$_->getAttribute("Target") =~ /(.*)\\\./;
			my $target = $1;
			#print "id: $id, method type: $target, speedA: $info[1], speedB: $info[2], n_rot: $info[3] \n";
			if ($target eq "MoveTankDistanceRotations"){
				my $method = new TankMethodCall($id, $info[1], $info[2], $info[3]);
				$blocks{$id} = $method if defined($id);
			}
			
			
		}
		elsif ($_->nodeName eq "StartBlock") {
			$start_id = $_->getAttribute("Id");
		}
	}
	
	my $level_code = "";
	my $finished = 0;

	#find the first wire
	my $next_block_id = $wires{$start_id};
	#print $next_block_id, "\n";
	my $next_block = $blocks{$next_block_id};
	while (! $finished) {

		$level_code .= $next_block->toCode($indents);
		if (exists($wires{$next_block_id})) {
			if (defined($blocks{$wires{$next_block_id}})) {
				$next_block = $blocks{$wires{$next_block_id}};
				$next_block_id = $next_block->getId;
			}
			else {
				$finished = 1;
			}
		}
		else {
			$finished = 1;
		}
	}
	$indents--;
	return $level_code;
}

sub getWhileInfo {
	my $top = $_[0];
	my @info;
	foreach ($top->childNodes()) {
		# first grab info, and then make recursive call
		if ($_->nodeName eq "ConfigurableWhileLoop.BuiltInMethod" and $_->getAttribute("CallType") eq "StopCondition") {
			foreach ($_->childNodes()) {
				if ($_->nodeName eq "ConfigurableMethodCall") {
					$_->getAttribute("Target") =~ /(.*)\\\./;
					push (@info, $1);
					foreach($_->childNodes()) {
						if (($_->nodeName eq "ConfigurableMethodTerminal") and $_->hasAttribute("ConfiguredValue")) {
							push(@info, $_->getAttribute("ConfiguredValue"));
						}
					}
				}
			}
		}
	}
	return @info;
}

sub getMethodInfo{
	my $top = $_[0];
	my @info;
	foreach ($top->childNodes()) {
		if ($_->nodeName eq "ConfigurableMethodTerminal") {
			push(@info, $_->getAttribute("ConfiguredValue"))
		}
	}
	return @info;
}


