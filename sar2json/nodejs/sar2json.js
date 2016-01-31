const readline = require('readline')
const rl = readline.createInterface({
    input: process.stdin,
    terminal: false
})

const re={
    'masterheader' : new RegExp(/^(Linux) (\S+) \((\S+)\)[ \s]+(\d+)\/(\d+)\/(\d+)/),
    'header'       : new RegExp(/^(\d+):(\d+):(\d+) (\S\S)\s+IFACE\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/),
    'data'         : new RegExp(/^(\d+):(\d+):(\d+) (\S\S)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/),
    'footer'       : new RegExp(/^Average:/),
    'blankline'    : new RegExp(/^$/),
}

var dJSONData={'data':{}}
var dJSONMeta={}
var dJSONMetaCols=[]

rl.on('line', function (line) {
    if (line.match(re['masterheader'])) {
	var m=line.match(re['masterheader'])

	dJSONData["operatingsystem"]=m[1]
	dJSONData["operatingsystemversion"]=m[2]
	dJSONData["hostname"]=m[3]

	dJSONMeta.month=m[4]-1
	dJSONMeta.dom=m[5]
	dJSONMeta.year=m[6]

    }else if (line.match(re['header'])) {
	var m=line.match(re['header'])
	for(var i=0;i<=6;i++){ dJSONMetaCols[i]=m[i+5] }
	
    }else if (line.match(re['data'])) {
	var recordMeta={}
	var recordData=[]
	var m=line.match(re['data'])

	recordMeta.hour=parseInt(m[1])
	recordMeta.minute=parseInt(m[2])
	recordMeta.second=parseInt(m[3])
	recordMeta.meridiem=m[4]
	recordMeta.iface=m[5]

	for(var i=0;i<=6;i++){ recordData[i]=m[i+6] }
	//................
	var t=new Date(
	    dJSONMeta.year, dJSONMeta.month, dJSONMeta.dom,
            (((recordMeta.meridiem == "AM") && (recordMeta.hour==12))?0:((recordMeta.meridiem == "PM") && (recordMeta.hour!=12))?recordMeta.hour+12:recordMeta.hour),
            recordMeta.minute, recordMeta.second
        )

	var timestamp=Math.floor(t.getTime()/1000)
	var mc={}

	for(var i=0;i<=6;i++){ mc[dJSONMetaCols[i]]=recordData[i] }

	if (!(dJSONData["data"] && dJSONData["data"][timestamp])) {
	    dJSONData["data"][timestamp]={}
	}
	dJSONData["data"][timestamp][recordMeta.iface]=mc

    }else if (line.match(re['footer'])) {
	// ignore the 'Average' lines at the end.

    }else if (line.match(re['blankline'])) {
	// skip blank

    }else{
	console.error("cannot parse: ", line);
    }


}).on('close', function () {
    console.log(JSON.stringify(dJSONData))
});
