#!/bin/bash

firewallDir="/usr/share/firewall"

# firewallDir contains a directory for each table (filter, nat, mangle)
# - each table dir contains a dir for each chain in that table
# - each chain dir has link files that are iptables snippets
# - each table dir can contain a CHAIN.head file, which goes in front of the chain
# - each table dir can contain a CHAIN.tail file, which goes in back of the chain
# and should set default policy
# 
# Example firewallDir layout
# filter
#   INPUT
#     ftp
#     http
#     smb
#   INPUT.head
#   INPUT.tail
#   OUTPUT
#   OUTPUT.head
#   FORWARD
# nat
#   PREROUTING
#
# Any chains not in this tree will be removed from the running config

#oldTable=$(mktemp oldTable.XXXXXX)
#currentTable=$(mktemp currTable.XXXXXX)
if [ "$1" == 'DEBUG' ]; then
    DEBUG=1
else
    DEBUG=0
fi
IPTABLES="/sbin/iptables"

# iptables wrapper
function ipt {

	if [ "$DEBUG" -eq 1 ]; then
		echo "DEBUG: running $IPTABLES $@"
                eval $IPTABLES $@
        else
                eval $IPTABLES $@ 2>/dev/null
	fi

	retVal="$?"
	return $retVal
}

function insertEntry {
	table="$1"
	chain="$2"
	entryNum="$3"
	shift; shift; shift
	ENTRY="$@"

	# Remove the -A if it's there, we already know the table and chain
	# This will make it easier to create the files, as you can just copy/paste
	# from an iptables-save
	ENTRY=$(echo $ENTRY | sed 's/^-A [0-9a-zA-Z-]* //')
        
	# Insert at the enegrep -v '^([[:space:]]*#|[[:space:]]*$)'d of the new section
	if echo "$ENTRY" | grep -q '^-P'; then
		ipt -t $table $ENTRY
	else
		ipt -t $table -I $chain $entryNum $ENTRY
	fi
}

function removeComments {
	filename="$1"
	egrep -v '^([[:space:]]*#|[[:space:]]*$)' $filename 2>/dev/null
}


# write out the current firewall
#iptables-save > $oldTable

# Set up all the tables in advance.
pushd ${firewallDir} > /dev/null
for table in *; do
	# A particular table
	if [ -d "$table" ]; then
		pushd "$table" > /dev/null
		for chain in *; do
			if [ ! -d "$chain" ]; then
				# Only directories are valid chains
				continue
			fi

			#create the table
			ipt -t $table -N $chain 2> /dev/null
		done
		popd > /dev/null
	fi
done
popd > /dev/null

# Put the iptables pieces into the full layout of the table
pushd ${firewallDir} > /dev/null
for table in *; do
	if [ -d "$table" ]; then
		pushd "$table" > /dev/null
		for chain in *; do
			if [ ! -d "$chain" ]; then
				# Only directories are valid chains
				continue
			fi

			echo "Working on chain $chain in table $table"
			numEntries=0
			
			echo "Adding rules to chain $chain in table $table"
			if [ -f "${chain}.head" ]; then
				# The head of the firewall goes in first.
				while read ENTRY; do
					if echo "$ENTRY" | grep -qv '^-P'; then
						let numEntries="$numEntries + 1"
					fi
					insertEntry $table $chain $numEntries $ENTRY
				done < <( removeComments "${chain}.head" )
			fi

			# go into the chain, add all the link files to the firewall			
			pushd $chain > /dev/null
			for link in *; do
				while read ENTRY; do
					if echo "$ENTRY" | grep -qv '^-P'; then
						let numEntries="$numEntries + 1"
					fi
					insertEntry $table $chain $numEntries $ENTRY
				done < <( removeComments "$link" )
			done 
			popd > /dev/null

			if [ -f "$chain.tail" ]; then
				# The tail of the firewall goes in last.
				while read ENTRY; do
					if echo "$ENTRY" | grep -qv '^-P'; then
						let numEntries="$numEntries + 1"
					fi

					insertEntry $table $chain $numEntries $ENTRY
				done < <( removeComments "${chain}.tail" )
			fi

			# flush out the old rules from this chain
			echo "Cleaning chain $chain in table $table..."
			let oldEntry="$numEntries + 1"
			while ipt -t $table -D $chain $oldEntry; do
				echo -en "."
			done
			echo -en "\n"
		done
		popd > /dev/null
	fi
done
popd > /dev/null

# Delete all rules from the chains that shouldn't be there
pushd ${firewallDir} > /dev/null
for table in *; do
	pushd "$table" > /dev/null > /dev/null
	for chain in $(iptables-save | sed -n '/^\*'$table'/,/^\*/p' | grep '^:' | cut -d' ' -f1 | sed 's/://'); do
		if [ ! -d "$chain" ]; then
			# Flush the chain
			echo "Flushing rules from chain $chain in table $table"
			ipt -t $table -F $chain
		fi
	done
	popd > /dev/null
done
popd > /dev/null

# delete the chains that shouldn't be there 
pushd ${firewallDir} > /dev/null
for table in filter nat mangle; do
	if [ ! -d "$table" ]; then
		# This table isn't used, clear it
		ipt -t $table -F
		ipt -t $table -X
	else
		
		pushd "$table" > /dev/null
		for chain in $(iptables-save | sed -n '/^\*'$table'/,/^\*/p' | grep '^:' | cut -d' ' -f1 | sed 's/://'); do
                        if [ "$chain" == "FORWARD" ]; then
                            continue
                        fi
			if [ ! -d "$chain" ]; then
				# Delete the chain
				echo "Deleting chain $chain from table $table"
				ipt -t $table -P $chain ACCEPT
				ipt -t $table -X $chain
			fi
		done
		popd > /dev/null
	fi
done
