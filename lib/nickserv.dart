part of irc_client;

/**
 * A handler which identifies with NickServ, and if another user is
 * connected with our nick, ghosts them so that we can connect.
 * 
 * This must be added to the IrcClient as the first handler.
 * 
 * When this handler is in use, subsequent handlers' [onConnection]
 * methods will not be called until this has succesfully identified
 * itself.
 * 
 * This has been tested against freenode. If the implementation of
 * NickServ returns messages in a different format, this will not
 * work. 
 */
class NickServHandler extends Handler {
  String nick;
  String nickservPassword;
  bool connected = false;
  bool first = true;
  
  NickServHandler(this.nickservPassword);
  
  _identify(Irc irc) {
    irc.sendMessage("nickserv", "identify ${nick} ${nickservPassword}");    
  }
  
  bool onCommand(Command cmd, Irc irc) {
    if (first) {
      nick = irc.nick;
      _identify(irc);
      first = false;
    }
    if (cmd.commandNumber == Errors.NICKNAME_IN_USE) {
      var inUseNick = cmd.params[1];
      if (inUseNick == irc.nick) {
        var newNick = "${irc.nick}_";
        irc.setNick(newNick);
        irc.sendMessage("nickserv", "ghost ${nick} ${nickservPassword}");
      }
      return true;
    }
    if (cmd.command == Commands.NOTICE && cmd.params[0] == irc.nick 
        && cmd.trailing.contains("has been ghosted")) {
      irc.setNick(nick);
      _identify(irc);
      return true;
    }
    if (cmd.command == Commands.NOTICE && cmd.params[0] == irc.nick 
        && cmd.trailing.contains("You are now identified for")) {
      connected = true;
      irc._client.connected(irc);
      return true;
    }
    return false;
  }
  
  bool onConnection(Irc irc) {
    if (!connected) {
      return true;
    }
    return false;
  }
}


