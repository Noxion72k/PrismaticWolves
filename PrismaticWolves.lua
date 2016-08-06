hexchat.register("PrismaticWolves","dev-6.1","Cut-Aware Colorscript");

codes =
{
    white= '\x0300',
    black= '\x0301',
    dark_blue= '\x0302',
    dark_green= '\x0303',
    light_red= '\x0304',
    dark_red= '\x0305',
    magenta= '\x0306',
    orange= '\x0307',
    yellow= '\x0308',
    light_green= '\x0309',
    cyan= '\x0310',
    light_cyan= '\x0311',
    light_blue= '\x0312',
    light_magenta= '\x0313',
    gray= '\x0314',
    light_gray= '\x0315',

    bold= '\x02',
    underline= '\x1f',

    --reset= '\x0f'
};

colourHash =
{
  ['"'] = "dark_blue",
  ['='] = "orange",
  ['$'] = "dark_red",
  ['§'] = "dark_green",
  ['*'] = "bold",
  ['_'] = "underline"
}
colourPattern='([\xC2-\xF4]?[\xC2-\xF4]?[\xC2-\xF4]?["=%$%\xa7%*%_])'

formatHash = {}

urc = '\xC2'

--utf8char = "[\0-\x7F\xC2-\xF4][\x80-\xBF]*"
sicTags = {"[sic]"}
autoSicTags = {"https:","http:","ftp:","[sic]"}

function string:checkSic()
  for i,v in ipairs(autoSicTags) do
    local loc = self:find(v,1,true)
    if loc then
      return self, true
    end
  end
  return self, false
end

function string:sanitize()
  return self:gsub(urc,'')
end



function saveConfigStr()
  local cfg_str=""
  for k,v in pairs(colourHash) do
    cfg_str = cfg_str .. "["..k.."]=["..v.."] "
  end

  --print("Config -> " .. cfg_str)
  --print(colourPattern)
  return cfg_str
end

function loadConfigStr(cfg_str)
  local nch = {}
  local ncp = ''
  local valid = 0;

  for k,v in cfg_str:gmatch("%[([^%s]+)%]=%[([%w_]+)%]") do
    if (codes[v]) then
      nch[k]=v
      ncp=ncp .. "%" .. k:sub(-1,-1) --only use very last byte as pattern
      valid=valid+1
      --print("K: " .. k .. " v: " .. v)
    end
  end

  if valid > 0 then

    colourHash=nch;
    colourPattern="([\xC2-\xF4]?[\xC2-\xF4]?[\xC2-\xF4]?["..ncp.."])"
  end

end

function alterColorCode(colorCode, colour)
  colourHash[colorCode]=colour;
  local cfg_s = saveConfigStr()
  --print("ACC "..cfg_s)
  hexchat.pluginprefs["PrismaticWolvesConfig"]=cfg_s
  loadConfigStr(cfg_s)


end

--Init

myprefs = hexchat.pluginprefs["PrismaticWolvesConfig"];

if(type(myprefs)=="string") then loadConfigStr(myPrefs) end



hexchat.hook_command("setcolorcode", function (words, words_eol)

  --print("bytes:", words[2]:byte(1,4));
  if(#words < 2) then print("Not enough parameters; character and colour required")
  --elseif (#(words[2]:sanitize()) > 1) then print('Only single characters supported(note, for " you may need to type "")')
  elseif (codes[words[3]]==nil) then print("Unknown colour")
  else
    alterColorCode(words[2], words[3])
  end

  return hexchat.EAT_ALL;

end, "Usage: /setcolorcode <character> <color>;    Sets the colorcode character for a color")


hexchat.hook_command("setpwconfig", function (words, words_eol)

  --print("par "..words_eol[2])
  if words_eol[2] then loadConfigStr(words_eol[2]);
  else print("No config-string given") end

  return hexchat.EAT_ALL;

end, "Usage: /setpwconfig <config>;    Load config into Prismatic Wolves")

hexchat.hook_command("printpwconfig", function (words, words_eol)

  --print(words[2], words[3])
  print(saveConfigStr());
  return hexchat.EAT_ALL;

end, "Usage: /printpwconfig <config>;    Print config from Prismatic Wolves")


function colourText(text, cs)
  local prefix = ""
  if #cs > 0 then
    prefix = codes[colourHash[cs[#cs]]]
  end

  local function cr(t)
    if not colourHash[t] then return t end -- make sure we have the correct character
    if colourHash[t]=="bold" or colourHash[t]=="underline" then return codes[colourHash[t]] end
    if(cs[#cs]==t) then
      table.remove(cs);
      if(#cs==0) then return "\x03"
      else return codes[colourHash[cs[#cs]]] end
    else
      table.insert(cs,t)
      --print("found ".. t)
      return codes[colourHash[cs[#cs]]]
    end
  end

  local ctext = string.gsub(text, colourPattern,cr);

  return prefix .. ctext

end



function cutter(text)
  local segments = {}
  local space_index=1;
  local last_si;
  repeat
    last_si=space_index
    space_index = string.find(text, " ", space_index+1);
    if (space_index ~= nil) and (space_index > 400) then
      table.insert(segments, string.sub(text,1,last_si).."...")
      text = "..." .. string.sub(text,last_si+1, -1);
      space_index=1;
    end
  until (space_index == nil)
  table.insert(segments, text)
  return segments;
end

local saylock = false

hexchat.hook_command("me", function (words, words_eol)
  --print("Nox-command:" .. words_eol[2])

  local sic_modded, sicced = words_eol[1]:checkSic()

  if not (saylock or sicced) then
    saylock = true
    cs = {}
    local segments = cutter(words_eol[2]);

    --print("segments: " .. #segments);
    for i,v in ipairs(segments) do
      hexchat.command("action " .. colourText(v, cs));
      --print(i .. ":" .. v);
    end
    --hexchat.command("say " .. colourText(words_eol[1], cs));

    saylock = false
    return hexchat.EAT_ALL;
  end
  return hexchat.EAT_NONE;
end)



hexchat.hook_command("", function (words, words_eol)
  --print("Nox-command:" .. words_eol[2])

  local sic_modded, sicced = words_eol[1]:checkSic()

  if not (saylock or sicced) then
    saylock = true
    cs = {}

    local segments = cutter(words_eol[1]);

    --print("segments: " .. #segments);
    for i,v in ipairs(segments) do
      hexchat.command("say " .. colourText(v, cs));
      --print(i .. ":" .. v);
    end
    --hexchat.command("say " .. colourText(words_eol[1], cs));


    saylock = false
    return hexchat.EAT_ALL;
  end
  return hexchat.EAT_NONE;
end)
