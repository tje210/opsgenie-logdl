#!/bin/bash

# keep in mind that the time that the script sends is GMT.  so if you enter 10pm, then you really mean 5pm EST (or 6pm EDT).
# maybe functionality can be built in to adjust this automatically.  probably more work right now than it's worth, but maybe in the future.




if [ $1 ]; then
        echo "date present - format not checked"
        else
        sleep 2
        echo "!!!!!!!!!!!!!ERROR ERROR ERROR!!!!!!!!!!!!!!!!!!!!!"
        sleep 2
        echo "Usage:  user$ logdl timestamp NumberOfEntries"
        exit 1
fi
if [ $2 ]; then
        echo "number of entries present - format not checked"
        else
        sleep 2
        echo "!!!!!!!!!!!!!ERROR ERROR ERROR!!!!!!!!!!!!!!!!!!!!!"
        sleep 2
        echo "Usage:  user$ logdl timestamp NumberOfEntries"
        exit 1
fi

# find $HOME/logdl, if it doesn't exist then make it.
if [ ! -d $HOME/logdl ]; then
        mkdir $HOME/logdl/;
	echo It looks like this is the first time you\'re using logdl.  Welcome!  To start off, we need to get your access set up.
        echo What\'s your api key?
        read apikey
        echo $apikey > $HOME/logdl/logdl.conf
	chmod 700 $HOME/logdl/logdl.conf
fi

# usage - logdl 2021-02-18-10-00-00 100
# will download the next 100 timestamps' urls, then then the script will parse that for the inidividual timestamps, then plug those back in to get downloads urls for the log entries, then it'll download the entries and cat them from a file ... optionally maybe a 3rd argument to grep for something specific, but we'll want to put the stuff in a file no matter what to save us from re-doing the whole search and dl process

timestamp=$1
numberofentries=$2
apikey=`cat $HOME/logdl/logdl.conf`


# for debugging
#echo the api key is $apikey ... this is fine
#for debugging
#echo the curl command is curl -X GET \'https://api.opsgenie.com/v2/logs/list/$1?limit=$2\' -H \'Authorization: GenieKey $apikey\' -H \'Content-Type: application/json\'  ... this is fine

#STEP 1
# downloads list of log entries, delimited at thee beginning by a timestamp, and at the end by the entry #.

# verbose curl is for debugging
#curl -v -X GET 'https://api.opsgenie.com/v2/logs/list/'$1'?limit='$2 -H 'Authorization: GenieKey '$apikey -H 'Content-Type: application/json' > $HOME/logdl/1.entrylist.json

#regular curl is not for debugging, comment and uncomment as approps
rm $HOME/logdl/1.entrylist.json
curl -X GET 'https://api.opsgenie.com/v2/logs/list/'$1'?limit='$2 -H 'Authorization: GenieKey '$apikey -H 'Content-Type: application/json' > $HOME/logdl/1.entrylist.json

#STEP 2
# next run that output through grep -o to get the timestamps only, which lets us get dl links
# for debugging
#cat $HOME/logdl/1.entrylist.json;
#printf "\nthis probably isnt fine if the key form is invalid\n"

rm $HOME/logdl/2.timestamps.txt
grep -o '[0-9-]\+.json' $HOME/logdl/1.entrylist.json > $HOME/logdl/2.timestamps.txt

#STEP 3
# convert timestamps to download curls, push output to 3.output
rm $HOME/logdl/3.output
while read p; do
        curl -X GET 'https://api.opsgenie.com/v2/logs/download/'$p -H 'Authorization: GenieKey '$apikey -H 'Content-Type: application/json' >> $HOME/logdl/3.output
        printf "\n" >> $HOME/logdl/3.output
done <$HOME/logdl/2.timestamps.txt

#STEP 4
# now perform the download of each like from 3.output
rm $HOME/logdl/4.output
while read p; do
        # do verbose curl if this fails
        curl $p >> 4.output
done < 3.output

# example output of one line:  {"message":"[system] Alert closed via system using policy/policies[autoclose and no-notify tags]","type":"AlertLog","level":"INFO","details":{"_result":{"alertMessage":"DIG-IP-S WARNING OUT  2114658  17:05 2  alarm(s)","alertAction":"Close","alertCount":"1","alertId":"c2033ea0-b455-4aaa-bc15-4028f2ad12c2-1613599817637","alertAlias":"c2033ea0-b455-4aaa-bc15-4028f2ad12c2-1613599817637","user":"System"},"alertLogOwner":"System","alertId":"c2033ea0-b455-4aaa-bc15-4028f2ad12c2-1613599817637","alertLogType":"system"},"date":1613686218706}
# so then from here, use awk, grep, sed etc to get the info out.  e.g. - grep -o 'alertMessage.*,' <- will get you the alert's message (sure there's a wawy to just capture the message and not the 'alertMessage' part ... or use awk FS too and just print $2

# just for an example, to get the message roughly, go cat 4.output | grep -o 'alertMessage.*alertAction' .  not the prettiest but it gets it done.  i can imagine using this script consistently to look for things that happened once around a certain time, or to see if things happen around a certain time, or for things that always happen around a certain time.  could enhance this by giving timestamps and options to dl ... or give timestamps + messages as output, as succinctly as possible

