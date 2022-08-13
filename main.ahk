

; ==================== PREPAIRING SECTOR ====================

FileEncoding "UTF-16"
SetWorkingDir A_ScriptDir
#SingleInstance
#NoTrayIcon
#Include SQLite.ahk
#Include JS.ahk
botToken := read("settings.ini", "sys", "token")
admin := read("settings.ini", "sys", "admin")
warnmode := read("settings.ini", "sys", "warnmode")
#warn all, off
global admin
global warnmode

; ============================================================



; ==================== GETTING SOURCES SECTOR ====================

data := ""
for i, a in A_Args
   data := data a
data := StrReplace(data, "***Spaceholder", A_Space)
tg := Jxon_Load(&data)

; ============================================================



; ==================== HANDLING SECTOR ====================

setvar(&text,           tg, 'message', 'text')
setvar(&name,           tg, 'message', 'from', 'first_name')
setvar(&username,       tg, 'message', 'from', 'username')
setvar(&from_id,        tg, 'message', 'from', 'id')
setvar(&chat_id,        tg, 'message', 'chat', 'id')
setvar(&message_id,     tg, 'message', 'message_id')
setvar(&callback,       tg, 'callback_query', 'data')
setvar(&entities,       tg, 'message', 'entities')
setvar(&added,          tg, 'message', 'new_chat_participant', 'username')

if ( added = "AntimojiBot" )
   added := true
else
   added := false

if ( callback != '' )
{
   from_id           := tg['callback_query']['from']['id']
   chat_id           := tg['callback_query']['message']['chat']['id']
   message_id        := tg['callback_query']['message']['message_id']

   switch callback
   {
      case "1":
         delete(chat_id, message_id)
         answer(chat_id, "Теперь бот будет предупреждать пользователей, испольщующих пользовательские эмодзи")
         write(1, "settings.ini", "sys", "warnmode")
      case "2":
         delete(chat_id, message_id)
         answer(chat_id, "Теперь бот будет удалять сообщения с пользовательскими эмодзи")
         write(2, "settings.ini", "sys", "warnmode")
      case "3":
         delete(chat_id, message_id)
         answer(chat_id, "Теперь бот будет удалять сообщения с пользовательскими эмодзи и предупреждать пользователя")
         write(3, "settings.ini", "sys", "warnmode")
   }
}

else if added
   answer(chat_id, "🔒 <b>Antimoji — групповой бот для ограничения использования пользовательских и анимированных эмодзи</b>`n`n<b>Как пользоваться:</b>`n— Выдайте боту право на удаление сообщений;`n— Отправьте команду /mode и выберите режим работы.")


else if ( instr(text, '/start') = 1 )
{
   if ( IsNewUser(from_id) )
   {
      CreateNewUser(from_id, name, username, 'home')
      global admin
      answer(admin, 'Новый пользователь: <a href="tg://user?id=' from_id '">' name '</a>')
   }
   if ( from_id = chat_id )
      answer(from_id, "🔒 <b>Antimoji — групповой бот для ограничения использования пользовательских и анимированных эмодзи</b>`n`n<b>Как пользоваться:</b>`n— Добавьте бота в свою группу;`n— Выдайте боту право на удаление сообщений;`n— Отправьте команду /mode и выберите режим работы.", str("addmenu"))
   else
      answer(chat_id, "🔒 <b>Antimoji — групповой бот для ограничения использования пользовательских и анимированных эмодзи</b>`n`n<b>Как пользоваться:</b>`n— Выдайте боту право на удаление сообщений;`n— Отправьте команду /mode и выберите режим работы.")
}

else if ( chat_id != from_id ) && entities
{
   if ( text = '/mode' or text = '/mode@AntimojiBot' ) and ( chat_id != from_id ) 
      if isadmin(from_id, chat_id)
         answer(chat_id, "⚙️ <b>Выбор режима бота</b>`n`nВыберите, в каком режиме бот будет контролировать сообщения с пользовательскими эмодзи", str("mode"))
      else
         answer(chat_id, "Команда доступна только администраторам чата", , message_id)
   else
   {
      found := false
      for i, value in entities
      {
         try
         {
            var := value['custom_emoji_id']
            found := true
            break
         }
         catch
            continue
      }
      if found
      {
         global warnmode
         switch warnmode
         {
            case "1":
               answer(chat_id, "⚠️ Использование пользовательских эмодзи запрещено", , message_id)
            case "2":
               delete(chat_id, message_id)
            case "3":
               answer(chat_id, '⚠️ <a href="tg://user?id=' from_id '">' name '</a>, использование пользовательских эмодзи запрещено')
               delete(chat_id, message_id)
         }
      }
   }  
}

