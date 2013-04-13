part of irc_client;

/**
 * Transforms a stream of Strings into a stream of [Command]s. Used internally
 * by [IrcClient].
 */
class IrcTransformer extends StreamEventTransformer<String, Command> {
  void handleData(String event, EventSink<Command> sink) {
    var command = new Command(event);
    sink.add(command);
  }
}



