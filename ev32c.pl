use strict;
use XML::LibXML;
use Types;

my $parser = XML::LibXML->new();
#TODO: Make this take in the name of a file as an argument
my $xml_doc = $parser->parse_file("Program.ev3p");

my @block_diagram = $xml_doc->getElementsByTagName('BlockDiagram');
my $bd_node = $block_diagram[0];
my $indents = 0;
my $code = "void foo () {\n";
$code .= traverse($bd_node);
$code .= "}\n";

#TODO: Make this print out to "<filename>.c"
print $code;

sub traverse {
	$indents++;
	my $top = $_[0];
	my @children = $top->childNodes();
	my $start_id = "";
	my %blocks = ();
	my %wires = ();
	my %pairs = ();
	my %pairIds = (); #use a hash for easier searching
	
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
			$connections =~ /N\((\w+\d*):.*N\((\w+\d*).*/;
			
			$wires{$1} = $2 if defined($1);
			if ($1 eq "n0") {
				$start_id = "n0";
			}
			elsif($1 eq "Output") {
				#if th wire is Output to Input, then nothing happens and 
				#no blocks have to be looked for. Maybe remove it.
			
				$start_id = "Output";
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
		elsif ($_->nodeName eq "PairedConfigurableMethodCall") { 
			#Paired structure need target for compare, need paired ID
			#This block shouldn't have any nested blocks. It's just a 
			#comparison block.
			my $id = $_->getAttribute("Id");
			my $target = $_->getAttribute("Target");
			my $pair = $_->getAttribute("PairedStructure");
			my @info = getPairedInfo($_);
			my $pairBlock = new PairedStructure($id, $pair, $target, $info[0], $info[1]);
			$blocks{$id} = $pairBlock if defined($id);
			$pairs{$pair} = $pairBlock if defined ($pair); #paired structs act as the test condition
			$pairIds{$id} = $pairBlock;
			if (defined($blocks{$pair})) {
				$blocks{$pair}->setTest($pairBlock->toCode);
			}
			
		}
		elsif ($_->nodeName eq "ConfigurableFlatCaseStructure") {
			
			#Case statement (If/Else)
			my $id = $_->getAttribute("Id");
			# deal with test condition
			my $test = "";
			if (defined($pairs{$id})) {
				$test = $pairs{$id}->toCode;
			}
			#loop through to find true case and false
			my $trueCode = "";
			my $falseCode = "";
			foreach ($_->childNodes()) {
				if ($_->nodeName eq "ConfigurableFlatCaseStructure.Case") {
					if ($_->getAttribute("Pattern") eq "True") {
						#true case
						$trueCode = traverse($_);
					}
					else {
						#false case, assuming there are only 2 cases
						$falseCode = traverse($_);
					}
				}
			}
			
			my $case = new CaseStatement($id, $test, $trueCode, $falseCode);
			$blocks{$id} = $case if defined($id);
		}
		elsif ($_->nodeName eq "ConfigurableWaitFor") {
			my $id = $_->getAttribute("Id");
			my @info;
			foreach ($_->childNodes()) {
				if ($_->nodeName eq "ConfigurableMethodTerminal") {
					#assuming terminals are always in the same order
					push(@info, $_->getAttribute("ConfiguredValue"));
				}
			}
			my $time = $info[0];
			my $wait = new WaitBlock($id, $time);
			$blocks{$id} = $wait if defined($id);
		}
	}
	
	# have to update wires now
	foreach (keys %wires) {
		my $end = $wires{$_};
		if (defined($pairIds{$end})) {
			my $pairBlock = $pairIds{$end};
			$wires{$_} = $pairBlock->getPair;
		}
	}
	
	my $level_code = "";
	my $finished = 0;

	#find the first wire
	my $next_block_id = $wires{$start_id};
	#print $next_block_id, "\n";
	my $next_block = $blocks{$next_block_id};
	while (! $finished) {
		if ($next_block_id eq "Input") {
			#we're done at this level
			$finished = 1;
		}
		else {
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
	}
	$indents--;
	return $level_code;
}

sub getPairedInfo {
	my $node = $_[0];
	my @info;
	#making an assumption that terminals are always the same order
	foreach ($node->childNodes()) {
		if ($_->nodeName() eq "ConfigurableMethodTerminal") {
			push (@info, $_->getAttribute("ConfiguredValue"));
		}
	}
	#only need the first 2 values but for simplicity grab all of them
	return @info;
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


