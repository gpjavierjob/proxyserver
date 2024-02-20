#!/bin/bash

# Set beginning index:
counter=1

#Print out a message for user to get the file name
echo "What is the name of the file that we are going to generate?"

# Set the HTPASSWD file name:
read fileName

# Checj if file exists already. If it does, delete it:
if test -f "./$fileName"; then
	echo "File named $fileName already exists. We need to delete it."
	rm ./$fileName
else
	echo "A file named $fileName will be created."
fi

# Print out a message for user:
echo "how many users do we need to create?"

# Read from console:
read maxUser

# Ask for a default password:
echo "What is the default password you are going to set for users?"

# Set the default password:
read defaultPassword

# Create "maxUser" number of users and store into HTPASSWD file:
while [ $counter -le $maxUser ]
do
	echo "Creating user$counter"

	# Each user name will be in a format of "user" followed by a number:
	user="user"
	user+=$counter

	# If it is for the first user, just create a new file. Later, just append
	# the new user's credential to the file:
	if [ $counter == 1 ]; then
		htpasswd -c -B -b ./${fileName} ${user} ${defaultPassword}
	else
		htpasswd -B -b ./${fileName} ${user} ${defaultPassword}
	fi

	(( counter ++ ))
done

echo "All done. Your HTPASSWD file is available at $fileName"