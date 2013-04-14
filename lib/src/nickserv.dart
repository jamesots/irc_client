part of irc_client;

/**
 * A handler which identifies with NickServ, and if another user is
 * connected with our nick, ghosts them so that we can connect.
 * 
 * This must be added to the IrcClient as the first handler. For example:
 * 
 *     var bot = new IrcClient("bottymcbot");
 *     bot.realName = "Mr Bot";
 *     bot.handlers.add(new NickServHandler("wibble"));
 *     bot.handlers.add(new MyHandler());
 *     bot.run("irc.freenode.net", 6667);
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
  String _originalNick;
  String nickservPassword;
  bool _connected = false;
  bool _first = true;
  
  NickServHandler(this.nickservPassword);
  
  _identify(Irc irc) {
    irc.sendMessage("nickserv", "identify ${_originalNick} ${nickservPassword}");    
  }
  
  bool onCommand(Command cmd, Irc irc) {
    if (_first) {
      _originalNick = irc.nick;
      _identify(irc);
      _first = false;
    }
    if (cmd.commandNumber == Errors.NICKNAME_IN_USE) {
      var inUseNick = cmd.params[1];
      if (namesAreEqual(inUseNick, irc.nick)) {
        var newNick = "${irc.nick}_";
        irc.setNick(newNick);
        irc.sendMessage("nickserv", "ghost ${_originalNick} ${nickservPassword}");
      }
      return true;
    }
    if (cmd.command == Commands.NOTICE && namesAreEqual(cmd.params[0], irc.nick) 
        && cmd.trailing.contains("has been ghosted")) {
      irc.setNick(_originalNick);
      _identify(irc);
      return true;
    }
    if (cmd.command == Commands.NOTICE && namesAreEqual(cmd.params[0], irc.nick) 
        && cmd.trailing.contains("You are now identified for")) {
      _connected = true;
      irc._client.connected(irc);
      return true;
    }
    return false;
  }
  
  bool onConnection(Irc irc) {
    if (!_connected) {
      return true;
    }
    return false;
  }
}


