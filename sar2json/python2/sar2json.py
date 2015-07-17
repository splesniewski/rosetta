#!/usr/bin/env python

import sys
import re
import time
import json

def main(argv):
    dJSONData={'data':{}}
    dJSONMeta={}
    dJSONMetaCols=[None]*7
    reMasterHeader=re.compile(r'^(Linux) (\S+) \((\S+)\)[ \s]+(\d+)\/(\d+)\/(\d+)');
    reHeader=re.compile(r'^(\d+):(\d+):(\d+) (\S\S)\s+IFACE\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)')
    reData=re.compile(r'^(\d+):(\d+):(\d+) (\S\S)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)')
    reFooter=re.compile(r'^Average:')
    reBlankLine=re.compile(r'^$')
    for line in sys.stdin:
        if ( reMasterHeader.search(line) is not None):
            lre=reMasterHeader.match(line)
            dJSONData["operatingsystem"]=lre.group(1);
            dJSONData["operatingsystemversion"]=lre.group(2);
            dJSONData["hostname"]=lre.group(3);
            dJSONMeta["month"]=lre.group(4);
            dJSONMeta["dom"]=lre.group(5);
            dJSONMeta["year"]=lre.group(6);
        elif (reHeader.search(line) is not None):
            lre=reHeader.match(line)
            for i in range(0,7):
                dJSONMetaCols[i]=lre.group(i+5)
        elif (reData.search(line) is not None):
            recordMeta={}
            recordData=[None]*7
            lre=reData.match(line)
            recordMeta["hour"]=lre.group(1);
            recordMeta["minute"]=lre.group(2);
            recordMeta["second"]=lre.group(3);
            recordMeta["meridiem"]=lre.group(4);
            recordMeta["IFACE"]=lre.group(5);
            for i in range(0,7):
                recordData[i]=lre.group(i+6)
            #................
            t=time.strptime("{0}/{1}/{2} {3}:{4}:{5} {6}".format(
                dJSONMeta['year'], dJSONMeta['month'], dJSONMeta['dom'],
                recordMeta["hour"], recordMeta["minute"], recordMeta["second"], recordMeta["meridiem"]),"%Y/%m/%d %I:%M:%S %p")
            timestamp=time.strftime("%s",t)
            if timestamp not in dJSONData['data']:
                dJSONData['data'][timestamp]={}
            mc={}
            for i in range(0,7):
                mc[dJSONMetaCols[i]]=recordData[i]
            dJSONData['data'][timestamp][recordMeta["IFACE"]]=mc
        elif (reFooter.search(line) is not None): # ignore the 'Average' lines at the end.
            pass
        elif (reBlankLine.search(line) is not None): # skip blank
            pass
        else:
            sys.stderr.write("cannot parse '{0}'\n".format(line))
    sys.stdout.write(json.dumps(dJSONData))

if __name__ == "__main__":
    exitcode = main(sys.argv[1:])
    sys.exit(exitcode)
