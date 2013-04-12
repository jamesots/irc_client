part of irc_client;

class Irc {
  IrcClient _client;
  Socket _socket;
  String _nick;
  
  Irc(this._client, this._socket);
  
  String get nick => _nick;

  write(String msg) {
    print(">>${msg}");
    _socket.writeln(msg);
  }
  
  sendMessage(String to, String msg) {
    write("${Commands.PRIVMSG} ${to} :${msg}");
  }
  
  sendNotice(String to, String msg) {
    write("${Commands.NOTICE} ${to} :${msg}");
  }
  
  join(String channel) {
    write("${Commands.JOIN} ${channel}");
  }
  
  setNick(String nick) {
    _nick = nick;
    write("${Commands.NICK} ${nick}");
  }
}



