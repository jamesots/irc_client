library irc_client;

import 'dart:io';
import 'dart:async';

part 'constants.dart';
part 'irc.dart';
part 'command.dart';
part 'handler.dart';
part 'nickserv.dart';

class IrcClient {
  String nick;
  String realName;
  List<Handler> _handlers;
  
  IrcClient(this.nick) {
    _handlers = new List<Handler>();
    realName = "Robbe";
  }
  
  List<Handler> get handlers => _handlers;
  
  connected(Irc irc) {
    for (var handler in handlers) {
      if (handler.onConnection(irc)) {
        break;
      }
    }
  }
  
  run(String server, int port) {
    Socket.connect(server, port).then((socket) {
      var stream = socket.transform(new StringDecoder()).transform(new LineTransformer());
      
      var irc = new Irc(this, socket);
      
      irc.setNick(nick);
      irc.write("${Commands.USER} ${nick} 0 * :${realName}");
      
      stream.listen((line) {
        print("<<${line}");
        var cmd = new Command(line);
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

