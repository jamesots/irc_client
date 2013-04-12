part of irc_client;

class Handler {
  bool onCommand(Command cmd, Irc irc) {
    return false;
  }
  
  bool onChannelMessage(String channel, String message, Irc irc) {
    return false;    
  }
  
  bool onPrivateMessage(String user, String message, Irc irc) {
    return false;
  }
  
  bool onConnection(Irc irc) {
    return false;
  }
}




