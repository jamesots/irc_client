import 'package:irc_client/irc_client.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'dart:json';
import 'dart:async';

class BotHandler extends Handler {
  bool onChannelMessage(String channel, String message, Irc irc) {
    if (message.toLowerCase().contains("hello")) {
      irc.sendMessage(channel, "Hey!");
    }
    if (message.contains("tweet?")) {
      getTweet(channel, irc);
    }
    return true;
  }
  
  bool onPrivateMessage(String user, String message, Irc irc) {
    if (message.toLowerCase() == "help") {
      irc.sendNotice(user, "This is an ${BOLD}example${BOLD} dart bot");
      irc.sendNotice(user, "It isn't very useful");
    }
    return true;
  }
  
  bool onConnection(Irc irc) {
    var channel = "#mytest56";
    irc.join(channel);
    irc.sendMessage(channel, "I'm baaack!");
    new Timer.periodic(new Duration(minutes: 8), (timer) {
      irc.sendMessage(channel, "I'm still here!");
    });
    return true;
  }
  
  getTweet(String channel, Irc irc) {
    var url = "https://api.twitter.com/1/statuses/user_timeline.json?include_entities=true&include_rts=true&screen_name=inspire_us&count=1";
    http.read(url, headers: {"Accept": "application/json"}).then((body) {
      var data = parse(body);
      var tweet = data[0]["text"];
      irc.sendMessage(channel, "${BOLD}A tweet:${BOLD} ${tweet}");
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
  bot.run("irc.freenode.net", 6667);
}

