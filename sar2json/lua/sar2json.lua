local json = require("json")

-- remember: lua patters are not full regexp (but is enough)
local patterns={
   ['masterheader'] = "^(Linux) (%S+) %((%S+)%)[ %s]+(%d+)/(%d+)/(%d+)",
   ['header']       = "^(%d+):(%d+):(%d+) (%S%S)%s+IFACE%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)",
   ['data']         = "^(%d+):(%d+):(%d+) (%S%S)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)",
   ['footer']       = "^Average:",
   ['blankline']    = "^$",
}

dJSONData={['data'] ={}}
dJSONMeta={}
dJSONMetaCols={}

for line in io.lines() do
   if string.find(line,patterns['masterheader']) then
	dJSONData["operatingsystem"],
	dJSONData["operatingsystemversion"],
	dJSONData["hostname"],
	dJSONMeta.month,
	dJSONMeta.dom,
	dJSONMeta.year
	   =string.match(line,patterns['masterheader'])

   elseif string.find(line,patterns['header']) then
      local m={string.match(line,patterns['header'])}
      for i = 1,7 do dJSONMetaCols[i]=m[i+4] end
    
   elseif string.find(line,patterns['data']) then
      local recordMeta={}
      local recordData={}

      local m={string.match(line,patterns['data'])}
      recordMeta.hour,
      recordMeta.minute,
      recordMeta.second,
      recordMeta.meridiem,
      recordMeta.iface = tonumber(m[1]),m[2],m[3],m[4],m[5]
      for i = 1,7 do recordData[i]=m[i+5] end

      --................
      local t = os.time{
	 year=dJSONMeta.year,
	 month=dJSONMeta.month,
	 day=dJSONMeta.dom,
	 hour=(
	    ((recordMeta.meridiem == "AM") and (recordMeta.hour==12)) and 0
	       or ((recordMeta.meridiem == "PM") and (recordMeta.hour~=12)) and recordMeta.hour+12
	       or recordMeta.hour
	      ),
	 min=recordMeta.minute,
	 sec=recordMeta.second
      }
      local timestamp=t
      local mc={}

      for i = 1,7 do mc[dJSONMetaCols[i]]=recordData[i] end

      if (not (dJSONData["data"] and dJSONData["data"][timestamp])) then
	 dJSONData["data"][timestamp]={}
      end
      dJSONData["data"][timestamp][recordMeta.iface]=mc

   elseif string.find(line,patterns['footer']) then
      -- ignore the 'Average' lines at the end.

   elseif string.find(line,patterns['blankline']) then
      -- skip blank

   else
      io.stderr:write(string.format('cannot parse: %s\n', line))

   end
end

io.stdout:write(json.encode(dJSONData))
io.stdout:write('\n')
