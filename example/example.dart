import 'package:irc_client/irc_client.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

class BotHandler extends Handler {
  bool onChannelMessage(String channel, String message, Connection cnx) {
    if (message.toLowerCase().contains("hello")) {
      cnx.sendMessage(channel, "Hey!");
    }
    if (message.contains("tweet?")) {
      getTweet(channel, cnx);
    }
    return true;
  }
  
  bool onPrivateMessage(String user, String message, Connection cnx) {
    if (message.toLowerCase() == "help") {
      cnx.sendNotice(user, "This is an ${BOLD}example${BOLD} dart bot");
      cnx.sendNotice(user, "It isn't very useful");
    }
    if (message.toLowerCase() == "quit") {
      cnx.close()
          .then((socket) {
            print("Connection closed for ${socket.remoteAddress}");
            exit(0);
          })
          .catchError((message) => print(message));
    }
    return true;
  }
  
  bool onConnection(Connection cnx) {
    var channel = "#mytest56";
    cnx.join(channel);
    cnx.sendMessage(channel, "I'm baaack!");
    new Timer.periodic(new Duration(minutes: 8), (timer) {
      cnx.sendMessage(channel, "I'm still here!");
    });
    return true;
  }
  
  getTweet(String channel, Connection cnx) {
    var url = "https://api.twitter.com/1/statuses/user_timeline.json?include_entities=true&include_rts=true&screen_name=inspire_us&count=1";
    http.read(url, headers: {"Accept": "application/json"}).then((body) {
      var data = JSON.decode(body);
      var tweet = data[0]["text"];
      cnx.sendMessage(channel, "${BOLD}A tweet:${BOLD} ${tweet}");
    });
  }
}

main() {
  print("Starting bot");
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((r) {
    print("${r.time}: ${r.loggerName}: ${r.message}");
  });
  
  var bot = new IrcClient("bottymcbot");
  bot.realName = "Mr Bot";
//  bot.handlers.add(new NickServHandler("wibble"));
  bot.handlers.add(new BotHandler());
  bot.connect("irc.freenode.net", 6667);
}

