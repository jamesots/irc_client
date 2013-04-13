part of irc_client;

class Irc {
  IrcClient _client;
  Socket _socket;
  String _nick;
  
  Irc._internal(this._client, this._socket);
  
  /**
   * Returns the current nickname
   */
  String get nick => _nick;

  /**
   * Writes the [message] to the irc server. (Currently also writes it to
   * the console, but will eventually replace with with a logger).
   */
  write(String message) {
    print(">>${message}"); //TODO: use a logger
    _socket.writeln(message);
  }
  
  /**
   * Sends a private [message] to the [nickOrChannel]. 
   */
  sendMessage(String nickOrChannel, String message) {
    write("${Commands.PRIVMSG} ${nickOrChannel} :${message}");
  }
  
  /**
   * Sends a [notice] to the [user].
   */
  sendNotice(String user, String notice) {
    write("${Commands.NOTICE} ${user} :${notice}");
  }
  
  /**
   * Joins a [channel].
   */
  join(String channel) {
    write("${Commands.JOIN} ${channel}");
  }
  
  /**
   * Sets the current [nick].
   */
  setNick(String nick) {
    _nick = nick;
    write("${Commands.NICK} ${nick}");
  }
}



