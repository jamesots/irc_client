part of irc_client;

const MAX_MESSAGE_SIZE = 411;

/**
 * The [Connection] object is passed to methods on the [Handler]s, so that they
 * can send commands back to the IRC server.
 */
class Connection {
  Logger ioLog = new Logger("io");
  Socket _socket;
  String _nick;
  String _server;
  String _realName;
  int _port;
  List<Handler> _handlers;
  
  Connection._(this._server, this._port, this._nick, this._realName, this._handlers);
  
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
   * Prepare the [message] to  be sent to the irc server, prefixed with [command].
   * It will cap the user message length to [MAX_MESSAGE_SIZE] if it exceeds it,
   * issuing then multiple requests.
   */
  void splitAndWrite(String command, String message) {
    var messages = new List<String>();
    if (message.length > MAX_MESSAGE_SIZE) {
      ioLog.fine("message longer than $MAX_MESSAGE_SIZE, splitting it");
      var separatedList = message.split(" ");
      var sb = new StringBuffer();
      separatedList.forEach((elem) {
        if ((sb.length != 0) && (sb.length + elem.length > MAX_MESSAGE_SIZE)) {
          messages.add(sb.toString());
          sb.clear();
        }
        while (elem.length > MAX_MESSAGE_SIZE) {
          messages.add(elem.substring(0, MAX_MESSAGE_SIZE));
          elem = elem.substring(MAX_MESSAGE_SIZE);
        }
        if (sb.length != 0) {
          sb.write(" ");
        }
        sb.write(elem);
      });
      messages.add(sb.toString());
    } else {
      messages.add(message);
    }
    messages.forEach((message) => write("$command :${message}"));
  }

  /**
   * Sends a private [message] to the [nickOrChannel]. 
   */
  void sendMessage(String nickOrChannel, String message) {
    splitAndWrite("${Commands.PRIVMSG} ${nickOrChannel}", message);
  }
  
  /**
   * Sends a [notice] to the [user].
   */
  void sendNotice(String user, String notice) {
    splitAndWrite("${Commands.NOTICE} ${user}", notice);
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
  
  /**
   * Call this to cause the [onConnection] methods of the [handlers] get
   * called. This is usually not necessary, as the IrcClient or
   * NickServHandler calls this when appropriate anyway.
   */
  connected(Connection irc) {
    for (var handler in _handlers) {
      if (handler.onConnection(this)) {
        break;
      }
    }
  }
  
  newIrcTransformer() {
    return new StreamTransformer.fromHandlers(handleData: (String event, EventSink<Command> sink) {
      var command = new Command(event);
      sink.add(command);
    });
  }
  
  /**
   * Attemps to connect to the server that this connection handles.
   */
  void connect() {
    Socket.connect(_server, _port).then((socket) {
      var stream = socket
          .transform(UTF8.decoder)
          .transform(new LineSplitter())
          .transform(newIrcTransformer());
      _socket = socket;
      
      setNick(_nick);
      write("${Commands.USER} ${_nick} 0 * :${_realName}");
      
      stream.listen((cmd) {
        ioLog.fine("<<${cmd.line}");
        var handled = false;
        for (var handler in _handlers) {
          handled = handler.onCommand(cmd, this);
          if (handled) {
            break;
          }
        }
        if (!handled) {
          if (cmd.commandNumber == Replies.END_OF_MOTD) {
            connected(this);
          }
          if (cmd.command == Commands.PRIVMSG && isChannel(cmd.params[0])) {
            for (var handler in _handlers) {
              if (handler.onChannelMessage(cmd.params[0], cmd.trailing, this)) {
                break;
              }
            }
          }
          if (cmd.command == Commands.PRIVMSG && namesAreEqual(cmd.params[0], nick)) {
            var user = cmd.prefix.substring(0, cmd.prefix.indexOf("!"));
            for (var handler in _handlers) {
              if (handler.onPrivateMessage(user, cmd.trailing, this)) {
                break;
              }
            }
          }
          if (cmd.command == Commands.PING) {
            write("${Commands.PONG} ${cmd.params[0]}");
          }
        }
      },
      onError: _onError, 
      onDone: _onDone);
    });
  }
  
  /**
   * Attempts to disconnect from the server that this connection handles.
   */
  Future<Socket> close() {
    var completer = new Completer();
    if (_socket == null) {
      ioLog.warning("Can't close an already closed connection");
      completer.completeError("The connection is already closed");
    } else {
      _socket.close().then((closedSocket) {
        _onDone();
        return completer.complete(closedSocket);
      });
    }
    return completer.future;
  }

  _onError(error) {
    // TODO: what?
  }
  
  _onDone() {
    _socket = null;
    for (var handler in _handlers) {
      if (handler.onDisconnection(this)) {
        break;
      }
    }
  }
}
