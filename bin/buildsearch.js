a = new ActiveXObject("scripting.filesystemobject")
x = new ActiveXObject("wscript.shell")
b = x.exec('findstr /b \"' + WScript.Arguments(0) + '\" build\\DISPLAY.CONF')

entries = []

while (!b.stdout.atendofstream)
{
  c = b.stdout.readline()
  d = c.indexOf("#")

  if (d >= 0)
  {
    c = c.substr(0, d)
  }

  if (c.indexOf("[eof]") >= 0)
  {
    break
  }

  if (c.length > 0)
  {
    entries.push(c)
  }
}

a.createtextfile(WScript.Arguments(1)).write(";\r\n; Game count\r\n;\r\n; This file is automatically generated\r\n;\r\n" + "!word " + "         ".substr(0, 8 - entries.length.toString().length) + entries.length + "\r\n")

source = a.createtextfile("build\\search.a")
source.writeline("*=$6000")
source.writeline("!le16 " + entries.length)
source.writeline("!word KeyLookup")

hgrlog = a.opentextfile("build\\HGR.TITLES.LOG").readall().replace(/\r\n/, "\n")
dhgrlog = a.opentextfile("build\\DHGR.TITLES.LOG").readall().replace(/\r\n/, "\n")

for (i = 0; i < entries.length; i++)
{
  bits = entries[i].indexOf(",")
  dhgr = entries[i].substr(bits - 2, 1)

  if (WScript.Arguments(1).substr(WScript.Arguments(1).length - 3, 1) == "0")
  {
    dhgr = "0"
  }

  cheat = entries[i].substr(bits - 1, 1)
  eq = entries[i].indexOf("=")
  key = ((eq >= 0) ? entries[i].substr(bits + 1, eq - bits - 1) : entries[i])
  value = ((eq >= 0) ? entries[i].substr(eq + 1) : "")
  source.writeline("!byte " + (key.length + value.length + 10).toString())
  source.writeline("Key" + (i + 1).toString())
  source.writeline("!byte " + key.length)
  source.writeline("!text \"" + key + "\"")
  source.writeline("!byte " + value.length)
  source.writeline("!text \"" + value + "\"")
  source.writeline("!byte 1")
  source.writeline("!byte " + ((dhgr * 128) + Number(cheat)))

  if (dhgr != 0)
  {
    dname = dhgrlog.indexOf("\n" + key + ",") + key.length + 2
    dpos = dhgrlog.substr(dname).indexOf(",")
    dsize = dhgrlog.substr(dname + dpos + 1).indexOf("\n")
    dsize = dhgrlog.substr(dname + dpos + 1, dsize)
    dpos = dhgrlog.substr(dname, dpos)
  }
  else
  {
    dname = hgrlog.indexOf("\n" + key + ",") + key.length + 2
    dpos = hgrlog.substr(dname).indexOf(",")
    dsize = hgrlog.substr(dname + dpos + 1).indexOf("\n")
    dsize = hgrlog.substr(dname + dpos + 1, dsize)
    dpos = hgrlog.substr(dname, dpos)
  }

  source.writeline("!be24 " + dpos)
  source.writeline("!le16 " + dsize)
}

source.writeline("KeyLookup")

for (i = 0; i < entries.length; i++)
{
  source.writeline("!word Key" + (i + 1))
}

source.close()
new ActiveXObject("wscript.shell").run('cmd /c %acme% -o ' + WScript.Arguments(2) + ' build\\search.a', 0, 1)