exitapp

; ============================================================












; ==================== METHODS SECTOR ====================

isadmin(id, chat)
{
   url := "https://api.telegram.org/bot" . botToken . "/getChatAdministrators?chat_id=" . chat_id
   result := go(url)
   result := jxon_load(&result)
   setvar(&status, result['result'])
   admin := false
   for i, value in status
      if ( id = value['user']['id'] )
         admin := true
   return admin
}

Answer(chat_id, text, reply_markup:="", reply_to_message_id:=0)
{
   global botToken
   text := StrReplace(text, "`n", "%0A")
   text := StrReplace(text, "+", "%2B")
   url := "https://api.telegram.org/bot" . botToken . "/SendMessage?text=" . text . "&chat_id=" . chat_id . "&reply_markup=" . reply_markup . "&reply_to_message_id=" . reply_to_message_id . "&parse_mode=HTML"
   result := go(url)

}

Delete(chat_id, message_id)
{
   global botToken
   url := "https://api.telegram.org/bot" . BotToken . "/DeleteMessage?message_id=" . message_id . "&chat_id=" . chat_id
   result := go(url)
}

; ============================================================

; ==================== DB SECTOR ====================

CreateNewUser(id, name, username, state)
{
   db := sql(A_WorkingDir "\db.sqlite")
   q := "CREATE DATABASE IF NOT EXISTS db.sqlite;"
   db.exec(q, db.hdb)
        
   q := "CREATE TABLE IF NOT EXISTS users(id INTEGER NOT NULL PRIMARY KEY, username TEXT, name VARCHAR, realname VARCHAR, phone TEXT, state VARCHAR);"
   db.set(q)

   q := "INSERT INTO users (name, id, username, state) VALUES ('" name "', " id ", '" username "', 'home');"
   db.set(q)
   db.close()
}

IsNewUser(id)
{
   db := sql(A_WorkingDir "\db.sqlite")
   q := "SELECT 1 FROM users WHERE id = " id ";"
   result := db.get(q)
   db.close()
   if ( result )
      return false
   else
      return true
   
}

SysData(id, name, state := '')
{
  if ( state = '' )
   {
      db := sql(A_WorkingDir "\db.sqlite")
      q := "SELECT " name " FROM users WHERE id = " id ";"
      state := db.get(q)
      db.close()
      return state[1][name]
   }
   else if ( state = 'delete')
   {
      db := sql(A_WorkingDir "\db.sqlite")
      q := "UPDATE users SET " name " = '' WHERE id = " id ";"
      db.set(q)
      db.close()
   }
   else
   {
      db := sql(A_WorkingDir "\db.sqlite")
      q := "SELECT " name " FROM users WHERE id = " id ";"
      stat := db.get(q)
      if ( stat = "" )
      {
         q := "ALTER TABLE users ADD " name " VARCHAR;"
         db.set(q)
      }
      q := "UPDATE users SET " name " = '" state "' WHERE id = " id ";"
      db.set(q)
      db.close()
   }
}

; ============================================================






; ==================== TECHNICAL SECTOR ====================

read(path, sector, key)
{
   try
   {
      a := iniread(path, sector, key)
      return a
   }
   catch
      return "ERROR"
}

write(data, path, sector, key)
{
   iniwrite(data, path, sector, key)
}

setvar(&dest, src, keys*) 
{
   try {
     for val in keys
       src := src[val]
     dest := src
     return true
   }
   catch
   {
     dest := ""
   }
}

str(name)
{
   string := read("strings.ini", "strings", name)
   string := strreplace(string, "``n", "%0A")
   return string
}

