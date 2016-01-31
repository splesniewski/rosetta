require "pp"
require "date"
require "json"

dJSONData={'data'=>{}}
dJSONMeta={}
dJSONMetaCols=[]

re={
  :masterheader => /^(Linux) (\S+) \((\S+)\)[ \s]+(\d+)\/(\d+)\/(\d+)/,
  :header       => /^(\d+):(\d+):(\d+) (\S\S)\s+IFACE\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/,
  :data         => /^(\d+):(\d+):(\d+) (\S\S)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/,
  :footer       => /^Average:/,
  :blankline    => /^$/,
}

while line = gets
  case line 
  when re[:masterheader]
    m=re[:masterheader].match(line)
    dJSONData["operatingsystem"]=m[1]
    dJSONData["operatingsystemversion"]=m[2]
    dJSONData["hostname"]=m[3]

    dJSONMeta[:month]=m[4].to_i
    dJSONMeta[:dom]=m[5].to_i
    dJSONMeta[:year]=m[6].to_i

  when re[:header]
    m=re[:header].match(line)
    (0..6).each{|i| dJSONMetaCols[i]=m[i+5]}

  when re[:data]
    recordMeta={}
    recordData=[]

    m=re[:data].match(line)
    recordMeta[:hour]=m[1].to_i
    recordMeta[:minute]=m[2].to_i
    recordMeta[:second]=m[3].to_i
    recordMeta[:meridiem]=m[4]
    recordMeta[:iface]=m[5]
    (0..6).each{|i| recordData[i]=m[i+6]}
    #................
    t=DateTime.new(dJSONMeta[:year], dJSONMeta[:month], dJSONMeta[:dom],
                   (((recordMeta[:meridiem] == "AM") && (recordMeta[:hour]==12))?0:((recordMeta[:meridiem] == "PM") && (recordMeta[:hour]!=12))?recordMeta[:hour]+12:recordMeta[:hour]),
                   recordMeta[:minute], recordMeta[:second] ,"-0500"
                  )

#    t=DateTime.strptime("%4d/%02d/%02d %02d:%02d:%02d %s -0500" % [
#                          dJSONMeta[:year], dJSONMeta[:month], dJSONMeta[:dom],
#                          recordMeta[:hour], recordMeta[:minute], recordMeta[:second], recordMeta[:meridiem]
#                        ],
#                        "%Y/%m/%d %I:%M:%S %p %z")

    timestamp=t.strftime("%s")
    mc={}
    (0..6).each{|i| mc[dJSONMetaCols[i]]=recordData[i] }

    if ! (dJSONData["data"] && dJSONData["data"][timestamp])
      dJSONData["data"][timestamp]={}
    end
    dJSONData["data"][timestamp][recordMeta[:iface]]=mc

  when re[:footer] # ignore the 'Average' lines at the end.

  when re[:blankline] # skip blank

  else
    $stderr.puts "cannot parse: #{line}"

  end
end

puts JSON.generate(dJSONData)
