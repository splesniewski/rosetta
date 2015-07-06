BEGIN{
rMasterHeader="^(Linux) ([[:alnum:]\\-.]+) +.([a-z0-9]+).[ \t]+([0-9]+)/([0-9]+)/([0-9]+)"

rHeader="^[0-9]+:[0-9]+:[0-9]+ [AP]M[ \t]+IFACE[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]+([^ \t]+)"

rData="^([0-9]+):([0-9]+):([0-9]+) (AM|PM)[ \t]+([^ \t]+)[ \t]+([0-9]+\\.[0-9]+)[ \t]+([0-9]+\\.[0-9]+)[ \t]+([0-9]+\\.[0-9]+)[ \t]+([0-9]+\\.[0-9]+)[ \t]+([0-9]+\\.[0-9]+)[ \t]+([0-9]+\\.[0-9]+)[ \t]+([0-9]+\\.[0-9]+)"

rFooter="^Average:"
rBlankLine="^$"
}
$0 ~ rMasterHeader{
    match($0,rMasterHeader, m)
    dJSONData["operatingsystem"]=m[1]
    dJSONData["operatingsystemversion"]=m[2]
    dJSONData["hostname"]=m[3]

    dJSONMeta["month"]=m[4]
    dJSONMeta["dom"]=m[5]
    dJSONMeta["year"]=m[6]

    next
}
$0 ~ rHeader {
    match($0, rHeader, dJSONMetaCols)
    next
}
$0 ~ rData {
    match($0, rData, m)
 
    recordMeta["hour"]=m[1]
    recordMeta["minute"]=m[2]
    recordMeta["second"]=m[3]
    recordMeta["meridiem"]=m[4]
    recordMeta["IFACE"]=m[5]

    timestamp=mktime(sprintf("%d %d %d %d %d %d",
			     dJSONMeta["year"], dJSONMeta["month"], dJSONMeta["dom"],
			     ((recordMeta["meridiem"]=="AM")?(recordMeta["hour"]==12?0:recordMeta["hour"]):(recordMeta["hour"]==12?12:recordMeta["hour"]+12)),
			     recordMeta["minute"],
			     recordMeta["second"] ) )

    for (n=0; n<7; n++)
	dJSONData["data",timestamp,recordMeta["IFACE"],dJSONMetaCols[n+1]]=m[n+6];

    # track values to use later interating over data
    ktimestamp[timestamp]++
    kIFACE[recordMeta["IFACE"]]++

    next
}
$0 ~ rFooter {
    next
}
$0 ~ rBlankLine {
    next
}
{
    next
}
END{
    # No convenient JSON output lib for gawk so generate it the hard way.
    # - use *_comma as flag to determine when a commas should be inserted
    # (skip first, insert for remaining)
    printf("{\n")

    printf("\"data\":{\n")
    timestamp_comma=0
    for(timestamp in ktimestamp){
	printf("%s\"%s\": {",(timestamp_comma==0?"":","),timestamp)
	timestamp_comma=1
	IFACE_comma=0
	for(IFACE in kIFACE){
	    printf("%s\"%s\": {",(IFACE_comma==0?"":","),IFACE)
	    IFACE_comma=1
	    cols_comma=0
	    for (n=0; n<7; n++){
		printf("%s\"%s\": \"%s\"",((cols_comma==0)?"":","),dJSONMetaCols[n+1],dJSONData["data",timestamp,IFACE,dJSONMetaCols[n+1]])
		cols_comma=1
	    }
	    printf("}\n") # IFACE
	}
	printf("}\n") # timestamp
    }
    printf("},\n") # data

    printf( "\"%s\": \"%s\"\n","operatingsystem", dJSONData["operatingsystem"])
    printf(",\"%s\": \"%s\"\n","operatingsystemversion", dJSONData["operatingsystemversion"])
    printf(",\"%s\": \"%s\"\n","hostname", dJSONData["hostname"])

    printf("}\n")
}
