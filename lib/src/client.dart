part of irc_client;

/**
 * A very simple IRC client, which connects to an IRC server and then
 * calls methods on the supplied [handlers] when commands are received.
 * 
 * An example IRC bot:
 * 
 *     import 'packages:irc_client/irc_client.dart';
 *     
 *     class BotHandler extends Handler {
 *       bool onChannelMessage(String channel, String message, Irc irc) {
 *         if (message.toLowerCase().contains("hello")) {
 *           irc.sendMessage(channel, "Hey!");
 *         }
 *       }
 *     }
 *     
 *     main() {
 *       var bot = new IrcClient("bottymcbot");
 *       bot.handlers.add(new BotHandler());
 *       bot.run("irc.freenode.net");
 *     }
 *     
 */
class IrcClient {
  String nick;
  String realName;
  List<Handler> _handlers;
  Logger ioLog = new Logger("io");
  
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
   * Connects to the [server] on the given [port].
   * 
   * Currently there is no error handling, or handling of closed connections.
   */
  run(String server, [int port = 6667]) {
    var irc = new Irc._(server, port, nick, realName, _handlers);
    irc.connect();
  }
}

/**
 * Returns [true] if the [possibleChannel] is channel name, because it
 * starts with #, &, + or !
 */
bool isChannel(String possibleChannel) {
  if (possibleChannel.length < 2) {
    return false;
  }
  var firstChar = possibleChannel[0];
  return firstChar == '#' || firstChar == '&' || firstChar == '+'
      || firstChar == '!';
}

/**
 * Converts a nick or channel name to lower case according to
 * IRC's rules of equality, where these characters {}|^ are 
 * considered to be the lower case versions of []\~ 
 */
String nameToLowerCase(String name) {
  return name
      .toLowerCase()
      .replaceAll(r"[", r"{")
      .replaceAll(r"]", r"}")
      .replaceAll(r"\", r"|")
      .replaceAll(r"~", r"^");
}

/**
 * Returns [true] if [nameOne] and [nameTwo] are equal, according to
 * IRC's rules of equality, where everything is converted to lower
 * case, and these characters {}|^ are considered to be the lower case
 * versions of []\~ 
 */
bool namesAreEqual(String nameOne, String nameTwo) {
  return nameToLowerCase(nameOne) == nameToLowerCase(nameTwo);
}

/**
 * Use this in a message for it to go bold in most IRC clients.
 * 
 * Example:
 *     irc.sendNotice(user, "This is an ${BOLD}example${BOLD} message");
 */
final String BOLD = "\u0002";

//TODO: do PONG properly
//TODO: extract user from prefix properly
//TODO: handle connection closing, and reconnection
//TODO: do USER properly
//TODO: methods to get list of users, etc
// http://tools.ietf.org/html/rfc2812#section-3.2.2