go(url,&variable:="")
{      
   try
   {  
      hObject:=ComObject("WinHttp.WinHttpRequest.5.1")
      hObject.Open("GET",url)
      hObject.Send()
      variable:=hObject.ResponseText
      return variable
   }
}

Jxon_Load(&src, args*) 
{

  key := "", is_key := false
  stack := [ tree := [] ]
  is_arr := Map(tree, 1) ; ahk v2
  next := '"{[01234567890-tfn'
  pos := 0
   
  while ( (ch := SubStr(src, ++pos, 1)) != "" ) 
  {
    if InStr(" `t`n`r", ch)
       continue
    if !InStr(next, ch, true) 
    {
       testArr := StrSplit(SubStr(src, 1, pos), "`n")
       
       ln := testArr.Length
       col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))

       msg := Format("{}: line {} col {} (char {})"
       ,   (next == "")      ? ["Extra data", ch := SubStr(src, pos)][1]
         : (next == "'")     ? "Unterminated string starting at"
         : (next == "\")     ? "Invalid \escape"
         : (next == ":")     ? "Expecting ':' delimiter"
         : (next == '"')     ? "Expecting object key enclosed in double quotes"
         : (next == '"}')    ? "Expecting object key enclosed in double quotes or object closing '}'"
         : (next == ",}")    ? "Expecting ',' delimiter or object closing '}'"
         : (next == ",]")    ? "Expecting ',' delimiter or array closing ']'"
         : [ "Expecting JSON value(string, number, [true, false, null], object or array)"
           , ch := SubStr(src, pos, (SubStr(src, pos)~="[\]\},\s]|$")-1) ][1]
       , ln, col, pos)

       throw Error(msg, -1, ch)
    }
    
    obj := stack[1]
    memType := Type(obj)
    is_array := (memType = "Array") ? 1 : 0
    
    if i := InStr("{[", ch) { ; start new object / map?
       val := (i = 1) ? Map() : Array() ; ahk v2
       
       is_array ? obj.Push(val) : obj[key] := val
       stack.InsertAt(1,val)
       
       is_arr[val] := !(is_key := ch == "{")
       next := '"' (is_key ? "}" : "{[]0123456789-tfn")
    } else if InStr("}]", ch) {
       stack.RemoveAt(1)
       next := stack[1]==tree ? "" : is_arr[stack[1]] ? ",]" : ",}"
    } else if InStr(",:", ch) {
       is_key := (!is_array && ch == ",")
       next := is_key ? '"' : '"{[0123456789-tfn'
    } else { ; string | number | true | false | null
       if (ch == '"') { ; string
          i := pos
          while i := InStr(src, '"',, i+1) {
             val := StrReplace(SubStr(src, pos+1, i-pos-1), "\\", "\u005C")
             if (SubStr(val, -1) != "\")
                break
          }
          if !i ? (pos--, next := "'") : 0
             continue

          pos := i ; update pos

          val := StrReplace(val, "\/", "/")
          val := StrReplace(val, '\"', '"')
          , val := StrReplace(val, "\b", "`b")
          , val := StrReplace(val, "\f", "`f")
          , val := StrReplace(val, "\n", "`n")
          , val := StrReplace(val, "\r", "`r")
          , val := StrReplace(val, "\t", "`t")

          i := 0
          while i := InStr(val, "\",, i+1) {
             if (SubStr(val, i+1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
                continue 2

             xxxx := Abs("0x" . SubStr(val, i+2, 4)) ; \uXXXX - JSON unicode escape sequence
             if (xxxx < 0x100)
                val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
          }
          
          if is_key {
             key := val, next := ":"
             continue
          }
       } else { ; number | true | false | null
          val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
          
              if IsInteger(val)
                  val += 0
              else if IsFloat(val)
                  val += 0
              else if (val == "true" || val == "false")
                  val := (val == "true")
              else if (val == "null")
                  val := ""
              else if is_key {
                  pos--, next := "#"
                  continue
              }
          
          pos += i-1
       }
       
       is_array ? obj.Push(val) : obj[key] := val
       next := obj == tree ? "" : is_array ? ",]" : ",}"
    }
  }
   
  return tree[1]
}



; ============================================================
