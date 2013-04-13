library irc_client;

import 'dart:io';
import 'dart:async';

part 'src/constants.dart';
part 'src/irc.dart';
part 'src/command.dart';
part 'src/handler.dart';
part 'src/nickserv.dart';
part 'src/transformer.dart';

/**
 * A very simple IRC client, which connects to an IRC server and then
 * calls methods on the supplied [handlers] when commands are received.
 */
class IrcClient {
  String nick;
  String realName;
  List<Handler> _handlers;
  
  /**
   * Create an IrcClient which will connect with the given [nick].
   */
  IrcClient(this.nick) {
    _handlers = new List<Handler>();
    realName = "Robbe";
  }
  
  /**
   * Methods on [handlers] are called when commands are received from
   * the server. 
   */
  List<Handler> get handlers => _handlers;
  
  /**
   * Call this to cause the [onConnection] methods of the [handlers] get
   * called. This is usually not necessary, as the IrcClient or
   * NickServHandler calls this when appropriate anyway.
   */
  connected(Irc irc) {
    for (var handler in handlers) {
      if (handler.onConnection(irc)) {
        break;
      }
    }
  }
  
  /**
   * Connects to the [server] on the given [port].
   * 
   * Currently there is no error handling, or handling of closed connections.
   */
  run(String server, int port) {
    Socket.connect(server, port).then((socket) {
      var stream = socket
          .transform(new StringDecoder())
          .transform(new LineTransformer())
          .transform(new IrcTransformer());
      
      var irc = new Irc._internal(this, socket);
      
      irc.setNick(nick);
      irc.write("${Commands.USER} ${nick} 0 * :${realName}");
      
      stream.listen((cmd) {
        print("<<${cmd.line}");
        var handled = false;
        for (var handler in _handlers) {
          handled = handler.onCommand(cmd, irc);
          if (handled) {
            break;
          }
        }
        if (!handled) {
          if (cmd.commandNumber == Replies.END_OF_MOTD) {
            connected(irc);
          }
          if (cmd.command == Commands.PRIVMSG && cmd.params[0].startsWith("#")) {
            for (var handler in _handlers) {
              if (handler.onChannelMessage(cmd.params[0], cmd.trailing, irc)) {
                break;
              }
            }
          }
          if (cmd.command == Commands.PRIVMSG && cmd.params[0] == nick) {
            var user = cmd.prefix.substring(0, cmd.prefix.indexOf("!"));
            for (var handler in _handlers) {
              if (handler.onPrivateMessage(user, cmd.trailing, irc)) {
                break;
              }
            }
          }
          if (cmd.command == Commands.PING) {
            irc.write("${Commands.PONG} thisserver ${cmd.params[0]}");
          }
        }
      });
    });
  }
}

//TODO: do PONG properly
//TODO: extract user from prefix properly
//TODO: handle connection closing, and reconnection
//TODO: do USER properly
//TODO: use logger
//TODO: character sets, wierd upper/lower case symbols thing
//TODO: methods to get list of users, etc
// http://tools.ietf.org/html/rfc2812#section-3.2.2

