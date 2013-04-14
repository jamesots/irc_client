part of irc_client;

/**
 * The [Irc] object is passed to methods on the [Handler]s, so that they
 * can send commands back to the IRC server.
 */
class Irc {
  Logger ioLog = new Logger("io");
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
  void write(String message) {
    ioLog.fine(">>${message}");
    _socket.writeln(message);
  }
  
  /**
   * Sends a private [message] to the [nickOrChannel]. 
   */
  void sendMessage(String nickOrChannel, String message) {
    write("${Commands.PRIVMSG} ${nickOrChannel} :${message}");
  }
  
  /**
   * Sends a [notice] to the [user].
   */
  void sendNotice(String user, String notice) {
    write("${Commands.NOTICE} ${user} :${notice}");
  }
  
  /**
   * Joins a [channel].
   */
  void join(String channel) {
    write("${Commands.JOIN} ${channel}");
  }
  
  /**
   * Sets the current [nick].
   */
  void setNick(String nick) {
    _nick = nick;
    write("${Commands.NICK} ${nick}");
  }
}
